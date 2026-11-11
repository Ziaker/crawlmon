import * as THREE from 'three';
import {
  TAU, clamp, lerp, easeOutCubic, rand, liveParams, stageRoot, placeDummy,
  ringMesh, glowSprite, shaderMaterial, makeBurst, makePoints, COLORS,
} from '../helpers.js';
import {
  NOISE_GLSL, bladeCrownGeometry, makeFlipbookPlane, makeSmokeField, makeStreakField,
  loadFlipbook,
} from '../vfxlib.js';

const SMOKE = loadFlipbook(new URL('../../../../assets/vfx/flipbook_smoke.png', import.meta.url).href);
const IMPACT = loadFlipbook(new URL('../../../../assets/vfx/flipbook_impact.png', import.meta.url).href);

export const REF_DEFAULTS = {
  crown: {
    spikes: 16, height: 2.3, radius: 1.15, debris: 18, core: 1.0,
    hot: '#fff6e2', mid: '#ffb02e', dark: '#b83300',
  },
  slash: {
    arc: 150, radius: 2.1, width: 0.62, tilt: 48,
    hot: '#ffffff', body: '#4fd4ff', edge: '#8a5cff',
  },
  vortex: {
    radius: 2.2, height: 3.4, spin: 1.0, particles: 700,
    deep: '#0b2a63', mid: '#2fb9ff', hot: '#eaffff',
  },
  aura: {
    radius: 0.85, height: 2.7, count: 90,
    hot: '#f2ffff', mid: '#35c9ff', ring: '#7a5cff',
  },
  dust: {
    size: 0.95, density: 1.0, rise: 0.35, opacity: 0.55, color: '#cbbca4',
  },
  shockwave: {
    radius: 4.8, speed: 1.0, rings: 2, dust: 22,
    hot: '#fff6e0', mid: '#6fd8ff',
  },
};

function easeOutBack(t) {
  const c1 = 1.70158;
  const c3 = c1 + 1;
  const x = clamp(t, 0, 1);
  return 1 + c3 * Math.pow(x - 1, 3) + c1 * Math.pow(x - 1, 2);
}
const smooth01 = (x) => {
  const t = clamp(x, 0, 1);
  return t * t * (3 - 2 * t);
};

