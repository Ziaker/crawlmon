import * as THREE from 'three';
import {
  TAU, clamp, lerp, easeOutCubic, rand, randRange,
  ribbonGeometry, ringMesh, glowSprite, shaderMaterial,
  makeBurst, stageRoot, liveParams, placeDummy, coneMaterial, COLORS,
} from '../helpers.js';

const vShader = `varying vec2 vUv;
void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}`;

export const MOTION_DEFAULTS = {
  thrust: { length: 2.4, opening: 1.05, intensity: 1.0 },
  speedlines: { count: 70, length: 1.0, speed: 14 },
  motiontrail: { width: 0.55, persist: 120 },
  aura: { radius: 2.6, height: 1.8, count: 90 },
  dust: { size: 0.8, density: 1.0, rise: 0.3 },
  scuff: { spread: 0.6, power: 4.0, size: 0.55 },
  scratch: { length: 6.0, width: 1.0, rocks: 18 },
};

function travel(stage, t, duration) {
  return (stage.dist - 1.25) * easeOutCubic(clamp(t / duration, 0, 1));
}

// LIB-VFX-06 — THRUST CONE ----------------------------------------------------
export function createThrust(ctx) {
  const p = liveParams(ctx, MOTION_DEFAULTS.thrust);
  const group = stageRoot(ctx.stage);
  const mat = coneMaterial(0x2bb8ff, 0xeaffff, 15);
  const cone = new THREE.Mesh(new THREE.CylinderGeometry(0.04, p.opening, p.length, 44, 16, true), mat);
  cone.name = 'cone de propulsão';
  cone.rotation.x = -Math.PI / 2;
  group.add(cone);

  const ring = ringMesh(p.opening * 0.86, p.opening, COLORS.cyan, 0.55);
  ring.name = 'bocal';
  group.add(ring);
  const nozzle = glowSprite(0xbfefff, 1.3, 0.75, ctx.soft);
  nozzle.name = 'brilho do bocal';
  group.add(nozzle);

  const trail = makeBurst(160, ctx.soft, 0xbfefff, 0.06, 0.55, true);
  trail.points.name = 'rastro';
  group.add(trail.points);
  let acc = 0;

  return {
    group,
    duration: 2.8,
    update(t, dt) {
      const d = travel(ctx.stage, t, 2.4);
      placeDummy(ctx, d);
      const z = -d;
      cone.position.set(0, 1.05, z + p.length * 0.5 + 0.05);
      ring.position.set(0, 0.02, z + p.length + 0.1);
      ring.rotation.x = -Math.PI / 2;
      ring.scale.setScalar(0.9 + Math.sin(t * 18.0) * 0.05);
      nozzle.position.set(0, 1.05, z + 0.1);
      nozzle.scale.setScalar(0.9 + Math.sin(t * 21.0) * 0.06);
      mat.uniforms.uTime.value = t;
      mat.uniforms.uProgress.value = 0.55 + p.intensity * 0.6;
      acc += dt;
      if (acc > 0.035) {
        acc = 0;
        trail.spawn(new THREE.Vector3((rand() - 0.5) * 0.5, 0.05 + rand() * 0.3, z + p.length * 0.8), 3, 0.4, 0.8, 0.6, new THREE.Vector3(0, 0.2, 1), 0.3);
      }
      trail.update(dt, 0.8);
    },
  };
}

