import * as THREE from 'three';
import {
  clamp, easeOutCubic, rand, ribbonGeometry, ringMesh, glowSprite,
  shaderMaterial, makeBurst, stageRoot, placeDummy, COLORS,
} from '../helpers.js';
import {
  createVortex, createFunnel, createSpiralRibbon, createHelix, createDissolve,
} from './forms.js';
import {
  createThrust, createSpeedLines, createMotionTrail, createAura,
  createDustTrail, createScuff,
} from './motion.js';
import {
  createShockwave, createCrown, createBlastCone, createFlipbook, createSparks,
  createDebris,
} from './impacts.js';
import {
  createCrownRef, createShockwaveRef, createAuraRef, createDustRef,
} from './flagship.js';
import { createSlash } from './slash.js';

const vShader = `varying vec2 vUv;
void main() {
  vUv = uv;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}`;

/**
 * Composição real: instancia componentes independentes e liga cada um na sua
 * janela de tempo. Não copia a implementação de nenhum deles.
 */
function compose(ctx, parts) {
  const group = new THREE.Group();
  const built = parts.map((part) => {
    const sub = Object.create(ctx);
    sub.skipDummy = part.skipDummy !== false;
    if (part.ownsDummy) sub.skipDummy = false;
    const inst = part.create(sub);
    inst.group.visible = false;
    inst.group.userData.windowVisible = false;
    inst.group.name = part.label;
    group.add(inst.group);
    return { ...part, inst };
  });
  const duration = Math.max(...parts.map((p) => p.start + p.dur));
  return {
    group,
    duration,
    update(t, dt, camera) {
      for (const b of built) {
        const local = t - b.start;
        const on = local >= -0.0001 && local <= b.dur;
        b.inst.group.userData.windowVisible = on;
        b.inst.group.visible = on && !b.inst.group.userData.userHidden;
        if (on) {
          b.inst.group.position.y = b.y || 0;
          b.inst.group.scale.setScalar(b.scale || 1);
          b.inst.update(local, dt, camera);
        }
      }
    },
  };
}

// EXTRA — ATTACK PRELUDE / HIT-WINDUP ----------------------------------------
export function createPrelude(ctx) {
  ctx.target.visible = true;
  const group = stageRoot(ctx.stage);
  const dist = ctx.stage.dist;
  placeDummy(ctx, 0);

  const hand = new THREE.Vector3(0.46, 1.35, -0.55);
  const contact = new THREE.Vector3(0, 1.25, -dist);
  const mid = hand.clone().lerp(contact, 0.5).add(new THREE.Vector3(0.35, 0.18, 0));
  const curve = new THREE.CatmullRomCurve3([hand, mid, contact]);
  const tubeMat = shaderMaterial(vShader, `
    varying vec2 vUv;
    uniform float uTime;
    uniform float uProgress;
    void main() {
      float bands = pow(0.5 + 0.5 * sin(vUv.x * 70.0 - uTime * 12.0), 4.0);
      float head = smoothstep(uProgress, uProgress - 0.05, vUv.x);
      vec3 col = mix(vec3(0.25, 0.8, 1.0), vec3(1.0, 0.85, 0.4), bands);
      gl_FragColor = vec4(col, (0.25 + bands * 0.7) * head);
    }`, { uTime: { value: 0 }, uProgress: { value: 0 } });
  const tube = new THREE.Mesh(new THREE.TubeGeometry(curve, 80, 0.055, 8, false), tubeMat);
  tube.name = 'traço de carga';
  group.add(tube);
  const halo = glowSprite(0xffd27a, 1.5, 0.8, ctx.soft);
  halo.position.copy(hand);
  group.add(halo);

  const lock = ringMesh(0.7, 0.82, COLORS.coral, 0.8);
  lock.position.set(0, 0.02, -dist);
  group.add(lock);
  const lockInner = ringMesh(1.3, 1.36, COLORS.amber, 0.5);
  lockInner.position.set(0, 0.02, -dist);
  group.add(lockInner);

  const skid = makeBurst(150, ctx.soft, 0xcdbfa8, 0.4, 0.32, false);
  group.add(skid.points);
  const sparks = makeBurst(90, ctx.soft, 0xffd27a, 0.06, 0.8);
  group.add(sparks.points);
  let acc = 0;

  return {
    group,
    duration: 2.8,
    update(t, dt) {
      const k = clamp(t / 2.2, 0, 1);
      const charge = clamp(t / 0.45, 0, 1);
      placeDummy(ctx, 0);
      tubeMat.uniforms.uTime.value = t;
      tubeMat.uniforms.uProgress.value = 0.3 + charge * 0.7;
      halo.scale.setScalar(0.8 + charge * 1.4 + Math.sin(t * 14.0) * 0.06);
      lock.scale.setScalar(1.6 - charge * 0.55 + Math.sin(t * 7.0) * 0.04);
      lock.material.opacity = 0.8 * (1 - k * 0.5);
      lockInner.rotation.z = t * 0.8;
      lockInner.scale.setScalar(1.0 + Math.sin(t * 2.2) * 0.06);
      acc += dt;
      if (acc > 0.06) {
        acc = 0;
        sparks.spawn(hand.clone(), 2, 0.5, 0.6, 0.5, new THREE.Vector3(0, 0.3, -0.5), 0.16);
        skid.spawn(new THREE.Vector3(0, 0.1, 0), 2, 0.7, 1.0, 0.7, new THREE.Vector3(0, 0.2, 1), 0.3);
      }
      sparks.update(dt, 0.6);
      skid.update(dt, 0.3);
    },
  };
}

