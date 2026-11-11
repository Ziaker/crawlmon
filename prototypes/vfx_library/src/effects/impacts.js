import * as THREE from 'three';
import {
  TAU, clamp, lerp, easeOutCubic, rand, randRange,
  ribbonGeometry, ringMesh, glowSprite, shaderMaterial,
  makeBurst, stageRoot, liveParams, coneMaterial, COLORS,
} from '../helpers.js';

const vShader = `varying vec2 vUv;
void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}`;

export const IMPACT_DEFAULTS = {
  shockwave: { radius: 4.6 },
  crown: { spikes: 18, height: 2.0, radius: 1.0 },
  blastcone: { length: 3.4, opening: 1.55, intensity: 1.0 },
  fracture: { radius: 3.2, branches: 7 },
  flipbook: { size: 3.4, fps: 22, intensity: 1.0 },
  sparks: { count: 90, speed: 8, gravity: -7 },
  debris: { count: 26, size: 1.0, gravity: -8 },
  slash: { arc: 150, radius: 2.0, width: 0.5 },
};

// Recurso real do projeto (16 quadros, 4x4), usado também no Godot
// (assets/vfx/flipbook_impact.png + shaders/flipbook.gdshader).
const flipbookImpact = new THREE.TextureLoader().load(
  new URL('../../../../assets/vfx/flipbook_impact.png', import.meta.url).href
);
flipbookImpact.colorSpace = THREE.SRGBColorSpace;
flipbookImpact.userData.shared = true;

// LIB-VFX-13 — SHOCKWAVE RING ------------------------------------------------
export function createShockwave(ctx) {
  const p = liveParams(ctx, IMPACT_DEFAULTS.shockwave);
  const group = stageRoot(ctx.stage);
  const dist = ctx.stage.dist;

  const rings = [];
  for (let i = 0; i < 3; i++) {
    const r = ringMesh(0.94, 1.0, i === 0 ? 0xfff2c2 : (i === 1 ? COLORS.cyan : COLORS.violet), 0.7);
    r.name = `anel ${i + 1}`;
    r.position.set(0, 0.03 + i * 0.006, -dist);
    group.add(r);
    rings.push({ mesh: r, delay: i * 0.10 });
  }

  const flash = glowSprite(0xfff2c2, 2.4, 0.8, ctx.soft);
  flash.name = 'clarão';
  flash.position.set(0, 0.9, -dist);
  group.add(flash);
  const burst = makeBurst(220, ctx.soft, 0xffd08a, 0.06, 0.85);
  group.add(burst.points);

  return {
    group,
    duration: 2.2,
    update(t, dt) {
      for (const r of rings) {
        const k = clamp((t - r.delay) / 1.4, 0, 1);
        const e = easeOutCubic(k);
        r.mesh.scale.setScalar(0.25 + e * p.radius);
        r.mesh.material.opacity = 0.75 * (1 - k) * (1 - k);
      }
      flash.scale.setScalar(1.0 + easeOutCubic(t / 0.25) * 2.2);
      flash.material.opacity = Math.max(0, 0.8 - t * 0.7);
      if (t < 0.08) burst.spawn(new THREE.Vector3(0, 0.25, -dist), 60, 6.0, 0.8, 1.0, new THREE.Vector3(0, 0.4, 0), 0.3);
      burst.update(dt, -7.0);
    },
  };
}

