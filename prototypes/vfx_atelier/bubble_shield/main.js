import * as THREE from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import { clone as cloneSkeleton } from 'three/addons/utils/SkeletonUtils.js';
import { EffectComposer } from 'three/addons/postprocessing/EffectComposer.js';
import { RenderPass } from 'three/addons/postprocessing/RenderPass.js';
import { UnrealBloomPass } from 'three/addons/postprocessing/UnrealBloomPass.js';
import * as Q from 'three.quarks';

// ---------------------------------------------------------------------------
// D-323 Bubble Shield / protÃ³tipo visual isolado (HTML + three.quarks).
// Nada aqui altera o jogo Godot: Ã© um laboratÃ³rio de arte com 3 leituras.
// Regras da ficha: status, Ãgua, ALL ALLIES, 3 ATB, wind-up 0,7 s,
// 25 + MAG por aliado, 8 s, reserva individual, SEM TIPO (resposta do criador).
// ---------------------------------------------------------------------------

const SLIME_GLB = '__SLIME_GLB__';
const ORC_GLB = '__ORC_GLB__';
const CYCLOPS_GLB = '__CYCLOPS_GLB__';
const WINDUP = 0.7;
const DURATION = 8.0;
const MAG_DEMO = 9;
const SHIELD_MAX = 25 + MAG_DEMO;
const HIT_DAMAGE = 15;
const ALLY_POSITIONS = [
  new THREE.Vector3(-4.0, 0, 0.15),
  new THREE.Vector3(0, 0, 0.55),
  new THREE.Vector3(4.0, 0, 0.15),
];
const ALLY_NAMES = ['ORC', 'SLIME', 'CYCLOPS'];
const PARTY = [
  {
    name: 'ORC', glb: ORC_GLB, targetH: 1.90, pos: ALLY_POSITIONS[0],
    idle: 'cm_00_0020_00', cast: 'cm_00_0020_10',
  },
  {
    name: 'SLIME', glb: SLIME_GLB, targetH: 1.42, pos: ALLY_POSITIONS[1],
    idle: 'cm_00_0000_00', cast: 'cm_00_0000_10',
  },
  {
    name: 'CYCLOPS', glb: CYCLOPS_GLB, targetH: 2.60, pos: ALLY_POSITIONS[2],
    idle: 'cm_00_0065_00', cast: 'cm_00_0065_10',
  },
];
const TAU = Math.PI * 2;

const clamp = (v, a, b) => Math.max(a, Math.min(b, v));
const lerp = (a, b, t) => a + (b - a) * t;
const easeOutCubic = (t) => 1 - Math.pow(1 - t, 3);
const easeOutBack = (t) => 1 + 2.7 * Math.pow(t - 1, 3) + 1.7 * Math.pow(t - 1, 2);
const smoothstep = (a, b, x) => {
  const t = clamp((x - a) / (b - a), 0, 1);
  return t * t * (3 - 2 * t);
};

const ui = {
  options: [...document.querySelectorAll('#options button')],
  cast: document.getElementById('castBtn'),
  hit: document.getElementById('hitBtn'),
  break: document.getElementById('breakBtn'),
  expire: document.getElementById('expireBtn'),
  mirror: document.getElementById('mirrorBtn'),
  reset: document.getElementById('resetBtn'),
  allies: document.getElementById('allies'),
  phase: document.getElementById('phaseLabel'),
  fill: document.getElementById('phaseFill'),
  mark: document.getElementById('phaseMark'),
  clock: document.getElementById('clock'),
  toast: document.getElementById('toast'),
};

const state = {
  option: 'A',
  mode: 'idle', // idle | windup | active | broken | expired
  phaseT: 0,
  timer: DURATION,
  shieldHP: [SHIELD_MAX, SHIELD_MAX, SHIELD_MAX],
  shielded: [false, false, false],
  mirrored: false,
  paused: false,
  loading: true,
};

// Escudos continuam sendo atualizados mesmo depois de rompidos/expirados (a animaÃ§Ã£o
// de saÃ­da nÃ£o pode congelar quando ch.shield vira null).
const activeShields = new Set();
const formationFX = [];
let autoCastTimer = 0;

// ---------------------------------------------------------------------------
// Renderer / cena / cÃ¢mera
// ---------------------------------------------------------------------------

const canvas = document.getElementById('scene');
const renderer = new THREE.WebGLRenderer({ canvas, antialias: true, powerPreference: 'high-performance' });
renderer.setPixelRatio(Math.min(devicePixelRatio, 2));
renderer.setSize(innerWidth, innerHeight);
renderer.outputColorSpace = THREE.SRGBColorSpace;
renderer.toneMapping = THREE.ACESFilmicToneMapping;
renderer.toneMappingExposure = 1.02;
renderer.shadowMap.enabled = true;
renderer.shadowMap.type = THREE.PCFSoftShadowMap;

const scene = new THREE.Scene();
scene.background = new THREE.Color(0x050b12);
scene.fog = new THREE.FogExp2(0x050b12, 0.036);

// Céu de estúdio: gradiente escuro com horizonte verde-azulado.
{
  const sky = new THREE.Mesh(
    new THREE.SphereGeometry(42, 32, 16),
    new THREE.ShaderMaterial({
      side: THREE.BackSide,
      depthWrite: false,
      uniforms: {
        cLow: { value: new THREE.Color(0x0b2632) },
        cHigh: { value: new THREE.Color(0x02050a) },
      },
      vertexShader: `varying vec3 vDir; void main(){ vDir = normalize(position); gl_Position = projectionMatrix * modelViewMatrix * vec4(position,1.0); }`,
      fragmentShader: `uniform vec3 cLow; uniform vec3 cHigh; varying vec3 vDir;
        void main(){ float h = smoothstep(-0.08, 0.55, vDir.y); vec3 c = mix(cLow, cHigh, h); gl_FragColor = vec4(c, 1.0); }`,
    }),
  );
  scene.add(sky);
}

const camera = new THREE.PerspectiveCamera(43, innerWidth / innerHeight, 0.05, 80);
camera.position.set(0, 5.2, 17.5);

const controls = new OrbitControls(camera, canvas);
controls.target.set(0, 1.45, 0.2);
controls.enableDamping = true;
controls.dampingFactor = 0.07;
controls.minDistance = 6.0;
controls.maxDistance = 30;
controls.minPolarAngle = 0.55;
controls.maxPolarAngle = 1.52;
controls.enablePan = false;
controls.update();

const composer = new EffectComposer(renderer);
composer.addPass(new RenderPass(scene, camera));
const bloom = new UnrealBloomPass(new THREE.Vector2(innerWidth, innerHeight), 0.52, 0.7, 0.82);
composer.addPass(bloom);

// Luzes
const hemi = new THREE.HemisphereLight(0xa8e8ff, 0x07121b, 1.15);
scene.add(hemi);
const key = new THREE.DirectionalLight(0xffffff, 2.3);
key.position.set(4.5, 8, 6);
key.castShadow = true;
key.shadow.mapSize.set(2048, 2048);
key.shadow.camera.near = 0.5;
key.shadow.camera.far = 26;
key.shadow.camera.left = -8;
key.shadow.camera.right = 8;
key.shadow.camera.top = 8;
key.shadow.camera.bottom = -6;
key.shadow.bias = -0.0008;
scene.add(key);
const rim = new THREE.DirectionalLight(0x6fe7ff, 2.4);
rim.position.set(-5, 4, -4);
scene.add(rim);
const fill = new THREE.PointLight(0x7fffc8, 16, 12, 2);
fill.position.set(0, 3.2, 2.2);
scene.add(fill);

// ChÃ£o
const floorMat = new THREE.MeshStandardMaterial({
  color: 0x07141d, roughness: 0.74, metalness: 0.18,
});
const floor = new THREE.Mesh(new THREE.PlaneGeometry(70, 70), floorMat);
floor.rotation.x = -Math.PI / 2;
floor.receiveShadow = true;
scene.add(floor);

const grid = new THREE.GridHelper(46, 46, 0x1b6a85, 0x0d2a38);
grid.position.y = 0.004;
grid.material.transparent = true;
grid.material.opacity = 0.42;
scene.add(grid);

// Plataforma circular
const platformMat = new THREE.MeshStandardMaterial({
  color: 0x091d28, roughness: 0.5, metalness: 0.35,
  emissive: 0x06151d, emissiveIntensity: 0.6,
});
const platform = new THREE.Mesh(new THREE.CylinderGeometry(6.7, 7.0, 0.12, 96), platformMat);
platform.position.y = -0.065;
platform.receiveShadow = true;
scene.add(platform);
for (const r of [6.72, 5.4, 3.6]) {
  const ring = new THREE.Mesh(
    new THREE.RingGeometry(r - 0.012, r + 0.012, 128),
    new THREE.MeshBasicMaterial({ color: 0x2d8aa8, transparent: true, opacity: 0.32, side: THREE.DoubleSide, depthWrite: false }),
  );
  ring.rotation.x = -Math.PI / 2;
  ring.position.y = 0.007;
  scene.add(ring);
}

// MonÃ³litos de fundo
const monolithMat = new THREE.MeshStandardMaterial({ color: 0x061019, roughness: 0.9, metalness: 0.05 });
for (let i = 0; i < 18; i++) {
  const a = (i / 18) * TAU + 0.12;
  const r = 18.0 + (i % 4) * 2.8;
  const h = 3.2 + ((i * 7) % 9);
  const w = 1.0 + ((i * 3) % 5) * 0.28;
  const m = new THREE.Mesh(new THREE.BoxGeometry(w, h, w * 0.8), monolithMat);
  m.position.set(Math.cos(a) * r, h / 2, Math.sin(a) * r);
  m.rotation.y = a + (i % 3) * 0.2;
  m.castShadow = true;
  m.receiveShadow = true;
  scene.add(m);
  if (i % 5 === 0) {
    const strip = new THREE.Mesh(
      new THREE.BoxGeometry(0.05, h * 0.55, 0.05),
      new THREE.MeshBasicMaterial({ color: 0x38b7d9, transparent: true, opacity: 0.35 }),
    );
    strip.position.set(m.position.x + w * 0.42, h * 0.4, m.position.z + w * 0.36);
    scene.add(strip);
  }
}

// Poeira ambiente
{
  const count = 380;
  const pos = new Float32Array(count * 3);
  for (let i = 0; i < count; i++) {
    const r = 3 + Math.random() * 16;
    const a = Math.random() * TAU;
    pos[i * 3] = Math.cos(a) * r;
    pos[i * 3 + 1] = 0.2 + Math.random() * 6;
    pos[i * 3 + 2] = Math.sin(a) * r;
  }
  const geo = new THREE.BufferGeometry();
  geo.setAttribute('position', new THREE.BufferAttribute(pos, 3));
  const mat = new THREE.PointsMaterial({
    color: 0x8fe8ff, size: 0.035, transparent: true, opacity: 0.5,
    blending: THREE.AdditiveBlending, depthWrite: false, sizeAttenuation: true,
  });
  scene.add(new THREE.Points(geo, mat));
}

// ---------------------------------------------------------------------------
// Texturas procedurais para o Quarks
// ---------------------------------------------------------------------------

function makeCanvasTexture(size, draw) {
  const c = document.createElement('canvas');
  c.width = c.height = size;
  const ctx = c.getContext('2d');
  draw(ctx, size);
  const tex = new THREE.CanvasTexture(c);
  tex.colorSpace = THREE.SRGBColorSpace;
  tex.minFilter = THREE.LinearFilter;
  tex.magFilter = THREE.LinearFilter;
  tex.needsUpdate = true;
  return tex;
}

const TEX = {
  paper: makeCanvasTexture(256, (ctx, s) => {
    ctx.fillStyle = '#f3edde';
    ctx.fillRect(0, 0, s, s);
    for (let i = 0; i < 1600; i++) {
      const x = Math.random() * s;
      const y = Math.random() * s;
      const len = 2 + Math.random() * 10;
      ctx.strokeStyle = `rgba(${120 + Math.random() * 70 | 0},${110 + Math.random() * 60 | 0},${90 + Math.random() * 50 | 0},${0.02 + Math.random() * 0.05})`;
      ctx.lineWidth = 0.5 + Math.random() * 0.8;
      ctx.beginPath();
      ctx.moveTo(x, y);
      ctx.lineTo(x + len, y + (Math.random() - 0.5) * 2);
      ctx.stroke();
    }
    for (let i = 0; i < 90; i++) {
      ctx.fillStyle = 'rgba(255,255,245,0.06)';
      ctx.beginPath();
      ctx.arc(Math.random() * s, Math.random() * s, 1 + Math.random() * 3, 0, TAU);
      ctx.fill();
    }
  }),
  kaleido: makeCanvasTexture(512, (ctx, s) => {
    const c = s / 2;
    ctx.clearRect(0, 0, s, s);
    const wedges = 12;
    for (let i = 0; i < wedges; i++) {
      const a0 = (i / wedges) * TAU;
      const a1 = ((i + 1) / wedges) * TAU;
      const grad = ctx.createLinearGradient(c, c, c + Math.cos((a0 + a1) / 2) * c, c + Math.sin((a0 + a1) / 2) * c);
      const hue = 175 + (i % 3) * 28;
      grad.addColorStop(0, `hsla(${hue}, 90%, 70%, 0.05)`);
      grad.addColorStop(1, `hsla(${hue + 35}, 85%, 62%, 0.24)`);
      ctx.fillStyle = grad;
      ctx.beginPath();
      ctx.moveTo(c, c);
      ctx.arc(c, c, c, a0, a1);
      ctx.closePath();
      ctx.fill();
      ctx.strokeStyle = `hsla(${hue + 30}, 100%, 82%, 0.34)`;
      ctx.lineWidth = 1.2;
      ctx.beginPath();
      ctx.moveTo(c, c);
      ctx.lineTo(c + Math.cos(a0) * c, c + Math.sin(a0) * c);
      ctx.stroke();
    }
    ctx.strokeStyle = 'rgba(220,255,255,0.28)';
    for (const r of [0.22, 0.44, 0.68, 0.88]) {
      ctx.beginPath();
      ctx.arc(c, c, s * r, 0, TAU);
      ctx.stroke();
    }
    ctx.fillStyle = 'rgba(235,255,255,0.55)';
    ctx.beginPath();
    ctx.arc(c, c, s * 0.035, 0, TAU);
    ctx.fill();
  }),
  hex: makeCanvasTexture(512, (ctx, s) => {
    ctx.clearRect(0, 0, s, s);
    const R = 26;
    const w = Math.sqrt(3) * R;
    const h = 2 * R;
    ctx.strokeStyle = 'rgba(150,255,235,0.55)';
    ctx.lineWidth = 1.4;
    for (let row = -1; row < s / (h * 0.75) + 1; row++) {
      for (let col = -1; col < s / w + 1; col++) {
        const cx = col * w + (row % 2 ? w / 2 : 0);
        const cy = row * h * 0.75;
        ctx.beginPath();
        for (let k = 0; k < 6; k++) {
          const a = (k / 6) * TAU + Math.PI / 6;
          const x = cx + Math.cos(a) * R;
          const y = cy + Math.sin(a) * R;
          if (k === 0) ctx.moveTo(x, y);
          else ctx.lineTo(x, y);
        }
        ctx.closePath();
        ctx.stroke();
      }
    }
  }),
  sigilD: makeCanvasTexture(256, (ctx, s) => {
    const c = s / 2;
    ctx.strokeStyle = 'rgba(200,255,255,.80)';
    ctx.lineWidth = s * 0.010;
    for (let i = 0; i < 3; i++) {
      const a = i * TAU / 3 + 0.25;
      ctx.beginPath();
      ctx.arc(c, c, s * 0.30, a, a + 1.55);
      ctx.stroke();
      ctx.fillStyle = 'rgba(220,255,255,.9)';
      ctx.beginPath();
      ctx.arc(c + Math.cos(a + 1.55) * s * 0.30, c + Math.sin(a + 1.55) * s * 0.30, s * 0.014, 0, TAU);
      ctx.fill();
    }
    ctx.fillStyle = 'rgba(230,255,255,.95)';
    ctx.beginPath();
    ctx.moveTo(c, c - s * 0.055);
    ctx.lineTo(c + s * 0.045, c);
    ctx.lineTo(c, c + s * 0.055);
    ctx.lineTo(c - s * 0.045, c);
    ctx.closePath();
    ctx.fill();
  }),
  bubble: makeCanvasTexture(128, (ctx, s) => {
    const g = ctx.createRadialGradient(s * 0.42, s * 0.38, s * 0.02, s * 0.5, s * 0.5, s * 0.5);
    g.addColorStop(0, 'rgba(255,255,255,.05)');
    g.addColorStop(0.55, 'rgba(205,250,255,.10)');
    g.addColorStop(0.82, 'rgba(225,255,255,.55)');
    g.addColorStop(0.95, 'rgba(255,255,255,.95)');
    g.addColorStop(1, 'rgba(255,255,255,0)');
    ctx.fillStyle = g;
    ctx.fillRect(0, 0, s, s);
    ctx.strokeStyle = 'rgba(255,255,255,.7)';
    ctx.lineWidth = s * 0.018;
    ctx.beginPath();
    ctx.arc(s * 0.5, s * 0.5, s * 0.43, 0, TAU);
    ctx.stroke();
    ctx.fillStyle = 'rgba(255,255,255,.95)';
    ctx.beginPath();
    ctx.ellipse(s * 0.34, s * 0.3, s * 0.055, s * 0.032, -0.6, 0, TAU);
    ctx.fill();
  }),
  spark: makeCanvasTexture(64, (ctx, s) => {
    const g = ctx.createRadialGradient(s / 2, s / 2, 0, s / 2, s / 2, s / 2);
    g.addColorStop(0, 'rgba(255,255,255,1)');
    g.addColorStop(0.18, 'rgba(220,255,255,.85)');
    g.addColorStop(0.6, 'rgba(150,240,255,.18)');
    g.addColorStop(1, 'rgba(150,240,255,0)');
    ctx.fillStyle = g;
    ctx.fillRect(0, 0, s, s);
    ctx.fillStyle = 'rgba(255,255,255,.9)';
    ctx.beginPath();
    ctx.moveTo(s / 2, s * 0.06);
    ctx.lineTo(s * 0.55, s * 0.45);
    ctx.lineTo(s * 0.94, s / 2);
    ctx.lineTo(s * 0.55, s * 0.55);
    ctx.lineTo(s / 2, s * 0.94);
    ctx.lineTo(s * 0.45, s * 0.55);
    ctx.lineTo(s * 0.06, s / 2);
    ctx.lineTo(s * 0.45, s * 0.45);
    ctx.closePath();
    ctx.fill();
  }),
  drop: makeCanvasTexture(64, (ctx, s) => {
    const g = ctx.createRadialGradient(s * 0.44, s * 0.38, s * 0.04, s * 0.5, s * 0.5, s * 0.5);
    g.addColorStop(0, 'rgba(255,255,255,.95)');
    g.addColorStop(0.4, 'rgba(195,248,255,.65)');
    g.addColorStop(0.8, 'rgba(120,220,255,.18)');
    g.addColorStop(1, 'rgba(120,220,255,0)');
    ctx.fillStyle = g;
    ctx.beginPath();
    ctx.arc(s * 0.5, s * 0.54, s * 0.38, 0, TAU);
    ctx.fill();
  }),
  shard: makeCanvasTexture(64, (ctx, s) => {
    ctx.fillStyle = 'rgba(235,255,255,.9)';
    ctx.beginPath();
    ctx.moveTo(s * 0.5, s * 0.08);
    ctx.lineTo(s * 0.86, s * 0.84);
    ctx.lineTo(s * 0.16, s * 0.7);
    ctx.closePath();
    ctx.fill();
    ctx.strokeStyle = 'rgba(150,240,255,.8)';
    ctx.lineWidth = s * 0.02;
    ctx.stroke();
  }),
  flash: makeCanvasTexture(128, (ctx, s) => {
    const g = ctx.createRadialGradient(s / 2, s / 2, 0, s / 2, s / 2, s / 2);
    g.addColorStop(0, 'rgba(255,255,255,1)');
    g.addColorStop(0.12, 'rgba(255,255,255,.95)');
    g.addColorStop(0.34, 'rgba(200,250,255,.35)');
    g.addColorStop(0.7, 'rgba(150,240,255,.08)');
    g.addColorStop(1, 'rgba(150,240,255,0)');
    ctx.fillStyle = g;
    ctx.fillRect(0, 0, s, s);
  }),
};

