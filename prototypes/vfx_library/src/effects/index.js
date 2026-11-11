import {
  createVortex, createFunnel, createSpiralRibbon, createHelix, createDissolve,
} from './forms.js';
import {
  createThrust, createSpeedLines, createMotionTrail, createAura,
  createDustTrail, createScuff, createGroundScratch,
} from './motion.js';
import {
  createShockwave, createCrown, createBlastCone, createFracture,
  createFlipbook, createSparks, createDebris,
} from './impacts.js';
import {
  createPrelude, createAnimeDash, createPunchyImpact,
  createEnergyHelix, createVortexStudy, createStylizedSlash,
} from './composites.js';
import {
  createVortexRef, createAuraRef, createDustRef, createShockwaveRef,
  createCrownRef, REF_DEFAULTS,
} from './flagship.js';
import { createSlash, SLASH_DEFAULTS } from './slash.js';

/** Referência-âncora de cada flagship (nota local, não é decisão). */
const REF = {
  vortex: 'Genshin Impact / Honkai: Star Rail — portal de energia',
  aura: 'Dragon Ball FighterZ / Sparking! Zero — power-up',
  dust: 'Guilty Gear Strive / DBFZ — poeira de dash',
  shockwave: 'DBFZ / Sparking! Zero — onda de impacto',
  crown: 'DBFZ / Guilty Gear Strive — impacto pesado',
  slash: 'Lucie Travaux; Mourad El Ghali; Ali’s Sketchbook (quadros reais)',
};

export const CATEGORIES = ['Todos', 'Formas', 'Movimento', 'Impacto', 'Demonstrações', 'Extra'];

/** c(key, label, grupo, min, max, step, def, rebuild) */
const c = (key, label, group, min, max, step, def, rebuild = false) =>
  ({ key, label, group, min, max, step, def, rebuild });
/** col(key, label, grupo, def) — seletor de cor */
const col = (key, label, group, def) => ({ key, label, group, type: 'color', def });

const statePrototype = 'Protótipo funcional';
const LIMITS_COMMON = 'Lab em Three.js/WebGL; a versão Godot 4.7 (GL Compatibility) precisa de shader equivalente, sem decals nem GPUParticles.';

