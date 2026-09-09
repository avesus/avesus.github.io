// Rebuild the inline source browser and ZIP with Node.js 20+. No npm packages.
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {deflateRawSync} from 'node:zlib';
const here=path.dirname(fileURLToPath(import.meta.url));
const base=path.join(here,'source');
const allowed=/\.(cpp|hpp|h|sv|v|xdc|tcl|cmd|ps1|sh|md|html)$/i;
function walk(dir,prefix='') {
  return fs.readdirSync(dir,{withFileTypes:true}).flatMap(e=>{
    const rel=prefix+e.name;
    if(e.isDirectory()) return ['build','.git','private'].includes(e.name)?[]:walk(path.join(dir,e.name),rel+'/');
    return allowed.test(e.name)||['LICENSE','.gitignore','CMakeLists.txt'].includes(e.name)||rel.startsWith('licenses/') ? [rel] : [];
  });
}
const files=walk(base).sort();
const esc=s=>s.replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('>','&gt;').replaceAll('"','&quot;');
const aliases={
  'e310_host_waveform.hpp':'host-waveform','gf_host_waveform_tx.sv':'waveform-player',
  'gf_dsss_1mbps_rx.sv':'receiver','gf_serial_differential.sv':'serial-adapter',
  'gf_serial_mul40.sv':'serial-multiply','gf_sifs_scheduler.sv':'sifs',
  'gf_low_mac_classifier.sv':'classifier','gf_dsss_1mbps_control_tx.sv':'control-tx',
  'ap_realtime.cpp':'protocol','wifi_protocol.cpp':'crypto',
  'e310_packet_wire.hpp':'wire','e310_packet_ap_core.hpp':'host-core',
  'e310_rx_events.hpp':'rx-events','e310_packet_agent.cpp':'agent'
};
const contents=files.map(rel=>({rel,data:fs.readFileSync(path.join(base,rel))}));
for(const {rel,data} of contents) {
  if(data.includes(0)) throw Error('Unexpected binary file '+rel);
}
const sections=contents.map(({rel,data},i)=>{
  const id=aliases[path.basename(rel)]||'file-'+i;
  return `<details class="source-file" id="${id}" data-name="${esc(rel.toLowerCase())}"><summary>${esc(rel)} · ${data.toString().split('\n').length} lines</summary><p><a href="source/${rel}" download>Download this file</a> · <a href="#${id}">Permanent section link</a></p><pre><code>${esc(data.toString())}</code></pre></details>`;
}).join('\n');
fs.writeFileSync(path.join(here,'source.html'),`<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="robots" content="noindex,follow"><title>Complete source — Greenforest WPA2 access point</title><link rel="stylesheet" href="article.css"></head><body><main><p><a href="./">← Implementation walkthrough</a></p><h1>Every source file, inline</h1><p>${files.length} files. All text below is embedded in this page: no source-viewer service, login or network fetch is needed to expand a file. Build outputs and private configuration are excluded.</p><p><a href="greenforest-wpa2-ap-source.zip" download>Download the full source ZIP</a> · <a href="source/README.md">Build and run instructions</a></p><label for="filter">Find a file</label><input id="filter" type="search" placeholder="receiver, protocol, serial, README…"><p id="count" aria-live="polite"></p>${sections}</main><script>
const filter=document.getElementById('filter'), entries=[...document.querySelectorAll('.source-file')];
filter.addEventListener('input',()=>{let n=0; for(const e of entries){e.hidden=!e.dataset.name.includes(filter.value.toLowerCase());if(!e.hidden)n++;}document.getElementById('count').textContent=n+' files';});
function reveal(){const e=document.getElementById(location.hash.slice(1));if(e?.matches('details')){e.hidden=false;e.open=true;requestAnimationFrame(()=>e.scrollIntoView());}}
addEventListener('hashchange',reveal);reveal();
</script></body></html>`);
// Standard ZIP/deflate, CRC-32, UTF-8 filenames, fixed archive date.
const table=Array.from({length:256},(_,c)=>{for(let i=0;i<8;i++)c=(c&1)?0xedb88320^(c>>>1):c>>>1;return c>>>0;});
const crc=data=>{let c=0xffffffff;for(const b of data)c=table[(c^b)&255]^(c>>>8);return (c^0xffffffff)>>>0;};
let offset=0; const locals=[],central=[];
for(const {rel,data} of contents){
  const name=Buffer.from('greenforest-wpa2-ap/'+rel), packed=deflateRawSync(data,{level:9}), checksum=crc(data);
  const h=Buffer.alloc(30);h.writeUInt32LE(0x04034b50);h.writeUInt16LE(20,4);h.writeUInt16LE(0x800,6);h.writeUInt16LE(8,8);h.writeUInt16LE(((2026-1980)<<9)|(9<<5)|9,12);h.writeUInt32LE(checksum,14);h.writeUInt32LE(packed.length,18);h.writeUInt32LE(data.length,22);h.writeUInt16LE(name.length,26);
  const c=Buffer.alloc(46);c.writeUInt32LE(0x02014b50);c.writeUInt16LE(20,4);h.copy(c,6,4,30);c.writeUInt32LE(offset,42);central.push(c,name);locals.push(h,name,packed);offset+=h.length+name.length+packed.length;
}
const dir=Buffer.concat(central),end=Buffer.alloc(22);end.writeUInt32LE(0x06054b50);end.writeUInt16LE(files.length,8);end.writeUInt16LE(files.length,10);end.writeUInt32LE(dir.length,12);end.writeUInt32LE(offset,16);
const zip=Buffer.concat([...locals,dir,end]);fs.writeFileSync(path.join(here,'greenforest-wpa2-ap-source.zip'),zip);
console.log(JSON.stringify({files:files.length,sourceBytes:contents.reduce((n,e)=>n+e.data.length,0),zipBytes:zip.length}));
