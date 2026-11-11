import * as THREE from 'three';
import {
  TAU, clamp, rand, liveParams, stageRoot,
} from '../helpers.js';
import { NOISE_GLSL, makeStreakField, makeFlipbookPlane, loadFlipbook } from '../vfxlib.js';

const IMPACT_ATLAS = loadFlipbook(new URL('../../../../assets/vfx/flipbook_impact.png', import.meta.url).href);

export const SLASH_DEFAULTS = {
  arc: 190,
  radius: 2.05,
  width: 0.55,
  tilt: 12,
  reveal: 0.22,
  hold: 0.22,
  fade: 0.55,
  sparks: 1.0,
  splash: 0.5,
  charge: 0.8,
  under: 0.55,
  hot: '#fff2c4',
  body: '#ff7a12',
  edge: '#4a0f00',
};

function smooth01(x) {
  const t = clamp(x, 0, 1);
  return t * t * (3 - 2 * t);
}

/**
 * Fita de arco com três camadas: under-trail escuro, corpo colorido e gume branco.
 * A largura é medida no plano do arco; y=0 é a borda interna, y=1 a externa.
 */
function buildRibbon({ arc, radius, tilt, width, widthMul, offset, dist = 0, baseY = 1.15, upMode = 'plane', segments = 180 }) {
  const positions = [];
  const uv = [];
  const index = [];
  const rad = THREE.MathUtils.degToRad(arc);
  const tiltRad = THREE.MathUtils.degToRad(tilt);
  const up = new THREE.Vector3(0, 0, 1);
  const upv = new THREE.Vector3();
  const tan = new THREE.Vector3();
  const side = new THREE.Vector3();

  const point = (u, out = new THREE.Vector3()) => {
    const th = -rad / 2 + rad * u;
    out.set(
      Math.sin(th) * radius,
      baseY + Math.sin(th) * radius * Math.sin(tiltRad) * 0.35,
      -dist + Math.sin(th) * Math.sin(th) * 0.55
    );
    return out;
  };

  for (let i = 0; i <= segments; i++) {
    const u = i / segments;
    const q = point(u);
    const q2 = point(Math.min(1, u + 0.01));
    const q0 = point(Math.max(0, u - 0.01));
    tan.copy(q2).sub(q0).normalize();
    if (upMode === 'volume') {
      upv.set(0, 1, 0);
    } else {
      upv.copy(up);
    }
    side.crossVectors(tan, upv).normalize();
    if (side.lengthSq() < 1e-5) side.set(0, 1, 0);
    const w = width * widthMul * (0.14 + 0.86 * Math.sin(Math.PI * u)) * (0.90 + 0.18 * Math.sin(u * 19.0 + 2.0));
    const c = q.clone().addScaledVector(side, offset * width + Math.sin(u * 11.0) * width * 0.05);
    const a = c.clone().addScaledVector(side, -w * 0.5);
    const b = c.clone().addScaledVector(side, w * 0.5);
    positions.push(a.x, a.y, a.z, b.x, b.y, b.z);
    uv.push(u, 0, u, 1);
    if (i < segments) {
      const v = i * 2;
      index.push(v, v + 1, v + 2, v + 1, v + 3, v + 2);
    }
  }

  const geo = new THREE.BufferGeometry();
  geo.setAttribute('position', new THREE.Float32BufferAttribute(positions, 3));
  geo.setAttribute('uv', new THREE.Float32BufferAttribute(uv, 2));
  geo.setIndex(index);
  return geo;
}

const VERT = `
  varying vec2 vUv;
  void main() { vUv = uv; gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0); }`;

