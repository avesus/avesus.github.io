// Assemble the human-readable chapters into the single published article.
// Run from any directory: node e310-wpa2-access-point/build-article.mjs
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const root=path.dirname(fileURLToPath(import.meta.url));
const file=name=>path.join(root,name);
const read=name=>fs.readFileSync(file(name),'utf8');
const chapters=[
  ['01-foundations','Vocabulary'],['deadline','The timing barrier'],
  ['design-choice','Why ten microseconds?'],['cpu-only','CPU requirements'],
  ['partition','The hardware boundary'],['02-signal','I/Q and Barker'],
  ['03-physical-packet','Physical packet','transmit'],
  ['04-receiver','Recover bits','receive'],['05-serial-arithmetic','Serial multiplication'],
  ['06-mac-frames','Radio headers'],['12-local-reply','Local ACK / CTS'],
  ['07-joining','Discovery and joining','association'],['08-keys','WPA2 key exchange','keys'],
  ['09-protection','CCMP encryption','data'],['10-addressing','IP, DHCP and ARP','ip'],
  ['11-tcp','TCP, HTTP and sleep','tcp'],['transport','Host transport'],
  ['port','Porting the stack'],['build','Build and run'],['rights','Source and rights']
];
if(process.argv.includes('--import-previous')) {
  if(fs.existsSync(file('article-template.html'))) throw Error('Template already exists; import is one-time.');
  const original=read('index.html');
  const section=id=>{
    const found=original.match(new RegExp(`<section id="${id}">[\\s\\S]*?<\\/section>`));
    if(!found)throw Error(`Missing previous section ${id}`);
    return found[0]+'\n';
  };
  for(const id of ['deadline','design-choice','cpu-only','partition','transport','port','build','rights'])
    fs.writeFileSync(file(`chapters/${id}.html`),section(id));
  const intro=original.match(/<div class="article-intro">[\s\S]*?<\/div>/)?.[0];
  if(!intro)throw Error('Missing introduction');
  fs.writeFileSync(file('chapters/opening.html'),intro+'\n');
  fs.writeFileSync(file('article-template.html'),original.replace(/<main>[\s\S]*?<\/main>/,'<main>\n<!-- ARTICLE -->\n</main>'));
}
let links=[],body=[];
for(const [name,label,alias] of chapters) {
  const chapter=read(`chapters/${name}.html`).trim();
  const id=chapter.match(/^<section id="([^"]+)"/)?.[1];
  if(!id)throw Error(`Missing section ID in ${name}`);
  links.push(`<a href="#${id}">${label}</a>`);
  body.push((alias?`<span id="${alias}" class="anchor-alias" aria-hidden="true"></span>\n`:'')+chapter);
}
const content=read('chapters/opening.html')+'\n<nav class="contents" aria-label="Article contents">'+links.join('\n')+'</nav>\n\n'+body.join('\n\n');
const template=read('article-template.html');
if(template.split('<!-- ARTICLE -->').length!==2)throw Error('Expected one article placeholder');
const html=template.replace('<!-- ARTICLE -->',content).replace('article.css?v=20260910-fit','article.css?v=20260910-manual');
const ids=[...html.matchAll(/\bid="([^"]+)"/g)].map(m=>m[1]);
if(new Set(ids).size!==ids.length)throw Error('Duplicate article IDs');
for(const [,id] of html.matchAll(/href="#([^"]+)"/g))if(!ids.includes(id))throw Error(`Missing anchor ${id}`);
fs.writeFileSync(file('index.html'),html);
const text=html.replace(/<script\b[^>]*>[\s\S]*?<\/script>/g,'').replace(/<[^>]+>/g,' ').replace(/&\w+;/g,' ');
console.log(JSON.stringify({chapters:chapters.length,words:text.trim().split(/\s+/).length,bytes:Buffer.byteLength(html)}));
