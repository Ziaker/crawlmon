# Família B/C — Movimento e solo (LIB 06–12)

Referências completas em `refs.json`; contatos em `contatos/contato-<id>.png`.

---

## LIB-VFX-06 — Thrust Cone

### 5 candidatos

| # | Obra | Fonte |
|---|---|---|
| 1 | Guilty Gear combo breakdown | [80.lv](https://80.lv/articles/animating-guilty-gear-inspired-fighting-game-combo-in-maya) |
| 2 | GG Strive 2.0 — Johnny | [YouTube](https://www.youtube.com/watch?v=wyJHtD5qoQ) |
| 3 | ZZZ attack VFX (Stormhound) | [80.lv](https://80.lv/articles/check-out-this-fancy-real-time-attack-vfx-for-zenless-zone-zero-animation) |
| 4 | Anime Stylized VFX (dash) | [Fab / Vefects](https://www.fab.com/listings/d85dee78-9584-4b4b-a3b7-4b96de33c2b8) |
| 5 | Slash VFX | [ArtStation / Lucie Travaux](https://lixsh.artstation.com/projects/ea8PrX) |

**Selecionadas:** 1, 2, 3.

### Leitura

- **GG combo (1):** o "thrust" não é um cone literal; é **compressão direcional** — speed lines,
 rim light e poeira no pé. A leitura vem da postura e das linhas, não de um jato.
- **Johnny (2):** o dash tem um **frame de arranque** e depois o corpo desliza; a poeira fica atrás.
 O efeito é curto e não cobre o personagem.
- **ZZZ (3):** faíscas e flares acompanham o golpe; a direção é clara e o efeito não preenche a tela.

### Hoje vs. referência

O protótipo tem um cone aberto de 2,4 m com listras e um bocal. É um jato contínuo, não um
arranque. Falta o frame de compressão, o rim light e a poeira de saída; o cone é grande demais.

### Proposta

- Cone curto (1,2–1,6 m), **ponta no corpo e boca atrás**, com borda de ataque branca e corpo
 ciano translúcido; duração de 0,10–0,18 s.
- Anel de compressão no pé + 6–10 tufos de poeira; sem rastro contínuo.

---

## LIB-VFX-07 — Speed Lines

### 5 candidatos

| # | Obra | Fonte |
|---|---|---|
| 1 | Guilty Gear combo breakdown | [80.lv](https://80.lv/articles/animating-guilty-gear-inspired-fighting-game-combo-in-maya) |
| 2 | GG Strive 2.0 — Johnny | [YouTube](https://www.youtube.com/watch?v=wyJHtD5qoQ) |
| 3 | Genshin VFX breakdown | [VFX Apprentice](https://www.vfxapprentice.com/blog/genshin-impact-stylized-vfx-breakdown) |
| 4 | 2D hit impact — part 3 | [YouTube / VFX Apprentice](https://www.youtube.com/watch?v=Zzha-1ccQak) |
| 5 | ZZZ attack VFX | [80.lv](https://80.lv/articles/check-out-this-fancy-real-time-attack-vfx-for-zenless-zone-zero-animation) |

**Selecionadas:** 1, 2, 4.

### Leitura

- **GG combo (1):** as linhas são **2D sobre o 3D**, com comprimentos e espaçamentos irregulares;
 nascem e morrem em 0,1–0,2 s, concentradas atrás do corpo.
- **Johnny (2):** cada dash tem poucas linhas, mas todas na mesma direção; o contraste com o fundo
 é alto. Não é uma chuva de riscos.
- **VFX Apprentice 2D (4):** as linhas são desenhadas quadro a quadro; a variação de espessura e
 a ponta afinada são o que dão velocity.

### Hoje vs. referência

O protótipo usa 70 caixas finas num tubo ao redor do corpo. É 3D e uniforme; as linhas cobrem
360° e não têm uma direção dominante. Falta o contraste 2D, a ponta e o agrupamento.

### Proposta

- 3 camadas: **fundo** (linhas longas, escuras), **corpo** (linhas médias, ciano) e **frente**
 (linhas curtas, brancas). Todas paralelas ao eixo, com offsets irregulares.
- Quads camera-facing (não caixas), com alpha em gradiente e ponta afinada; 0,15 s de vida.

---

## LIB-VFX-08 — Motion Trail

### 5 candidatos

| # | Obra | Fonte |
|---|---|---|
| 1 | Melee Weapon Aura & Trails | [Fab / EYSON](https://www.fab.com/listings/bb36b822-001a-4927-a02b-79b17cf2b36b) |
| 2 | Slash VFX | [ArtStation / Lucie Travaux](https://lixsh.artstation.com/projects/ea8PrX) |
| 3 | Fire Slash | [ArtStation / Mourad El Ghali](https://mouradzzz.artstation.com/projects/3EaexB) |
| 4 | Mesh slash textures | [RealTimeVFX / Stt](https://realtimevfx.com/t/stt-sketch-22/8586) |
| 5 | Venom Slash | [RealTimeVFX / Geri](https://realtimevfx.com/t/venom-slash-breakdown-of-the-effect-included/18903) |

**Selecionadas:** 1, 2, 4.

### Leitura

- **Melee Trails (1):** a trilha tem **largura, taper e continuidade**; quando a arma muda de
 direção, a fita preserva a curva. É o histórico que manda, não um spline fixo.
- **Lucie (2):** a fita é limpa, com borda definida e alpha; a superfície é visível.
- **Stt (4):** duas camadas — uma emissiva no centro e uma **trilha escura** por baixo. Isso dá
 profundidade e evita o "adesivo brilhante".

### Hoje vs. referência

O protótipo tem uma fita de 0,55 m com glow. Não tem segunda camada, a largura é uniforme e a
textura não corre. O rastro é curto porque o palco tem 4 m.

### Proposta

- Duas fitas: corpo (cor, NormalBlending) + under-trail (escuro, alpha 0,4) + fio branco no gume.
- Largura em sino, taper nas pontas, UV com textura de risco correndo; fade por idade.

---

## LIB-VFX-09 — Aura Burst

### 5 candidatos

| # | Obra | Fonte |
|---|---|---|
| 1 | Outline Anime Aura (Genshin-inspired) | [ArtStation / Mourad El Ghali](https://mouradzzz.artstation.com/projects/AZ6XqW) |
| 2 | Super Saiyan Aura (After Effects) | [YouTube](https://www.youtube.com/watch?v=ESOShZCqVZY) |
| 3 | Genshin VFX breakdown | [VFX Apprentice](https://www.vfxapprentice.com/blog/genshin-impact-stylized-vfx-breakdown) |
| 4 | Anime Stylized VFX (buff) | [Fab / Vefects](https://www.fab.com/listings/d85dee78-9584-4b4b-a3b7-4b96de33c2b8) |
| 5 | Fake light / gradient material | [RealTimeVFX / Brais](https://realtimevfx.com/t/brais-sketchbook/31406) |

**Selecionadas:** 1, 2, 3.

### Leitura

- **Outline aura (1):** a aura é um **contorno** que segue o modelo, com gradiente. O corpo do
 personagem continua legível; a aura não o cobre.
- **SSJ aura (2):** silhueta de chama com camadas (núcleo branco, corpo amarelo, borda laranja) e
 ruído; as partículas sobem.
- **Genshin (3):** o buff tem timing curto e cor saturada; o efeito não compete com o personagem.

### Hoje vs. referência

O protótipo é uma coluna cônica de ruído em volta do corpo, sem contorno e sem leitura de silhueta.
Parece uma jaula de energia, não uma aura.

### Proposta

- **Contorno** (inverted hull/fresnel) + **volume interno** com ruído subindo + brasas.
- Cor: núcleo branco, corpo ciano, borda roxa; o contorno é a parte mais brilhante.

---

## LIB-VFX-10 — Dust Trail

### 5 candidatos

| # | Obra | Fonte |
|---|---|---|
| 1 | Reusable procedural smoke material | [RealTimeVFX / Brais](https://realtimevfx.com/t/brais-sketchbook/31406) |
| 2 | Guilty Gear combo breakdown | [80.lv](https://80.lv/articles/animating-guilty-gear-inspired-fighting-game-combo-in-maya) |
| 3 | Noska Sketch #50 | [RealTimeVFX](https://realtimevfx.com/t/noska-sketch-50/19460) |
| 4 | Ground crack breakdown | [1mafx](https://www.1mafx.com/blog/ground-crack-vfx-breakdown) |
| 5 | Venom Slash (splash atlas) | [RealTimeVFX / Geri](https://realtimevfx.com/t/venom-slash-breakdown-of-the-effect-included/18903) |

**Selecionadas:** 1, 2, 3.

### Leitura

- **Brais (1):** a fumaça é **malha**, não sprite; tem depth fade e dissolve. A nuvem tem lado
 claro e lado escuro, o que dá volume.
- **GG (2):** a poeira fica no chão, atrás do pé, e não acompanha o corpo; os tufos são pequenos e
 muitos.
- **Noska (3):** camadas de fumaça com antecipação; a nuvem cresce e se dissipa.

### Hoje vs. referência

O protótipo usa o atlas de fumaça (bom), mas os tufos são pequenos e uniformes, sem lado claro/
escuro e sem esteira. A poeira nasce no ponto e fica; falta a leitura de "chão".

### Proposta

- 3 classes de tamanho (0,6/1,0/1,6 m), atlas com frames diferentes, cor bege quente.
- Esteira no chão (anel com ruído) + 60% dos tufos atrás do pé.

---

## LIB-VFX-11 — Brake Dust

### 5 candidatos

| # | Obra | Fonte |
|---|---|---|
| 1 | Guilty Gear combo breakdown | [80.lv](https://80.lv/articles/animating-guilty-gear-inspired-fighting-game-combo-in-maya) |
| 2 | ZZZ attack VFX | [80.lv](https://80.lv/articles/check-out-this-fancy-real-time-attack-vfx-for-zenless-zone-zero-animation) |
| 3 | Ground crack breakdown | [1mafx](https://www.1mafx.com/blog/ground-crack-vfx-breakdown) |
| 4 | Reusable procedural smoke | [RealTimeVFX / Brais](https://realtimevfx.com/t/brais-sketchbook/31406) |
| 5 | GG Strive 2.0 — Johnny | [YouTube](https://www.youtube.com/watch?v=wyJHtD5qoQ) |

**Selecionadas:** 1, 2, 3.

### Leitura

- **GG (1):** a frenagem é um **leque baixo e largo**, com a poeira saindo para trás e para os
 lados; o corpo continua visível.
- **ZZZ (2):** a parada brusca tem faíscas e poeira no mesmo frame; a direção é oposta ao avanço.
- **1mafx (3):** o impacto de solo levanta poeira em leque, com pedras.

### Hoje vs. referência

O protótipo usa um plano com shader de leque + partículas. O leque é uma mancha cinza uniforme,
sem direção dominante e sem pedras; as partículas são fracas.

### Proposta

- Leque em **duas camadas**: densa perto dos pés, esparsa longe; ruído no alpha.
- 20–30 pedras pequenas + 8 tufos grandes; direção oposta ao movimento.

---

## LIB-VFX-12 — Ground Scratch

### 5 candidatos

| # | Obra | Fonte |
|---|---|---|
| 1 | Ground slam decals (height/normal) | [Keiren Wall](https://keirenwall.com/home/Houdini-Decals) |
| 2 | Ground crack breakdown | [1mafx](https://www.1mafx.com/blog/ground-crack-vfx-breakdown) |
| 3 | Cracking concrete (Houdini) | [80.lv / Pol Villà](https://80.lv/articles/creating-cracking-concrete-effect-using-houdini) |
| 4 | The "ground breaking" effect | [RealTimeVFX](https://realtimevfx.com/t/the-ground-breaking-effect/5832) |
| 5 | Houdini RBD II — ground destruction | [CGcircuit](https://www.cgcircuit.com/tutorial/houdini-rbd-ii---ground-destruction) |

**Selecionadas:** 1, 2, 3.

### Leitura

- **Keiren (1):** a rachadura é um **decal com height/normal/roughness** e parallax; tem
 profundidade, não é uma linha branca.
- **1mafx (2):** a fratura é **geometria** + textura + poeira; as bordas têm espessura.
- **Pol Villà (3):** rachadura com atributos e shader; o detalhe vem do material, não da malha.

### Hoje vs. referência

O protótipo desenha 3 linhas num plano, sem profundidade, com brilho uniforme. Parece um arranhão
de caneta, não uma marca no chão.

### Proposta

- Shader com **falsa profundidade**: interior escuro, borda clara, ruído no comprimento.
- 3 escalas de rachadura (principal, secundária, cabelo) + 6–10 pedras.