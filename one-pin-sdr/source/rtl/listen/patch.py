from pathlib import Path
import sys,subprocess,json
sys.path.insert(0,'/usr/share/fpga-icestorm/python');import icebox
p=Path(sys.argv[1]);ic=icebox.iceconfig();ic.read_file(str(p/'receiver.asc'))
t=ic.tile(9,0);changes=[]
for r,c in [(1,3),(6,15)]:
 assert t[r][c]=='1'
 t[r]=t[r][:c]+'0'+t[r][c+1:];changes.append([9,0,r,c,1,0])
ic.write_file(str(p/'receiver_pullup.asc'))
subprocess.run(['icepack',str(p/'receiver_pullup.asc'),str(p/'receiver.bin')],check=True)
(p/'pullup_patch.json').write_text(json.dumps(changes))
