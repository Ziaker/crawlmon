import * as THREE from 'three';

export const TAU = Math.PI * 2;

export const clamp = (v, a, b) => Math.min(b, Math.max(a, v));
export const lerp = (a, b, t) => a + (b - a) * t;
export const smoothstep = (x, a, b) => {
  const t = clamp((x - a) / (b - a || 1e-6), 0, 1);
  return t * t * (3 - 2 * t);
};
export const easeOutCubic = (t) => 1 - Math.pow(1 - clamp(t, 0, 1), 3);
export const easeInOutCubic = (t) => {
  const x = clamp(t, 0, 1);
  return x < 0.5 ? 4 * x * x * x : 1 - Math.pow(-2 * x + 2, 3) / 2;
};

// RNG determinístico: o scrub reconstrói o efeito do zero e precisa dar o
// mesmo resultado todas as vezes (item 10 do prompt).
let _state = 1337;
export function resetRandom(seed = 1337) {
  _state = (seed >>> 0) || 1337;
}
export function rand() {
  _state = (_state + 0x6d2b79f5) | 0;
  let t = Math.imul(_state ^ (_state >>> 15), 1 | _state);
  t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
  return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
}
export const randRange = (a, b) => a + (b - a) * rand();
export const pick = (arr) => arr[Math.floor(rand() * arr.length) % arr.length];

export function hash(n) {
  const x = Math.sin(n * 127.1 + 311.7) * 43758.5453;
  return x - Math.floor(x);
}

export function softTexture(size = 128) {
  const c = document.createElement('canvas');
  c.width = c.height = size;
  const ctx = c.getContext('2d');
  const g = ctx.createRadialGradient(size / 2, size / 2, 0, size / 2, size / 2, size / 2);
  g.addColorStop(0, 'rgba(255,255,255,1)');
  g.addColorStop(0.28, 'rgba(255,255,255,0.9)');
  g.addColorStop(0.62, 'rgba(255,255,255,0.28)');
  g.addColorStop(1, 'rgba(255,255,255,0)');
  ctx.fillStyle = g;
  ctx.fillRect(0, 0, size, size);
  const tex = new THREE.CanvasTexture(c);
  tex.colorSpace = THREE.SRGBColorSpace;
  return tex;
}

export function makeDummy(color = 0x8e9dad, accent = 0x55e6ff) {
  const g = new THREE.Group();
  g.name = 'emissor';
  const bodyMat = new THREE.MeshStandardMaterial({
    color, roughness: 0.62, metalness: 0.08,
    emissive: new THREE.Color(accent), emissiveIntensity: 0.045,
  });
  const darkMat = new THREE.MeshStandardMaterial({ color: 0x2a3440, roughness: 0.7, metalness: 0.1 });
  const body = new THREE.Mesh(new THREE.CapsuleGeometry(0.28, 0.78, 8, 16), bodyMat);
  body.position.y = 1.02;
  g.add(body);
  const head = new THREE.Mesh(new THREE.SphereGeometry(0.26, 24, 16), bodyMat);
  head.position.y = 1.86;
  g.add(head);
  const visor = new THREE.Mesh(new THREE.BoxGeometry(0.22, 0.06, 0.06), darkMat);
  visor.position.set(0, 1.87, 0.22);
  g.add(visor);
  for (const side of [-1, 1]) {
    const arm = new THREE.Mesh(new THREE.CapsuleGeometry(0.075, 0.52, 6, 10), bodyMat);
    arm.position.set(side * 0.36, 1.08, 0);
    arm.rotation.z = side * 0.16;
    g.add(arm);
    const leg = new THREE.Mesh(new THREE.CapsuleGeometry(0.095, 0.55, 6, 10), darkMat);
    leg.position.set(side * 0.14, 0.38, 0);
    g.add(leg);
  }
  const ring = new THREE.Mesh(
    new THREE.RingGeometry(0.42, 0.47, 48),
    new THREE.MeshBasicMaterial({ color: accent, transparent: true, opacity: 0.4, side: THREE.DoubleSide, blending: THREE.AdditiveBlending, depthWrite: false })
  );
  ring.rotation.x = -Math.PI / 2;
  ring.position.y = 0.012;
  g.add(ring);
  g.userData.bodyMat = bodyMat;
  return g;
}