// LIB-VFX-07 — SPEED LINES ----------------------------------------------------
export function createSpeedLines(ctx) {
  const p = liveParams(ctx, MOTION_DEFAULTS.speedlines);
  const group = stageRoot(ctx.stage);
  const count = p.count;
  const geo = new THREE.BoxGeometry(0.022, 0.022, 1);
  const mat = new THREE.MeshBasicMaterial({
    color: 0xcfeeff, transparent: true, opacity: 0.30,
    blending: THREE.AdditiveBlending, depthWrite: false,
  });
  const lines = new THREE.InstancedMesh(geo, mat, count);
  lines.name = 'linhas de ação';
  group.add(lines);

  const data = [];
  for (let i = 0; i < count; i++) {
    const a = rand() * TAU;
    const r = 0.55 + rand() * 1.05;
    data.push({
      a, r,
      y: -0.9 + rand() * 1.8,
      zRel: rand() * 4.2 - 2.0,
      len: p.length * (0.9 + rand() * 1.3),
      speed: 5 + rand() * p.speed,
    });
  }
  const helper = new THREE.Object3D();
  const burst = makeBurst(90, ctx.soft, 0xbfefff, 0.05, 0.45, true);
  group.add(burst.points);
  let acc = 0;

  return {
    group,
    duration: 3.0,
    update(t, dt) {
      const d = travel(ctx.stage, t, 2.6);
      placeDummy(ctx, d);
      for (let i = 0; i < count; i++) {
        const s = data[i];
        s.zRel += dt * s.speed;
        if (s.zRel > 2.2) {
          s.zRel = -2.0;
          s.a = rand() * TAU;
          s.r = 0.55 + rand() * 1.05;
          s.y = -0.9 + rand() * 1.8;
          s.len = p.length * (0.9 + rand() * 1.3);
        }
        const x = Math.cos(s.a) * s.r;
        const yy = 1.2 + Math.sin(s.a) * s.r * 0.45 + s.y * 0.5;
        helper.position.set(x, yy, -d + s.zRel);
        helper.rotation.set(0, 0, 0);
        helper.scale.set(1, 1, s.len);
        helper.updateMatrix();
        lines.setMatrixAt(i, helper.matrix);
      }
      lines.instanceMatrix.needsUpdate = true;
      acc += dt;
      if (acc > 0.05) {
        acc = 0;
        burst.spawn(new THREE.Vector3(0, 0.15, -d + 0.8), 2, 0.35, 0.7, 0.4, new THREE.Vector3(0, 0.25, 1), 0.5);
      }
      burst.update(dt, 0.4);
    },
  };
}

// LIB-VFX-08 — MOTION TRAIL ---------------------------------------------------
export function createMotionTrail(ctx) {
  const p = liveParams(ctx, MOTION_DEFAULTS.motiontrail);
  const group = stageRoot(ctx.stage);
  const max = p.persist;
  const history = [];
  for (let i = 0; i < max; i++) history.push(new THREE.Vector3(0, 1.0, 0));
  const mat = shaderMaterial(vShader, `
    varying vec2 vUv;
    uniform float uTime;
    uniform float uTaper;
    void main() {
      float core = smoothstep(0.5, 0.0, abs(vUv.y - 0.5) * 2.0);
      float body = smoothstep(0.0, 0.32, vUv.x) * (1.0 - smoothstep(0.94, 1.0, vUv.x));
      float flow = pow(0.5 + 0.5 * sin(vUv.x * 40.0 - uTime * 7.0), 6.0);
      vec3 col = mix(vec3(0.3, 0.85, 1.0), vec3(1.0, 0.85, 0.35), vUv.x);
      gl_FragColor = vec4(col + flow * 0.5, core * body * 0.9);
    }`, { uTime: { value: 0 }, uTaper: { value: 0.5 } });
  let ribbon = null;
  function rebuild() {
    if (ribbon) { group.remove(ribbon); ribbon.geometry.dispose(); }
    const widths = history.map((_, i) => p.width * (0.10 + 0.90 * Math.pow(i / (max - 1), 0.6)));
    ribbon = new THREE.Mesh(ribbonGeometry(history, widths, new THREE.Vector3(1, 0, 0)), mat);
    ribbon.name = 'rastro';
    group.add(ribbon);
  }
  const glow = glowSprite(0xffd27a, 0.8, 0.5, ctx.soft);
  group.add(glow);

  return {
    group,
    duration: 3.4,
    update(t, dt) {
      const d = travel(ctx.stage, t, 3.0);
      placeDummy(ctx, d);
      const z = -d;
      const x = Math.sin((d / Math.max(ctx.stage.dist, 0.001)) * Math.PI * 2.0) * 0.55;
      glow.position.set(x, 1.05, z - 0.2);
      glow.scale.setScalar(0.8 + Math.sin(t * 16.0) * 0.1);
      history.shift();
      history.push(new THREE.Vector3(x, 1.05, z - 0.2));
      if (!ctx.fast) rebuild();
      mat.uniforms.uTime.value = t;
    },
  };
}

