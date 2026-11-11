import * as THREE from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
import { EffectComposer } from 'three/addons/postprocessing/EffectComposer.js';
import { RenderPass } from 'three/addons/postprocessing/RenderPass.js';
import { UnrealBloomPass } from 'three/addons/postprocessing/UnrealBloomPass.js';
import { OutputPass } from 'three/addons/postprocessing/OutputPass.js';
import { EFFECTS, CATEGORIES } from './src/effects/index.js';
import {
  makeDummy, makeTarget, resetDummy, softTexture, disposeGroup, clamp,
  computeStage, resetRandom,
} from './src/helpers.js';

const canvas = document.getElementById('scene');
const renderer = new THREE.WebGLRenderer({
  canvas, antialias: true, alpha: false, powerPreference: 'high-performance',
  preserveDrawingBuffer: true,
});
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.outputColorSpace = THREE.SRGBColorSpace;
renderer.toneMapping = THREE.ACESFilmicToneMapping;
renderer.toneMappingExposure = 1.1;
renderer.shadowMap.enabled = true;
renderer.shadowMap.type = THREE.PCFSoftShadowMap;
renderer.info.autoReset = false;

const scene = new THREE.Scene();
scene.background = new THREE.Color(0x050b12);
scene.fog = new THREE.FogExp2(0x050b12, 0.016);

const camera = new THREE.PerspectiveCamera(42, window.innerWidth / window.innerHeight, 0.1, 140);
camera.position.set(7.0, 4.8, 8.0);

const controls = new OrbitControls(camera, canvas);
controls.enableDamping = true;
controls.dampingFactor = 0.075;
controls.minDistance = 2.0;
controls.maxDistance = 24;
controls.maxPolarAngle = Math.PI * 0.495;
controls.autoRotateSpeed = 0.7;

const hemi = new THREE.HemisphereLight(0x9fdcff, 0x08121a, 1.15);
scene.add(hemi);
const key = new THREE.DirectionalLight(0xfff0d8, 2.3);
key.position.set(4.5, 7.0, 5.0);
key.castShadow = true;
key.shadow.mapSize.set(1024, 1024);
key.shadow.camera.near = 0.5;
key.shadow.camera.far = 28;
key.shadow.camera.left = -10;
key.shadow.camera.right = 10;
key.shadow.camera.top = 10;
key.shadow.camera.bottom = -10;
scene.add(key);
const rimA = new THREE.PointLight(0x55e6ff, 14, 20, 2);
rimA.position.set(-3.5, 2.6, 3.0);
scene.add(rimA);
const rimB = new THREE.PointLight(0xa88bff, 12, 20, 2);
rimB.position.set(3.8, 2.0, -4.0);
scene.add(rimB);

const groundMat = new THREE.MeshStandardMaterial({ color: 0x08131d, roughness: 0.82, metalness: 0.22 });
const ground = new THREE.Mesh(new THREE.PlaneGeometry(70, 70), groundMat);
ground.rotation.x = -Math.PI / 2;
ground.receiveShadow = true;
scene.add(ground);
const grid = new THREE.GridHelper(48, 48, 0x1b5a74, 0x0b2635);
grid.position.y = 0.002;
grid.material.transparent = true;
grid.material.opacity = 0.42;
scene.add(grid);

const dummy = makeDummy();
dummy.castShadow = true;
scene.add(dummy);
const target = makeTarget();
target.castShadow = true;
scene.add(target);

const soft = softTexture();
soft.userData.shared = true;

const ctx = {
  scene, camera, renderer, dummy, target, ground, soft, p: {}, fast: false,
  stage: computeStage(dummy, target),
};

const composer = new EffectComposer(renderer);
composer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
composer.setSize(window.innerWidth, window.innerHeight);
composer.addPass(new RenderPass(scene, camera));
const bloom = new UnrealBloomPass(new THREE.Vector2(window.innerWidth, window.innerHeight), 0.44, 0.62, 0.74);
composer.addPass(bloom);
composer.addPass(new OutputPass());

// ── estado ────────────────────────────────────────────────────────────────
let current = null;
let currentDef = null;
let duration = 1;
let t = 0;
let playing = true;
let loop = true;
let speed = 1;
let dummyOn = true;
let gridOn = true;
let bloomOn = true;
let wireOn = false;
let onlyFx = false;
let lightBg = false;
let activeCategory = 'Todos';
let searchTerm = '';
let stageFlip = 1;      // 1 = alvo em -Z; -1 = espelhado (+Z)
let stageDist = 4.0;
let currentPreset = 'three-quarter';
let pendingSeek = null;
let pendingRebuild = false;
const paramStore = {};
const hiddenLayers = new Set();