// ── LIB-VFX-14 — Impact Crown (DBFZ / Sparking! Zero) ───────────────────────
export function createCrownRef(ctx) {
  const p = liveParams(ctx, REF_DEFAULTS.crown);
  const group = stageRoot(ctx.stage);
  const dist = ctx.stage.dist;

  const geo = bladeCrownGeometry({ count: p.spikes, height: p.height, radius: p.radius, layers: 2 });
  const mat = new THREE.ShaderMaterial({
    uniforms: {
      uTime: { value: 0 }, uOpen: { value: 0 }, uFade: { value: 1 },
      uHot: { value: new THREE.Color(p.hot) },
      uMid: { value: new THREE.Color(p.mid) },
      uDark: { value: new THREE.Color(p.dark) },
    },
    vertexShader: `
      attribute float aT; attribute float aSide; attribute float aSeed; attribute float aLayer;
      varying float vT; varying float vSide; varying float vSeed; varying float vLayer;
      void main() {
        vT = aT; vSide = aSide; vSeed = aSeed; vLayer = aLayer;
        gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
      }`,
    fragmentShader: NOISE_GLSL + `
      varying float vT; varying float vSide; varying float vSeed; varying float vLayer;
      uniform float uTime; uniform float uOpen; uniform float uFade;
      uniform vec3 uHot; uniform vec3 uMid; uniform vec3 uDark;
      void main() {
        float across = abs(vSide);
        float edge = 1.0 - across;
        float body = smoothstep(0.0, 0.06, vT) * (1.0 - smoothstep(0.84, 1.0, vT));
        float n = fbm2(vec2(vSeed * 11.0, vT * 5.0 - uTime * 2.6));
        float coreLine = smoothstep(0.30, 0.0, across);
        float a = body * (0.40 + 0.60 * edge) * (0.40 + n * 0.85) * uOpen * uFade;
        a *= mix(0.55, 1.0, vLayer);
        vec3 col = mix(uDark, uMid, smoothstep(0.0, 0.55, vT));
        col = mix(col, uHot, smoothstep(0.35, 0.9, edge * body));
        col += uHot * coreLine * 0.9;
        gl_FragColor = vec4(col * 1.55, a);
      }`,
    transparent: true, depthWrite: false, side: THREE.DoubleSide, blending: THREE.NormalBlending,
  });
  const blades = new THREE.Mesh(geo, mat);
  blades.name = 'lâminas da coroa';
  group.add(blades);

  const flash = glowSprite(0xfff0c0, 2.6, 0.9, ctx.soft);
  flash.name = 'clarão';
  flash.position.set(0, 0.9, -dist);
  group.add(flash);

  const core = makeFlipbookPlane(IMPACT, { size: 3.2, fps: 30 });
  core.mesh.name = 'núcleo (flipbook)';
  core.mesh.position.set(0, 1.05, -dist);
  group.add(core.mesh);

  const debris = new THREE.InstancedMesh(
    new THREE.TetrahedronGeometry(0.1, 0),
    new THREE.MeshStandardMaterial({ color: 0x6b4a33, roughness: 0.85, metalness: 0.05 }),
    p.debris
  );
  debris.name = 'estilhaços';
  group.add(debris);
  const bits = [];
  for (let i = 0; i < p.debris; i++) {
    const a = rand() * TAU;
    const up = 1.6 + rand() * 3.4;
    bits.push({
      p: new THREE.Vector3(0, 0.8, -dist),
      v: new THREE.Vector3(Math.cos(a) * (1.4 + rand() * 2.4), up, Math.sin(a) * (1.4 + rand() * 2.4)),
      r: new THREE.Vector3(rand() * TAU, rand() * TAU, rand() * TAU),
      s: 0.5 + rand() * 1.1,
    });
  }
  const dummy = new THREE.Object3D();

  return {
    group,
    duration: 1.6,
    update(t, dt, camera) {
      const open = easeOutBack(t / 0.16);
      const fade = 1 - smooth01((t - 0.55) / 0.5);
      mat.uniforms.uTime.value = t;
      mat.uniforms.uOpen.value = clamp(open, 0, 1.2);
      mat.uniforms.uFade.value = fade;
      mat.uniforms.uHot.value.set(p.hot);
      mat.uniforms.uMid.value.set(p.mid);
      mat.uniforms.uDark.value.set(p.dark);
      blades.scale.setScalar(0.55 + clamp(open, 0, 1) * 0.55);

      flash.scale.setScalar(p.core * (0.5 + easeOutCubic(t / 0.18) * 1.6));
      flash.material.opacity = 0.9 * fade * (0.5 + p.core * 0.5);
      core.update(t, camera);
      core.mesh.scale.multiplyScalar(p.core);
      core.mat.uniforms.uOpacity.value = 0.9 * fade;
      for (let i = 0; i < p.debris; i++) {
        const b = bits[i];
        b.v.y -= 9.0 * dt;
        b.p.addScaledVector(b.v, dt);
        if (b.p.y < 0.07) { b.p.y = 0.07; b.v.y *= -0.35; b.v.x *= 0.6; b.v.z *= 0.6; }
        b.r.x += dt * 6; b.r.y += dt * 4;
        dummy.position.copy(b.p);
        dummy.rotation.set(b.r.x, b.r.y, b.r.z);
        dummy.scale.setScalar(b.s * (1 - smooth01((t - 1.0) / 0.45)) * fade);
        dummy.updateMatrix();
        debris.setMatrixAt(i, dummy.matrix);
      }
      debris.instanceMatrix.needsUpdate = true;
    },
  };
}

