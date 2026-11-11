import * as THREE from 'three';
import {
  TAU, clamp, lerp, easeOutCubic, hash, softTexture,
  funnelGeometry, ribbonGeometry, ringMesh, glowSprite, shaderMaterial,
  makePoints, makeBurst, stageRoot, coneMaterial, COLORS,
} from '../helpers.js';

const vShader = `
varying vec2 vUv;
varying vec3 vPos;
void main() {
  vUv = uv;
  vPos = position;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}`;

// 1. VORTEX MESH -------------------------------------------------------------
// Funil de sucção: estreito no chão, largo na boca. As bandas helicoidais são
// o que dá leitura da forma; o miolo fica vazado de propósito.
export function createVortex(ctx) {
  const group = new THREE.Group();

  const shell = (dir, radius, top, height, twist, colorA, colorB, alpha) => {
    const mat = shaderMaterial(vShader, `
      varying vec2 vUv;
      uniform float uTime;
      void main() {
        float a = vUv.x * 6.28318;
        float s = sin(a * 3.0 ${dir > 0 ? '-' : '+'} vUv.y * 24.0 + uTime * ${dir > 0 ? '4.0' : '5.5'});
        float band = smoothstep(0.35, 1.0, s);
        float streak = pow(0.5 + 0.5 * sin(a * 12.0 ${dir > 0 ? '-' : '+'} vUv.y * 58.0 + uTime * 8.0), 7.0);
        float vFade = smoothstep(0.0, 0.10, vUv.y) * smoothstep(1.0, 0.78, vUv.y);
        float hollow = smoothstep(0.0, 0.42, vUv.y);
        vec3 col = mix(vec3(${colorA}), vec3(${colorB}), vUv.y);
        col += vec3(0.75, 0.95, 1.0) * band * 0.5;
        float alpha = (band * 0.20 + streak * 0.55) * vFade;
        alpha *= mix(1.0, hollow, 0.55);
        gl_FragColor = vec4(col, alpha * ${alpha.toFixed(2)});
      }`, { uTime: { value: 0 } });
    mat.side = THREE.FrontSide;
    const mesh = new THREE.Mesh(funnelGeometry({ height, radius, top, twist, segments: 168, rings: 72 }), mat);
    group.add(mesh);
    return { mesh, mat };
  };

  const outer = shell(1, 0.16, 2.15, 3.3, 8.0, '0.12, 0.68, 1.0', '0.58, 0.38, 1.0', 1.0);
  const inner = shell(-1, 0.40, 1.55, 2.9, -12.0, '0.30, 0.90, 1.0', '0.85, 0.55, 1.0', 0.55);

  // Disco espiral no chão: a "boca" que suga.
  const discMat = shaderMaterial(vShader, `
    varying vec2 vUv;
    uniform float uTime;
    void main() {
      vec2 p = vUv - 0.5;
      float r = length(p) * 2.0;
      float a = atan(p.y, p.x);
      float spiral = 0.5 + 0.5 * sin(a * 4.0 + log(max(r, 0.02)) * 14.0 - uTime * 5.0);
      float arms = pow(spiral, 6.0);
      float rim = smoothstep(1.0, 0.86, r) * smoothstep(0.06, 0.34, r);
      float alpha = arms * rim * 0.55;
      vec3 col = mix(vec3(0.45, 0.92, 1.0), vec3(0.55, 0.40, 1.0), r);
      gl_FragColor = vec4(col, alpha);
    }`, { uTime: { value: 0 } });
  const disc = new THREE.Mesh(new THREE.PlaneGeometry(4.6, 4.6), discMat);
  disc.rotation.x = -Math.PI / 2;
  disc.position.y = 0.02;
  group.add(disc);

  const ground = ringMesh(2.0, 2.08, COLORS.cyan, 0.28);
  ground.position.y = 0.03;
  group.add(ground);

  const count = 640;
  const pts = makePoints(count, ctx.soft, 0x9fe4ff, 0.055, 0.9);
  const pos = pts.geometry.attributes.position.array;
  const angles = new Float32Array(count);
  const u = new Float32Array(count);
  const speeds = new Float32Array(count);
  const radii = new Float32Array(count);
  for (let i = 0; i < count; i++) {
    angles[i] = Math.random() * TAU;
    u[i] = Math.random();
    speeds[i] = 0.4 + Math.random() * 0.9;
    radii[i] = 0.16 + u[i] * 1.9;
  }
  group.add(pts);

  return {
    group,
    duration: 6,
    update(t, dt) {
      outer.mat.uniforms.uTime.value = t;
      inner.mat.uniforms.uTime.value = t;
      discMat.uniforms.uTime.value = t;
      outer.mesh.rotation.y = t * 0.16;
      inner.mesh.rotation.y = -t * 0.30;
      disc.rotation.z = -t * 0.55;
      ground.scale.setScalar(1 + Math.sin(t * 2.0) * 0.02);
      for (let i = 0; i < count; i++) {
        u[i] += dt * (0.16 + speeds[i] * 0.22);
        if (u[i] > 1) { u[i] = 0; angles[i] = Math.random() * TAU; }
        const v = u[i];
        radii[i] = 0.16 + v * 2.0;
        const r = radii[i];
        const lift = (v * v * 3.0) * (0.75 + speeds[i] * 0.25);
        const a = angles[i] + v * 7.0 + t * (0.35 + speeds[i] * 0.3);
        pos[i * 3] = Math.cos(a) * r;
        pos[i * 3 + 1] = 0.05 + lift;
        pos[i * 3 + 2] = Math.sin(a) * r;
      }
      pts.geometry.attributes.position.needsUpdate = true;
    },
  };
}

