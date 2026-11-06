import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { build } from 'esbuild';

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, '../../..');
const glbPath = path.join(root, 'assets/modelos/dqt_slime/dqt_slime.glb');
const orcPath = path.join(root, 'assets/modelos/dqt_orc/dqt_orc.glb');
const cyclopsPath = path.join(root, 'assets/modelos/dqt_cyclops/dqt_cyclops.glb');

const result = await build({
  entryPoints: [path.join(here, 'main.js')],
  bundle: true,
  write: false,
  format: 'iife',
  minify: true,
  target: ['chrome100'],
  legalComments: 'inline',
});

let app = result.outputFiles[0].text;
const glb64 = fs.readFileSync(glbPath).toString('base64');
app = app.replaceAll('__SLIME_GLB__', `data:model/gltf-binary;base64,${glb64}`);
app = app.replaceAll('__ORC_GLB__', `data:model/gltf-binary;base64,${fs.readFileSync(orcPath).toString('base64')}`);
app = app.replaceAll('__CYCLOPS_GLB__', `data:model/gltf-binary;base64,${fs.readFileSync(cyclopsPath).toString('base64')}`);
app = app.replaceAll('</script', '<\\/script');

let html = fs.readFileSync(path.join(here, 'shell.html'), 'utf8');
html = html.replace('/*__CSS__*/', () => fs.readFileSync(path.join(here, 'style.css'), 'utf8'));
html = html.replace('/*__APP__*/', () => app);

const licenses = [
  'node_modules/three/LICENSE',
  'node_modules/three.quarks/LICENSE',
  'node_modules/quarks.core/LICENSE',
].map((p) => {
  const file = path.join(here, '..', p);
  return fs.existsSync(file) ? `${p}\n${fs.readFileSync(file, 'utf8')}` : '';
}).filter(Boolean).join('\n\n');
html += `\n<!-- Third-party licenses\n${licenses.replaceAll('-->', '-- >')}\n-->\n`;

const out = path.join(here, 'bubble_shield.html');
fs.writeFileSync(out, html);
console.log('Built', out, Buffer.byteLength(html), 'bytes');