// LIB-VFX-14 — IMPACT CROWN ---------------------------------------------------
export function createCrown(ctx) {
  const p = liveParams(ctx, IMPACT_DEFAULTS.crown);
  const group = stageRoot(ctx.stage);
  const dist = ctx.stage.dist;
  const count = p.spikes;

  const spikeGeo = new THREE.ConeGeometry(0.155, 1.0, 5, 1);
  spikeGeo.translate(0, 0.5, 0);
  const mat = new THREE.MeshBasicMaterial({
    color: 0xffb04a, transparent: true, opacity: 0.92,
    depthWrite: false, side: THREE.DoubleSide,
  });
  const spikes = new THREE.InstancedMesh(spikeGeo, mat, count);
  spikes.name = 'pontas';
  group.add(spikes);

  // Base da coroa: cunhas curtas, para a silhueta não ser só "cones soltos".
  const baseGeo = new THREE.ConeGeometry(0.16, 0.32, 4, 1);
  baseGeo.translate(0, 0.16, 0);
  const baseMesh = new THREE.InstancedMesh(baseGeo, mat.clone(), count);
  baseMesh.name = 'base';
  group.add(baseMesh);

  const ring = ringMesh(p.radius * 0.94, p.radius, 0xff8a5c, 0.5);
  ring.position.set(0, 0.03, -dist);
  group.add(ring);
  const flash = glowSprite(0xffe6b0, 1.2, 0.4, ctx.soft);
  flash.name = 'clarão';
  flash.position.set(0, 0.5, -dist);
  group.add(flash);
  const burst = makeBurst(180, ctx.soft, 0xffc46a, 0.07, 0.85);
  group.add(burst.points);
  const dummy = new THREE.Object3D();

  return {
    group,
    duration: 1.8,
    update(t, dt) {
      const k = easeOutCubic(t / 0.5);
      const fade = 1 - clamp((t - 1.15) / 0.65, 0, 1);
      const open = 0.35 + k * 0.9;
      for (let i = 0; i < count; i++) {
        const a = (i / count) * TAU;
        const rr = p.radius * (0.62 + k * 0.55);
        const hh = p.height * (0.55 + ((i * 53) % 13) / 13 * 0.75) * (0.35 + k * 0.9);
        dummy.position.set(Math.cos(a) * rr, 0.02, -dist + Math.sin(a) * rr);
        dummy.rotation.set(Math.cos(a) * open, -a + Math.PI / 2, Math.sin(a) * open);
        dummy.scale.set(0.55 + ((i * 29) % 7) / 7 * 0.6, hh, 0.55 + ((i * 17) % 5) / 5 * 0.6);
        dummy.updateMatrix();
        spikes.setMatrixAt(i, dummy.matrix);

        const rr2 = p.radius * (0.55 + k * 0.5);
        dummy.position.set(Math.cos(a) * rr2, 0.02, -dist + Math.sin(a) * rr2);
        dummy.rotation.set(Math.cos(a) * open, -a + Math.PI / 2, Math.sin(a) * open);
        dummy.scale.set(1.0, 0.5 + k * 0.8, 1.0);
        dummy.updateMatrix();
        baseMesh.setMatrixAt(i, dummy.matrix);
      }
      spikes.instanceMatrix.needsUpdate = true;
      baseMesh.instanceMatrix.needsUpdate = true;
      mat.opacity = 0.95 * fade;
      baseMesh.material.opacity = 0.9 * fade;
      ring.scale.setScalar(0.4 + k * 1.6);
      ring.material.opacity = 0.55 * fade;
      flash.scale.setScalar(0.7 + k * 1.6);
      flash.material.opacity = 0.55 * fade;
      if (t < 0.1) burst.spawn(new THREE.Vector3(0, 0.2, -dist), 50, 3.6, 1.0, 1.0, new THREE.Vector3(0, 0.5, 0), 0.4);
      burst.update(dt, -5.5);
    },
  };
}

