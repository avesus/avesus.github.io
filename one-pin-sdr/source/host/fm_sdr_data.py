"""Receive and plot actual R1/D0 FPGA bursts through the existing UART owner."""
import hashlib,json,struct,time
from pathlib import Path
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

def capture(u,manifest,out,kind,stop=None,progress=None,read_delay_ms=0,ram_gated=False,bias_hold=False):
    if bias_hold and (kind!='raw' or not manifest.get('bias_servo')):
        raise ValueError('Brief bias hold requires qualified servo and raw RF capture')
    if type(ram_gated) is not bool:raise ValueError('RAM gate must be boolean')
    if ram_gated and (kind!='compressed' or not manifest['sdr_capture'].get('compressed_ram_gate_control')):
        raise ValueError('RAM-gating-capable C1 image required')
    if not isinstance(read_delay_ms,(int,float)) or not np.isfinite(read_delay_ms) or not 0<=read_delay_ms<=100:
        raise ValueError('Read delay must be finite and within0..100ms')
    if read_delay_ms and kind!='compressed':
        raise ValueError('Read-delay discriminator is restricted to C1 captures')
    if kind=='deep':
        from sdr_psram_rf_data import capture as capture_deep
        return capture_deep(u,manifest,out,stop,progress)
    spec=manifest['sdr_capture'];fmt=spec[kind+'_format']
    record_bytes=spec.get(kind+'_record_bytes',spec['record_bytes'])
    out=Path(out);out.mkdir(parents=True,exist_ok=False)
    (out/'source_manifest.json').write_text(json.dumps(manifest,indent=2))
    (out/'capture_source.py').write_bytes(Path(__file__).read_bytes())
    u.bulk(False,b'P')
    if kind=='compressed' and spec.get('compressed_ram_gate_control'):
        u.bulk(False,b'G' if ram_gated else b'g')
    time.sleep(.03)
    command={'raw':b'R','dual':b'D','filtered':b'F','compressed':b'C','memory':b'M'}[kind]
    request_qpc_ns=time.perf_counter_ns()
    hold_events=dict(requested=bias_hold,hold_request_qpc_ns=request_qpc_ns,rearm_complete_qpc_ns=None)
    rearmed=not bias_hold
    # H then R on the same UART write. The R1 header is emitted only after
    # all65536 RF words are frozen; rearm immediately on that header, before
    # waiting for the11second USB drain. G is accepted while R1 is sending.
    try:
      u.bulk(False,(b'H' if bias_hold else b'')+command)
      command_complete_qpc_ns=time.perf_counter_ns()
    # The installed bridge has a16KiB UART RX ring plus512-byte CDC buffers.
    # At115200 baud,100ms receives at most1152 UART bytes. No MCU/USB reset,
    # line-coding change, heartbeat or pending IN request occurs in this wait.
    # USB SOF traffic may continue: this is not an electrically USB-off capture.
      if read_delay_ms:time.sleep(read_delay_ms/1000)
      first_read_qpc_ns=time.perf_counter_ns()
      deadline=time.monotonic()+35;raw=bytearray();packet=None
      with (out/'uart_raw.bin').open('wb',buffering=0) as f:
        while time.monotonic()<deadline:
            b=u.bulk(True,length=64);f.write(b);raw.extend(b)
            ix=raw.find(b'\xa5\x5a'+fmt.encode())
            if bias_hold and not rearmed and ix>=0 and len(raw)>=ix+16:
                hold_events['completed_capture_header_qpc_ns']=time.perf_counter_ns()
                u.bulk(False,b'G');rearmed=True
                hold_events['rearm_complete_qpc_ns']=time.perf_counter_ns()
            if ix>=0 and len(raw)>=ix+record_bytes:
                packet=bytes(raw[ix:ix+record_bytes]);break
            if len(raw)>record_bytes+4096:raise RuntimeError('Unexpected SDR framing; raw retained')
    finally:
      if bias_hold and not rearmed:
        try:
          u.bulk(False,b'G');rearmed=True
          hold_events['rearm_complete_qpc_ns']=time.perf_counter_ns()
        finally:(out/'bias_hold_events.json').write_text(json.dumps(hold_events,indent=2))
      elif bias_hold:(out/'bias_hold_events.json').write_text(json.dumps(hold_events,indent=2))
    if packet is None:raise RuntimeError('SDR packet incomplete; raw retained')
    (out/'packet.bin').write_bytes(packet)
    if sum(packet[:-2])&65535!=struct.unpack_from('<H',packet,len(packet)-2)[0]:raise RuntimeError('SDR checksum mismatch; raw retained')
    sequence,ticks,n,decimation,bits=struct.unpack_from('<IIHBB',packet,4)
    if kind=='memory':
        if (n,decimation,bits)!=(spec['memory_records'],1,32):raise RuntimeError('Memory probe format mismatch')
    elif kind=='compressed':
        if not 1<=n<=32766 or (decimation,bits)!=(1,16):raise RuntimeError('Compressed SDR format mismatch')
        if struct.unpack_from('<H',packet,131086)[0]!=int(ram_gated):raise RuntimeError('RAM-gating mode acknowledgement mismatch')
    elif kind=='filtered':
        if (n,decimation,bits&15)!=(16384,2,8 if fmt=='F3' else 3):raise RuntimeError('Filtered SDR format mismatch')
    elif (n,decimation,bits)!=((0,1,16) if kind=='raw' else (8192,81,32)):raise RuntimeError('SDR format mismatch')
    report=dict(kind=kind,format=fmt,sequence=sequence,first_fpga_clock=ticks,
        request_qpc_ns=request_qpc_ns,complete_qpc_ns=time.perf_counter_ns(),checksum_passed=True,
        packet_sha256=hashlib.sha256(packet).hexdigest(),generator_commands=0,relay_commands=0,
        radio_reception_confirmed=False,clock_calibrated=False,run=str(out))
    report.update(read_delay_ms=read_delay_ms,command_complete_qpc_ns=command_complete_qpc_ns,
        first_read_submit_qpc_ns=first_read_qpc_ns,
        actual_host_read_delay_ms=(first_read_qpc_ns-command_complete_qpc_ns)/1e6,
        usb_quiet_scope='No owner IN requests during delay; USB SOF and other bus activity are not disabled')
    if bias_hold:report['bias_hold']=hold_events
    if kind=='memory':
        from sdr_psram_data import render
        report=render(packet,out,report)
        (out/'report.json').write_text(json.dumps(report,indent=2))
        return report
    if kind=='compressed':
        from sdr_lossless_data import render
        report['sample_rate_nominal']=spec['raw_sample_rate_nominal']
        report=render(packet,out,report)
        (out/'report.json').write_text(json.dumps(report,indent=2))
        return report
    if kind=='filtered':
        if fmt=='F3':
            from interstage15_data import render
        else:
            from interstage_data import render
        report['sample_rate_nominal']=spec['filtered_rate_hz']
        report=render(packet,out,report)
        (out/'report.json').write_text(json.dumps(report,indent=2))
        return report
    if kind=='raw':
        words=np.frombuffer(packet[16:-2],dtype='<u2')
        samples=((words[:,None]>>np.arange(15,-1,-1))&1).reshape(-1).astype(np.int8)
        rate=spec['raw_sample_rate_nominal'];duration=len(samples)/rate
        report.update(samples=len(samples),sample_rate_nominal=rate,duration_s=duration,
            one_fraction=float(samples.mean()),transitions=int(np.count_nonzero(np.diff(samples))),
            first_nyquist_max_hz=rate/2,dc_200mhz_sampling_span=rate/2>=200000000,
            analog_bandwidth_calibrated=False)
        fig,axes=plt.subplots(3,1,figsize=(14,9),layout='constrained')
        axes[0].step(np.arange(256)/rate*1e6,samples[:256],where='post',lw=.8)
        axes[0].set(xlabel='Nominal time (us)',ylabel='Actual comparator bit',ylim=(-.1,1.1),title='One-pin raw RF capture: first 256 actual bits')
        x=samples.astype(float)*2-1;x-=x.mean()
        nfft=32768;window=np.hanning(nfft);blocks=x.reshape(-1,nfft)
        spectra=np.abs(np.fft.rfft(blocks*window,axis=1))**2/(rate*np.sum(window**2))
        spectra[:,1:-1]*=2;frequency=np.fft.rfftfreq(nfft,1/rate)/1e6
        db=10*np.log10(np.maximum(spectra,1e-30))
        axes[1].plot(frequency,10*np.log10(np.maximum(spectra.mean(axis=0),1e-30)),lw=.6)
        axes[1].set(xlabel='MHz',ylabel='Comparator-relative dB/Hz',title='Simultaneous spectrum from one retained block; no sweep')
        im=axes[2].imshow(db,origin='lower',aspect='auto',extent=(0,rate/2e6,0,duration*1000),cmap='magma',vmin=-105,vmax=-65)
        axes[2].set(xlabel='MHz',ylabel='Time within capture (ms)',title=f'Actual waterfall · {rate/1e6:g} Msample/s nominal · constant DC removed for FFT')
        for ax in axes[1:]:
            ax.set_xlim(0,200)
            if rate/2e6<200:ax.axvspan(rate/2e6,200,color='#dddddd',hatch='//',alpha=.7)
        if rate/2e6<200:axes[1].text(rate/2e6+2,axes[1].get_ylim()[0]+5,f'{rate/2e6:g}–200 MHz\nnot independently\ncaptured',fontsize=8)
        if not report['transitions']:axes[1].text(5,-295,'Constant input; zero AC. Numerical display floor is not a noise measurement.')
        np.savez(out/'spectrum.npz',frequency_hz=frequency*1e6,psd=spectra.mean(axis=0),waterfall_psd=spectra)
        fig.colorbar(im,ax=axes[2],label='Comparator-relative dB/Hz')
    else:
        iq=np.frombuffer(packet[16:-2],dtype='<i4').reshape(-1,4).copy()
        np.savez(out/'raw_dual_iq32.npz',iq=iq,sample_rate_nominal=spec['iq_sample_rate_nominal'],first_fpga_clock=ticks)
        rate=spec['iq_sample_rate_nominal'];duration=len(iq)/rate
        report.update(samples_per_channel=len(iq),component_bits=32,sample_rate_nominal=rate,duration_s=duration,
            ranges=[[int(a.min()),int(a.max())] for a in iq.T],unique_rows=len(np.unique(iq,axis=0)),channels=spec['channels'],simultaneous_channels=True,
            iq_dc_offset=spec.get('iq_dc_offset',[0,1280]),cic_order=spec.get('cic_order',1),cic_gain=spec.get('cic_gain',80))
        fig,axes=plt.subplots(3,2,figsize=(14,10),layout='constrained')
        for ch in range(2):
            t=np.arange(len(iq))/rate;pair=iq[:,2*ch:2*ch+2];freq=spec['channels'][ch]['rf_hz']/1e6
            for k,label in enumerate(('I','Q')):
                axes[0,ch].plot(t[:512]*1e3,pair[:512,k],'.-',ms=1.5,lw=.6,color=('tab:blue','tab:orange')[k],label=label)
            axes[0,ch].set(title=f'DDS {ch+1} · {freq:.3f} MHz · actual32-bit I/Q',xlabel='Nominal time (ms)',ylabel='Signed numeric counts');axes[0,ch].legend()
            offset=spec.get('iq_dc_offset',[0,1280])
            z=(pair[:,0].astype(float)-offset[0])+1j*(pair[:,1]-offset[1])
            fullwin=np.hanning(len(z));fullpower=np.abs(np.fft.fftshift(np.fft.fft(z*fullwin)))**2/(rate*np.sum(fullwin**2))
            fullfreq=np.fft.fftshift(np.fft.fftfreq(len(z),1/rate))/1e6+freq
            axes[1,ch].plot(fullfreq,10*np.log10(np.maximum(fullpower,1e-30)),lw=.6)
            axes[1,ch].set(xlabel='Nominal RF frequency (MHz)',ylabel='dB(counts²/Hz)',title=f'Full8192-point FFT · {rate/len(z):.3f} Hz bins · DC retained')
            np.savez(out/f'channel{ch+1}_full_spectrum.npz',frequency_hz=fullfreq*1e6,psd=fullpower)
            nfft=512;hop=256;blocks=np.lib.stride_tricks.sliding_window_view(z,nfft)[::hop];win=np.hanning(nfft)
            p=np.abs(np.fft.fftshift(np.fft.fft(blocks*win,axis=1),axes=1))**2/(rate*np.sum(win**2))
            db=10*np.log10(np.maximum(p,1e-30));floor=float(np.percentile(db,10));ceiling=max(floor+10,float(np.percentile(db,99.5)))
            im=axes[2,ch].imshow(db,origin='lower',aspect='auto',
                extent=(freq-rate/2e6,freq+rate/2e6,0,duration*1e3),cmap='magma',vmin=floor,vmax=ceiling)
            axes[2,ch].set(xlabel='Nominal RF frequency (MHz)',ylabel='Time within same capture (ms)',title=f'Time detail · {rate/nfft:.1f} Hz bins / {hop/rate*1000:.3f} ms hop')
            fig.colorbar(im,ax=axes[2,ch],label='dB(counts²/Hz)')
    fig.savefig(out/'waterfall.png',dpi=130);plt.close(fig)
    (out/'report.json').write_text(json.dumps(report,indent=2))
    return report