// ── LIB-VFX-20 — Slash Arc (Guilty Gear / Persona) ──────────────────────────
export function createSlashRef(ctx) {
  const p = liveParams(ctx, REF_DEFAULTS.slash);
  const group = stageRoot(ctx.stage);
  const dist = ctx.stage.dist;
  const arc = THREE.MathUtils.degToRad(p.arc);
  const tilt = THREE.MathUtils.degToRad(p.tilt);
  const cs = Math.cos(tilt);
  const sn = Math.sin(tilt);
  const N = 140;

  const arcPoint = (u) => {
    const th = -arc / 2 + arc * u;
    const lx = Math.cos(th) * p.radius;
    const ly = Math.sin(th) * p.radius;
    return new THREE.Vector3(
      lx * cs - ly * sn,
      1.3 + lx * sn + ly * cs,
      -dist + Math.sin(th * 1.4) * 0.28
    );
  };

  // Fita construída à mão (tangente × normal do plano do arco)
  const buildRibbon = (widthMul) => {
    const pos = [];
    const uv = [];
    const idx = [];
    const up = new THREE.Vector3(0, 0, 1);
    const tan = new THREE.Vector3();
    const side = new THREE.Vector3();
    for (let i = 0; i <= N; i++) {
      const q = arcPoint(i / N);
      const q2 = arcPoint(Math.min(1, i / N + 0.01));
      const q0 = arcPoint(Math.max(0, i / N - 0.01));
      tan.copy(q2).sub(q0).normalize();
      side.crossVectors(tan, up).normalize().multiplyScalar(p.width * widthMul * (0.16 + 0.84 * Math.sin((i / N) * Math.PI)) * 0.5);
      pos.push(q.x - side.x, q.y - side.y, q.z - side.z);
      pos.push(q.x + side.x, q.y + side.y, q.z + side.z);
      uv.push(i / N, 0, i / N, 1);
      if (i < N) {
        const a = i * 2;
        idx.push(a, a + 1, a + 2, a + 1, a + 3, a + 2);
      }
    }
    const geo = new THREE.BufferGeometry();
    geo.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
    geo.setAttribute('uv', new THREE.Float32BufferAttribute(uv, 2));
    geo.setIndex(idx);
    return geo;
  };

  const bodyMat = new THREE.ShaderMaterial({
    uniforms: {
      uReveal: { value: 0 }, uFade: { value: 1 }, uTime: { value: 0 },
      uBody: { value: new THREE.Color(p.body) },
      uEdge: { value: new THREE.Color(p.edge) },
    },
    vertexShader: `
      varying vec2 vUv;
      void main() { vUv = uv; gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0); }`,
    fragmentShader: NOISE_GLSL + `
      varying vec2 vUv;
      uniform float uReveal; uniform float uFade; uniform float uTime;
      uniform vec3 uBody; uniform vec3 uEdge;
      void main() {
        float across = abs(vUv.y - 0.5) * 2.0;
        float edgeMask = smoothstep(0.45, 1.0, across);
        float n = fbm2(vec2(vUv.x * 14.0 - uTime * 3.0, vUv.y * 5.0));
        float head = smoothstep(uReveal + 0.10, uReveal - 0.02, vUv.x);
        float tail = smoothstep(0.0, 0.28, vUv.x);
        float erode = smoothstep(0.08, 0.55, n + (1.0 - vUv.x) * 0.35);
        vec3 col = mix(uBody, uEdge, edgeMask);
        col = mix(col, vec3(1.0), smoothstep(0.8, 1.0, across) * 0.85);
        float a = (0.30 + edgeMask * 0.70) * head * tail * erode * uFade;
        gl_FragColor = vec4(col * 1.5, a);
      }`,
    transparent: true, depthWrite: false, side: THREE.DoubleSide, blending: THREE.NormalBlending,
  });
  const body = new THREE.Mesh(buildRibbon(1.0), bodyMat);
  body.name = 'corpo do arco';
  group.add(body);

  const coreMat = new THREE.ShaderMaterial({
    uniforms: {
      uReveal: { value: 0 }, uFade: { value: 1 }, uTime: { value: 0 },
      uHot: { value: new THREE.Color(p.hot) },
    },
    vertexShader: `varying vec2 vUv; void main(){ vUv=uv; gl_Position=projectionMatrix*modelViewMatrix*vec4(position,1.0); }`,
    fragmentShader: `
      varying vec2 vUv;
      uniform float uReveal; uniform float uFade; uniform float uTime;
      uniform vec3 uHot;
      void main() {
        float across = abs(vUv.y - 0.5) * 2.0;
        float core = smoothstep(0.55, 0.0, across);
        float head = smoothstep(uReveal + 0.10, uReveal - 0.02, vUv.x);
        float tail = smoothstep(0.0, 0.42, vUv.x);
        gl_FragColor = vec4(uHot * 2.2, core * head * tail * uFade * 0.95);
      }`,
    transparent: true, depthWrite: false, side: THREE.DoubleSide, blending: THREE.AdditiveBlending,
  });
  const core = new THREE.Mesh(buildRibbon(0.34), coreMat);
  core.name = 'gume quente';
  group.add(core);

  const streaks = makeStreakField({ count: 26, color: '#dff6ff', size: 0.026 });
  streaks.mesh.name = 'faíscas';
  group.add(streaks.mesh);

  const shards = new THREE.InstancedMesh(
    new THREE.TetrahedronGeometry(0.09, 0),
    new THREE.MeshStandardMaterial({ color: 0x2c3a4a, roughness: 0.4, metalness: 0.5 }),
    10
  );
  shards.name = 'estilhaços';
  group.add(shards);
  const shardData = [];
  for (let i = 0; i < 10; i++) {
    shardData.push({ p: new THREE.Vector3(), v: new THREE.Vector3(), r: new THREE.Vector3(rand() * 6, rand() * 6, rand() * 6) });
  }
  const dummy = new THREE.Object3D();

  return {
    group,
    duration: 1.5,
    update(t, dt) {
      const reveal = clamp(t / 0.16, 0, 1);
      const fade = 1 - smooth01((t - 0.62) / 0.55);
      bodyMat.uniforms.uReveal.value = reveal;
      bodyMat.uniforms.uFade.value = fade;
      bodyMat.uniforms.uTime.value = t;
      bodyMat.uniforms.uBody.value.set(p.body);
      bodyMat.uniforms.uEdge.value.set(p.edge);
      coreMat.uniforms.uReveal.value = reveal;
      coreMat.uniforms.uFade.value = fade;
      coreMat.uniforms.uHot.value.set(p.hot);

      if (t < 0.16) {
        const q = arcPoint(reveal);
        for (let i = 0; i < 2; i++) {
          streaks.spawn(q, new THREE.Vector3((rand() - 0.5) * 6, (rand() - 0.2) * 4, (rand() - 0.5) * 6), 0.45, 0.25);
        }
        for (let i = 0; i < 10; i++) {
          const sd = shardData[i];
          if (sd.v.lengthSq() === 0) {
            sd.p.copy(q);
            sd.v.set((rand() - 0.5) * 3.5, rand() * 2.5, (rand() - 0.5) * 3.5);
          }
        }
      }
      streaks.update(dt, -5);

      for (let i = 0; i < 10; i++) {
        const sd = shardData[i];
        sd.v.y -= 7 * dt;
        sd.p.addScaledVector(sd.v, dt);
        sd.r.x += dt * 8; sd.r.y += dt * 6;
        const hide = 1 - smooth01((t - 1.0) / 0.45);
        dummy.position.copy(sd.p);
        dummy.rotation.set(sd.r.x, sd.r.y, sd.r.z);
        dummy.scale.setScalar(sd.v.lengthSq() > 0 ? hide : 0);
        dummy.updateMatrix();
        shards.setMatrixAt(i, dummy.matrix);
      }
      shards.instanceMatrix.needsUpdate = true;
    },
  };
}

