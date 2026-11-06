import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { build } from 'esbuild';

const here = path.dirname(fileURLToPath(import.meta.url));
const atelier = path.resolve(here, '..');
const root = path.resolve(here, '../../..');
const glbPath = path.join(root, 'assets/modelos/dqt_slime/dqt_slime.glb');

const result = await build({
  entryPoints: [path.join(here, 'main.js')],
  bundle: true,
  write: false,
  format: 'iife',
  minify: true,
  target: ['chrome100'],
  legalComments: 'none',
});

let app = result.outputFiles[0].text;
const glb64 = fs.readFileSync(glbPath).toString('base64');
app = app.replaceAll('__SLIME_GLB__', `data:model/gltf-binary;base64,${glb64}`);
const caustic64 = fs.readFileSync(path.join(here, 'assets/caustics.png')).toString('base64');
const foam64 = fs.readFileSync(path.join(here, 'assets/foam.png')).toString('base64');
app = app.replaceAll('__CAUSTICS__', `data:image/png;base64,${caustic64}`);
app = app.replaceAll('__FOAMTEX__', `data:image/png;base64,${foam64}`);
app = app.replaceAll('</script', '<\\/script');

let html = fs.readFileSync(path.join(here, 'shell.html'), 'utf8');
html = html.replace('/*__CSS__*/', () => fs.readFileSync(path.join(here, 'style.css'), 'utf8'));
html = html.replace('/*__APP__*/', () => app);

const licenses = [
  'node_modules/@babylonjs/core/LICENSE.md',
  'node_modules/@babylonjs/loaders/LICENSE.md',
].map((rel) => {
  const file = path.join(atelier, rel);
  return fs.existsSync(file) ? `${rel}\n${fs.readFileSync(file, 'utf8')}` : '';
}).filter(Boolean).join('\n\n');

html += `\n<!-- Third-party licenses\n${licenses.replaceAll('-->', '-- >')}\n-->\n`;

const out = path.join(here, 'bubble_shield_babylon.html');
fs.writeFileSync(out, html);
console.log('Built', out, Buffer.byteLength(html), 'bytes');
