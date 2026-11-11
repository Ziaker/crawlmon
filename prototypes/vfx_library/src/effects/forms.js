import * as THREE from 'three';
import {
  TAU, clamp, lerp, easeOutCubic, rand, randRange, hash,
  funnelGeometry, ribbonGeometry, ringMesh, glowSprite, shaderMaterial,
  makePoints, makeBurst, liveParams, COLORS,
} from '../helpers.js';

const vShader = `varying vec2 vUv;
varying vec3 vPos;
void main() {
  vUv = uv;
  vPos = position;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}`;

/** Defaults de cada componente — fonte única (registry e demos usam estes). */
export const FORM_DEFAULTS = {
  vortex: { radius: 2.15, height: 3.3, spin: 1.0, particles: 640 },
  funnel: { height: 4.6, width: 1.0, twist: 10, opacity: 1.0 },
  ribbon: { radius: 1.0, height: 3.2, turns: 3.0, width: 0.55, flow: 1.0 },
  helix: { radius: 0.95, height: 4.2, turns: 3.2, thickness: 0.028, speed: 1.0 },
  dissolve: { edge: 0.16, spiral: 0.6, brightness: 1.2 },
};

// LIB-VFX-01 — VORTEX MESH ----------------------------------------------------
export function createVortex(ctx) {
  const p = liveParams(ctx, FORM_DEFAULTS.vortex);
  const group = new THREE.Group();
  const mouth = p.radius;
  const height = p.height;
  const spin = p.spin;

  const shell = (dir, base, top, h, twist, colorA, colorB, alpha, phase) => {
    const mat = shaderMaterial(`
      varying vec2 vUv;
      uniform float uTime;
      uniform float uSpin;
      void main() {
        vUv = uv;
        vec3 q = position;
        float w = 1.0 + 0.05 * sin(uv.x * 31.4159 + uv.y * 9.0 - uTime * 1.4);
        q.xz *= w;
        gl_Position = projectionMatrix * modelViewMatrix * vec4(q, 1.0);
      }`, `
      varying vec2 vUv;
      uniform float uTime;
      uniform float uSpin;
      uniform float uAlpha;
      void main() {
        float a = vUv.x * 6.28318;
        float s = sin(a * 3.0 ${dir > 0 ? '-' : '+'} vUv.y * 24.0 + uTime * ${phase.toFixed(1)} * uSpin);
        float band = smoothstep(0.35, 1.0, s);
        float streak = pow(0.5 + 0.5 * sin(a * 12.0 ${dir > 0 ? '-' : '+'} vUv.y * 58.0 + uTime * 8.0 * uSpin), 7.0);
        float vFade = smoothstep(0.0, 0.10, vUv.y) * smoothstep(1.0, 0.78, vUv.y);
        float hollow = smoothstep(0.0, 0.42, vUv.y);
        vec3 col = mix(vec3(${colorA}), vec3(${colorB}), vUv.y);
        col += vec3(0.75, 0.95, 1.0) * band * 0.5;
        float alpha = (band * 0.20 + streak * 0.55) * vFade;
        alpha *= mix(1.0, hollow, 0.55) * uAlpha;
        gl_FragColor = vec4(col, alpha);
      }`, { uTime: { value: 0 }, uSpin: { value: spin }, uAlpha: { value: alpha } });
    mat.side = THREE.FrontSide;
    const mesh = new THREE.Mesh(funnelGeometry({ height: h, radius: base, top, twist, segments: 168, rings: 72 }), mat);
    mesh.name = dir > 0 ? 'casca externa' : 'casca interna';
    group.add(mesh);
    return { mesh, mat };
  };

  const outer = shell(1, 0.16, mouth, height, 8.0, '0.12, 0.68, 1.0', '0.58, 0.38, 1.0', 1.0, 4.0);
  const inner = shell(-1, 0.40, mouth * 0.72, height * 0.88, -12.0, '0.30, 0.90, 1.0', '0.85, 0.55, 1.0', 0.55, 5.5);

  const discMat = shaderMaterial(vShader, `
    varying vec2 vUv;
    uniform float uTime;
    uniform float uSpin;
    void main() {
      vec2 p = vUv - 0.5;
      float r = length(p) * 2.0;
      float a = atan(p.y, p.x);
      float spiral = 0.5 + 0.5 * sin(a * 2.0 + log(max(r, 0.02)) * 9.0 - uTime * 5.0 * uSpin);
      float arms = pow(spiral, 4.0);
      float rim = smoothstep(1.0, 0.86, r) * smoothstep(0.06, 0.34, r);
      vec3 col = mix(vec3(0.45, 0.92, 1.0), vec3(0.55, 0.40, 1.0), r);
      gl_FragColor = vec4(col, arms * rim * 0.45);
    }`, { uTime: { value: 0 }, uSpin: { value: spin } });
  const disc = new THREE.Mesh(new THREE.PlaneGeometry(mouth * 2.15, mouth * 2.15), discMat);
  disc.name = 'disco espiral';
  disc.rotation.x = -Math.PI / 2;
  disc.position.y = 0.02;
  group.add(disc);

  const ground = ringMesh(mouth * 0.92, mouth * 0.97, COLORS.cyan, 0.26);
  ground.position.y = 0.03;
  group.add(ground);

  const count = p.particles;
  const pts = makePoints(count, ctx.soft, 0x9fe4ff, 0.055, 0.9);
  pts.name = 'partículas';
  const pos = pts.geometry.attributes.position.array;
  const angles = new Float32Array(count);
  const u = new Float32Array(count);
  const speeds = new Float32Array(count);
  for (let i = 0; i < count; i++) {
    angles[i] = rand() * TAU;
    u[i] = rand();
    speeds[i] = 0.4 + rand() * 0.9;
  }
  group.add(pts);

  return {
    group,
    duration: 6,
    update(t, dt) {
      outer.mat.uniforms.uTime.value = t;
      inner.mat.uniforms.uTime.value = t;
      discMat.uniforms.uTime.value = t;
      discMat.uniforms.uSpin.value = spin;
      outer.mesh.rotation.y = t * 0.16 * spin;
      inner.mesh.rotation.y = -t * 0.30 * spin;
      disc.rotation.z = -t * 0.55 * spin;
      ground.scale.setScalar(1 + Math.sin(t * 2.0) * 0.02);
      for (let i = 0; i < count; i++) {
        u[i] += dt * (0.16 + speeds[i] * 0.22);
        if (u[i] > 1) { u[i] = 0; angles[i] = rand() * TAU; }
        const v = u[i];
        const r = 0.16 + v * (mouth - 0.16);
        const lift = (v * v * height) * (0.75 + speeds[i] * 0.25);
        const a = angles[i] + v * 7.0 + t * (0.35 + speeds[i] * 0.3) * spin;
        pos[i * 3] = Math.cos(a) * r;
        pos[i * 3 + 1] = 0.05 + lift;
        pos[i * 3 + 2] = Math.sin(a) * r;
      }
      pts.geometry.attributes.position.needsUpdate = true;
    },
  };
}