// ── LIB-VFX-01 — Vortex Mesh (Genshin / HSR portal) ─────────────────────────
export function createVortexRef(ctx) {
  const p = liveParams(ctx, REF_DEFAULTS.vortex);
  const group = new THREE.Group();
  const H = p.height;
  const R = p.radius;

  const shell = (dir, base, top, twist, phase, alpha) => {
    const mat = new THREE.ShaderMaterial({
      uniforms: {
        uTime: { value: 0 }, uSpin: { value: p.spin }, uAlpha: { value: alpha },
        uDeep: { value: new THREE.Color(p.deep) },
        uMid: { value: new THREE.Color(p.mid) },
        uHot: { value: new THREE.Color(p.hot) },
      },
      vertexShader: `
        varying vec2 vUv;
        uniform float uTime;
        void main() {
          vUv = uv;
          vec3 q = position;
          float w = 1.0 + 0.055 * sin(uv.x * 31.4159 + uv.y * 9.0 - uTime * 1.3);
          q.xz *= w;
          gl_Position = projectionMatrix * modelViewMatrix * vec4(q, 1.0);
        }`,
      fragmentShader: NOISE_GLSL + `
        varying vec2 vUv;
        uniform float uTime; uniform float uSpin; uniform float uAlpha;
        uniform vec3 uDeep; uniform vec3 uMid; uniform vec3 uHot;
        void main() {
          float a = vUv.x * 6.28318;
          float n = fbm2(vec2(a * 2.0 + uTime * 0.12 * uSpin, vUv.y * 4.5 - uTime * 0.75 * uSpin));
          float spiral = 0.5 + 0.5 * sin(a * 3.0 ${dir > 0 ? '-' : '+'} vUv.y * 15.0 + uTime * 3.0 * uSpin);
          float bands = smoothstep(0.42, 0.92, n * 0.65 + spiral * 0.55);
          float vFade = smoothstep(0.0, 0.08, vUv.y) * (1.0 - smoothstep(0.78, 1.0, vUv.y));
          float mouth = smoothstep(0.72, 1.0, vUv.y);
          vec3 col = mix(uDeep, uMid, smoothstep(0.1, 0.75, n + vUv.y * 0.25));
          col = mix(col, uHot, bands * 0.75 + mouth * 0.35);
          float alpha = (bands * 0.55 + n * 0.18) * vFade * uAlpha;
          gl_FragColor = vec4(col, clamp(alpha, 0.0, 0.92));
        }`,
      transparent: true, depthWrite: false, side: THREE.FrontSide, blending: THREE.NormalBlending,
    });
    const mesh = new THREE.Mesh(
      funnelGeo({ height: H, radius: base, top, twist, segments: 180, rings: 80 }),
      mat
    );
    mesh.name = dir > 0 ? 'casca externa' : 'casca interna';
    group.add(mesh);
    return { mesh, mat };
  };

  const outer = shell(1, 0.14, R, 8.0, 4.0, 1.0);
  const inner = shell(-1, 0.36, R * 0.72, -12.0, 5.5, 0.75);

  const rimMat = new THREE.MeshBasicMaterial({ color: new THREE.Color(p.hot), transparent: true, opacity: 0.75, blending: THREE.AdditiveBlending, depthWrite: false });
  const rim = new THREE.Mesh(new THREE.TorusGeometry(R, 0.035, 10, 160), rimMat);
  rim.name = 'aro da boca';
  rim.rotation.x = Math.PI / 2;
  rim.position.y = H;
  group.add(rim);

  const discMat = new THREE.ShaderMaterial({
    uniforms: { uTime: { value: 0 }, uSpin: { value: p.spin }, uHot: { value: new THREE.Color(p.hot) }, uMid: { value: new THREE.Color(p.mid) } },
    vertexShader: `varying vec2 vUv; void main(){ vUv=uv; gl_Position=projectionMatrix*modelViewMatrix*vec4(position,1.0); }`,
    fragmentShader: NOISE_GLSL + `
      varying vec2 vUv;
      uniform float uTime; uniform float uSpin; uniform vec3 uHot; uniform vec3 uMid;
      void main() {
        vec2 q = vUv - 0.5;
        float r = length(q) * 2.0;
        float a = atan(q.y, q.x);
        float spiral = 0.5 + 0.5 * sin(a * 2.0 + log(max(r, 0.02)) * 8.0 - uTime * 3.2 * uSpin);
        float arms = pow(spiral, 4.0);
        float n = fbm2(vec2(a * 3.0, r * 5.0 - uTime * 0.5));
        float rimFade = smoothstep(1.0, 0.86, r) * smoothstep(0.05, 0.3, r);
        vec3 col = mix(uMid, uHot, arms * 0.8 + n * 0.2);
        float alpha = (arms * 0.55 + n * 0.10) * rimFade;
        gl_FragColor = vec4(col, alpha);
      }`,
    transparent: true, depthWrite: false, side: THREE.DoubleSide, blending: THREE.AdditiveBlending,
  });
  const disc = new THREE.Mesh(new THREE.PlaneGeometry(R * 2.1, R * 2.1), discMat);
  disc.name = 'disco espiral';
  disc.rotation.x = -Math.PI / 2;
  disc.position.y = 0.02;
  group.add(disc);

  const count = p.particles;
  const pts = makePoints(count, ctx.soft, 0xbfefff, 0.05, 0.85);
  pts.name = 'partículas';
  const pos = pts.geometry.attributes.position.array;
  const ang = new Float32Array(count);
  const u = new Float32Array(count);
  const spd = new Float32Array(count);
  for (let i = 0; i < count; i++) { ang[i] = rand() * TAU; u[i] = rand(); spd[i] = 0.4 + rand() * 0.9; }
  group.add(pts);

  const shards = new THREE.InstancedMesh(
    new THREE.TetrahedronGeometry(0.07, 0),
    new THREE.MeshStandardMaterial({ color: 0x335577, roughness: 0.5, metalness: 0.3 }),
    22
  );
  shards.name = 'detritos orbitando';
  group.add(shards);
  const shardData = [];
  for (let i = 0; i < 22; i++) shardData.push({ a: rand() * TAU, r: 0.6 + rand() * (R * 0.9), y: rand() * H, s: 0.5 + rand() });
  const dummy = new THREE.Object3D();

  return {
    group,
    duration: 6,
    update(t, dt) {
      outer.mat.uniforms.uTime.value = t;
      inner.mat.uniforms.uTime.value = t;
      discMat.uniforms.uTime.value = t;
      discMat.uniforms.uHot.value.set(p.hot);
      discMat.uniforms.uMid.value.set(p.mid);
      outer.mat.uniforms.uDeep.value.set(p.deep);
      outer.mat.uniforms.uMid.value.set(p.mid);
      outer.mat.uniforms.uHot.value.set(p.hot);
      inner.mat.uniforms.uDeep.value.set(p.deep);
      inner.mat.uniforms.uMid.value.set(p.mid);
      inner.mat.uniforms.uHot.value.set(p.hot);
      rimMat.color.set(p.hot);
      rim.scale.setScalar(1 + Math.sin(t * 2.0) * 0.01);
      outer.mesh.rotation.y = t * 0.14 * p.spin;
      inner.mesh.rotation.y = -t * 0.26 * p.spin;
      disc.rotation.z = -t * 0.45 * p.spin;
      for (let i = 0; i < count; i++) {
        u[i] += dt * (0.14 + spd[i] * 0.2);
        if (u[i] > 1) { u[i] = 0; ang[i] = rand() * TAU; }
        const v = u[i];
        const r = 0.14 + v * (R - 0.14);
        const a = ang[i] + v * 6.5 + t * (0.3 + spd[i] * 0.25) * p.spin;
        pos[i * 3] = Math.cos(a) * r;
        pos[i * 3 + 1] = 0.04 + v * v * H;
        pos[i * 3 + 2] = Math.sin(a) * r;
      }
      pts.geometry.attributes.position.needsUpdate = true;

      for (let i = 0; i < 22; i++) {
        const s = shardData[i];
        s.a += dt * 0.6;
        s.y += dt * 0.25;
        if (s.y > H) s.y = 0;
        dummy.position.set(Math.cos(s.a) * s.r, s.y, Math.sin(s.a) * s.r);
        dummy.rotation.set(t * 1.2 + i, t * 0.8, t);
        dummy.scale.setScalar(s.s);
        dummy.updateMatrix();
        shards.setMatrixAt(i, dummy.matrix);
      }
      shards.instanceMatrix.needsUpdate = true;
    },
  };
}

