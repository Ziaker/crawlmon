import * as BABYLON from '@babylonjs/core';
import '@babylonjs/loaders/glTF';

const SLIME_GLB = '__SLIME_GLB__';
const CAUSTIC_TEX_DATA = '__CAUSTICS__';
const FOAM_TEX_DATA = '__FOAMTEX__';
const ALLY_POS = [
  new BABYLON.Vector3(-1.95, 0, 0.15),
  new BABYLON.Vector3(0, 0, 0.55),
  new BABYLON.Vector3(1.95, 0, 0.15),
];
const CENTER = new BABYLON.Vector3(0, 0, 0.28);
const DURATION = 5.0;
const WINDUP_END = 1.0;
const FORM_END = 2.25;

const canvas = document.getElementById('scene');
const engine = new BABYLON.Engine(canvas, true, {
  preserveDrawingBuffer: true,
  stencil: true,
  antialias: true,
  alpha: false,
}, true);
engine.setHardwareScalingLevel(1);

const scene = new BABYLON.Scene(engine);
scene.clearColor = new BABYLON.Color4(0.012, 0.028, 0.047, 1);
scene.fogMode = BABYLON.Scene.FOGMODE_EXP2;
scene.fogColor = new BABYLON.Color3(0.015, 0.045, 0.065);
scene.fogDensity = 0.028;

const causticTex = new BABYLON.Texture(
  CAUSTIC_TEX_DATA,
  scene,
  false,
  false,
  BABYLON.Texture.TRILINEAR_SAMPLINGMODE,
);
causticTex.wrapU = BABYLON.Texture.WRAP_ADDRESSMODE;
causticTex.wrapV = BABYLON.Texture.WRAP_ADDRESSMODE;
causticTex.hasAlpha = true;

const foamTex = new BABYLON.Texture(
  FOAM_TEX_DATA,
  scene,
  false,
  false,
  BABYLON.Texture.TRILINEAR_SAMPLINGMODE,
);
foamTex.wrapU = BABYLON.Texture.WRAP_ADDRESSMODE;
foamTex.wrapV = BABYLON.Texture.WRAP_ADDRESSMODE;
foamTex.hasAlpha = true;

const camera = new BABYLON.ArcRotateCamera(
  'camera',
  Math.PI / 2,
  1.34,
  8.2,
  new BABYLON.Vector3(0, 1.02, 0.2),
  scene,
);
camera.attachControl(canvas, true);
camera.fov = 0.76;
camera.lowerRadiusLimit = 4.0;
camera.upperRadiusLimit = 16;
camera.lowerBetaLimit = 0.5;
camera.upperBetaLimit = 1.52;
camera.panningSensibility = 0;
camera.wheelPrecision = 28;
camera.inertia = 0.72;

const hemi = new BABYLON.HemisphericLight('hemi', new BABYLON.Vector3(0, 1, 0), scene);
hemi.intensity = 0.90;
hemi.diffuse = new BABYLON.Color3(0.42, 0.66, 0.72);
hemi.groundColor = new BABYLON.Color3(0.015, 0.035, 0.05);

const key = new BABYLON.DirectionalLight('key', new BABYLON.Vector3(0.35, -1, -0.55), scene);
key.position = new BABYLON.Vector3(-4, 9, -5);
key.intensity = 6.0;
key.diffuse = new BABYLON.Color3(0.82, 0.96, 1.0);

const rim = new BABYLON.DirectionalLight('rim', new BABYLON.Vector3(-0.7, -0.25, 0.9), scene);
rim.position = new BABYLON.Vector3(6, 3, 8);
rim.intensity = 1.4;
rim.diffuse = new BABYLON.Color3(0.28, 0.75, 1.0);

const fill = new BABYLON.DirectionalLight('fill', new BABYLON.Vector3(0.08, -0.35, -1), scene);
fill.position = new BABYLON.Vector3(0, 4.5, 8);
fill.intensity = 3.0;
fill.diffuse = new BABYLON.Color3(0.36, 0.68, 1.0);

const frontGlow = new BABYLON.PointLight('frontGlow', new BABYLON.Vector3(0, 2.0, 6.2), scene);
frontGlow.intensity = 3.0;
frontGlow.range = 18;
frontGlow.diffuse = new BABYLON.Color3(0.25, 0.72, 1.0);

const shadows = new BABYLON.ShadowGenerator(2048, key);
shadows.useBlurExponentialShadowMap = true;
shadows.blurKernel = 32;
shadows.setDarkness(0.15);

// ---------------------------------------------------------------------------
// Environment
// ---------------------------------------------------------------------------
const refractionMeshes = [];
const monoliths = [];

const floor = BABYLON.MeshBuilder.CreateGround('floor', { width: 64, height: 64 }, scene);
const floorMat = new BABYLON.PBRMaterial('floorMat', scene);
floorMat.albedoColor = new BABYLON.Color3(0.018, 0.038, 0.047);
floorMat.metallic = 0.08;
floorMat.roughness = 0.72;
floorMat.environmentIntensity = 0.25;
floor.material = floorMat;
floor.receiveShadows = true;
refractionMeshes.push(floor);

// Arena rings on the ground.
const ringMatA = new BABYLON.StandardMaterial('ringMatA', scene);
ringMatA.disableLighting = true;
ringMatA.emissiveColor = new BABYLON.Color3(0.1, 0.55, 0.65);
ringMatA.alpha = 0.32;
for (const r of [2.9, 4.3, 6.0]) {
  const ring = BABYLON.MeshBuilder.CreateTorus(`floorRing${r}`, {
    diameter: r * 2,
    thickness: 0.012,
    tessellation: 128,
  }, scene);
  ring.rotation.x = Math.PI / 2;
  ring.position.y = 0.012;
  ring.material = ringMatA;
  ring.isPickable = false;
}

// Soft pool of light under the party.
{
  const glowTex = new BABYLON.DynamicTexture('floorGlowTex', { width: 256, height: 256 }, scene, false);
  const ctx = glowTex.getContext();
  const g = ctx.createRadialGradient(128, 128, 8, 128, 128, 128);
  g.addColorStop(0, 'rgba(110,225,255,0.62)');
  g.addColorStop(0.35, 'rgba(50,170,220,0.26)');
  g.addColorStop(0.75, 'rgba(20,100,150,0.06)');
  g.addColorStop(1, 'rgba(0,0,0,0)');
  ctx.fillStyle = g;
  ctx.fillRect(0, 0, 256, 256);
  glowTex.update();
  glowTex.hasAlpha = true;
  const disc = BABYLON.MeshBuilder.CreateDisc('floorGlow', { radius: 3.55, tessellation: 64 }, scene);
  disc.rotation.x = Math.PI / 2;
  disc.position.set(CENTER.x, 0.008, CENTER.z);
  const gm = new BABYLON.StandardMaterial('floorGlowMat', scene);
  gm.disableLighting = true;
  gm.emissiveTexture = glowTex;
  gm.opacityTexture = glowTex;
  gm.alphaMode = BABYLON.Engine.ALPHA_ADD;
  gm.alpha = 0.55;
  gm.backFaceCulling = false;
  disc.material = gm;
  disc.isPickable = false;
  disc.alphaIndex = 0;
}

