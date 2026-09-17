"""Numeric SDR source lowering and elaborated arithmetic-width gate."""
import json
from pathlib import Path

def dds_init(k):
    # Top nibble lags the low one by12 clocks. Sign replication takes4 more.
    # Preload each nibble at its own logical time, including boundary carries.
    origin=(1<<47)+16*k
    nibbles=sum((((origin-j*k)>>(4*j))&15)<<(4*j) for j in range(13))
    carries=0
    for j in range(12):
        width=4*(j+1);mask=(1<<width)-1
        carries|=((((origin-(j+1)*k)&mask)+(k&mask))>>width)<<j
    return dict(INIT_NIBBLES=f"52'h{nibbles:013x}",INIT_CARRIES=f"12'h{carries:03x}",
                INIT_BIT47=f"1'b{(((1<<47)+4*k)>>47)&1}")

def lower(text, operations):
    """Replace exact, reviewed expressions, then attach explicit resolver cells."""
    declarations=[]
    for number,(expression,width,a,b,ci) in enumerate(operations):
        if expression not in text:raise ValueError('Arithmetic expression changed: '+expression)
        name='explicit_result_'+str(number)
        text=text.replace(expression,name)
        declarations.append(f' wire [{width-1}:0] {name};\n gf_resolve #(.W({width})) explicit_add_{number}({a},{b},{ci},{name},);')
    position=text.rfind('endmodule')
    return text[:position]+'\n'.join(declarations)+'\n'+text[position:]

def numeric_control(source,uart):
    # Obsolete alternate receiver module is not part of this numeric image.
    a=source.index('module fm_pop16(');b=source.index('// R:65536',a)
    source=source[:a]+source[b:]
    a=source.index('module fm_sdr_capture(') if 'module fm_sdr_capture(' in source else source.index('module fm_sdr_capture #')
    prefix,transport=source[:a],source[a:]
    operations=[
      ("clocks+1'b1",32,'clocks',"32'd1","1'b0"),
      ("sequence+1'b1",32,'sequence',"32'd1","1'b0"),
      ("clocks+(raw_mode?32'd1:32'd81)",32,'clocks',"(raw_mode?32'd1:32'd81)","1'b0"),
      ("wr_addr+1'b1",16,'wr_addr',"16'd1","1'b0"),
      ("rd_addr+1'b1",16,'rd_addr',"16'd1","1'b0"),
      ("add_remaining-1'b1",5,'add_remaining',"5'b11111","1'b0"),
      ("baud_counter+1'b1",8,'baud_counter',"8'd1","1'b0"),
      ("byte_index+1'b1",18,'byte_index',"18'd1","1'b0"),
      ("rx_div-1'b1",8,'rx_div',"8'hff","1'b0")]
    source=prefix+lower(transport,operations)
    # These audio registers are deliberately zero in the numeric image.
    uart=uart.replace('comb1<=integ2-delay1','comb1<=0').replace('comb2<=comb1-delay2','comb2<=0')
    assert 'pending_sdm=0,checksum=0;' in uart
    uart=uart.replace('pending_sdm=0,checksum=0;', '''pending_sdm=0;
 wire [15:0] checksum;reg checksum_clear=0,checksum_start=0;reg [7:0] checksum_byte=0;
 gf_serial_checksum16 serial_checksum(clk,checksum_clear,checksum_start,checksum_byte,checksum);''')
    uart=uart.replace("clocks<=clocks+1'b1;", "checksum_clear<=0;checksum_start<=0;clocks<=clocks+1'b1;")
    uart=uart.replace('checksum<=0;', 'checksum_clear<=1;')
    uart=uart.replace('if(byte_index<64) checksum<=checksum+byte_value;', 'if(byte_index<64)begin checksum_start<=1;checksum_byte<=byte_value;end')
    operations=[
      ('pc4+pc5',5,"{1'b0,pc4}","{1'b0,pc5}","1'b0"),
      ('tc4+tc5',5,"{1'b0,tc4}","{1'b0,tc5}","1'b0"),
      ('transition_sum+tc6',19,'transition_sum',"{14'd0,tc6}","1'b0"),
      ('rf_sum+pc6',19,'rf_sum',"{14'd0,pc6}","1'b0"),
      ("clocks+1'b1",32,'clocks',"32'd1","1'b0"),
      ("seq+1'b1",32,'seq',"32'd1","1'b0"),
      ("phase+1'b1",14,'phase',"14'd1","1'b0"),
      ("stream_lease-1'b1",10,'stream_lease',"10'h3ff","1'b0"),
      ("baud_counter+1'b1",8,'baud_counter',"8'd1","1'b0"),
      ("tx_gap-1'b1",10,'tx_gap',"10'h3ff","1'b0"),
      ("byte_index+1'b1",7,'byte_index',"7'd1","1'b0"),
      ("rx_div-1'b1",8,'rx_div',"8'hff","1'b0")]
    return source,lower(uart,operations)

def audit(path):
    net=json.loads(Path(path).read_text());cells=[]
    for name,module in net['modules'].items():
        for label,cell in module.get('cells',{}).items():
            if cell['type'] not in ('$add','$sub','$mul','$macc','$alu'):continue
            widths={k:int(v,2) for k,v in cell['parameters'].items() if k.endswith('_WIDTH')}
            cells.append(dict(module=name,cell=label,type=cell['type'],widths=widths))
    bad=[c for c in cells if max(c['widths'].values(),default=0)>4]
    report=dict(passed=not bad,arithmetic_cells=cells,violations=bad,
                scope='Elaborated optimized active numeric receiver including transport/control; compile-time indices excluded')
    Path(path).with_name('arithmetic_audit.json').write_text(json.dumps(report,indent=2))
    if bad:raise RuntimeError('Inferred wide arithmetic remains: '+str(bad[:5]))
    print(json.dumps(dict(arithmetic_audit_passed=True,cells=len(cells))),flush=True)

def audit_fanout(net):
    checks=[]
    for ch in range(2):
        for component in ('fi','fq'):
            prefix=f'channel{ch}.{component}'
            for level,count in (('a',2),('b',4),('c',8),('copies',16)):
                bits=net['netnames'][prefix+'.'+level]['bits']
                checks.append(dict(net=prefix+'.'+level,unique_register_outputs=len(set(bits)),expected=count))
    if any(c['unique_register_outputs']!=c['expected'] for c in checks):raise RuntimeError('Sign replication tree was merged: '+str(checks))
    return checks

if __name__=='__main__':
    if json.loads(Path('source_manifest.json').read_text()).get('numeric_sdr'):
        audit('arithmetic.json')