const listEl = document.getElementById('list');
const filtersEl = document.getElementById('filters');
const searchEl = document.getElementById('search');
const timeEl = document.getElementById('time');
const timeLabel = document.getElementById('time-label');
const playBtn = document.getElementById('btn-play');
const loopBtn = document.getElementById('btn-loop');
const speedEl = document.getElementById('speed');
const titleEl = document.getElementById('effect-name');
const descEl = document.getElementById('effect-desc');
const catEl = document.getElementById('effect-category');
const statusEl = document.getElementById('status');
const paramsEl = document.getElementById('params');
const layersEl = document.getElementById('layers');
const inspLib = document.getElementById('insp-lib');
const inspFamily = document.getElementById('insp-family');
const inspName = document.getElementById('insp-name');
const inspState = document.getElementById('insp-state');
const inspRef = document.getElementById('insp-ref');
const inspDesc = document.getElementById('insp-desc');
const inspTech = document.getElementById('insp-tech');
const inspDeps = document.getElementById('insp-deps');
const inspLimits = document.getElementById('insp-limits');
const distEl = document.getElementById('stage-dist');
const distLabel = document.getElementById('stage-dist-label');

// ── parâmetros ────────────────────────────────────────────────────────────
function paramsFor(def) {
  if (!paramStore[def.id]) {
    paramStore[def.id] = {};
    for (const ctl of def.controls) paramStore[def.id][ctl.key] = ctl.def;
  }
  return paramStore[def.id];
}

function resetParams(def) {
  paramStore[def.id] = {};
  for (const ctl of def.controls) paramStore[def.id][ctl.key] = ctl.def;
}

const fmt = (v) => (Math.abs(v) >= 10 ? v.toFixed(0) : v.toFixed(2));

// ── reconstrução / reprodução ─────────────────────────────────────────────
function rebuild(def) {
  if (current) {
    scene.remove(current.group);
    disposeGroup(current.group);
  }
  resetRandom(1337);
  resetDummy(dummy);
  resetDummy(target);
  target.position.set(0, 0, -stageDist * stageFlip);
  target.visible = dummyOn;
  dummy.visible = dummyOn;

  currentDef = def;
  ctx.stage = computeStage(dummy, target);
  ctx.p = paramsFor(def);
  ctx.fast = false;
  current = def.create(ctx);
  scene.add(current.group);
  duration = current.duration || def.duration || 1;
  timeEl.max = duration;
  t = 0;
  current.update(0, 0, camera);
  applyWire();
  applyLayerHiding();
}

function loadEffect(def) {
  hiddenLayers.clear();
  rebuild(def);
  playing = true;
  updateUi();
  buildInspector();
  buildLayers();
}

function replay(goal) {
  if (!currentDef) return;
  const g = clamp(goal, 0, duration);
  rebuild(currentDef);
  ctx.fast = true;
  const step = 1 / 60;
  let acc = 0;
  while (acc < g - 1e-6) {
    const d = Math.min(step, g - acc);
    acc += d;
    t = acc;
    current.update(t, d, camera);
  }
  ctx.fast = false;
  t = g;
  current.update(t, 0, camera);
  applyWire();
  applyLayerHiding();
  updateUi();
}

// ── UI ────────────────────────────────────────────────────────────────────
function updateUi() {
  if (!currentDef) return;
  catEl.textContent = currentDef.category.toUpperCase();
  titleEl.textContent = currentDef.name;
  descEl.textContent = currentDef.desc;
  timeLabel.textContent = `${t.toFixed(2)}s`;
  timeEl.value = t;
  playBtn.textContent = playing ? '❚❚' : '▶';
  inspLib.textContent = currentDef.lib;
  inspFamily.textContent = `FAMÍLIA ${currentDef.family}`;
  inspName.textContent = currentDef.name;
  inspState.textContent = currentDef.status;
  inspState.className = 'badge ' + (currentDef.status.startsWith('Refeito') ? 'ok'
    : currentDef.status.startsWith('Aguardando') ? 'legacy' : 'wip');
  inspRef.textContent = currentDef.reference || '—';
  inspDesc.textContent = currentDef.desc;
  inspTech.textContent = currentDef.technique;
  inspDeps.textContent = currentDef.deps;
  inspLimits.textContent = currentDef.limits;
}