// 2. TORNADO / FUNNEL ---------------------------------------------------------
export function createFunnel(ctx) {
  const group = new THREE.Group();
  const layers = [];
  const defs = [
    { h: 4.6, r: 0.22, top: 2.3, twist: 10, color: [0.3, 0.85, 1.0], speed: 0.25 },
    { h: 4.2, r: 0.16, top: 1.65, twist: -14, color: [0.7, 0.4, 1.0], speed: -0.35 },
    { h: 3.8, r: 0.12, top: 1.05, twist: 18, color: [0.9, 0.95, 1.0], speed: 0.5 },
  ];
  for (const d of defs) {
    const mat = shaderMaterial(vShader, `
      varying vec2 vUv;
      uniform float uTime;
      uniform vec3 uColor;
      void main() {
        float a = vUv.x * 6.28318;
        float s = sin(a * 2.0 + vUv.y * 36.0 - uTime * 4.0);
        float b = smoothstep(0.2, 1.0, s);
        float fade = smoothstep(0.0, 0.1, vUv.y) * smoothstep(1.0, 0.75, vUv.y);
        gl_FragColor = vec4(uColor, b * fade * 0.42);
      }`, { uTime: { value: 0 }, uColor: { value: new THREE.Color(...d.color) } });
    const mesh = new THREE.Mesh(funnelGeometry({ height: d.h, radius: d.r, top: d.top, twist: d.twist, segments: 120, rings: 52 }), mat);
    group.add(mesh);
    layers.push({ mesh, mat, speed: d.speed });
  }

  const ground = ringMesh(2.30, 2.52, COLORS.cyan, 0.30);
  ground.position.y = 0.025;
  group.add(ground);
  const burst = makeBurst(220, ctx.soft, 0xccefff, 0.09, 0.45, false);
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
      ground.scale.setScalar(1 + Math.sin(t * 1.7) * 0.04);
      acc += dt;
      if (acc > 0.05) {
        acc = 0;
        const a = Math.random() * TAU;
        const r = 1.6 + Math.random() * 0.9;
        burst.spawn(new THREE.Vector3(Math.cos(a) * r, 0.05, Math.sin(a) * r), 4, 0.3, 1.3, 0.7, new THREE.Vector3(-Math.cos(a), 0.4, -Math.sin(a)), 0.4);
      }
      burst.update(dt, 0.4);
    },
  };
}