const BODY_FRAG = NOISE_GLSL + `
  varying vec2 vUv;
  uniform float uTime; uniform float uReveal; uniform float uFade;
  uniform vec3 uHot; uniform vec3 uBody; uniform vec3 uEdge;
  void main() {
    float y = vUv.y;
    float n = fbm2(vec2(vUv.x * 16.0 - uTime * 3.0, y * 6.0));
    float n2 = fbm2(vec2(vUv.x * 34.0 - uTime * 7.0, y * 16.0 + 3.0));
    float f1 = fbm2(vec2(vUv.x * 7.0 - uTime * 4.0, y * 9.0 + 1.0));
    float f2 = fbm2(vec2(vUv.x * 18.0 - uTime * 7.0, y * 21.0 + 4.0));
    // Manchas de fogo em degraus (cel): sem gradiente suave no corpo.
    float flame = step(0.62, f1 * 0.6 + f2 * 0.5);
    float burn = step(0.60, n2);
    float head = smoothstep(uReveal + 0.08, uReveal - 0.02, vUv.x);
    float tail = smoothstep(0.0, 0.20, vUv.x);
    float erode = smoothstep(0.18, 0.62, n + (1.0 - vUv.x) * 0.38);
    // Três bandas chapadas: contorno escuro, corpo laranja, gume quente.
    float gume = step(0.78, y);
    vec3 col = uEdge;
    col = mix(col, uBody, step(0.26, y));
    col = mix(col, uHot, gume);
    float bodyBand = step(0.26, y) * (1.0 - gume);
    col = mix(col, uHot, flame * bodyBand * 0.30);
    col = mix(col, uEdge, burn * bodyBand * 0.18);
    // Alpha sólido: o desenho é chapado; só a cauda e a cabeça dissolvem.
    float a = head * tail * erode * (0.94 + 0.06 * flame) * uFade;
    gl_FragColor = vec4(col, clamp(a, 0.0, 0.97));
  }`;

const EDGE_FRAG = `
  varying vec2 vUv;
  uniform float uReveal; uniform float uFade; uniform vec3 uHot;
  void main() {
    float core = step(0.30, 1.0 - abs(vUv.y - 0.5) * 2.0);
    float head = smoothstep(uReveal + 0.08, uReveal - 0.02, vUv.x);
    float tail = smoothstep(0.0, 0.26, vUv.x);
    gl_FragColor = vec4(uHot * 1.2, core * 0.90 * head * tail * uFade);
  }`;

const UNDER_FRAG = `
  varying vec2 vUv;
  uniform float uReveal; uniform float uFade; uniform float uUnder; uniform vec3 uUnderColor;
  void main() {
    float head = smoothstep(uReveal + 0.10, uReveal - 0.02, vUv.x);
    float tail = smoothstep(0.0, 0.18, vUv.x);
    gl_FragColor = vec4(uUnderColor, 0.92 * uUnder * head * tail * uFade);
  }`;