// ---------------------------------------------------------------------------
// Gerenciador Quarks
// ---------------------------------------------------------------------------

class ParticleHub {
  constructor(parent) {
    this.scene = parent;
    this.batch = new Q.BatchedRenderer();
    this.scene.add(this.batch);
    this.systems = [];
    this.materials = new Map();
  }

  material(texture, blending = THREE.AdditiveBlending) {
    const key = `${texture.uuid}:${blending}`;
    if (!this.materials.has(key)) {
      this.materials.set(key, new THREE.MeshBasicMaterial({
        map: texture, transparent: true, depthWrite: false, side: THREE.DoubleSide,
        blending, toneMapped: false,
      }));
    }
    return this.materials.get(key);
  }

  add(system, ttl) {
    this.batch.addSystem(system);
    this.scene.add(system.emitter);
    this.systems.push({ system, ttl });
    return system;
  }

  burst({
    origin, count = 30, texture = TEX.bubble, colorA = [0.75, 1, 1], colorB = [0.35, 0.85, 1],
    speed = [0.6, 1.8], size = [0.12, 0.3], life = [0.5, 1.2], radius = 0.15,
    gravity = 0.55, blending = THREE.AdditiveBlending, ttl = 2.2,
  }) {
    const system = new Q.ParticleSystem({
      duration: 0.02,
      looping: false,
      shape: new Q.SphereEmitter({ radius }),
      startLife: new Q.IntervalValue(life[0], life[1]),
      startSpeed: new Q.IntervalValue(speed[0], speed[1]),
      startSize: new Q.IntervalValue(size[0], size[1]),
      startColor: new Q.ConstantColor(new THREE.Vector4(1, 1, 1, 1)),
      emissionOverTime: new Q.ConstantValue(0),
      emissionBursts: [{ time: 0, count: new Q.ConstantValue(count), cycle: 1, interval: 0, probability: 1 }],
      behaviors: [
        new Q.ApplyForce(new THREE.Vector3(0, 1, 0), new Q.ConstantValue(gravity)),
        new Q.ColorOverLife(new Q.Gradient(
          [[new THREE.Vector3(...colorA), 0], [new THREE.Vector3(...colorB), 0.55], [new THREE.Vector3(...colorB), 1]],
          [[0, 0], [0.06, 1], [1, 0]],
        )),
        new Q.SizeOverLife({
          type: 'function',
          startGen() {},
          genValue(_m, t) { return 0.65 + 0.7 * Math.sin(Math.min(t, 1) * Math.PI * 0.9); },
          toJSON() { return { type: 'function', functionName: 'bubbleGrow' }; },
          clone() { return this; },
        }),
      ],
      material: this.material(texture, blending),
      renderMode: Q.RenderMode.BillBoard,
      worldSpace: true,
    });
    system.emitter.position.copy(origin);
    system.play();
    return this.add(system, ttl);
  }

  stream({
    origin, rate = 20, texture = TEX.bubble, colorA = [0.8, 1, 1], colorB = [0.4, 0.9, 1],
    speed = [0.15, 0.5], size = [0.06, 0.16], life = [0.8, 1.6], radius = 0.3,
    duration = 0.7, gravity = 0.3, ttl = 2.5, blending = THREE.AdditiveBlending,
  }) {
    const system = new Q.ParticleSystem({
      duration,
      looping: true,
      shape: new Q.SphereEmitter({ radius }),
      startLife: new Q.IntervalValue(life[0], life[1]),
      startSpeed: new Q.IntervalValue(speed[0], speed[1]),
      startSize: new Q.IntervalValue(size[0], size[1]),
      startColor: new Q.ConstantColor(new THREE.Vector4(1, 1, 1, 1)),
      emissionOverTime: new Q.ConstantValue(rate),
      emissionBursts: [],
      behaviors: [
        new Q.ApplyForce(new THREE.Vector3(0, 1, 0), new Q.ConstantValue(gravity)),
        new Q.ColorOverLife(new Q.Gradient(
          [[new THREE.Vector3(...colorA), 0], [new THREE.Vector3(...colorB), 1]],
          [[0, 0], [0.08, 1], [1, 0]],
        )),
        new Q.SizeOverLife({
          type: 'function',
          startGen() {},
          genValue(_m, t) { return 0.65 + 0.75 * Math.sin(Math.min(t, 1) * Math.PI * 0.85); },
          toJSON() { return { type: 'function', functionName: 'bubbleGrow' }; },
          clone() { return this; },
        }),
      ],
      material: this.material(texture, blending),
      renderMode: Q.RenderMode.BillBoard,
      worldSpace: false,
    });
    system.emitter.position.copy(origin);
    system.play();
    return this.add(system, ttl);
  }

  update(dt) {
    this.batch.update(dt);
    for (let i = this.systems.length - 1; i >= 0; i--) {
      const it = this.systems[i];
      it.ttl -= dt;
      if (it.ttl <= 0) {
        this.batch.deleteSystem(it.system);
        it.system.emitter.removeFromParent();
        it.system.dispose();
        this.systems.splice(i, 1);
      }
    }
  }

  clear() {
    for (const it of this.systems) {
      this.batch.deleteSystem(it.system);
      it.system.emitter.removeFromParent();
      it.system.dispose();
    }
    this.systems.length = 0;
  }
}

const particles = new ParticleHub(scene);

// ---------------------------------------------------------------------------
// Shaders das membranas
// ---------------------------------------------------------------------------

const soapVertex = /* glsl */`
  uniform float uTime;
  uniform vec3 uHitDir;
  uniform float uHitAge;
  uniform float uHitStrength;
  varying vec3 vWorld;
  varying vec3 vNormalW;
  varying vec3 vViewW;
  varying vec2 vUv;
  varying float vHitAng;
  void main() {
    vUv = uv;
    vec3 n = normalize(normal);
    float ang = acos(clamp(dot(normalize(position), normalize(uHitDir)), -1.0, 1.0));
    vHitAng = ang;
    float dent = exp(-pow(ang / 0.34, 2.0)) * uHitStrength;
    vec3 p = position - n * dent * 0.13;
    p += n * sin(ang * 18.0 - uHitAge * 16.0) * exp(-ang * 3.5) * uHitStrength * 0.026;
    p += n * (sin(uv.x * 16.0 + uTime * 1.1) + sin(uv.y * 12.0 - uTime * 0.8)) * 0.0035;
    vec4 wp = modelMatrix * vec4(p, 1.0);
    vWorld = wp.xyz;
    vNormalW = normalize(mat3(modelMatrix) * normal);
    vViewW = normalize(cameraPosition - wp.xyz);
    gl_Position = projectionMatrix * viewMatrix * wp;
  }
`;

const soapFragment = /* glsl */`
  uniform float uTime;
  uniform float uOpacity;
  uniform float uHit;
  uniform float uHitAge;
  uniform float uHitStrength;
  uniform float uDepletion;
  uniform float uBaseAlpha;
  uniform vec3 uTint;
  varying vec3 vWorld;
  varying vec3 vNormalW;
  varying vec3 vViewW;
  varying vec2 vUv;
  varying float vHitAng;
  void main() {
    vec3 N = normalize(vNormalW);
    vec3 V = normalize(vViewW);
    float ndv = abs(dot(N, V));
    float fres = pow(1.0 - ndv, 2.15);
    float rim = pow(1.0 - ndv, 3.6);
    float film = 0.5 + 0.5 * sin(fres * 13.0 + uTime * 0.9 + vWorld.y * 4.0 + sin(vWorld.x * 2.0 + uTime * 0.5) * 0.8);
    vec3 irid = 0.5 + 0.5 * cos(6.28318 * (vec3(0.0, 0.33, 0.67) + film * 1.15 + fres * 0.55));
    vec3 col = mix(uTint * 0.45, irid, clamp(fres * 1.35, 0.0, 1.0));
    col += rim * 0.30;
    float band = smoothstep(0.88, 1.0, sin(vWorld.y * 8.5 - uTime * 1.4 + fres * 5.0)) * 0.10;
    col += band;
    float hitWave = smoothstep(0.16, 0.0, abs(vHitAng - uHitAge * 2.4)) * uHitStrength;
    col += hitWave * 1.20;
    float alpha = uBaseAlpha + rim * 0.66 + fres * 0.075 + band * 0.25 + uHit * 0.28;
    alpha += hitWave * 0.40 + exp(-pow(vHitAng / 0.42, 2.0)) * uHitStrength * 0.06;
    alpha *= (1.0 - uDepletion * 0.26) * uOpacity;
    if (alpha < 0.008) discard;
    gl_FragColor = vec4(col, clamp(alpha, 0.0, 1.0));
  }
`;

const honeycombFragment = /* glsl */`
  uniform float uTime;
  uniform float uOpacity;
  uniform float uHit;
  uniform float uHitAge;
  uniform float uHitStrength;
  uniform float uDepletion;
  uniform float uBaseAlpha;
  uniform vec3 uTint;
  varying vec3 vWorld;
  varying vec3 vNormalW;
  varying vec3 vViewW;
  varying vec2 vUv;
  varying float vHitAng;
  void main() {
    vec3 N = normalize(vNormalW);
    vec3 V = normalize(vViewW);
    float ndv = abs(dot(N, V));
    float fres = pow(1.0 - ndv, 2.0);
    float rim = pow(1.0 - ndv, 3.4);

    // Colmeia hexagonal (grade de bolhas) sobre a membrana.
    vec2 p = vUv * vec2(15.0, 8.5);
    vec2 r = vec2(1.0, 1.7320508);
    vec2 h = r * 0.5;
    vec2 a = mod(p, r) - h;
    vec2 b = mod(p - h, r) - h;
    vec2 gv = dot(a, a) < dot(b, b) ? a : b;
    float hd = max(abs(gv.x), dot(abs(gv), normalize(r)));
    float edge = smoothstep(0.42, 0.49, hd);
    float inner = smoothstep(0.49, 0.12, hd);
    float id = dot(p - gv, vec2(12.9898, 78.233));
    float cellShade = 0.82 + 0.18 * sin(id * 0.17 + uTime * 0.75);
    float cellPulse = 0.5 + 0.5 * sin(id * 0.11 - uTime * 0.9);

    float film = 0.5 + 0.5 * sin(fres * 12.0 + uTime * 0.8 + vWorld.y * 3.5);
    vec3 irid = 0.5 + 0.5 * cos(6.28318 * (vec3(0.0, 0.33, 0.67) + film * 1.1 + fres * 0.6));
    vec3 col = mix(uTint * 0.55, irid, 0.42) * cellShade;
    col += edge * 0.55 + rim * 0.40 + inner * cellPulse * 0.05;

    float hitWave = smoothstep(0.18, 0.0, abs(vHitAng - uHitAge * 2.4)) * uHitStrength;
    col += hitWave * 1.5;
    float alpha = uBaseAlpha + rim * 0.52 + edge * 0.20 + inner * 0.018 + uHit * 0.26;
    alpha += hitWave * 0.52 + exp(-pow(vHitAng / 0.42, 2.0)) * uHitStrength * 0.10;
    alpha *= (1.0 - uDepletion * 0.26) * uOpacity;
    if (alpha < 0.008) discard;
    gl_FragColor = vec4(col, clamp(alpha, 0.0, 1.0));
  }
`;

function makeHoneycombMaterial(tint = new THREE.Color(0.76, 0.98, 1.0)) {
  return new THREE.ShaderMaterial({
    uniforms: {
      uTime: { value: 0 }, uOpacity: { value: 1 }, uHit: { value: 0 },
      uHitDir: { value: new THREE.Vector3(0, 0, 1) },
      uHitAge: { value: 0 }, uHitStrength: { value: 0 },
      uDepletion: { value: 0 }, uBaseAlpha: { value: 0.026 },
      uTint: { value: tint },
    },
    vertexShader: soapVertex,
    fragmentShader: honeycombFragment,
    transparent: true,
    depthWrite: false,
    side: THREE.DoubleSide,
    blending: THREE.NormalBlending,
  });
}

const waterVertex = /* glsl */`
  uniform float uTime;
  uniform float uHitAge;
  uniform float uPower;
  uniform float uDepletion;
  uniform vec3 uHitDir;
  varying vec3 vWorld;
  varying vec3 vNormal;
  varying vec3 vLocal;
  varying float vWave;
  varying float vBump;
  void main() {
    vec3 p = position;
    float d = dot(normalize(position), normalize(uHitDir));
    float impact = exp(-pow((1.0 - d) / 0.28, 2.0));
    float recoil = exp(-max(uHitAge, 0.0) * 8.0);
    float contact = (uHitAge >= 0.0 && uHitAge < 0.8) ? impact * recoil : 0.0;
    float ring = (uHitAge >= 0.0 && uHitAge < 1.0)
      ? exp(-pow((acos(clamp(d, -1.0, 1.0)) - uHitAge * 5.0) / 0.19, 2.0)) * (1.0 - uHitAge)
      : 0.0;
    float wobble = 0.012 * sin(position.y * 13.0 + uTime * 1.5 + sin(position.x * 7.0))
                 + 0.008 * sin(position.x * 11.0 - uTime * 2.3);
    float deform = -contact * 0.16 * uPower + ring * 0.025 * uPower + wobble * (1.0 + uDepletion * 0.4);
    p *= 1.0 + deform;
    vec4 wp = modelMatrix * vec4(p, 1.0);
    vWorld = wp.xyz;
    vNormal = normalize(mat3(modelMatrix) * normal);
    vLocal = position;
    vWave = ring;
    vBump = contact;
    gl_Position = projectionMatrix * viewMatrix * wp;
  }
`;

const waterFragment = /* glsl */`
  uniform float uTime;
  uniform float uAlpha;
  uniform float uDepletion;
  uniform float uReveal;
  varying vec3 vWorld;
  varying vec3 vNormal;
  varying vec3 vLocal;
  varying float vWave;
  varying float vBump;
  void main() {
    vec3 N = normalize(vNormal);
    vec3 V = normalize(cameraPosition - vWorld);
    float fres = pow(1.0 - abs(dot(N, V)), 2.55);
    float az = atan(vLocal.z, vLocal.x);
    float water = sin(az * 5.0 + vLocal.y * 8.0 - uTime * 1.25 + sin(vLocal.y * 4.0 + uTime) * 1.6);
    float whorl = sin(vLocal.y * 11.0 + az * 4.0 + uTime * 1.7);
    float filaments = smoothstep(0.76, 1.0, water * 0.5 + 0.5) * 0.075;
    float highlight = smoothstep(0.90, 1.0, whorl * 0.5 + 0.5) * 0.06;
    float crest = vWave * 0.40 + vBump * 0.18;
    float rim = fres * (0.30 + 0.06 * sin(az * 5.0 + uTime * 1.2));
    float bright = (rim + filaments + highlight + crest) * (1.0 - uDepletion * 0.4);
    vec3 c = mix(vec3(0.04, 0.45, 0.70), vec3(0.69, 0.98, 1.0),
                 clamp(fres * 0.55 + filaments * 1.5 + crest * 0.9, 0.0, 1.0));
    float alpha = (0.020 + bright * 0.50) * (1.0 - 0.5 * uDepletion) * uAlpha * uReveal;
    if (alpha < 0.006) discard;
    gl_FragColor = vec4(c, clamp(alpha, 0.0, 0.75));
  }
`;

const crownWaterVertex = /* glsl */`
  varying vec2 vUv;
  varying vec3 vWorld;
  varying vec3 vNormal;
  void main() {
    vUv = uv;
    vec4 wp = modelMatrix * vec4(position, 1.0);
    vWorld = wp.xyz;
    vNormal = normalize(mat3(modelMatrix) * normal);
    gl_Position = projectionMatrix * viewMatrix * wp;
  }
`;

const crownWaterFragment = /* glsl */`
  uniform float uTime;
  uniform float uAlpha;
  uniform float uReveal;
  uniform float uBoost;
  varying vec2 vUv;
  varying vec3 vWorld;
  varying vec3 vNormal;
  void main() {
    vec3 N = normalize(vNormal);
    vec3 V = normalize(cameraPosition - vWorld);
    float fres = pow(1.0 - abs(dot(N, V)), 2.1);

    float flow = sin(vUv.y * 25.0 - uTime * 2.8 + sin(vUv.x * 7.0 + uTime * 0.9) * 2.4);
    float vein = smoothstep(0.54, 0.96, sin(vUv.x * 30.0 + sin(vUv.y * 8.0 - uTime * 1.6) * 3.0) * 0.5 + 0.5);
    float caustic = smoothstep(0.50, 1.0, flow * 0.5 + 0.5);
    float foamBand = smoothstep(0.74, 0.86, vUv.y) * (1.0 - smoothstep(0.90, 0.98, vUv.y));

    float sideEdge = smoothstep(0.06, 0.0, min(vUv.x, 1.0 - vUv.x));
    float topEdge = smoothstep(0.89, 0.995, vUv.y);
    float reveal = exp(-pow((vUv.y - uReveal) / 0.065, 2.0)) * (1.0 - uReveal) * 1.5;

    vec3 deep = vec3(0.02, 0.25, 0.45);
    vec3 aqua = vec3(0.30, 0.86, 0.98);
    vec3 white = vec3(0.92, 1.0, 1.0);
    vec3 col = mix(deep, aqua, clamp(vUv.y * 0.50 + fres * 0.35 + caustic * 0.26 + vein * 0.10, 0.0, 1.0));
    col = mix(col, white, clamp(topEdge * 0.62 + sideEdge * 0.32 + foamBand * 0.38 + reveal * 0.85, 0.0, 1.0));

    float alpha = (0.045 + fres * 0.16 + caustic * 0.14 + vein * 0.05 + foamBand * 0.20
      + sideEdge * 0.09 + topEdge * 0.40 + reveal * 0.50) * uAlpha * uBoost;
    if (alpha < 0.006) discard;
    gl_FragColor = vec4(col, clamp(alpha, 0.0, 0.86));
  }
`;