// Monolith silhouettes.
const monolithMat = new BABYLON.StandardMaterial('monolithMat', scene);
monolithMat.diffuseColor = new BABYLON.Color3(0.012, 0.028, 0.038);
monolithMat.specularColor = BABYLON.Color3.Black();
monolithMat.emissiveColor = new BABYLON.Color3(0.004, 0.012, 0.018);
for (let i = 0; i < 18; i++) {
  const a = (i / 18) * Math.PI * 2 + 0.12;
  const rad = 10.5 + (i % 4) * 2.4;
  const h = 3.2 + ((i * 7) % 9);
  const w = 1.0 + ((i * 3) % 5) * 0.28;
  const m = BABYLON.MeshBuilder.CreateBox(`monolith${i}`, { width: w, height: h, depth: w * 0.8 }, scene);
  m.position.set(Math.cos(a) * rad, h / 2, Math.sin(a) * rad);
  m.rotation.y = a + (i % 3) * 0.2;
  m.material = monolithMat;
  m.isPickable = false;
  monoliths.push(m);
  refractionMeshes.push(m);
  if (i % 5 === 0) {
    const strip = BABYLON.MeshBuilder.CreateBox(`strip${i}`, {
      width: 0.055,
      height: h * 0.55,
      depth: 0.055,
    }, scene);
    const sm = new BABYLON.StandardMaterial(`stripMat${i}`, scene);
    sm.disableLighting = true;
    sm.emissiveColor = new BABYLON.Color3(0.04, 0.42, 0.55);
    sm.alpha = 0.6;
    strip.material = sm;
    strip.position.set(m.position.x + w * 0.42, h * 0.4, m.position.z + w * 0.36);
    strip.isPickable = false;
    monoliths.push(strip);
    refractionMeshes.push(strip);
  }
}

// Ambient dust (simple points cloud).
{
  const pcs = new BABYLON.PointsCloudSystem('dust', 2, scene);
  const count = 420;
  for (let i = 0; i < count; i++) {
    const r = 2.5 + Math.random() * 18;
    const a = Math.random() * Math.PI * 2;
    pcs.addPoints(1, (p) => {
      p.position.set(Math.cos(a) * r, 0.2 + Math.random() * 8, Math.sin(a) * r);
    });
  }
  pcs.buildMeshAsync().then((mesh) => {
    const mat = new BABYLON.StandardMaterial('dustMat', scene);
    mat.disableLighting = true;
    mat.emissiveColor = new BABYLON.Color3(0.35, 0.8, 0.95);
    mat.alpha = 0.32;
    mat.pointsCloud = true;
    mat.pointSize = 1.5;
    mesh.material = mat;
    mesh.isPickable = false;
  });
}

// ---------------------------------------------------------------------------
// Slimes
// ---------------------------------------------------------------------------
const slimes = [];
const slimeMeshes = [];

function makeFallbackSlime(index) {
  const root = new BABYLON.TransformNode(`slimeFallback${index}`, scene);
  const body = BABYLON.MeshBuilder.CreateSphere(`fbBody${index}`, { diameter: 1.35, segments: 32 }, scene);
  body.scaling.y = 1.1;
  body.position.y = 0.78;
  body.parent = root;
  const mat = new BABYLON.PBRMaterial(`fbMat${index}`, scene);
  mat.albedoColor = new BABYLON.Color3(0.08, 0.34, 0.95);
  mat.roughness = 0.45;
  mat.metallic = 0.05;
  body.material = mat;
  const cone = BABYLON.MeshBuilder.CreateCylinder(`fbTip${index}`, {
    diameterTop: 0,
    diameterBottom: 0.55,
    height: 0.55,
    tessellation: 24,
  }, scene);
  cone.position.y = 1.52;
  cone.parent = root;
  cone.material = mat;
  for (const [x, y] of [[-0.22, 0.95], [0.22, 0.95]]) {
    const eye = BABYLON.MeshBuilder.CreateSphere(`fbEye${index}`, { diameter: 0.09, segments: 12 }, scene);
    eye.position.set(x, y, 0.62);
    eye.parent = root;
    const em = new BABYLON.StandardMaterial(`fbEyeMat${index}`, scene);
    em.disableLighting = true;
    em.emissiveColor = BABYLON.Color3.Black();
    eye.material = em;
  }
  const mouth = BABYLON.MeshBuilder.CreateTorus(`fbMouth${index}`, {
    diameter: 0.32,
    thickness: 0.045,
    tessellation: 24,
  }, scene);
  mouth.rotation.x = Math.PI / 2;
  mouth.position.set(0, 0.55, 0.62);
  mouth.parent = root;
  const mm = new BABYLON.StandardMaterial(`fbMouthMat${index}`, scene);
  mm.disableLighting = true;
  mm.emissiveColor = new BABYLON.Color3(0.8, 0.06, 0.06);
  mouth.material = mm;
  return { root, meshes: [body, cone, eye, mouth] };
}

