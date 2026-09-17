"""Retain and demodulate J1 numerical I/Q from the physical FPGA tap."""
import binascii,hashlib,json,struct,time
from pathlib import Path
import numpy as np
from scipy.signal import butter,sosfilt,lfilter,resample_poly
from scipy.io.wavfile import write
from matplotlib.figure import Figure
from matplotlib.backends.backend_agg import FigureCanvasAgg

def decode(packet):
 size=131106
 if len(packet)%size:raise ValueError('Incomplete J1 record')
 payload=[];identity=None;count=len(packet)//size
 for index in range(count):
  p=packet[index*size:(index+1)*size]
  if p[:4]!=b'\xa5\x5aJ1' or sum(p[:-2])&65535!=int.from_bytes(p[-2:],'little'):raise ValueError('J1 checksum/framing error')
  seq,ticks,n,dec,bits=struct.unpack_from('<IIHBB',p,4)
  halves,crc,flags,events,chunk,total=struct.unpack_from('<IHHIHH',p,131088)
  current=(seq,ticks,halves,crc,flags,events,total)
  if (n,dec,bits)!=(0,1,32) or total!=count or chunk!=index or flags&~1:raise ValueError('J1 ordering/flags mismatch')
  if identity is None:identity=current
  elif identity!=current:raise ValueError('J1 mixed acquisition identities')
  payload.append(p[16:131088])
 seq,ticks,halves,crc,flags,events,total=identity
 if events%2 or halves!=events*2 or total!=(events+32767)//32768:raise ValueError('J1 exact-word counts mismatch')
 payload=b''.join(payload)
 if any(payload[events*4:]):raise ValueError('J1 padding not zero')
 raw=payload[:events*4]
 crc_actual=binascii.crc_hqx(np.frombuffer(raw,dtype='<u2').astype('>u2').tobytes(),0xffff)
 if crc_actual!=crc:raise ValueError(f'J1 full input CRC mismatch {crc_actual} != {crc}')
 iq=np.frombuffer(raw,dtype='<i4').reshape(-1,2).copy()
 return iq,dict(sequence=seq,first_fpga_clock=ticks,input_crc_matched=True,pre_encoding_crc16=crc,reconstructed_crc16=crc_actual,crc_scope='CRC of every numerical I/Q word entering RAM, not a CRC of all underlying RF decisions',queue_pressure_stop=bool(flags),chunks=count,complex_samples=len(iq),payload_sha256=hashlib.sha256(raw).hexdigest())

def read_chunk(u,out,name,stall_after_bytes=None):
 size=131106;raw=bytearray();packet=None;deadline=time.monotonic()+40;stalled=False
 with (out/name).open('wb',buffering=0) as f:
  while time.monotonic()<deadline:
   b=u.bulk(True,length=64);f.write(b);raw.extend(b);start=raw.find(b'\xa5\x5aJ1')
   if stall_after_bytes is not None and not stalled and len(raw)>=stall_after_bytes:
    print('Controlled transport test: pause host reads for3s; FPGA capture is already retained.',flush=True)
    time.sleep(3);stalled=True
   if start>=0 and len(raw)>=start+size:packet=bytes(raw[start:start+size]);break
   if len(raw)>size+4096:raise RuntimeError('J1 stream framing lost; bytes retained')
 if packet is None:raise TimeoutError('J1 transfer timeout; no USB reset issued')
 if sum(packet[:-2])&65535!=int.from_bytes(packet[-2:],'little'):raise ValueError('J1 chunk checksum failed')
 return packet

def capture(u,manifest,out):
 out=Path(out);out.mkdir()
 (out/'source_manifest.json').write_text(json.dumps(manifest,indent=2));(out/'capture_source.py').write_bytes(Path(__file__).read_bytes())
 size=131106;packets=[];count=1;identity=None;requested=time.perf_counter_ns()
 u.bulk(False,b'P');time.sleep(.03)
 while len(packets)<count:
  index=len(packets);u.bulk(False,b'E' if index==0 else b'N')
  # E acquires the whole 2.63s record before sending a byte. The stable USB
  # reader intentionally times out after 1s of silence; wait for acquisition
  # here instead of changing its transport policy. The bridge buffers the
  # short head start in UART delivery before this first read.
  if index==0:time.sleep(manifest.get('listen_tap',{}).get('capture_wait_s',2.8))
  for attempt in range(3):
   try:
    packet=read_chunk(u,out,f'chunk_{index:02d}_uart.bin' if attempt==0 else f'chunk_{index:02d}_retry{attempt}_uart.bin');break
   except (TimeoutError,ValueError) as exc:
    if attempt==2 or manifest.get('chunk_replay_command')!='T' or getattr(u,'_poisoned',False):raise
    retry=dict(chunk=index,attempt=attempt+1,error=repr(exc),command='T',qpc_ns=time.perf_counter_ns(),reacquisition=False)
    with (out/'retries.jsonl').open('a') as f:f.write(json.dumps(retry)+'\n')
    print(json.dumps(dict(stage='Replay same retained chunk; USB not reset',**retry)),flush=True)
    u.bulk(False,b'T')
  fields=struct.unpack_from('<IHHIHH',packet,131088);count=fields[-1]
  if not 1<=count<=64 or fields[-2]!=index:raise ValueError('J1 chunk order error')
  current=packet[4:12]+packet[131088:131100]+packet[131102:131104]
  if identity is None:identity=current
  elif identity!=current:raise ValueError('J1 acquisition changed')
  (out/f'chunk_{index:02d}.bin').write_bytes(packet);packets.append(packet)
  progress=dict(stage='physical numerical I/Q transfer',chunks=len(packets),expected=count,run=str(out))
  (out/'progress.json').write_text(json.dumps(progress));print(json.dumps(progress),flush=True)
 packet=b''.join(packets);(out/'packet.bin').write_bytes(packet)
 iq,checked=decode(packet);rate=manifest['listen_tap']['iq_sample_rate_nominal_hz']
 np.savez_compressed(out/'iq.npz',i=iq[:,0],q=iq[:,1],rate_hz=rate)
 report=dict(run=str(out),format='J1',packet_sha256=hashlib.sha256(packet).hexdigest(),bitstream_sha256=manifest['bitstream_sha256'],frequency_hz=manifest['listen_tap']['frequency_hz'],sample_rate_nominal=rate,duration_s=len(iq)/rate,request_qpc_ns=requested,complete_qpc_ns=time.perf_counter_ns(),generator_commands=0,relay_commands=0,usb_reset=False,**checked)
 (out/'report.json').write_text(json.dumps(report,indent=2));return report