// LIB-VFX-15 — BLAST CONE -----------------------------------------------------
export function createBlastCone(ctx) {
  const p = liveParams(ctx, IMPACT_DEFAULTS.blastcone);
  const group = stageRoot(ctx.stage);
  const dist = ctx.stage.dist;
  const contact = new THREE.Vector3(0, 1.25, -dist);

  const mat = coneMaterial(0xff6a08, 0xfff2c0, 11);
  const cone = new THREE.Mesh(new THREE.CylinderGeometry(0.06, p.opening, p.length, 48, 18, true), mat);
  cone.name = 'cone de choque';
  cone.rotation.x = Math.PI / 2;
  cone.position.set(0, 1.25, -dist - p.length * 0.5);
  group.add(cone);

  const mat2 = coneMaterial(0xffd27a, 0xffffff, 18);
  const inner = new THREE.Mesh(new THREE.CylinderGeometry(0.03, p.opening * 0.55, p.length * 0.72, 40, 14, true), mat2);
  inner.name = 'lamina interna';
  inner.rotation.x = Math.PI / 2;
  inner.position.set(0, 1.25, -dist - p.length * 0.36);
  group.add(inner);

  const ring = ringMesh(0.72, 0.78, COLORS.amber, 0.65);
  ring.position.set(0, 0.03, -dist);
  group.add(ring);
  const flash = glowSprite(0xffe0a0, 1.8, 0.7, ctx.soft);
  flash.name = 'clarão';
  flash.position.copy(contact);
  group.add(flash);
  const burst = makeBurst(260, ctx.soft, 0xffc46a, 0.07, 0.9);
  group.add(burst.points);
  let fired = false;

  return {
    group,
    duration: 1.8,
    update(t, dt) {
      const e = easeOutCubic(t / 0.5);
      const fade = 1 - clamp((t - 1.05) / 0.7, 0, 1);
      mat.uniforms.uTime.value = t;
      mat2.uniforms.uTime.value = t;
      mat.uniforms.uProgress.value = clamp(t / 0.16, 0, 1) * fade * (0.6 + p.intensity * 0.5);
      mat2.uniforms.uProgress.value = clamp(t / 0.16, 0, 1) * fade * (0.5 + p.intensity * 0.6);
      cone.scale.set(0.25 + e * 0.95, 0.25 + e * 0.95, 0.35 + e * 0.9);
      inner.scale.set(0.2 + e * 0.85, 0.2 + e * 0.85, 0.3 + e * 0.9);
      ring.scale.setScalar(0.2 + e * 3.6);
      ring.material.opacity = 0.8 * fade;
      flash.scale.setScalar(0.7 + e * 1.8);
      flash.material.opacity = 0.85 * fade;
      if (!fired) {
        fired = true;
        burst.spawn(contact.clone(), 90, 6.5, 0.9, 1.0, new THREE.Vector3(0, 0.2, -1), 0.5);
      }
      burst.update(dt, -4.0);
    },
  };
}

// LIB-VFX-16 — GROUND FRACTURE ------------------------------------------------
export function createFracture(ctx) {
  const p = liveParams(ctx, IMPACT_DEFAULTS.fracture);
  const group = stageRoot(ctx.stage);
  const dist = ctx.stage.dist;

  const mat = shaderMaterial(vShader, `
    varying vec2 vUv;
    uniform float uProgress;
    uniform float uTime;
    uniform float uBranches;
    float hash21(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
    float noise2(vec2 p) {
      vec2 i = floor(p), f = fract(p);
      f = f * f * (3.0 - 2.0 * f);
      return mix(mix(hash21(i), hash21(i + vec2(1, 0)), f.x),
                 mix(hash21(i + vec2(0, 1)), hash21(i + vec2(1, 1)), f.x), f.y);
    }
    void main() {
      vec2 q = vUv - 0.5;
      float r = length(q) * 2.0;
      float a = atan(q.y, q.x);
      float wob = noise2(vec2(a * 3.0, r * 5.0)) * 1.4;
      float arms = abs(sin(a * uBranches + wob));
      float crack = smoothstep(0.10, 0.0, arms);
      float web = smoothstep(0.20, 0.0, abs(sin(a * uBranches * 2.0 + noise2(vec2(a * 9.0, r * 14.0)) * 3.0 + r * 9.0))) * smoothstep(0.8, 0.25, r) * 0.6;
      float front = uProgress * 1.05;
      float reveal = 1.0 - smoothstep(front - 0.04, front, r);
      float edge = smoothstep(front - 0.22, front - 0.06, r) * (1.0 - smoothstep(front - 0.06, front, r));
      vec3 col = mix(vec3(0.12, 0.38, 0.9), vec3(1.0, 0.55, 0.14), crack);
      col += vec3(0.8, 0.95, 1.0) * edge * 0.9;
      float alpha = (crack * 0.85 + web * 0.35) * reveal * (1.0 - smoothstep(0.92, 1.0, r));
      gl_FragColor = vec4(col, alpha);
    }`, { uProgress: { value: 0 }, uTime: { value: 0 }, uBranches: { value: p.branches } });
  const floor = new THREE.Mesh(new THREE.PlaneGeometry(p.radius * 2, p.radius * 2), mat);
  floor.name = 'rachaduras';
  floor.rotation.x = -Math.PI / 2;
  floor.position.set(0, 0.018, -dist);
  group.add(floor);

  const rockGeo = new THREE.DodecahedronGeometry(0.13, 0);
  const rockMat = new THREE.MeshStandardMaterial({ color: 0x6b5a4a, roughness: 0.9, metalness: 0.05 });
  const rocks = new THREE.InstancedMesh(rockGeo, rockMat, 26);
  rocks.name = 'pedras';
  group.add(rocks);
  const dummy = new THREE.Object3D();
  const burst = makeBurst(180, ctx.soft, 0xb8a68a, 0.08, 0.5, false);
  group.add(burst.points);
  let fired = false;
  const rockData = [];
  for (let i = 0; i < 26; i++) {
    rockData.push({
      a: rand() * TAU,
      r: 0.8 + rand() * (p.radius * 0.85),
      h: 0.3 + rand() * 0.9,
      spin: 0.4 + rand() * 0.9,
      scale: 0.5 + rand() * 0.8,
    });
  }

  return {
    group,
    duration: 2.6,
    update(t, dt) {
      mat.uniforms.uProgress.value = clamp(t / 0.55, 0, 1);
      mat.uniforms.uTime.value = t;
      for (let i = 0; i < 26; i++) {
        const rd = rockData[i];
        const up = Math.max(0, Math.sin((t - 0.1) * 3.0 + i * 0.7)) * rd.h;
        dummy.position.set(Math.cos(rd.a) * rd.r, 0.05 + up, -dist + Math.sin(rd.a) * rd.r);
        dummy.rotation.set(t * rd.spin, t * 0.8, t * 0.3);
        const hide = 1 - clamp((t - 1.9) / 0.6, 0, 1);
        dummy.scale.setScalar(rd.scale * hide);
        dummy.updateMatrix();
        rocks.setMatrixAt(i, dummy.matrix);
      }
      rocks.instanceMatrix.needsUpdate = true;
      if (!fired) {
        fired = true;
        burst.spawn(new THREE.Vector3(0, 0.1, -dist), 60, 2.8, 1.0, 1.0, new THREE.Vector3(0, 0.3, 0), 1.2);
      }
      burst.update(dt, -3.0);
    },
  };
}