// 3. RIBBON / TRAIL -----------------------------------------------------------
export function createRibbon(ctx) {
  const group = new THREE.Group();
  const orb = new THREE.Mesh(new THREE.SphereGeometry(0.16, 24, 16), new THREE.MeshBasicMaterial({ color: 0xfff2c2 }));
  const halo = glowSprite(0x8fe8ff, 1.6, 0.8, ctx.soft);
  halo.position.copy(orb.position);
  group.add(orb, halo);

  const history = [];
  const max = 84;
  for (let i = 0; i < max; i++) history.push(new THREE.Vector3(0, 1.4, 0));
  let ribbon = null;
  let ribbonMat = shaderMaterial(vShader, `
    varying vec2 vUv;
    uniform float uTime;
    void main() {
      float core = smoothstep(0.55, 0.0, abs(vUv.y - 0.5) * 2.0);
      float head = smoothstep(0.0, 0.2, vUv.x);
      float tail = smoothstep(1.0, 0.55, vUv.x);
      vec3 col = mix(vec3(0.25, 0.8, 1.0), vec3(0.9, 0.5, 1.0), vUv.x);
      col += vec3(0.35, 0.9, 1.0) * core;
      gl_FragColor = vec4(col, core * head * tail * 0.85);
    }`, { uTime: { value: 0 } });

  function rebuild() {
    if (ribbon) {
      group.remove(ribbon);
      ribbon.geometry.dispose();
    }
    const widths = history.map((_, i) => 0.22 * (0.2 + 0.8 * Math.pow(i / (max - 1), 0.5)));
    ribbon = new THREE.Mesh(ribbonGeometry(history, widths), ribbonMat);
    group.add(ribbon);
  }

  return {
    group,
    duration: 5,
    update(t, dt) {
      const a = t * 1.15;
      const r = 2.15;
      orb.position.set(Math.cos(a) * r, 1.45 + Math.sin(a * 2.0) * 0.35, Math.sin(a) * r - 0.4);
      halo.position.copy(orb.position);
      history.shift();
      history.push(orb.position.clone());
      rebuild();
      ribbonMat.uniforms.uTime.value = t;
    },
  };
}

// 4. HELIX CYLINDER -----------------------------------------------------------
export function createHelix(ctx) {
  const group = new THREE.Group();
  const tubes = [];
  const defs = [
    { r: 0.95, turns: 3.2, sign: 1, color: 0x55e6ff },
    { r: 0.72, turns: 2.4, sign: -1, color: 0xa88bff },
    { r: 1.18, turns: 4.0, sign: 1, color: 0xd8ff00 },
  ];
  for (const d of defs) {
    const pts = [];
    for (let i = 0; i <= 160; i++) {
      const u = i / 160;
      const a = u * TAU * d.turns * d.sign;
      pts.push(new THREE.Vector3(Math.cos(a) * d.r, u * 4.2, Math.sin(a) * d.r));
    }
    const curve = new THREE.CatmullRomCurve3(pts);
    const geo = new THREE.TubeGeometry(curve, 220, 0.028, 8, false);
    const mat = shaderMaterial(vShader, `
      varying vec2 vUv;
      uniform float uTime;
      uniform vec3 uColor;
      void main() {
        float pulse = smoothstep(0.0, 0.08, abs(fract(vUv.x - uTime * 0.18) - 0.5) < 0.5 ? 1.0 : 0.0);
        float band = pow(0.5 + 0.5 * sin(vUv.x * 90.0 - uTime * 8.0), 5.0);
        vec3 col = uColor + vec3(0.6, 0.9, 1.0) * band;
        gl_FragColor = vec4(col, 0.42 + band * 0.55);
      }`, { uTime: { value: 0 }, uColor: { value: new THREE.Color(d.color) } });
    const tube = new THREE.Mesh(geo, mat);
    group.add(tube);
    const halo = new THREE.Mesh(geo, new THREE.MeshBasicMaterial({ color: d.color, transparent: true, opacity: 0.08, blending: THREE.AdditiveBlending, depthWrite: false, side: THREE.DoubleSide }));
    halo.scale.setScalar(1.012);
    group.add(halo);
    tubes.push({ tube, mat });
  }
  const ring = ringMesh(1.4, 1.55, COLORS.violet, 0.35);
  ring.position.y = 0.02;
  group.add(ring);

  return {
    group,
    duration: 4,
    update(t, dt) {
      group.rotation.y = t * 0.35;
      for (const x of tubes) x.mat.uniforms.uTime.value = t;
      ring.scale.setScalar(1 + Math.sin(t * 2.5) * 0.025);
    },
  };
}

