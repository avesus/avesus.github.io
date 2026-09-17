"""Expand physical C1 RF runs and check against the pre-encoding hardware CRC."""
import binascii,struct
import numpy as np
from scipy.fft import rfft


def decode(packet):
    count=struct.unpack_from('<H',packet,12)[0]
    if not 1<=count<=32766 or packet[2:4]!=b'C1':raise ValueError('Invalid C1 event count or version')
    pairs=np.frombuffer(packet[16:16+count*4],dtype='<u2').reshape(-1,2)
    lengths=pairs[:,1].astype(np.int64)+1;ends=np.cumsum(lengths)
    n,crc,reserved=struct.unpack_from('<IHH',packet,131080)
    if not 1<=n<=2097152 or ends[-1]!=n or reserved&~1:raise ValueError('C1 sample count/footer mismatch')
    if any(packet[16+count*4:131080]):raise ValueError('Nonzero C1 padding')
    words=np.zeros(n,dtype=np.uint16);words[ends-1]=pairs[:,0]
    checked=binascii.crc_hqx(words.astype('>u2').tobytes(),0xffff)
    if checked!=crc:raise ValueError('Reconstructed RF differs from pre-encoding hardware CRC')
    return words,dict(events=count,rf_words=n,pre_encoding_crc16=crc,reconstructed_crc16=checked,
        pre_encoding_crc_matched=True,samples=n*16,compression_ratio=n*2/131072,
        ram_idle_gated=bool(reserved&1),
        validation='Decoded RF word count and CRC agree with FPGA input before compression; no sample interpolation')


def render(packet,out,report):
    words,metrics=decode(packet)
    return render_words(words,out,report,metrics)


def render_words(words,out,report,metrics):
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    rate=float(report['sample_rate_nominal'])
    bits=np.unpackbits(words.astype('>u2',copy=False).view(np.uint8))
    report.update(metrics,sample_rate_nominal=rate,duration_s=len(bits)/rate,
        one_fraction=float(bits.mean()),transitions=int(np.count_nonzero(np.diff(bits))),
        first_nyquist_max_hz=rate/2,analog_bandwidth_calibrated=False)
    np.savez_compressed(out/'rf_words.npz',words=words,sample_rate_nominal=rate)
    n=len(bits);x=bits.astype(np.float32)*2-1;x-=x.mean();win=np.hanning(n).astype(np.float32)
    energy=np.sum(win.astype(np.float64)**2)
    psd=abs(rfft(x*win,workers=1))**2/(rate*energy);psd[1:-1]*=2
    freq=np.fft.rfftfreq(n,1/rate);enbw=rate*energy/np.sum(win,dtype=np.float64)**2
    report.update(fft_samples=n,fft_bin_hz=rate/n,fft_enbw_hz=enbw,fft_duration_s=n/rate)
    np.savez_compressed(out/'full_spectrum.npz',frequency_hz=freq,psd=psd)
    del x,win
    fig,axes=plt.subplots(3,1,figsize=(20.48,12),layout='constrained')
    edges=np.linspace(0,len(freq),min(8192,len(freq))+1,dtype=np.int64)
    xf=freq[(edges[:-1]+edges[1:])//2]/1e6
    axes[0].plot(xf,10*np.log10(np.maximum([np.max(psd[a:b]) for a,b in zip(edges[:-1],edges[1:])],1e-30)),lw=.65)
    axes[0].set(xlim=(0,200),xlabel='Nominal RF frequency (MHz)',ylabel='Comparator-relative dB/Hz',title='Full-interval spectrum; maximum actual FFT bin per display column')
    ix=np.flatnonzero((freq>=88e6)&(freq<=108e6));groups=np.array_split(ix,min(8192,len(ix)))
    axes[1].plot([freq[g[len(g)//2]]/1e6 for g in groups],10*np.log10(np.maximum([max(psd[g]) for g in groups],1e-30)),lw=.65)
    axes[1].set(xlim=(88,108),xlabel='Nominal RF frequency (MHz)',ylabel='Comparator-relative dB/Hz',title='FM-band detail from the same full-band recording; stations unconfirmed')
    del freq,psd
    size=65536;whole=len(bits)//size;window=np.hanning(size).astype(np.float32)
    # Bound temporary memory without discarding time rows or RF samples.
    p=np.empty((whole,4096),dtype=np.float32)
    for start in range(0,whole,64):
        end=min(whole,start+64)
        blocks=bits[start*size:end*size].reshape(-1,size).astype(np.float32)*2-1
        blocks-=blocks.mean(axis=1,keepdims=True)
        power=2*abs(rfft(blocks*window,axis=1,workers=1))**2/(rate*np.sum(window**2))
        p[start:end]=power[:,:-1].reshape(end-start,4096,8).max(axis=2)
    db=10*np.log10(np.maximum(p,1e-30))
    floor=np.percentile(db,5);ceiling=max(floor+20,np.percentile(db,99.9))
    image=axes[2].imshow(db,origin='lower',aspect='auto',extent=(0,rate/2e6,0,whole*size/rate*1e3),cmap='magma',vmin=floor,vmax=ceiling)
    axes[2].set(xlim=(0,200),xlabel='Nominal RF frequency (MHz)',ylabel='Continuous captured time (ms)',title='Actual within-record waterfall; no stitching across USB gaps')
    fig.colorbar(image,ax=axes[2],label='Comparator-relative dB/Hz')
    fig.suptitle('One-pin SDR · lossless full-band RF acquisition',fontsize=21)
    stopped=' · queue pressure stopped acquisition at an exact word boundary' if metrics.get('queue_pressure_stop') else ''
    fig.supxlabel(f'{len(bits):,} actual RF samples · {len(bits)/rate*1000:.3f} ms continuous · {n:,}-point FFT · {rate/n:.3f} Hz bins / {enbw:.3f} Hz Hann ENBW\nInput CRC matched after decoding · {metrics["compression_ratio"]:.2f}× uncompressed bytes per payload'+stopped+'\nNo FPGA channel narrowing or audio processing',fontsize=11)
    fig.savefig(out/'waterfall.png',dpi=200);plt.close(fig)
    return report
