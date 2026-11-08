# Família A — Formas (LIB 01–05)

Referências completas em `refs.json`; contatos em `contatos/contato-<id>.png`.
**Impact Crown e Vortex** têm dossiê profundo em `00_flagship_coroa_vortice.md`.

---

## LIB-VFX-01 — Vortex Mesh

> Dossiê completo, 5 candidatos e proposta: `00_flagship_coroa_vortice.md`, seção 2.

Resumo: as referências (Doctor Strange/Framestore, portal da Chavez, tornado CGHOW) pedem **aro
quente, parede com erosão, centro escuro e detritos sugados**. O protótipo atual tem duas cascas
uniformes, disco de anéis concêntricos e pontos; falta hierarquia de borda e leitura de buraco.
Reconstrução proposta: 4 camadas + streaks + borda que racha. **Não aprovado.**

---

## LIB-VFX-02 — Tornado / Funnel

### 5 candidatos

| # | Obra | Fonte |
|---|---|---|
| 1 | Simple Stylized Tornado (torus + vortex force) | [CGHOW / Epic](https://dev.epicgames.com/community/learning/tutorials/XvOj9/unreal-engine-simple-stylized-tornado-vfx-in-ue5-niagara-torus-mesh-erode-dynamic-params) |
| 2 | Layered cone tornado | [80.lv / Gustavo Dresch Rosa](https://80.lv/articles/neat-stylized-tornado-vfx-set-up-in-unreal-engine-s-niagara) |
| 3 | Storm tornado (UE5 + Substance) | [80.lv / Kfir Balouka](https://80.lv/articles/take-a-look-at-these-stylized-tornado-vfx-created-with-ue5-s-niagara) |
| 4 | Stylized tornado preview (UE4 Niagara) | [YouTube](https://www.youtube.com/watch?v=oa2TK0zP8lc) |
| 5 | Explosion smoke cloud meshes | [RealTimeVFX / Brais](https://realtimevfx.com/t/brais-sketchbook/31406) |

**Selecionadas:** 1, 2, 3.

### Leitura das três

- **CGHOW (1):** o funil nasce de **vários toros** com erode e parâmetros aleatórios por partícula.
 O que importa não é o toro em si; é a **não uniformidade** — cada anel tem tiling, tamanho e
 rotação diferentes. A silhueta é uma coluna que afina na base e abre na boca.
- **Gustavo (2):** camadas de **cone** com shader e detritos orbitando. A silhueta é mais
 "Ghibli": borda suave, interior denso, poeira na base. A câmera vê volume, não uma folha.
- **Kfir (3):** textura/erosão autoral e clima. A referência ensina que o **ruído de erosão** é o
 que quebra a leitura de "cone de plástico"; a cor e a iluminação fazem o resto.

### O que o protótipo faz hoje

Três `funnelGeometry` concêntricos com twist diferente e um anel rasteiro. A silhueta é regular
demais; as bandas são listras longas (bom), mas não há erosão, os três funis quase coincidem e a
poeira é fraca. O anel do chão é um círculo uniforme.

### Proposta de reconstrução

- **Geometria:** 10–16 toros empilhados (ou 3 cones) com raios e alturas aleatórios; cada um com
 rotação e tiling próprios. Base fina, boca larga.
- **Shader:** FBM multi-oitava na parede, erode por altura, alpha mais denso no centro e
 quebrado nas bordas; cor de poeira/vento (bege sujo) ou energia (ciano) por uniform.
- **Poeira:** emissão na base + detritos orbitando; a poeira sobe e sai pela boca.
 TRAJECTORY (sustenta) → PRELUDE (borda racha) → IMPACT (explosão de poeira) → POST-IMPACT
 (funil perde densidade de baixo para cima).

---

## LIB-VFX-03 — Spiral Ribbon

### 5 candidatos

| # | Obra | Fonte |
|---|---|---|
| 1 | Fire Slash (Genshin-inspired) | [ArtStation / Mourad El Ghali](https://mouradzzz.artstation.com/projects/3EaexB) |
| 2 | Slash VFX (Unity Shader Graph) | [ArtStation / Lucie Travaux](https://lixsh.artstation.com/projects/ea8PrX) |
| 3 | Procedural slash shader (MIT) | [RealTimeVFX / Ali](https://realtimevfx.com/t/alis-sketchbook/29539/6) |
| 4 | Mesh slash textures | [RealTimeVFX / Stt](https://realtimevfx.com/t/stt-sketch-22/8586) |
| 5 | Melee Weapon Aura & Trails | [Fab / EYSON](https://www.fab.com/listings/bb36b822-001a-4927-a02b-79b17cf2b36b) |

**Selecionadas:** 1, 3, 5.

### Leitura das três

- **Fire Slash (1):** a fita tem **fase de carga, impacto e corte**. A largura cresce do punho
 para o meio e afina na ponta; a textura corre; a dissipação é por erosão, não por fade.
- **Ali (3):** o shader desenha a forma, distorce com ruído e dissolve. O segredo é a **borda
 fina e o interior com breakup**; a aberração cromática é opcional.
- **Melee Trails (5):** a fita é um **histórico de arma**: largura variável, taper nas pontas,
 continuidade quando a arma muda de direção. A referência é de continuidade, não de forma fixa.

### O que o protótipo faz hoje

Uma fita helicoidal de largura 0,55 com pulso branco. A superfície é fina e o pulso estoura; não
há segunda camada (trilha escura), nem textura correndo, nem erosão. A hélice é geométrica demais.

### Proposta de reconstrução

- **Duas camadas:** fita emissiva (cor) + fita escura por baixo (profundidade), como em Stt.
- **Perfil:** largura em sino, ponta afinada, leve torção; UV longitudinal com textura de risco.
- **Shader:** gradiente de cor, ruído na borda, flow ao longo do comprimento, dissolve nas pontas.
 (percorre a hélice) → PRELUDE (ponta brilha) → IMPACT (chicote) → POST-IMPACT (dissolve).

---

## LIB-VFX-04 — Helix Cylinder

### 5 candidatos

| # | Obra | Fonte |
|---|---|---|
| 1 | Anime fire beam (UE5/Houdini) | [80.lv / Rayane Saada](https://80.lv/articles/using-unreal-engine-to-make-an-anime-inspired-stylized-fire-beam-vfx) |
| 2 | Kamehameha-like laser (Unity) | [80.lv / Harry Alisavakis](https://80.lv/articles/crafting-a-kamehameha-like-vfx-001agt) |
| 3 | Genshin Impact VFX breakdown | [VFX Apprentice](https://www.vfxapprentice.com/blog/genshin-impact-stylized-vfx-breakdown) |
| 4 | Anime Stylized VFX (pack) | [Fab / Vefects](https://www.fab.com/listings/d85dee78-9584-4b4b-a3b7-4b96de33c2b8) |
| 5 | HSR VFX style study | [Nathan Lacsamana](https://nathanlacsamana.com/hsr-vfx-style-study) |

**Selecionadas:** 1, 2, 3.

### Leitura das três

- **Fire beam (1):** o feixe tem **build-up (esfera que cresce), release instantâneo e dissipação**.
 O shader é panning distorcido por ruído com máscara radial; a cor é branca no núcleo e laranja
 na borda. O texto é explícito: o timing é a alma do efeito.
- **Kamehameha (2):** esfera de carga, beam, poeira circular e slashes no impacto. A hélice não é
 o principal; o **núcleo** é. As espirais são detalhe de superfície.
- **Genshin (3):** malhas 3D assimétricas; o feixe/corte não é um cilindro uniforme. A borda é
 irregular e a leitura vem da silhueta.

### O que o protótipo faz hoje

Três `TubeGeometry` helicoidais + um cilindro central + anel. As correntes são finas e o núcleo
é um cilindro liso; não há carga, release nem poeira. A hélice é o efeito inteiro, quando nas
referências ela é **detalhe** de um feixe com núcleo.

### Proposta de reconstrução

- **Núcleo:** cilindro com fresnel e gradiente branco→ciano, mais grosso que as correntes.
- **Correntes:** 2–3 tubos com twist e raio variável; **não** uniformes; textura correndo.
- **Carga:** esfera/orbe que cresce no punho antes do release.
- **Impacto:** anel de poeira e slashes no ponto de contato.
 → PRELUDE (núcleo pulsa) → IMPACT (poeira/slashes) → POST-IMPACT (feixe afina e some).

---

## LIB-VFX-05 — Spiral Erosion

### 5 candidatos

| # | Obra | Fonte |
|---|---|---|
| 1 | Venom Slash — alpha mask + noise | [RealTimeVFX / Geri](https://realtimevfx.com/t/venom-slash-breakdown-of-the-effect-included/18903) |
| 2 | Procedural slash dissolve (MIT) | [RealTimeVFX / Ali](https://realtimevfx.com/t/alis-sketchbook/29539/6) |
| 3 | Reusable procedural smoke material | [RealTimeVFX / Brais](https://realtimevfx.com/t/brais-sketchbook/31406) |
| 4 | Tornado erode material | [80.lv / Kfir Balouka](https://80.lv/articles/take-a-look-at-these-stylized-tornado-vfx-created-with-ue5-s-niagara) |
| 5 | Tornado erode per particle | [CGHOW / Epic](https://dev.epicgames.com/community/learning/tutorials/XvOj9/unreal-engine-simple-stylized-tornado-vfx-in-ue5-niagara-torus-mesh-erode-dynamic-params) |

**Selecionadas:** 1, 2, 3.

### Leitura das três

- **Venom (1):** a máscara é um **anel** que cobre o centro; o ruído rola e dirige o movimento.
 A erosão é aplicada a uma superfície com significado (o corte), não a um objeto de teste.
- **Ali (2):** dissolve com ruído e distorção; a borda é o que conta. O shader é MIT e mostra o
 caminho para um erosion legível.
- **Brais (3):** material paramétrico com dissolve e gradient; o mesmo material serve a várias
 nuvens. A lição é **reuso com breakup**, não um shader por efeito.

### O que o protótipo faz hoje

Um `TorusKnotGeometry` com ruído 3D + espiral e `discard`. A superfície é arbitrária; a erosão
não tem relação com forma, uso ou leitura. A borda é branca e estoura; as brasas são pontos.

### Proposta de reconstrução

- **Superfície com significado:** aplicar a erosão a uma **lâmina/casca** reconhecível, não a um
 nó. A forma deve dizer o que está sendo destruído.
- **Máscara:** ruído 3D + espiral; frente de erosão com largura controlada; borda quente
 (branco→âmbar) e interior escuro.
- **Detritos:** brasas/partículas que saem da borda, com direção.
 TRAJECTORY (erosão percorre) → PRELUDE (núcleo exposto) → IMPACT (colapso) → POST-IMPACT
 (brasas e poeira).
