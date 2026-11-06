from pathlib import Path
import re

p=Path(__file__).parent
src=(p/'original.html').read_text(encoding='utf-8-sig')
js=src.split('<script type="module">')[1].split('</script>')[0]
head=js[:js.index('    // 3. BUILT-IN')]
head += '\nimport * as Q from "three.quarks";\nimport noiseGLSL from "./noise3D.glsl";\nimport { OutputPass } from "three/addons/postprocessing/OutputPass.js";\n'
head=head.replace("      if (type === 'glow') {",'''      if(type==='flame'||type==='smoke') {
        const pixels=ctx.createImageData(128,128);
        for(let y=0;y<128;y++)for(let x=0;x<128;x++){
          const u=(x-64)/64,v=y/128;
          const n=Math.sin(x*.19+Math.sin(y*.13)*3)*Math.cos(y*.17+x*.05);
          let a;
          if(type==='flame'){
            const width=.06+Math.sin(v*Math.PI)*.55;
            const axis=Math.sin(v*8)*.17*(1-v);
            const edge=width-Math.abs(u-axis)+n*.07;
            a=Math.max(0,Math.min(1,edge*13))*Math.min(1,v*12)*Math.min(1,(1-v)*12);
          }else{
            const d=Math.hypot(u,(v-.5)*2);
            a=Math.max(0,1-d+n*.12);a=a*a*.65;
          }
          const k=(y*128+x)*4;
          pixels.data[k]=pixels.data[k+1]=pixels.data[k+2]=255;
          pixels.data[k+3]=Math.min(255,a*255);
        }
        ctx.putImageData(pixels,0,0);return new THREE.CanvasTexture(canvas);
      }
      if (type === 'glow') {''')
engine=(p/'engine.js').read_text(encoding='utf-8')
initializer=js[js.index('      _initParticle('):js.index('      spawnAnimatedMesh(')]
engine=engine.replace('  // _initParticle is retained from the supplied source by prepare.py.',initializer)
scene=js[js.index('    const container ='):js.index('    // 6. COMBAT STATE')]
scene=scene.replace('    const vfx = new QuarksVFXEngine(scene);','    const worldScene = scene;')
scene=scene.replace('      composer.addPass(bloomPass);','      composer.addPass(bloomPass);\n      composer.addPass(new OutputPass());')
scene=scene.replace('        0.58,\n        0.45,\n        0.68','        0.30,\n        0.32,\n        0.95')
scene=scene.replace('renderer.toneMappingExposure = 1.12','renderer.toneMappingExposure = 1.0')

