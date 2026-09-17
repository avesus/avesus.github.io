"""Reproduce the published full-band spectrum from the retained physical E3 packet.

No hardware access. Every original RF word is reconstructed and CRC checked.
An optional original full-spectrum cache avoids recomputing the long FFT.
"""
import argparse, hashlib, json
from pathlib import Path
import numpy as np
from scipy.fft import rfft
from matplotlib.figure import Figure
from matplotlib.backends.backend_agg import FigureCanvasAgg
from sdr_psram_rf_data import decode

def reduce_power(power, columns):
    edges=np.linspace(0,len(power),columns+1,dtype=np.int64)
    maximum=np.maximum.reduceat(power,edges[:-1])
    mean=np.add.reduceat(power,edges[:-1])/np.diff(edges)
    return edges,maximum,mean

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output',type=Path,required=True)
    parser.add_argument('--spectrum-cache',type=Path)
    args=parser.parse_args()
    src=Path(__file__).resolve().parents[1]/'fullband'
    report=json.loads((src/'report.json').read_text())
    packet=(src/'packet.bin').read_bytes()
    assert hashlib.sha256(packet).hexdigest()==report['packet_sha256']
    words,check=decode(packet)
    assert check['pre_encoding_crc_matched']
    samples=((words[:,None]>>np.arange(15,-1,-1))&1).reshape(-1).astype(np.int8)
    fs=report['sample_rate_nominal']; n=len(samples)
    assert n==report['fft_samples']
    if args.spectrum_cache:
        with np.load(args.spectrum_cache) as cache:
            p=cache['psd']; f=cache['frequency_hz']
        assert len(p)==n//2+1 and np.allclose(f[[0,1,-1]],[0,fs/n,fs/2])
        del f
    else:
        x=samples.astype(np.float32)*2-1; x-=x.mean()
        window=np.hanning(n).astype(np.float32)
        scale=fs*np.sum(window.astype(np.float64)**2)
        x*=window; del window
        z=rfft(x,workers=2); del x
        p=(z.real.astype(np.float64)**2+z.imag.astype(np.float64)**2)/scale
        p[1:-1]*=2; del z
    columns=8192
    edges,maximum,mean=reduce_power(p,columns)
    frequencies=(edges[:-1]+edges[1:]-1)*.5*fs/n/1e6
    del p
    nfft=262144; window=np.hanning(nfft); scale=fs*np.sum(window**2)
    rows=[]; last=0
    for first in range(0,n-nfft+1,nfft):
        x=samples[first:first+nfft].astype(np.float32)*2-1
        x-=x.mean(); z=rfft(x*window)
        power=np.abs(z)**2/scale; power[1:-1]*=2
        rows.append(reduce_power(power,4096)[1]); last=first+nfft
    waterfall=10*np.log10(np.maximum(rows,1e-30))
    fig=Figure(figsize=(20.48,9),layout='constrained');FigureCanvasAgg(fig)
    grid=fig.add_gridspec(2,1,height_ratios=[1,1.35]);a=fig.add_subplot(grid[0]);b=fig.add_subplot(grid[1])
    fig.suptitle('One-pin SDR: simultaneous DC–204 MHz capture\nNo external LNA · FPGA-only V_REF control · one contiguous 211.227 ms record',fontsize=19)
    a.plot(frequencies,10*np.log10(np.maximum(maximum,1e-30)),color='#166a59',lw=.6,label='Peak retained within each display column')
    a.plot(frequencies,10*np.log10(np.maximum(mean,1e-30)),color='#8491a4',lw=.45,label='Mean linear power within each display column')
    a.set(xlim=(0,204),ylabel='Comparator-relative PSD (dB/Hz)',title='Full-record Hann FFT: 4.734 Hz bin spacing · 7.101 Hz ENBW · 8,192 display columns')
    a.grid(alpha=.2);a.legend(loc='lower right',fontsize=9)
    im=b.imshow(waterfall,origin='lower',aspect='auto',extent=(0,204,0,last/fs*1000),cmap='magma',vmin=float(np.percentile(waterfall,8)),vmax=float(np.percentile(waterfall,99.8)),interpolation='nearest')
    b.set(xlabel='Nominal RF frequency (MHz)',ylabel='Time in the same capture (ms)',title='Contiguous 262,144-sample windows · 1,556.4 Hz FFT bins · peak-preserving display reduction')
    fig.colorbar(im,ax=b,label='Comparator-relative PSD (dB/Hz)',fraction=.018,pad=.01)
    for ax in (a,b):ax.set_xticks(np.arange(0,205,12));ax.tick_params(labelsize=10)
    args.output.parent.mkdir(parents=True,exist_ok=True)
    fig.savefig(args.output,dpi=400,metadata={'Title':'One-pin SDR simultaneous DC–204 MHz physical capture','Author':'Brian Greenforest'})
    print(json.dumps({'output':str(args.output),'rf_samples':n,'crc_matched':True,'fft_bin_hz':fs/n,'waterfall_windows':len(rows),'waterfall_covered_seconds':last/fs},indent=2))

if __name__=='__main__':main()
