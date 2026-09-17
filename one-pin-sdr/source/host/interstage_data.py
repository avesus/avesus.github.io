"""Decode and check physical F1 records against their retained RF input bits."""
import numpy as np

def phases(count, first_phase, sample_quadrature=False):
    states=np.array([1,0,2,3],dtype=np.int32)
    start=int(np.flatnonzero(states==first_phase)[0])
    return states[(np.arange(count*8)+start)%4] if sample_quadrature else np.repeat(states[(np.arange(count)+start)%4],8)


def decode(records, first_phase, sample_quadrature=False):
    records=np.asarray(records,dtype=np.uint64)
    words=(records>>48).astype(np.uint16)
    b=((words[:,None]>>np.arange(15,-1,-1))&1).astype(np.int32).reshape(-1)
    iq=np.empty((len(records),8,2),dtype=np.int32)
    for j in range(8):
        for k in range(2):
            v=((records>>(6*j+3*k))&7).astype(np.int32)
            iq[:,j,k]=(v^4)-4
    iq=iq.reshape(-1,2)
    phase=phases(len(records),first_phase,sample_quadrature)
    ti=1-2*(phase>>1);tq=1-2*(phase&1)
    masks=[np.tile(((m>>np.arange(15,-1,-1))&1).astype(np.int32),len(words)) for m in (0x3333,0x9999)]
    sums=[]
    for mask in masks:
        x=2*(b^mask)-1;c=np.r_[0,np.cumsum(x,dtype=np.int64)]
        sums.append((c[4:]-c[:-4])[::2])
    ai,aq=sums
    expected=np.column_stack(((-ai*ti[1:]+aq*tq[1:])//2,(ai*tq[1:]+aq*ti[1:])//2)).astype(np.int32)
    difference=iq[1:]-expected
    metrics=dict(checked_complex_samples=len(expected),mismatching_samples=int(np.count_nonzero(np.any(difference,axis=1))),
        maximum_integer_error=int(abs(difference).max()),first_sample_excluded='Its two preceding RF bits are outside this record',
        actual_range=[int(iq.min()),int(iq.max())],source_bits=len(b),
        input_one_fraction=float(b.mean()),comparison='Exact integer sliding integration and four signed products, no fitting')
    return iq,b,expected,metrics

def render(packet,out,report):
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    records=np.frombuffer(packet[16:-2],dtype='<u8');phase=(packet[15]>>4)&3
    sample_quadrature=packet[2:4]==b'F2'
    iq,b,expected,metrics=decode(records,phase,sample_quadrature)
    rate=float(report['sample_rate_nominal']);report.update(metrics,samples=len(iq),sample_rate_nominal=rate,duration_s=len(iq)/rate,
        first_dds_signs=phase,interstage_taps=4,rf_stride=2,stored_component_bits=3,
        sample_quadrature=sample_quadrature,second_lo_hz=rate/(4 if sample_quadrature else 32),
        storage='Exact packed integer values, expanded to signed32 bits; no information discarded')
    np.savez_compressed(out/'interstage_iq.npz',iq=iq,source_rf=b,expected_iq=expected,sample_rate_nominal=rate)
    fig,ax=plt.subplots(3,1,figsize=(18,11),layout='constrained')
    active=np.flatnonzero(np.any(iq[1:]!=0,axis=1));start=max(1,int(active[0])-16) if len(active) else 1
    stop=min(len(iq),start+192);t=np.arange(start,stop)/rate*1e6
    for k,name in enumerate(('I','Q')):
        ax[0].plot(t,expected[start-1:stop-1,k],lw=1.4,label=name+' expected from same captured RF')
        ax[0].plot(t,iq[start:stop,k],'.',ms=3,label=name+' captured FPGA output')
    ax[0].set(xlabel='Time within capture (us)',ylabel='Exact integer',title='Sliding integration BEFORE the second DDS: captured and expected samples');ax[0].legend(ncol=2)
    z=iq[:,0]+1j*iq[:,1];win=np.hanning(len(z));power=abs(np.fft.fftshift(np.fft.fft(z*win)))**2/(rate*np.sum(win**2));f=np.fft.fftshift(np.fft.fftfreq(len(z),1/rate))/1e6
    ax[1].plot(f,10*np.log10(np.maximum(power,1e-30)),lw=.6);ax[1].set(xlabel='Second-mixer output frequency (MHz)',ylabel='dB(integer²/Hz)',title='Actual complex output spectrum; '+('sample-by-sample quadrature rotation' if sample_quadrature else 'square-wave LO replicas retained'))
    bins=4096;blocks=z.reshape(-1,bins);w=np.hanning(bins);p=abs(np.fft.fftshift(np.fft.fft(blocks*w,axis=1),axes=1))**2/(rate*np.sum(w**2));db=10*np.log10(np.maximum(p,1e-30))
    im=ax[2].imshow(db,origin='lower',aspect='auto',extent=(-rate/2e6,rate/2e6,0,len(z)/rate*1e3),cmap='magma',vmin=-110,vmax=-65);ax[2].set(xlabel='Second-mixer output frequency (MHz)',ylabel='Within-capture time (ms)',title='Physical filtered I/Q waterfall');fig.colorbar(im,ax=ax[2],label='dB(integer²/Hz)')
    fig.suptitle(f'Hardware interstage integration · {report["second_lo_hz"]/1e6:g}MHz '+('sample quadrature' if sample_quadrature else 'word quadrature'),fontsize=19)
    fig.supxlabel(f'{len(expected):,} exact sample comparisons · {metrics["mismatching_samples"]} mismatches · 4 RF taps / stride2 · no accumulator reset\nRF passband and stopband remain to be qualified; not an image-rejection or calibrated input-power result.',fontsize=11)
    fig.savefig(out/'waterfall.png',dpi=200);plt.close(fig)
    return report