function buildFilters() {
  filtersEl.innerHTML = '';
  for (const c of CATEGORIES) {
    const b = document.createElement('button');
    b.textContent = c;
    b.className = c === activeCategory ? 'active' : '';
    b.addEventListener('click', () => {
      activeCategory = c;
      buildFilters();
      buildList();
    });
    filtersEl.appendChild(b);
  }
}

function buildList() {
  listEl.innerHTML = '';
  const q = searchTerm.trim().toLowerCase();
  const items = EFFECTS.filter((e) => {
    const catOk = activeCategory === 'Todos' || e.category === activeCategory;
    const qOk = !q || `${e.lib} ${e.name} ${e.technique} ${e.desc}`.toLowerCase().includes(q);
    return catOk && qOk;
  });
  for (const e of items) {
    const b = document.createElement('button');
    b.innerHTML = `<span class="idx">${e.lib}</span><span class="name">${e.name}</span>`;
    b.className = currentDef?.id === e.id ? 'active' : '';
    b.addEventListener('click', () => {
      loadEffect(e);
      buildList();
    });
    listEl.appendChild(b);
  }
}

function buildInspector() {
  paramsEl.innerHTML = '';
  if (!currentDef.controls.length) {
    const p = document.createElement('p');
    p.className = 'empty';
    p.textContent = 'Sem parâmetros próprios. Use o palco, as camadas e a câmera.';
    paramsEl.appendChild(p);
    return;
  }
  const store = paramsFor(currentDef);
  let lastGroup = '';
  for (const ctl of currentDef.controls) {
    if (ctl.group !== lastGroup) {
      lastGroup = ctl.group;
      const g = document.createElement('div');
      g.className = 'param-group';
      g.textContent = ctl.group;
      paramsEl.appendChild(g);
    }

    if (ctl.type === 'color') {
      const wrap = document.createElement('div');
      wrap.className = 'param color-row';
      const top = document.createElement('div');
      top.className = 'param-top';
      const lab = document.createElement('span');
      lab.textContent = ctl.label;
      const swatch = document.createElement('span');
      swatch.className = 'swatch';
      swatch.style.background = store[ctl.key];
      top.append(lab, swatch);
      const input = document.createElement('input');
      input.type = 'color';
      input.value = store[ctl.key];
      input.addEventListener('input', () => {
        store[ctl.key] = input.value;
        swatch.style.background = input.value;
        ctx.p = store;
        if (current) current.update(t, 0, camera);
      });
      wrap.append(top, input);
      paramsEl.appendChild(wrap);
      continue;
    }

    const wrap = document.createElement('div');
    wrap.className = 'param';
    const top = document.createElement('div');
    top.className = 'param-top';
    const lab = document.createElement('span');
    lab.textContent = ctl.label;
    const val = document.createElement('span');
    val.textContent = fmt(store[ctl.key]);
    top.append(lab, val);

    const input = document.createElement('input');
    input.type = 'range';
    input.min = ctl.min;
    input.max = ctl.max;
    input.step = ctl.step;
    input.value = store[ctl.key];
    input.addEventListener('input', () => {
      const v = parseFloat(input.value);
      store[ctl.key] = v;
      val.textContent = fmt(v);
      ctx.p = store;
      if (ctl.rebuild) pendingRebuild = true;
      else if (current) current.update(t, 0, camera);
    });
    wrap.append(top, input);
    paramsEl.appendChild(wrap);
  }
}

function buildLayers() {
  layersEl.innerHTML = '';
  if (!current) return;
  const kids = current.group.children;
  if (!kids.length) {
    const p = document.createElement('p');
    p.className = 'empty';
    p.textContent = 'Sem camadas isoláveis.';
    layersEl.appendChild(p);
    return;
  }
  kids.forEach((child, i) => {
    const row = document.createElement('label');
    row.className = 'layer';
    const cb = document.createElement('input');
    cb.type = 'checkbox';
    cb.checked = !child.userData.userHidden;
    cb.addEventListener('change', () => {
      child.userData.userHidden = !cb.checked;
      applyLayerHiding();
    });
    const span = document.createElement('span');
    span.textContent = child.name || `${child.type} ${i + 1}`;
    row.append(cb, span);
    layersEl.appendChild(row);
  });
}

function applyLayerHiding() {
  if (!current) return;
  for (const child of current.group.children) {
    if (child.userData.userHidden) child.visible = false;
    else if (child.userData.windowVisible === false) child.visible = false;
    else child.visible = true;
  }
}

function applyWire() {
  if (!current) return;
  current.group.traverse((o) => {
    if (!o.material) return;
    const mats = Array.isArray(o.material) ? o.material : [o.material];
    for (const m of mats) {
      if ('wireframe' in m) m.wireframe = wireOn;
    }
  });
}

