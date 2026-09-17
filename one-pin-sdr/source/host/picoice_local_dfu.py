"""Local USBIP transport; no relay or generator operations."""
import hashlib,json,socket,struct,time
from pathlib import Path

class LocalUSB:
    def __init__(self,bus,run,default_baud_trial=False):
        policy_path=Path(__file__).resolve().parent/'USB_TRANSPORT_POLICY.json'
        if policy_path.exists():
            policy=json.loads(policy_path.read_text())
            if not policy.get('usb_handoff_enabled',True) and not(default_baud_trial and policy.get('single_session_default_baud_trial')):
                raise RuntimeError('USB handoff disabled to preserve the recovered pico-ice connection')
        self.sock=socket.create_connection(('127.0.0.1',3240),5);self.sock.settimeout(5)
        self.seq=0;self.log=(run/'usb_control.jsonl').open('w')
        try:
            self.sock.sendall(struct.pack('>HHI32s',0x111,0x8003,0,bus.encode()))
            version,opcode,status=struct.unpack('>HHI',self.recv(8))
            if (version,opcode,status)!=(0x111,3,0):raise RuntimeError(f'USBIP import rejected: {version,opcode,status}')
            d=self.recv(312);self.devid=(struct.unpack_from('>I',d,288)[0]<<16)|struct.unpack_from('>I',d,292)[0]
            if struct.unpack_from('>HH',d,300)!=(0x1209,0xb1c0):raise RuntimeError('Wrong USB device')
        except BaseException:self.close();raise
    def recv(self,n):
        result=b''
        while len(result)<n:
            data=self.sock.recv(n-len(result))
            if not data:raise RuntimeError('USBIP socket closed')
            result+=data
        return result
    def control(self,request_type,request,value=0,index=0,length=0,data=b''):
        incoming=bool(request_type&0x80)
        if not incoming:length=len(data)
        if not 0<=length<=4096:raise ValueError('Control transfer too large')
        self.seq+=1
        setup=struct.pack('<BBHHH',request_type,request,value,index,length)
        header=struct.pack('>6I4i',1,self.seq,self.devid,int(incoming),0,0x200 if incoming else 0,length,0,-1,0)
        start=time.perf_counter_ns();self.sock.sendall(header+setup+(b'' if incoming else data))
        ret=self.recv(48);command,seq,*_=struct.unpack_from('>5I',ret)
        status,actual,start_frame,packets,errors=struct.unpack_from('>5i',ret,20)
        if command!=3 or seq!=self.seq or not 0<=actual<=length:raise RuntimeError('USBIP reply framing failed')
        body=self.recv(actual) if incoming else b''
        row={'qpc_start_ns':start,'qpc_end_ns':time.perf_counter_ns(),'setup':setup.hex(),'status':status,
             'actual':actual,'response_hex':body.hex() if actual<=512 else None,'data_sha256':hashlib.sha256(data).hexdigest() if data else None}
        self.log.write(json.dumps(row)+'\n');self.log.flush()
        if status or errors:raise RuntimeError(f'USB control failed status={status}, errors={errors}, setup={setup.hex()}')
        if not incoming and actual!=length:raise RuntimeError('Short USB OUT transfer')
        return body
    def close(self):
        self.sock.close();self.log.close()
