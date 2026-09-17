"""Portable entry points for the published one-pin receiver.

Replay never accesses hardware. Capture uses one already-installed bridge and
never changes firmware, baud rate, relays or a signal generator.
"""
import argparse, hashlib, json, shutil, struct, sys
from pathlib import Path
import fm_listen_data, fm_sdr_data

ROOT=Path(__file__).resolve().parents[1]

def replay(output):
    source=ROOT/'recording'; output=output.resolve()
    if output.exists(): raise FileExistsError('Choose a new output directory')
    output.mkdir(parents=True)
    meta=json.loads((source/'report.json').read_text())
    packet=(source/'packet.bin').read_bytes()
    if hashlib.sha256(packet).hexdigest()!=meta['packet_sha256']:
        raise ValueError('Recording hash differs from the published manifest')
    iq,checked=fm_listen_data.decode(packet)
    keys=('format','packet_sha256','bitstream_sha256','frequency_hz',
          'sample_rate_nominal','duration_s','complex_samples')
    report={k:meta[k] for k in keys};report.update(checked,run=str(output))
    (output/'report.json').write_text(json.dumps(report,indent=2))
    (output/'packet.bin').write_bytes(packet)
    fm_listen_data.analyze(output)
    actual=hashlib.sha256((output/'106.5MHz_listen.wav').read_bytes()).hexdigest()
    result={'full_input_crc_matched':checked['input_crc_matched'],
            'complex_samples':len(iq),'wav_sha256':actual,
            'matches_published_wav':actual==meta['audio_sha256']}
    (output/'replay-check.json').write_text(json.dumps(result,indent=2))
    print(json.dumps(result,indent=2))
    if not result['matches_published_wav']:
        raise RuntimeError('WAV bytes differ; retain both and inspect library-version differences')

class SerialTransport:
    def __init__(self,port):
        import serial
        # Select CDC1 (FPGA UART), not CDC0 (bridge status).
        self.port=serial.Serial(port,115200,timeout=1,write_timeout=1)
    def bulk(self,incoming,data=b'',length=64):
        if incoming:return self.port.read(length)
        if self.port.write(data)!=len(data):raise IOError('Short serial write')
        return b''
    def close(self):self.port.close()

def capture(args):
    spec=json.loads((ROOT/'rtl'/args.image/'manifest.json').read_text())
    if args.kind=='listen' and args.image!='listen':
        raise ValueError('J1 listening capture requires the listening image')
    if args.kind=='deep' and args.image!='wideband':
        raise ValueError('E3 full-band capture requires the wideband image')
    if args.kind!='listen' and not spec['sdr_capture'].get(args.kind+'_format'):
        raise ValueError('The selected image does not implement this capture mode')
    output=args.output.resolve()
    if output.exists():raise FileExistsError('Choose a new output directory')
    output.mkdir(parents=True);u=None
    try:
        if args.usbip_bus:
            from usbip_uart_stream import UARTUSB
            u=UARTUSB(args.usbip_bus,output)
            d=u.control(0x80,6,0x100,length=18)
            if len(d)!=18 or struct.unpack_from('<HH',d,8)!=(0x1209,0xb1c0) or struct.unpack_from('<H',d,12)[0]!=0x0200:
                raise RuntimeError('Expected the published buffered bridge v1')
            if u.control(0xa1,0x21,index=2,length=7)!=struct.pack('<IBBB',115200,0,0,8):
                raise RuntimeError('Unexpected line coding; it was not changed')
            u.control(0x21,0x22,3,index=2)
        else:u=SerialTransport(args.port)
        u.bulk(False,b'P')
        if args.arm_bias:u.bulk(False,str(args.profile).encode()+b'G')
        target=output/'capture'
        if args.kind=='listen':
            fm_listen_data.capture(u,spec,target);fm_listen_data.analyze(target)
        else:fm_sdr_data.capture(u,spec,target,args.kind)
    finally:
        if u is not None:
            try:
                if not getattr(u,'_poisoned',False):u.bulk(False,b'P')
            finally:u.close()

def main():
    p=argparse.ArgumentParser(description=__doc__);sub=p.add_subparsers(dest='command',required=True)
    r=sub.add_parser('replay');r.add_argument('--output',type=Path,default=Path('replayed-recording'))
    c=sub.add_parser('capture');connection=c.add_mutually_exclusive_group(required=True)
    connection.add_argument('--port');connection.add_argument('--usbip-bus')
    c.add_argument('--image',choices=('listen','wideband'),required=True)
    c.add_argument('--kind',choices=('listen','raw','filtered','deep'),required=True)
    c.add_argument('--output',type=Path,required=True)
    c.add_argument('--arm-bias',action='store_true',help='Enable the published short low-only pulse controller after wiring review')
    c.add_argument('--profile',type=int,choices=range(8),default=5)
    a=p.parse_args()
    if a.command=='replay':replay(a.output)
    else:capture(a)

if __name__=='__main__':main()