// LIB-VFX-02 — TORNADO / FUNNEL MESH -----------------------------------------
export function createFunnel(ctx) {
  const p = liveParams(ctx, FORM_DEFAULTS.funnel);
  const group = new THREE.Group();
  const layers = [];

  const defs = [
    { h: p.height, r: 0.18 * p.width, top: p.width, twist: p.twist, color: [0.3, 0.85, 1.0], speed: 0.25, alpha: 0.42 },
    { h: p.height * 0.92, r: 0.14 * p.width, top: p.width * 0.72, twist: -p.twist * 1.4, color: [0.7, 0.4, 1.0], speed: -0.35, alpha: 0.30 },
    { h: p.height * 0.82, r: 0.10 * p.width, top: p.width * 0.46, twist: p.twist * 1.8, color: [0.9, 0.95, 1.0], speed: 0.5, alpha: 0.22 },
  ];

  for (let idx = 0; idx < defs.length; idx++) {
    const d = defs[idx];
    const mat = shaderMaterial(`
      varying vec2 vUv;
      uniform float uTime;
      void main() {
        vUv = uv;
        vec3 q = position;
        float w = 1.0 + 0.06 * sin(uv.x * 37.7 + uv.y * 12.0 - uTime * 1.9);
        q.xz *= w;
        gl_Position = projectionMatrix * modelViewMatrix * vec4(q, 1.0);
      }`, `
      varying vec2 vUv;
      uniform float uTime;
      uniform vec3 uColor;
      uniform float uAlpha;
      void main() {
        float a = vUv.x * 6.28318;
        float streak = pow(0.5 + 0.5 * sin(a * 9.0 - vUv.y * 14.0 + uTime * 4.2), 4.0);
        float longFade = smoothstep(0.0, 0.08, vUv.y) * smoothstep(1.0, 0.72, vUv.y);
        vec3 col = uColor + vec3(0.55, 0.85, 1.0) * streak * 0.6;
        gl_FragColor = vec4(col, (0.05 + streak * 0.55) * longFade * uAlpha);
      }`, {
      uTime: { value: 0 },
      uColor: { value: new THREE.Color(...d.color) },
      uAlpha: { value: d.alpha * p.opacity },
    });
    mat.side = THREE.FrontSide;
    const mesh = new THREE.Mesh(funnelGeometry({ height: d.h, radius: d.r, top: d.top, twist: d.twist, segments: 144, rings: 64 }), mat);
    mesh.name = `camada ${idx + 1}`;
    group.add(mesh);
    layers.push({ mesh, mat, speed: d.speed });
  }

  const ground = ringMesh(p.width * 0.88, p.width * 0.93, COLORS.cyan, 0.28);
  ground.position.y = 0.025;
  group.add(ground);

  const burst = makeBurst(240, ctx.soft, 0xccefff, 0.09, 0.42, false);
  burst.points.name = 'poeira';
  group.add(burst.points);
  let acc = 0;

  return {
    group,
    duration: 6,
    update(t, dt) {
      for (const l of layers) {
        l.mat.uniforms.uTime.value = t;
        l.mesh.rotation.y = t * l.speed;
      }
      ground.scale.setScalar(1 + Math.sin(t * 1.7) * 0.035);
      acc += dt;
      if (acc > 0.05) {
        acc = 0;
        const a = rand() * TAU;
        const r = p.width * (0.65 + rand() * 0.3);
        burst.spawn(new THREE.Vector3(Math.cos(a) * r, 0.05, Math.sin(a) * r), 4, 0.3, 1.3, 0.7, new THREE.Vector3(-Math.cos(a), 0.4, -Math.sin(a)), 0.4);
      }
      burst.update(dt, 0.4);
    },
  };
}

