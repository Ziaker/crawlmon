import {build} from 'esbuild';
import {readFileSync,writeFileSync} from 'node:fs';
const result=await build({entryPoints:['main.js'],bundle:true,platform:'browser',format:'iife',write:false,minify:true,legalComments:'none'});
const html=readFileSync('index.html','utf8').replace('<link rel="stylesheet" href="style.css">',`<style>${readFileSync('style.css','utf8')}</style>`).replace('<script type="module" src="main.js"></script>',`<script>${new TextDecoder().decode(result.outputFiles[0].contents).replaceAll('</script','<\\/script')}</script>`);
writeFileSync('drain_spear.html',html);
console.log('drain_spear.html',Math.round(Buffer.byteLength(html)/1024),'KiB');