// LIB-VFX-17 — ANIME IMPACT FLIPBOOK -----------------------------------------
export function createFlipbook(ctx) {
  const p = liveParams(ctx, IMPACT_DEFAULTS.flipbook);
  const group = stageRoot(ctx.stage);
  const dist = ctx.stage.dist;

  const mat = shaderMaterial(`
    varying vec2 vUv;
    void main() {
      vUv = uv;
      gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
    }`, `
    varying vec2 vUv;
    uniform sampler2D uMap;
    uniform float uProgress;
    uniform float uIntensity;
    void main() {
      float f = floor(uProgress * 16.0);
      f = clamp(f, 0.0, 15.0);
      float col = mod(f, 4.0);
      float row = 3.0 - floor(f / 4.0);
      vec2 uv = (vUv + vec2(col, row)) * 0.25;
      vec4 tex = texture2D(uMap, uv);
      float a = tex.a * (0.55 + uIntensity * 0.55);
      if (a < 0.015) discard;
      gl_FragColor = vec4(tex.rgb * (0.8 + uIntensity), a);
    }`, {
    uMap: { value: flipbookImpact },
    uProgress: { value: 0 },
    uIntensity: { value: p.intensity },
  });
  const plane = new THREE.Mesh(new THREE.PlaneGeometry(1, 1), mat);
  plane.name = 'flipbook (16 quadros)';
  plane.position.set(0, 1.35, -dist);
  plane.scale.setScalar(p.size);
  group.add(plane);

  const flash = glowSprite(0xffe8c0, 1.6, 0.55, ctx.soft);
  flash.name = 'clarão';
  flash.position.set(0, 1.3, -dist);
  group.add(flash);

  return {
    group,
    duration: 1.4,
    update(t, dt, camera) {
      const k = clamp(t / (p.fps > 0 ? 16 / p.fps : 0.8), 0, 1);
      mat.uniforms.uProgress.value = k;
      plane.quaternion.copy(camera.quaternion);
      const s = p.size * (0.55 + easeOutCubic(k) * 0.65);
      plane.scale.setScalar(s);
      flash.scale.setScalar(0.8 + easeOutCubic(k) * 1.4);
      flash.material.opacity = Math.max(0, 0.55 - t * 0.45);
    },
  };
}