function makeCrownWaterMaterial(boost = 1) {
  return new THREE.ShaderMaterial({
    uniforms: {
      uTime: { value: 0 },
      uAlpha: { value: 1 },
      uReveal: { value: 1 },
      uBoost: { value: boost },
    },
    vertexShader: crownWaterVertex,
    fragmentShader: crownWaterFragment,
    transparent: true,
    depthWrite: false,
    side: THREE.DoubleSide,
    blending: THREE.NormalBlending,
  });
}

const maelstromVertex = /* glsl */`
  varying vec2 vUv;
  varying vec3 vWorld;
  varying vec3 vNormal;
  uniform float uTime;
  uniform float uWobble;
  void main() {
    vUv = uv;
    vec3 p = position + normal * (
      sin(uTime * 2.4 + position.y * 7.0 + position.x * 3.0) * 0.55 +
      sin(uTime * 1.7 + position.z * 5.0 - position.y * 4.0) * 0.45
    ) * uWobble;
    vec4 wp = modelMatrix * vec4(p, 1.0);
    vWorld = wp.xyz;
    vNormal = normalize(mat3(modelMatrix) * normal);
    gl_Position = projectionMatrix * viewMatrix * wp;
  }
`;

const maelstromFragment = /* glsl */`
  uniform float uTime;
  uniform float uAlpha;
  varying vec2 vUv;
  varying vec3 vWorld;
  varying vec3 vNormal;
  void main() {
    vec3 N = normalize(vNormal);
    vec3 V = normalize(cameraPosition - vWorld);
    float fres = pow(1.0 - abs(dot(N, V)), 2.1);

    float flow = sin(vUv.y * 30.0 - uTime * 3.0 + sin(vUv.x * 8.0 + uTime) * 2.2);
    float vein = smoothstep(0.55, 0.96, sin(vUv.x * 24.0 + sin(vUv.y * 8.0 - uTime * 1.8) * 3.0) * 0.5 + 0.5);
    float foam = smoothstep(0.60, 0.93, flow * 0.5 + 0.5) * smoothstep(0.48, 0.95, vUv.y);
    foam *= 0.35 + 0.65 * vein;
    float top = smoothstep(0.80, 0.995, vUv.y);
    float side = smoothstep(0.09, 0.0, min(vUv.x, 1.0 - vUv.x));
    vec3 L = normalize(vec3(-0.35, 0.75, 0.55));
    float spec = pow(max(dot(reflect(-V, N), L), 0.0), 38.0);

    vec3 deep = vec3(0.004, 0.10, 0.24);
    vec3 mid = vec3(0.01, 0.28, 0.50);
    vec3 aqua = vec3(0.06, 0.52, 0.80);
    vec3 white = vec3(0.88, 0.99, 1.0);
    vec3 col = mix(deep, mid, smoothstep(0.0, 0.55, vUv.y));
    col = mix(col, aqua, smoothstep(0.48, 1.0, vUv.y));
    col *= 0.90 + 0.08 * fres;
    col += vec3(0.25, 0.72, 0.95) * fres * 0.34;
    col += white * spec * 0.45;
    col = mix(col, white, clamp(foam * 0.28 + top * 0.42 + side * 0.22, 0.0, 1.0));

    float alpha = clamp(0.82 + fres * 0.10 + foam * 0.03 + top * 0.03, 0.0, 0.97) * uAlpha;
    if (alpha < 0.01) discard;
    gl_FragColor = vec4(col, alpha);
  }
`;

function makeMaelstromMaterial() {
  return new THREE.ShaderMaterial({
    uniforms: {
      uTime: { value: 0 },
      uAlpha: { value: 1 },
      uWobble: { value: 0.008 },
    },
    vertexShader: maelstromVertex,
    fragmentShader: maelstromFragment,
    transparent: true,
    depthWrite: true,
    side: THREE.DoubleSide,
    blending: THREE.NormalBlending,
  });
}

function makeWaterMaterial() {
  return new THREE.ShaderMaterial({
    uniforms: {
      uTime: { value: 0 },
      uAlpha: { value: 1 },
      uDepletion: { value: 0 },
      uReveal: { value: 1 },
      uHitAge: { value: -10 },
      uPower: { value: 0 },
      uHitDir: { value: new THREE.Vector3(0, 0.35, 1).normalize() },
    },
    vertexShader: waterVertex,
    fragmentShader: waterFragment,
    transparent: true,
    depthWrite: false,
    side: THREE.DoubleSide,
    blending: THREE.NormalBlending,
  });
}

function makeSoapMaterial(tint = new THREE.Color(0.72, 0.95, 1.0), baseAlpha = 0.010) {
  return new THREE.ShaderMaterial({
    uniforms: {
      uTime: { value: 0 },
      uOpacity: { value: 1 },
      uHit: { value: 0 },
      uHitDir: { value: new THREE.Vector3(0, 0, 1) },
      uHitAge: { value: 0 },
      uHitStrength: { value: 0 },
      uDepletion: { value: 0 },
      uBaseAlpha: { value: baseAlpha },
      uTint: { value: tint },
    },
    vertexShader: soapVertex,
    fragmentShader: soapFragment,
    transparent: true,
    depthWrite: false,
    side: THREE.DoubleSide,
    blending: THREE.NormalBlending,
  });
}

const facetVertex = /* glsl */`
  uniform vec3 uHitDir;
  uniform float uHitAge;
  uniform float uHitStrength;
  varying vec3 vWorld;
  varying vec3 vNormalW;
  varying vec3 vViewW;
  varying float vHitDot;
  void main() {
    vec4 wp = modelMatrix * vec4(position, 1.0);
    vWorld = wp.xyz;
    vNormalW = normalize(mat3(modelMatrix) * normal);
    vViewW = normalize(cameraPosition - wp.xyz);
    vHitDot = dot(normalize(normal), normalize(uHitDir));
    gl_Position = projectionMatrix * viewMatrix * wp;
  }
`;

const facetFragment = /* glsl */`
  uniform float uTime;
  uniform float uOpacity;
  uniform float uHit;
  uniform float uFreeze;
  uniform float uHitAge;
  uniform float uHitStrength;
  uniform vec3 uTint;
  varying vec3 vWorld;
  varying vec3 vNormalW;
  varying vec3 vViewW;
  varying float vHitDot;
  void main() {
    vec3 N = normalize(vNormalW);
    vec3 V = normalize(vViewW);
    float ndv = abs(dot(N, V));
    float fres = pow(1.0 - ndv, 1.45);
    float facet = smoothstep(0.0, 1.0, abs(N.x * 0.6 + N.y * 0.8));
    float film = 0.5 + 0.5 * sin(facet * 8.0 + uTime * 0.55 + vWorld.y * 2.2);
    vec3 irid = 0.5 + 0.5 * cos(6.28318 * (vec3(0.0, 0.33, 0.67) + film * 1.1 + fres * 0.7));
    vec3 col = mix(uTint, irid, 0.65 + uFreeze * 0.2);
    col += fres * 0.42;
    float edge = pow(1.0 - ndv, 5.0) * 0.8;
    float ripple = smoothstep(0.035, 0.0, abs(vHitDot - (1.0 - uHitAge * 1.6))) * uHitStrength;
    col += ripple * 0.85;
    float alpha = 0.032 + fres * 0.55 + edge + uHit * 0.10;
    alpha += ripple * 0.22 + uHitStrength * 0.015;
    alpha *= uOpacity;
    if (alpha < 0.008) discard;
    gl_FragColor = vec4(col, clamp(alpha, 0.0, 1.0));
  }
`;

function makeFacetMaterial(tint = new THREE.Color(0.72, 0.95, 1.0)) {
  return new THREE.ShaderMaterial({
    uniforms: {
      uTime: { value: 0 }, uOpacity: { value: 1 }, uHit: { value: 0 },
      uFreeze: { value: 0 }, uTint: { value: tint },
      uHitDir: { value: new THREE.Vector3(0, 0, 1) },
      uHitAge: { value: 0 }, uHitStrength: { value: 0 },
    },
    vertexShader: facetVertex,
    fragmentShader: facetFragment,
    transparent: true,
    depthWrite: false,
    side: THREE.DoubleSide,
    blending: THREE.NormalBlending,
  });
}

// ---------------------------------------------------------------------------
// Slimes
// ---------------------------------------------------------------------------

const characters = [];
let caster = null;
let idleClip = null;
let castClip = null;
let loaded = false;

function addBlobShadow(root, scale = 1) {
  const m = new THREE.Mesh(
    new THREE.CircleGeometry(0.62 * scale, 40),
    new THREE.MeshBasicMaterial({ color: 0x000000, transparent: true, opacity: 0.34, depthWrite: false }),
  );
  m.rotation.x = -Math.PI / 2;
  m.position.y = 0.012;
  root.add(m);
  const ring = new THREE.Mesh(
    new THREE.RingGeometry(0.66 * scale, 0.72 * scale, 64),
    new THREE.MeshBasicMaterial({ color: 0x7fe9ff, transparent: true, opacity: 0.18, side: THREE.DoubleSide, depthWrite: false }),
  );
  ring.rotation.x = -Math.PI / 2;
  ring.position.y = 0.014;
  root.add(ring);
}

async function loadSlimes() {
  const loader = new GLTFLoader();

  for (let i = 0; i < PARTY.length; i++) {
    const spec = PARTY[i];
    const gltf = await loader.loadAsync(spec.glb);
    const model = gltf.scene;
    const box = new THREE.Box3().setFromObject(model);
    const size = new THREE.Vector3();
    box.getSize(size);
    const s = spec.targetH / Math.max(0.001, size.y);

    const root = new THREE.Group();
    root.position.copy(ALLY_POSITIONS[i]);
    scene.add(root);

    model.scale.setScalar(s);
    model.rotation.y = Math.PI;
    model.traverse((o) => {
      if (o.isMesh) {
        o.castShadow = true;
        o.receiveShadow = true;
        o.frustumCulled = false;
        if (o.material) {
          const mats = Array.isArray(o.material) ? o.material : [o.material];
          const fixed = mats.map((mat) => {
            const m = mat.clone();
            m.side = THREE.FrontSide;
            if (m.map) {
              m.map.magFilter = THREE.NearestFilter;
              m.map.minFilter = THREE.NearestMipmapLinearFilter;
              m.map.needsUpdate = true;
            }
            m.envMapIntensity = 0.7;
            return m;
          });
          o.material = Array.isArray(o.material) ? fixed : fixed[0];
        }
      }
    });
    root.add(model);

    const b2 = new THREE.Box3().setFromObject(model);
    model.position.y -= b2.min.y;
    const fitted = new THREE.Box3().setFromObject(model);
    const fsize = new THREE.Vector3();
    fitted.getSize(fsize);
    const center = new THREE.Vector3();
    fitted.getCenter(center);
    const radius = 0.5 * Math.sqrt(
      fsize.x * fsize.x + fsize.y * fsize.y + fsize.z * fsize.z,
    ) * 1.04;

    addBlobShadow(root, Math.max(1, radius / 0.92));

    const idleClip = THREE.AnimationClip.findByName(gltf.animations, spec.idle)
      || gltf.animations.find((a) => a.name.endsWith('_00'))
      || gltf.animations[0];
    const castClip = THREE.AnimationClip.findByName(gltf.animations, spec.cast)
      || gltf.animations.find((a) => a.name.endsWith('_10'))
      || idleClip;

    const mixer = new THREE.AnimationMixer(model);
    const idle = mixer.clipAction(idleClip);
    idle.play();
    let cast = null;
    if (castClip && castClip !== idleClip) {
      cast = mixer.clipAction(castClip);
      cast.setLoop(THREE.LoopOnce, 1);
      cast.clampWhenFinished = true;
    }

    const ch = {
      index: i, name: ALLY_NAMES[i], root, model, mixer, idle, cast,
      center,
      radius,
      shield: null,
      phase: 0,
    };
    characters.push(ch);
    if (i === 1) caster = ch;
  }
  loaded = true;
  state.loading = false;
  updateAllyHud();
  toast('ORC + SLIME + CYCLOPS - prontos para conjurar');
}

function playCast(ch) {
  if (!ch.cast) return;
  ch.idle.fadeOut(0.08);
  ch.cast.reset().fadeIn(0.08).play();
  ch.phase = 1;
}

function updateCharacterAnim(ch, dt) {
  ch.mixer.update(dt);
  const dx = camera.position.x - ch.root.position.x;
  const dz = camera.position.z - ch.root.position.z;
  ch.root.rotation.y = Math.atan2(dx, dz);
  // Pequena respiraÃ§Ã£o no grupo (o clipe idle jÃ¡ anima o esqueleto).
  const t = clock.elapsedTime;
  ch.root.position.y = Math.sin(t * 1.7 + ch.index * 1.3) * 0.012;
  if (ch.phase === 1 && ch.cast && !ch.cast.isRunning()) {
    ch.cast.fadeOut(0.15);
    ch.idle.reset().fadeIn(0.2).play();
    ch.phase = 0;
  }
}

// ---------------------------------------------------------------------------
// Bolhas de conjuraÃ§Ã£o / voo
// ---------------------------------------------------------------------------

const flightBubbles = [];
const rings = [];
const flashes = [];

const waterDebris = [];
const releaseRings = [];

function spawnWaterDebris(ch, mode = 'break', n = 40) {
  const center = ch.center.clone();
  const radius = ch.radius;
  for (let i = 0; i < n; i++) {
    const a = Math.random() * TAU;
    const z = Math.random() * 2 - 1;
    const h = Math.sqrt(Math.max(0, 1 - z * z));
    const dir = new THREE.Vector3(Math.cos(a) * h, z, Math.sin(a) * h);
    const soft = mode === 'soft';
    const m = new THREE.Mesh(
      new THREE.SphereGeometry(1, 8, 6),
      new THREE.MeshBasicMaterial({
        color: 0xbfefff, transparent: true, opacity: 0.82,
        blending: THREE.AdditiveBlending, depthWrite: false,
      }),
    );
    const size = radius * (0.018 + Math.random() * 0.029);
    m.scale.setScalar(size);
    m.position.copy(center).addScaledVector(dir, radius * (0.75 + Math.random() * 0.22));
    scene.add(m);
    waterDebris.push({
      mesh: m,
      vel: dir.multiplyScalar((soft ? 0.25 : 0.8) * (0.45 + Math.random() * 1.2))
        .add(new THREE.Vector3(0, 0.2 + Math.random() * 0.65, 0)),
      age: 0,
      life: (soft ? 0.6 : 1.0) + Math.random() * 0.5,
      soft,
    });
  }
}

function updateWaterDebris(dt) {
  for (let i = waterDebris.length - 1; i >= 0; i--) {
    const d = waterDebris[i];
    d.age += dt;
    const t = d.age / d.life;
    if (t >= 1) {
      d.mesh.geometry.dispose();
      d.mesh.material.dispose();
      d.mesh.removeFromParent();
      waterDebris.splice(i, 1);
      continue;
    }
    d.mesh.position.addScaledVector(d.vel, dt);
    d.vel.y -= (d.soft ? 0.4 : 1.1) * dt;
    d.mesh.material.opacity = Math.pow(1 - t, 1.35) * 0.82;
    d.mesh.scale.y *= 1.0 + dt * (d.soft ? 0.2 : 0.6);
  }
}

function addReleaseRing(origin) {
  const mesh = new THREE.Mesh(
    new THREE.TorusGeometry(1, 0.018, 6, 96),
    new THREE.MeshBasicMaterial({
      color: 0x6be6ff, transparent: true, opacity: 0.4,
      blending: THREE.AdditiveBlending, depthWrite: false,
    }),
  );
  mesh.rotation.x = -Math.PI / 2;
  mesh.position.set(origin.x, 0.11, origin.z);
  mesh.scale.setScalar(0.3);
  scene.add(mesh);
  releaseRings.push({ mesh, age: 0, life: 0.98 });
}

function updateReleaseRings(dt) {
  for (let i = releaseRings.length - 1; i >= 0; i--) {
    const r = releaseRings[i];
    r.age += dt;
    const t = r.age / r.life;
    const s = 0.3 + easeOutCubic(clamp(t, 0, 1)) * 8.2;
    r.mesh.scale.set(s, s, 1);
    r.mesh.material.opacity = Math.max(0, 0.4 * (1 - t));
    if (t >= 1) {
      r.mesh.geometry.dispose();
      r.mesh.material.dispose();
      r.mesh.removeFromParent();
      releaseRings.splice(i, 1);
    }
  }
}

function addFlash(origin, color = 0xffffff, size = 0.22, life = 0.16) {
  const mat = new THREE.SpriteMaterial({
    map: TEX.spark, color, transparent: true, opacity: 0.95,
    depthWrite: false, blending: THREE.AdditiveBlending, toneMapped: false,
  });
  const sprite = new THREE.Sprite(mat);
  sprite.position.copy(origin);
  sprite.scale.setScalar(size * 0.35);
  scene.add(sprite);
  flashes.push({ mesh: sprite, age: 0, life, size });
}

function updateFlashes(dt) {
  for (let i = flashes.length - 1; i >= 0; i--) {
    const f = flashes[i];
    f.age += dt;
    const t = f.age / f.life;
    f.mesh.scale.setScalar(f.size * (0.35 + t * 1.35));
    f.mesh.material.opacity = Math.max(0, 0.95 * (1 - t));
    if (t >= 1) {
      f.mesh.material.dispose();
      f.mesh.removeFromParent();
      flashes.splice(i, 1);
    }
  }
}

function addRing(origin, color = 0x9ff3ff, radius = 1, y = 0.02, normal = null) {
  const m = new THREE.Mesh(
    new THREE.RingGeometry(radius * 0.82, radius, 64),
    new THREE.MeshBasicMaterial({ color, transparent: true, opacity: 0.32, side: THREE.DoubleSide, depthWrite: false, blending: THREE.AdditiveBlending }),
  );
  if (normal) {
    m.position.copy(origin);
    m.lookAt(origin.clone().add(normal));
  } else {
    m.rotation.x = -Math.PI / 2;
    m.position.copy(origin);
    m.position.y = y;
  }
  scene.add(m);
  rings.push({ mesh: m, age: 0, life: 0.8, radius });
}

function updateRings(dt) {
  for (let i = rings.length - 1; i >= 0; i--) {
    const r = rings[i];
    r.age += dt;
    const t = r.age / r.life;
    r.mesh.scale.setScalar(0.8 + t * 1.7);
    r.mesh.material.opacity = 0.34 * (1 - t);
    if (t >= 1) {
      r.mesh.geometry.dispose();
      r.mesh.material.dispose();
      r.mesh.removeFromParent();
      rings.splice(i, 1);
    }
  }
}

const charge = {
  mesh: null,
  light: null,
  active: false,
  releasing: false,
  t: 0,
  releaseT: 0,
  spiral: [],
  seeds: [],
  waterHelix: null,
  waterCore: null,
  waterGlow: null,
  waterDrops: [],
  partyRing: null,
  allyRings: [],
};