function setCameraPreset(name) {
  currentPreset = name;
  const midZ = -stageDist * stageFlip * 0.5;
  const presets = {
    'three-quarter': { pos: [5.2, 3.7, midZ + 7.4], target: [0, 1.2, midZ] },
    side: { pos: [7.6, 2.6, midZ], target: [0, 1.2, midZ] },
    front: { pos: [0.2, 2.8, midZ + 8.4], target: [0, 1.2, midZ] },
    top: { pos: [0.01, 8.6, midZ], target: [0, 0.6, midZ] },
    impact: { pos: [2.6, 2.1, midZ + 3.8 * stageFlip], target: [0, 1.2, midZ - 0.8 * stageFlip] },
  };
  const p = presets[name] || presets['three-quarter'];
  camera.position.set(...p.pos);
  controls.target.set(...p.target);
  controls.update();
  document.querySelectorAll('[data-cam]').forEach((b) => b.classList.toggle('active', b.dataset.cam === name));
}

function applyVisibility() {
  dummy.visible = dummyOn && !onlyFx;
  target.visible = dummyOn && !onlyFx;
  grid.visible = gridOn && !onlyFx;
}

// ── eventos ───────────────────────────────────────────────────────────────
document.getElementById('btn-reset').addEventListener('click', () => setCameraPreset('three-quarter'));
document.getElementById('btn-orbit').addEventListener('click', (e) => {
  controls.autoRotate = !controls.autoRotate;
  e.currentTarget.classList.toggle('active', controls.autoRotate);
});
playBtn.addEventListener('click', () => { playing = !playing; updateUi(); });
document.getElementById('btn-restart').addEventListener('click', () => { pendingSeek = 0; playing = true; });
loopBtn.addEventListener('click', () => {
  loop = !loop;
  loopBtn.classList.toggle('active', loop);
});
speedEl.addEventListener('change', () => { speed = parseFloat(speedEl.value); });
timeEl.addEventListener('input', () => {
  playing = false;
  pendingSeek = clamp(parseFloat(timeEl.value), 0, duration);
  updateUi();
});

document.getElementById('btn-bloom').addEventListener('click', (e) => {
  bloomOn = !bloomOn;
  bloom.enabled = bloomOn;
  e.currentTarget.classList.toggle('active', bloomOn);
});
document.getElementById('btn-grid').addEventListener('click', (e) => {
  gridOn = !gridOn;
  e.currentTarget.classList.toggle('active', gridOn);
  applyVisibility();
});
document.getElementById('btn-dummy').addEventListener('click', (e) => {
  dummyOn = !dummyOn;
  e.currentTarget.classList.toggle('active', dummyOn);
  dummy.visible = dummyOn && !onlyFx;
  target.visible = dummyOn && !onlyFx;
});
document.getElementById('btn-wire').addEventListener('click', (e) => {
  wireOn = !wireOn;
  applyWire();
  e.currentTarget.classList.toggle('active', wireOn);
});
document.getElementById('btn-only').addEventListener('click', (e) => {
  onlyFx = !onlyFx;
  applyVisibility();
  e.currentTarget.classList.toggle('active', onlyFx);
});
document.getElementById('btn-bg').addEventListener('click', (e) => {
  lightBg = !lightBg;
  scene.background.set(lightBg ? 0xdbe7ee : 0x050b12);
  scene.fog.color.set(lightBg ? 0xdbe7ee : 0x050b12);
  groundMat.color.set(lightBg ? 0xbecbd4 : 0x08131d);
  e.currentTarget.classList.toggle('active', lightBg);
});
document.getElementById('btn-flip').addEventListener('click', (e) => {
  const keep = t;
  stageFlip *= -1;
  e.currentTarget.classList.toggle('active', stageFlip === -1);
  rebuild(currentDef);
  replay(keep);
  setCameraPreset(currentPreset);
});
distEl.addEventListener('input', () => {
  stageDist = parseFloat(distEl.value);
  distLabel.textContent = `${stageDist.toFixed(1)} m`;
});
distEl.addEventListener('change', () => {
  const keep = t;
  rebuild(currentDef);
  replay(keep);
  setCameraPreset(currentPreset);
});
document.getElementById('btn-reset-params').addEventListener('click', () => {
  if (!currentDef) return;
  const keep = t;
  resetParams(currentDef);
  rebuild(currentDef);
  replay(keep);
  buildInspector();
});
document.getElementById('btn-all-layers').addEventListener('click', () => {
  if (!current) return;
  for (const child of current.group.children) child.userData.userHidden = false;
  buildLayers();
  applyLayerHiding();
});
searchEl.addEventListener('input', () => {
  searchTerm = searchEl.value;
  buildList();
});
document.querySelectorAll('[data-cam]').forEach((b) => {
  b.addEventListener('click', () => setCameraPreset(b.dataset.cam));
});
window.addEventListener('keydown', (e) => {
  if (e.target.matches('input, select, textarea')) return;
  if (e.code === 'Space') { e.preventDefault(); playing = !playing; updateUi(); }
  if (e.code === 'ArrowLeft') { playing = false; pendingSeek = clamp(t - 0.05, 0, duration); }
  if (e.code === 'ArrowRight') { playing = false; pendingSeek = clamp(t + 0.05, 0, duration); }
  if (e.code === 'KeyR') setCameraPreset('three-quarter');
});