// LIB-VFX-03 — SPIRAL RIBBON --------------------------------------------------
export function createSpiralRibbon(ctx) {
  const p = liveParams(ctx, FORM_DEFAULTS.ribbon);
  const group = new THREE.Group();
  const turns = p.turns;
  const H = p.height;
  const R = p.radius;
  const N = 260;

  const points = [];
  const ups = [];
  for (let i = 0; i <= N; i++) {
    const u = i / N;
    const a = u * TAU * turns;
    const r = R * (0.72 + 0.28 * Math.sin(u * Math.PI));
    points.push(new THREE.Vector3(Math.cos(a) * r, u * H, Math.sin(a) * r));
    ups.push(new THREE.Vector3(Math.cos(a), 0, Math.sin(a)));
  }
  const widths = points.map((_, i) => p.width * (0.18 + 0.82 * Math.sin((i / N) * Math.PI)));
  const geo = ribbonGeometry(points, widths, new THREE.Vector3(0, 1, 0), ups);

  const mat = shaderMaterial(`
    varying vec2 vUv;
    uniform float uTime;
    void main() {
      vUv = uv;
      gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
    }`, `
    varying vec2 vUv;
    uniform float uTime;
    uniform float uFlow;
    void main() {
      float core = smoothstep(0.5, 0.0, abs(vUv.y - 0.5) * 2.0);
      float edge = smoothstep(0.5, 0.32, abs(vUv.y - 0.5) * 2.0);
      float pulse = pow(0.5 + 0.5 * sin(vUv.x * 46.0 - uTime * uFlow * 7.0), 8.0);
      vec3 base = mix(vec3(0.18, 0.72, 1.0), vec3(0.72, 0.45, 1.0), vUv.x);
      vec3 col = base + vec3(0.85, 0.98, 1.0) * pulse * 0.45 + vec3(0.4, 0.9, 1.0) * core * 0.22;
      float alpha = (0.26 + pulse * 0.45) * edge + core * 0.14;
      gl_FragColor = vec4(col, clamp(alpha, 0.0, 0.85));
    }`, { uTime: { value: 0 }, uFlow: { value: p.flow } });
  const ribbon = new THREE.Mesh(geo, mat);
  ribbon.name = 'fita helicoidal';
  group.add(ribbon);

  // Núcleo fino, para a fita não virar "fita solta no ar".
  const coreMat = shaderMaterial(`
    varying vec2 vUv;
    void main() { vUv = uv; gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0); }`, `
    varying vec2 vUv;
    uniform float uTime;
    void main() {
      float a = smoothstep(0.0, 0.25, vUv.y) * smoothstep(1.0, 0.75, vUv.y);
      float pulse = pow(0.5 + 0.5 * sin(vUv.y * 60.0 - uTime * 6.0), 6.0);
      gl_FragColor = vec4(vec3(0.6, 0.95, 1.0), a * (0.10 + pulse * 0.30));
    }`, { uTime: { value: 0 } });
  const core = new THREE.Mesh(new THREE.CylinderGeometry(0.035, 0.035, H, 12, 48, true), coreMat);
  core.position.y = H / 2;
  core.name = 'núcleo';
  group.add(core);

  return {
    group,
    duration: 5,
    update(t, dt) {
      mat.uniforms.uTime.value = t;
      coreMat.uniforms.uTime.value = t;
      ribbon.rotation.y = t * 0.18;
      core.rotation.y = t * 0.18;
    },
  };
}