helpers=js[js.index('    function showSkillBanner('):js.index('    function setExtraClonesEnabled(')]
helpers=helpers.replace('const proj = worldPos.clone();','const proj = context.frame.localToWorld(worldPos.clone());')
helpers=helpers.replace('String(opacity);','String(opacity * .35);')
helpers=helpers.replace("banner.className = 'block action-banner-anim';","banner.className = 'block';")
helpers=helpers.replace("el.className = 'combat-popup';","el.className = 'combat-popup';\n      el.style.animation = 'none';")
casts=js[js.index('    function spawnSacredHealCircle('):js.index('    // 14. UI EVENT BINDINGS')]
# The old draft's accidental undeclared shader variable.
casts=casts.replace('floatbands =','float bands =').replace(', floatbands)',', bands)')
casts=casts.replace('if (gibleMain.hp <= 8)', 'if (combatState.enemies[0].hp <= 8)')
casts=casts.replace(' / combatState.timeScale','')
casts=casts.replace('dot(vNormal, vViewDir)','dot(normalize(vNormal), normalize(vViewDir))')
casts=casts.replace("{ model: pancham, pos: ALLY_SLOTS['+1'], healAmt: 22 }\n      ];", "...(context.companion !== context.attacker ? [{ model: pancham, pos: ALLY_SLOTS['+1'], healAmt: 22 }] : [])\n      ];")
# All positions are now in the actual attacker's measured local frame.
casts=casts.replace("new THREE.Vector3(0.4, 0, 3.6)","ALLY_SLOTS['-1'].clone().lerp(ALLY_SLOTS['+1'], .5)")
casts=casts.replace("fxLight.position.set(0.4, 3.5, 3.6)","fxLight.position.copy(ALLY_SLOTS['-1']).lerp(ALLY_SLOTS['+1'], .5).add(new THREE.Vector3(0,3.5,0))")
casts=casts.replace("fxLight.position.set(1.8, 3.5, -5.8)","fxLight.position.copy(ENEMY_SLOTS['0']).add(new THREE.Vector3(0,3.5,0))")
casts=casts.replace('new THREE.Vector3(1.6, 0, -6.5)',"ENEMY_SLOTS['0'].clone()")
casts=casts.replace('new THREE.Vector3(-6.5, 1.8, -5.5)',"ENEMY_SLOTS['0'].clone().add(new THREE.Vector3(-context.radius(context.targets[0])*3, context.height(context.targets[0])*.8, 0))")
casts=re.sub(r'const wavePoints = \[.*?\];', "const extent=3.0;\n      const wavePoints=[context.targets.length>1?ENEMY_SLOTS['-2'].clone():ENEMY_SLOTS['0'].clone().add(new THREE.Vector3(-extent*2,0,0)), ENEMY_SLOTS['0'].clone().add(new THREE.Vector3(-extent,0,0)), ENEMY_SLOTS['0'].clone(), ENEMY_SLOTS['0'].clone().add(new THREE.Vector3(extent,0,0)), context.targets.length>2?ENEMY_SLOTS['+2'].clone():ENEMY_SLOTS['0'].clone().add(new THREE.Vector3(extent*2,0,0))];",casts,flags=re.S)
# Emission sockets use bounds, never anatomy or model names.
socket_replacements={
"ALLY_SLOTS['+1'].clone().add(new THREE.Vector3(0, 0.6, -0.4))":"context.socket(0,.27,.5)",
"ALLY_SLOTS['-1'].clone().add(new THREE.Vector3(0.2, 1.65, -1.25))":"context.socket(.15,.72,1.15)",
"ALLY_SLOTS['-1'].clone().add(new THREE.Vector3(0.25, 1.85, -1.15))":"context.socket(.15,.8,1.05)",
"ALLY_SLOTS['-1'].clone().add(new THREE.Vector3(0, 1.35, -0.7))":"context.socket(0,.6,.75)",
"ALLY_SLOTS['-1'].clone().add(new THREE.Vector3(-0.95, 1.48, -0.45))":"context.socket(-1,.65,.5)",
"ALLY_SLOTS['-1'].clone().add(new THREE.Vector3(0.95, 1.48, -0.45))":"context.socket(1,.65,.5)"}
for old,new in socket_replacements.items():casts=casts.replace(old,new)
casts=re.sub(r"ENEMY_SLOTS\['0'\]\.clone\(\)\.add\(new THREE.Vector3\(0, 1\.(?:0|05|1|15), 0\)\)","context.center(context.targets[0])",casts)
casts=casts.replace("ENEMY_SLOTS['-2'].clone().add(new THREE.Vector3(0, 1.0, 0))","context.center(context.targets[1] || context.targets[0])")
casts=casts.replace("ENEMY_SLOTS['+2'].clone().add(new THREE.Vector3(0, 1.0, 0))","context.center(context.targets[2] || context.targets[1] || context.targets[0])")
# Move the demo's target death out of the drawing callback, onto the shared event clock.
start=casts.index("          if (mode === 'retarget' && !retargetTriggered && p >= 0.42) {")
end=casts.index('\n          // Sample positions along curves',start)
block=casts[start:end]
body=block[block.index('{')+1:block.rfind('}')]
casts=casts[:start]+casts[end:]
marker='        const flightDummy = new THREE.Object3D();\n        vfx.spawnAnimatedMesh(flightDummy, flightDuration, (p, m, dt) => {'
# This exact marker is used by Splitter; the other flight routines have different indentation/content.
insert="        if(mode === 'retarget') setTimeout(() => {"+body+"\n        }, flightDuration * .42 * 1000);\n"
idx=casts.index(marker,casts.index('    function castSplitterFlames'))
casts=casts[:idx]+insert+casts[idx:]
casts=casts.replace('new THREE.Vector3(-4.2, 1.35, 0)',"new THREE.Vector3(-leftOrigin.distanceTo(leftTargetInitial)*.34, 1.35, 0)")
casts=casts.replace('new THREE.Vector3(4.2, 1.35, 0)',"new THREE.Vector3(rightOrigin.distanceTo(rightTargetInitial)*.34, 1.35, 0)")

# GLSL smoothstep requires strictly increasing edges on every GPU.
def fix_steps(text):
    pat=re.compile(r'smoothstep\(\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*,')
    for m in list(pat.finditer(text))[::-1]:
        a,b=map(float,m.groups())
        if a<=b:continue
        depth=1;end=m.end()
        while depth:
            if text[end]=='(':depth+=1
            elif text[end]==')':depth-=1
            end+=1
        arg=text[m.end():end-1]
        text=text[:m.start()]+f'(1.0 - smoothstep({m.group(2)}, {m.group(1)}, {arg}))'+text[end:]
    return text
