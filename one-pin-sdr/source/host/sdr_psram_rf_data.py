"""Retain numbered E1/E2 chunks from one physical, full-band RF acquisition."""
import binascii,hashlib,json,struct,time
from pathlib import Path
import numpy as np


def decode(packet):
    fmt=packet[2:4]
    if fmt not in (b'E1',b'E2',b'E3'):raise ValueError('Unknown deep RF format')
    size=131110 if fmt==b'E2' else 131106
    if not len(packet) or len(packet)%size:raise ValueError('Incomplete E1 chunk set')
    chunks=[packet[i:i+size] for i in range(0,len(packet),size)]
    event_bytes=[];identity=None
    for index,p in enumerate(chunks):
        if p[:4]!=b'\xa5\x5a'+fmt or sum(p[:-2])&65535!=int.from_bytes(p[-2:],'little'):
            raise ValueError('E1 framing/checksum mismatch')
        seq,ticks,n,dec,bits=struct.unpack_from('<IIHBB',p,4)
        words,crc,flags,events,chunk,count=struct.unpack_from('<IHHIHH',p,131088)
        if (n,dec,bits)!=(0,1,32) or flags&~1 or chunk!=index or count!=len(chunks):
            raise ValueError('E1 header/chunk order/flags mismatch')
        marker=struct.unpack_from('<I',p,131104)[0] if fmt==b'E2' else None
        current=(seq,ticks,words,crc,flags,events,count,marker)
        if identity is None:identity=current
        elif current!=identity:raise ValueError('E1 chunks belong to different RF acquisitions')
        event_bytes.append(p[16:131088])
    seq,ticks,n,crc,flags,events,count,marker=identity
    if not 1<=n<=33554432 or not 1<=events<=2097152 or count!=(events+32767)//32768:
        raise ValueError('E1 capture bounds mismatch')
    payload=b''.join(event_bytes)
    if any(payload[events*4:]):raise ValueError('E1 nonzero padding')
    if fmt==b'E3':
        from sdr_dense_codec import decode as dense_decode
        words=dense_decode(payload[:events*4],n)
    else:
        pairs=np.frombuffer(payload[:events*4],dtype='<u2').reshape(-1,2)
        ends=np.cumsum(pairs[:,1].astype(np.int64)+1)
        if ends[-1]!=n:raise ValueError(f'E1 reconstructed word count {ends[-1]} != hardware {n}')
        words=np.zeros(n,dtype=np.uint16);words[ends-1]=pairs[:,0]
    checked=binascii.crc_hqx(words.astype('>u2').tobytes(),0xffff)
    if checked!=crc:raise ValueError(f'E1 input CRC mismatch {checked:04x} != {crc:04x}')
    return words,dict(sequence=seq,first_fpga_clock=ticks,events=events,rf_words=n,
        chunks=count,queue_pressure_stop=bool(flags&1),pre_encoding_crc16=crc,
        first_ram_write_rf_word=marker,
        reconstructed_crc16=checked,pre_encoding_crc_matched=True,samples=n*16,
        compression_ratio=n*2/(count*131072),
        validation='Every reconstructed RF word checked against the pre-encoding hardware CRC; USB chunks share one acquisition identity')


def capture(u,manifest,out,stop=None,progress=None):
    out=Path(out);out.mkdir(parents=True,exist_ok=False)
    (out/'source_manifest.json').write_text(json.dumps(manifest,indent=2))
    size=manifest['sdr_capture']['deep_record_bytes'];fmt=manifest['sdr_capture']['deep_format']
    packets=[];count=1;identity=None
    requested=time.perf_counter_ns()
    def update(**extra):
        value=dict(kind='deep',chunks_received=len(packets),chunks_expected=count,run=str(out),**extra)
        (out/'progress.json').write_text(json.dumps(value,indent=2))
        if progress:progress(value)
    u.bulk(False,b'P');time.sleep(.03)
    while len(packets)<count:
        index=len(packets);update(stage='receiving RF from PSRAM')
        u.bulk(False,b'E' if index==0 else b'N')
        raw=bytearray();deadline=time.monotonic()+35;packet=None
        with (out/f'chunk_{index:02d}_uart.bin').open('wb',buffering=0) as stream:
            while time.monotonic()<deadline:
                b=u.bulk(True,length=64);stream.write(b);raw.extend(b)
                start=raw.find(b'\xa5\x5a'+fmt.encode())
                if start>=0 and len(raw)>=start+size:packet=bytes(raw[start:start+size]);break
                if len(raw)>size+4096:raise RuntimeError('E1 framing lost; actual bytes retained')
        if packet is None:raise TimeoutError(f'E1 chunk {index} incomplete; owner not restarted')
        (out/f'chunk_{index:02d}.bin').write_bytes(packet)
        if sum(packet[:-2])&65535!=int.from_bytes(packet[-2:],'little'):raise ValueError('E1 USB checksum mismatch')
        seq,ticks,n,dec,bits=struct.unpack_from('<IIHBB',packet,4)
        words,crc,flags,events,chunk,count=struct.unpack_from('<IHHIHH',packet,131088)
        if not 1<=count<=manifest['sdr_capture'].get('deep_max_chunks',8) or chunk!=index:raise ValueError('E1 chunk number/count mismatch')
        marker=struct.unpack_from('<I',packet,131104)[0] if fmt=='E2' else None
        current=(seq,ticks,words,crc,flags,events,count,marker)
        if identity is None:identity=current
        elif current!=identity:raise ValueError('E1 acquisition changed during transfer')
        packets.append(packet);update(stage='chunk retained')
        if stop is not None and stop.is_set() and len(packets)<count:
            return dict(kind='deep',cancelled=True,run=str(out),chunks_received=len(packets))
    packet=b''.join(packets);(out/'packet.bin').write_bytes(packet)
    update(stage='checking complete RF input CRC')
    words,metrics=decode(packet)
    report=dict(kind='deep',format=fmt,request_qpc_ns=requested,
        sample_rate_nominal=manifest['sdr_capture']['raw_sample_rate_nominal'],
        complete_qpc_ns=time.perf_counter_ns(),checksum_passed=True,
        packet_sha256=hashlib.sha256(packet).hexdigest(),run=str(out),
        generator_commands=0,relay_commands=0,radio_reception_confirmed=False,clock_calibrated=False,**metrics)
    (out/'report.json').write_text(json.dumps(report,indent=2))
    update(stage='rendering actual full-band RF')
    from sdr_lossless_data import render_words
    report=render_words(words,out,report,metrics)
    (out/'report.json').write_text(json.dumps(report,indent=2));update(stage='complete')
    return report