export function createSlash(ctx) {
  const p = liveParams(ctx, SLASH_DEFAULTS);
  const group = stageRoot(ctx.stage);
  const dist = ctx.stage.dist;

  // Escala derivada do corpo do alvo (lição da auditoria: efeito no alvo é
  // proporcional ao alvo, não um tamanho fixo em metros).
  const box = new THREE.Box3().setFromObject(ctx.target);
  const tsize = box.getSize(new THREE.Vector3());
  const bodyH = Math.max(0.6, tsize.y);
  const k = bodyH / 2.12;
  const R = p.radius * k;
  const W = p.width * k;
  const baseY = box.min.y + bodyH * 0.55;

  const underMat = new THREE.ShaderMaterial({
    uniforms: {
      uReveal: { value: 0 }, uFade: { value: 1 }, uUnder: { value: p.under },
      uUnderColor: { value: new THREE.Color('#070b18') },
    },
    vertexShader: VERT, fragmentShader: UNDER_FRAG,
    transparent: true, depthWrite: false, side: THREE.DoubleSide, blending: THREE.NormalBlending,
  });
  const under = new THREE.Mesh(
    buildRibbon({ arc: p.arc, radius: R, tilt: p.tilt, width: W, widthMul: 1.30, offset: 0, dist, baseY }),
    underMat
  );
  under.name = 'under-trail';
  group.add(under);

  const bodyMat = new THREE.ShaderMaterial({
    uniforms: {
      uTime: { value: 0 }, uReveal: { value: 0 }, uFade: { value: 1 },
      uHot: { value: new THREE.Color(p.hot) },
      uBody: { value: new THREE.Color(p.body) },
      uEdge: { value: new THREE.Color(p.edge) },
    },
    vertexShader: VERT, fragmentShader: BODY_FRAG,
    transparent: true, depthWrite: false, side: THREE.DoubleSide, blending: THREE.NormalBlending,
  });
  const body = new THREE.Mesh(
    buildRibbon({ arc: p.arc, radius: R, tilt: p.tilt, width: W, widthMul: 1.0, offset: 0, dist, baseY }),
    bodyMat
  );
  body.name = 'corpo do arco';
  body.renderOrder = 1;
  group.add(body);

  const volume = new THREE.Mesh(
    buildRibbon({ arc: p.arc, radius: R, tilt: p.tilt, width: W, widthMul: 0.35, offset: 0, dist, baseY, upMode: 'volume' }),
    bodyMat
  );
  volume.name = 'volume do arco';
  volume.renderOrder = 1;
  group.add(volume);

  const edgeMat = new THREE.ShaderMaterial({
    uniforms: {
      uReveal: { value: 0 }, uFade: { value: 1 },
      uHot: { value: new THREE.Color(p.hot) },
    },
    vertexShader: VERT, fragmentShader: EDGE_FRAG,
    transparent: true, depthWrite: false, side: THREE.DoubleSide, blending: THREE.AdditiveBlending,
  });
  const edge = new THREE.Mesh(
    buildRibbon({ arc: p.arc, radius: R, tilt: p.tilt, width: W, widthMul: 0.16, offset: 0.42, dist, baseY }),
    edgeMat
  );
  edge.name = 'gume';
  edge.renderOrder = 2;
  group.add(edge);

  const streaks = makeStreakField({ count: 36, color: '#dff6ff', size: 0.024 });
  streaks.mesh.name = 'faíscas';
  group.add(streaks.mesh);

  const shards = new THREE.InstancedMesh(
    new THREE.TetrahedronGeometry(0.075, 0),
    new THREE.MeshStandardMaterial({ color: 0x2a3442, roughness: 0.45, metalness: 0.45 }),
    10
  );
  shards.name = 'estilhaços';
  group.add(shards);
  const shardData = [];
  for (let i = 0; i < 10; i++) {
    shardData.push({ p: new THREE.Vector3(0, -999, 0), v: new THREE.Vector3(), r: new THREE.Vector3(rand() * 6, rand() * 6, rand() * 6), live: false });
  }
  const dummy = new THREE.Object3D();

  // ponto do arco no instante de revelação, para emitir faíscas na cabeça
  const headPoint = (u) => {
    const rad = THREE.MathUtils.degToRad(p.arc);
    const tiltRad = THREE.MathUtils.degToRad(p.tilt);
    const th = -rad / 2 + rad * u;
    return new THREE.Vector3(
      Math.sin(th) * R,
      baseY + Math.sin(th) * R * Math.sin(tiltRad) * 0.35,
      -dist + Math.sin(th) * Math.sin(th) * 0.55
    );
  };

  // Carga em zigue-zague à frente do punho, no eixo do ataque. A posição do
  // punho vem do corpo do atacante (D-235), não de uma coordenada fixa.
  const attackerBox = new THREE.Box3().setFromObject(ctx.dummy);
  const attackerSize = attackerBox.getSize(new THREE.Vector3());
  const ka = Math.max(0.6, attackerSize.y) / 2.12;
  const hand = new THREE.Vector3(
    Math.max(0.18, attackerSize.x * 0.42),
    attackerBox.min.y - ctx.stage.from.y + attackerSize.y * 0.55,
    -(attackerSize.z * 0.5 + 0.10)
  );
  const chargeReach = Math.min(1.5 * ka, dist * 0.42);
  const chargeEnd = hand.clone().add(new THREE.Vector3(0, 0, -chargeReach));
  const dir = chargeEnd.clone().sub(hand);
  const side = new THREE.Vector3(-dir.z, 0, dir.x).normalize();
  const mk = (u, sAmt, yAmt, zAmt) => hand.clone().lerp(chargeEnd, u)
    .addScaledVector(side, sAmt * ka)
    .add(new THREE.Vector3(0, yAmt * ka, zAmt * ka));
  const zig = [
    hand.clone().add(new THREE.Vector3(0, 0.10 * ka, 0.25 * ka)),
    mk(0.15, 0.70, 0.55, 0.45),
    mk(0.33, -0.70, -0.55, 0.35),
    mk(0.52, 0.55, 0.50, 0.25),
    mk(0.72, -0.50, -0.40, 0.15),
    mk(0.88, 0.30, 0.25, 0.08),
    chargeEnd.clone(),
  ];
  const chargeMat = new THREE.MeshBasicMaterial({
    color: new THREE.Color(p.hot), transparent: true, opacity: 0.85,
    blending: THREE.AdditiveBlending, depthWrite: false, side: THREE.DoubleSide,
  });
  const zigPath = new THREE.CurvePath();
  for (let i = 0; i < zig.length - 1; i++) zigPath.add(new THREE.LineCurve3(zig[i], zig[i + 1]));
  const charge = new THREE.Mesh(new THREE.TubeGeometry(zigPath, 96, 0.028 * ka, 6, false), chargeMat);
  charge.name = 'carga em zigue-zague';
  group.add(charge);

  // respingos com atlas real 4x4 (ref. Venom)
  const splashes = [];
  for (let i = 0; i < 6; i++) {
    const s = makeFlipbookPlane(IMPACT_ATLAS, { size: 0.16 + i * 0.03, fps: 60 });
    s.mesh.name = 'respingo (atlas 4x4)';
    s.mesh.visible = false;
    group.add(s.mesh);
    splashes.push({ ...s, at: -1 });
  }
  let splashCursor = 0;

  let lastReveal = 0;
  let shardCursor = 0;

  return {
    group,
    duration: 1.5,
    update(t, dt, camera) {
      const revealTime = Math.max(0.06, p.reveal);
      const reveal = clamp(t / revealTime, 0, 1);
      const fade = 1 - smooth01((t - (revealTime + p.hold)) / Math.max(0.05, p.fade));

      underMat.uniforms.uReveal.value = reveal;
      underMat.uniforms.uFade.value = fade;
      underMat.uniforms.uUnder.value = p.under;
      bodyMat.uniforms.uTime.value = t;
      bodyMat.uniforms.uReveal.value = reveal;
      bodyMat.uniforms.uFade.value = fade;
      bodyMat.uniforms.uHot.value.set(p.hot);
      bodyMat.uniforms.uBody.value.set(p.body);
      bodyMat.uniforms.uEdge.value.set(p.edge);
      edgeMat.uniforms.uReveal.value = reveal;
      edgeMat.uniforms.uFade.value = fade;
      edgeMat.uniforms.uHot.value.set(p.hot);

      chargeMat.color.set(p.hot);
      chargeMat.opacity = p.charge * (1 - smooth01((t - 0.02) / 0.20)) * (0.85 + 0.15 * Math.sin(t * 70));
      underMat.uniforms.uUnderColor.value.set(p.edge).multiplyScalar(0.18);
      streaks.mesh.material.color.set(p.hot);
      shards.material.color.set(p.edge);

      // faíscas e estilhaços na cabeça do arco, enquanto revela
      if (reveal > lastReveal && reveal < 1 && p.sparks > 0) {
        const u = reveal;
        const q = headPoint(u);
        const q2 = headPoint(Math.min(1, u + 0.02));
        const tan = q2.clone().sub(q).normalize();
        const rad = THREE.MathUtils.degToRad(p.arc);
        const th = -rad / 2 + rad * u;
        const normal = new THREE.Vector3(Math.sin(th), 0, Math.cos(th)).normalize();
        q.addScaledVector(normal, W * 0.45);
        const n = Math.round(2 * p.sparks);
        for (let i = 0; i < n; i++) {
          const v = tan.clone().multiplyScalar(2.4 + rand() * 1.8)
            .addScaledVector(normal, 0.7 + rand() * 1.1)
            .add(new THREE.Vector3((rand() - 0.5) * 1.6, (rand() - 0.2) * 1.6, (rand() - 0.5) * 1.6));
          streaks.spawn(q, v, 0.35 + rand() * 0.3, 0.16 + rand() * 0.12);
        }
        if (rand() < 0.6 * p.sparks) {
          const ub = Math.max(0, u - 0.12 - rand() * 0.2);
          const qb = headPoint(ub).addScaledVector(normal, -W * 0.35);
          const inward = tan.clone().multiplyScalar(-0.6 - rand() * 1.4)
            .addScaledVector(normal, -0.3 - rand() * 0.6)
            .add(new THREE.Vector3((rand() - 0.5) * 0.5, (rand() - 0.2) * 0.5, (rand() - 0.5) * 0.5));
          streaks.spawn(qb, inward, 0.5, 0.12);
        }
        if (p.sparks > 0.4) {
          for (let k = 0; k < 2; k++) {
            const ub = Math.max(0, u - 0.08 - rand() * 0.35);
            const qb = headPoint(ub).addScaledVector(normal, -W * 0.4);
            const inward = tan.clone().multiplyScalar(-0.4 - rand() * 1.0)
              .addScaledVector(normal, -0.2 - rand() * 0.5)
              .add(new THREE.Vector3((rand() - 0.5) * 0.6, (rand() - 0.1) * 0.5, (rand() - 0.5) * 0.6));
            streaks.spawn(qb, inward, 0.45, 0.10);
          }
        }
        if (rand() < 0.5 * p.sparks) {
          const sd = shardData[shardCursor % shardData.length];
          shardCursor++;
          sd.p.copy(q);
          sd.v.set((rand() - 0.5) * 3.0, rand() * 2.2, (rand() - 0.5) * 3.0);
          sd.live = true;
        }
        if (rand() < 0.55 * p.splash) {
          const s = splashes[splashCursor++ % splashes.length];
          s.at = t;
          s.mesh.visible = true;
          s.mesh.position.copy(q).add(new THREE.Vector3((rand() - 0.5) * 0.35, (rand() - 0.5) * 0.35, (rand() - 0.5) * 0.35));
          s.mesh.rotation.set(0, 0, rand() * TAU);
        }
      }
      lastReveal = reveal;
      streaks.update(dt, -4);

      for (const s of splashes) {
        if (s.at < 0) continue;
        const lt = t - s.at;
        if (lt > 0.20) { s.mesh.visible = false; s.at = -1; continue; }
        s.mesh.visible = true;
        s.update(Math.min(lt, 0.10), camera);
        s.mat.uniforms.uOpacity.value = 0.85 * (1 - smooth01((lt - 0.10) / 0.08));
      }

      for (let i = 0; i < shardData.length; i++) {
        const sd = shardData[i];
        if (!sd.live) {
          dummy.position.set(0, -999, 0);
          dummy.scale.setScalar(0);
          dummy.updateMatrix();
          shards.setMatrixAt(i, dummy.matrix);
          continue;
        }
        sd.v.y -= 6.5 * dt;
        sd.p.addScaledVector(sd.v, dt);
        sd.r.x += dt * 8; sd.r.y += dt * 6;
        const hide = 1 - smooth01((t - 0.7) / 0.5);
        dummy.position.copy(sd.p);
        dummy.rotation.set(sd.r.x, sd.r.y, sd.r.z);
        dummy.scale.setScalar(hide);
        dummy.updateMatrix();
        shards.setMatrixAt(i, dummy.matrix);
      }
      shards.instanceMatrix.needsUpdate = true;
    },
  };
}
