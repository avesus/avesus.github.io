"""Full-record, zoomable spectra from actual R1 and lossless C1 packets.

No instrument I/O. Each history row is a separate acquisition. Downsampling
to screen columns retains maxima and mean linear power, never interpolated RF.
"""
import hashlib, json, threading
from collections import OrderedDict
from pathlib import Path
import numpy as np

_cache = OrderedDict()
_columns = OrderedDict()
_lock = threading.Lock()

def capture_paths(state, kind, count):
    current=Path(state['run']);folders=[current]
    index=current.parent.parent/'SDR_HISTORY_SOURCES.json'
    if index.exists():
        digest=json.loads((current/'source_manifest.json').read_text())['bitstream_sha256']
        for name in json.loads(index.read_text()).get('runs',[]):
            p=Path(name)
            if p==current or not p.is_relative_to(current.parent):continue
            if (p/'source_manifest.json').exists() and json.loads((p/'source_manifest.json').read_text()).get('bitstream_sha256')==digest:
                folders.append(p)
    paths=list(p.parent for folder in folders for p in (folder/'sdr').glob('*_'+kind+'/report.json'))
    latest=state['last'].get(kind)
    if latest:
        p=Path(latest['run'])
        if p not in paths:paths.append(p)
        paths=[p for p in paths if json.loads((p/'report.json').read_text())['request_qpc_ns']<=latest['request_qpc_ns']]
    def profile(report):return report.get('bias_profile', (report.get('bias_before_capture') or {}).get('profile'))
    if latest:paths=[p for p in paths if profile(json.loads((p/'report.json').read_text()))==profile(latest)]
    paths.sort(key=lambda p:json.loads((p/'report.json').read_text())['request_qpc_ns'])
    return paths[-count:]

def spectrum(path):
    path = Path(path)
    key = str(path)
    with _lock:
        if key in _cache:
            _cache.move_to_end(key)
            return _cache[key]
    report = json.loads((path / 'report.json').read_text())
    packet = (path / 'packet.bin').read_bytes()
    deep=packet[2:4] in (b'E1',b'E2',b'E3')
    if not deep and (packet[2:4] not in (b'R1',b'C1') or len(packet) != 131090):
        raise ValueError('Expected complete physical R1/C1/E1/E2 capture')
    if hashlib.sha256(packet).hexdigest() != report['packet_sha256']:
        raise ValueError('Packet hash mismatch')
    if not deep and sum(packet[:-2]) & 65535 != int.from_bytes(packet[-2:], 'little'):
        raise ValueError('Packet checksum mismatch')
    rate = report['sample_rate_nominal']
    if packet[2:4] == b'C1' or deep:
        if deep:from sdr_psram_rf_data import decode
        else:from sdr_lossless_data import decode
        words, checked = decode(packet)
        n = len(words)*16
        if n != report['fft_samples'] or not checked['pre_encoding_crc_matched']:
            raise ValueError('C1 source count/CRC mismatch')
        # These are the full-record FFT bins retained by the acquisition owner.
        # Do not recrop RF to a power of two or resample the frequency grid.
        with np.load(path/'full_spectrum.npz') as stored:
            p = stored['psd'].astype(np.float32)
            f = stored['frequency_hz']
            if len(p) != n//2+1 or len(f) != len(p) or not np.allclose(f[[0,1,-1]], [0,rate/n,rate/2]):
                raise ValueError('C1 spectrum length/frequency mismatch')
        enbw = report['fft_enbw_hz']
    else:
        words = np.frombuffer(packet[16:-2], dtype='<u2')
        x = (((words[:, None] >> np.arange(15, -1, -1)) & 1).reshape(-1).astype(float) * 2 - 1)
        x -= x.mean()
        n = len(x); win = np.hanning(n)
        p = np.abs(np.fft.rfft(x * win)) ** 2 / (rate * np.sum(win ** 2))
        p[1:-1] *= 2
        enbw = rate * np.sum(win ** 2) / np.sum(win) ** 2
    value = (report, p.astype(np.float32), rate / n, enbw)
    with _lock:
        _cache[key] = value
        while len(_cache)>1 and sum(v[1].nbytes for v in _cache.values()) > 192*1024*1024:
            _cache.popitem(last=False)
    return value