export function makeTarget() {
  const g = makeDummy(0x9b5f68, 0xff5b7a);
  g.name = 'alvo';
  return g;
}

export function resetDummy(dummy) {
  dummy.position.set(0, 0, 0);
  dummy.rotation.set(0, 0, 0);
  dummy.visible = true;
}

/** Funil: raio `radius` na base (v=0) e `top` na boca (v=1). */
export function funnelGeometry({ height = 3, radius = 2, top = 0.15, twist = 4, segments = 120, rings = 48 }) {
  const positions = [];
  const uvs = [];
  const indices = [];
  for (let j = 0; j <= rings; j++) {
    const v = j / rings;
    const rr = radius * (1 - v) + top * v;
    const y = v * height;
    for (let i = 0; i <= segments; i++) {
      const u = i / segments;
      const a = u * TAU + twist * v;
      positions.push(Math.cos(a) * rr, y, Math.sin(a) * rr);
      uvs.push(u, v);
    }
  }
  for (let j = 0; j < rings; j++) {
    for (let i = 0; i < segments; i++) {
      const a = j * (segments + 1) + i;
      const b = a + segments + 1;
      indices.push(a, b, a + 1, b, b + 1, a + 1);
    }
  }
  const geo = new THREE.BufferGeometry();
  geo.setAttribute('position', new THREE.Float32BufferAttribute(positions, 3));
  geo.setAttribute('uv', new THREE.Float32BufferAttribute(uvs, 2));
  geo.setIndex(indices);
  geo.computeVertexNormals();
  return geo;
}

/** Fita ao longo de pontos; `ups` opcional para orientar a largura por ponto. */
export function ribbonGeometry(points, widths, up = new THREE.Vector3(0, 1, 0), ups = null) {
  const n = points.length;
  const positions = new Float32Array(n * 2 * 3);
  const uvs = new Float32Array(n * 2 * 2);
  const indices = [];
  const tangent = new THREE.Vector3();
  const side = new THREE.Vector3();
  const p = new THREE.Vector3();
  const upv = new THREE.Vector3();
  for (let i = 0; i < n; i++) {
    p.copy(points[i]);
    if (i < n - 1) tangent.copy(points[i + 1]).sub(p);
    else tangent.copy(p).sub(points[i - 1]);
    if (tangent.lengthSq() < 1e-8) tangent.set(0, 0, 1);
    tangent.normalize();
    upv.copy(ups ? ups[i] : up);
    side.crossVectors(tangent, upv);
    if (side.lengthSq() < 1e-6) side.set(1, 0, 0);
    side.normalize().multiplyScalar(widths[i] * 0.5);
    const o = i * 6;
    positions[o] = p.x - side.x;
    positions[o + 1] = p.y - side.y;
    positions[o + 2] = p.z - side.z;
    positions[o + 3] = p.x + side.x;
    positions[o + 4] = p.y + side.y;
    positions[o + 5] = p.z + side.z;
    uvs[i * 4] = i / Math.max(n - 1, 1);
    uvs[i * 4 + 1] = 0;
    uvs[i * 4 + 2] = i / Math.max(n - 1, 1);
    uvs[i * 4 + 3] = 1;
    if (i < n - 1) {
      const a = i * 2;
      indices.push(a, a + 1, a + 2, a + 1, a + 3, a + 2);
    }
  }
  const geo = new THREE.BufferGeometry();
  geo.setAttribute('position', new THREE.BufferAttribute(positions, 3));
  geo.setAttribute('uv', new THREE.BufferAttribute(uvs, 2));
  geo.setIndex(indices);
  geo.computeVertexNormals();
  return geo;
}

export function ringMesh(inner, outer, color, opacity = 0.8, segments = 96) {
  const geo = new THREE.RingGeometry(inner, outer, segments);
  const mat = new THREE.MeshBasicMaterial({
    color, transparent: true, opacity, side: THREE.DoubleSide,
    blending: THREE.AdditiveBlending, depthWrite: false,
  });
  const m = new THREE.Mesh(geo, mat);
  m.rotation.x = -Math.PI / 2;
  return m;
}

