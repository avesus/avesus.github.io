"""Decode actual M1 external-RAM readbacks; never replace reads with a verdict."""
import numpy as np


def render(packet,out,report):
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    burst=packet[2:4]==b'M2';count=768 if burst else 96
    if any(packet[16+count*8:-2]):raise ValueError('Nonzero memory-probe padding')
    values=np.frombuffer(packet[16:16+count*8],dtype='<u8')
    records=[]
    for n,v in enumerate(values):
        v=int(v);actual=v&0xffffffff;address=(v>>32)&0xffffff;flags=v>>56;round_number=flags&3
        index=(n//8)%24 if burst else n%24;r=n//192 if burst else n//24
        word=n%8 if burst else 0
        if burst:
            base={0:0,19:0x7fffe0,20:0x3e0,21:0x420,22:0x7ffc00,23:0x7ffe00}.get(index,16<<index)
            expected_address=base+word*4
        else:expected_address=0 if index==0 else 0x7ffffc if index==22 else 0x3fc if index==23 else 2<<index
        expected=0x96e15ca3^(((expected_address&0xffff)<<16)|(expected_address>>8))^(0xffffffff if r&2 else 0)
        records.append(dict(round=round_number,address=address,expected_address=expected_address,
            actual=actual,expected=expected,bit_difference=actual^expected,
            valid=address==expected_address and round_number==r and flags==(word<<2|r) and actual==expected))
    report.update(memory_test=True,records=records,tests=len(records),passed=sum(r['valid'] for r in records),
        all_passed=all(r['valid'] for r in records),spi_clock_hz=25500000,burst_bytes=32 if burst else 4,
        test_scope=('24 blocks,8 words per block,four quad passes' if burst else '24 addresses,four serial/quad mode passes')+'; does not yet test streaming throughput or all8MB',
        radio_reception_confirmed=False)
    fig,ax=plt.subplots(figsize=(13,4),layout='constrained')
    ax.imshow(np.asarray([r['valid'] for r in records]).reshape(4,-1),vmin=0,vmax=1,cmap='RdYlGn',aspect='auto',interpolation='nearest')
    ax.set_yticks(range(4),['Quad pass1','Quad pass2','Quad inverse1','Quad inverse2'] if burst else ['Serial write / serial read','Quad write / quad read','Serial inverse / quad read','Quad inverse / serial read'])
    stride=8 if burst else 1
    ax.set_xticks(np.arange(24)*stride,[f'{r["expected_address"]:06X}' for r in records[:24*stride:stride]],rotation=70)
    ax.set(xlabel='Physical RAM byte address (hex)',title=f'External PSRAM physical readback: {report["passed"]}/{count} exact words matched at25.5MHz; {32 if burst else 4}-byte bursts')
    fig.savefig(out/'memory_readback.png',dpi=200);plt.close(fig)
    return report