// 5. EROSION / DISSOLVE SPIRAL ------------------------------------------------
export function createDissolve(ctx) {
  const group = new THREE.Group();
  const mat = shaderMaterial(vShader, `
    varying vec2 vUv;
    varying vec3 vPos;
    uniform float uProgress;
    uniform float uTime;
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
      float field = n * 0.7 + spiral * 0.3;
      float cut = uProgress * 1.25;
      float alive = smoothstep(cut, cut + 0.06, field);
      if (alive < 0.015) discard;
      float edge = 1.0 - smoothstep(cut, cut + 0.16, field);
      vec3 col = mix(vec3(0.25, 0.65, 1.0), vec3(1.0, 0.55, 0.18), edge);
      col += vec3(0.9, 0.95, 1.0) * edge * 1.5;
      gl_FragColor = vec4(col, alive * 0.85);
    }`, { uProgress: { value: 0 }, uTime: { value: 0 } });
  const knot = new THREE.Mesh(new THREE.TorusKnotGeometry(1.05, 0.2, 220, 28, 2, 3), mat);
  knot.position.y = 1.65;
  group.add(knot);
  const burst = makeBurst(260, ctx.soft, 0xffcf8a, 0.06, 0.8);
  group.add(burst.points);
  let acc = 0;

  return {
    group,
    duration: 4.5,
    update(t, dt) {
      const p = (t % 4.0) / 4.0;
      mat.uniforms.uProgress.value = p;
      mat.uniforms.uTime.value = t;
      knot.rotation.y = t * 0.3;
      knot.rotation.x = Math.sin(t * 0.25) * 0.18;
      acc += dt;
      if (acc > 0.04) {
        acc = 0;
        burst.spawn(new THREE.Vector3((Math.random() - 0.5) * 2, 0.8 + Math.random() * 1.8, (Math.random() - 0.5) * 2), 3, 0.35, 1.2, 0.6, new THREE.Vector3(0, 0.5, 0), 0.8);
      }
      burst.update(dt, -0.5);
    },
  };
}

// 6. IMPACT CROWN -------------------------------------------------------------
export function createCrown(ctx) {
  const group = new THREE.Group();
  const count = 30;
  const spikeGeo = new THREE.ConeGeometry(0.12, 1.0, 5, 1);
  spikeGeo.translate(0, 0.5, 0);
  const mat = new THREE.MeshBasicMaterial({ color: COLORS.amber, transparent: true, opacity: 0.9, blending: THREE.AdditiveBlending, depthWrite: false, side: THREE.DoubleSide });
  const spikes = new THREE.InstancedMesh(spikeGeo, mat, count);
  group.add(spikes);
  const ring = ringMesh(1.0, 1.12, COLORS.coral, 0.8);
  ring.position.y = 0.02;
  group.add(ring);
  const flash = glowSprite(0xfff0c0, 3.2, 0.9, ctx.soft);
  flash.position.y = 0.7;
  group.add(flash);
  const burst = makeBurst(160, ctx.soft, 0xffc46a, 0.07, 0.9);
  group.add(burst.points);
  const dummy = new THREE.Object3D();

  return {
    group,
    duration: 1.8,
    update(t, dt) {
      const k = easeOutCubic(t / 0.55);
      const fade = 1 - smoothstep(t, 1.25, 1.8);
      ring.scale.setScalar(0.3 + k * 2.4);
      ring.material.opacity = 0.7 * fade;
      flash.scale.setScalar(1.2 + k * 2.2);
      flash.material.opacity = 0.7 * fade;
      mat.opacity = 0.9 * fade;
      for (let i = 0; i < count; i++) {
        const a = (i / count) * TAU;
        const r = 0.65 + 0.55 * k;
        const h = 0.2 + 1.35 * k * (0.7 + hash(i) * 0.3);
        dummy.position.set(Math.cos(a) * r, 0.02, Math.sin(a) * r);
        dummy.rotation.set(0, -a + Math.PI / 2, 0.4 + hash(i + 2) * 0.3);
        dummy.scale.set(0.7 + hash(i + 5) * 0.7, h, 0.7 + hash(i + 7) * 0.7);
        dummy.updateMatrix();
        spikes.setMatrixAt(i, dummy.matrix);
      }
      spikes.instanceMatrix.needsUpdate = true;
      if (t < 0.1) burst.spawn(new THREE.Vector3(0, 0.2, 0), 40, 4.5, 1.0, 1.0, new THREE.Vector3(0, 0.5, 0), 0.4);
      burst.update(dt, -5.5);
    },
  };
}

