import * as THREE from 'three';
import { TAU, rand, clamp, lerp } from './helpers.js';

/** Ruído reutilizável (hash + value noise + FBM) para os shaders dos flagships. */
export const NOISE_GLSL = `
float hash11(float p) { p = fract(p * 0.1031); p *= p + 33.33; p *= p + p; return fract(p); }
float hash21(vec2 p) { p = fract(p * vec2(123.34, 456.21)); p += dot(p, p + 45.32); return fract(p.x * p.y); }
float noise2(vec2 p) {
  vec2 i = floor(p); vec2 f = fract(p);
  f = f * f * (3.0 - 2.0 * f);
  return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), f.x),
             mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), f.x), f.y);
}
float fbm2(vec2 p) {
  float v = 0.0; float a = 0.5;
  for (int i = 0; i < 5; i++) { v += a * noise2(p); p *= 2.03; a *= 0.5; }
  return v;
}
`;

export function loadFlipbook(url) {
  const tex = new THREE.TextureLoader().load(url);
  tex.colorSpace = THREE.SRGBColorSpace;
  tex.userData.shared = true;
  return tex;
}

/**
 * Coroa de lâminas: geometria autoral (não é um círculo de cones).
 * Atributos: aT (base→ponta), aSide (-1..1), aSeed, aLayer.
 */
export function bladeCrownGeometry({ count = 16, height = 2.2, radius = 1.1, layers = 2 } = {}) {
  const positions = [];
  const aT = [];
  const aSide = [];
  const aSeed = [];
  const aLayer = [];
  const indices = [];
  let v = 0;

  for (let layer = 0; layer < layers; layer++) {
    const inner = layer === 1;
    const n = inner ? Math.max(6, Math.floor(count * 0.55)) : count;
    const rBase = radius * (inner ? 0.38 : 0.66);
    const rTip = radius * (inner ? 0.95 : 1.55);
    const hMul = inner ? 0.52 : 1.0;

    for (let i = 0; i < n; i++) {
      const a = (i / n) * TAU + (rand() - 0.5) * 0.16;
      const h = height * hMul * (0.55 + rand() * 0.7);
      const w0 = (inner ? 0.11 : 0.17) * (0.55 + rand() * 0.9);
      const w1 = w0 * (0.05 + rand() * 0.10);
      const ca = Math.cos(a);
      const sa = Math.sin(a);
      const tx = -sa;
      const tz = ca;
      const rb = rBase * (0.9 + rand() * 0.22);
      const rt = rTip * (0.85 + rand() * 0.45);
      const bx = ca * rb;
      const bz = sa * rb;
      const px = ca * rt;
      const pz = sa * rt;
      const seed = rand();
      const corners = [
        [bx - tx * w0 * 0.5, 0.01, bz - tz * w0 * 0.5, 0, -1],
        [bx + tx * w0 * 0.5, 0.01, bz + tz * w0 * 0.5, 0, 1],
        [px - tx * w1 * 0.5, h, pz - tz * w1 * 0.5, 1, -1],
        [px + tx * w1 * 0.5, h, pz + tz * w1 * 0.5, 1, 1],
      ];
      for (const [x, y, z, t, s] of corners) {
        positions.push(x, y, z);
        aT.push(t);
        aSide.push(s);
        aSeed.push(seed);
        aLayer.push(layer);
      }
      indices.push(v, v + 1, v + 2, v + 1, v + 3, v + 2);
      v += 4;
    }
  }

  const geo = new THREE.BufferGeometry();
  geo.setAttribute('position', new THREE.Float32BufferAttribute(positions, 3));
  geo.setAttribute('aT', new THREE.Float32BufferAttribute(aT, 1));
  geo.setAttribute('aSide', new THREE.Float32BufferAttribute(aSide, 1));
  geo.setAttribute('aSeed', new THREE.Float32BufferAttribute(aSeed, 1));
  geo.setAttribute('aLayer', new THREE.Float32BufferAttribute(aLayer, 1));
  geo.setIndex(indices);
  return geo;
}

