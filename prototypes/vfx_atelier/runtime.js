const actors = [
  {name:'Abra', team:0, model:abra, maxHp:32},
  {name:'Pancham', team:0, model:pancham, maxHp:45},
  {name:'Gible', team:1, model:gibleMain, maxHp:60},
  {name:'Gible α', team:1, model:gibleAlpha, maxHp:34},
  {name:'Gible β', team:1, model:gibleBeta, maxHp:34}
].map((a,id) => {
  a.id=id; a.hp=a.maxHp; a.home=a.model.root.position.clone(); a.active=id<3;
  a.burnRemaining=0; a.burnTickAccum=0;
  Object.assign(a.model, {castAnimTimer:0, shudderTimer:0, frozenTint:0, burnTint:0, knockupVelY:0, knockupY:0, customOverride:false});
  a.model.materials=[]; a.model.root.traverse(o=>{if(o.isMesh){o.castShadow=true;o.receiveShadow=true;if(o.material?.emissive)a.model.materials.push(o.material);}});
  a.model.materials=[...new Set(a.model.materials)]; return a;
});
const state={speed:1, paused:false, selected:0, target:2, mode:'single', auto:false, autoIndex:0, autoTime:0, clones:false};
const timeline=new Timeline(); let current=null; const sessions=[];
const moveNames=['Media','Mabufula','Dig','Sand Attack','Dragon Rage','Splitter Flames','Psychic Cannon','Psycho Orb'];
const moveIds=['media','mabufula','dig','sand','dragon','splitter','psychic','psycho-orb'];
const $=id=>document.getElementById(id);
function measure(a) {
  a.model.root.updateWorldMatrix(true,true);
  const box=new THREE.Box3().setFromObject(a.model.root), size=box.getSize(new THREE.Vector3());
  return {height:size.y,radius:Math.max(size.x,size.z)*.5,center:box.getCenter(new THREE.Vector3()),foot:a.home.clone()};
}
function actorView(a,frame) {
  const root=new THREE.Object3D(); root.position.copy(frame.worldToLocal(a.model.root.position.clone()));
  root.quaternion.copy(frame.quaternion.clone().invert().multiply(a.model.root.quaternion)); root.visible=a.model.root.visible;
  return new Proxy(a.model,{get:(m,k)=>k==='root'?root:m[k],set:(m,k,v)=>{m[k]=v;return true;}});
}
function makeContext(id) {
  const attacker=actors[state.selected];
  let targets=[actors[state.target],...actors.filter(a=>a.id!==state.target&&a.id!==attacker.id&&a.team!==attacker.team&&a.active)];
  targets=targets.filter(a=>a&&a.active&&a.id!==attacker.id);
  if (!targets.length) return null;
  if(id===5&&state.mode!=='single'&&targets.length<2){setClones(true);targets=[actors[state.target],...actors.filter(a=>a.id!==state.target&&a.id!==attacker.id&&a.team!==attacker.team&&a.active)];}
  if(id===5&&state.mode!=='single'&&targets.length<2) return null;
  // Selection is a fixture concern; effect transforms know only participants.
  const companion=actors.find(a=>a!==attacker&&a.active&&a.team===attacker.team)||attacker;
  const frame=new THREE.Group();
  frame.position.copy(attacker.home);
  const backward=attacker.home.clone().sub(targets[0].home); backward.y=0; backward.normalize();
  frame.quaternion.setFromRotationMatrix(new THREE.Matrix4().makeBasis(new THREE.Vector3(0,1,0).cross(backward).normalize(),new THREE.Vector3(0,1,0),backward));
  // D-334: rigid frame only. Participant bounds locate sockets, never scale VFX.
  scene.add(frame); frame.updateMatrixWorld(true);
  const c={id,attacker,companion,targets,frame,done:false,start:timeline.time,views:new Map(),mode:state.mode};
  for(const a of new Set([attacker,companion,...targets])) c.views.set(a,actorView(a,frame));
  c.view=a=>c.views.get(a); c.point=a=>frame.worldToLocal(a.home.clone());
  c.center=a=>frame.worldToLocal(measure(a).center.clone());
  c.height=a=>measure(a).height/frame.scale.x;
  c.radius=a=>measure(a).radius/frame.scale.x;
  c.socket=(side=0,height=.62,forward=.9)=>c.point(attacker).add(new THREE.Vector3(side*c.radius(attacker),height*c.height(attacker),-forward*c.radius(attacker)));
  c.vfx=new AtelierParticles(frame); c.light=new THREE.PointLight(0xffffff,0,18);frame.add(c.light);
  c.roles=[targets[0],targets[1]||targets[0],targets[2]||targets[1]||targets[0]].map((a,i)=>({
    id:i, name:a.name, model:c.view(a), slotPos:c.point(a), maxHp:a.maxHp,
    get hp(){return a.hp;},set hp(v){a.hp=v;},get active(){return i===0 || (targets.length>=3 ? true : targets.length>=2&&i===2);},
    get burnRemaining(){return a.burnRemaining;},set burnRemaining(v){a.burnRemaining=v;},
    get burnTickAccum(){return a.burnTickAccum;},set burnTickAccum(v){a.burnTickAccum=v;}
  }));
  // Dual mode addresses roles 1 and 2. Use two distinct real participants.
  if(targets.length===2 && id===5 && c.mode!=='single') c.roles[1]=roleFor(targets[0],1,c);
  c.combat={enemies:c.roles, extraClonesActive:targets.length>1, splitterMode:c.mode, timeScale:1,
    get isCasting(){return c.started&&!c.done;},set isCasting(v){if(v)c.started=true;else c.done=true;},
    get abraHp(){return attacker.hp;},set abraHp(v){attacker.hp=v;},abraMaxHp:attacker.maxHp,
    get panchamHp(){return companion.hp;},set panchamHp(v){if(companion!==attacker)companion.hp=v;},panchamMaxHp:companion.maxHp};
  return c;
}
function roleFor(a,id,c){return {id,name:a.name,model:c.view(a),slotPos:c.point(a),maxHp:a.maxHp,active:true,
  get hp(){return a.hp;},set hp(v){a.hp=v;},get burnRemaining(){return a.burnRemaining;},set burnRemaining(v){a.burnRemaining=v;},get burnTickAccum(){return a.burnTickAccum;},set burnTickAccum(v){a.burnTickAccum=v;}};}
