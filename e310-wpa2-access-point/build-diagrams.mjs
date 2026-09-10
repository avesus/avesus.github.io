// Native SVG field maps; measurements below are byte counts, not proportional widths.
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const root=path.dirname(fileURLToPath(import.meta.url));
const esc=s=>String(s).replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('>','&gt;');
function drawing(name,title,subtitle,rows){
 const h=132+rows.length*132;
 let svg=`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1120 ${h}" width="1120" height="${h}" role="img" aria-labelledby="title desc"><title id="title">${esc(title)}</title><desc id="desc">${esc(subtitle)}</desc><style>text{font-family:Arial,sans-serif;fill:#161616}.title{font-size:30px;font-weight:bold}.sub{font-size:20px}.label{font-size:23px;font-weight:bold}.field{font-size:21px}.count{font-size:19px;fill:#542800}</style><rect width="1120" height="${h}" fill="#fff"/><text class="title" x="30" y="44">${esc(title)}</text><text class="sub" x="30" y="77">${esc(subtitle)}</text>`;
 rows.forEach(([label,fields],r)=>{
  const y=116+r*132,n=fields.length,w=1060/n;
  svg+=`<text class="label" x="30" y="${y}">${esc(label)}</text>`;
  fields.forEach(([a,b],i)=>{
   const x=30+i*w;
   svg+=`<rect x="${x}" y="${y+13}" width="${w-7}" height="77" rx="3" fill="${i%2?'#faf2e7':'#f1f3f4'}" stroke="#a99b8c"/><text class="field" x="${x+12}" y="${y+43}">${esc(a)}</text><text class="count" x="${x+12}" y="${y+71}">${esc(b)}</text>`;
  });
 });
 fs.writeFileSync(path.join(root,name+'.svg'),svg+'</svg>\n');
}
drawing('management-layouts','Management frames: what follows the 24-byte header','Lengths are bytes. Each complete frame ends with a four-byte FCS. Fields are not to scale.',[
 ['Beacon / probe response',[['Timestamp','8'],['Interval','2'],['Capability','2'],['Elements','variable']]],
 ['Probe request',[['SSID element','wildcard or named'],['Rates / other elements','variable']]],
 ['Authentication',[['Algorithm','2: open = 0'],['Transaction','2: request 1, reply 2'],['Status','2: success = 0']]],
 ['Association request',[['Capability','2'],['Listen interval','2'],['Elements','SSID, rates, RSN']]],
 ['Reassociation request',[['Capability','2'],['Listen interval','2'],['Previous AP','6'],['Elements','variable']]],
 ['Association / reassociation response',[['Capability','2'],['Status','2'],['Association ID','2'],['Elements','rates, RSN']]],
 ['Disassociation / deauthentication',[['Reason code','2'],['Following fields','if present']]]
]);
drawing('control-layouts','Immediate and power-save control frames','Frame Control values are shown as transmitted bytes. Lengths are bytes; fields are not to scale.',[
 ['ACK: 14 bytes',[['D4 00','2'],['Duration = 0','2'],['Receiver','6'],['FCS','4']]],
 ['CTS: 14 bytes',[['C4 00','2'],['Remaining time','2'],['Receiver','6'],['FCS','4']]],
 ['RTS: 20 bytes',[['B4 00 + duration','2 + 2'],['Receiver','6'],['Transmitter','6'],['FCS','4']]],
 ['PS-Poll: 20 bytes',[['A4 00 + AID','2 + 2'],['AP address','6'],['Station address','6'],['FCS','4']]]
]);
drawing('key-messages','Four messages establish a pairwise key','The flag words below are big-endian EAPOL values, not Wi-Fi Frame Control values.',[
 ['1. AP → station',[['Flags 008A','no keyed check'],['Replay r','8 bytes'],['ANonce','32 bytes']]],
 ['2. Station → AP',[['Flags 010A','KCK check'],['Replay r','same transaction'],['SNonce + RSN','derive / verify PTK']]],
 ['3. AP → station',[['Flags 13CA','KCK check'],['Replay r + 1','same ANonce'],['Wrapped key data','RSN + GTK']]],
 ['4. Station → AP',[['Flags 030A','KCK check'],['Replay r + 1','confirm install'],['Protected data','may now proceed']]],
 ['PTK: 48 bytes',[['KCK: 16','check EAPOL'],['KEK: 16','wrap key data'],['TK: 16','protect data frames']]]
]);
drawing('protection-layout','What encryption covers','The outer FCS detects radio corruption; the keyed tag authenticates payload and selected header fields.',[
 ['Protected ordinary data frame',[['MAC header','24 readable bytes'],['CCMP header','8 readable bytes'],['Ciphertext','LLC + payload'],['Tag + FCS','8 + 4 bytes']]],
 ['CCMP header: 8 bytes',[['PN0 PN1','low PN bytes'],['00, 20 | ID<<6','reserved / key ID'],['PN2 PN3 PN4 PN5','remaining PN bytes']]],
 ['Nonce: 13 bytes',[['Priority','1 byte'],['Transmitter','6 bytes: Address 2'],['PN5 … PN0','6 bytes, high first']]],
 ['Ordinary AAD: 22 bytes',[['Masked control','2 bytes'],['Addresses 1–3','18 bytes'],['Fragment + zero','2 bytes']]],
 ['Plaintext dispatch',[['AA AA 03 00 00 00','LLC / SNAP prefix'],['08 00 or 08 06','IPv4 or ARP'],['Network message','unencrypted inside CCM']]]
]);
drawing('physical-layout','From frame bytes to the 1 Mb/s waveform','One information bit becomes one 1 µs symbol: 11 spreading chips, represented by 20 I/Q samples.',[
 ['Complete long-preamble physical transmission',[['Training','128 bits'],['Delimiter','16 bits'],['PHY header','48 bits'],['MAC + FCS','8 × N bits']]],
 ['Six-byte physical header',[['SIGNAL 0A','1 byte'],['SERVICE 00','1 byte'],['LENGTH = 8N','2 bytes, low first'],['CRC16','2 bytes, low first']]],
 ['Bit-to-waveform operations',[['Scramble','seven-bit state'],['Differential phase','phase XOR bit'],['Barker signs','11-chip pattern'],['Sample mapping','floor(11s / 20)']]],
 ['Each output sample',[['Choose polarity','Barker sign XOR phase'],['I = +8192 or −8192','signed 16-bit value'],['Q = 0','signed 16-bit value']]]
]);
console.log('Wrote five field-map SVGs.');
