import fs from 'node:fs/promises';
import {FileBlob,PresentationFile} from 'file:///C:/Program%20Files/WindowsApps/OpenAI.CodexPrimaryRuntime.v26-1105-1297-0_26.1105.1297.0_x64__3k8sg7r9htsxt/dependencies/node/node_modules/@oai/artifact-tool/dist/artifact_tool.mjs';
const file='output/presentations/Final Project EDA Presentation - Expanded.pptx';
const p=await PresentationFile.importPptx(await FileBlob.load(file));
await fs.mkdir('.slide_build/final',{recursive:true});
for(let i=0;i<p.slides.items.length;i++){
  const png=await p.export({slide:p.slides.items[i],format:'png',scale:1});
  await fs.writeFile(`.slide_build/final/slide-${i+1}.png`,new Uint8Array(await png.arrayBuffer()));
}
console.log('Rendered final deck:',p.slides.items.length,'slides.');