function cast(id){
  if(current || state.paused) return false;
  const c=makeContext(id); if(!c)return false;
  current=c;sessions.push(c); c.moves=createMoves(c);c.moves[id]();updateHUD();return true;
}
function setClones(on){if(current)return;state.clones=on;for(const a of actors.slice(3)){a.active=on;a.model.root.visible=on;}refreshSelectors();updateHUD();}
function updateHUD(){
  for(let i=0;i<3;i++){
    const a=current?.targets[i]||actors[i+2], hud=$(`enemy-hud-${i}`);hud.style.display=a?.active?'flex':'none';
    if(!a)continue;
    hud.querySelector('[data-name]').textContent=a.name;
    $(`enemy-${i}-hp-bar`).style.width=`${100*a.hp/a.maxHp}%`;
    if(i===0)$('enemy-0-hp-ghost').style.width=`${100*a.hp/a.maxHp}%`;
    $(`enemy-${i}-hp-text`).textContent=`HP ${a.hp} / ${a.maxHp}`;
    const pill=$(`enemy-${i}-burn-pill`);pill.classList.toggle('hidden',a.burnRemaining<=0);
    $(`enemy-${i}-burn-text`).textContent=`BURN ${a.burnRemaining.toFixed(1)}s`;
  }
  const allies=[current?.attacker||actors[state.selected],current?.companion||actors.find(a=>a.team===actors[state.selected].team&&a.id!==state.selected)||actors[state.selected]];
  allies.forEach((a,i)=>{const p=i?'pancham':'abra';$(`${p}-hp-bar`).style.width=`${100*a.hp/a.maxHp}%`;$(`${p}-hp-text`).textContent=`HP ${a.hp}/${a.maxHp}`;$(`${p}-name`).textContent=a.name;});
  $('clones-state-text').textContent=state.clones?'ON':'OFF';
  document.querySelectorAll('.skill-btn').forEach(b=>b.disabled=!!current);
  for(const id of ['actor-select','target-select','target-size','btn-toggle-clones','btn-mirror'])$(id).disabled=!!current;
}
function refreshSelectors(){
  const fill=(id,list,val)=>{$(id).replaceChildren(...list.map(a=>{const o=document.createElement('option');o.value=a.id;o.textContent=a.name;return o;}));$(id).value=val;};
  fill('actor-select',actors.filter(a=>a.active),state.selected);
  const eligible=actors.filter(a=>a.active&&a.id!==state.selected);
  if(!eligible.some(a=>a.id===state.target))state.target=eligible[0].id;
  fill('target-select',eligible,state.target);
}
function setCamera(mode='cinema'){
  scene.updateMatrixWorld(true);
  const bounds=new THREE.Box3();actors.filter(a=>a.active).forEach(a=>bounds.union(new THREE.Box3().setFromObject(a.model.root)));
  const center=bounds.getCenter(new THREE.Vector3()),size=bounds.getSize(new THREE.Vector3());
  const axis=actors[state.selected].home.clone().sub(actors[state.target].home).setY(0).normalize();
  const side=new THREE.Vector3(0,1,0).cross(axis);
  const radius=Math.max(size.length()*.53,1), fov=mode==='tatica'?46:43;
  const v=THREE.MathUtils.degToRad(fov/2),h=Math.atan(Math.tan(v)*camera.aspect);
  const dist=radius/Math.sin(Math.min(v,h)) * 1.1;
  const direction=axis.clone().multiplyScalar(mode==='tatica'?.65:1).addScaledVector(side,mode==='impacto'?.38:.08).add(new THREE.Vector3(0,mode==='tatica'?1.3:.32,0)).normalize();
  camera.position.copy(center).addScaledVector(direction,dist);camera.fov=fov;camera.updateProjectionMatrix();camera.lookAt(center);
  state.camera=mode;document.querySelectorAll('.cam-btn').forEach(b=>b.classList.toggle('active',b.dataset.cam===mode));
}
function step(dt){
  timeline.advance(dt,delta=>{
    for(const s of sessions){s.vfx.update(delta);if(!s.done){for(const [a,m]of s.views){a.model.root.position.copy(s.frame.localToWorld(m.root.position.clone()));a.model.root.quaternion.copy(s.frame.quaternion).multiply(m.root.quaternion);a.model.root.visible=m.root.visible;}}}
    for(const a of actors){
      const m=a.model;
      if(a.burnRemaining>0){const active=Math.min(delta,a.burnRemaining);a.burnRemaining=Math.max(0,a.burnRemaining-delta);a.burnTickAccum+=active;
        while(a.burnTickAccum+1e-8>=1){a.burnTickAccum-=1;if(a.hp>0)a.hp=Math.max(0,a.hp-2);}if(a.burnRemaining===0)m.burnTint=0;}
      m.castAnimTimer=Math.max(0,m.castAnimTimer-delta);m.shudderTimer=Math.max(0,m.shudderTimer-delta);
      if(m.knockupY>0||m.knockupVelY!==0){m.knockupY+=m.knockupVelY*delta;m.knockupVelY-=22*delta;if(m.knockupY<=0){m.knockupY=0;m.knockupVelY=0;}}
      if(!m.customOverride){m.bodyGroup.position.set(m.shudderTimer>0?Math.sin(timeline.time*90)*.1:0,m.knockupY+Math.sin(timeline.time*2.8+a.id)*.04,0);}
      for(const mat of m.materials){if(m.frozenTint){mat.emissive.set('#00a8ff');mat.emissiveIntensity=.35;}else if(m.burnTint){mat.emissive.set('#ff5722');mat.emissiveIntensity=.25;}else mat.emissiveIntensity=0;}
    }
  });
  if(current?.done){current.attacker.model.root.position.copy(current.attacker.home);current=null;updateHUD();}
  for(let i=sessions.length-1;i>=0;i--){const s=sessions[i];if(s.done&&timeline.time-s.start>8){s.vfx.dispose();disposeTree(s.frame);s.frame.removeFromParent();sessions.splice(i,1);}}
  if(state.auto&&!current){state.autoTime+=dt;if(state.autoTime>1.25){state.autoTime=0;cast(state.autoIndex++%8);}}
}
moveIds.forEach((id,i)=>$(`btn-cast-${id}`).onclick=()=>cast(i));
document.querySelectorAll('.speed-btn').forEach(b=>b.onclick=()=>{state.speed=Number(b.dataset.speed);document.querySelectorAll('.speed-btn').forEach(x=>x.style.color=x===b?'#d8ff00':'#8294a3');});
document.querySelectorAll('.splitter-mode-btn').forEach(b=>b.onclick=()=>{if(current)return;state.mode=b.dataset.sfmode;document.querySelectorAll('.splitter-mode-btn').forEach(x=>x.classList.toggle('active',x===b));if(state.mode!=='single')setClones(true);});
document.querySelectorAll('.cam-btn').forEach(b=>b.onclick=()=>setCamera(b.dataset.cam));
$('actor-select').onchange=e=>{state.selected=Number(e.target.value);refreshSelectors();updateHUD();};
$('target-select').onchange=e=>{state.target=Number(e.target.value);};
$('target-size').onchange=e=>{actors[state.target].model.root.scale.setScalar(Number(e.target.value));setCamera(state.camera);};
$('btn-mirror').onclick=()=>{[state.selected,state.target]=[state.target,state.selected];refreshSelectors();updateHUD();};
$('btn-pause').onclick=()=>{state.paused=!state.paused;$('btn-pause').textContent=state.paused?'▶ Continuar':'Ⅱ Pausar';};
$('btn-toggle-clones').onclick=()=>setClones(!state.clones);
$('btn-sim-damage').onclick=()=>{actors.filter(a=>a.team===actors[state.selected].team).forEach(a=>a.hp=Math.floor(a.maxHp*.4));updateHUD();};
$('btn-auto-loop').onclick=()=>{state.auto=!state.auto;$('loop-state-text').textContent=state.auto?'ON':'OFF';};
$('btn-toggle-sfx').onclick=()=>{sfx.enabled=!sfx.enabled;$('sfx-state-text').textContent=sfx.enabled?'ON':'MUTE';};
window.addEventListener('keydown',e=>{if(e.repeat||/INPUT|SELECT|TEXTAREA/.test(e.target.tagName))return;if(/^[1-8]$/.test(e.key))cast(Number(e.key)-1);if(e.key.toLowerCase()==='c'){const modes=['cinema','tatica','impacto'];setCamera(modes[(modes.indexOf(state.camera)+1)%3]);}});
window.addEventListener('resize',()=>{camera.aspect=innerWidth/innerHeight;renderer.setSize(innerWidth,innerHeight);composer?.setSize(innerWidth,innerHeight);setCamera(state.camera);});
function projectHUD(){for(let i=0;i<3;i++){const a=current?.targets[i]||actors[i+2];if(!a?.active)continue;const pt=measure(a).center;pt.y+=measure(a).height*.6;pt.project(camera);const hud=$(`enemy-hud-${i}`);hud.style.left=`${(pt.x*.5+.5)*innerWidth}px`;hud.style.top=`${(-pt.y*.5+.5)*innerHeight}px`;hud.style.opacity=pt.z<1&&pt.z>-1?'1':'0';}}
let last=null,accumulator=0;
function advanceReal(raw){
  if(state.paused || !Number.isFinite(raw) || raw<=0)return;
  accumulator+=raw*state.speed;
  while(accumulator>=1/120){step(1/120);accumulator-=1/120;}
}
function render(now){requestAnimationFrame(render);const raw=last===null?0:Math.max(0,Math.min((now-last)/1000,.1));last=now;
  advanceReal(raw);
  updateHUD();projectHUD();
  $('particle-count-readout').textContent=`${sessions.reduce((n,s)=>n+s.vfx.activeParticlesCount,0)} PTCL · QUARKS.JS`;
  if(composer)composer.render();else renderer.render(scene,camera);
}
refreshSelectors();updateHUD();setCamera();requestAnimationFrame(render);
// Deterministic stepping and observations for the regression harness.
window.atelier={cast,step,advanceReal,actors,state,timeline,renderer,get current(){return current;},get sessions(){return sessions;},select(a,t){if(current)throw Error('busy');state.selected=a;state.target=t;refreshSelectors();},setClones,setCamera};