async function loadSlimes() {
  let container = null;
  try {
    const res = await fetch(SLIME_GLB);
    const blob = await res.blob();
    const blobUrl = URL.createObjectURL(blob);
    container = await BABYLON.SceneLoader.LoadAssetContainerAsync(
      blobUrl,
      '',
      scene,
      undefined,
      '.glb',
    );
    URL.revokeObjectURL(blobUrl);
  } catch (err) {
    console.warn('GLB load failed, using fallback slimes:', err);
  }

  for (let i = 0; i < 3; i++) {
    const root = new BABYLON.TransformNode(`slimeRoot${i}`, scene);
    root.position.copyFrom(ALLY_POS[i]);
    root.rotation.y = Math.PI;
    let meshes = [];
    let anims = [];

    if (container) {
      const entry = container.instantiateModelsToScene((name) => `${name}_${i}`, false);
      entry.rootNodes.forEach((n) => { n.parent = root; });
      meshes = root.getChildMeshes(false);
      anims = entry.animationGroups || [];
      for (const m of meshes) {
        m.isPickable = false;
        m.receiveShadows = true;
        m.castShadow = true;
        shadows.addShadowCaster(m);
        if (m.material) {
          m.material.backFaceCulling = true;
          if (m.material.albedoTexture) {
            m.material.albedoTexture.updateSamplingMode(BABYLON.Texture.NEAREST_SAMPLINGMODE);
          }
        }
      }
      // Normalize height.
      let bounds = root.getHierarchyBoundingVectors(true);
      const h = Math.max(0.001, bounds.max.y - bounds.min.y);
      const s = 1.42 / h;
      root.scaling.setAll(s);
      bounds = root.getHierarchyBoundingVectors(true);
      root.position.y -= bounds.min.y;
      // Idle animation.
      const idle = anims.find((g) => g.name.includes('cm_00_0000_00')) || anims[0];
      anims.forEach((g) => g.stop());
      if (idle) idle.start(true);
    } else {
      const fb = makeFallbackSlime(i);
      fb.root.position.copyFrom(ALLY_POS[i]);
      fb.meshes.forEach((m) => {
        m.parent = root;
        shadows.addShadowCaster(m);
      });
      meshes = fb.meshes;
      root.rotation.y = 0;
    }

    for (const m of root.getChildMeshes(false)) {
      m.receiveShadows = true;
      m.isPickable = false;
      if (m.material) m.material.backFaceCulling = true;
      refractionMeshes.push(m);
      slimeMeshes.push(m);
    }
    slimes.push({ index: i, root, meshes, anims });
  }
}

// ---------------------------------------------------------------------------
// Vortex volume shader
// ---------------------------------------------------------------------------
const vortexVertex = /* glsl */`
  precision highp float;
  attribute vec3 position;
  uniform mat4 world;
  uniform mat4 worldViewProjection;
  varying vec3 vWorld;
  void main() {
    vec4 wp = world * vec4(position, 1.0);
    vWorld = wp.xyz;
    gl_Position = worldViewProjection * vec4(position, 1.0);
  }
`;

const vortexFragment = /* glsl */`
  precision highp float;
  varying vec3 vWorld;
  uniform vec3 cameraPosition;
  uniform vec3 uCenter;
  uniform float uRadius;
  uniform float uHeight;
  uniform float uTime;
  uniform float uIntensity;
  uniform float uCollapse;

  float hash(vec3 p) {
    p = fract(p * 0.3183099 + vec3(0.11, 0.22, 0.33));
    p *= 17.0;
    return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
  }
  float noise(vec3 x) {
    vec3 i = floor(x);
    vec3 f = fract(x);
    f = f * f * (3.0 - 2.0 * f);
    return mix(
      mix(mix(hash(i + vec3(0,0,0)), hash(i + vec3(1,0,0)), f.x),
          mix(hash(i + vec3(0,1,0)), hash(i + vec3(1,1,0)), f.x), f.y),
      mix(mix(hash(i + vec3(0,0,1)), hash(i + vec3(1,0,1)), f.x),
          mix(hash(i + vec3(0,1,1)), hash(i + vec3(1,1,1)), f.x), f.y),
      f.z);
  }
  float fbm(vec3 p) {
    float v = 0.0;
    float a = 0.55;
    for (int i = 0; i < 3; i++) {
      v += a * noise(p);
      p = p * 2.03 + vec3(11.0, 7.0, 13.0);
      a *= 0.5;
    }
    return v;
  }

  void main() {
    if (gl_FrontFacing) discard;
    vec3 ro = cameraPosition;
    vec3 rd = normalize(vWorld - ro);
    vec3 oc = ro - uCenter;

    float a = dot(rd.xz, rd.xz);
    float b = 2.0 * dot(oc.xz, rd.xz);
    float c = dot(oc.xz, oc.xz) - uRadius * uRadius;
    float disc = b * b - 4.0 * a * c;
    if (disc < 0.0 || abs(a) < 1e-5) discard;
    float sq = sqrt(disc);
    float t0 = (-b - sq) / (2.0 * a);
    float t1 = (-b + sq) / (2.0 * a);

    float ty0 = (0.0 - ro.y) / rd.y;
    float ty1 = (uHeight - ro.y) / rd.y;
    float ymin = min(ty0, ty1);
    float ymax = max(ty0, ty1);
    if (abs(rd.y) < 1e-5) { ymin = -100.0; ymax = 100.0; }
    t0 = max(t0, ymin);
    t1 = min(t1, ymax);
    t0 = max(t0, 0.0);
    t1 = min(t1, length(vWorld - ro));
    if (t1 <= t0 + 0.01) discard;

    float dt = (t1 - t0) / 56.0;
    float alpha = 0.0;
    vec3 col = vec3(0.0);
    float shrink = mix(1.0, 0.55, uCollapse);

    for (int i = 0; i < 56; i++) {
      if (alpha > 0.94) break;
      float t = t0 + dt * (float(i) + 0.5);
      vec3 p = ro + rd * t;
      vec3 q = p - uCenter;
      float yN = q.y / uHeight;
      if (yN < 0.0 || yN > 1.0) continue;
      float rN = length(q.xz) / uRadius;
      if (rN > 1.02) continue;
      float ang = atan(q.z, q.x);

      float yEff = yN / mix(1.0, 0.82, uCollapse);
      float rEff = rN / shrink;

      float funnel = mix(1.0, 0.30, smoothstep(0.0, 1.0, yEff));
      float topEdge = 0.70 + 0.10 * sin(ang * 6.0 + uTime * 0.55) + 0.045 * sin(ang * 13.0 - uTime * 1.1);
      float topMask = smoothstep(topEdge + 0.10, topEdge - 0.02, yEff);
      float strand = pow(0.5 + 0.5 * sin(ang * 9.0 + yEff * 9.0 - uTime * 2.4 + fbm(q * 1.8) * 4.0), 3.0);
      float arms = pow(0.5 + 0.5 * sin(ang * 3.0 + yEff * 4.5 - uTime * 1.9), 5.0);

      float wall = exp(-pow((rEff - funnel * 0.86) / 0.14, 2.0)) * (0.28 + 0.72 * strand);
      float crown = exp(-pow((rEff - 0.80) / 0.085, 2.0));
      crown *= smoothstep(0.28, 0.5, yEff) * (1.0 - smoothstep(topEdge - 0.12, topEdge, yEff));
      crown *= 0.30 + 0.70 * pow(0.5 + 0.5 * sin(ang * 6.0 + uTime * 0.4), 2.0);
      float ribbon = exp(-pow((rEff - 0.44 - 0.12 * sin(ang * 2.0 + yEff * 5.0 - uTime * 2.1)) / 0.05, 2.0));
      ribbon *= smoothstep(0.0, 0.18, yEff);
      float armD = arms * exp(-pow((rEff - (0.36 + 0.30 * yEff)) / 0.16, 2.0)) * (0.6 + 0.4 * yEff);
      float core = exp(-pow(rEff / 0.18, 2.0)) * smoothstep(0.0, 0.45, yEff);

      float n = fbm(q * 1.7 + vec3(0.0, uTime * 0.4, 0.0));
      float density = (wall * 0.20 + crown * 0.55 + ribbon * 0.20 + armD * 0.18 + core * 0.45);
      density *= 0.45 + 0.55 * n;
      density *= topMask * smoothstep(0.0, 0.06, yN) * smoothstep(1.0, 0.94, yN);
      density *= smoothstep(1.02, 0.86, rN);

      float foam = smoothstep(0.58, 0.84, fbm(q * 4.6 + vec3(0.0, uTime * 0.9, 0.0)));
      foam *= smoothstep(0.20, 0.85, yEff) * (0.45 + 0.55 * strand);

      vec3 deep = vec3(0.010, 0.16, 0.28);
      vec3 aqua = vec3(0.28, 0.82, 1.0);
      vec3 white = vec3(0.88, 1.0, 1.0);
      vec3 cc = mix(deep, aqua, clamp(yEff * 0.7 + ribbon * 0.6 + crown * 0.35 + armD * 0.3, 0.0, 1.0));
      cc = mix(cc, white, clamp(foam * 0.65 + crown * 0.12, 0.0, 1.0));
      cc *= 1.0 + 0.30 * crown;

      float da = density * dt * 0.30 * uIntensity;
      da = min(da, 0.26);
      col += (1.0 - alpha) * cc * da;
      alpha += (1.0 - alpha) * da;
    }

    if (alpha < 0.003) discard;
    gl_FragColor = vec4(col / max(alpha, 0.0001), clamp(alpha, 0.0, 0.92));
  }
`;