window.addEventListener('resize', () => {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(window.innerWidth, window.innerHeight);
  composer.setSize(window.innerWidth, window.innerHeight);
  bloom.setSize(window.innerWidth, window.innerHeight);
});

// ── loop ──────────────────────────────────────────────────────────────────
const clock = new THREE.Clock();
let fps = 0;
let frames = 0;
let fpsAcc = 0;
let perfAcc = 0;

function animate() {
  requestAnimationFrame(animate);
  const raw = Math.min(clock.getDelta(), 0.05);
  const dt = raw * speed;

  if (pendingRebuild && currentDef) {
    pendingRebuild = false;
    replay(t);
  }
  if (pendingSeek !== null && currentDef) {
    const goal = pendingSeek;
    pendingSeek = null;
    replay(goal);
  }

  if (current && playing) {
    t += dt;
    if (t >= duration) {
      if (loop) {
        rebuild(currentDef);
        playing = true;
        t = 0;
        updateUi();
      } else {
        t = duration;
        playing = false;
      }
    }
    current.update(t, dt, camera);
  } else if (current) {
    current.update(t, 0, camera);
  }

  applyLayerHiding();
  timeEl.value = t;
  timeLabel.textContent = `${t.toFixed(2)}s`;
  if (playing) playBtn.textContent = '❚❚';

  controls.update();
  renderer.info.reset();
  composer.render();

  frames++;
  fpsAcc += raw;
  perfAcc += raw;
  if (fpsAcc >= 0.5) {
    fps = Math.round(frames / fpsAcc);
    frames = 0;
    fpsAcc = 0;
  }
  if (perfAcc >= 0.35) {
    perfAcc = 0;
    const r = renderer.info.render;
    statusEl.textContent = `${currentDef?.lib || '—'} · ${fps} fps · ${r.calls} draws · ${(r.triangles / 1000).toFixed(0)}k tris`;
  }
}

buildFilters();
buildList();
setCameraPreset('three-quarter');
loadEffect(EFFECTS[0]);
animate();

// ── hook de captura/inspeção ──────────────────────────────────────────────
window.__vfx = {
  renderer, scene, camera, controls, composer, bloom, effects: EFFECTS,
  get effectId() { return currentDef?.id; },
  get time() { return t; },
  get duration() { return duration; },
  setEffect(id) {
    const d = EFFECTS.find((e) => e.id === id);
    if (d) { loadEffect(d); buildList(); }
  },
  setTime(value) { playing = false; replay(Number(value) || 0); },
  setCamera(name) { setCameraPreset(name); },
  setStage({ flip = stageFlip, dist = stageDist } = {}) {
    const keep = t;
    stageFlip = flip;
    stageDist = clamp(dist, 2.5, 8);
    rebuild(currentDef);
    replay(keep);
    setCameraPreset(currentPreset);
  },
  setParam(key, value) {
    if (!currentDef) return;
    const ctl = currentDef.controls.find((c) => c.key === key);
    if (!ctl) return;
    paramsFor(currentDef)[key] = clamp(Number(value), ctl.min, ctl.max);
    replay(t);
    buildInspector();
  },
  hideLayer(index, hidden) {
    if (!current) return;
    const child = current.group.children[index];
    if (!child) return;
    child.userData.userHidden = !!hidden;
    applyLayerHiding();
  },
  bench(frames = 300) {
    if (!current) return 0;
    const t0 = performance.now();
    for (let i = 0; i < frames; i++) current.update(i / 60, 1 / 60, camera);
    const ms = (performance.now() - t0) / frames;
    current.update(t, 0, camera);
    return ms;
  },
  capture() {
    composer.render();
    return renderer.domElement.toDataURL('image/png');
  },
};