// DEMO-01 — ANIME DASH --------------------------------------------------------
export function createAnimeDash(ctx) {
  return compose(ctx, [
    { label: 'aura de saída', create: createAuraRef, start: 0.0, dur: 1.6 },
    { label: 'cone de propulsão', create: createThrust, start: 0.05, dur: 2.6, ownsDummy: true },
    { label: 'linhas de velocidade', create: createSpeedLines, start: 0.10, dur: 2.6 },
    { label: 'rastro', create: createMotionTrail, start: 0.10, dur: 3.0 },
    { label: 'poeira', create: createDustRef, start: 0.10, dur: 3.0 },
    { label: 'poeira de frenagem', create: createScuff, start: 2.35, dur: 2.0 },
  ]);
}

// DEMO-02 — PUNCHY ANIME IMPACT ----------------------------------------------
export function createPunchyImpact(ctx) {
  return compose(ctx, [
    { label: 'flipbook de impacto', create: createFlipbook, start: 0.00, dur: 2.0 },
    { label: 'coroa', create: createCrownRef, start: 0.00, dur: 1.6 },
    { label: 'onda de choque', create: createShockwaveRef, start: 0.02, dur: 1.9 },
    { label: 'cone de choque', create: createBlastCone, start: 0.04, dur: 1.8 },
    { label: 'faíscas', create: createSparks, start: 0.02, dur: 1.6 },
    { label: 'fragmentos', create: createDebris, start: 0.06, dur: 2.4 },
  ]);
}

// DEMO-03 — ENERGY HELIX ------------------------------------------------------
export function createEnergyHelix(ctx) {
  return compose(ctx, [
    { label: 'fita helicoidal', create: createSpiralRibbon, start: 0.0, dur: 4.6 },
    { label: 'feixe helicoidal', create: createHelix, start: 0.2, dur: 4.0 },
    { label: 'erosão', create: createDissolve, start: 2.0, dur: 2.5, y: 4.1, scale: 0.55 },
  ]);
}

// DEMO-04 — VORTEX / TORNADO STUDY -------------------------------------------
export function createVortexStudy(ctx) {
  return compose(ctx, [
    { label: 'vórtice', create: createVortex, start: 0.0, dur: 6.0 },
    { label: 'tornado', create: createFunnel, start: 0.3, dur: 5.5 },
    { label: 'erosão', create: createDissolve, start: 1.8, dur: 3.0, y: 3.2, scale: 0.6 },
  ]);
}

// DEMO-05 — STYLIZED SLASH ----------------------------------------------------
export function createStylizedSlash(ctx) {
  return compose(ctx, [
    { label: 'aproximação', create: createMotionTrail, start: 0.0, dur: 1.4, ownsDummy: true },
    { label: 'arco de corte', create: createSlash, start: 0.7, dur: 1.5 },
  ]);
}