BABYLON.Effect.ShadersStore['vortexVertexShader'] = vortexVertex;
BABYLON.Effect.ShadersStore['vortexFragmentShader'] = vortexFragment;

const vortexMat = new BABYLON.ShaderMaterial('vortexMat', scene, {
  vertex: 'vortex',
  fragment: 'vortex',
}, {
  attributes: ['position'],
  uniforms: [
    'world', 'worldViewProjection', 'cameraPosition',
    'uCenter', 'uRadius', 'uHeight', 'uTime', 'uIntensity', 'uCollapse',
  ],
  needAlphaBlending: true,
});
vortexMat.backFaceCulling = false;
vortexMat.alphaMode = BABYLON.Engine.ALPHA_COMBINE;
vortexMat.disableDepthWrite = true;
vortexMat.setVector3('uCenter', new BABYLON.Vector3(CENTER.x, 0, -0.35));
vortexMat.setFloat('uRadius', 1.30);
vortexMat.setFloat('uHeight', 3.55);
vortexMat.setFloat('uIntensity', 0);
vortexMat.setFloat('uCollapse', 0);
vortexMat.setFloat('uTime', 0);

const vortex = BABYLON.MeshBuilder.CreateCylinder('vortex', {
  height: 4.4,
  diameterTop: 4.0,
  diameterBottom: 4.0,
  tessellation: 64,
  cap: BABYLON.Mesh.NO_CAP,
  sideOrientation: BABYLON.Mesh.FRONTSIDE,
}, scene);
vortex.position.set(CENTER.x, 2.2, -0.35);
vortex.material = vortexMat;
vortex.isPickable = false;
vortex.alphaIndex = 0;

// Ground ring (thin bright lip).
const ring = BABYLON.MeshBuilder.CreateTorus('releaseRing', {
  diameter: 5.6,
  thickness: 0.035,
  tessellation: 160,
}, scene);
ring.rotation.x = Math.PI / 2;
ring.position.set(CENTER.x, 0.025, CENTER.z);
const ringMat = new BABYLON.StandardMaterial('releaseRingMat', scene);
ringMat.disableLighting = true;
ringMat.emissiveColor = new BABYLON.Color3(0.4, 0.95, 1.0);
ringMat.alpha = 0;
ring.material = ringMat;
ring.isPickable = false;
ring.alphaIndex = 2;

// ---------------------------------------------------------------------------
// Foam particles
// ---------------------------------------------------------------------------
function makeSoftTexture(name, size = 64) {
  const tex = new BABYLON.DynamicTexture(name, { width: size, height: size }, scene, false);
  const ctx = tex.getContext();
  const g = ctx.createRadialGradient(size / 2, size / 2, 0, size / 2, size / 2, size / 2);
  g.addColorStop(0, 'rgba(255,255,255,1)');
  g.addColorStop(0.32, 'rgba(190,245,255,0.70)');
  g.addColorStop(0.72, 'rgba(120,220,255,0.18)');
  g.addColorStop(1, 'rgba(120,220,255,0)');
  ctx.fillStyle = g;
  ctx.fillRect(0, 0, size, size);
  tex.update();
  tex.hasAlpha = true;
  return tex;
}

const softDot = makeSoftTexture('softDot');
const foam = new BABYLON.ParticleSystem('foam', 600, scene);
foam.particleTexture = foamTex;
foam.emitter = new BABYLON.Vector3(CENTER.x, 0.12, CENTER.z);
foam.createCylinderEmitter(2.65, 0.1, 0.92, 0.35);
foam.minSize = 0.018;
foam.maxSize = 0.085;
foam.minLifeTime = 0.55;
foam.maxLifeTime = 1.45;
foam.emitRate = 0;
foam.color1 = new BABYLON.Color4(0.60, 0.96, 1.0, 0.65);
foam.color2 = new BABYLON.Color4(0.28, 0.76, 1.0, 0.42);
foam.colorDead = new BABYLON.Color4(0.1, 0.4, 0.6, 0.0);
foam.blendMode = BABYLON.ParticleSystem.BLENDMODE_ADD;
foam.gravity = new BABYLON.Vector3(0, 0.9, 0);
foam.direction1 = new BABYLON.Vector3(-0.12, 0.35, -0.12);
foam.direction2 = new BABYLON.Vector3(0.12, 1.05, 0.12);
foam.minEmitPower = 0.22;
foam.maxEmitPower = 0.8;
foam.updateSpeed = 0.016;
foam.start();