// LIB-VFX-18 — KINETIC SPARKS -------------------------------------------------
export function createSparks(ctx) {
  const p = liveParams(ctx, IMPACT_DEFAULTS.sparks);
  const group = stageRoot(ctx.stage);
  const dist = ctx.stage.dist;
  const contact = new THREE.Vector3(0, 1.25, -dist);
  const count = p.count;

  const geo = new THREE.BoxGeometry(0.035, 0.035, 1);
  const mat = new THREE.MeshBasicMaterial({ color: 0xffffff, transparent: true, opacity: 0.95, blending: THREE.AdditiveBlending, depthWrite: false });
  const mesh = new THREE.InstancedMesh(geo, mat, count);
  mesh.name = 'faíscas';
  group.add(mesh);
  mesh.instanceColor = new THREE.InstancedBufferAttribute(new Float32Array(count * 3), 3);

  const items = [];
  const dummy = new THREE.Object3D();
  const dir = new THREE.Vector3();
  for (let i = 0; i < count; i++) {
    const a = rand() * TAU;
    const b = Math.acos(2 * rand() - 1);
    dir.set(Math.cos(a) * Math.sin(b), Math.abs(Math.cos(b)) * 1.2 + 0.15, Math.sin(a) * Math.sin(b)).normalize();
    const speed = p.speed * (0.35 + rand() * 0.9);
    items.push({
      p: contact.clone(),
      v: dir.clone().multiplyScalar(speed),
      life: 0.45 + rand() * 0.75,
      age: 0,
      len: 0.10 + rand() * 0.22,
      hue: rand(),
    });
  }

  return {
    group,
    duration: 1.6,
    update(t, dt) {
      for (let i = 0; i < count; i++) {
        const it = items[i];
        it.age += dt;
        it.v.y += p.gravity * dt;
        it.p.addScaledVector(it.v, dt);
        const alive = it.age < it.life ? 1 - it.age / it.life : 0;
        dummy.position.copy(it.p);
        if (it.v.lengthSq() > 1e-6) {
          dummy.quaternion.setFromUnitVectors(new THREE.Vector3(0, 0, 1), it.v.clone().normalize());
        }
        dummy.scale.set(alive > 0 ? 1 : 0, alive > 0 ? 1 : 0, it.len * (0.5 + alive));
        dummy.updateMatrix();
        mesh.setMatrixAt(i, dummy.matrix);
        const c = new THREE.Color().setHSL(0.10 + it.hue * 0.06, 1.0, 0.55 + alive * 0.35);
        if (it.age > it.life) c.setRGB(0, 0, 0);
        mesh.setColorAt(i, c);
      }
      mesh.instanceMatrix.needsUpdate = true;
      if (mesh.instanceColor) mesh.instanceColor.needsUpdate = true;
    },
  };
}

// LIB-VFX-19 — DIRECTIONAL DEBRIS --------------------------------------------
export function createDebris(ctx) {
  const p = liveParams(ctx, IMPACT_DEFAULTS.debris);
  const group = stageRoot(ctx.stage);
  const dist = ctx.stage.dist;
  const contact = new THREE.Vector3(0, 0.9, -dist);
  const count = p.count;

  const geo = new THREE.DodecahedronGeometry(0.12, 0);
  const mat = new THREE.MeshStandardMaterial({ color: 0x7a6754, roughness: 0.92, metalness: 0.04 });
  const mesh = new THREE.InstancedMesh(geo, mat, count);
  mesh.name = 'fragmentos';
  group.add(mesh);

  const items = [];
  for (let i = 0; i < count; i++) {
    const a = rand() * TAU;
    const b = Math.acos(2 * rand() - 1);
    const speed = 2.2 + rand() * 4.2;
    items.push({
      p: contact.clone(),
      v: new THREE.Vector3(Math.cos(a) * Math.sin(b), Math.abs(Math.cos(b)) * 1.4 + 0.4, Math.sin(a) * Math.sin(b)).multiplyScalar(speed),
      rot: new THREE.Vector3(rand() * TAU, rand() * TAU, rand() * TAU),
      spin: new THREE.Vector3(randRange(-7, 7), randRange(-7, 7), randRange(-7, 7)),
      size: p.size * (0.5 + rand() * 0.9),
      delay: 0,
    });
  }
  const dummy = new THREE.Object3D();

  return {
    group,
    duration: 2.4,
    update(t, dt) {
      for (let i = 0; i < count; i++) {
        const it = items[i];
        it.v.y += p.gravity * dt;
        it.p.addScaledVector(it.v, dt);
        if (it.p.y < 0.08) {
          it.p.y = 0.08;
          it.v.y *= -0.32;
          it.v.x *= 0.65;
          it.v.z *= 0.65;
        }
        it.rot.addScaledVector(it.spin, dt);
        const hide = 1 - clamp((t - 1.85) / 0.5, 0, 1);
        dummy.position.copy(it.p);
        dummy.rotation.set(it.rot.x, it.rot.y, it.rot.z);
        dummy.scale.setScalar(it.size * hide);
        dummy.updateMatrix();
        mesh.setMatrixAt(i, dummy.matrix);
      }
      mesh.instanceMatrix.needsUpdate = true;
    },
  };
}

