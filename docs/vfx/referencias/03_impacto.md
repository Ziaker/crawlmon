# Família D — Impacto (LIB 13–16)

Referências completas em `refs.json`; contatos em `contatos/contato-<id>.png`.

---

## LIB-VFX-13 — Shockwave Ring

### 5 candidatos

| # | Obra | Fonte |
|---|---|---|
| 1 | Stylized explosion — shockwave disk + heat distortion | [RealTimeVFX / Brais](https://realtimevfx.com/t/brais-sketchbook/31406) |
| 2 | Sketch #50 — shockwave mesh | [RealTimeVFX / Noska](https://realtimevfx.com/t/noska-sketch-50/19460) |
| 3 | Stylized lightning — timing critique | [RealTimeVFX](https://realtimevfx.com/t/lightning-strike-stylized-what-do-you-guys-think-update/1972) |
| 4 | Radial → shockwave (Niagara) | [CGHOW / Epic](https://dev.epicgames.com/community/learning/tutorials/XvOj9/unreal-engine-simple-stylized-tornado-vfx-in-ue5-niagara-torus-mesh-erode-dynamic-params) |
| 5 | One-Punch Man impact | [Rebelway](https://rebelway.net/one-punch-man-houdini-tutorial) |

**Selecionadas:** 1, 2, 5.

### Leitura

- **Brais (1):** a onda é um **disco com UV radial** e uma segunda camada de **distorção de calor**.
 A frente é fina e o halo é o que dá volume.
- **Noska (2):** a onda é uma malha que cresce com curva de escala e cor; a crítica do próprio
 artista é que a escala precisa ser rápida no começo e desacelerar.
- **One-Punch Man (5):** a onda tem escala planetária; a lição é **separar escalas** (frente fina,
 poeira grossa, detritos). Não é um anel só.

### Hoje vs. referência

O protótipo tem 2–3 planos com uma banda gaussiana e um flash. Falta a **distorção** (o ar
deslocado), a poeira levantada e a diferença de escala entre as camadas. A onda some sem deixar
rastro.

### Proposta

- **Camada 1:** frente fina (banda 0,02) com ruído angular e cor branca.
- **Camada 2:** halo largo (0,12) com alpha baixo e distorção de UV (screen-space se possível).
- **Camada 3:** poeira levantada em anel, 0,05 s depois; 0,6 s de vida.
- **Timing:** frente 0,35 s; halo 0,5 s; poeira 0,8 s.

---

## LIB-VFX-14 — Impact Crown

> Dossiê completo, 5 candidatos, análise e proposta: `00_flagship_coroa_vortice.md`, seção 1.

Resumo: as referências (Genshin 2-frame flash, 3dxdev impact frames, One-Punch Man, RoClicks)
pedem **silhueta radial irregular, centro escuro, flash de 1–2 frames e camadas com tempos
próprios**. O protótipo atual é um círculo de cones aditivos, sem hierarquia e com timing longo.
**Não aprovado.**

---

## LIB-VFX-15 — Blast Cone

### 5 candidatos

| # | Obra | Fonte |
|---|---|---|
| 1 | Anime fire beam | [80.lv / Rayane Saada](https://80.lv/articles/using-unreal-engine-to-make-an-anime-inspired-stylized-fire-beam-vfx) |
| 2 | One-Punch Man impact | [Rebelway](https://rebelway.net/one-punch-man-houdini-tutorial) |
| 3 | Initial blast (two meshes) | [RealTimeVFX / Brais](https://realtimevfx.com/t/brais-sketchbook/31406) |
| 4 | Sketch #50 explosion | [RealTimeVFX / Noska](https://realtimevfx.com/t/noska-sketch-50/19460) |
| 5 | Cast/impact breakdown | [80.lv / Pawel Margacz](https://80.lv/articles/breakdown-creating-vfx-in-unreal-engine-4) |

**Selecionadas:** 1, 2, 3.

### Leitura

- **Fire beam (1):** o cone/feixe tem **release instantâneo** e uma borda de ataque branca; o
 interior é uma textura panning distorcida. A direção é a informação principal.
- **One-Punch Man (2):** o cone de pressão é curto e largo, com poeira na boca; a parte de trás
 é turbulentaa.
- **Brais (3):** o blast inicial são **duas esferas/malhas** com materiais diferentes; não é um
 sprite. A sobreposição dá volume.

### Hoje vs. referência

O protótipo é um cone aberto com listras longitudinais + cone interno. A boca é larga e o cone
parece um leque de penas; falta a **borda de ataque** (uma tampa fina e brilhante) e a turbulência
na cauda.

### Proposta

- **Tampa de ataque:** um disco/cone fino no contato, branco, 2 frames.
- **Corpo:** cone com FBM e listras longitudinais; a boca se dissolve em poeira.
- **Cauda:** 6–8 tufos de fumaça e faíscas.

---

## LIB-VFX-16 — Ground Fracture

### 5 candidatos

| # | Obra | Fonte |
|---|---|---|
| 1 | Ground crack (3 parts) | [1mafx](https://www.1mafx.com/blog/ground-crack-vfx-breakdown) |
| 2 | Ground slam decals (height/normal) | [Keiren Wall](https://keirenwall.com/home/Houdini-Decals) |
| 3 | Cracking concrete | [80.lv / Pol Villà](https://80.lv/articles/creating-cracking-concrete-effect-using-houdini) |
| 4 | Destruction VFX techniques | [SideFX](https://www.sidefx.com/learn/talks/destruction-vfx-techniques-with-houdini-and-unreal/) |
| 5 | Houdini RBD II | [CGcircuit](https://www.cgcircuit.com/tutorial/houdini-rbd-ii---ground-destruction) |

**Selecionadas:** 1, 2, 3.

### Leitura

- **1mafx (1):** a fratura é um **pipeline**: geometria fraturada → textura → Niagara (poeira e
 brilho de borda). A rachadura tem espessura e as pedras têm peso.
- **Keiren (2):** a fratura é convertida em **decal com height/normal/roughness**; o parallax dá
 profundidade quando a câmera se move.
- **Pol Villà (3):** o detalhe vem do **shader** sobre a geometria fraturada; a rachadura é
 irregular e ramificada.

### Hoje vs. referência

O protótipo desenha linhas radiais com `sin(a*branches)` e um pouco de ruído; as linhas são finas,
uniformes e não têm profundidade. As pedras são dodecaedros pequenos.

### Proposta

- **Falsa profundidade:** interior escuro, borda clara, sombra interna; 3 escalas de rachadura.
- **Ramos:** 5–8 principais + 12–20 secundários, com largura variável.
- **Pedras:** 3 tamanhos, com rotação e poeira; 0,6–1,0 s.