export const EFFECTS = [
  // ── FAMÍLIA A ───────────────────────────────────────────────────────────────
  {
    id: 'vortex', lib: 'LIB-VFX-01', name: 'Vortex Mesh', family: 'A', category: 'Formas',
    duration: 6, create: createVortexRef, status: statePrototype,
    desc: 'Portal de energia: funil com ruído FBM, aro quente, disco espiral e detritos orbitando. Referência: Genshin/HSR.',
    technique: 'Duas cascas de funil com FBM + domain warp no fragment, aro toroidal aditivo, disco espiral com ruído e 22 detritos orbitando. Cores por uniform.',
    deps: 'three (ShaderMaterial + FBM própria)',
    limits: LIMITS_COMMON + ' Sem distorção de tela/refração (exigiria render target).',
    controls: [
      c('radius', 'Boca do portal', 'Geometria', 1.4, 3.4, 0.05, REF_DEFAULTS.vortex.radius, true),
      c('height', 'Altura', 'Geometria', 2.2, 5.5, 0.05, REF_DEFAULTS.vortex.height, true),
      c('spin', 'Velocidade de giro', 'Movimento', 0.2, 2.5, 0.05, REF_DEFAULTS.vortex.spin),
      c('particles', 'Partículas', 'Material', 200, 1400, 20, REF_DEFAULTS.vortex.particles, true),
      col('deep', 'Cor profunda', 'Cores', REF_DEFAULTS.vortex.deep),
      col('mid', 'Cor média', 'Cores', REF_DEFAULTS.vortex.mid),
      col('hot', 'Cor quente', 'Cores', REF_DEFAULTS.vortex.hot),
    ],
  },
  {
    id: 'funnel', lib: 'LIB-VFX-02', name: 'Tornado / Funnel', family: 'A', category: 'Formas',
    duration: 6, create: createFunnel, status: statePrototype,
    desc: 'Volume cônico espiralado, com três camadas de twist e silhueta irregular; serve para vento, fogo ou coluna de energia.',
    technique: 'Três funnelGeometry com raios/giros diferentes, vertex shader com ondulação radial e listras longitudinais no fragment shader. Poeira emitida na base.',
    deps: 'three (ShaderMaterial com deslocamento no vertex)',
    limits: LIMITS_COMMON + ' Poeira é CPU (Points), não flipbook.',
    controls: [
      c('height', 'Altura', 'Geometria', 3.0, 6.5, 0.1, 4.6, true),
      c('width', 'Abertura', 'Geometria', 0.6, 1.8, 0.05, 1.0, true),
      c('twist', 'Torção', 'Geometria', 4, 24, 0.5, 10, true),
      c('opacity', 'Opacidade', 'Material', 0.3, 1.0, 0.05, 1.0),
    ],
  },
  {
    id: 'ribbon', lib: 'LIB-VFX-03', name: 'Spiral Ribbon', family: 'A', category: 'Formas',
    duration: 5, create: createSpiralRibbon, status: statePrototype,
    desc: 'Fita 3D percorrendo uma hélice, com largura variável, brilho correndo pela superfície e núcleo fino.',
    technique: 'ribbonGeometry ao longo de uma hélice paramétrica, com up radial por ponto (a fita fica em pé, não deitada). Shader com pulso longitudinal.',
    deps: 'three (BufferGeometry própria)',
    limits: LIMITS_COMMON,
    controls: [
      c('radius', 'Raio', 'Geometria', 0.6, 1.8, 0.05, 1.0, true),
      c('height', 'Altura', 'Geometria', 2.0, 4.5, 0.1, 3.2, true),
      c('turns', 'Voltas', 'Geometria', 1.5, 6, 0.1, 3.0, true),
      c('width', 'Largura', 'Geometria', 0.12, 0.8, 0.01, 0.55, true),
      c('flow', 'Fluxo', 'Movimento', 0.2, 2.5, 0.05, 1.0),
    ],
  },
  {
    id: 'helix', lib: 'LIB-VFX-04', name: 'Helix Cylinder', family: 'A', category: 'Formas',
    duration: 4, create: createHelix, status: statePrototype,
    desc: 'Feixe com núcleo longitudinal e três correntes helicoidais; lê de frente e de lado.',
    technique: 'TubeGeometry em CatmullRomCurve3 para cada corrente + cilindro central com shader de borda. Halo por escala da mesma geometria.',
    deps: 'three (TubeGeometry, CatmullRomCurve3)',
    limits: LIMITS_COMMON,
    controls: [
      c('radius', 'Raio', 'Geometria', 0.5, 1.5, 0.05, 0.95, true),
      c('height', 'Comprimento', 'Geometria', 2.5, 6, 0.1, 4.2, true),
      c('turns', 'Voltas', 'Geometria', 1.5, 6, 0.1, 3.2, true),
      c('thickness', 'Espessura', 'Geometria', 0.012, 0.06, 0.002, 0.028, true),
      c('speed', 'Velocidade', 'Movimento', 0.2, 2.5, 0.05, 1.0),
    ],
  },
  {
    id: 'dissolve', lib: 'LIB-VFX-05', name: 'Spiral Erosion', family: 'A', category: 'Formas',
    duration: 4.5, create: createDissolve, status: statePrototype,
    desc: 'Superfície que desaparece seguindo ruído + espiral, com borda incandescente e brasas.',
    technique: 'Shader com hash/noise 3D, campo espiral e limiar progressivo (discard). A mudança é na visibilidade da superfície, não na opacidade global.',
    deps: 'three (ShaderMaterial, TorusKnotGeometry)',
    limits: LIMITS_COMMON + ' A máscara é procedural; no Godot precisaria de textura de ruído.',
    controls: [
      c('edge', 'Borda de erosão', 'Material', 0.02, 0.35, 0.01, 0.16),
      c('spiral', 'Peso da espiral', 'Material', 0.0, 1.0, 0.05, 0.6),
      c('brightness', 'Brilho da borda', 'Material', 0.2, 2.5, 0.1, 1.2),
    ],
  },

  // ── FAMÍLIA B ───────────────────────────────────────────────────────────────
  {
    id: 'thrust', lib: 'LIB-VFX-06', name: 'Thrust Cone', family: 'B', category: 'Movimento',
    duration: 2.8, create: createThrust, status: statePrototype,
    desc: 'Cone de propulsão atrás do emissor, com bocal, listras longitudinais e poeira no rastro.',
    technique: 'Cone com coneMaterial (listras + fresnel de silhueta), anel de bocal e sprite de brilho. Percurso derivado do palco.',
    deps: 'three (CylinderGeometry aberta)',
    limits: LIMITS_COMMON + ' Sem refração de tela (exigiria Forward+).',
    controls: [
      c('length', 'Comprimento', 'Geometria', 1.2, 4.0, 0.05, 2.4, true),
      c('opening', 'Abertura', 'Geometria', 0.5, 1.8, 0.05, 1.05, true),
      c('intensity', 'Intensidade', 'Material', 0.3, 2.0, 0.05, 1.0),
    ],
  },
  {
    id: 'speedlines', lib: 'LIB-VFX-07', name: 'Speed Lines', family: 'B', category: 'Movimento',
    duration: 3.0, create: createSpeedLines, status: statePrototype,
    desc: 'Linhas de ação em volume ao redor do trajeto, com comprimentos e distâncias variados.',
    technique: 'InstancedMesh de caixas finas (não LineSegments): têm espessura e leem de qualquer ângulo. Fluxo relativo ao eixo do palco.',
    deps: 'three (InstancedMesh)',
    limits: LIMITS_COMMON,
    controls: [
      c('count', 'Quantidade', 'Geometria', 30, 180, 5, 70, true),
      c('length', 'Comprimento', 'Geometria', 0.4, 3.0, 0.05, 1.0),
      c('speed', 'Velocidade', 'Movimento', 4, 30, 0.5, 14),
    ],
  },
  {
    id: 'motiontrail', lib: 'LIB-VFX-08', name: 'Motion Trail', family: 'B', category: 'Movimento',
    duration: 3.4, create: createMotionTrail, status: statePrototype,
    desc: 'Fita contínua gerada pelo histórico real de posição do emissor; preserva a curva anterior.',
    technique: 'Anel de histórico (90 amostras) reconstruído em ribbonGeometry por frame. O scrub reencena do zero para o histórico existir.',
    deps: 'three (BufferGeometry reconstruída)',
    limits: LIMITS_COMMON + ' Reconstruir a fita a cada frame é caro para muitas instâncias; no Godot usar MeshDataTool/ImmediateMesh com orçamento.',
    controls: [
      c('width', 'Largura', 'Geometria', 0.1, 1.0, 0.01, 0.55, true),
      c('persist', 'Persistência', 'Geometria', 30, 160, 5, 120, true),
    ],
  },
  {
    id: 'aura', lib: 'LIB-VFX-09', name: 'Aura Burst', family: 'B', category: 'Movimento',
    duration: 1.6, create: createAuraRef, status: statePrototype,
    desc: 'Power-up: coluna de energia com ruído subindo, silhueta irregular, brasas e anel de impulso. Referência: DBFZ/Sparking! Zero.',
    technique: 'Cilindro aberto com deslocamento senoidal no vertex, FBM rolando no fragment, fresnel para a silhueta, 90 brasas instanciadas e anel com ruído.',
    deps: 'three (ShaderMaterial + FBM)',
    limits: LIMITS_COMMON + ' Sem GPUParticles; brasas são instâncias CPU.',
    controls: [
      c('radius', 'Raio da base', 'Geometria', 0.4, 1.6, 0.05, REF_DEFAULTS.aura.radius, true),
      c('height', 'Altura da coluna', 'Geometria', 1.2, 4.5, 0.1, REF_DEFAULTS.aura.height, true),
      c('count', 'Brasas', 'Geometria', 30, 220, 5, REF_DEFAULTS.aura.count, true),
      col('hot', 'Núcleo quente', 'Cores', REF_DEFAULTS.aura.hot),
      col('mid', 'Cor da energia', 'Cores', REF_DEFAULTS.aura.mid),
      col('ring', 'Anel de impulso', 'Cores', REF_DEFAULTS.aura.ring),
    ],
  },
  {
    id: 'dust', lib: 'LIB-VFX-10', name: 'Dust Trail', family: 'B', category: 'Movimento',
    duration: 3.2, create: createDustRef, status: statePrototype,
    desc: 'Poeira com corpo: atlas de fumaça real do projeto, billboards com 16 quadros e esteira no chão. Referência: Guilty Gear/DBFZ.',
    technique: 'InstancedBufferGeometry com aOffset/aScale/aAge + shader que escolhe a célula do atlas flipbook_smoke.png (4x4); opacidade, cor, tamanho e subida por uniform.',
    deps: 'assets/vfx/flipbook_smoke.png (recurso do projeto) + three',
    limits: LIMITS_COMMON + ' Sem iluminação real; o sombreado do atlas é fixo.',
    controls: [
      c('size', 'Tamanho', 'Material', 0.3, 2.0, 0.05, REF_DEFAULTS.dust.size),
      c('density', 'Densidade', 'Movimento', 0.4, 2.2, 0.05, REF_DEFAULTS.dust.density),
      c('rise', 'Subida', 'Movimento', 0.0, 1.5, 0.05, REF_DEFAULTS.dust.rise),
      c('opacity', 'Opacidade', 'Material', 0.1, 1.0, 0.05, REF_DEFAULTS.dust.opacity),
      col('color', 'Cor da poeira', 'Cores', REF_DEFAULTS.dust.color),
    ],
  },
  {
    id: 'scuff', lib: 'LIB-VFX-11', name: 'Brake Dust', family: 'B', category: 'Movimento',
    duration: 2.2, create: createScuff, status: statePrototype,
    desc: 'Poeira em leque na frenagem, orientada pelo movimento anterior.',
    technique: 'Leque em plano horizontal com shader de cone + jato de partículas direcionado para trás. Direção vem do eixo do palco.',
    deps: 'three (PlaneGeometry + Points)',
    limits: LIMITS_COMMON,
    controls: [
      c('spread', 'Abertura do leque', 'Geometria', 0.3, 1.2, 0.05, 0.6),
      c('power', 'Impulso', 'Movimento', 1.5, 8, 0.1, 4.0),
      c('size', 'Tamanho', 'Material', 0.25, 1.0, 0.05, 0.55),
    ],
  },
  {
    id: 'scratch', lib: 'LIB-VFX-12', name: 'Ground Scratch', family: 'B', category: 'Movimento',
    duration: 2.8, create: createGroundScratch, status: statePrototype,
    desc: 'Sulcos alongados rentes ao chão, com três linhas irregulares e fragmentos.',
    technique: 'Plano com shader de sulcos (3 frequências) revelado por progresso + InstancedMesh de pedras. Sem decal.',
    deps: 'three (PlaneGeometry + InstancedMesh)',
    limits: LIMITS_COMMON + ' Não persiste no terreno; é demonstração.',
    controls: [
      c('length', 'Comprimento', 'Geometria', 2.0, 6.0, 0.1, 6.0, true),
      c('width', 'Largura', 'Geometria', 0.5, 2.0, 0.05, 1.0, true),
      c('rocks', 'Fragmentos', 'Geometria', 6, 30, 1, 18, true),
    ],
  },

  // ── FAMÍLIA D ───────────────────────────────────────────────────────────────
  {
    id: 'shockwave', lib: 'LIB-VFX-13', name: 'Shockwave Ring', family: 'D', category: 'Impacto',
    duration: 1.9, create: createShockwaveRef, status: statePrototype,
    desc: 'Frente de choque fina com halo, ruído quebrando o anel e onda de poeira levantada do chão. Referência: DBFZ/Sparking! Zero.',
    technique: 'Planos radiais com shader gaussiano de frente + FBM no ângulo; dois anéis defasados, flash e 22 nuvens de fumaça empurradas para fora.',
    deps: 'assets/vfx/flipbook_smoke.png + three (ShaderMaterial)',
    limits: LIMITS_COMMON + ' Sem distorção de refração; a frente é emissiva.',
    controls: [
      c('radius', 'Raio máximo', 'Geometria', 2.0, 8.0, 0.1, REF_DEFAULTS.shockwave.radius, true),
      c('speed', 'Velocidade', 'Movimento', 0.4, 2.5, 0.05, REF_DEFAULTS.shockwave.speed),
      c('rings', 'Anéis', 'Geometria', 1, 4, 1, REF_DEFAULTS.shockwave.rings, true),
      c('dust', 'Nuvens de poeira', 'Geometria', 0, 40, 1, REF_DEFAULTS.shockwave.dust),
      col('hot', 'Núcleo', 'Cores', REF_DEFAULTS.shockwave.hot),
      col('mid', 'Borda', 'Cores', REF_DEFAULTS.shockwave.mid),
    ],
  },
  {
    id: 'crown', lib: 'LIB-VFX-14', name: 'Impact Crown', family: 'D', category: 'Impacto',
    duration: 1.6, create: createCrownRef, status: statePrototype,
    desc: 'Coroa de lâminas irregulares em duas camadas, com núcleo de flipbook e estilhaços. Referência: DBFZ/Guilty Gear.',
    technique: 'Geometria autoral de lâminas (aT/aSide/aSeed/aLayer) com FBM e gradiente quente; NormalBlending para ter corpo; flipbook de impacto no núcleo.',
    deps: 'assets/vfx/flipbook_impact.png + three',
    limits: LIMITS_COMMON + ' O núcleo é billboard; de perfil ele fica de face para a câmera.',
    controls: [
      c('spikes', 'Lâminas', 'Geometria', 8, 28, 1, REF_DEFAULTS.crown.spikes, true),
      c('height', 'Altura', 'Geometria', 0.8, 3.4, 0.05, REF_DEFAULTS.crown.height, true),
      c('radius', 'Raio', 'Geometria', 0.6, 2.0, 0.05, REF_DEFAULTS.crown.radius, true),
      c('debris', 'Estilhaços', 'Geometria', 0, 40, 1, REF_DEFAULTS.crown.debris, true),
      c('core', 'Núcleo', 'Material', 0.2, 1.8, 0.05, REF_DEFAULTS.crown.core),
      col('hot', 'Núcleo quente', 'Cores', REF_DEFAULTS.crown.hot),
      col('mid', 'Cor da coroa', 'Cores', REF_DEFAULTS.crown.mid),
      col('dark', 'Base escura', 'Cores', REF_DEFAULTS.crown.dark),
    ],
  },
  {
    id: 'blastcone', lib: 'LIB-VFX-15', name: 'Blast Cone', family: 'D', category: 'Impacto',
    duration: 1.8, create: createBlastCone, status: statePrototype,
    desc: 'Cone de choque a partir do contato, com lâmina interna, anel e faíscas.',
    technique: 'Dois cones abertos com coneMaterial; ponta no contato e boca para longe do atacante. Eixo derivado do palco.',
    deps: 'three (CylinderGeometry aberta)',
    limits: LIMITS_COMMON,
    controls: [
      c('length', 'Comprimento', 'Geometria', 1.8, 5.0, 0.1, 3.4, true),
      c('opening', 'Abertura', 'Geometria', 0.8, 2.4, 0.05, 1.55, true),
      c('intensity', 'Intensidade', 'Material', 0.3, 2.0, 0.05, 1.0),
    ],
  },
  {
    id: 'fracture', lib: 'LIB-VFX-16', name: 'Ground Fracture', family: 'D', category: 'Impacto',
    duration: 2.6, create: createFracture, status: statePrototype,
    desc: 'Rachaduras radiais ramificadas que se revelam do centro, com pedras subindo.',
    technique: 'Shader com ruído 2D + ramos radiais (sin(a*branches + ruído)), frente de revelação; InstancedMesh de pedras.',
    deps: 'three (PlaneGeometry + InstancedMesh)',
    limits: LIMITS_COMMON + ' Sem destruição de cenário; é uma malha de demonstração.',
    controls: [
      c('radius', 'Raio', 'Geometria', 2.0, 5.5, 0.1, 3.2, true),
      c('branches', 'Ramos', 'Geometria', 4, 14, 1, 7, true),
    ],
  },

  // ── FAMÍLIA E ───────────────────────────────────────────────────────────────
  {
    id: 'flipbook', lib: 'LIB-VFX-17', name: 'Anime Impact Flipbook', family: 'E', category: 'Impacto',
    duration: 1.4, create: createFlipbook, status: statePrototype,
    desc: 'Explosão de impacto com o atlas real do projeto (16 quadros, 4×4).',
    technique: 'Textura assets/vfx/flipbook_impact.png; shader escolhe a célula por progresso e faz billboard para a câmera. Mesmo recurso do shaders/flipbook.gdshader.',
    deps: 'assets/vfx/flipbook_impact.png (recurso existente do projeto)',
    limits: LIMITS_COMMON + ' Atlas é 4×4 fixo; trocar o recurso exige h_frames/v_frames.',
    controls: [
      c('size', 'Tamanho', 'Geometria', 1.5, 6.0, 0.1, 3.4),
      c('fps', 'Quadros/s', 'Movimento', 8, 40, 1, 22),
      c('intensity', 'Intensidade', 'Material', 0.3, 2.0, 0.05, 1.0),
    ],
  },
  {
    id: 'sparks', lib: 'LIB-VFX-18', name: 'Kinetic Sparks', family: 'E', category: 'Impacto',
    duration: 1.6, create: createSparks, status: statePrototype,
    desc: 'Faíscas alongadas e direcionais, com gravidade e enfraquecimento por instância.',
    technique: 'InstancedMesh de caixas orientadas pela velocidade; cor por instância (instanceColor) para apagar sem sumir de golpe.',
    deps: 'three (InstancedMesh + instanceColor)',
    limits: LIMITS_COMMON,
    controls: [
      c('count', 'Quantidade', 'Geometria', 30, 200, 5, 90, true),
      c('speed', 'Velocidade', 'Movimento', 3, 16, 0.5, 8),
      c('gravity', 'Gravidade', 'Movimento', -20, 0, 0.5, -7),
    ],
  },
  {
    id: 'debris', lib: 'LIB-VFX-19', name: 'Directional Debris', family: 'E', category: 'Impacto',
    duration: 2.4, create: createDebris, status: statePrototype,
    desc: 'Fragmentos sólidos arremessados, com rotação, gravidade e quique visual.',
    technique: 'InstancedMesh de dodecaedros com física balística simples (sem colisão de gameplay).',
    deps: 'three (InstancedMesh)',
    limits: LIMITS_COMMON + ' Quique é visual; não altera o cenário.',
    controls: [
      c('count', 'Quantidade', 'Geometria', 8, 60, 1, 26, true),
      c('size', 'Tamanho', 'Geometria', 0.5, 2.0, 0.05, 1.0, true),
      c('gravity', 'Gravidade', 'Movimento', -20, -1, 0.5, -8),
    ],
  },
  {
    id: 'slash', lib: 'LIB-VFX-20', name: 'Slash Arc', family: 'E', category: 'Impacto',
    duration: 1.5, create: createSlash, status: 'Protótipo — referência aplicada (não aprovado)',
    desc: 'Corte horizontal em três camadas com linguagem cel: bandas chapadas, contorno escuro e gume quente; escala derivada do corpo do alvo, carga à frente do punho e faíscas/respingos na cabeça do arco. Referência: Lucie Travaux, Mourad El Ghali e Ali.',
    technique: 'Fita própria com UV y=0 no dorso e y=1 no gume; corpo em três bandas step e alpha sólido; under-trail escuro; volume cruzado; FBM em manchas chapadas. Carga derivada do Box3 do atacante (D-235); faíscas e respingos na cabeça do arco.',
    deps: 'three (BufferGeometry própria + FBM + flipbook de impacto)',
    limits: LIMITS_COMMON + ' A leitura de perfil é fina; a vista principal é 3/4 e espelhada. A escala é proporcional ao alvo (lição da auditoria), não o tamanho fixo da D-308 de combate. A malha do slash_arc.glb continua sendo referência, não carregada.',
    controls: [
      c('arc', 'Ângulo', 'Geometria', 90, 260, 5, SLASH_DEFAULTS.arc, true),
      c('radius', 'Raio', 'Geometria', 1.0, 3.2, 0.05, SLASH_DEFAULTS.radius, true),
      c('width', 'Espessura', 'Geometria', 0.12, 1.1, 0.01, SLASH_DEFAULTS.width, true),
      c('tilt', 'Inclinação', 'Geometria', -90, 90, 1, SLASH_DEFAULTS.tilt, true),
      c('reveal', 'Tempo de revelação', 'Movimento', 0.06, 0.5, 0.01, SLASH_DEFAULTS.reveal),
      c('hold', 'Permanência', 'Movimento', 0.0, 0.6, 0.01, SLASH_DEFAULTS.hold),
      c('fade', 'Dissipação', 'Movimento', 0.1, 1.2, 0.01, SLASH_DEFAULTS.fade),
      c('sparks', 'Faíscas', 'Material', 0.0, 2.0, 0.05, SLASH_DEFAULTS.sparks),
      c('splash', 'Respingos (atlas)', 'Material', 0.0, 1.0, 0.05, SLASH_DEFAULTS.splash),
      c('charge', 'Carga (zigue-zague)', 'Material', 0.0, 1.0, 0.05, SLASH_DEFAULTS.charge),
      c('under', 'Under-trail', 'Material', 0.0, 1.0, 0.05, SLASH_DEFAULTS.under),
      col('hot', 'Gume', 'Cores', SLASH_DEFAULTS.hot),
      col('body', 'Corpo', 'Cores', SLASH_DEFAULTS.body),
      col('edge', 'Borda interna', 'Cores', SLASH_DEFAULTS.edge),
    ],
  },

  // ── COMPOSIÇÕES ─────────────────────────────────────────────────────────────
  {
    id: 'animeDash', lib: 'DEMO-01', name: 'Anime Dash', family: 'DEMO', category: 'Demonstrações',
    duration: 4.4, create: createAnimeDash, status: statePrototype,
    desc: 'Aura + propulsão + linhas + rastro + poeira + frenagem, em sequência.',
    technique: 'Composição por janelas de tempo; cada peça é o componente independente (nenhuma cópia de implementação).',
    deps: 'LIB-VFX-06, 07, 08, 09, 10, 11',
    limits: 'Sequência de laboratório; não é movimentação nem ATB do jogo.',
    controls: [],
  },
  {
    id: 'punchyImpact', lib: 'DEMO-02', name: 'Punchy Anime Impact', family: 'DEMO', category: 'Demonstrações',
    duration: 2.5, create: createPunchyImpact, status: statePrototype,
    desc: 'Flipbook + coroa + onda de choque + cone + faíscas + fragmentos no mesmo contato.',
    technique: 'Composição por janelas de tempo sobre o ponto de impacto; peças independentes e isoláveis.',
    deps: 'LIB-VFX-13, 14, 15, 17, 18, 19',
    limits: 'Não altera Tackle nem adiciona hit-stop.',
    controls: [],
  },
  {
    id: 'energyHelix', lib: 'DEMO-03', name: 'Energy Helix', family: 'DEMO', category: 'Demonstrações',
    duration: 4.6, create: createEnergyHelix, status: statePrototype,
    desc: 'Fita helicoidal + feixe + erosão, mostrando forma, fluxo e desaparecimento.',
    technique: 'Composição de três formas independentes com defasagem.',
    deps: 'LIB-VFX-03, 04, 05',
    limits: 'Estudo de forma; não é Move.',
    controls: [],
  },
  {
    id: 'vortexStudy', lib: 'DEMO-04', name: 'Vortex / Tornado Study', family: 'DEMO', category: 'Demonstrações',
    duration: 6, create: createVortexStudy, status: statePrototype,
    desc: 'Vórtice + tornado + erosão; use as camadas para isolar núcleo e superfícies.',
    technique: 'Composição de formas com defasagem; a erosão roda dentro do volume.',
    deps: 'LIB-VFX-01, 02, 05',
    limits: 'Sobreposição intencional; isolar camadas para estudar.',
    controls: [],
  },
  {
    id: 'stylizedSlash', lib: 'DEMO-05', name: 'Stylized Slash', family: 'DEMO', category: 'Demonstrações',
    duration: 2.6, create: createStylizedSlash, status: statePrototype,
    desc: 'Aproximação com rastro e arco de corte com faíscas internas.',
    technique: 'Composição de rastro + arco (o arco traz as próprias faíscas e respingos).',
    deps: 'LIB-VFX-08, 20',
    limits: 'Laboratório; não é o corte de nenhum Move.',
    controls: [],
  },

  // ── EXTRA DO PROJETO ────────────────────────────────────────────────────────
  {
    id: 'prelude', lib: 'EXTRA', name: 'Attack Prelude / Hit-windup', family: 'EXTRA', category: 'Extra',
    duration: 2.8, create: createPrelude, status: statePrototype,
    desc: 'Pré-ataque do projeto: carga no membro, traço até o contato e trava no alvo — a janela do Evade.',
    technique: 'TubeGeometry sobre curva do punho ao contato + anéis de trava + faíscas de carga.',
    deps: 'three',
    limits: 'Conceito do projeto (não é um dos 20 componentes do catálogo).',
    controls: [],
  },
];

// D-956: referência declarada e estado honesto por item. Só os 6 flagships
// desta rodada ganham "Refeito com referência"; o resto é legado explícito.
for (const e of EFFECTS) {
  const isDemo = e.lib.startsWith('DEMO');
  e.reference = REF[e.id] || (isDemo ? '— (compõe flagships e peças em revisão)' : '— (referências no dossiê; reconstrução não iniciada)');
  if (e.id === 'slash') e.status = 'Protótipo — referência aplicada (não aprovado)';
  else if (REF[e.id]) e.status = 'Protótipo — referência inicial (não aprovado)';
  else if (isDemo) e.status = 'Composição — em revisão';
  else e.status = 'Aguardando referência';
}
