# Família E — Complementos de impacto (LIB 17–20)

Referências completas em `refs.json`; contatos em `contatos/contato-<id>.png`.

---

## LIB-VFX-17 — Anime Impact Flipbook

### 5 candidatos

| # | Obra | Fonte |
|---|---|---|
| 1 | 2D Animation — Basic Hit Impact (part 3) | [YouTube / VFX Apprentice](https://www.youtube.com/watch?v=Zzha-1ccQak) |
| 2 | Impact Frames (UE5) | [3dxdev](https://3dxdev.com/assets/impact-frames-anime-hit-effects-for-unreal-engine-5) |
| 3 | "Impact frames" in UE5? | [RealTimeVFX](https://realtimevfx.com/t/impact-frames-in-ue5/24982) |
| 4 | GG Strive effect reverse engineering | [RealTimeVFX](https://realtimevfx.com/t/please-help-me-reverse-engineer-this-effect-from-guilty-gear-strive/30609) |
| 5 | Genshin impact frames | [VFX Apprentice](https://www.vfxapprentice.com/blog/genshin-impact-stylized-vfx-breakdown) |

**Selecionadas:** 1, 2, 4.

### Leitura

- **VFX Apprentice 2D (1):** o impacto é construído **quadro a quadro**: planejamento, in-between,
 dissolve, break apart. A silhueta muda a cada frame; não é um único sprite crescendo.
- **3dxdev (2):** o frame de impacto é **1–2 frames**, branco/negativo, com linhas radiais; o
 segredo é a raridade e o contraste.
- **GG reverse (4):** a discussão levanta que o efeito do jogo pode ser **flipbook em malha 3D**,
 não um decal; a leitura muda com o ângulo.

### Hoje vs. referência

O protótipo usa o atlas real de 16 quadros, mas só como um **anel** no centro. Falta o frame
chapado, a silhueta e a mudança de forma entre quadros. O atlas também esvazia no fim.

### Proposta

- **Camada 1:** frame chapado (branco/negativo) por 1–2 frames, com a silhueta do alvo.
- **Camada 2:** atlas de impacto (16 quadros) em 0,5 s, com cor.
- **Camada 3:** linhas radiais e detritos.
- **Timing:** 0,04 s de flash; 0,5 s de atlas; 0,8 s de detritos.

---

## LIB-VFX-18 — Kinetic Sparks

### 5 candidatos

| # | Obra | Fonte |
|---|---|---|
| 1 | Venom Slash — splash atlas | [RealTimeVFX / Geri](https://realtimevfx.com/t/venom-slash-breakdown-of-the-effect-included/18903) |
| 2 | Stylized fireball — impact | [RealTimeVFX / RenderWright](https://realtimevfx.com/t/stylized-fireball-projectile/31658) |
| 3 | Cast/impact breakdown | [80.lv / Pawel Margacz](https://80.lv/articles/breakdown-creating-vfx-in-unreal-engine-4) |
| 4 | Guilty Gear combo breakdown | [80.lv](https://80.lv/articles/animating-guilty-gear-inspired-fighting-game-combo-in-maya) |
| 5 | Ground crack breakdown | [1mafx](https://www.1mafx.com/blog/ground-crack-vfx-breakdown) |

**Selecionadas:** 1, 2, 3.

### Leitura

- **Venom (1):** as faíscas são um **atlas de respingos** com glow e dissolve; a direção acompanha
 o corte. Não são pontos genéricos.
- **Fireball (2):** as faíscas usam **bandas de cor** (step) e line art; o impacto tem a mesma
 linguagem do projétil.
- **Pawel (3):** o mesmo impacto usa flash, círculo e faíscas com configurações diferentes; a
 variedade de tamanho/velocidade é o que dá riqueza.

### Hoje vs. referência

O protótipo usa caixas orientadas pela velocidade, com cor por instância. É funcional, mas:
tamanho único, sem line art, sem variação de cor e sem atlas. Lê como "pó de luz".

### Proposta

- 3 comprimentos e 3 espessuras; 2 cores (branco e âmbar); 20% com atlas de respingo.
- Direção inicial concentrada no eixo do impacto; gravidade e fade por instância.

---

## LIB-VFX-19 — Directional Debris

### 5 candidatos

| # | Obra | Fonte |
|---|---|---|
| 1 | Debris ribbons + cloud meshes | [RealTimeVFX / Brais](https://realtimevfx.com/t/brais-sketchbook/31406) |
| 2 | Ground crack debris | [1mafx](https://www.1mafx.com/blog/ground-crack-vfx-breakdown) |
| 3 | Destruction VFX techniques | [SideFX](https://www.sidefx.com/learn/talks/destruction-vfx-techniques-with-houdini-and-unreal/) |
| 4 | Sketch #50 | [RealTimeVFX / Noska](https://realtimevfx.com/t/noska-sketch-50/19460) |
| 5 | Houdini RBD II | [CGcircuit](https://www.cgcircuit.com/tutorial/houdini-rbd-ii---ground-destruction) |

**Selecionadas:** 1, 2, 3.

### Leitura

- **Brais (1):** os detritos usam **ribbons** e nuvens em malha; a profundidade vem de camadas,
 não de muitos objetos iguais.
- **1mafx (2):** pedras e poeira são camadas separadas; as pedras têm tamanho e distância variados.
- **SideFX (3):** a fratura é simulada e depois **traduzida para Niagara**; o peso vem da curva de
 velocidade, não do número de pedaços.

### Hoje vs. referência

O protótipo usa 26 dodecaedros iguais (0,12 m base) com gravidade e quique. Falta variação de
tamanho, poeira grudada e direção dominante.

### Proposta

- 3 tamanhos (0,08/0,16/0,28 m), 2 materiais (terra e pedra), 60% na direção do impacto.
- Poeira presa aos pedaços (2–3 tufos por pedaço grande).

---

## LIB-VFX-20 — Slash Arc

### 5 candidatos

| # | Obra | Fonte |
|---|---|---|
| 1 | Fire Slash | [ArtStation / Mourad El Ghali](https://mouradzzz.artstation.com/projects/3EaexB) |
| 2 | Procedural slash shader (MIT) | [RealTimeVFX / Ali](https://realtimevfx.com/t/alis-sketchbook/29539/6) |
| 3 | Venom Slash — ring mesh + noise | [RealTimeVFX / Geri](https://realtimevfx.com/t/venom-slash-breakdown-of-the-effect-included/18903) |
| 4 | Mesh slash textures | [RealTimeVFX / Stt](https://realtimevfx.com/t/stt-sketch-22/8586) |
| 5 | Slash VFX | [ArtStation / Lucie Travaux](https://lixsh.artstation.com/projects/ea8PrX) |

**Selecionadas:** 1, 2, 3.

### Leitura

- **Fire Slash (1):** o corte tem **carga, impacto e slash**; a lâmina de fogo é uma fita com
 textura e a dissipação é erosionada. A ponta é mais fina que o meio.
- **Ali (2):** o shader desenha um triângulo, distorce com ruído e dissolve; a **borda externa**
 é o gume e a interna é a cauda. A aberração cromática é tempero, não base.
- **Venom (3):** a malha anelar + alpha mask + duas texturas multiplicadas; o ruído rola e o
 splash atlas completa. A leitura é de **corte com matéria**, não de luz.

### Hoje vs. referência

O protótipo tem uma fita única com gume branco e erosão. Melhorou, mas ainda:
1. não tem **under-trail escuro**;
2. a textura não corre ao longo do arco;
3. a ponta não é fina o suficiente;
4. as faíscas são poucas e não seguem a direção do corte.

### Proposta

- 3 camadas: under-trail escuro, corpo colorido, gume branco.
- Textura de risco correndo; alpha em gradiente; ponta afinada.
- Faíscas e 6–8 estilhaços na saída do arco.