function smoothstep(x, a, b) {
  const t = clamp((x - a) / (b - a), 0, 1);
  return t * t * (3 - 2 * t);
}

// 7. SHOCKWAVE RING / TORUS ---------------------------------------------------
export function createShockwave(ctx) {
  const group = new THREE.Group();
  const rings = [];
  for (let i = 0; i < 3; i++) {
    const r = ringMesh(0.82, 1.0, i === 0 ? 0xfff2c2 : (i === 1 ? COLORS.cyan : COLORS.violet), 0.8);
    r.position.y = 0.025 + i * 0.006;
    group.add(r);
    rings.push({ mesh: r, delay: i * 0.12 });
  }
  const flash = glowSprite(0xfff2c2, 2.6, 0.9, ctx.soft);
  flash.position.y = 0.6;
  group.add(flash);
  const burst = makeBurst(220, ctx.soft, 0xffd08a, 0.06, 0.9);
  group.add(burst.points);

  return {
    group,
    duration: 2.2,
    update(t, dt) {
      for (const r of rings) {
        const k = clamp((t - r.delay) / 1.4, 0, 1);
        const e = easeOutCubic(k);
        r.mesh.scale.setScalar(0.25 + e * 4.6);
        r.mesh.material.opacity = 0.8 * (1 - k) * (1 - k);
      }
      flash.scale.setScalar(1.2 + easeOutCubic(t / 0.25) * 2.4);
      flash.material.opacity = Math.max(0, 0.8 - t * 0.7);
      if (t < 0.08) burst.spawn(new THREE.Vector3(0, 0.2, 0), 60, 6.0, 0.8, 1.0, new THREE.Vector3(0, 0.4, 0), 0.3);
      burst.update(dt, -7.0);
    },
  };
}

// 8. BLAST CONE / IMPACT FUNNEL ----------------------------------------------
export function createBlastCone(ctx) {
  ctx.target.visible = true;
  const group = stageRoot(ctx.stage);
  const dist = ctx.stage.dist;
  const mat = coneMaterial(0xff6a08, 0xfff2c0, 11);
  const cone = new THREE.Mesh(new THREE.CylinderGeometry(0.06, 1.55, 3.4, 48, 18, true), mat);
  cone.rotation.x = Math.PI / 2;
  cone.position.set(0, 1.25, -dist - 1.7);
  group.add(cone);
  const ring = ringMesh(0.35, 0.55, COLORS.amber, 0.8);
  ring.position.set(0, 0.03, -dist);
  group.add(ring);
  const flash = glowSprite(0xffe0a0, 2.2, 0.9, ctx.soft);
  flash.position.set(0, 1.3, -dist);
  group.add(flash);
  const burst = makeBurst(260, ctx.soft, 0xffc46a, 0.07, 0.9);
  group.add(burst.points);

  return {
    group,
    duration: 1.8,
    update(t, dt) {
      const e = easeOutCubic(t / 0.55);
      mat.uniforms.uTime.value = t;
      mat.uniforms.uProgress.value = clamp(t / 0.2, 0, 1) * (1 - smoothstep(t, 1.0, 1.8));
      cone.scale.set(0.2 + e * 1.0, 0.2 + e * 1.0, 0.2 + e * 1.0);
      ring.scale.setScalar(0.2 + e * 4.2);
      ring.material.opacity = 0.8 * (1 - clamp(t / 1.8, 0, 1));
      flash.scale.setScalar(0.8 + e * 2.0);
      flash.material.opacity = Math.max(0, 0.8 - t * 0.6);
      if (t < 0.08) burst.spawn(new THREE.Vector3(0, 1.2, -dist), 80, 7.0, 0.9, 1.0, new THREE.Vector3(0, 0.2, -1), 0.5);
      burst.update(dt, -4.0);
    },
  };
}