const mist = new BABYLON.ParticleSystem('mist', 500, scene);
mist.particleTexture = softDot;
mist.emitter = new BABYLON.Vector3(CENTER.x, 0.15, CENTER.z);
mist.createCylinderEmitter(2.72, 2.25, 0.78, 0.28);
mist.minSize = 0.055;
mist.maxSize = 0.20;
mist.minLifeTime = 1.0;
mist.maxLifeTime = 2.1;
mist.emitRate = 0;
mist.color1 = new BABYLON.Color4(0.30, 0.78, 1.0, 0.20);
mist.color2 = new BABYLON.Color4(0.14, 0.52, 0.85, 0.12);
mist.colorDead = new BABYLON.Color4(0.05, 0.25, 0.4, 0.0);
mist.blendMode = BABYLON.ParticleSystem.BLENDMODE_ADD;
mist.gravity = new BABYLON.Vector3(0, 0.18, 0);
mist.direction1 = new BABYLON.Vector3(-0.25, 0.1, -0.25);
mist.direction2 = new BABYLON.Vector3(0.25, 0.5, 0.25);
mist.minEmitPower = 0.12;
mist.maxEmitPower = 0.45;
mist.updateSpeed = 0.016;
mist.start();

// ---------------------------------------------------------------------------
// Bubbles + formation
// ---------------------------------------------------------------------------
const sceneRTT = new BABYLON.RenderTargetTexture('sceneRTT', {
  width: engine.getRenderWidth(),
  height: engine.getRenderHeight(),
}, scene, {
  generateMipMaps: false,
  doNotChangeAspectRatio: true,
  type: BABYLON.Constants.TEXTURETYPE_UNSIGNED_BYTE,
  samplingMode: BABYLON.Texture.BILINEAR_SAMPLINGMODE,
  generateDepthBuffer: true,
  generateStencilBuffer: false,
});
sceneRTT.activeCamera = camera;
sceneRTT.renderList = refractionMeshes;
sceneRTT.refreshRate = 1;
sceneRTT.clearColor = scene.clearColor;
scene.customRenderTargets.push(sceneRTT);

// ---------------------------------------------------------------------------
// Crown of refractive water blades
// ---------------------------------------------------------------------------
const crownRoot = new BABYLON.TransformNode('crownRoot', scene);
crownRoot.position.set(CENTER.x, 0, CENTER.z);

const crestMat = new BABYLON.StandardMaterial('crestMat', scene);
crestMat.disableLighting = true;
crestMat.emissiveColor = new BABYLON.Color3(0.45, 0.86, 0.96);
crestMat.alpha = 0;

const beadMat = new BABYLON.StandardMaterial('beadMat', scene);
beadMat.disableLighting = true;
beadMat.emissiveColor = new BABYLON.Color3(0.70, 0.98, 1.0);
beadMat.alpha = 0;

const ribbonVertex = /* glsl */`
  precision highp float;
  attribute vec3 position;
  attribute vec3 normal;
  attribute vec2 uv;
  uniform mat4 world;
  uniform mat4 worldViewProjection;
  uniform float uTime;
  uniform float uWobble;
  uniform float uPhase;
  varying vec3 vWorld;
  varying vec3 vNormal;
  varying vec2 vUv;
  void main() {
    vec3 p = position + normal * (
      sin(uTime * 2.2 + position.y * 6.0 + uPhase) * 0.65 +
      sin(uTime * 1.6 + uv.x * 8.0 - position.y * 4.0) * 0.35
    ) * uWobble;
    vec4 wp = world * vec4(p, 1.0);
    vWorld = wp.xyz;
    vNormal = normalize((world * vec4(normal, 0.0)).xyz);
    vUv = uv;
    gl_Position = worldViewProjection * vec4(p, 1.0);
  }
`;

const ribbonFragment = /* glsl */`
  precision highp float;
  varying vec3 vWorld;
  varying vec3 vNormal;
  varying vec2 vUv;
  uniform vec3 cameraPosition;
  uniform float uTime;
  uniform float uOpacity;

  void main() {
    vec3 N = normalize(vNormal);
    if (!gl_FrontFacing) N = -N;
    vec3 V = normalize(cameraPosition - vWorld);
    float fres = pow(1.0 - abs(dot(N, V)), 2.1);

    float flow = sin(vUv.y * 24.0 - uTime * 2.7 + sin(vUv.x * 8.0 + uTime) * 2.2);
    float vein = smoothstep(0.58, 0.96, sin(vUv.x * 20.0 + sin(vUv.y * 7.0 - uTime * 1.7) * 2.6) * 0.5 + 0.5);
    float foam = smoothstep(0.62, 0.94, flow * 0.5 + 0.5) * smoothstep(0.50, 0.95, vUv.y);
    foam *= 0.35 + 0.65 * vein;

    float top = smoothstep(0.82, 0.995, vUv.y);
    float side = smoothstep(0.10, 0.0, min(vUv.x, 1.0 - vUv.x));
    vec3 L = normalize(vec3(-0.35, 0.75, 0.55));
    float spec = pow(max(dot(reflect(-V, N), L), 0.0), 38.0);

    vec3 deep = vec3(0.006, 0.15, 0.30);
    vec3 aqua = vec3(0.08, 0.56, 0.84);
    vec3 col = mix(deep, aqua, clamp(0.20 + 0.55 * vUv.y + 0.18 * fres, 0.0, 1.0));
    col *= 0.80 + 0.20 * smoothstep(0.0, 0.55, vUv.y);
    col += vec3(0.32, 0.82, 1.0) * fres * 0.55;
    col += vec3(0.92, 1.0, 1.0) * spec * 0.70;
    col = mix(col, vec3(0.78, 0.98, 1.0), clamp(foam * 0.32 + top * 0.50 + side * 0.22, 0.0, 1.0));

    float alpha = clamp(0.62 + fres * 0.24 + foam * 0.12 + top * 0.16 + side * 0.12, 0.0, 0.96) * uOpacity;
    gl_FragColor = vec4(col, clamp(alpha, 0.0, 0.86));
  }
`;

BABYLON.Effect.ShadersStore['ribbonVertexShader'] = ribbonVertex;
BABYLON.Effect.ShadersStore['ribbonFragmentShader'] = ribbonFragment;

