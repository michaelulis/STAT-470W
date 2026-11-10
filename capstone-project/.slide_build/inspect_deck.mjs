import fs from 'node:fs/promises';
import { FileBlob, PresentationFile } from 'file:///C:/Program%20Files/WindowsApps/OpenAI.CodexPrimaryRuntime.v26-1105-1297-0_26.1105.1297.0_x64__3k8sg7r9htsxt/dependencies/node/node_modules/@oai/artifact-tool/dist/artifact_tool.mjs';
const source='C:/Users/micha_o0x2g07/Downloads/Final Project EDA Presentation - Gavin, Michael, Thaddeus.pptx';
await fs.mkdir('.slide_build/source', {recursive:true});
const p=await PresentationFile.importPptx(await FileBlob.load(source));
console.log('Slides',p.slides.items.length);
await fs.writeFile('.slide_build/source/inspection.ndjson',(await p.inspect({kind:'slide,layout,textbox,shape,notes',maxChars:60000})).ndjson);
await fs.writeFile('.slide_build/source/proto.json',JSON.stringify(p.toProto(),null,2));
for(let i=0;i<p.slides.items.length;i++) {
 const png=await p.export({slide:p.slides.items[i],format:'png',scale:1});
 await fs.writeFile(`.slide_build/source/slide-${i+1}.png`,new Uint8Array(await png.arrayBuffer()));
}
console.log('Source rendered');