// 9. GROUND FRACTURE ----------------------------------------------------------
export function createFracture(ctx) {
  const group = new THREE.Group();
  const mat = shaderMaterial(vShader, `
    varying vec2 vUv;
    uniform float uProgress;
    uniform float uTime;
    void main() {
      vec2 p = vUv - 0.5;
      float r = length(p) * 2.0;
      float a = atan(p.y, p.x);
      float crack = smoothstep(0.94, 1.0, sin(a * 17.0 + 3.0 * sin(r * 14.0) + uTime * 0.2));
      float web = smoothstep(0.9, 1.0, sin(a * 31.0 - 5.0 * sin(r * 9.0)));
      float front = uProgress * 1.2;
      float reveal = 1.0 - smoothstep(front - 0.2, front, r);
      float edge = smoothstep(front - 0.32, front - 0.12, r) * (1.0 - smoothstep(front - 0.12, front, r));
      float alpha = (crack * 0.85 + web * 0.3) * reveal * smoothstep(1.0, 0.75, r);
      vec3 col = mix(vec3(0.1, 0.4, 0.9), vec3(1.0, 0.5, 0.12), crack);
      col += vec3(0.7, 0.9, 1.0) * edge * 0.8;
      gl_FragColor = vec4(col, alpha);
    }`, { uProgress: { value: 0 }, uTime: { value: 0 } });
  const floor = new THREE.Mesh(new THREE.PlaneGeometry(7.5, 7.5), mat);
  floor.rotation.x = -Math.PI / 2;
  floor.position.y = 0.018;
  group.add(floor);
  const rockGeo = new THREE.DodecahedronGeometry(0.13, 0);
  const rockMat = new THREE.MeshStandardMaterial({ color: 0x6b5a4a, roughness: 0.9, metalness: 0.05 });
  const rocks = new THREE.InstancedMesh(rockGeo, rockMat, 24);
  group.add(rocks);
  const dummy = new THREE.Object3D();
  const burst = makeBurst(180, ctx.soft, 0xb8a68a, 0.08, 0.5, false);
  group.add(burst.points);

  return {
    group,
    duration: 2.6,
    update(t, dt) {
      const p = clamp(t / 0.65, 0, 1);
      mat.uniforms.uProgress.value = p;
      mat.uniforms.uTime.value = t;
      for (let i = 0; i < 24; i++) {
        const a = hash(i) * TAU;
        const r = 1.0 + hash(i + 9) * 2.6;
        const up = Math.max(0, Math.sin((t - 0.1) * 3.0 + hash(i + 3) * 2.0)) * (0.3 + hash(i + 7) * 0.9);
        dummy.position.set(Math.cos(a) * r, 0.05 + up, Math.sin(a) * r);
        dummy.rotation.set(t * (0.4 + hash(i + 5)), t * 0.8, t * 0.3);
        const s = 0.5 + hash(i + 11) * 0.8;
        dummy.scale.set(s, s, s);
        dummy.updateMatrix();
        rocks.setMatrixAt(i, dummy.matrix);
      }
      rocks.instanceMatrix.needsUpdate = true;
      if (t < 0.12) burst.spawn(new THREE.Vector3(0, 0.1, 0), 50, 2.8, 1.0, 1.0, new THREE.Vector3(0, 0.3, 0), 1.2);
      burst.update(dt, -3.0);
    },
  };
}