function makeFlatRing(radius, color = 0x9ff3ff) {
  const m = new THREE.Mesh(
    new THREE.RingGeometry(radius * 0.94, radius, 96),
    new THREE.MeshBasicMaterial({ color, transparent: true, opacity: 0, side: THREE.DoubleSide, depthWrite: false, blending: THREE.AdditiveBlending }),
  );
  m.rotation.x = -Math.PI / 2;
  m.position.y = 0.018;
  scene.add(m);
  return m;
}

function buildCharge() {
  const mat = makeSoapMaterial(new THREE.Color(0.78, 0.98, 1.0));
  const mesh = new THREE.Mesh(new THREE.SphereGeometry(1, 48, 32), mat);
  mesh.visible = false;
  scene.add(mesh);
  charge.mesh = mesh;
  const light = new THREE.PointLight(0x9ff6ff, 0, 4, 2);
  scene.add(light);
  charge.light = light;

  // Bolhas menores espiralam em volta do Slime e convergem para a bolha grande.
  const orbGeo = new THREE.SphereGeometry(1, 18, 12);
  for (let i = 0; i < 16; i++) {
    const om = makeSoapMaterial(new THREE.Color(0.72, 0.97, 1.0));
    const orb = new THREE.Mesh(orbGeo, om);
    orb.visible = false;
    scene.add(orb);
    charge.spiral.push({
      mesh: orb,
      angle: Math.random() * TAU,
      radius: 0.95 + Math.random() * 0.55,
      y: 0.25 + Math.random() * 1.25,
      speed: 1.2 + Math.random() * 1.8,
      size: 0.035 + Math.random() * 0.06,
    });
  }

  charge.partyRing = makeFlatRing(3.15);
  charge.partyRing.position.z = 0.3;
  for (let i = 0; i < 3; i++) {
    const r = makeFlatRing(0.78);
    r.position.set(ALLY_POSITIONS[i].x, 0.02, ALLY_POSITIONS[i].z);
    charge.allyRings.push(r);
    const sm = makeSoapMaterial(new THREE.Color(0.85, 1.0, 1.0), 0.18);
    const seed = new THREE.Mesh(new THREE.SphereGeometry(1, 24, 16), sm);
    const glow = new THREE.Sprite(new THREE.SpriteMaterial({
      map: TEX.flash, color: 0x9ff6ff, transparent: true, opacity: 0.7,
      depthWrite: false, depthTest: false, blending: THREE.AdditiveBlending, toneMapped: false,
    }));
    glow.scale.setScalar(2.2);
    glow.renderOrder = 8;
    seed.add(glow);
    seed.userData.glow = glow;
    seed.visible = false;
    scene.add(seed);
    charge.seeds.push(seed);
  }

  // Referência bubble_shield_vfx_lab.html: hélice de água + núcleo ciano + gotas.
  const pts = [];
  for (let i = 0; i <= 120; i++) {
    const u = i / 120;
    const a = u * TAU * 2.3;
    const r = 0.75 + 0.12 * Math.sin(a * 1.5);
    pts.push(new THREE.Vector3(r * Math.cos(a), u * 1.4 - 0.7, r * Math.sin(a)));
  }
  const helixGeo = new THREE.TubeGeometry(new THREE.CatmullRomCurve3(pts), 120, 0.028, 6, false);
  const helixMat = new THREE.MeshBasicMaterial({
    color: 0x33d4f4, transparent: true, opacity: 0.5,
    blending: THREE.AdditiveBlending, depthWrite: false,
  });
  charge.waterHelix = new THREE.Mesh(helixGeo, helixMat);
  charge.waterHelix.visible = false;
  scene.add(charge.waterHelix);

  charge.waterCore = new THREE.Mesh(
    new THREE.SphereGeometry(1, 24, 16),
    new THREE.MeshBasicMaterial({ color: 0x9bf3ff, transparent: true, opacity: 0.62, blending: THREE.AdditiveBlending, depthWrite: false }),
  );
  charge.waterCore.visible = false;
  scene.add(charge.waterCore);
  charge.waterGlow = new THREE.Sprite(new THREE.SpriteMaterial({
    map: TEX.flash, color: 0x6be6ff, transparent: true, opacity: 0.7,
    depthWrite: false, depthTest: false, blending: THREE.AdditiveBlending, toneMapped: false,
  }));
  charge.waterGlow.scale.setScalar(2.6);
  charge.waterGlow.visible = false;
  scene.add(charge.waterGlow);

  const dropGeo = new THREE.SphereGeometry(1, 8, 6);
  const dropMat = new THREE.MeshBasicMaterial({
    color: 0xbfefff, transparent: true, opacity: 0.8,
    blending: THREE.AdditiveBlending, depthWrite: false,
  });
  for (let i = 0; i < 28; i++) {
    const d = new THREE.Mesh(dropGeo, dropMat);
    d.visible = false;
    scene.add(d);
    charge.waterDrops.push({ mesh: d, i });
  }
}

function crownFrame() {
  let cx = 0, cz = 0;
  for (const ch of characters) { cx += ch.root.position.x; cz += ch.root.position.z; }
  cx /= characters.length; cz /= characters.length;
  let maxd = 0;
  for (const ch of characters) {
    maxd = Math.max(maxd, Math.hypot(ch.root.position.x - cx, ch.root.position.z - cz));
  }
  return { center: new THREE.Vector3(cx, 0, cz), radius: maxd + 1.30 };
}

function crownMat(color, opacity, additive = true) {
  return new THREE.MeshBasicMaterial({
    color, transparent: true, opacity, side: THREE.DoubleSide,
    depthWrite: false, blending: additive ? THREE.AdditiveBlending : THREE.NormalBlending,
  });
}

function paperWaveShape(w, h) {
  const s = new THREE.Shape();
  s.moveTo(-w / 2, 0);
  s.quadraticCurveTo(-w * 0.46, h * 0.24, -w * 0.32, h * 0.52);
  s.quadraticCurveTo(-w * 0.18, h * 0.80, w * 0.02, h * 0.86);
  s.quadraticCurveTo(w * 0.22, h * 0.92, w * 0.30, h * 0.70);
  s.quadraticCurveTo(w * 0.36, h * 0.50, w * 0.26, h * 0.34);
  s.quadraticCurveTo(w * 0.20, h * 0.22, w * 0.32, h * 0.12);
  s.quadraticCurveTo(w * 0.42, h * 0.04, w / 2, 0);
  s.closePath();
  return s;
}

function waterBladeShape(w, h) {
  const s = new THREE.Shape();
  s.moveTo(-w / 2, 0);
  s.bezierCurveTo(-w * 0.44, h * 0.16, -w * 0.38, h * 0.64, -w * 0.10, h * 0.84);
  s.bezierCurveTo(w * 0.08, h * 0.96, w * 0.25, h * 0.82, w * 0.29, h * 0.62);
  s.bezierCurveTo(w * 0.34, h * 0.42, w * 0.40, h * 0.20, w / 2, 0);
  s.closePath();
  return s;
}

function paperCurlShape(radius, width, start = 0.2, end = 2.5) {
  const s = new THREE.Shape();
  s.absarc(0, 0, radius, start, end, false);
  s.absarc(0, 0, radius - width, end, start, true);
  s.closePath();
  return s;
}