// ── LIB-VFX-09 — Aura Burst (DBFZ / Sparking! Zero) ─────────────────────────
export function createAuraRef(ctx) {
  const p = liveParams(ctx, REF_DEFAULTS.aura);
  const group = stageRoot(ctx.stage);

  const H = p.height;
  const mat = new THREE.ShaderMaterial({
    uniforms: {
      uTime: { value: 0 }, uOpen: { value: 0 }, uFade: { value: 1 },
      uHot: { value: new THREE.Color(p.hot) },
      uMid: { value: new THREE.Color(p.mid) },
    },
    vertexShader: `
      varying vec2 vUv; varying vec3 vN; varying vec3 vView;
      uniform float uTime;
      void main() {
        vUv = uv;
        vec3 q = position;
        float wob = sin(uv.y * 16.0 + uTime * 5.0 + uv.x * 22.0) * 0.05
                  + sin(uv.y * 31.0 - uTime * 7.0) * 0.02;
        q.xz *= 1.0 + wob;
        vec4 mv = modelViewMatrix * vec4(q, 1.0);
        vView = -mv.xyz;
        vN = normalize(normalMatrix * normal);
        gl_Position = projectionMatrix * mv;
      }`,
    fragmentShader: NOISE_GLSL + `
      varying vec2 vUv; varying vec3 vN; varying vec3 vView;
      uniform float uTime; uniform float uOpen; uniform float uFade;
      uniform vec3 uHot; uniform vec3 uMid;
      void main() {
        float n = fbm2(vec2(vUv.x * 9.0 + uTime * 0.4, vUv.y * 5.5 - uTime * 2.4));
        float fres = 1.0 - abs(dot(normalize(vN), normalize(vView)));
        float vertical = smoothstep(0.0, 0.10, vUv.y) * (1.0 - smoothstep(0.70, 1.0, vUv.y));
        float a = (0.10 + fres * 0.85) * (0.30 + n * 0.95) * vertical * uOpen * uFade;
        vec3 col = mix(uMid, uHot, smoothstep(0.35, 0.95, fres) * 0.7 + n * 0.35);
        gl_FragColor = vec4(col * 1.35, clamp(a, 0.0, 0.85));
      }`,
    transparent: true, depthWrite: false, side: THREE.DoubleSide, blending: THREE.AdditiveBlending,
  });
  const column = new THREE.Mesh(new THREE.CylinderGeometry(p.radius * 0.7, p.radius, H, 56, 28, true), mat);
  column.name = 'coluna';
  column.position.y = H / 2;
  group.add(column);

  const ringMat = new THREE.ShaderMaterial({
    uniforms: { uTime: { value: 0 }, uFade: { value: 1 }, uColor: { value: new THREE.Color(p.ring) } },
    vertexShader: `varying vec2 vUv; void main(){ vUv=uv; gl_Position=projectionMatrix*modelViewMatrix*vec4(position,1.0); }`,
    fragmentShader: NOISE_GLSL + `
      varying vec2 vUv;
      uniform float uTime; uniform float uFade; uniform vec3 uColor;
      void main() {
        vec2 q = vUv - 0.5;
        float r = length(q) * 2.0;
        float band = smoothstep(0.10, 0.0, abs(r - 0.82));
        float n = fbm2(vec2(atan(q.y, q.x) * 5.0, uTime * 0.6));
        gl_FragColor = vec4(uColor * 1.4, band * (0.35 + n * 0.8) * uFade);
      }`,
    transparent: true, depthWrite: false, side: THREE.DoubleSide, blending: THREE.AdditiveBlending,
  });
  const ring = new THREE.Mesh(new THREE.PlaneGeometry(p.radius * 5.0, p.radius * 5.0), ringMat);
  ring.name = 'anel de impulso';
  ring.rotation.x = -Math.PI / 2;
  ring.position.y = 0.03;
  group.add(ring);

  const count = p.count;
  const embers = new THREE.InstancedMesh(
    new THREE.PlaneGeometry(0.045, 0.16),
    new THREE.MeshBasicMaterial({ color: new THREE.Color(p.hot), transparent: true, opacity: 0.9, blending: THREE.AdditiveBlending, depthWrite: false, side: THREE.DoubleSide }),
    count
  );
  embers.name = 'brasas';
  group.add(embers);
  const emberData = [];
  for (let i = 0; i < count; i++) {
    emberData.push({ a: rand() * TAU, r: p.radius * (0.2 + rand() * 1.1), y: rand() * H, sp: 0.7 + rand() * 1.6, s: 0.5 + rand() });
  }
  const dummy = new THREE.Object3D();

  return {
    group,
    duration: 1.6,
    update(t, dt) {
      const open = clamp(t / 0.12, 0, 1);
      const fade = 1 - smooth01((t - 0.7) / 0.8);
      mat.uniforms.uTime.value = t;
      mat.uniforms.uOpen.value = open;
      mat.uniforms.uFade.value = fade;
      mat.uniforms.uHot.value.set(p.hot);
      mat.uniforms.uMid.value.set(p.mid);
      column.scale.set(1, 0.6 + open * 0.4, 1);
      ringMat.uniforms.uTime.value = t;
      ringMat.uniforms.uFade.value = fade;
      ringMat.uniforms.uColor.value.set(p.ring);
      ring.scale.setScalar(0.5 + open * 0.9);

      for (let i = 0; i < count; i++) {
        const e = emberData[i];
        e.y += dt * e.sp;
        if (e.y > H * 1.15) { e.y = 0; e.a = rand() * TAU; }
        const r = e.r * (1 - e.y / (H * 1.4) * 0.35);
        dummy.position.set(Math.cos(e.a) * r, e.y * (0.6 + open * 0.4), Math.sin(e.a) * r);
        dummy.rotation.set(0, -e.a, 0.2 * Math.sin(t * 4 + i));
        dummy.scale.set(e.s, e.s * (0.6 + open * 0.6), e.s);
        dummy.updateMatrix();
        embers.setMatrixAt(i, dummy.matrix);
      }
      embers.instanceMatrix.needsUpdate = true;
    },
  };
}