const ribbonMat = new BABYLON.ShaderMaterial('ribbonMat', scene, {
  vertex: 'ribbon',
  fragment: 'ribbon',
}, {
  attributes: ['position', 'normal', 'uv'],
  uniforms: [
    'world', 'worldViewProjection', 'cameraPosition',
    'uTime', 'uOpacity', 'uWobble', 'uPhase',
  ],
  needAlphaBlending: true,
});
ribbonMat.backFaceCulling = false;
ribbonMat.alphaMode = BABYLON.Engine.ALPHA_COMBINE;
ribbonMat.disableDepthWrite = true;
ribbonMat.setFloat('uTime', 0);
ribbonMat.setFloat('uOpacity', 0);
ribbonMat.setFloat('uWobble', 0.014);
ribbonMat.setFloat('uPhase', 0);

const crownRibbons = [];
const RIBBON_COUNT = 10;
const RIBBON_NU = 10;
const RIBBON_NV = 24;

for (let ri = 0; ri < RIBBON_COUNT; ri++) {
  const baseAng = (ri / RIBBON_COUNT) * Math.PI * 2;
  const baseH = 0.94 + 0.07 * Math.sin(baseAng * 3.0 + 0.7);
  const positions = [];
  const uvs = [];
  const indices = [];
  const topPts = [];

  for (let iu = 0; iu <= RIBBON_NU; iu++) {
    const u = iu / RIBBON_NU;
    const height = baseH * (0.72 + 0.28 * Math.pow(Math.max(0, Math.sin(Math.PI * u)), 0.50))
      + 0.035 * Math.sin(u * Math.PI * 3.0 + ri);
    for (let iv = 0; iv <= RIBBON_NV; iv++) {
      const v = iv / RIBBON_NV;
      const ang = baseAng + 0.08 * v + 0.025 * Math.sin(v * 5.0 + ri * 1.7);
      const centerR = 2.86 + 0.08 * Math.sin(v * Math.PI) - 0.14 * v * v;
      const width = (0.94 + 0.06 * Math.sin(v * Math.PI)) * (1.0 - 0.22 * v * v);
      const rr = centerR + (u - 0.5) * width + Math.sin(Math.PI * u) * 0.055 * (1.0 - v * 0.35);
      const px = Math.cos(ang) * rr;
      const pz = Math.sin(ang) * rr;
      const py = 0.035 + v * height;
      positions.push(px, py, pz);
      uvs.push(u, v);
      if (iv === RIBBON_NV) topPts.push(new BABYLON.Vector3(px, py, pz));
    }
  }

  for (let iu = 0; iu < RIBBON_NU; iu++) {
    for (let iv = 0; iv < RIBBON_NV; iv++) {
      const a0 = iu * (RIBBON_NV + 1) + iv;
      const b0 = a0 + RIBBON_NV + 1;
      indices.push(a0, b0, a0 + 1, a0 + 1, b0, b0 + 1);
    }
  }

  const normals = [];
  BABYLON.VertexData.ComputeNormals(positions, indices, normals);
  const vd = new BABYLON.VertexData();
  vd.positions = positions;
  vd.indices = indices;
  vd.uvs = uvs;
  vd.normals = normals;

  const mesh = new BABYLON.Mesh(`waterBlade${ri}`, scene);
  vd.applyToMesh(mesh);
  mesh.parent = crownRoot;
  mesh.material = ribbonMat;
  mesh.isPickable = false;
  mesh.alphaIndex = 1;
  mesh.scaling.y = 0.02;

  const crest = BABYLON.MeshBuilder.CreateTube(`crest${ri}`, {
    path: topPts,
    radius: 0.006,
    tessellation: 6,
    cap: BABYLON.Mesh.NO_CAP,
  }, scene);
  crest.parent = mesh;
  crest.material = crestMat;
  crest.isPickable = false;
  crest.alphaIndex = 2;

  for (let k = 1; k <= 5; k++) {
    const p = topPts[Math.floor((k / 6) * (topPts.length - 1))];
    const bead = BABYLON.MeshBuilder.CreateSphere(`crestBead${ri}_${k}`, {
      diameter: 0.038 + 0.032 * (0.5 + 0.5 * Math.sin(k * 2.3 + ri)),
      segments: 8,
    }, scene);
    bead.position.copyFrom(p);
    bead.parent = mesh;
    bead.material = beadMat;
    bead.isPickable = false;
    bead.alphaIndex = 2;
  }

  crownRibbons.push({ mesh, crest, baseAng, delay: 0.02 + ri * 0.020 });
}

// Thin spiral filaments outside the blades.
const filamentMat = new BABYLON.StandardMaterial('filamentMat', scene);
filamentMat.disableLighting = true;
filamentMat.emissiveColor = new BABYLON.Color3(0.28, 0.82, 1.0);
filamentMat.alpha = 0;
const crownFilaments = [];
for (let s = 0; s < 3; s++) {
  const pts = [];
  for (let j = 0; j <= 48; j++) {
    const t = j / 48;
    const a = s * (Math.PI * 2 / 3) + t * Math.PI * 2.2;
    const r = 2.72 - 0.20 * t + 0.06 * Math.sin(t * Math.PI * 4.0);
    pts.push(new BABYLON.Vector3(
      Math.cos(a) * r,
      0.06 + t * 1.48,
      Math.sin(a) * r,
    ));
  }
  const tube = BABYLON.MeshBuilder.CreateTube(`filament${s}`, {
    path: pts,
    radius: 0.009,
    tessellation: 6,
    cap: BABYLON.Mesh.NO_CAP,
  }, scene);
  tube.parent = crownRoot;
  tube.material = filamentMat;
  tube.isPickable = false;
  tube.isVisible = false;
  tube.alphaIndex = 2;
  crownFilaments.push(tube);
}

const bubbleVertex = /* glsl */`
  precision highp float;
  attribute vec3 position;
  attribute vec3 normal;
  attribute vec2 uv;
  uniform mat4 world;
  uniform mat4 worldViewProjection;
  uniform float uTime;
  uniform float uWobble;
  varying vec3 vWorld;
  varying vec3 vNormal;
  varying vec2 vUv;
  void main() {
    vec3 p = position + normal * (
      sin(uTime * 2.7 + position.y * 9.0 + position.x * 4.0) * 0.55 +
      sin(uTime * 1.9 + position.z * 7.0 - position.y * 3.0) * 0.45
    ) * uWobble;
    vec4 wp = world * vec4(p, 1.0);
    vWorld = wp.xyz;
    vNormal = normalize((world * vec4(normal, 0.0)).xyz);
    vUv = uv;
    gl_Position = worldViewProjection * vec4(p, 1.0);
  }
`;