function buildCrown(option, center, R) {
  const root = new THREE.Group();
  root.position.set(center.x, 0.015, center.z);
  scene.add(root);
  const crown = {
    root, option, center: center.clone(), radius: R,
    age: 0, releasing: false, releaseT: 0, time: 0,
    spin: option === 'A' ? 0.32 : option === 'B' ? 0.12 : option === 'C' ? 0.10 : 0.90,
    materials: [],
  };
  const reg = (mat, shader = false) => {
    crown.materials.push({ mat, shader, base: shader ? 1 : mat.opacity });
    return mat;
  };

  const baseMat = reg(crownMat(option === 'D' ? 0x5fe0ff : 0x9fe8ff, option === 'D' ? 0.22 : 0.38));
  const baseGeo = new THREE.RingGeometry(R - 0.20, R + 0.05, option === 'B' ? 6 : option === 'C' ? 10 : 96);
  const base = new THREE.Mesh(baseGeo, baseMat);
  base.rotation.x = -Math.PI / 2;
  base.position.y = 0.015;
  root.add(base);

  if (option === 'A') {
    // Coroa de ondas de papel: diorama plano, sem espessura, montado como pop-up.
    const paperColors = [0x0f5668, 0x3aa3ad, 0xbfe9e0, 0xf3edde];
    crown.paperPanels = [];
    const lineMat = reg(new THREE.LineBasicMaterial({
      color: 0x082b33, transparent: true, opacity: 0.45, depthWrite: false,
    }));

    const panelCount = 6;
    for (let i = 0; i < panelCount; i++) {
      const x = -3.15 + (i / (panelCount - 1)) * 6.3;
      const z = -1.82 - Math.abs(x) * 0.10;
      const panel = new THREE.Group();
      panel.position.set(x, 0.015, z);
      panel.rotation.y = -x * 0.06;
      root.add(panel);

      const baseH = 1.42 + 0.16 * Math.sin(i * 1.55 + 0.4);
      const layers = [
        { color: paperColors[0], w: 1.98, h: baseH * 1.18, x: -0.06, y: 0.00, z: 0.000 },
        { color: paperColors[1], w: 1.70, h: baseH * 1.00, x: 0.04, y: 0.030, z: 0.014 },
      ];
      for (const cfg of layers) {
        const shape = paperWaveShape(cfg.w, cfg.h);
        const geo = new THREE.ShapeGeometry(shape, 32);
        const mat = reg(new THREE.MeshBasicMaterial({
          color: cfg.color, side: THREE.DoubleSide,
          transparent: false, opacity: 1, depthWrite: true,
        }));
        const layer = new THREE.Mesh(geo, mat);
        layer.position.set(cfg.x, cfg.y, cfg.z);
        panel.add(layer);
        const pts = shape.getPoints(72).map((p) => new THREE.Vector3(p.x, p.y, 0.002));
        const outline = new THREE.LineLoop(
          new THREE.BufferGeometry().setFromPoints(pts),
          lineMat,
        );
        layer.add(outline);
      }

      const foamMat = reg(new THREE.MeshBasicMaterial({
        color: 0xfbf7ea, side: THREE.DoubleSide,
        transparent: false, opacity: 1, depthWrite: true,
      }));
      const curlConfigs = [
        { r: 0.31, w: 0.085, x: 0.12, y: baseH * 0.76, rot: -0.15, start: 0.15, end: 2.7 },
        { r: 0.22, w: 0.070, x: -0.19, y: baseH * 0.84, rot: 0.45, start: 0.25, end: 2.4 },
      ];
      for (const c of curlConfigs) {
        const curlShape = paperCurlShape(c.r, c.w, c.start, c.end);
        const curl = new THREE.Mesh(new THREE.ShapeGeometry(curlShape, 24), foamMat);
        curl.position.set(c.x, c.y, 0.030);
        curl.rotation.z = c.rot;
        panel.add(curl);
        const pts = curlShape.getPoints(48).map((p) => new THREE.Vector3(p.x, p.y, 0.002));
        const outline = new THREE.LineLoop(
          new THREE.BufferGeometry().setFromPoints(pts),
          lineMat,
        );
        curl.add(outline);
      }

      const foamGeo = new THREE.CircleGeometry(0.062, 10);
      for (let k = 0; k < 3; k++) {
        const foam = new THREE.Mesh(foamGeo, foamMat);
        foam.position.set(-0.22 + k * 0.16, baseH * 0.83 + 0.04 * Math.sin(k * 2.0 + i), 0.034);
        foam.scale.setScalar(0.55 + (k % 2) * 0.30);
        panel.add(foam);
      }
      crown.paperPanels.push(panel);
    }

    // Sol de papel atrás do diorama.
    const sun = new THREE.Group();
    sun.position.set(0, 2.35, -3.15);
    root.add(sun);

    const sunMat = reg(new THREE.MeshBasicMaterial({
      color: 0xf3edde, side: THREE.DoubleSide,
      transparent: false, opacity: 1, depthWrite: true,
    }));
    const sunDisc = new THREE.Mesh(new THREE.CircleGeometry(0.78, 64), sunMat);
    sun.add(sunDisc);

    const rayMat = reg(new THREE.MeshBasicMaterial({
      color: 0xe9dfc9, side: THREE.DoubleSide,
      transparent: false, opacity: 1, depthWrite: true,
    }));
    for (let i = 0; i < 12; i++) {
      const a = (i / 12) * TAU;
      const rayShape = new THREE.Shape();
      rayShape.moveTo(-0.060, 0.86);
      rayShape.lineTo(0.060, 0.86);
      rayShape.lineTo(0, 1.22);
      rayShape.closePath();
      const ray = new THREE.Mesh(new THREE.ShapeGeometry(rayShape), rayMat);
      ray.rotation.z = a;
      sun.add(ray);
    }

    const sunPts = [];
    for (let i = 0; i < 72; i++) {
      const a = (i / 72) * TAU;
      sunPts.push(new THREE.Vector3(Math.cos(a) * 0.785, Math.sin(a) * 0.785, 0.002));
    }
    const sunLine = new THREE.LineLoop(
      new THREE.BufferGeometry().setFromPoints(sunPts),
      lineMat,
    );
    sunDisc.add(sunLine);
    crown.paperPanels.push(sun);
  } else if (option === 'B') {
    // Coroa-colmeia: portal hexagonal atrás, placas no chão e anéis finos.
    const latticeMat = reg(new THREE.MeshBasicMaterial({
      map: TEX.hex, transparent: true, opacity: 0.17, side: THREE.DoubleSide,
      blending: THREE.AdditiveBlending, depthWrite: false,
    }));
    const lattice = new THREE.Mesh(new THREE.PlaneGeometry(8.0, 3.7), latticeMat);
    lattice.position.set(0, 1.65, -3.15);
    root.add(lattice);

    const lattice2Mat = reg(new THREE.MeshBasicMaterial({
      map: TEX.hex, transparent: true, opacity: 0.07, side: THREE.DoubleSide,
      blending: THREE.AdditiveBlending, depthWrite: false,
    }));
    const lattice2 = new THREE.Mesh(new THREE.PlaneGeometry(7.4, 3.4), lattice2Mat);
    lattice2.position.set(0, 1.52, -3.08);
    lattice2.rotation.z = Math.PI / 6;
    root.add(lattice2);

    const gateMat = reg(crownMat(0x8ff2e0, 0.62));
    const gateLineMat = reg(new THREE.LineBasicMaterial({
      color: 0xeaffff, transparent: true, opacity: 0.60, depthWrite: false,
    }));
    const gate = new THREE.Group();
    gate.position.set(0, 1.58, -2.35);
    root.add(gate);

    const paneMat = reg(new THREE.MeshBasicMaterial({
      color: 0x0b4654, transparent: true, opacity: 0.38, side: THREE.DoubleSide,
      blending: THREE.AdditiveBlending, depthWrite: false,
    }));
    const pane = new THREE.Mesh(new THREE.CircleGeometry(1.49, 6), paneMat);
    pane.rotation.z = Math.PI / 6;
    pane.position.z = -0.015;
    gate.add(pane);

    for (let j = 0; j < 3; j++) {
      const r = 0.95 + j * 0.25;
      const frame = new THREE.Mesh(new THREE.RingGeometry(r - 0.028, r, 6), gateMat);
      frame.rotation.z = Math.PI / 6;
      gate.add(frame);
      const pts = [];
      for (let k = 0; k < 6; k++) {
        const ang = (k / 6) * TAU + Math.PI / 6;
        pts.push(new THREE.Vector3(Math.cos(ang) * r, Math.sin(ang) * r, 0.002));
      }
      frame.add(new THREE.LineLoop(new THREE.BufferGeometry().setFromPoints(pts), gateLineMat));
    }

    const coreMat = reg(crownMat(0x7fe8dc, 0.55));
    const coreGeo = new THREE.CylinderGeometry(0.28, 0.42, 1.28, 6, 1, false);
    const core = new THREE.Mesh(coreGeo, coreMat);
    core.position.z = 0.04;
    core.rotation.x = Math.PI / 2;
    core.add(new THREE.LineSegments(new THREE.EdgesGeometry(coreGeo, 20), gateLineMat));
    gate.add(core);
    crown.hexGate = gate;
    crown.hexCore = core;
    crown.lattice2 = lattice2;

    const plateMat = reg(crownMat(0x1f8f9a, 0.48));
    const plateLineMat = reg(new THREE.LineBasicMaterial({
      color: 0xbffcf0, transparent: true, opacity: 0.38, depthWrite: false,
    }));
    crown.hexPlates = [];
    for (let i = 0; i < 6; i++) {
      const a = (i / 6) * TAU + 0.28;
      const rr = R - 0.42;
      const plate = new THREE.Mesh(new THREE.CylinderGeometry(0.58, 0.58, 0.035, 6, 1, false), plateMat);
      plate.position.set(Math.cos(a) * rr, 0.04, Math.sin(a) * rr);
      plate.rotation.y = a;
      plate.add(new THREE.LineSegments(new THREE.EdgesGeometry(plate.geometry, 20), plateLineMat));
      plate.userData.noPiece = true;
      plate.scale.set(0.01, 1, 0.01);
      root.add(plate);
      crown.hexPlates.push({ mesh: plate, delay: 0.02 + i * 0.035 });
    }

    const ringMat = reg(crownMat(0x9ff2ff, 0.20));
    crown.hexRings = [];
    for (let j = 0; j < 3; j++) {
      const r = R - 0.50 + j * 0.16;
      const ring = new THREE.Mesh(new THREE.RingGeometry(r, r + 0.022, 6), ringMat);
      ring.rotation.x = -Math.PI / 2;
      ring.rotation.z = j * 0.30;
      ring.position.y = 0.03 + j * 0.025;
      ring.userData.noPiece = true;
      ring.scale.setScalar(0.01);
      root.add(ring);
      crown.hexRings.push(ring);
    }
  } else if (option === 'C') {
    // Coroa caleidoscópica: discos de luz, anéis de prismas e diamante central.
    const kaleidoMat = reg(new THREE.MeshBasicMaterial({
      map: TEX.kaleido, transparent: true, opacity: 0.26, side: THREE.DoubleSide,
      blending: THREE.AdditiveBlending, depthWrite: false,
    }));
    const kaleido = new THREE.Mesh(new THREE.CircleGeometry(3.55, 64), kaleidoMat);
    kaleido.position.set(0, 1.72, -3.02);
    root.add(kaleido);
    crown.kaleido = kaleido;

    const fanColors = [0x1f6f8f, 0x2f9fb0, 0x5f57c8, 0x9fe6dc];
    const fanMats = fanColors.map((color) => reg(new THREE.MeshBasicMaterial({
      color, side: THREE.DoubleSide, transparent: true, opacity: 0.86, depthWrite: true,
    })));
    const fanEdgeMat = reg(new THREE.LineBasicMaterial({
      color: 0xe2ffff, transparent: true, opacity: 0.48, depthWrite: false,
    }));
    const tri = new THREE.Shape();
    tri.moveTo(0, 0);
    tri.lineTo(-0.31, 2.28);
    tri.lineTo(0.31, 2.28);
    tri.closePath();
    const triGeo = new THREE.ShapeGeometry(tri, 1);
    const triPts = tri.getPoints(3).map((p) => new THREE.Vector3(p.x, p.y, 0.002));

    const fan = new THREE.Group();
    fan.position.set(0, 0.10, -2.34);
    root.add(fan);
    for (let i = 0; i < 12; i++) {
      const a = -Math.PI * 0.43 + (i / 11) * Math.PI * 0.86;
      const blade = new THREE.Mesh(triGeo, fanMats[i % fanMats.length]);
      blade.rotation.z = a;
      blade.add(new THREE.LineLoop(new THREE.BufferGeometry().setFromPoints(triPts), fanEdgeMat));
      fan.add(blade);
    }
    crown.fan = fan;

    const fan2 = new THREE.Group();
    fan2.position.set(0, 0.16, -2.42);
    fan2.rotation.z = Math.PI / 12;
    fan2.scale.setScalar(0.72);
    root.add(fan2);
    for (let i = 0; i < 12; i++) {
      const a = -Math.PI * 0.43 + (i / 11) * Math.PI * 0.86;
      const blade = new THREE.Mesh(triGeo, fanMats[(i + 2) % fanMats.length]);
      blade.rotation.z = a;
      fan2.add(blade);
    }
    crown.fan2 = fan2;

    const kaleido2Mat = reg(new THREE.MeshBasicMaterial({
      map: TEX.kaleido, transparent: true, opacity: 0.18, side: THREE.DoubleSide,
      blending: THREE.AdditiveBlending, depthWrite: false,
    }));
    const kaleido2 = new THREE.Mesh(new THREE.CircleGeometry(2.6, 64), kaleido2Mat);
    kaleido2.position.set(0, 1.62, -2.90);
    kaleido2.rotation.z = Math.PI / 6;
    root.add(kaleido2);
    crown.kaleido2 = kaleido2;

    const prismColors = [0x1f6f8f, 0x2f9fb0, 0x6d5fd0, 0x9fe6dc];
    const prismMats = prismColors.map((color) => reg(new THREE.MeshBasicMaterial({
      color, side: THREE.DoubleSide, transparent: true, opacity: 0.88, depthWrite: true,
    })));
    const edgeMat = reg(new THREE.LineBasicMaterial({
      color: 0xd8ffff, transparent: true, opacity: 0.55, depthWrite: false,
    }));
    crown.prismRings = [];
    const ringDefs = [
      { count: 8, radius: 2.62, height: 1.52, phase: 0.0, dir: 1 },
    ];
    for (let ring = 0; ring < ringDefs.length; ring++) {
      const def = ringDefs[ring];
      const group = new THREE.Group();
      root.add(group);
      for (let i = 0; i < def.count; i++) {
        const a = (i / def.count) * TAU + def.phase;
        if (Math.sin(a) > 0.5) continue;
        const geo = new THREE.CylinderGeometry(0.075, 0.24, def.height, 3, 1);
        const prism = new THREE.Mesh(geo, prismMats[i % prismMats.length]);
        prism.position.set(Math.cos(a) * def.radius, def.height * 0.5 + 0.02, Math.sin(a) * def.radius);
        prism.rotation.y = a;
        prism.rotation.z = -Math.cos(a) * 0.18;
        prism.rotation.x = Math.sin(a) * 0.18;
        prism.add(new THREE.LineSegments(new THREE.EdgesGeometry(geo, 18), edgeMat));
        group.add(prism);
      }
      crown.prismRings.push({ group, dir: def.dir });
    }

    const shardMat = reg(crownMat(0xd8ffff, 0.62));
    const shardGeo = new THREE.TetrahedronGeometry(0.09, 0);
    const shardGroup = new THREE.Group();
    root.add(shardGroup);
    for (let i = 0; i < 12; i++) {
      const a = (i / 12) * TAU;
      const shard = new THREE.Mesh(shardGeo, shardMat);
      shard.position.set(Math.cos(a) * 1.18, 0.12 + (i % 3) * 0.16, Math.sin(a) * 1.18);
      shard.rotation.set(a * 1.7, a * 2.3, a * 0.9);
      shardGroup.add(shard);
    }
    crown.shardGroup = shardGroup;

    const diamondMat = reg(new THREE.MeshBasicMaterial({
      color: 0x2f9fb0, transparent: true, opacity: 0.82, side: THREE.DoubleSide, depthWrite: true,
    }));
    const diamondGeo = new THREE.OctahedronGeometry(0.38, 0);
    const diamond = new THREE.Mesh(diamondGeo, diamondMat);
    diamond.position.set(0, 1.56, -0.46);
    diamond.add(new THREE.LineSegments(new THREE.EdgesGeometry(diamondGeo, 1), edgeMat));
    root.add(diamond);
    crown.diamond = diamond;
  } else if (option === 'D') {
    // Coroa Maelstrom: lâminas de água sólida, coluna central e redemoinho.
    const bladeMat = makeMaelstromMaterial();
    reg(bladeMat, true);
    const spoutMat = makeMaelstromMaterial();
    reg(spoutMat, true);
    const foamMat = reg(new THREE.MeshBasicMaterial({
      color: 0xeaffff, transparent: true, opacity: 0.52,
      depthWrite: false, blending: THREE.AdditiveBlending, side: THREE.DoubleSide,
    }));
    const whirlMat = reg(new THREE.MeshBasicMaterial({
      color: 0x63d8ee, transparent: true, opacity: 0.18,
      depthWrite: false, blending: THREE.AdditiveBlending, side: THREE.DoubleSide,
    }));

    const spoutGeo = new THREE.CylinderGeometry(0.20, 0.78, 2.62, 24, 1, true);
    const spout = new THREE.Mesh(spoutGeo, spoutMat);
    spout.position.set(0, 1.31, -0.66);
    root.add(spout);
    crown.spout = spout;

    const spoutRings = [];
    for (let j = 0; j < 3; j++) {
      const ring = new THREE.Mesh(
        new THREE.TorusGeometry(0.28 + j * 0.13, 0.010, 6, 32),
        foamMat,
      );
      ring.rotation.x = Math.PI / 2;
      ring.position.set(0, 1.85 + j * 0.24, -0.66);
      root.add(ring);
      spoutRings.push(ring);
    }
    crown.spoutRings = spoutRings;

    crown.waterBlades = [];
    for (let i = 0; i < 8; i++) {
      const a = (i / 8) * TAU;
      const h = 1.24 + 0.10 * Math.sin(a * 3.0 + 0.8);
      const shape = waterBladeShape(0.94, h);
      const geo = new THREE.ShapeGeometry(shape, 32);
      geo.computeBoundingBox();
      {
        const bb = geo.boundingBox;
        const pos = geo.attributes.position;
        const uv = geo.attributes.uv;
        const dx = Math.max(0.001, bb.max.x - bb.min.x);
        const dy = Math.max(0.001, bb.max.y - bb.min.y);
        for (let v = 0; v < pos.count; v++) {
          uv.setXY(v, (pos.getX(v) - bb.min.x) / dx, (pos.getY(v) - bb.min.y) / dy);
        }
        uv.needsUpdate = true;
      }
      const blade = new THREE.Mesh(geo, bladeMat);
      blade.position.set(Math.cos(a) * (R - 0.34), 0.02, Math.sin(a) * (R - 0.34));
      blade.rotation.y = -a;
      root.add(blade);
      crown.waterBlades.push(blade);

      const curl = new THREE.Mesh(
        new THREE.ShapeGeometry(paperCurlShape(0.15, 0.050, 0.15, 2.6), 24),
        foamMat,
      );
      curl.position.set(0.02, h * 0.80, 0.012);
      curl.rotation.z = -0.18;
      blade.add(curl);

      const curl2 = new THREE.Mesh(
        new THREE.ShapeGeometry(paperCurlShape(0.10, 0.036, 0.3, 2.3), 20),
        foamMat,
      );
      curl2.position.set(-0.16, h * 0.87, 0.012);
      curl2.rotation.z = 0.5;
      blade.add(curl2);
    }

    crown.whirl = [];
    for (let j = 0; j < 3; j++) {
      const r = 2.10 + j * 0.32;
      const ring = new THREE.Mesh(
        new THREE.TorusGeometry(r, 0.009, 6, 72, Math.PI * 1.55),
        whirlMat,
      );
      ring.rotation.x = Math.PI / 2;
      ring.rotation.z = j * 1.8;
      ring.position.y = 0.02 + j * 0.025;
      root.add(ring);
      crown.whirl.push(ring);
    }

    const sigil = new THREE.Mesh(
      new THREE.PlaneGeometry(2.4, 2.4),
      reg(new THREE.MeshBasicMaterial({
        map: TEX.sigilD, color: 0x6fe6ff, transparent: true, opacity: 0.34,
        blending: THREE.AdditiveBlending, depthWrite: false, side: THREE.DoubleSide,
      })),
    );
    sigil.rotation.x = -Math.PI / 2;
    sigil.position.y = 0.026;
    root.add(sigil);
    crown.sigil = sigil;

    particles.stream({
      origin: new THREE.Vector3(center.x, 0.10, center.z),
      rate: 28, texture: TEX.drop, colorA: [0.8, 1, 1], colorB: [0.4, 0.9, 1],
      speed: [0.15, 0.55], size: [0.03, 0.09], life: [0.65, 1.25], radius: Math.max(0.5, R - 0.35),
      duration: WINDUP + 0.1, gravity: 0.30, ttl: WINDUP + 1.6,
    });
  } else {
    // Coroa Aegis: fallback antigo (não usado).
    const threadMat = makeCrownWaterMaterial(0.75);
    reg(threadMat, true);
    const bellMat = reg(new THREE.MeshBasicMaterial({
      color: 0x8feaff, transparent: true, opacity: 0.20, side: THREE.DoubleSide,
      depthWrite: false, blending: THREE.AdditiveBlending,
    }));
    const bellRimMat = reg(new THREE.MeshBasicMaterial({
      color: 0xd8ffff, transparent: true, opacity: 0.42,
      depthWrite: false, blending: THREE.AdditiveBlending,
    }));
    const crestMat = reg(new THREE.MeshBasicMaterial({
      color: 0xd8ffff, transparent: true, opacity: 0.55,
      depthWrite: false, blending: THREE.AdditiveBlending,
    }));
    const foamMat = reg(new THREE.MeshBasicMaterial({
      color: 0xeaffff, transparent: true, opacity: 0.50,
      depthWrite: false, blending: THREE.AdditiveBlending,
    }));
    const foamGeo = new THREE.SphereGeometry(1, 8, 6);
    crown.petals = [];
    crown.bells = [];
    crown.threads = [];
    crown.foam = [];

    const rimMat = reg(crownMat(0xaef7ff, 0.42));
    const rim = new THREE.Mesh(new THREE.RingGeometry(R + 0.00, R + 0.05, 96), rimMat);
    rim.rotation.x = -Math.PI / 2;
    rim.position.y = 0.02;
    root.add(rim);

    const SEGS = 12;
    const SPAN = 0.58;
    const NU = 10;
    const NV = 16;
    let petalIndex = 0;
    for (let i = 0; i < SEGS; i++) {
      const a = i / SEGS * TAU;
      const baseH = 1.95 + 0.12 * Math.sin(a * 3.0 + 0.7);
      const positions = [];
      const uvs = [];
      const indices = [];
      const topPts = [];
      for (let iu = 0; iu <= NU; iu++) {
        const u = iu / NU;
        const edge = Math.pow(Math.max(0, Math.sin(Math.PI * u)), 0.55);
        const h = baseH * (0.30 + 0.70 * edge);
        for (let iv = 0; iv <= NV; iv++) {
          const v = iv / NV;
          const ang = a + 0.060 * Math.sin(u * Math.PI) + 0.020 * Math.sin(v * 4.0 + u * 5.0);
          const r = (R - 0.46) + u * SPAN - 0.10 * v * v
            + 0.028 * Math.sin(u * Math.PI * 2 + v * 4.0);
          const y = 0.03 + v * h;
          const px = Math.cos(ang) * r;
          const pz = Math.sin(ang) * r;
          positions.push(px, y, pz);
          uvs.push(u, v);
          if (iv === NV) topPts.push(new THREE.Vector3(px, y, pz));
        }
      }
      for (let iu = 0; iu < NU; iu++) {
        for (let iv = 0; iv < NV; iv++) {
          const a0 = iu * (NV + 1) + iv;
          const b0 = a0 + NV + 1;
          indices.push(a0, b0, a0 + 1, a0 + 1, b0, b0 + 1);
        }
      }
      const geo = new THREE.BufferGeometry();
      geo.setAttribute('position', new THREE.Float32BufferAttribute(positions, 3));
      geo.setAttribute('uv', new THREE.Float32BufferAttribute(uvs, 2));
      geo.setIndex(indices);
      geo.computeVertexNormals();
      const mat = makeCrownWaterMaterial(0.95);
      reg(mat, true);
      const mesh = new THREE.Mesh(geo, mat);
      mesh.scale.y = 0.02;
      const crestCurve = new THREE.CatmullRomCurve3(topPts);
      const crest = new THREE.Mesh(
        new THREE.TubeGeometry(crestCurve, 24, baseH > 0.9 ? 0.014 : 0.009, 6, false),
        crestMat,
      );
      mesh.add(crest);
      const beadCount = baseH > 0.9 ? 5 : 3;
      for (let k = 1; k <= beadCount; k++) {
        const p = crestCurve.getPointAt(k / (beadCount + 1));
        const bead = new THREE.Mesh(foamGeo, foamMat);
        bead.position.copy(p);
        const bs = baseH > 0.9 ? 0.022 + 0.016 * (0.5 + 0.5 * Math.sin(k * 2.3 + i)) : 0.008;
        bead.scale.setScalar(bs);
        bead.userData.baseScale = bs;
        bead.userData.phase = k * 1.4 + i;
        mesh.add(bead);
        crown.foam.push(bead);
      }
      if (baseH > 0.9) {
        for (let k = 0; k < 4; k++) {
          const u = 0.18 + 0.64 * Math.random();
          const v = 0.22 + 0.55 * Math.random();
          const edge = Math.pow(Math.max(0, Math.sin(Math.PI * u)), 0.55);
          const ang = a + 0.060 * Math.sin(u * Math.PI) + 0.020 * Math.sin(v * 4.0 + u * 5.0);
          const r = (R - 0.46) + u * SPAN - 0.10 * v * v
            + 0.028 * Math.sin(u * Math.PI * 2 + v * 4.0) + 0.015;
          const y = 0.03 + v * baseH * (0.30 + 0.70 * edge);
          const drop = new THREE.Mesh(foamGeo, foamMat);
          drop.position.set(Math.cos(ang) * r, y, Math.sin(ang) * r);
          const ds = 0.010 + 0.013 * Math.random();
          drop.scale.setScalar(ds);
          drop.userData.baseScale = ds;
          drop.userData.phase = Math.random() * TAU;
          mesh.add(drop);
          crown.foam.push(drop);
        }
      }
      root.add(mesh);
      crown.petals.push({
        mesh, mat, baseAngle: a, frontScale: 1,
        delay: 0.02 + petalIndex * 0.018,
      });
      petalIndex++;
    }

    for (let i = 0; i < 2; i++) {
      const pts = [];
      for (let j = 0; j <= 48; j++) {
        const t = j / 48;
        const a = i * Math.PI + t * TAU * 1.30;
        const r = (R - 0.48) - 0.08 * t + 0.030 * Math.sin(t * Math.PI * 3.0);
        pts.push(new THREE.Vector3(Math.cos(a) * r, 0.08 + t * 0.92, Math.sin(a) * r));
      }
      const mesh = new THREE.Mesh(
        new THREE.TubeGeometry(new THREE.CatmullRomCurve3(pts), 64, 0.018, 7, false),
        threadMat,
      );
      mesh.userData.dir = i === 0 ? 1 : -1;
      root.add(mesh);
      crown.threads.push(mesh);
    }

    const jellyAngles = [0.10, 3.20, 4.30, 5.30];
    for (let i = 0; i < jellyAngles.length; i++) {
      const a = jellyAngles[i];
      const by = 1.72 + (i % 2) * 0.16;
      const group = new THREE.Group();
      group.position.set(Math.cos(a) * (R - 0.12), by, Math.sin(a) * (R - 0.12));
      const bell = new THREE.Mesh(
        new THREE.SphereGeometry(0.17, 14, 10, 0, TAU, 0, Math.PI / 2),
        bellMat,
      );
      group.add(bell);
      const rim = new THREE.Mesh(new THREE.TorusGeometry(0.17, 0.010, 6, 28), bellRimMat);
      rim.rotation.x = Math.PI / 2;
      group.add(rim);
      for (let k = 0; k < 4; k++) {
        const ta = k / 4 * TAU + 0.35;
        const tx = Math.cos(ta) * 0.10;
        const tz = Math.sin(ta) * 0.10;
        const pts = [
          new THREE.Vector3(tx, -0.015, tz),
          new THREE.Vector3(tx * 1.25, -0.18, tz * 1.25),
          new THREE.Vector3(tx * 1.55, -0.38, tz * 1.55),
        ];
        group.add(new THREE.Mesh(
          new THREE.TubeGeometry(new THREE.CatmullRomCurve3(pts), 10, 0.008, 4, false),
          threadMat,
        ));
      }
      group.scale.setScalar(0.01);
      group.userData.baseY = by;
      group.userData.phase = i * 1.9;
      group.userData.spin = (i % 2 === 0 ? 1 : -1) * 0.5;
      root.add(group);
      crown.bells.push(group);
    }

    const sigilMat = reg(new THREE.MeshBasicMaterial({
      map: TEX.sigilD, color: 0x7fe8ff, transparent: true, opacity: 0.42,
      blending: THREE.AdditiveBlending, depthWrite: false, side: THREE.DoubleSide,
    }));
    const sigil = new THREE.Mesh(new THREE.PlaneGeometry(1.7, 1.7), sigilMat);
    sigil.rotation.x = -Math.PI / 2;
    sigil.position.y = 0.022;
    root.add(sigil);
    crown.sigil = sigil;

    const sigilRingMat = reg(new THREE.MeshBasicMaterial({
      color: 0x9fe8ff, transparent: true, opacity: 0.28,
      blending: THREE.AdditiveBlending, depthWrite: false, side: THREE.DoubleSide,
    }));
    const sigilRing = new THREE.Mesh(new THREE.RingGeometry(0.80, 0.84, 64), sigilRingMat);
    sigilRing.rotation.x = -Math.PI / 2;
    sigilRing.position.y = 0.024;
    root.add(sigilRing);

    particles.stream({
      origin: new THREE.Vector3(center.x, 0.10, center.z),
      rate: 9, texture: TEX.bubble, colorA: [0.85, 1, 1], colorB: [0.4, 0.9, 1],
      speed: [0.35, 0.85], size: [0.03, 0.08], life: [0.45, 0.95], radius: 0.16,
      duration: WINDUP + 0.1, gravity: 1.05, ttl: WINDUP + 1.5,
    });
    particles.stream({
      origin: new THREE.Vector3(center.x, 0.08, center.z),
      rate: 20, texture: TEX.drop, colorA: [0.8, 1, 1], colorB: [0.4, 0.9, 1],
      speed: [0.15, 0.55], size: [0.03, 0.09], life: [0.65, 1.25], radius: Math.max(0.5, R - 0.30),
      duration: WINDUP + 0.1, gravity: 0.30, ttl: WINDUP + 1.6,
    });
  }

  crown.pieces = [];
  if (option !== 'D') {
    let pieceIndex = 0;
    for (const child of root.children) {
      if (child === base || !child.scale || child.userData.noPiece) continue;
      crown.pieces.push({
        mesh: child,
        base: child.scale.clone(),
        delay: 0.02 + pieceIndex * 0.024,
      });
      pieceIndex++;
    }
  }

  root.scale.setScalar(0.22);
  return crown;
}