// LIB-VFX-09 — AURA BURST -----------------------------------------------------
export function createAura(ctx) {
  const p = liveParams(ctx, MOTION_DEFAULTS.aura);
  const group = stageRoot(ctx.stage);
  const count = p.count;
  const geo = new THREE.BoxGeometry(0.05, 0.05, 1);
  const mat = new THREE.MeshBasicMaterial({ color: 0x9df0ff, transparent: true, opacity: 0.85, blending: THREE.AdditiveBlending, depthWrite: false });
  const streaks = new THREE.InstancedMesh(geo, mat, count);
  streaks.name = 'descarga radial';
  group.add(streaks);

  const data = [];
  for (let i = 0; i < count; i++) {
    data.push({
      a: (i / count) * TAU + rand() * 0.12,
      e: 0.15 + rand() * 0.85,
      len: 0.5 + rand() * 0.7,
      sp: 0.7 + rand() * 0.6,
    });
  }
  const helper = new THREE.Object3D();
  const dir = new THREE.Vector3();
  const ring = ringMesh(0.2, 0.3, COLORS.cyan, 0.85);
  ring.position.y = 0.02;
  group.add(ring);
  const flash = glowSprite(0xbfefff, 2.0, 0.65, ctx.soft);
  flash.name = 'clarão';
  flash.position.y = 0.45;
  group.add(flash);
  let did = false;

  return {
    group,
    duration: 1.6,
    update(t, dt) {
      placeDummy(ctx, 0);
      if (!did) did = true;
      const e = easeOutCubic(t / 0.42);
      const fade = 1 - clamp((t - 0.25) / 1.2, 0, 1);
      for (let i = 0; i < count; i++) {
        const s = data[i];
        const dist = 0.2 + e * p.radius * s.sp;
        const h = 0.15 + e * p.height * s.e;
        dir.set(Math.cos(s.a), s.e * 1.4, Math.sin(s.a)).normalize();
        helper.position.set(Math.cos(s.a) * dist * 0.55, h * 0.5, Math.sin(s.a) * dist * 0.55);
        helper.quaternion.setFromUnitVectors(new THREE.Vector3(0, 0, 1), dir);
        helper.scale.set(1, 1, s.len * (0.5 + e * 1.6));
        helper.updateMatrix();
        streaks.setMatrixAt(i, helper.matrix);
      }
      streaks.instanceMatrix.needsUpdate = true;
      mat.opacity = 0.85 * fade;
      ring.scale.setScalar(0.2 + e * p.radius * 1.6);
      ring.material.opacity = 0.85 * fade;
      flash.scale.setScalar(0.8 + e * 2.4);
      flash.material.opacity = Math.max(0, 0.65 - t * 0.5);
    },
  };
}

// LIB-VFX-10 — DUST TRAIL -----------------------------------------------------
export function createDustTrail(ctx) {
  const p = liveParams(ctx, MOTION_DEFAULTS.dust);
  const group = stageRoot(ctx.stage);
  const dust = makeBurst(340, ctx.soft, 0xcdbfa8, p.size, 0.52, false);
  dust.points.name = 'poeira';
  group.add(dust.points);
  const ring = ringMesh(0.2, 0.8, 0xd8c7a8, 0.22, 64);
  ring.position.y = 0.02;
  group.add(ring);
  let acc = 0;

  return {
    group,
    duration: 3.2,
    update(t, dt) {
      const d = travel(ctx.stage, t, 3.0);
      placeDummy(ctx, d);
      acc += dt;
      if (acc > 0.038 / p.density) {
        acc = 0;
        dust.spawn(
          new THREE.Vector3((rand() - 0.5) * 0.65, 0.08 + rand() * 0.25, -d + 0.5 + (rand() - 0.5) * 0.45),
          Math.round(6 * p.density), 0.8, 1.2, 0.9,
          new THREE.Vector3(0, 0.15 + p.rise, 1), 0.45
        );
      }
      dust.update(dt, 0.6 - p.rise * 0.4);
      ring.position.z = -d + 0.8;
      ring.rotation.x = -Math.PI / 2;
      ring.scale.setScalar(0.9 + Math.sin(t * 8.0) * 0.07);
    },
  };
}

// LIB-VFX-11 — BRAKE / SCUFF DUST --------------------------------------------
export function createScuff(ctx) {
  const p = liveParams(ctx, MOTION_DEFAULTS.scuff);
  const group = stageRoot(ctx.stage);
  const dust = makeBurst(340, ctx.soft, 0xd6c3a6, p.size, 0.42, false);
  dust.points.name = 'poeira de frenagem';
  group.add(dust.points);

  const fan = shaderMaterial(vShader, `
    varying vec2 vUv;
    uniform float uProgress;
    uniform float uSpread;
    void main() {
      float cone = smoothstep(0.5, 0.0, abs(vUv.x - 0.5) * 2.0 - vUv.y * uSpread);
      float fade = smoothstep(1.0, 0.0, vUv.y) * smoothstep(0.0, 0.15, vUv.y);
      gl_FragColor = vec4(0.82, 0.75, 0.62, cone * fade * uProgress * 0.85);
    }`, { uProgress: { value: 0 }, uSpread: { value: p.spread } });
  const fanMesh = new THREE.Mesh(new THREE.PlaneGeometry(3.4, 2.6), fan);
  fanMesh.name = 'leque de poeira';
  fanMesh.rotation.x = -Math.PI / 2;
  fanMesh.position.set(0, 0.02, -1.7);
  group.add(fanMesh);
  let did = false;

  return {
    group,
    duration: 2.2,
    update(t, dt) {
      const d = travel(ctx.stage, t, 0.7);
      placeDummy(ctx, d);
      if (!did) {
        did = true;
        dust.spawn(new THREE.Vector3(0, 0.12, -d + 0.5), 140, p.power, 1.2, 1.0, new THREE.Vector3(0, 0.15, 1), 0.45);
      }
      dust.update(dt, -2.0);
      fan.uniforms.uProgress.value = clamp(t / 0.25, 0, 1) * (1 - clamp(t / 2.2, 0, 1));
    },
  };
}