/** Plano billboard com atlas de flipbook (4x4), usado como núcleo de impacto. */
export function makeFlipbookPlane(texture, { size = 2.0, fps = 24 } = {}) {
  const mat = new THREE.ShaderMaterial({
    uniforms: {
      uMap: { value: texture },
      uProgress: { value: 0 },
      uOpacity: { value: 1 },
      uEnergy: { value: 1.4 },
    },
    vertexShader: `
      varying vec2 vUv;
      void main() { vUv = uv; gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0); }`,
    fragmentShader: `
      varying vec2 vUv;
      uniform sampler2D uMap;
      uniform float uProgress;
      uniform float uOpacity;
      uniform float uEnergy;
      void main() {
        float f = floor(clamp(uProgress, 0.0, 0.999) * 16.0);
        float col = mod(f, 4.0);
        float row = 3.0 - floor(f / 4.0);
        vec2 uv = (vUv + vec2(col, row)) * 0.25;
        vec4 tex = texture2D(uMap, uv);
        float a = tex.a * uOpacity;
        if (a < 0.012) discard;
        gl_FragColor = vec4(tex.rgb * uEnergy, a);
      }`,
    transparent: true, depthWrite: false, blending: THREE.AdditiveBlending, side: THREE.DoubleSide,
  });
  const mesh = new THREE.Mesh(new THREE.PlaneGeometry(size, size), mat);
  mesh.frustumCulled = false;
  let life = 0;
  return {
    mesh, mat,
    update(t, camera) {
      const k = clamp(t / (16 / fps), 0, 1);
      mat.uniforms.uProgress.value = k;
      mat.uniforms.uOpacity.value = 1 - smooth01((t - 0.45) / 0.5);
      mesh.quaternion.copy(camera.quaternion);
      mesh.scale.setScalar(0.75 + k * 0.5);
    },
  };
}

function smooth01(x) {
  const t = clamp(x, 0, 1);
  return t * t * (3 - 2 * t);
}

/**
 * Fumaça/poeira em billboards instanciados com o atlas REAL do projeto
 * (assets/vfx/flipbook_smoke.png, 4x4). NormalBlending para ter corpo, não "luzinha".
 */
export function makeSmokeField({ count = 60, texture, color = '#c9bda8', opacity = 0.55 } = {}) {
  const base = new THREE.PlaneGeometry(1, 1);
  const geo = new THREE.InstancedBufferGeometry();
  geo.index = base.index;
  geo.setAttribute('position', base.attributes.position);
  geo.setAttribute('uv', base.attributes.uv);

  const offsets = new Float32Array(count * 3);
  const scales = new Float32Array(count);
  const ages = new Float32Array(count);
  const seeds = new Float32Array(count);
  for (let i = 0; i < count; i++) {
    offsets[i * 3 + 1] = -999;
    ages[i] = 1;
  }
  const aOffset = new THREE.InstancedBufferAttribute(offsets, 3);
  const aScale = new THREE.InstancedBufferAttribute(scales, 1);
  const aAge = new THREE.InstancedBufferAttribute(ages, 1);
  const aSeed = new THREE.InstancedBufferAttribute(seeds, 1);
  geo.setAttribute('aOffset', aOffset);
  geo.setAttribute('aScale', aScale);
  geo.setAttribute('aAge', aAge);
  geo.setAttribute('aSeed', aSeed);
  geo.instanceCount = count;

  const mat = new THREE.ShaderMaterial({
    uniforms: {
      uMap: { value: texture },
      uColor: { value: new THREE.Color(color) },
      uOpacity: { value: opacity },
    },
    vertexShader: `
      attribute vec3 aOffset;
      attribute float aScale;
      attribute float aAge;
      attribute float aSeed;
      varying vec2 vUv;
      varying float vAge;
      varying float vSeed;
      void main() {
        vec4 mv = modelViewMatrix * vec4(aOffset, 1.0);
        mv.xy += position.xy * aScale;
        gl_Position = projectionMatrix * mv;
        vUv = uv;
        vAge = aAge;
        vSeed = aSeed;
      }`,
    fragmentShader: `
      varying vec2 vUv;
      varying float vAge;
      varying float vSeed;
      uniform sampler2D uMap;
      uniform vec3 uColor;
      uniform float uOpacity;
      void main() {
        float f = floor(clamp(vAge, 0.0, 0.999) * 16.0);
        float col = mod(f, 4.0);
        float row = 3.0 - floor(f / 4.0);
        vec2 uv = (vUv + vec2(col, row)) * 0.25;
        vec4 tex = texture2D(uMap, uv);
        float fadeIn = smoothstep(0.0, 0.10, vAge);
        float fadeOut = 1.0 - smoothstep(0.55, 1.0, vAge);
        float a = tex.a * fadeIn * fadeOut * uOpacity;
        if (a < 0.008) discard;
        vec3 c = uColor * (0.45 + tex.r * 0.9);
        gl_FragColor = vec4(c, a);
      }`,
    transparent: true, depthWrite: false, blending: THREE.NormalBlending, side: THREE.DoubleSide,
  });

  const mesh = new THREE.Mesh(geo, mat);
  mesh.frustumCulled = false;
  mesh.name = 'fumaça (atlas 4x4)';
  mesh.renderOrder = 2;

  const items = [];
  for (let i = 0; i < count; i++) {
    items.push({ pos: new THREE.Vector3(0, -999, 0), vel: new THREE.Vector3(), life: 1, age: 1, scale: 0 });
  }
  let cursor = 0;

  function spawn(origin, { vel = new THREE.Vector3(), life = 1.2, scale = 1.2 } = {}) {
    const it = items[cursor % count];
    cursor++;
    it.pos.copy(origin);
    it.vel.copy(vel);
    it.life = life;
    it.age = 0;
    it.scale = scale;
    seeds[(cursor - 1) % count] = rand();
  }

  function update(dt) {
    for (let i = 0; i < count; i++) {
      const it = items[i];
      if (it.age >= it.life) {
        offsets[i * 3 + 1] = -999;
        scales[i] = 0;
        ages[i] = 1;
        continue;
      }
      it.age += dt;
      it.pos.addScaledVector(it.vel, dt);
      it.vel.multiplyScalar(1 - Math.min(dt * 1.6, 0.9));
      const k = clamp(it.age / it.life, 0, 1);
      offsets[i * 3] = it.pos.x;
      offsets[i * 3 + 1] = it.pos.y;
      offsets[i * 3 + 2] = it.pos.z;
      scales[i] = it.scale * (0.55 + k * 0.9);
      ages[i] = k;
    }
    aOffset.needsUpdate = true;
    aScale.needsUpdate = true;
    aAge.needsUpdate = true;
    aSeed.needsUpdate = true;
  }

  function reset() {
    for (const it of items) { it.age = 1; it.life = 0; }
    for (let i = 0; i < count; i++) {
      offsets[i * 3 + 1] = -999;
      ages[i] = 1;
      scales[i] = 0;
    }
    aOffset.needsUpdate = true;
    aScale.needsUpdate = true;
    aAge.needsUpdate = true;
  }

  function setColor(hex) { mat.uniforms.uColor.value.set(hex); }
  function setOpacity(v) { mat.uniforms.uOpacity.value = v; }

  return { mesh, spawn, update, reset, setColor, setOpacity, items };
}