// LIB-VFX-20 — SLASH ARC ------------------------------------------------------
export function createSlash(ctx) {
  const p = liveParams(ctx, IMPACT_DEFAULTS.slash);
  const group = stageRoot(ctx.stage);
  const dist = ctx.stage.dist;
  const arc = THREE.MathUtils.degToRad(p.arc);
  const tilt = THREE.MathUtils.degToRad(48);
  const cs = Math.cos(tilt);
  const sn = Math.sin(tilt);
  const N = 120;

  const arcPoint = (u) => {
    const th = -arc / 2 + arc * u;
    const lx = Math.cos(th) * p.radius;
    const ly = Math.sin(th) * p.radius;
    return new THREE.Vector3(
      lx * cs - ly * sn,
      1.25 + lx * sn + ly * cs,
      -dist + Math.sin(th * 1.6) * 0.22
    );
  };

  const points = [];
  for (let i = 0; i <= N; i++) points.push(arcPoint(i / N));
  const widths = points.map((_, i) => p.width * (0.18 + 0.82 * Math.sin((i / N) * Math.PI)));
  const geo = ribbonGeometry(points, widths, new THREE.Vector3(0, 0, 1));

  const mat = shaderMaterial(`
    varying vec2 vUv;
    void main() {
      vUv = uv;
      gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
    }`, `
    varying vec2 vUv;
    uniform float uReveal;
    uniform float uFade;
    void main() {
      float edge = smoothstep(0.5, 0.02, abs(vUv.y - 0.5) * 2.0);
      float core = smoothstep(0.32, 0.0, abs(vUv.y - 0.5) * 2.0);
      float head = smoothstep(uReveal + 0.12, uReveal - 0.02, vUv.x);
      float tail = smoothstep(0.0, 0.40, vUv.x);
      vec3 col = mix(vec3(0.42, 0.90, 1.0), vec3(1.0, 0.98, 0.88), core);
      gl_FragColor = vec4(col, (edge * 0.55 + core * 0.75) * head * tail * uFade);
    }`, { uReveal: { value: 0 }, uFade: { value: 1 } });
  const slash = new THREE.Mesh(geo, mat);
  slash.name = 'arco de corte';
  group.add(slash);

  const glow = glowSprite(0xbfefff, 1.2, 0.55, ctx.soft);
  group.add(glow);
  const burst = makeBurst(90, ctx.soft, 0xcfefff, 0.05, 0.7);
  group.add(burst.points);
  let fired = false;

  return {
    group,
    duration: 1.7,
    update(t, dt) {
      const reveal = clamp(t / 0.55, 0, 1);
      mat.uniforms.uReveal.value = reveal;
      mat.uniforms.uFade.value = 1 - clamp((t - 0.9) / 0.8, 0, 1);
      glow.position.copy(arcPoint(reveal));
      glow.scale.setScalar(0.8 + Math.sin(t * 24.0) * 0.08);
      if (!fired) {
        fired = true;
        burst.spawn(arcPoint(1), 50, 4.0, 0.8, 1.0, new THREE.Vector3(0, 0.3, 0), 0.3);
      }
      burst.update(dt, -3.0);
    },
  };
}