function disposeCrown(crown) {
  if (!crown || !crown.root) return;
  const geos = new Set();
  const mats = new Set();
  crown.root.traverse((o) => {
    if (o.geometry) geos.add(o.geometry);
    if (o.material) {
      const arr = Array.isArray(o.material) ? o.material : [o.material];
      for (const m of arr) mats.add(m);
    }
  });
  for (const g of geos) g.dispose();
  for (const m of mats) m.dispose();
  crown.root.removeFromParent();
}

function updateCrown(dt) {
  const c = charge.crown;
  if (!c) return;
  c.age += dt;
  c.time += dt;

  const fovTarget = 43 - 1.3 * Math.sin(Math.PI * clamp(c.age / WINDUP, 0, 1));
  camera.fov += (fovTarget - camera.fov) * Math.min(1, dt * 8);
  camera.updateProjectionMatrix();

  if (!c.releasing) {
    const k = clamp(c.age / WINDUP, 0, 1);
    const e = easeOutCubic(k);
    c.root.rotation.y += dt * c.spin;
    c.root.scale.setScalar(0.22 + 0.78 * e);
    if (c.pieces) {
      for (const p of c.pieces) {
        const e2 = easeOutBack(clamp((k - p.delay) / 0.45, 0, 1));
        p.mesh.scale.copy(p.base).multiplyScalar(Math.max(0.01, e2));
      }
    }
    if (c.hexPlates) {
      for (const p of c.hexPlates) {
        const e2 = easeOutBack(clamp((k - p.delay) / 0.45, 0, 1));
        p.mesh.scale.set(Math.max(0.01, e2), 1, Math.max(0.01, e2));
      }
    }
    if (c.hexRings) {
      c.hexRings.forEach((ring, j) => {
        const e2 = easeOutBack(clamp((k - 0.05 - j * 0.04) / 0.45, 0, 1));
        ring.scale.setScalar(Math.max(0.01, e2));
        ring.rotation.z = j * 0.30 + c.time * (j % 2 ? -0.75 : 0.75);
      });
    }
    if (c.hexGate) {
      c.hexGate.rotation.z = Math.sin(c.time * 0.8) * 0.05;
    }
    if (c.hexCore) c.hexCore.rotation.z += dt * 0.55;
    if (c.lattice2) c.lattice2.rotation.z = Math.PI / 6 + c.time * 0.05;
    if (c.prismRings) {
      for (const ring of c.prismRings) ring.group.rotation.y += dt * 0.9 * ring.dir;
    }
    if (c.shardGroup) c.shardGroup.rotation.y -= dt * 1.35;
    if (c.diamond) {
      c.diamond.rotation.y += dt * 1.1;
      c.diamond.rotation.x += dt * 0.55;
    }
    if (c.kaleido) c.kaleido.rotation.z += dt * 0.04;
    if (c.kaleido2) c.kaleido2.rotation.z -= dt * 0.06;
    if (c.fan) c.fan.rotation.z = Math.sin(c.time * 0.55) * 0.05;
    if (c.fan2) c.fan2.rotation.z = Math.PI / 12 - c.time * 0.08;
    if (c.spout) c.spout.rotation.y += dt * 0.75;
    if (c.spoutRings) {
      c.spoutRings.forEach((ring, j) => {
        ring.rotation.z += dt * (j % 2 ? -0.7 : 0.7);
        ring.position.y = 1.85 + j * 0.24 + Math.sin(c.time * 1.8 + j) * 0.03;
      });
    }
    if (c.whirl) {
      c.whirl.forEach((ring, j) => {
        ring.rotation.z += dt * (j % 2 ? -0.55 : 0.55);
      });
    }
    if (c.sigil) c.sigil.rotation.z += dt * 0.35;
    const fade = 0.25 + 0.75 * e;
    for (const item of c.materials) {
      if (item.shader) {
        item.mat.uniforms.uAlpha.value = fade;
        item.mat.uniforms.uTime.value += dt;
      } else {
        item.mat.opacity = item.base * fade;
      }
    }
    charge.light.position.set(c.center.x, 0.80, c.center.z);
    charge.light.intensity = 3 + 9 * e;
    if (c.petals) {
      for (const p of c.petals) {
        const e2 = clamp((k - p.delay) / 0.44, 0, 1);
        const assembly = 0.02 + 0.98 * easeOutBack(e2);
        const worldA = p.baseAngle + c.root.rotation.y;
        const front = Math.max(0, Math.sin(worldA));
        const target = 1 - smoothstep(0.10, 0.45, front) * 0.95;
        p.frontScale += (target - p.frontScale) * Math.min(1, dt * 9);
        p.mesh.scale.y = assembly * p.frontScale;
        p.mat.uniforms.uReveal.value = e2;
      }
    }
    if (c.foam) {
      for (const f of c.foam) {
        f.scale.setScalar(f.userData.baseScale * (1 + 0.12 * Math.sin(c.time * 3.2 + f.userData.phase)));
      }
    }
    if (c.threads) {
      for (const th of c.threads) th.rotation.y += dt * 0.78 * th.userData.dir;
    }
    if (c.bells) {
      for (const bell of c.bells) {
        const e2 = easeOutBack(clamp((k - 0.30) / 0.40, 0, 1));
        bell.scale.setScalar(Math.max(0.01, e2));
        bell.position.y = bell.userData.baseY + Math.sin(c.time * 2.1 + bell.userData.phase) * 0.045;
        bell.rotation.y += dt * bell.userData.spin;
      }
    }
    if (c.sigil) {
      c.sigil.rotation.z = -c.time * 0.55;
      c.sigil.scale.setScalar(0.55 + 0.45 * e);
      c.sigil.material.opacity = 0.42 * fade * (0.30 + 0.70 * e);
    }
    if (k >= 1) beginRelease();
  } else {
    c.releaseT += dt;
    const rt = clamp(c.releaseT / 0.85, 0, 1);
    c.root.rotation.y += dt * c.spin * 1.7;
    c.root.scale.setScalar(1.02 + rt * 0.12);
    if (c.paperPanels) {
      for (const p of c.paperPanels) p.scale.setScalar(Math.max(0.001, 1 - rt));
    }
    for (const item of c.materials) {
      if (item.shader) {
        item.mat.uniforms.uAlpha.value = Math.max(0, 1 - rt);
        item.mat.uniforms.uTime.value += dt;
      } else {
        item.mat.opacity = Math.max(0, item.base * (1 - rt));
      }
    }
    if (c.petals) {
      for (let i = 0; i < c.petals.length; i++) {
        const p = c.petals[i];
        const rp = clamp((rt - i * 0.025) / 0.9, 0, 1);
        const worldA = p.baseAngle + c.root.rotation.y;
        const front = Math.max(0, Math.sin(worldA));
        const target = 1 - smoothstep(0.10, 0.45, front) * 0.95;
        p.frontScale += (target - p.frontScale) * Math.min(1, dt * 9);
        p.mesh.scale.y = Math.max(0.02, (1 - rp * rp) * p.frontScale);
        p.mat.uniforms.uReveal.value = 1 - rp;
      }
    }
    if (c.threads) {
      for (const th of c.threads) th.rotation.y += dt * 2.2 * th.userData.dir;
    }
    if (c.bells) {
      for (const bell of c.bells) {
        bell.scale.setScalar(Math.max(0.01, 1 - rt));
        bell.position.y = bell.userData.baseY - rt * 0.45;
      }
    }
    if (c.sigil) {
      c.sigil.rotation.z -= dt * 0.9;
      c.sigil.material.opacity = Math.max(0, 0.30 * (1 - rt));
    }
    charge.light.intensity = Math.max(0, 12 * (1 - rt));
    if (rt >= 1) {
      disposeCrown(c);
      charge.crown = null;
    }
  }
}

function startCharge() {
  charge.active = true;
  charge.releasing = false;
  charge.t = 0;
  charge.releaseT = 0;
  if (charge.crown) {
    disposeCrown(charge.crown);
    charge.crown = null;
  }
  // O wind-up agora é a coroa-vórtice; os elementos antigos ficam desligados.
  charge.mesh.visible = false;
  for (const o of charge.spiral) o.mesh.visible = false;
  for (const seed of charge.seeds) seed.visible = false;
  charge.waterHelix.visible = false;
  charge.waterCore.visible = false;
  charge.waterGlow.visible = false;
  for (const d of charge.waterDrops) d.mesh.visible = false;
  charge.partyRing.material.opacity = 0;
  for (const r of charge.allyRings) r.material.opacity = 0;

  const frame = crownFrame();
  charge.crown = buildCrown(state.option, frame.center, frame.radius);
  charge.light.position.set(frame.center.x, 0.80, frame.center.z);
  charge.light.intensity = 3;
}

function updateCharge(dt) {
  if (!charge.active) return;
  updateCrown(dt);
}

function clearFormationFX() {
  for (const fx of formationFX) {
    if (fx.seed) {
      fx.seed.geometry.dispose();
      fx.seedMat.dispose();
      fx.seed.removeFromParent();
      fx.ring.geometry.dispose();
      fx.ringMat.dispose();
      fx.ring.removeFromParent();
    } else {
      fx.tube.geometry.dispose();
      fx.tubeMat.dispose();
      fx.tube.removeFromParent();
    }
  }
  formationFX.length = 0;
}

function spawnFormationFX(center, R) {
  clearFormationFX();

  for (const ch of characters) {
    const seedMat = new THREE.MeshBasicMaterial({
      color: 0xbff8ff, transparent: true, opacity: 0.0,
      blending: THREE.AdditiveBlending, depthWrite: false, depthTest: true,
    });
    const seed = new THREE.Mesh(new THREE.SphereGeometry(1, 16, 12), seedMat);
    seed.position.copy(ch.center);
    seed.scale.setScalar(0.02);
    scene.add(seed);

    const ringMat = new THREE.MeshBasicMaterial({
      color: 0x9fe8ff, transparent: true, opacity: 0.0,
      blending: THREE.AdditiveBlending, depthWrite: false, side: THREE.DoubleSide,
    });
    const ring = new THREE.Mesh(new THREE.RingGeometry(0.18, 0.23, 64), ringMat);
    ring.rotation.x = -Math.PI / 2;
    ring.position.set(ch.root.position.x, 0.03, ch.root.position.z);
    ring.scale.setScalar(0.4);
    scene.add(ring);

    formationFX.push({ kind: 'seed', seed, seedMat, ring, ringMat, age: 0, delay: ch.index * 0.035 });
  }
}

function updateFormationFX(dt) {
  for (let i = formationFX.length - 1; i >= 0; i--) {
    const fx = formationFX[i];
    fx.age += dt;
    const local = Math.max(0, fx.age - fx.delay);

    if (fx.kind === 'seed') {
      const t = clamp(local / 0.78, 0, 1);
      const pulse = Math.sin(Math.PI * Math.min(1, t * 1.08));
      fx.seed.scale.setScalar(0.04 + 0.92 * pulse);
      fx.seedMat.opacity = (1 - t) * 0.95;
      fx.ring.scale.setScalar(0.35 + 0.85 * easeOutCubic(t));
      fx.ringMat.opacity = Math.sin(Math.PI * t) * 0.55;
      if (t >= 1) {
        fx.seed.geometry.dispose();
        fx.seedMat.dispose();
        fx.seed.removeFromParent();
        fx.ring.geometry.dispose();
        fx.ringMat.dispose();
        fx.ring.removeFromParent();
        formationFX.splice(i, 1);
      }
    } else {
      const t = clamp(local / 0.85, 0, 1);
      fx.tubeMat.opacity = Math.sin(Math.PI * t) * 0.22;
      if (t >= 1) {
        fx.tube.geometry.dispose();
        fx.tubeMat.dispose();
        fx.tube.removeFromParent();
        formationFX.splice(i, 1);
      }
    }
  }
}

function beginRelease() {
  if (charge.releasing) return;
  charge.releasing = true;
  charge.releaseT = 0;
  const c = charge.crown;
  if (c) {
    c.releasing = true;
    c.releaseT = 0;
  }
  const option = state.option;
  const texture = option === 'C' ? TEX.shard : option === 'D' ? TEX.drop : TEX.bubble;
  const center = c ? c.center : new THREE.Vector3(0, 0, 0.3);
  const R = c ? c.radius : 2.7;
  for (let i = 0; i < 10; i++) {
    const a = i / 10 * TAU;
    particles.burst({
      origin: new THREE.Vector3(center.x + Math.cos(a) * (R - 0.1), 0.18, center.z + Math.sin(a) * (R - 0.1)),
      count: 8, texture, colorA: [0.8, 1, 1], colorB: [0.4, 0.9, 1],
      speed: [0.5, 1.9], size: option === 'C' ? [0.04, 0.10] : [0.04, 0.13],
      life: [0.35, 0.9], radius: 0.14, gravity: 0.35, ttl: 1.4,
    });
  }
  for (const ch of characters) {
    particles.stream({
      origin: new THREE.Vector3(ch.root.position.x, 0.05, ch.root.position.z),
      rate: 18, texture, colorA: [0.8, 1, 1], colorB: [0.4, 0.9, 1],
      speed: [0.7, 1.7], size: option === 'C' ? [0.03, 0.09] : [0.04, 0.12],
      life: [0.40, 0.85], radius: 0.28, duration: 0.7, gravity: 0.6, ttl: 1.5,
    });
  }
  spawnFormationFX(center, R);
  if (option === 'D') addReleaseRing(caster.root.position.clone());
}

function launchBubbles() {
  characters.forEach((ch, i) => {
    const start = charge.mesh.position.clone();
    const end = ch.center.clone();
    const mid = start.clone().lerp(end, 0.5).add(new THREE.Vector3(0, 0.9 + 0.15 * i, 0));
    for (let n = 0; n < 5; n++) {
      const mat = makeSoapMaterial(new THREE.Color(0.8, 0.98, 1.0));
      const mesh = new THREE.Mesh(new THREE.SphereGeometry(1, 24, 16), mat);
      mesh.scale.setScalar(0.10 + Math.random() * 0.06);
      scene.add(mesh);
      flightBubbles.push({
        mesh, t: -n * 0.035 - i * 0.05, life: 0.3, start, mid, end,
        curve: new THREE.CubicBezierCurve3(start, mid, mid.clone().add(new THREE.Vector3(0, 0.3, 0)), end),
      });
    }
  });
}

function updateFlightBubbles(dt) {
  for (let i = flightBubbles.length - 1; i >= 0; i--) {
    const b = flightBubbles[i];
    b.t += dt;
    if (b.t < 0) {
      b.mesh.visible = false;
      continue;
    }
    b.mesh.visible = true;
    const k = clamp(b.t / b.life, 0, 1);
    b.mesh.position.copy(b.curve.getPointAt(easeOutCubic(k)));
    b.mesh.scale.setScalar((0.1 + k * 0.12) * (1 - smoothstep(0.8, 1, k) * 0.5));
    b.mesh.material.uniforms.uTime.value += dt;
    if (k >= 1) {
      particles.burst({
        origin: b.mesh.position.clone(), count: 8, texture: TEX.spark,
        colorA: [0.9, 1, 1], colorB: [0.6, 1, 0.9],
        speed: [0.4, 1.2], size: [0.05, 0.12], life: [0.25, 0.55], radius: 0.05, gravity: 0.2, ttl: 1.0,
      });
      b.mesh.geometry.dispose();
      b.mesh.material.dispose();
      b.mesh.removeFromParent();
      flightBubbles.splice(i, 1);
    }
  }
}

// ---------------------------------------------------------------------------
// OpÃ§Ã£o A â€” bolha de sabÃ£o clÃ¡ssica
// ---------------------------------------------------------------------------

class ShieldA {
  constructor(ch) {
    this.ch = ch;
    this.group = new THREE.Group();
    this.group.position.copy(ch.center);
    scene.add(this.group);
    this.material = makeSoapMaterial(new THREE.Color(0.72, 0.97, 1.0));
    this.shell = new THREE.Mesh(new THREE.SphereGeometry(ch.radius, 64, 48), this.material);
    this.group.add(this.shell);
    this.rings = [];
    this.hitPulse = 0;
    for (let i = 0; i < 2; i++) {
      const r = new THREE.Mesh(
        new THREE.RingGeometry(0.62 + i * 0.16, 0.69 + i * 0.16, 64),
        new THREE.MeshBasicMaterial({ color: 0x9ff3ff, transparent: true, opacity: 0.28 - i * 0.08, side: THREE.DoubleSide, depthWrite: false, blending: THREE.AdditiveBlending }),
      );
      r.rotation.x = -Math.PI / 2;
      r.position.y = -0.80;
      this.group.add(r);
      this.rings.push(r);
    }
    this.age = 0;
    this.spawning = true;
    this.breaking = false;
    this.expiring = false;
    this.done = false;
    this.rise = 0;
    this.popped = false;
    this.flash = 0;
    this.group.scale.setScalar(0.02);
    this.mote = particles.stream({
      origin: ch.center.clone(), rate: 10, texture: TEX.bubble,
      colorA: [0.8, 1, 1], colorB: [0.5, 0.92, 1], speed: [0.05, 0.3],
      size: [0.035, 0.09], life: [0.8, 1.5], radius: 0.68, duration: DURATION + 1.0,
      gravity: 0.25, ttl: DURATION + 1.4,
    });
  }