// LIB-VFX-04 — HELIX CYLINDER -------------------------------------------------
export function createHelix(ctx) {
  const p = liveParams(ctx, FORM_DEFAULTS.helix);
  const group = new THREE.Group();
  const tubes = [];
  const H = p.height;
  const defs = [
    { r: p.radius, turns: p.turns, sign: 1, color: 0x55e6ff },
    { r: p.radius * 0.76, turns: p.turns * 0.75, sign: -1, color: 0xa88bff },
    { r: p.radius * 1.24, turns: p.turns * 1.25, sign: 1, color: 0xd8ff00 },
  ];
  for (const d of defs) {
    const pts = [];
    for (let i = 0; i <= 180; i++) {
      const u = i / 180;
      const a = u * TAU * d.turns * d.sign;
      pts.push(new THREE.Vector3(Math.cos(a) * d.r, u * H, Math.sin(a) * d.r));
    }
    const curve = new THREE.CatmullRomCurve3(pts);
    const geo = new THREE.TubeGeometry(curve, 260, p.thickness, 8, false);
    const mat = shaderMaterial(vShader, `
      varying vec2 vUv;
      uniform float uTime;
      uniform vec3 uColor;
      void main() {
        float band = pow(0.5 + 0.5 * sin(vUv.x * 90.0 - uTime * 8.0), 5.0);
        vec3 col = uColor + vec3(0.6, 0.9, 1.0) * band;
        gl_FragColor = vec4(col, 0.38 + band * 0.55);
      }`, { uTime: { value: 0 }, uColor: { value: new THREE.Color(d.color) } });
    const tube = new THREE.Mesh(geo, mat);
    tube.name = 'corrente helicoidal';
    group.add(tube);
    const halo = new THREE.Mesh(geo, new THREE.MeshBasicMaterial({ color: d.color, transparent: true, opacity: 0.07, blending: THREE.AdditiveBlending, depthWrite: false, side: THREE.DoubleSide }));
    halo.scale.setScalar(1.02);
    group.add(halo);
    tubes.push({ tube, mat });
  }

  const coreMat = shaderMaterial(vShader, `
    varying vec2 vUv;
    uniform float uTime;
    void main() {
      float edge = smoothstep(0.0, 0.35, vUv.x) * smoothstep(1.0, 0.65, vUv.x);
      float pulse = pow(0.5 + 0.5 * sin(vUv.y * 46.0 - uTime * 7.0), 5.0);
      gl_FragColor = vec4(vec3(0.65, 0.95, 1.0), (0.08 + pulse * 0.35) * edge);
    }`, { uTime: { value: 0 } });
  const core = new THREE.Mesh(new THREE.CylinderGeometry(0.055, 0.055, H, 16, 1, true), coreMat);
  core.position.y = H / 2;
  core.name = 'núcleo do feixe';
  group.add(core);

  const ring = ringMesh(p.radius * 1.12, p.radius * 1.2, COLORS.violet, 0.32);
  ring.position.y = 0.02;
  group.add(ring);

  return {
    group,
    duration: 4,
    update(t, dt) {
      group.rotation.y = t * 0.35 * p.speed;
      for (const x of tubes) x.mat.uniforms.uTime.value = t;
      coreMat.uniforms.uTime.value = t;
      ring.scale.setScalar(1 + Math.sin(t * 2.5) * 0.025);
    },
  };
}