// ── LIB-VFX-10 — Dust Trail (Guilty Gear / DBFZ) ────────────────────────────
export function createDustRef(ctx) {
  const p = liveParams(ctx, REF_DEFAULTS.dust);
  const group = stageRoot(ctx.stage);
  const dist = ctx.stage.dist;

  const smoke = makeSmokeField({ count: 64, texture: SMOKE, color: p.color, opacity: p.opacity });
  group.add(smoke.mesh);

  const ringMat = new THREE.ShaderMaterial({
    uniforms: { uFade: { value: 1 }, uColor: { value: new THREE.Color(p.color) } },
    vertexShader: `varying vec2 vUv; void main(){ vUv=uv; gl_Position=projectionMatrix*modelViewMatrix*vec4(position,1.0); }`,
    fragmentShader: NOISE_GLSL + `
      varying vec2 vUv;
      uniform float uFade; uniform vec3 uColor;
      void main() {
        vec2 q = vUv - 0.5;
        float r = length(q) * 2.0;
        float band = smoothstep(0.12, 0.0, abs(r - 0.8));
        float n = fbm2(vec2(atan(q.y, q.x) * 6.0, r * 4.0));
        gl_FragColor = vec4(uColor * 0.9, band * (0.2 + n * 0.4) * uFade);
      }`,
    transparent: true, depthWrite: false, side: THREE.DoubleSide, blending: THREE.NormalBlending,
  });
  const ring = new THREE.Mesh(new THREE.PlaneGeometry(2.6, 2.6), ringMat);
  ring.name = 'esteira no chão';
  ring.rotation.x = -Math.PI / 2;
  ring.position.y = 0.02;
  group.add(ring);

  let acc = 0;
  return {
    group,
    duration: 3.2,
    update(t, dt) {
      const d = (dist - 1.25) * easeOutCubic(clamp(t / 3.0, 0, 1));
      placeDummy(ctx, d);
      smoke.setColor(p.color);
      smoke.setOpacity(p.opacity);
      acc += dt;
      if (acc > 0.045 / p.density) {
        acc = 0;
        const side = (rand() - 0.5) * 0.9;
        const back = 0.35 + rand() * 0.5;
        smoke.spawn(new THREE.Vector3(side, 0.12 + rand() * 0.25, -d + back), {
          vel: new THREE.Vector3((rand() - 0.5) * 0.5, p.rise * (0.5 + rand()), 0.4 + rand() * 0.7),
          life: 1.0 + rand() * 0.9,
          scale: p.size * (0.7 + rand() * 0.8),
        });
      }
      smoke.update(dt);
      ring.position.z = -d + 0.6;
      ring.scale.setScalar(0.9 + Math.sin(t * 6.0) * 0.05);
      ringMat.uniforms.uFade.value = 1 - smooth01((t - 2.4) / 0.8);
      ringMat.uniforms.uColor.value.set(p.color);
    },
  };
}