def analyze(out):
 out=Path(out);r=json.loads((out/'report.json').read_text());iq,_=decode((out/'packet.bin').read_bytes());rate=r['sample_rate_nominal']
 x=iq[:,0].astype(np.float64)+1j*iq[:,1].astype(np.float64);guard=int(.006*rate);x=x[guard:-guard]
 hz=np.angle(x[1:]*x[:-1].conj())*rate/(2*np.pi);offset=float(hz.mean());hz-=offset
 from fm_tracking_receiver import tracking_fm
 tracked,errors=tracking_fm(x,rate,8000);tracked-=tracked.mean()
 from fractions import Fraction
 ratio=Fraction(48000/rate).limit_denominator(1000000);audios={}
 for name,values in [('phase',hz),('tracking',tracked)]:
  audio=sosfilt(butter(4,15000,fs=rate,output='sos'),values)
  pole=np.exp(-1/(rate*75e-6));audio=lfilter([1-pole],[1,-pole],audio)
  audio=resample_poly(audio,ratio.numerator,ratio.denominator).astype(np.float32)
  audios[name]=audio;write(out/(name+'.wav'),48000,audio*(.25/55000))
 gain=.9/max(float(abs(audios['phase']).max()),1e-30);write(out/'106.5MHz_listen.wav',48000,audios['phase']*gain)
 np.savez_compressed(out/'multiplex.npz',phase_hz=hz,tracking_hz=tracked,iq_rate_hz=rate)
 from scipy.signal import welch,spectrogram
 f,p=welch(hz,rate,nperseg=65536);p=np.maximum(p,1e-30)
 pilot=abs(f-19000)<200;j=np.flatnonzero(pilot)[np.argmax(p[pilot])];flank=(abs(f-19000)>500)&(abs(f-19000)<1800)
 report=dict(**r,audio_seconds=len(audios['phase'])/48000,envelope_cv=float(np.std(abs(x))/np.mean(abs(x))),fm_mean_offset_hz=offset,phase_std_hz=float(hz.std()),tracking_error_std_rad=float(np.std(errors)),pilot_peak_hz=float(f[j]),pilot_contrast_db=float(10*np.log10(p[j]/p[flank].mean())),constant_listening_gain=gain,station_identity_confirmed=False,gap_filling=False,modeled=False)
 (out/'analysis.json').write_text(json.dumps(report,indent=2))
 fig=Figure(figsize=(20.48,12.8),layout='constrained');FigureCanvasAgg(fig);ax=fig.subplots(2,2)
 ax[0,0].plot(f/1000,10*np.log10(p));ax[0,0].set(xlim=(0,65),xlabel='Multiplex frequency (kHz)',ylabel='Deviation PSD (dB Hz²/Hz)',title='Actual FM phase-difference multiplex')
 t=np.arange(len(audios['phase']))/48000;ax[0,1].plot(t,audios['phase']/1000,lw=.5);ax[0,1].set(xlabel='Time (s)',ylabel='Audio deviation (kHz)',title='Actual mono audio,75µs de-emphasis')
 f,t,p=spectrogram(audios['phase'],48000,nperseg=2048,noverlap=1536)
 ax[1,0].pcolormesh(t,f/1000,10*np.log10(np.maximum(p,1e-30)),shading='auto',cmap='magma');ax[1,0].set(ylim=(0,15),xlabel='Time (s)',ylabel='Audio frequency (kHz)',title='Captured audio spectrogram')
 ax[1,1].plot(np.arange(len(x))[::128]/rate,abs(x)[::128],lw=.5);ax[1,1].set(xlabel='Time (s)',ylabel='Exact I/Q magnitude (counts)',title='Recorded numerical I/Q envelope')
 fig.suptitle('106.5MHz • physical one-pin RF → numerical I/Q → host FM\nNo LNA; generator off; autonomous FPGA bias; analog audio pad disabled',fontsize=19)
 fig.supxlabel(f'{r["complex_samples"]:,} exact32-bit I/Q pairs • {r["duration_s"]:.6f}s continuous • full I/Q CRC matched\nTemporary selected-channel diagnostic; full-band acquisition remains a separate mode. No gap filling or repeated audio.',fontsize=12)
 fig.savefig(out/'106.5MHz_listen.png',dpi=200);print(json.dumps(report,indent=2));return report

if __name__=='__main__':
 import argparse
 p=argparse.ArgumentParser();p.add_argument('--capture',type=Path,required=True);a=p.parse_args();analyze(a.capture)