const bubbleFragment = /* glsl */`
  precision highp float;
  varying vec3 vWorld;
  varying vec3 vNormal;
  varying vec2 vUv;
  uniform vec3 cameraPosition;
  uniform sampler2D uSceneTex;
  uniform vec2 uResolution;
  uniform float uTime;
  uniform float uOpacity;
  uniform float uRefract;

  void main() {
    vec3 N = normalize(vNormal);
    vec3 V = normalize(cameraPosition - vWorld);
    float fres = pow(1.0 - abs(dot(N, V)), 2.35);

    vec2 uv = gl_FragCoord.xy / uResolution;
    vec2 off = N.xy * uRefract * (0.28 + 0.72 * fres);
    vec3 bg = texture2D(uSceneTex, clamp(uv + off, vec2(0.001), vec2(0.999))).rgb;

    float iridT = fres * 2.3 + N.y * 0.55 + uTime * 0.04;
    vec3 irid = 0.5 + 0.5 * cos(6.28318 * (vec3(0.0, 0.34, 0.67) + iridT));
    vec3 col = mix(bg, irid, 0.05 + 0.15 * fres);
    col = mix(col, vec3(0.18, 0.62, 1.0), 0.09 + 0.14 * fres);
    col += vec3(0.36, 0.88, 1.0) * fres * 0.62;

    float lower = smoothstep(0.35, 0.95, -N.y);
    col = mix(col, vec3(0.05, 0.30, 0.55), lower * 0.18);

    float alpha = clamp(0.16 + fres * 0.56 + lower * 0.12, 0.0, 0.90) * uOpacity;
    gl_FragColor = vec4(col, alpha);
  }
`;

BABYLON.Effect.ShadersStore['bubbleVertexShader'] = bubbleVertex;
BABYLON.Effect.ShadersStore['bubbleFragmentShader'] = bubbleFragment;

const bubbles = [];
const bubbleMatCache = [];
for (let i = 0; i < 3; i++) {
  const mat = new BABYLON.ShaderMaterial(`bubbleMat${i}`, scene, {
    vertex: 'bubble',
    fragment: 'bubble',
  }, {
    attributes: ['position', 'normal', 'uv'],
    uniforms: [
      'world', 'worldViewProjection', 'cameraPosition',
      'uSceneTex', 'uResolution', 'uTime', 'uOpacity', 'uRefract',
    ],
    needAlphaBlending: true,
  });
  mat.backFaceCulling = false;
  mat.alphaMode = BABYLON.Engine.ALPHA_COMBINE;
  mat.disableDepthWrite = true;
  mat.setTexture('uSceneTex', sceneRTT);
  mat.setVector2('uResolution', new BABYLON.Vector2(engine.getRenderWidth(), engine.getRenderHeight()));
  mat.setFloat('uTime', 0);
  mat.setFloat('uOpacity', 0);
  mat.setFloat('uRefract', 0.035);
  bubbleMatCache.push(mat);

  const bubble = BABYLON.MeshBuilder.CreateSphere(`bubble${i}`, {
    diameter: 1.95,
    segments: 48,
  }, scene);
  bubble.position.set(ALLY_POS[i].x, 0.95, ALLY_POS[i].z);
  bubble.material = mat;
  bubble.isPickable = false;
  bubble.alphaIndex = 3;
  bubble.isVisible = false;
  bubbles.push(bubble);

  const seed = BABYLON.MeshBuilder.CreateSphere(`seed${i}`, { diameter: 0.12, segments: 16 }, scene);
  seed.position.copyFrom(bubble.position);
  const sm = new BABYLON.StandardMaterial(`seedMat${i}`, scene);
  sm.disableLighting = true;
  sm.emissiveColor = new BABYLON.Color3(0.55, 0.98, 1.0);
  sm.alpha = 0;
  seed.material = sm;
  seed.isPickable = false;
  seed.isVisible = false;
  bubble.metadata = { seed };
}

// Streams from the vortex to each ally during formation.
const streams = [];
for (let i = 0; i < 3; i++) {
  const start = new BABYLON.Vector3(CENTER.x, 2.2, CENTER.z);
  const end = new BABYLON.Vector3(ALLY_POS[i].x, 1.0, ALLY_POS[i].z);
  const mid = BABYLON.Vector3.Lerp(start, end, 0.45).add(new BABYLON.Vector3(0, 0.55, 0));
  const path = [];
  for (let k = 0; k <= 24; k++) {
    const t = k / 24;
    const p = BABYLON.Vector3.Lerp(start, end, t);
    p.y += Math.sin(t * Math.PI) * 0.55;
    const side = new BABYLON.Vector3(-(end.z - start.z), 0, end.x - start.x).normalize();
    p.addInPlace(side.scale(Math.sin(t * Math.PI * 2) * 0.18));
    path.push(p);
  }
  const tube = BABYLON.MeshBuilder.CreateTube(`stream${i}`, {
    path,
    radius: 0.014,
    tessellation: 8,
    cap: BABYLON.Mesh.NO_CAP,
  }, scene);
  const mat = new BABYLON.StandardMaterial(`streamMat${i}`, scene);
  mat.disableLighting = true;
  mat.emissiveColor = new BABYLON.Color3(0.20, 0.70, 0.95);
  mat.alpha = 0;
  tube.material = mat;
  tube.isPickable = false;
  tube.isVisible = false;
  tube.alphaIndex = 2;
  streams.push({ tube, mat });
}

// ---------------------------------------------------------------------------
// Post
// ---------------------------------------------------------------------------
const pipeline = new BABYLON.DefaultRenderingPipeline('pipeline', true, scene, [camera]);
pipeline.samples = 4;
pipeline.fxaaEnabled = true;
pipeline.bloomEnabled = true;
pipeline.bloomThreshold = 0.72;
pipeline.bloomWeight = 0.46;
pipeline.bloomKernel = 64;
pipeline.bloomScale = 0.55;
pipeline.imageProcessingEnabled = true;
pipeline.imageProcessing.contrast = 1.08;
pipeline.imageProcessing.exposure = 1.16;
pipeline.imageProcessing.vignetteEnabled = true;
pipeline.imageProcessing.vignetteWeight = 2.4;
pipeline.imageProcessing.vignetteStretch = 0.3;
pipeline.chromaticAberrationEnabled = true;
pipeline.chromaticAberration.aberrationAmount = 7;
pipeline.chromaticAberration.radialIntensity = 0.6;
pipeline.grainEnabled = true;
pipeline.grain.intensity = 2.0;
pipeline.grain.animated = true;