// ── LIB-VFX-13 — Shockwave Ring (DBFZ / Sparking! Zero) ─────────────────────
export function createShockwaveRef(ctx) {
  const p = liveParams(ctx, REF_DEFAULTS.shockwave);
  const group = stageRoot(ctx.stage);
  const dist = ctx.stage.dist;
  const maxR = p.radius;

  const makeRing = (delay, strength) => {
    const mat = new THREE.ShaderMaterial({
      uniforms: {
        uFront: { value: 0 }, uFade: { value: 1 }, uTime: { value: 0 },
        uHot: { value: new THREE.Color(p.hot) },
        uMid: { value: new THREE.Color(p.mid) },
        uStrength: { value: strength },
      },
      vertexShader: `varying vec2 vUv; void main(){ vUv=uv; gl_Position=projectionMatrix*modelViewMatrix*vec4(position,1.0); }`,
      fragmentShader: NOISE_GLSL + `
        varying vec2 vUv;
        uniform float uFront; uniform float uFade; uniform float uTime;
        uniform vec3 uHot; uniform vec3 uMid; uniform float uStrength;
        void main() {
          vec2 q = vUv - 0.5;
          float r = length(q) * 2.0;
          float band = exp(-pow((r - uFront) / 0.030, 2.0));
          float halo = exp(-pow((r - uFront) / 0.11, 2.0)) * 0.35;
          float n = fbm2(vec2(atan(q.y, q.x) * 7.0, r * 9.0 - uTime * 3.0));
          float a = (band + halo) * (0.35 + n * 0.9) * uFade * uStrength;
          vec3 col = mix(uMid, uHot, band);
          gl_FragColor = vec4(col * 1.6, clamp(a, 0.0, 1.0));
        }`,
      transparent: true, depthWrite: false, side: THREE.DoubleSide, blending: THREE.AdditiveBlending,
    });
    const mesh = new THREE.Mesh(new THREE.PlaneGeometry(maxR * 2.15, maxR * 2.15), mat);
    mesh.name = `frente ${strength}`;
    mesh.rotation.x = -Math.PI / 2;
    mesh.position.set(0, 0.03 + delay * 0.002, -dist);
    group.add(mesh);
    return { mesh, mat, delay };
  };

  const rings = [];
  for (let i = 0; i < Math.max(1, Math.round(p.rings)); i++) {
    rings.push(makeRing(i * 0.08, i === 0 ? 1.0 : 0.55));
  }

  const flash = glowSprite(0xfff2c2, 2.2, 0.85, ctx.soft);
  flash.name = 'clarão';
  flash.position.set(0, 0.7, -dist);
  group.add(flash);

  const smoke = makeSmokeField({ count: 40, texture: SMOKE, color: '#cbbca4', opacity: 0.5 });
  group.add(smoke.mesh);
  let spawned = false;

  return {
    group,
    duration: 1.9,
    update(t, dt) {
      const speed = 1.0 / Math.max(0.3, p.speed);
      for (const r of rings) {
        const k = clamp((t - r.delay) * speed / 0.5, 0, 1);
        r.mat.uniforms.uFront.value = easeOutCubic(k) * 0.98;
        r.mat.uniforms.uFade.value = 1 - smooth01(k);
        r.mat.uniforms.uTime.value = t;
        r.mat.uniforms.uHot.value.set(p.hot);
        r.mat.uniforms.uMid.value.set(p.mid);
        r.mesh.scale.setScalar(0.2 + easeOutCubic(k) * 0.97);
      }
      flash.scale.setScalar(0.6 + easeOutCubic(t / 0.18) * 1.8);
      flash.material.opacity = Math.max(0, 0.85 - t * 1.4);

      if (!spawned) {
        spawned = true;
        const n = Math.round(p.dust);
        for (let i = 0; i < n; i++) {
          const a = (i / n) * TAU;
          smoke.spawn(new THREE.Vector3(Math.cos(a) * 0.35, 0.1, -dist + Math.sin(a) * 0.35), {
            vel: new THREE.Vector3(Math.cos(a) * 2.6, 0.5 + rand() * 0.6, Math.sin(a) * 2.6),
            life: 1.0 + rand() * 0.6,
            scale: 1.1 + rand() * 0.8,
          });
        }
      }
      smoke.update(dt);
    },
  };
}

// geometria de funil local (evita import circular com forms.js)
function funnelGeo({ height, radius, top, twist, segments, rings }) {
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