// LIB-VFX-05 — SPIRAL EROSION / DISSOLVE -------------------------------------
export function createDissolve(ctx) {
  const p = liveParams(ctx, FORM_DEFAULTS.dissolve);
  const group = new THREE.Group();
  const mat = shaderMaterial(vShader, `
    varying vec2 vUv;
    varying vec3 vPos;
    uniform float uProgress;
    uniform float uTime;
    uniform float uEdge;
    uniform float uSpiral;
    uniform float uBright;
    float hash(vec3 p) {
      p = fract(p * 0.3183099 + 0.1);
      p *= 17.0;
      return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
    }
    float noise(vec3 x) {
      vec3 i = floor(x); vec3 f = fract(x);
      f = f * f * (3.0 - 2.0 * f);
      return mix(mix(mix(hash(i), hash(i + vec3(1,0,0)), f.x), mix(hash(i + vec3(0,1,0)), hash(i + vec3(1,1,0)), f.x), f.y),
                 mix(mix(hash(i + vec3(0,0,1)), hash(i + vec3(1,0,1)), f.x), mix(hash(i + vec3(0,1,1)), hash(i + vec3(1,1,1)), f.x), f.y), f.z);
    }
    void main() {
      float n = noise(vPos * 2.2 + vec3(0.0, uTime * 0.08, 0.0));
      float spiral = 0.5 + 0.5 * sin(atan(vPos.z, vPos.x) * 5.0 + vPos.y * 5.0);
      float field = mix(n, n * 0.55 + spiral * 0.45, uSpiral);
      float cut = uProgress * 1.18;
      float alive = smoothstep(cut, cut + 0.05, field);
      if (alive < 0.015) discard;
      float edge = 1.0 - smoothstep(cut, cut + uEdge, field);
      vec3 col = mix(vec3(0.20, 0.60, 1.0), vec3(1.0, 0.55, 0.18), edge);
      col += vec3(0.9, 0.95, 1.0) * edge * uBright;
      gl_FragColor = vec4(col, alive * 0.85);
    }`, { uProgress: { value: 0 }, uTime: { value: 0 }, uEdge: { value: p.edge }, uSpiral: { value: p.spiral }, uBright: { value: p.brightness } }, {
    side: THREE.DoubleSide,
    blending: THREE.NormalBlending,
  });
  const knot = new THREE.Mesh(new THREE.TorusKnotGeometry(1.05, 0.2, 220, 28, 2, 3), mat);
  knot.name = 'superfície';
  knot.position.y = 1.65;
  group.add(knot);
  const burst = makeBurst(260, ctx.soft, 0xffcf8a, 0.06, 0.75);
  burst.points.name = 'brasas';
  group.add(burst.points);
  let acc = 0;

  return {
    group,
    duration: 4.5,
    update(t, dt) {
      const prog = (t % 4.0) / 4.0;
      mat.uniforms.uProgress.value = prog;
      mat.uniforms.uTime.value = t;
      knot.rotation.y = t * 0.3;
      knot.rotation.x = Math.sin(t * 0.25) * 0.18;
      acc += dt;
      if (acc > 0.04) {
        acc = 0;
        burst.spawn(new THREE.Vector3((rand() - 0.5) * 2, 0.8 + rand() * 1.8, (rand() - 0.5) * 2), 3, 0.35, 1.2, 0.6, new THREE.Vector3(0, 0.5, 0), 0.8);
      }
      burst.update(dt, -0.5);
    },
  };
}