// LIB-VFX-12 — GROUND SCRATCH -------------------------------------------------
export function createGroundScratch(ctx) {
  const p = liveParams(ctx, MOTION_DEFAULTS.scratch);
  const group = stageRoot(ctx.stage);
  const mat = shaderMaterial(vShader, `
    varying vec2 vUv;
    uniform float uProgress;
    uniform float uTime;
    uniform float uWidth;
    void main() {
      vec2 q = vUv - 0.5;
      float y = q.y;
      float wob = sin(y * 26.0 + sin(y * 8.0) * 2.0) * 0.016;
      float line = smoothstep(0.055 * uWidth, 0.0, abs(q.x - wob));
      float line2 = smoothstep(0.030 * uWidth, 0.0, abs(q.x + 0.17 - sin(y * 34.0) * 0.03)) * 0.55;
      float line3 = smoothstep(0.022 * uWidth, 0.0, abs(q.x - 0.14 + sin(y * 19.0) * 0.02)) * 0.4;
      float reveal = 1.0 - smoothstep(uProgress, uProgress + 0.10, q.y + 0.5);
      float longFade = smoothstep(0.5, 0.42, abs(q.y));
      float a = (line + line2 + line3) * reveal * longFade;
      gl_FragColor = vec4(0.72, 0.52, 0.30, a * 0.9);
    }`, { uProgress: { value: 0 }, uTime: { value: 0 }, uWidth: { value: p.width } });
  const scratch = new THREE.Mesh(new THREE.PlaneGeometry(1.1, p.length), mat);
  scratch.name = 'sulcos';
  scratch.rotation.x = -Math.PI / 2;
  scratch.position.set(0, 0.02, -p.length * 0.35);
  group.add(scratch);

  const rocks = new THREE.InstancedMesh(
    new THREE.DodecahedronGeometry(0.075, 0),
    new THREE.MeshStandardMaterial({ color: 0x6b5a4a, roughness: 0.9 }),
    p.rocks
  );
  rocks.name = 'fragmentos';
  group.add(rocks);
  const dummyObj = new THREE.Object3D();
  const dust = makeBurst(180, ctx.soft, 0xc7b18e, 0.30, 0.34, false);
  group.add(dust.points);
  let acc = 0;
  const rockData = [];
  for (let i = 0; i < p.rocks; i++) {
    rockData.push({
      z: -p.length * 0.75 + (i / p.rocks) * p.length * 0.9 + (rand() - 0.5) * 0.12,
      x: (rand() - 0.5) * 0.7,
      s: 0.4 + rand() * 0.7,
      ph: rand() * 4,
    });
  }

  return {
    group,
    duration: 2.8,
    update(t, dt) {
      const d = travel(ctx.stage, t, 2.4);
      placeDummy(ctx, d);
      mat.uniforms.uProgress.value = clamp(t / 2.4, 0, 1);
      mat.uniforms.uTime.value = t;
      for (let i = 0; i < rockData.length; i++) {
        const rd = rockData[i];
        const y = 0.05 + Math.max(0, Math.sin(t * 4.0 + rd.ph)) * 0.3;
        dummyObj.position.set(rd.x, y, rd.z);
        dummyObj.rotation.set(t * 2.0, t * 3.0, t * 1.5);
        dummyObj.scale.setScalar(rd.s);
        dummyObj.updateMatrix();
        rocks.setMatrixAt(i, dummyObj.matrix);
      }
      rocks.instanceMatrix.needsUpdate = true;
      acc += dt;
      if (acc > 0.06) {
        acc = 0;
        dust.spawn(new THREE.Vector3(0, 0.1, -d + 0.4), 2, 0.5, 0.8, 0.7, new THREE.Vector3(0, 0.3, 1), 0.25);
      }
      dust.update(dt, 0.3);
    },
  };
}