casts=fix_steps(casts)
casts=casts.replace('float alpha = (1.0 - pow(uProgress, 1.4)) * (0.45 + 0.55 * mask);', 'float turbulence=snoise(vec3(vUv*4.0,uTime*3.0));\n            float alpha=(1.0-pow(uProgress,1.4))*smoothstep(.05,.6,mask+turbulence*.35)*smoothstep(.15,.3,r)*(1.0-smoothstep(.65,1.0,r));')
# Ashima simplex library provides subtle material breakup; silhouettes stay identifiable.
def detail(m):
    body=m.group(1)
    if 'varying vec2 vUv;' not in body or 'uniform float uTime;' not in body:return m.group(0)
    noise='''
            float detailNoise = snoise(vec3(vUv * vec2(4.0, 7.0), uTime * .7));
            gl_FragColor.rgb *= .9 + .18 * detailNoise;
            gl_FragColor.a *= .6 + .4 * smoothstep(-.6, .4, detailNoise);
'''
    at=body.rfind('}')
    body=body[:at]+noise+body[at:]
    return 'fragmentShader: `${noiseGLSL}\n'+body+'`'
casts=re.sub(r'fragmentShader: `([^`]*)`',detail,casts)

wrapper='''
function createMoves(context) {
  const scene={add:(...objects)=>context.frame.add(...objects),remove:(...objects)=>{for(const o of objects){o.removeFromParent();disposeTree(o);}}}, vfx=context.vfx, fxLight=context.light;
  // Historical names below are role aliases; any model can occupy either role.
  const abra=context.view(context.attacker);
  const pancham=context.view(context.id===0 ? context.companion : context.attacker);
  const gibleMain=context.roles[0].model, gibleAlpha=context.roles[1].model, gibleBeta=context.roles[2].model;
  const combatState=context.combat;
  const ALLY_SLOTS={'-1':context.point(context.attacker),'+1':context.point(context.id===0?context.companion:context.attacker)};
  const ENEMY_SLOTS={'0':context.roles[0].slotPos,'-2':context.roles[1].slotPos,'+2':context.roles[2].slotPos};
  const setTimeout=(fn,ms)=>timeline.after(ms,fn);
  const updateAllHUDs=updateHUD;
  const setExtraClonesEnabled=()=>{};
  function applyBurnStatus(target){target.burnRemaining=4;target.burnTickAccum=0;target.model.burnTint=1;}
'''
wrapper+=helpers+casts+"\nreturn [castMedia,castMabufula,castDig,castSandAttack,castDragonRage,castSplitterFlames,castPsychicCannon,castPsychoOrb];\n}\n"
(p/'app.js').write_text(head+engine+scene+(p/'runtime.js').read_text(encoding='utf8')+wrapper,encoding='utf8')

shell=src.split('  <script type="module">')[0]
shell=re.sub(r'<script src="https://cdn.tailwindcss.com"></script>','',shell)
shell=re.sub(r'  <link[^>]*>','',shell)
shell=re.sub(r'<script type="importmap">.*?</script>','',shell,flags=re.S)
hud=(p/'restored-hud.html').read_text(encoding='utf8')
shell=shell.replace('  <!-- Screen FX Overlays -->',hud+'\n  <!-- Screen FX Overlays -->')
shell=shell.replace('<style>','<style>\n/* BUNDLED_CSS */\n',1)
shell=shell.replace('</head>', '''<style>
  #skill-cast-banner {position:fixed;top:100px;left:24px;z-index:40;pointer-events:none}
  #cast-timer-widget {top:170px}
  .combat-popup {opacity:1;font-size:12px;transform:translate(-50%,-50%)}
  .skill-btn:disabled {opacity:.45;cursor:default}
  #fixture-controls {position:fixed;top:62px;left:18px;z-index:50;display:flex;gap:7px;align-items:center;flex-wrap:wrap;font:11px monospace}
  #fixture-controls select,#fixture-controls button {background:#102633;color:#dcebf4;border:1px solid #385061;padding:5px 7px}
  #fixture-controls :disabled {opacity:.5}
  #boot-error {position:fixed;inset:30%;z-index:100;background:#26151b;padding:24px;display:none;color:white}
  @media(max-width:650px){#fixture-controls{top:56px;max-width:95vw}.cam-btn{min-width:45px!important;padding:5px!important}#skill-cast-banner{top:145px}.hud-card-enemy{min-width:90px!important}#cast-timer-widget{top:210px}}
</style></head>''')
shell+='''<div id="fixture-controls">
<label>Atacante <select id="actor-select"></select></label>
<label>Alvo <select id="target-select"></select></label>
<button id="btn-mirror">⇄ Trocar lados</button>
<label>Tamanho do alvo <select id="target-size"><option value="1">1×</option><option value="0.65">0,65×</option><option value="1.6">1,6×</option></select></label>
<button id="btn-pause">Ⅱ Pausar</button>
</div><div id="boot-error"></div>
<script>window.addEventListener('error',e=>{const box=document.getElementById('boot-error');box.style.display='block';box.textContent='Erro ao iniciar: '+e.message;});</script>
<script>/* BUNDLED_APP */</script></body></html>'''
(p/'shell.html').write_text(shell,encoding='utf8')