// ---------------------------------------------------------------------------
// Timeline
// ---------------------------------------------------------------------------
const state = { t: 0, playing: true, speed: 1, loaded: false };
const ui = {
  fill: document.getElementById('fill'),
  phase: document.getElementById('phase'),
  time: document.getElementById('time'),
  play: document.getElementById('play'),
  speed: document.getElementById('speed'),
  replay: document.getElementById('replay'),
  loading: document.getElementById('loading'),
};

const smooth = (a, b, x) => {
  const t = Math.max(0, Math.min(1, (x - a) / (b - a)));
  return t * t * (3 - 2 * t);
};
const easeOutCubic = (t) => 1 - Math.pow(1 - t, 3);
const easeOutBack = (t) => {
  const c = 1.70158;
  const u = t - 1;
  return 1 + (c + 1) * u * u * u + c * u * u;
};

function setPhaseLabel(label) {
  if (ui.phase.textContent !== label) ui.phase.textContent = label;
}

function updateTimeline(t) {
  const wind = smooth(0, WINDUP_END, t);
  const form = smooth(WINDUP_END, FORM_END, t);
  const settle = smooth(FORM_END, DURATION, t);

  vortexMat.setFloat('uTime', t);
  vortexMat.setFloat('uIntensity', 1.15 * wind * (1 - 0.9 * form) * (1 - settle * 0.2));
  vortexMat.setFloat('uCollapse', smooth(WINDUP_END, FORM_END + 0.1, t) * 0.8);

  const crownFade = 1 - smooth(WINDUP_END, WINDUP_END + 0.58, t);
  crownRoot.rotation.y = 0.12 + t * 0.52;
  ribbonMat.setFloat('uTime', t);
  ribbonMat.setFloat('uOpacity', (0.32 + 0.68 * wind) * crownFade);
  ribbonMat.setFloat('uWobble', 0.006 + 0.012 * (1 - wind));
  crestMat.alpha = (0.08 + 0.32 * wind) * crownFade;
  beadMat.alpha = (0.20 + 0.72 * wind) * crownFade;
  filamentMat.alpha = 0;

  for (const rb of crownRibbons) {
    const e = easeOutCubic(Math.max(0, Math.min(1, (wind - rb.delay) / 0.55)));
    rb.mesh.scaling.y = (0.03 + 0.97 * e) * crownFade;
  }

  const ringScale = 1.04 - 0.10 * wind + 0.32 * form;
  ring.scaling.setAll(ringScale);
  ringMat.alpha = 0.12 + 0.65 * wind * (1 - form * 0.85);

  foam.emitRate = 64 * wind * (1 - form);
  foam.minEmitPower = 0.22 + 0.55 * wind;
  foam.maxEmitPower = 0.8 + 1.1 * wind;
  mist.emitRate = 34 * wind * (1 - form * 0.9);

  for (let i = 0; i < bubbles.length; i++) {
    const bubble = bubbles[i];
    const seed = bubble.metadata.seed;
    const local = Math.max(0, Math.min(1, (form - i * 0.035) / (1 - i * 0.02)));
    const scale = 0.035 + 0.965 * Math.max(0, easeOutBack(local));
    const visible = form > 0.001;
    bubble.isVisible = visible;
    seed.isVisible = visible;
    if (visible) {
      bubble.scaling.setAll(scale);
      const mat = bubbleMatCache[i];
      mat.setFloat('uTime', t);
      mat.setFloat('uOpacity', Math.min(1, local * 1.6) * (1 - settle * 0.12));
      mat.setFloat('uWobble', 0.006 + 0.010 * (1 - local));
      seed.scaling.setAll(Math.max(0.001, (1 - local) * 1.3 + 0.1));
      seed.material.alpha = Math.max(0, 1 - local * 1.5);
    }

    const st = streams[i];
    st.tube.isVisible = false;
    st.mat.alpha = 0;
  }

  if (t < WINDUP_END) setPhaseLabel('WIND-UP');
  else if (t < FORM_END) setPhaseLabel('FORMAÇÃO');
  else setPhaseLabel('ATIVO');

  ui.fill.style.width = `${(t / DURATION) * 100}%`;
  ui.time.textContent = `${t.toFixed(2)} s`;
}

function replay() {
  state.t = 0;
  state.playing = true;
  ui.play.textContent = 'PAUSE';
  updateTimeline(0);
}
function togglePlay() {
  state.playing = !state.playing;
  ui.play.textContent = state.playing ? 'PAUSE' : 'PLAY';
}
function toggleSpeed() {
  state.speed = state.speed === 1 ? 0.25 : 1;
  ui.speed.textContent = state.speed === 1 ? '0.25×' : '1×';
}

ui.replay.addEventListener('click', replay);
ui.play.addEventListener('click', togglePlay);
ui.speed.addEventListener('click', toggleSpeed);

// ---------------------------------------------------------------------------
// Boot
// ---------------------------------------------------------------------------
updateTimeline(0);

loadSlimes().then(() => {
  // Rebuild the RTT list now that slimes exist.
  sceneRTT.renderList = refractionMeshes.slice();
  state.loaded = true;
  ui.loading.classList.add('hidden');
  // Start with the formation paused at a hero frame? Play the full beat.
  replay();
}).catch((err) => {
  console.error(err);
  ui.loading.textContent = 'ERRO AO CARREGAR';
});

engine.runRenderLoop(() => {
  const dt = Math.min(engine.getDeltaTime() / 1000, 0.05) * state.speed;
  if (state.playing && state.loaded) {
    state.t = Math.min(DURATION, state.t + dt);
    if (state.t >= DURATION) state.playing = false;
    updateTimeline(state.t);
  }
  scene.render();
});

window.addEventListener('resize', () => {
  engine.resize();
  const w = engine.getRenderWidth();
  const h = engine.getRenderHeight();
  sceneRTT.resize({ width: w, height: h });
  for (const m of bubbleMatCache) m.setVector2('uResolution', new BABYLON.Vector2(w, h));
});

window.__lab = {
  scene,
  camera,
  engine,
  state,
  bubbles,
  vortex,
  replay,
  setSpeed: (v) => { state.speed = v; ui.speed.textContent = v === 1 ? '0.25×' : '1×'; },
  setTime: (t) => {
    state.t = Math.max(0, Math.min(DURATION, t));
    state.playing = false;
    ui.play.textContent = 'PLAY';
    updateTimeline(state.t);
    scene.render();
  },
  snap: () => {
    scene.render();
    return canvas.toDataURL('image/png');
  },
  snapJPEG: (q = 0.92) => {
    scene.render();
    return canvas.toDataURL('image/jpeg', q);
  },
};