export function glowSprite(color, size, opacity = 1, texture = null) {
  const mat = new THREE.SpriteMaterial({
    map: texture || softTexture(), color, transparent: true, opacity,
    blending: THREE.AdditiveBlending, depthWrite: false,
  });
  const s = new THREE.Sprite(mat);
  s.scale.set(size, size, 1);
  return s;
}

export function shaderMaterial(vertexShader, fragmentShader, uniforms, opts = {}) {  return new THREE.ShaderMaterial({
    vertexShader, fragmentShader, uniforms,
    transparent: true, depthWrite: false, side: THREE.DoubleSide,
    blending: THREE.AdditiveBlending, ...opts,
  });
}

/**
 * Parâmetros VIVOS: cada leitura vai no store do cartão e cai no default do
 * componente. Sem isso, `{ ...defaults, ...ctx.p }` congela os valores na
 * criação e os sliders "ao vivo" não fazem nada.
 */
export function liveParams(ctx, defaults) {
  const store = ctx.p || {};
  return new Proxy({}, {
    get(_t, key) {
      if (key === '__store') return store;
      const v = store[key];
      return v === undefined ? defaults[key] : v;
    },
    set(_t, key, val) { store[key] = val; return true; },
    has(_t, key) { return key in store || key in defaults; },
    ownKeys() { return [...new Set([...Object.keys(defaults), ...Object.keys(store)])]; },
    getOwnPropertyDescriptor() { return { enumerable: true, configurable: true }; },
  });
}

/** Partículas CPU com spawn/update; usa o RNG determinístico. */
export function makeBurst(count, texture, color, size, opacity = 1, additive = true) {
  const points = makePoints(count, texture, color, size, opacity, additive);
  const pos = points.geometry.attributes.position.array;
  const items = [];
  for (let i = 0; i < count; i++) {
    items.push({ p: new THREE.Vector3(0, -999, 0), v: new THREE.Vector3(), age: 1, life: 0 });
    pos[i * 3 + 1] = -999;
  }
  points.geometry.attributes.position.needsUpdate = true;
  let cursor = 0;
  function spawn(origin, n, speed, life, spread = 1, dir = new THREE.Vector3(0, 1, 0), radius = 0) {
    for (let k = 0; k < n; k++) {
      const it = items[cursor % count];
      cursor++;
      const a = rand() * TAU;
      const b = Math.acos(2 * rand() - 1);
      const r = radius * Math.cbrt(rand());
      it.p.set(
        origin.x + Math.cos(a) * Math.sin(b) * r,
        origin.y + Math.cos(b) * r,
        origin.z + Math.sin(a) * Math.sin(b) * r
      );
      const d = new THREE.Vector3(rand() * 2 - 1, rand() * 2 - 1, rand() * 2 - 1).normalize();
      d.lerp(dir, 0.55).normalize();
      it.v.copy(d).multiplyScalar(speed * (0.35 + rand() * spread));
      it.age = 0;
      it.life = life * (0.55 + rand() * 0.9);
    }
  }
  function update(dt, gravity = -1.8) {
    for (let i = 0; i < count; i++) {
      const it = items[i];
      if (it.age >= it.life) {
        pos[i * 3 + 1] = -999;
        continue;
      }
      it.age += dt;
      it.v.y += gravity * dt;
      it.p.addScaledVector(it.v, dt);
      pos[i * 3] = it.p.x;
      pos[i * 3 + 1] = it.p.y;
      pos[i * 3 + 2] = it.p.z;
    }
    points.geometry.attributes.position.needsUpdate = true;
  }
  function reset() {
    for (const it of items) { it.age = 1; it.life = 0; }
    for (let i = 0; i < count; i++) pos[i * 3 + 1] = -999;
    points.geometry.attributes.position.needsUpdate = true;
  }
  return { points, spawn, update, reset, items };
}

export function makePoints(count, texture, color, size, opacity = 1, additive = true) {
  const geo = new THREE.BufferGeometry();
  const positions = new Float32Array(count * 3);
  geo.setAttribute('position', new THREE.BufferAttribute(positions, 3));
  const mat = new THREE.PointsMaterial({
    map: texture, color, size, sizeAttenuation: true, transparent: true,
    opacity, depthWrite: false, alphaTest: 0.01,
    blending: additive ? THREE.AdditiveBlending : THREE.NormalBlending,
  });
  return new THREE.Points(geo, mat);
}

