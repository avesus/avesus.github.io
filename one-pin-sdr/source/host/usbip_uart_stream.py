"""USBIP UART requests with lease servicing and explicit pending-URB cancellation.

Wire format: https://docs.kernel.org/usb/usbip_protocol.html
Published transport used for the retained September 17 recordings.
"""
import hashlib,json,select,struct,time
from pathlib import Path
from picoice_local_dfu import LocalUSB

class UARTUSB(LocalUSB):
    def __init__(self,*args,**kwargs):
        self._pending={};self._done={};self._rx=bytearray();self._lease=False;self._renew=0.;self._poisoned=False
        super().__init__(*args,**kwargs)

    def _log(self,**row):
        self.log.write(json.dumps(row)+'\n');self.log.flush()

    def _submit(self,incoming,ep,length,data=b'',setup=bytes(8),heartbeat=False):
        if self._poisoned:raise RuntimeError('USBIP framing/cancellation failed; no more requests')
        self.seq+=1;seq=self.seq
        self._pending[seq]=dict(kind='submit',incoming=incoming,length=length,heartbeat=heartbeat,start=time.perf_counter_ns())
        h=struct.pack('>6I4i',1,seq,self.devid,int(incoming),ep,0x200 if incoming else 0,length,0,-1,0)+setup
        self.sock.sendall(h+(b'' if incoming else data))
        return seq

    def _receive(self,wait):
        if not select.select([self.sock],[],[],max(0,wait))[0]:return
        b=self.sock.recv(65536)
        if not b:raise RuntimeError('USBIP peer closed')
        self._rx+=b
        while len(self._rx)>=48:
            command,seq=struct.unpack_from('>2I',self._rx)
            request=self._pending.get(seq)
            if request is None:raise RuntimeError('Reply to unknown USBIP sequence '+str(seq))
            status,actual,_,_,errors=struct.unpack_from('>5i',self._rx,20)
            if command==3 and request['kind']=='submit':
                if not 0<=actual<=request['length']:raise RuntimeError('Invalid USBIP actual length')
                n=actual if request['incoming'] else 0
            elif command==4 and request['kind']=='unlink':n=0
            else:raise RuntimeError('USBIP reply type mismatch')
            if len(self._rx)<48+n:return
            body=bytes(self._rx[48:48+n]);del self._rx[:48+n]
            self._pending.pop(seq)
            self._log(sequence=seq,command=command,status=status,actual=actual,errors=errors,qpc_start_ns=request['start'],qpc_end_ns=time.perf_counter_ns(),heartbeat=request.get('heartbeat',False))
            if command==4:
                if status==-104:self._pending.pop(request['target'],None)
                elif status!=0:raise RuntimeError('USBIP cancellation status '+str(status))
            if request.get('heartbeat'):
                if status or errors or actual!=1:raise RuntimeError('Stream lease renewal failed')
            else:self._done[seq]=(status,actual,errors,body)

    def _tick(self):
        now=time.monotonic()
        if self._lease and now>=self._renew and not any(r.get('heartbeat') for r in self._pending.values()):
            self._submit(False,4,1,b'S',heartbeat=True);self._renew=now+.08

    def _cancel(self,target,timeout=.75):
        if target not in self._pending:return
        self.seq+=1;seq=self.seq
        self._pending[seq]=dict(kind='unlink',target=target,start=time.perf_counter_ns())
        self.sock.sendall(struct.pack('>6I',2,seq,self.devid,0,0,target)+bytes(24))
        end=time.monotonic()+timeout
        while seq not in self._done:
            if time.monotonic()>=end:raise TimeoutError('USBIP cancellation acknowledgement timed out')
            self._receive(min(.02,end-time.monotonic()))
        self._done.pop(seq)
        self._done.pop(target,None)

    def _wait(self,seq,timeout):
        end=time.monotonic()+timeout
        try:
            while seq not in self._done:
                if time.monotonic()>=end:
                    self._lease=False
                    self._cancel(seq)
                    raise TimeoutError('USB request timed out; pending URB cancellation completed')
                self._tick();self._receive(min(.02,end-time.monotonic()))
            status,actual,errors,body=self._done.pop(seq)
            if status or errors:raise RuntimeError('USB request failed '+str((status,errors)))
            return actual,body
        except TimeoutError:
            print('USB TRANSFER TIMED OUT; CAPTURE HAS STOPPED. DEVICE STATUS MUST BE CHECKED.',flush=True)
            if seq in self._pending:self._poisoned=True
            raise
        except BaseException:
            self._poisoned=True;raise

    def bulk(self,incoming,data=b'',length=64,endpoint=4):
        if endpoint not in (2,4):raise ValueError('Only status and FPGA UART endpoints are allowed')
        if not incoming:length=len(data)
        if not 0<=length<=4096:raise ValueError('Bulk length outside bound')
        if endpoint==4 and not incoming and data==b'P':self._lease=False
        seq=self._submit(incoming,endpoint,length,data)
        actual,body=self._wait(seq,1.0)
        if not incoming and actual!=length:raise RuntimeError('Short USB OUT')
        if endpoint==4 and not incoming and data==b'S':self._lease=True;self._renew=time.monotonic()+.08
        return body

    def control(self,request_type,request,value=0,index=0,length=0,data=b''):
        incoming=bool(request_type&0x80)
        if request_type==0x21 and request==0x20:raise ValueError('UART baud changes remain prohibited')
        if not incoming:length=len(data)
        if not 0<=length<=4096:raise ValueError('Control length outside bound')
        setup=struct.pack('<BBHHH',request_type,request,value,index,length)
        seq=self._submit(incoming,0,length,data,setup)
        actual,body=self._wait(seq,5.0)
        if not incoming and actual!=length:raise RuntimeError('Short control OUT')
        self._log(control_setup=setup.hex(),actual=actual,response_hex=body.hex() if actual<=512 else None,data_sha256=hashlib.sha256(data).hexdigest() if data else None)
        return body

    def close(self):
        self._lease=False
        if hasattr(self,'sock') and not self._poisoned:
            try:
                for seq in list(self._pending):
                    if seq in self._pending:self._cancel(seq)
            except BaseException as exc:
                self._poisoned=True
                if hasattr(self,'log'):self._log(close_cancellation_error=repr(exc))
        if hasattr(self,'sock'):self.sock.close()
        if hasattr(self,'log'):self.log.close()