  update(dt) {
    if (this.done) return;
    this.age += dt;
    this.material.uniforms.uTime.value += dt;
    this.material.uniforms.uHitAge.value += dt;
    this.material.uniforms.uHitStrength.value = Math.max(0, this.material.uniforms.uHitStrength.value - dt * 1.8);
    this.flash = Math.max(0, this.flash - dt * 2.8);
    this.material.uniforms.uHit.value = this.flash;
    this.rings.forEach((r, i) => {
      const p = 0.5 + 0.5 * Math.sin(this.age * 1.4 + i * 2.2);
      r.material.opacity = (0.10 + p * 0.10) * (1 - this.flash * 0.4);
      r.scale.setScalar(0.94 + p * 0.05);
    });
    this.hitPulse = Math.max(0, this.hitPulse - dt * 4.0);
    if (!this.spawning && !this.expiring && !this.breaking) {
      this.group.scale.setScalar(1 + Math.sin(this.hitPulse * Math.PI) * 0.055);
    }
    if (this.spawning) {
      const t = clamp(this.age / 0.82, 0, 1);
      const s = easeOutBack(t);
      this.group.scale.setScalar(Math.max(0.02, s));
      if (t >= 1) this.spawning = false;
    }
    if (this.expiring) {
      this.rise += dt;
      const t = this.rise;
      const lift = easeOutCubic(clamp(t / 0.9, 0, 1));
      this.group.position.y = this.ch.center.y + lift * 0.85 + Math.sin(t * 11.0) * 0.035;
      this.group.position.x = this.ch.center.x + Math.sin(t * 6.0) * 0.025;
      this.group.scale.setScalar(1 + Math.sin(t * 5.0) * 0.03);
      this.material.uniforms.uOpacity.value = Math.max(0, 1 - t / 1.25);
      this.rings.forEach((r) => (r.material.opacity = Math.max(0, r.material.opacity - dt * 0.8)));
      if (!this.popped && t >= 0.85) {
        this.popped = true;
        this.popT = 0;
        addFlash(this.group.position.clone(), 0xffffff, 0.7, 0.22);
        particles.burst({
          origin: this.group.position.clone(), count: 64, texture: TEX.bubble,
          colorA: [0.9, 1, 1], colorB: [0.45, 0.9, 1], speed: [1.0, 3.2],
          size: [0.06, 0.18], life: [0.4, 1.1], radius: 0.5, gravity: 0.8, ttl: 1.8,
        });
        particles.burst({
          origin: this.group.position.clone(), count: 24, texture: TEX.shard,
          colorA: [0.9, 1, 1], colorB: [0.5, 0.95, 1], speed: [1.2, 3.6],
          size: [0.05, 0.14], life: [0.3, 0.9], radius: 0.4, gravity: 0.5, ttl: 1.4,
        });
      }
      if (this.popped) {
        this.popT += dt;
        this.group.scale.setScalar(1 + easeOutCubic(clamp(this.popT / 0.22, 0, 1)) * 0.75);
        this.material.uniforms.uOpacity.value = Math.max(0, this.material.uniforms.uOpacity.value - dt * 5.5);
      }
      if (t > 1.25) this.finish();
    }
    if (this.breaking) {
      this.material.uniforms.uOpacity.value = Math.max(0, this.material.uniforms.uOpacity.value - dt * 2.5);
      this.group.scale.setScalar(1 + (1 - this.material.uniforms.uOpacity.value) * 0.35);
      if (this.material.uniforms.uOpacity.value <= 0.01) this.finish();
    }
  }

  hit(worldPoint) {
    if (this.done) return;
    this.flash = 1;
    this.hitPulse = 1;
    this.material.uniforms.uHit.value = 1;
    const local = this.group.worldToLocal(worldPoint.clone());
    const dir = local.normalize();
    this.material.uniforms.uHitDir.value.copy(dir);
    this.material.uniforms.uHitAge.value = 0;
    this.material.uniforms.uHitStrength.value = 1.15;
    addFlash(worldPoint.clone(), 0xffffff, 0.18, 0.12);
    particles.burst({
      origin: worldPoint.clone(), count: 40, texture: TEX.bubble,
      colorA: [0.9, 1, 1], colorB: [0.45, 0.9, 1], speed: [0.8, 2.8],
      size: [0.05, 0.16], life: [0.3, 0.9], radius: 0.08, gravity: 0.6, ttl: 1.5,
    });
    particles.burst({
      origin: worldPoint.clone(), count: 14, texture: TEX.drop,
      colorA: [0.9, 1, 1], colorB: [0.5, 0.95, 1], speed: [1.0, 3.0],
      size: [0.04, 0.11], life: [0.25, 0.7], radius: 0.05, gravity: 0.35, ttl: 1.2,
    });
    particles.burst({
      origin: worldPoint.clone(), count: 12, texture: TEX.shard,
      colorA: [0.9, 1, 1], colorB: [0.5, 0.95, 1], speed: [0.9, 3.0],
      size: [0.04, 0.10], life: [0.25, 0.7], radius: 0.05, gravity: 0.4, ttl: 1.2,
    });
    return dir;
  }

  breakShield() {
    if (this.done || this.breaking) return;
    this.breaking = true;
    this.material.uniforms.uOpacity.value = 1;
    this.mote.ttl = 0.01;
    particles.burst({
      origin: this.group.position.clone(), count: 70, texture: TEX.bubble,
      colorA: [0.9, 1, 1], colorB: [0.45, 0.9, 1], speed: [1.2, 3.8],
      size: [0.06, 0.2], life: [0.5, 1.4], radius: 0.55, gravity: 0.8, ttl: 2.2,
    });
    particles.burst({
      origin: this.group.position.clone(), count: 26, texture: TEX.shard,
      colorA: [0.85, 1, 1], colorB: [0.4, 0.85, 1], speed: [1.5, 4.0],
      size: [0.06, 0.14], life: [0.5, 1.1], radius: 0.5, gravity: 0.5, ttl: 1.8,
    });
    addFlash(this.group.position.clone(), 0xe8ffff, 0.9, 0.22);
  }

  expire() {
    if (this.done || this.expiring) return;
    this.expiring = true;
    this.mote.ttl = 0.01;
    particles.burst({
      origin: this.group.position.clone(), count: 24, texture: TEX.bubble,
      colorA: [0.85, 1, 1], colorB: [0.5, 0.9, 1], speed: [0.4, 1.4],
      size: [0.05, 0.14], life: [0.5, 1.2], radius: 0.6, gravity: 0.8, ttl: 1.6,
    });
  }

  finish() {
    this.done = true;
    activeShields.delete(this);
    this.group.removeFromParent();
    this.shell.geometry.dispose();
    this.material.dispose();
    this.rings.forEach((r) => { r.geometry.dispose(); r.material.dispose(); });
  }
}

// ---------------------------------------------------------------------------
// OpÃ§Ã£o B â€” colmeia de bolhas
// ---------------------------------------------------------------------------

class ShieldB {
  constructor(ch) {
    this.ch = ch;
    this.group = new THREE.Group();
    this.group.position.copy(ch.center);
    scene.add(this.group);
    this.material = makeHoneycombMaterial();
    this.shell = new THREE.Mesh(new THREE.SphereGeometry(ch.radius, 64, 48), this.material);
    this.group.add(this.shell);

    this.age = 0;
    this.spawning = true;
    this.breaking = false;
    this.expiring = false;
    this.done = false;
    this.flash = 0;
    this.rise = 0;
    this.popped = false;
    this.hitPulse = 0;
    this.group.scale.setScalar(0.02);
    this.mote = particles.stream({
      origin: ch.center.clone(), rate: 9, texture: TEX.bubble,
      colorA: [0.8, 1, 1], colorB: [0.5, 0.92, 1], speed: [0.04, 0.28],
      size: [0.03, 0.08], life: [0.7, 1.5], radius: 0.64, duration: DURATION + 1.0,
      gravity: 0.22, ttl: DURATION + 1.4,
    });
  }

  update(dt) {
    if (this.done) return;
    this.age += dt;
    this.material.uniforms.uTime.value += dt;
    this.material.uniforms.uHitAge.value += dt;
    this.material.uniforms.uHitStrength.value = Math.max(0, this.material.uniforms.uHitStrength.value - dt * 1.8);
    this.flash = Math.max(0, this.flash - dt * 2.8);
    this.material.uniforms.uHit.value = this.flash;

    if (this.spawning) {
      const t = clamp(this.age / 0.85, 0, 1);
      this.group.scale.setScalar(Math.max(0.02, easeOutBack(t)));
      if (t >= 1) this.spawning = false;
    }
    this.hitPulse = Math.max(0, this.hitPulse - dt * 4.0);
    if (!this.spawning && !this.expiring && !this.breaking) {
      this.group.scale.setScalar(1 + Math.sin(this.hitPulse * Math.PI) * 0.05);
    }

    if (this.expiring) {
      this.rise += dt;
      const t = this.rise;
      this.group.position.y = this.ch.center.y + easeOutCubic(clamp(t / 0.85, 0, 1)) * 0.82 + Math.sin(t * 10.0) * 0.035;
      this.group.position.x = this.ch.center.x + Math.sin(t * 6.0) * 0.025;
      this.material.uniforms.uOpacity.value = Math.max(0, 1 - t / 1.2);
      if (!this.popped && t >= 0.82) {
        this.popped = true;
        this.popT = 0;
        addFlash(this.group.position.clone(), 0xffffff, 0.7, 0.22);
        particles.burst({
          origin: this.group.position.clone(), count: 60, texture: TEX.bubble,
          colorA: [0.9, 1, 1], colorB: [0.45, 0.9, 1], speed: [0.9, 3.0],
          size: [0.05, 0.17], life: [0.4, 1.1], radius: 0.5, gravity: 0.8, ttl: 1.8,
        });
        particles.burst({
          origin: this.group.position.clone(), count: 24, texture: TEX.shard,
          colorA: [0.9, 1, 1], colorB: [0.5, 0.95, 1], speed: [1.1, 3.4],
          size: [0.05, 0.14], life: [0.3, 0.9], radius: 0.45, gravity: 0.5, ttl: 1.4,
        });
      }
      if (this.popped) {
        this.popT += dt;
        this.group.scale.setScalar(1 + easeOutCubic(clamp(this.popT / 0.22, 0, 1)) * 0.72);
        this.material.uniforms.uOpacity.value = Math.max(0, this.material.uniforms.uOpacity.value - dt * 5.2);
      }
      if (t > 1.25) this.finish();
    }

    if (this.breaking) {
      this.material.uniforms.uOpacity.value = Math.max(0, this.material.uniforms.uOpacity.value - dt * 2.6);
      this.group.scale.setScalar(1 + (1 - this.material.uniforms.uOpacity.value) * 0.35);
      if (this.material.uniforms.uOpacity.value <= 0.01) this.finish();
    }
  }

  hit(worldPoint) {
    if (this.done) return;
    this.flash = 1;
    this.hitPulse = 1;
    this.material.uniforms.uHit.value = 1;
    const local = this.group.worldToLocal(worldPoint.clone()).normalize();
    this.material.uniforms.uHitDir.value.copy(local);
    this.material.uniforms.uHitAge.value = 0;
    this.material.uniforms.uHitStrength.value = 1.15;
    addFlash(worldPoint.clone(), 0xffffff, 0.18, 0.12);
    particles.burst({
      origin: worldPoint.clone(), count: 40, texture: TEX.bubble,
      colorA: [0.9, 1, 1], colorB: [0.45, 0.9, 1], speed: [0.8, 2.8],
      size: [0.05, 0.16], life: [0.3, 0.9], radius: 0.08, gravity: 0.6, ttl: 1.5,
    });
    particles.burst({
      origin: worldPoint.clone(), count: 14, texture: TEX.drop,
      colorA: [0.9, 1, 1], colorB: [0.5, 0.95, 1], speed: [1.0, 3.0],
      size: [0.04, 0.11], life: [0.25, 0.7], radius: 0.05, gravity: 0.35, ttl: 1.2,
    });
  }

  breakShield() {
    if (this.done || this.breaking) return;
    this.breaking = true;
    this.mote.ttl = 0.01;
    particles.burst({
      origin: this.group.position.clone(), count: 66, texture: TEX.bubble,
      colorA: [0.9, 1, 1], colorB: [0.45, 0.9, 1], speed: [1.2, 4.0],
      size: [0.06, 0.2], life: [0.5, 1.4], radius: 0.55, gravity: 0.7, ttl: 2.2,
    });
    particles.burst({
      origin: this.group.position.clone(), count: 28, texture: TEX.shard,
      colorA: [0.85, 1, 1], colorB: [0.4, 0.85, 1], speed: [1.4, 4.0],
      size: [0.06, 0.15], life: [0.5, 1.1], radius: 0.5, gravity: 0.5, ttl: 1.8,
    });
    addFlash(this.group.position.clone(), 0xffffff, 0.85, 0.2);
  }

  expire() {
    if (this.done || this.expiring) return;
    this.expiring = true;
    this.rise = 0;
    this.popped = false;
    this.mote.ttl = 0.01;
    particles.burst({
      origin: this.group.position.clone(), count: 20, texture: TEX.bubble,
      colorA: [0.85, 1, 1], colorB: [0.5, 0.9, 1], speed: [0.3, 1.2],
      size: [0.05, 0.12], life: [0.5, 1.2], radius: 0.55, gravity: 0.7, ttl: 1.6,
    });
  }

  finish() {
    this.done = true;
    activeShields.delete(this);
    this.group.removeFromParent();
    this.shell.geometry.dispose();
    this.material.dispose();
  }
}

class ShieldC {
  constructor(ch) {
    this.ch = ch;
    this.group = new THREE.Group();
    this.group.position.copy(ch.center);
    scene.add(this.group);
    this.material = makeFacetMaterial(new THREE.Color(0.74, 0.97, 1.0));
    const geo = new THREE.IcosahedronGeometry(0.94, 2);
    geo.computeVertexNormals();
    this.shell = new THREE.Mesh(geo, this.material);
    this.group.add(this.shell);
    const edgeGeo = new THREE.EdgesGeometry(geo, 8);
    this.edges = new THREE.LineSegments(edgeGeo, new THREE.LineBasicMaterial({
      color: 0xd8ffff, transparent: true, opacity: 0.22, depthWrite: false,
    }));
    this.group.add(this.edges);
    this.age = 0;
    this.spawning = true;
    this.breaking = false;
    this.expiring = false;
    this.done = false;
    this.flash = 0;
    this.group.scale.setScalar(0.02);
    this.group.rotation.y = Math.random() * TAU;
    this.rise = 0;
    this.popped = false;
    this.mote = particles.stream({
      origin: ch.center.clone(), rate: 9, texture: TEX.bubble,
      colorA: [0.8, 1, 1], colorB: [0.5, 0.92, 1], speed: [0.04, 0.28],
      size: [0.03, 0.08], life: [0.7, 1.5], radius: 0.62, duration: DURATION + 1.0,
      gravity: 0.22, ttl: DURATION + 1.4,
    });
  }

  update(dt) {
    if (this.done) return;
    this.age += dt;
    this.material.uniforms.uTime.value += dt;
    this.material.uniforms.uHitAge.value += dt;
    this.material.uniforms.uHitStrength.value = Math.max(0, this.material.uniforms.uHitStrength.value - dt * 1.8);
    this.flash = Math.max(0, this.flash - dt * 2.4);
    this.material.uniforms.uHit.value = this.flash;
    if (!this.expiring && !this.breaking) this.material.uniforms.uOpacity.value = 1;
    this.shell.rotation.y += dt * 0.04;
    this.edges.rotation.copy(this.shell.rotation);
    if (this.spawning) {
      const t = clamp(this.age / 0.85, 0, 1);
      this.group.scale.setScalar(Math.max(0.02, easeOutBack(t)));
      this.material.uniforms.uFreeze.value = smoothstep(0.45, 1.0, t);
      if (t >= 1) this.spawning = false;
    } else {
      this.material.uniforms.uFreeze.value = 1;
    }
    this.edges.material.opacity = 0.16 + Math.sin(this.age * 1.7) * 0.05 + this.flash * 0.5;
    if (this.expiring) {
      this.rise += dt;
      const t = this.rise;
      this.group.position.y = this.ch.center.y + easeOutCubic(clamp(t / 0.75, 0, 1)) * 0.7;
      this.group.position.x = this.ch.center.x + Math.sin(t * 6.5) * 0.035;
      this.group.rotation.y += dt * (1.0 + t * 2.0);
      this.material.uniforms.uOpacity.value = Math.max(0, 1 - t / 1.15);
      this.edges.material.opacity = Math.max(0, this.edges.material.opacity - dt * 0.8);
      if (!this.popped && t >= 0.72) {
        this.popped = true;
        this.popT = 0;
        this.edges.visible = false;
        this.shell.visible = false;
        addFlash(this.group.position.clone(), 0xffffff, 0.75, 0.22);
        particles.burst({
          origin: this.group.position.clone(), count: 60, texture: TEX.shard,
          colorA: [0.9, 1, 1], colorB: [0.4, 0.9, 1], speed: [1.4, 4.2],
          size: [0.06, 0.17], life: [0.4, 1.1], radius: 0.45, gravity: 0.35, ttl: 1.8,
        });
        particles.burst({
          origin: this.group.position.clone(), count: 32, texture: TEX.bubble,
          colorA: [0.9, 1, 1], colorB: [0.5, 0.95, 1], speed: [0.7, 2.4],
          size: [0.04, 0.14], life: [0.4, 1.0], radius: 0.55, gravity: 0.7, ttl: 1.6,
        });
      }
      if (this.popped) {
        this.popT += dt;
        this.group.scale.setScalar(1 + easeOutCubic(clamp(this.popT / 0.2, 0, 1)) * 0.7);
        this.material.uniforms.uOpacity.value = Math.max(0, this.material.uniforms.uOpacity.value - dt * 5.0);
      }
      if (t > 1.25) this.finish();
    }
    if (this.breaking) {
      this.material.uniforms.uOpacity.value = Math.max(0, this.material.uniforms.uOpacity.value - dt * 3.0);
      this.edges.material.opacity = Math.max(0, this.edges.material.opacity - dt * 2.0);
      this.group.scale.setScalar(1 + (1 - this.material.uniforms.uOpacity.value) * 0.4);
      if (this.material.uniforms.uOpacity.value <= 0.01) this.finish();
    }
  }

  hit(worldPoint) {
    if (this.done) return;
    this.flash = 0.25;
    this.material.uniforms.uHit.value = 0.20;
    const local = this.group.worldToLocal(worldPoint.clone()).normalize();
    this.material.uniforms.uHitDir.value.copy(local);
    this.material.uniforms.uHitAge.value = 0;
    this.material.uniforms.uHitStrength.value = 0.45;
    addFlash(worldPoint.clone(), 0xffffff, 0.18, 0.12);
    particles.burst({
      origin: worldPoint.clone(), count: 36, texture: TEX.shard,
      colorA: [0.85, 1, 1], colorB: [0.4, 0.85, 1], speed: [0.9, 3.0],
      size: [0.05, 0.15], life: [0.35, 0.9], radius: 0.07, gravity: 0.5, ttl: 1.4,
    });
    particles.burst({
      origin: worldPoint.clone(), count: 16, texture: TEX.drop,
      colorA: [0.9, 1, 1], colorB: [0.5, 0.95, 1], speed: [1.0, 3.0],
      size: [0.04, 0.11], life: [0.25, 0.7], radius: 0.05, gravity: 0.35, ttl: 1.2,
    });
  }

