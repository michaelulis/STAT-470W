import fs from 'node:fs/promises';
import path from 'node:path';
import {createHash} from 'node:crypto';
import {finalizePresentation} from 'file:///C:/Users/micha_o0x2g07/.codex/plugins/cache/openai-primary-runtime/presentations/26.1105.12137/skills/presentations/container_tools/artifact_tool_utils.mjs';
const workspaceDir=process.cwd();
process.env.RUNTIME_NODE_MODULES='C:/Program Files/WindowsApps/OpenAI.CodexPrimaryRuntime.v26-1105-1297-0_26.1105.1297.0_x64__3k8sg7r9htsxt/dependencies/node/node_modules';
const SKILL_DIR='C:/Users/micha_o0x2g07/.codex/plugins/cache/openai-primary-runtime/presentations/26.1105.12137/skills/presentations';
const python='C:/Program Files/WindowsApps/OpenAI.CodexPrimaryRuntime.v26-1105-1297-0_26.1105.1297.0_x64__3k8sg7r9htsxt/dependencies/python/python.exe';
const source='C:/Users/micha_o0x2g07/Downloads/Final Project EDA Presentation - Gavin, Michael, Thaddeus.pptx';
const finalPath=path.join(workspaceDir,'output/presentations/Final Project EDA Presentation - Expanded.pptx');
await fs.mkdir(path.dirname(finalPath),{recursive:true});
const result=await finalizePresentation({
  workspaceDir,
  candidatePath:path.join(workspaceDir,'.slide_build/draft/extended-artifact.pptx'),
  finalPath,
  explicitTotalSlideCount:8,
  requiredNativeChartOwnerSlides:[5,6,7],
  requiredNativeTableOwnerSlides:[],
  materializeLiteralChartWorkbooks:true,
  pythonExecutable:python,
  integrityValidatorPath:path.join(SKILL_DIR,'container_tools/inspect_presentation_package_integrity.py'),
  layoutValidatorPath:path.join(SKILL_DIR,'container_tools/inspect_presentation_layout_geometry.py'),
  layoutArgs:['--expected-slide-size-emu','12191675,6858000','--validate-bullet-geometry','--validate-heading-fit'],
  fontPolicy:{basis:'reference',families:['Arial'],referencePath:source,
    referenceSha256:createHash('sha256').update(await fs.readFile(source)).digest('hex')},
  verifyArtifactToolImport:true,
  receiptPath:path.join(workspaceDir,'.slide_build/final-validation.json')
});
console.log(JSON.stringify(result,null,2));