/** Quads esticados (faíscas/estilhaços) orientados por velocidade. */
export function makeStreakField({ count = 40, color = '#ffffff', size = 0.03 } = {}) {
  const geo = new THREE.BoxGeometry(size, size, 1);
  const mat = new THREE.MeshBasicMaterial({
    color, transparent: true, opacity: 0.95, blending: THREE.AdditiveBlending, depthWrite: false,
  });
  const mesh = new THREE.InstancedMesh(geo, mat, count);
  mesh.frustumCulled = false;
  const items = [];
  for (let i = 0; i < count; i++) items.push({ p: new THREE.Vector3(0, -999, 0), v: new THREE.Vector3(), age: 1, life: 0, len: 0.15 });
  const dummy = new THREE.Object3D();
  const dir = new THREE.Vector3();
  let cursor = 0;

  function spawn(origin, vel, life = 0.5, len = 0.2) {
    const it = items[cursor % count];
    cursor++;
    it.p.copy(origin);
    it.v.copy(vel);
    it.age = 0;
    it.life = life;
    it.len = len;
  }

  function update(dt, gravity = -6) {
    for (let i = 0; i < count; i++) {
      const it = items[i];
      if (it.age >= it.life) {
        dummy.position.set(0, -999, 0);
        dummy.scale.setScalar(0);
        dummy.updateMatrix();
        mesh.setMatrixAt(i, dummy.matrix);
        continue;
      }
      it.age += dt;
      it.v.y += gravity * dt;
      it.p.addScaledVector(it.v, dt);
      const alive = 1 - it.age / it.life;
      dir.copy(it.v);
      if (dir.lengthSq() > 1e-5) dummy.quaternion.setFromUnitVectors(new THREE.Vector3(0, 0, 1), dir.normalize());
      dummy.position.copy(it.p);
      dummy.scale.set(alive, alive, it.len * (0.4 + alive));
      dummy.updateMatrix();
      mesh.setMatrixAt(i, dummy.matrix);
    }
    mesh.instanceMatrix.needsUpdate = true;
  }

  return { mesh, spawn, update };
}