  breakShield() {
    if (this.done || this.breaking) return;
    this.breaking = true;
    this.mote.ttl = 0.01;
    particles.burst({
      origin: this.group.position.clone(), count: 46, texture: TEX.shard,
      colorA: [0.9, 1, 1], colorB: [0.4, 0.9, 1], speed: [1.4, 4.2],
      size: [0.07, 0.18], life: [0.5, 1.3], radius: 0.45, gravity: 0.4, ttl: 2.0,
    });
    particles.burst({
      origin: this.group.position.clone(), count: 30, texture: TEX.bubble,
      colorA: [0.9, 1, 1], colorB: [0.5, 0.95, 1], speed: [0.8, 2.6],
      size: [0.05, 0.15], life: [0.5, 1.2], radius: 0.55, gravity: 0.6, ttl: 1.8,
    });
    addFlash(this.group.position.clone(), 0xe8ffff, 0.9, 0.2);
  }

  expire() {
    if (this.done || this.expiring) return;
    this.expiring = true;
    this.mote.ttl = 0.01;
    particles.burst({
      origin: this.group.position.clone(), count: 18, texture: TEX.bubble,
      colorA: [0.85, 1, 1], colorB: [0.5, 0.9, 1], speed: [0.3, 1.2],
      size: [0.05, 0.12], life: [0.5, 1.2], radius: 0.55, gravity: 0.7, ttl: 1.6,
    });
  }

  finish() {
    this.done = true;
    activeShields.delete(this);
    this.group.removeFromParent();
    this.shell.geometry.dispose();
    this.material.dispose();
    this.edges.geometry.dispose();
    this.edges.material.dispose();
  }
}

// ---------------------------------------------------------------------------
// Estado / efeitos do Move
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Opção D — Aegis aquática (referência: bubble_shield_vfx_lab.html)
// Membrana fina de água tensionada: filamentos, rim Fresnel, depressão no
// impacto e onda circular; ruptura com gotas balísticas; expiração suave.
// ---------------------------------------------------------------------------

class ShieldD {
  constructor(ch) {
    this.ch = ch;
    this.group = new THREE.Group();
    this.group.position.copy(ch.center);
    scene.add(this.group);
    this.material = makeWaterMaterial();
    this.shell = new THREE.Mesh(new THREE.SphereGeometry(ch.radius, 64, 48), this.material);
    this.group.add(this.shell);
    this.core = new THREE.Sprite(new THREE.SpriteMaterial({
      map: TEX.sigilD, color: 0x9fe8ff, transparent: true, opacity: 0.32,
      blending: THREE.AdditiveBlending, depthWrite: false, depthTest: true, toneMapped: false,
    }));
    this.core.scale.setScalar(0.62);
    this.group.add(this.core);

    this.dropGeo = new THREE.SphereGeometry(1, 8, 6);
    this.dropMat = new THREE.MeshBasicMaterial({
      color: 0xbfefff, transparent: true, opacity: 0.32,
      blending: THREE.AdditiveBlending, depthWrite: false,
    });
    this.droplets = [];
    for (let i = 0; i < 9; i++) {
      const d = new THREE.Mesh(this.dropGeo, this.dropMat);
      d.scale.setScalar(0.92 * 0.013);
      this.group.add(d);
      this.droplets.push({
        mesh: d,
        theta: i * 2.3999,
        phi: Math.sin(i * 4.2) * 0.38 + Math.sin(i * 0.8) * 0.55,
        speed: 0.32 + (i % 3) * 0.04,
      });
    }

    this.age = 0;
    this.spawning = true;
    this.breaking = false;
    this.expiring = false;
    this.done = false;
    this.deathT = 0;
    this.group.scale.setScalar(0.01);
  }

  update(dt) {
    if (this.done) return;
    this.age += dt;
    const hpFrac = clamp(state.shieldHP[this.ch.index] / SHIELD_MAX, 0, 1);
    const depletion = 1 - hpFrac;
    this.material.uniforms.uTime.value += dt;
    this.material.uniforms.uDepletion.value = depletion;
    this.material.uniforms.uHitAge.value += dt;

    let fade = 1;
    let scale = 1;
    if (this.age < 0.90) {
      const a = clamp(this.age / 0.72, 0, 1);
      const b = clamp((this.age - 0.72) / 0.18, 0, 1);
      scale = clamp(1.12 * easeOutCubic(a) - 0.12 * easeOutCubic(b), 0.01, 1.14);
      this.spawning = false;
    } else {
      scale = 1 + 0.01 * Math.sin(this.age * 1.45 + this.ch.index) * Math.cos(this.age * 0.5);
    }

    if (this.expiring) {
      this.deathT += dt;
      const t = clamp(this.deathT / 0.43, 0, 1);
      fade = 1 - easeOutCubic(t);
      scale *= 1 + 0.11 * easeOutCubic(t);
      if (this.deathT > 0.9) this.finish();
    }
    if (this.breaking) {
      this.deathT += dt;
      const t = clamp(this.deathT / 0.20, 0, 1);
      fade = 1 - easeOutCubic(t);
      scale *= 1 - 0.17 * easeOutCubic(t);
      if (this.deathT > 0.9) this.finish();
    }

    if (!this.expiring && !this.breaking) {
      // A fraqueza visual anda com a resistência, não com o tempo.
      this.material.uniforms.uAlpha.value = 1;
      if (state.mode === 'active' && state.timer < 1.2) {
        const f = 0.8 + 0.2 * Math.sin(this.age * 8) * Math.sin(this.age * 8);
        this.material.uniforms.uAlpha.value = f;
      }
    } else {
      this.material.uniforms.uAlpha.value = fade;
    }

    this.group.scale.setScalar(scale);
    const toCam = camera.position.clone().sub(this.group.position).normalize();
    this.core.position.copy(toCam).multiplyScalar(0.62);
    const corePulse = 0.92 + 0.08 * Math.sin(this.age * 2.2);
    const hpFracCore = clamp(state.shieldHP[this.ch.index] / SHIELD_MAX, 0, 1);
    this.core.scale.setScalar((0.45 + 0.22 * hpFracCore) * corePulse);
    this.core.material.opacity = (0.10 + 0.32 * hpFracCore) * fade;
    for (const d of this.droplets) {
      d.theta += d.speed * dt;
      const cp = Math.cos(d.phi);
      const v = new THREE.Vector3(
        Math.cos(d.theta) * cp,
        Math.sin(d.phi),
        Math.sin(d.theta) * cp,
      ).normalize();
      d.mesh.position.copy(v).multiplyScalar(0.92 * 1.07);
      d.mesh.scale.setScalar(0.92 * 0.013 * (1 - depletion * 0.35));
    }
    this.dropMat.opacity = 0.32 * fade * (1 - depletion * 0.4);
  }

  hit(worldPoint) {
    if (this.done || this.breaking || this.expiring) return;
    const local = this.group.worldToLocal(worldPoint.clone()).normalize();
    this.material.uniforms.uHitDir.value.copy(local);
    this.material.uniforms.uHitAge.value = 0;
    this.material.uniforms.uPower.value = clamp(HIT_DAMAGE / 35, 0.3, 1.6);
    particles.burst({
      origin: worldPoint.clone(), count: 12, texture: TEX.drop,
      colorA: [0.8, 1, 1], colorB: [0.4, 0.9, 1], speed: [0.4, 1.6],
      size: [0.03, 0.09], life: [0.25, 0.7], radius: 0.04, gravity: 0.3, ttl: 1.1,
    });
  }

  breakShield() {
    if (this.done || this.breaking || this.expiring) return;
    this.breaking = true;
    this.deathT = 0;
    spawnWaterDebris(this.ch, 'break', 58);
  }

  expire() {
    if (this.done || this.breaking || this.expiring) return;
    this.expiring = true;
    this.deathT = 0;
    spawnWaterDebris(this.ch, 'soft', 30);
  }

  finish() {
    this.done = true;
    activeShields.delete(this);
    this.group.removeFromParent();
    this.shell.geometry.dispose();
    this.material.dispose();
    this.core.material.dispose();
    this.dropGeo.dispose();
    this.dropMat.dispose();
  }
}

function createShield(ch) {
  removeShield(ch, false);
  const shield = state.option === 'A' ? new ShieldA(ch) : state.option === 'B' ? new ShieldB(ch) : state.option === 'C' ? new ShieldC(ch) : new ShieldD(ch);
  ch.shield = shield;
  activeShields.add(shield);
}

function removeShield(ch, visual = true) {
  if (ch.shield) {
    if (visual) ch.shield.expire();
    else ch.shield.finish();
    ch.shield = null;
  }
}

function cast() {
  if (!loaded) return;
  if (autoCastTimer) { clearTimeout(autoCastTimer); autoCastTimer = 0; }
  if (state.mode === 'active' || state.mode === 'windup') {
    // D-324: reaplicaÃ§Ã£o do mesmo Move reseta, nÃ£o soma.
    clearShields(true);
    toast('RECONJURADO - RESET');
  }
  state.mode = 'windup';
  state.phaseT = 0;
  state.timer = DURATION;
  state.shielded = [false, false, false];
  state.shieldHP = [SHIELD_MAX, SHIELD_MAX, SHIELD_MAX];
  updateAllyHud();
  playCast(caster);
  startCharge();
  setPhase('WIND-UP', 0);
}

function releaseShields() {
  state.mode = 'active';
  state.timer = DURATION;
  state.shielded = [true, true, true];
  beginRelease();
  for (const ch of characters) {
    createShield(ch);
    ch.shield && (ch.shield.spawning = true);
  }
  updateAllyHud();
  setPhase('ATIVO', 0);
  toast('ESCUDO APLICADO - ' + SHIELD_MAX + ' por aliado');
  particles.burst({
    origin: characters[1].root.position.clone().add(new THREE.Vector3(0, 1, 0)),
    count: 18, texture: TEX.spark, colorA: [0.8, 1, 1], colorB: [0.5, 1, 0.85],
    speed: [0.5, 1.8], size: [0.04, 0.1], life: [0.3, 0.7], radius: 0.6, gravity: 0.3, ttl: 1.2,
  });
}

function hitAllies() {
  if (state.mode !== 'active') return;
  let any = false;
  for (const ch of characters) {
    if (!state.shielded[ch.index] || !ch.shield) continue;
    any = true;
    state.shieldHP[ch.index] = Math.max(0, state.shieldHP[ch.index] - HIT_DAMAGE);
    const point = ch.center.clone().add(new THREE.Vector3(0, 0.10, 0.92));
    ch.shield.hit(point);
    if (state.shieldHP[ch.index] <= 0) {
      ch.shield.breakShield();
      state.shielded[ch.index] = false;
      ch.shield = null;
    }
  }
  if (!any) return;
  updateAllyHud();
  toast('ABSORVIDO - -' + HIT_DAMAGE + ' no escudo');
}

function breakAll() {
  if (state.mode !== 'active') return;
  for (const ch of characters) {
    if (ch.shield) {
      ch.shield.breakShield();
      ch.shield = null;
    }
    state.shielded[ch.index] = false;
    state.shieldHP[ch.index] = 0;
  }
  state.mode = 'broken';
  updateAllyHud();
  setPhase('ROMPIDO', 1);
  toast('BRICK BREAK - ESCUDOS ROMPIDOS');
}

function expireNow() {
  if (state.mode !== 'active') return;
  state.timer = 0;
  expireShields();
}

function expireShields() {
  for (const ch of characters) {
    if (ch.shield) {
      ch.shield.expire();
      ch.shield = null;
    }
    state.shielded[ch.index] = false;
  }
  state.mode = 'expired';
  updateAllyHud();
  setPhase('EXPIRADO', 1);
  toast('DURACAO ENCERRADA - 8,0 s');
}

function clearShields(visual = false) {
  for (const ch of characters) {
    if (ch.shield) {
      if (visual) ch.shield.expire(); else ch.shield.finish();
      ch.shield = null;
    }
    state.shielded[ch.index] = false;
  }
  if (charge.active) {
    charge.active = false;
    charge.mesh.visible = false;
    charge.waterHelix.visible = false;
    charge.waterCore.visible = false;
    charge.waterGlow.visible = false;
    for (const d of charge.waterDrops) d.mesh.visible = false;
    charge.light.intensity = 0;
  }
  if (charge.crown) {
    disposeCrown(charge.crown);
    charge.crown = null;
  }
  particles.clear();
}

function reset() {
  if (autoCastTimer) { clearTimeout(autoCastTimer); autoCastTimer = 0; }
  clearShields(false);
  clearFormationFX();
  state.mode = 'idle';
  state.phaseT = 0;
  state.timer = DURATION;
  state.shieldHP = [SHIELD_MAX, SHIELD_MAX, SHIELD_MAX];
  state.shielded = [false, false, false];
  setPhase('PRONTO', 0);
  updateAllyHud();
  toast('PROTOTIPO REINICIADO');
}

function setOption(opt) {
  if (state.option === opt) return;
  state.option = opt;
  ui.options.forEach((b) => b.classList.toggle('active', b.dataset.option === opt));
  if (state.mode === 'windup') {
    startCharge();
  } else if (state.mode === 'active') {
    for (const ch of characters) {
      removeShield(ch, true);
      createShield(ch);
    }
  }
  toast('OPCAO ' + opt);
}

function setMirror(on) {
  state.mirrored = on;
  const z = on ? -17.5 : 17.5;
  camera.position.set(0, 5.2, z);
  controls.target.set(0, 1.45, 0.2);
  controls.update();
  ui.mirror.classList.toggle('primary', on);
  toast(on ? 'VISTA ESPELHADA' : 'VISTA NORMAL');
}

// ---------------------------------------------------------------------------
// HUD
// ---------------------------------------------------------------------------

function buildAlliesHud() {
  ui.allies.innerHTML = '';
  for (let i = 0; i < 3; i++) {
    const el = document.createElement('div');
    el.className = 'ally';
    el.innerHTML = `
      <div class="name"><span>${ALLY_NAMES[i]}</span><b>SEM TIPO</b></div>
      <div class="bar"><i></i></div>
      <div class="nums"><span class="hp">—</span><em class="time">—</em></div>`;
    ui.allies.appendChild(el);
  }
}

function updateAllyHud() {
  [...ui.allies.children].forEach((el, i) => {
    const bar = el.querySelector('.bar i');
    const hp = el.querySelector('.hp');
    const time = el.querySelector('.time');
    const alive = state.shielded[i] && state.shieldHP[i] > 0;
    const pct = alive ? (state.shieldHP[i] / SHIELD_MAX) * 100 : 0;
    bar.style.width = pct + '%';
    bar.style.background = state.shieldHP[i] > SHIELD_MAX * 0.4 ? 'var(--mint)' : '#ff9b6d';
    hp.textContent = state.mode === 'active' || state.mode === 'windup'
      ? `${state.shieldHP[i]} / ${SHIELD_MAX}`
      : `- / ${SHIELD_MAX}`;
    time.textContent = state.mode === 'active' ? state.timer.toFixed(1) + ' s' : (alive ? 'ativo' : '-');
  });
}

function setPhase(label, progress) {
  ui.phase.textContent = label;
  ui.phase.classList.toggle('active', state.mode === 'active' || state.mode === 'windup');
  ui.fill.style.width = (clamp(progress, 0, 1) * 100) + '%';
  ui.mark.style.left = (clamp(progress, 0, 1) * 100) + '%';
}

let toastTimer = 0;
function toast(msg) {
  ui.toast.textContent = msg;
  ui.toast.classList.add('show');
  toastTimer = 2.0;
}

// ---------------------------------------------------------------------------
// Loop
// ---------------------------------------------------------------------------

const clock = new THREE.Clock();

function updateState(dt) {
  if (state.loading || state.paused) return;
  if (state.mode === 'windup') {
    state.phaseT += dt;
    const p = clamp(state.phaseT / WINDUP, 0, 1);
    setPhase('WIND-UP', p);
    ui.clock.textContent = (WINDUP - state.phaseT).toFixed(2) + ' s';
    if (state.phaseT >= WINDUP) {
      state.phaseT = 0;
      releaseShields();
    }
  } else if (state.mode === 'active') {
    state.timer = Math.max(0, state.timer - dt);
    setPhase('ATIVO', 1 - state.timer / DURATION);
    ui.clock.textContent = state.timer.toFixed(1) + ' s';
    updateAllyHud();
    if (state.timer <= 0) expireShields();
  } else {
    ui.clock.textContent = state.mode === 'broken' ? '—' : '0,0 s';
  }

  updateCharge(dt);
  updateFlightBubbles(dt);
  updateFormationFX(dt);
  updateRings(dt);
  updateFlashes(dt);
  updateWaterDebris(dt);
  updateReleaseRings(dt);
  for (const ch of characters) {
    updateCharacterAnim(ch, dt);
  }
  for (const s of [...activeShields]) {
    s.update(dt);
    if (s.done) activeShields.delete(s);
  }
  particles.update(dt);
}

function animate() {
  requestAnimationFrame(animate);
  const dt = Math.min(clock.getDelta(), 0.05);
  updateState(dt);
  if (toastTimer > 0) {
    toastTimer -= dt;
    if (toastTimer <= 0) ui.toast.classList.remove('show');
  }
  controls.update();
  composer.render();
}

// ---------------------------------------------------------------------------
// Input
// ---------------------------------------------------------------------------

ui.options.forEach((b) => b.addEventListener('click', () => setOption(b.dataset.option)));
ui.cast.addEventListener('click', cast);
ui.hit.addEventListener('click', hitAllies);
ui.break.addEventListener('click', breakAll);
ui.expire.addEventListener('click', expireNow);
ui.mirror.addEventListener('click', () => setMirror(!state.mirrored));
ui.reset.addEventListener('click', reset);

addEventListener('keydown', (e) => {
  if (e.repeat) return;
  const k = e.key.toLowerCase();
  if (k === ' ') { e.preventDefault(); cast(); }
  else if (k === 'h') hitAllies();
  else if (k === 'b') breakAll();
  else if (k === 'e') expireNow();
  else if (k === 'm') setMirror(!state.mirrored);
  else if (k === 'r') reset();
  else if (k === '1') setOption('A');
  else if (k === '2') setOption('B');
  else if (k === '3') setOption('C');
  else if (k === '4') setOption('D');
});

addEventListener('resize', () => {
  camera.aspect = innerWidth / innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(innerWidth, innerHeight);
  composer.setSize(innerWidth, innerHeight);
  bloom.setSize(innerWidth, innerHeight);
});

// ---------------------------------------------------------------------------
// Boot
// ---------------------------------------------------------------------------

buildAlliesHud();
buildCharge();
updateAllyHud();
setPhase('CARREGANDO', 0);
loadSlimes().then(() => {
  updateAllyHud();
  setPhase('PRONTO', 0);
  // Hook de inspeÃ§Ã£o/captura, como no atelier.
  window.__bubble = {
    state, characters, cast, hitAllies, breakAll, expireNow, reset, setOption, setMirror,
    scene, camera, renderer, composer, particles,
    tick: (dt) => {
      updateState(dt);
      if (toastTimer > 0) toastTimer -= dt;
      controls.update();
      composer.render();
    },
    snap: () => {
      composer.render();
      return renderer.domElement.toDataURL('image/png');
    },
  };
  autoCastTimer = setTimeout(() => { autoCastTimer = 0; cast(); }, 900);
}).catch((err) => {
  console.error(err);
  toast('Erro ao carregar o Slime: ' + err.message);
  setPhase('ERRO', 0);