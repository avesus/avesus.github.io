"""F3 exact I/Q decoding, invertible RF retention and independent input CRC."""
import binascii,struct
import numpy as np
from interstage_data import phases

COEFFICIENTS=np.array([-1,0,5,0,-13,0,41,64,41,0,-13,0,5,0,-1],dtype=np.int32)

def unpack(records,first_phase):
    records=np.asarray(records,dtype=np.uint64)
    packed=((records[:,None]>>np.arange(0,64,8,dtype=np.uint64))&255).astype(np.int32).reshape(-1)
    phase=phases(len(records),first_phase,True)
    ti=1-2*(phase>>1);tq=1-2*(phase&1)
    side=2*(((packed&127)^64)-64);center=(2*(packed>>7)-1)*64
    iq=np.column_stack((np.where(ti==tq,center,side),np.where(ti==tq,side,center)))
    return iq.astype(np.int32),side,center,ti,tq

def reference(words,guard,first_phase):
    allwords=np.r_[np.uint16(guard),np.asarray(words,dtype=np.uint16)]
    raw=((allwords[:,None]>>np.arange(15,-1,-1))&1).astype(np.int32).reshape(-1)
    sums=[]
    for maskword in (0x3333,0x9999):
        mask=np.tile((maskword>>np.arange(15,-1,-1))&1,len(allwords))
        x=2*(raw^mask)-1
        sums.append(np.convolve(x,COEFFICIENTS,mode='full')[17:len(raw):2])
    ai,aq=sums;phase=phases(len(words),first_phase,True)
    ti=1-2*(phase>>1);tq=1-2*(phase&1)
    return np.column_stack(((-ai*ti+aq*tq)//2,(ai*tq+aq*ti)//2)).astype(np.int32)

def decode(records,first_phase,guard,lastword,crc):
    iq,side,center,ti,tq=unpack(records,first_phase)
    # Recover odd RF_i signs in chronological order. The current side tap
    # coefficient is -1; all seven previous signs are already known.
    previous=[2*(((guard^0x3333)>>(14-2*j))&1)-1 for j in range(1,8)]
    signs=np.empty(len(side),dtype=np.int32)
    weights=COEFFICIENTS[::2]
    for n,value in enumerate(side*tq):
        old=sum(int(weights[k])*previous[-k] for k in range(1,8))
        signs[n]=old-int(value)
        if signs[n] not in (-1,1):raise ValueError(f'F3 RF inversion failed at complex sample {n}: {signs[n]}')
        previous=previous[1:]+[int(signs[n])]
    count=len(side)*2;raw=np.zeros(count,dtype=np.uint8)
    mask=np.tile(((0x3333>>np.arange(15,-1,-1))&1).astype(np.uint8),len(records))
    raw[1::2]=((signs+1)//2).astype(np.uint8)^mask[1::2]
    # C is delayed by seven RF samples; discard the first three guard evens.
    centersign=(-center*ti)//64
    raw[:count-6:2]=((centersign[3:]+1)//2).astype(np.uint8)^mask[:count-6:2]
    for offset in (5,3,1):raw[count-1-offset]=(lastword>>offset)&1
    words=np.packbits(raw.reshape(-1,16),axis=1,bitorder='big').copy().view('>u2').reshape(-1).astype(np.uint16)
    reconstructed_crc=binascii.crc_hqx(words.astype('>u2').tobytes(),0xffff)
    if int(words[-1])!=lastword:raise ValueError('F3 final raw witness mismatch')
    if reconstructed_crc!=crc:raise ValueError(f'F3 independent RF CRC mismatch: {reconstructed_crc} != {crc}')
    expected=reference(words,guard,first_phase)
    diff=iq.astype(np.int64)-expected
    metrics=dict(checked_complex_samples=len(iq),mismatching_samples=int(np.any(diff!=0,axis=1).sum()),
        maximum_integer_error=int(abs(diff).max()),source_bits=len(raw),input_one_fraction=float(raw.mean()),
        pre_encoding_crc16=crc,reconstructed_crc16=reconstructed_crc,pre_encoding_crc_matched=True,
        actual_range=[int(iq.min()),int(iq.max())],first_guard_raw_word=guard,last_raw_word=lastword,
        comparison='Exact15-tap signed convolution and original four Weaver products; RF recovered from lossless numerical encoding and independently checked against FPGA input CRC and boundary words')
    return iq,raw,expected,metrics

def render(packet,out,report):
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    if len(packet)!=131098 or packet[2:4]!=b'F3':raise ValueError('F3 packet size or magic')
    guard,lastword,crc,flags,delay=struct.unpack_from('<HHHBB',packet,131088)
    if (flags,delay)!=(1,7):raise ValueError('F3 boundary version/latency mismatch')
    phase=(packet[15]>>4)&3
    records=np.frombuffer(packet[16:131088],dtype='<u8')
    iq,raw,expected,metrics=decode(records,phase,guard,lastword,crc)
    if metrics['mismatching_samples']:raise ValueError('F3 physical integer mismatch: '+str(metrics))
    rate=float(report['sample_rate_nominal'])
    report.update(metrics,samples=len(iq),duration_s=len(iq)/rate,first_dds_signs=phase,
        interstage_taps=15,interstage_coefficients=COEFFICIENTS.tolist(),rf_stride=2,
        sample_quadrature=True,second_lo_hz=rate/4,stored_complex_bits=8,
        source_word_pipeline_delay=delay,source_first_fpga_clock=(report['first_fpga_clock']-delay)&0xffffffff,
        storage='Lossless signed7-bit side/2 and1-bit center sign; both full integer components reconstructed; not ADC ENOB')
    np.savez_compressed(out/'interstage_iq.npz',iq=iq,source_rf=raw,expected_iq=expected,
        first_guard_raw_word=guard,coefficients=COEFFICIENTS,sample_rate_nominal=rate)
    fig,ax=plt.subplots(3,1,figsize=(20,12),layout='constrained')
    transitions=np.flatnonzero(np.diff(raw));start=max(0,int(transitions[0]//2)-12) if len(transitions) else 0
    stop=min(len(iq),start+160);t=np.arange(start,stop)/rate*1e6
    for k,name in enumerate(('I','Q')):
        ax[0].plot(t,expected[start:stop,k],lw=1,label=name+' expected from CRC-verified RF')
        ax[0].plot(t,iq[start:stop,k],'.',ms=3,label=name+' captured FPGA output')
    ax[0].set(xlabel='Nominal time within capture (us)',ylabel='Exact integer',title='15-tap matched interstage filter: actual numerical samples and exact expectation')
    ax[0].legend(ncol=2)
    z=(iq[:,0]+1j*iq[:,1])/128;w=np.hanning(len(z))
    psd=abs(np.fft.fftshift(np.fft.fft(z*w)))**2/(rate*np.sum(w*w))
    f=np.fft.fftshift(np.fft.fftfreq(len(z),1/rate))
    ax[1].plot(f/1e6,10*np.log10(np.maximum(psd,1e-30)),lw=.5)
    ax[1].set(xlabel='Second-mixer output frequency (MHz)',ylabel='Receiver-relative dB/Hz',title=f'All {len(z):,} physical complex samples; {rate/len(z):.1f} Hz native FFT bins; coefficient-sum normalization')
    nfft=8192;hop=4096;blocks=np.lib.stride_tricks.sliding_window_view(z,nfft)[::hop];w=np.hanning(nfft)
    wf=abs(np.fft.fftshift(np.fft.fft(blocks*w,axis=1),axes=1))**2/(rate*np.sum(w*w))
    db=10*np.log10(np.maximum(wf,1e-30));lo,hi=np.percentile(db,[10,99.5]);hi=max(hi,lo+10)
    im=ax[2].imshow(db,origin='lower',aspect='auto',extent=(-rate/2e6,rate/2e6,0,len(z)/rate*1e3),vmin=lo,vmax=hi,cmap='magma',interpolation='nearest')
    ax[2].set(xlabel='Second-mixer output frequency (MHz)',ylabel='Within-capture time (ms)',title='Actual filtered I/Q waterfall; no gap filling or interpolated detail')
    fig.colorbar(im,ax=ax[2],label='Receiver-relative dB/Hz')
    fig.suptitle('Wide interstage filtering before Weaver recombination',fontsize=20)
    fig.supxlabel(f'{len(iq):,} exact comparisons, {metrics["mismatching_samples"]} mismatches; independent input CRC matched.\nNominal clocks. Analog passband, source identity and absolute input power are not calibrated.',fontsize=11)
    fig.savefig(out/'waterfall.png',dpi=205);plt.close(fig)
    np.savez(out/'filtered_spectrum.npz',frequency_hz=f,psd=psd,waterfall_psd=wf)
    return report