def view(state, low=0, high=200e6, columns=2048, rows=48, kind=None):
    if not 0 <= low < high <= 200e6 or high-low < 2000:
        raise ValueError('Frequency range must lie in DC..200 MHz and span at least2 kHz')
    if not 128 <= columns <= 4096 or not 1 <= rows <= 64:
        raise ValueError('Invalid display dimensions')
    # Same-record E2 evidence shows a changed input when RAM draining starts.
    # Keep that diagnostic in its own panel; use RAM-idle captures for the
    # normal explorer even when a deep record happens to contain more samples.
    if kind is None:kind='compressed' if state['last'].get('compressed') else 'raw'
    if kind not in ('raw','compressed','deep'):raise ValueError('Choose raw, compressed or deep spectrum')
    latest = state['last'].get(kind)
    if not latest:
        return {'ready': False}
    paths = capture_paths(state,kind,rows)
    reports = [json.loads((p/'report.json').read_text()) for p in paths]
    steps = [r['sample_rate_nominal']/r['samples'] for r in reports]
    # Variable C1 durations give distinct native grids. Pool actual bins into
    # common frequency intervals; never interpolate rows onto another FFT grid.
    # The widest native bin determines the minimum display interval.
    interval_min=2.0**np.ceil(np.log2(max(steps)))
    low_edge = max(low,interval_min)  # Constant DC was removed; omit its bin.
    count = min(columns,max(1,int((high-low_edge)/interval_min)))
    edges_hz = np.linspace(low_edge,high,count+1)
    peaks=[]; means=[]; counts=[]; peak_frequencies=[]
    for path in paths:
        column_key=(str(path),low_edge,high,count)
        with _lock: pooled=_columns.get(column_key)
        if pooled is None:
            r,p,step,enbw = spectrum(path)
            edges=np.clip(np.ceil(edges_hz/step).astype(int),1,len(p))
            width=np.diff(edges)
            if np.any(width<=0):raise ValueError('Empty native frequency interval')
            section=p[edges[0]:edges[-1]];offsets=edges[:-1]-edges[0]
            pf=[float((a+np.argmax(p[a:b]))*step) for a,b in zip(edges[:-1],edges[1:])]
            pooled=(np.maximum.reduceat(section,offsets),np.add.reduceat(section,offsets,dtype=np.float64)/width,width,pf,step,enbw)
            with _lock:
                _columns[column_key]=pooled
                while len(_columns)>256:_columns.popitem(last=False)
        pk,mn,width,pf,step,enbw=pooled
        peaks.append(pk);means.append(mn);counts.append(width)
        if path==paths[-1]:
            peak_frequencies=pf
    peaks=np.asarray(peaks);means=np.asarray(means);counts=np.asarray(counts)
    def db(p): return np.round(10*np.log10(np.maximum(p, 1e-30)), 3).tolist()
    native_f=[];native_db=[]
    if (high-low)/step<=4096:
        _,p,_,_=spectrum(paths[-1])
        a=max(1,int(np.ceil(low/step)));b=min(len(p),int(np.floor(high/step))+1)
        native_f=(np.arange(a,b)*step).tolist();native_db=db(p[a:b])
    # Measure the strongest visible peak on its ORIGINAL native grid. Display
    # pooling and zoom do not manufacture narrower lines or additional RF bits.
    _,latest_psd,_,_=spectrum(paths[-1])
    a=max(1,int(np.ceil(low/step)));b=min(len(latest_psd),int(np.floor(high/step))+1)
    j=a+int(np.argmax(latest_psd[a:b]));hz=j*step
    guard_hz=max(5000,8*enbw);radius_hz=max(20000,16*enbw)
    fa=max(1,int((hz-radius_hz)/step));fb=min(len(latest_psd),int((hz+radius_hz)/step)+1)
    ff=np.arange(fa,fb)*step;pp=latest_psd[fa:fb]
    floor=float(np.mean(pp[abs(ff-hz)>=guard_hz]));peak=float(latest_psd[j])
    level=float(10*np.log10(max(peak,1e-30)/max(floor,1e-30)))
    left=right=j;threshold=floor+(peak-floor)/2
    if peak>floor:
        while left>fa and latest_psd[left-1]>=threshold:left-=1
        while right<fb-1 and latest_psd[right+1]>=threshold:right+=1
    measured=dict(frequency_hz=hz,peak_local_db=level,
        apparent_half_excess_bin_span_hz=(right-left+1)*step if peak>floor else None,
        width_truncated=left==fa or right==fb-1,
        local_mean_flank_psd=floor,flank_inner_hz=guard_hz,flank_outer_hz=radius_hz,
        near_12mhz_comb=hz>=12e6-5000 and abs(hz-round(hz/12e6)*12e6)<5000,
        source_packet_sha256=reports[-1]['packet_sha256'],
        limitation='Apparent source/window width, not receiver adjacent-channel rejection. Contrast is receiver-relative, not calibrated dynamic range.')
    return dict(ready=True, low_hz=low, high_hz=high, bin_hz=step,measured_peak=measured,
        sample_rate_nominal=reports[-1]['sample_rate_nominal'],
        kind=kind, format=reports[-1]['format'],
        enbw_hz=enbw, fft_samples=reports[-1]['samples'], frequency_hz=((edges_hz[:-1]+edges_hz[1:])/2).tolist(),
        latest_peak_frequency_hz=peak_frequencies,
        latest_native_frequency_hz=native_f,latest_native_db=native_db,
        native_bin_range_hz=[min(steps),max(steps)],
        bins_per_column=counts[-1].tolist(), max_bins_per_column=counts.max(axis=0).tolist(),latest_peak_db=db(peaks[-1]),
        latest_mean_db=db(means[-1]), mean_peak_db=db(means.mean(axis=0)),
        waterfall_db=db(peaks), scale='Comparator-relative PSD (dB/Hz)',
        pooling='Actual native-bin maxima per frequency interval; cyan trace averages mean PSD per interval across acquisitions; no spectral interpolation',
        history_time='Each row is one actual acquisition; inter-row intervals are acquisition gaps, not continuous RF',
        captures=[dict(sequence=r['sequence'],request_qpc_ns=r['request_qpc_ns'],
            duration_s=r['duration_s'],one_fraction=r['one_fraction'],
            fft_samples=r['samples'],bin_hz=st,format=r['format'],
            sha256=r['packet_sha256'],run=r['run']) for r,st in zip(reports,steps)],
        physical_adc_bits=1, transported_iq_bits=32, effective_bits_measured=False)
