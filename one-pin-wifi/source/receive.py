"""Replay a one-pin R1 capture through the published Wi-Fi receive path.

Copyright (c) 2026 Brian Greenforest. MIT License; see LICENSE.
This program reads a file only. It does not configure or transmit on hardware.
"""
import argparse
import hashlib
import json
from pathlib import Path
import zlib
import numpy as np
from scipy.fft import rfft, ifft, ifftshift
from scipy.signal import convolve, resample

BARKER = np.repeat([1,-1,1,1,-1,1,1,1,-1,-1,-1],4)
SFD = np.unpackbits(np.array([0xa0,0xf3],dtype=np.uint8),bitorder='little')

def crc16(data):
    c=0xffff
    for b in data:
        c^=b
        for _ in range(8):c=(c>>1)^0x8408 if c&1 else c>>1
    return c^0xffff

def crc32_independent(data):
    c=0xffffffff
    for b in data:
        c^=b
        for _ in range(8):c=(c>>1)^0xedb88320 if c&1 else c>>1
    return c^0xffffffff

def load_raw(path):
    packet=Path(path).read_bytes()
    if len(packet)!=131090 or packet[2:4]!=b'R1':raise ValueError('Expected 131090-byte R1 capture')
    if (sum(packet[:-2])&65535)!=int.from_bytes(packet[-2:],'little'):raise ValueError('R1 transfer checksum failed')
    words=np.frombuffer(packet[16:-2],dtype='<u2')
    x=np.unpackbits(words.astype('>u2').view(np.uint8)).astype(np.float32)*2-1
    return x,hashlib.sha256(packet).hexdigest()

def extract_iq(x,rate,frequency):
    """Same 24 MHz raised-cosine FFT selection as the physical host decode."""
    rf=rfft(x);n=len(x);step=rate/n;center=int(round(frequency/step))
    count=1<<int(np.ceil(np.log2(48e6/step)))
    offsets=(np.arange(count)-count//2)*step
    indexes=center+np.arange(count)-count//2
    spectrum=np.zeros(count,dtype=np.complex64)
    valid=(indexes>0)&(indexes<len(rf));spectrum[valid]=rf[indexes[valid]]
    response=np.zeros(count,dtype=np.float32);half=12e6
    response[abs(offsets)<=half*.8]=1
    skirt=(abs(offsets)>half*.8)&(abs(offsets)<half)
    response[skirt]=.5+.5*np.cos(np.pi*(abs(offsets[skirt])-half*.8)/(half*.2))
    iq=ifft(ifftshift(spectrum*response),workers=1)*(2*count/n);fs=count*step
    iq*=np.exp(2j*np.pi*(center*step-frequency)*np.arange(count)/fs)
    guard=max(4,int(np.ceil(.000002*fs)));iq=iq[guard:-guard]
    return resample(iq,round(len(iq)*44e6/fs))

def valid_frames(decoded):
    for start in np.flatnonzero(np.all(np.lib.stride_tricks.sliding_window_view(decoded,16)==SFD,axis=1)):
        hs=int(start)+16
        if hs+48>len(decoded):continue
        h=np.packbits(decoded[hs:hs+48],bitorder='little').tobytes()
        if h[0]!=10 or crc16(h[:4])!=int.from_bytes(h[4:],'little'):continue
        length=int.from_bytes(h[2:4],'little');bs=hs+48
        if length<32 or length%8 or bs+length>len(decoded):continue
        frame=np.packbits(decoded[bs:bs+length],bitorder='little').tobytes()
        stored=int.from_bytes(frame[-4:],'little')
        if stored!=(zlib.crc32(frame[:-4])&0xffffffff) or stored!=crc32_independent(frame[:-4]):continue
        yield int(start),frame

def decode(x,rate,frequency):
    z=extract_iq(x,rate,frequency);mf=convolve(z,BARKER[::-1],mode='valid')
    # No expected SSID or payload participates in synchronization or decisions.
    for remove_dc in (False,True):
      for window in (4,8,16,24):
       for phase in np.arange(0.,44.,.5):
        pos=np.arange(phase,len(mf)-1,44.)
        symbols=np.interp(pos,np.arange(len(mf)),mf.real)+1j*np.interp(pos,np.arange(len(mf)),mf.imag)
        if remove_dc:symbols-=symbols.mean()
        angle=.5*np.unwrap(np.angle(convolve(symbols*symbols,np.ones(window),mode='same')))
        projected=np.real(symbols*np.exp(-1j*angle))
        differential=(projected[1:]*projected[:-1]<0).astype(np.uint8)
        for inversion in (0,1):
            bits=differential^inversion
            decoded=bits[7:]^bits[3:-4]^bits[:-7]
            for start,frame in valid_frames(decoded):
                return frame,dict(symbol_phase=float(phase),carrier_window_symbols=window,
                    symbol_dc_removed=remove_dc,inversion=inversion,sfd_bit_index=start,
                    corrected_bits=0,plcp_crc16_valid=True,mac_fcs32_valid=True,independent_crc32_valid=True)
    return None,None

def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('capture',type=Path)
    p.add_argument('--if-mhz',type=float,default=67);p.add_argument('--sample-rate',type=float,default=408e6)
    p.add_argument('--output',type=Path,default=Path('decoded'));p.add_argument('--write-private-frame',action='store_true')
    a=p.parse_args();x,digest=load_raw(a.capture);frame,settings=decode(x,a.sample_rate,a.if_mhz*1e6)
    report=dict(capture_sha256=digest,samples=len(x),nominal_sample_rate=a.sample_rate,
        duration_s=len(x)/a.sample_rate,if_hz=a.if_mhz*1e6,decoded=frame is not None,settings=settings)
    if frame:
        report.update(frame_bytes=len(frame),frame_sha256=hashlib.sha256(frame).hexdigest())
    a.output.mkdir(parents=True,exist_ok=True)
    (a.output/'report.json').write_text(json.dumps(report,indent=2))
    if frame and a.write_private_frame:(a.output/'frame.private.bin').write_bytes(frame)
    print(json.dumps(report,indent=2))
    if not frame:raise SystemExit(2)

if __name__=='__main__':main()