export function disposeGroup(group) {
  group.traverse((o) => {
    if (o.geometry) o.geometry.dispose();
    if (o.material) {
      const mats = Array.isArray(o.material) ? o.material : [o.material];
      for (const m of mats) {
        if (m.map && !m.map.userData?.shared) m.map.dispose();
        m.dispose();
      }
    }
  });
}

/** Enquadra o palco inteiro: emissor na origem, alvo a `dist` no eixo. */
export function computeStage(attacker, target) {
  const from = attacker.position.clone();
  const to = target.position.clone();
  const dir = to.clone().sub(from).setY(0);
  const dist = dir.length();
  if (dist < 1e-4) dir.set(0, 0, -1);
  else dir.normalize();
  const right = new THREE.Vector3().crossVectors(dir, new THREE.Vector3(0, 1, 0)).normalize();
  return { from, to, dir, right, dist, mid: from.clone().lerp(to, 0.5) };
}

export function stageRoot(stage) {
  const g = new THREE.Group();
  g.position.copy(stage.from);
  g.quaternion.setFromUnitVectors(new THREE.Vector3(0, 0, -1), stage.dir);
  return g;
}

/** Move o emissor `z` unidades no sentido do alvo (D-235). */
export function placeDummy(ctx, z, x = 0) {
  if (ctx.skipDummy) return;
  const { from, dir, right } = ctx.stage;
  ctx.dummy.position.copy(from).addScaledVector(dir, z).addScaledVector(right, x);
  ctx.dummy.position.y = 0;
  ctx.dummy.rotation.set(0, Math.atan2(dir.x, dir.z), 0);
}

export function alignY(mesh, dir) {
  const q = new THREE.Quaternion().setFromUnitVectors(new THREE.Vector3(0, 1, 0), dir.clone().normalize());
  mesh.quaternion.copy(q);
}

export function placeImpactCone(mesh, contact, dir, length) {
  mesh.position.copy(contact).addScaledVector(dir, length * 0.5);
  alignY(mesh, dir.clone().negate());
}

/**
 * Jato/cone: listras longitudinais + fresnel de silhueta (volume de verdade,
 * sem virar "mola" de anéis). vUv.y = 1 na ponta (bocal/contato).
 */
export function coneMaterial(colorA, colorB, speed = 12) {
  return new THREE.ShaderMaterial({
    vertexShader: `
      varying vec2 vUv;
      varying vec3 vN;
      void main() {
        vUv = uv;
        vN = normalize(normalMatrix * normal);
        gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
      }`,
    fragmentShader: `
      varying vec2 vUv;
      varying vec3 vN;
      uniform float uTime;
      uniform float uProgress;
      uniform float uSpeed;
      uniform vec3 uA;
      uniform vec3 uB;
      void main() {
        float streak = pow(0.5 + 0.5 * sin(vUv.x * 44.0 - uTime * uSpeed), 6.0);
        float fine = pow(0.5 + 0.5 * sin(vUv.x * 110.0 + vUv.y * 5.0 - uTime * uSpeed * 1.6), 9.0);
        float rim = 1.0 - abs(vN.z);
        float along = pow(clamp(vUv.y, 0.0, 1.0), 0.55);
        vec3 col = mix(uA, uB, streak * 0.75 + fine * 0.25);
        float a = (0.05 + streak * 0.32 + fine * 0.30) * (0.30 + rim * 0.95) * along * uProgress;
        gl_FragColor = vec4(col, a);
      }`,
    uniforms: {
      uTime: { value: 0 }, uProgress: { value: 1 }, uSpeed: { value: speed },
      uA: { value: new THREE.Color(colorA) }, uB: { value: new THREE.Color(colorB) },
    },
    transparent: true, depthWrite: false, side: THREE.DoubleSide, blending: THREE.AdditiveBlending,
  });
}

export const COLORS = {
  cyan: 0x55e6ff,
  lime: 0xd8ff00,
  violet: 0xa88bff,
  amber: 0xffb347,
  coral: 0xff5b7a,
  white: 0xffffff,
};
