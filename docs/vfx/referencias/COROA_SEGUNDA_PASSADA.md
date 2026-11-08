# Impact Crown — segunda passada (quadros reais)

**Estado: INCOMPLETA.** Duas referências principais com quadro real; a terceira não foi
encontrada. Nada aqui está aprovado e o efeito não será reconstruído até o criador decidir.

## Como os quadros foram obtidos

- `yt-dlp` baixou o vídeo; `ffmpeg` extraiu o quadro no instante exato. Cada ficha traz **ID do
  vídeo, autor e timestamp**.
- Para GIFs do RealTimeVFX, o quadro foi extraído do próprio GIF (número do frame).
- **Não usei capa de artigo, banner, logo ou thumbnail.** Os quadros abaixo são do efeito.

## Referências principais (2 de 3)

### PRINCIPAL 1 — Deen_VFX, `Unreal_VFX_2023_FanArt`, 3,78 s

Fonte: https://www.youtube.com/watch?v=HVLuol2m5gQ (13 s, Deen_VFX).
Quadros extraídos: 3,70 s / 3,78 s / 3,88 s.

O que o quadro de 3,78 s mostra, sem interpretar além da imagem:

- **Silhueta:** um estouro radial com cerca de 12–16 pontas brancas, de comprimentos muito
  desiguais; algumas atingem 2–3× o raio do núcleo, outras quase não saem.
- **Núcleo:** não é um disco; é um aglomerado quebrado de fragmentos brancos, com buracos pretos
  entre eles.
- **Vazio:** há grandes áreas escuras entre as pontas. A coroa não é um anel fechado.
- **Forma das pontas:** finas na base e afinando até a ponta, com bordas irregulares (não são
  triângulos limpos).
- **Linhas externas:** além das pontas brancas, linhas azul-escuras mais longas continuam para
  fora — o efeito tem duas escalas de raio.
- **Cor:** branco-estourado no núcleo, azul-claro nas pontas, azul-escuro no fundo. Sem laranja
  ou âmbar.
- **Composição:** centrado no ponto de impacto, ocupando ~60% da altura do quadro; o personagem
  aparece pequeno embaixo. O efeito não cobre a tela inteira.
- **Sequência (3,70 → 3,78 → 3,88):** em 3,70 há um núcleo laranja pequeno com raios elétricos;
  em 3,78 o núcleo vira a coroa branca; em 3,88 restam o clarão e o personagem em close. É uma
  sequência real do mesmo plano, não uma montagem.

**O que ela prova:** a geometria de coroa radial com pontas desiguais, núcleo quebrado e vazio
negro. **O que ela não prova:** volume 3D em outra câmera (o plano é quase frontal) e
dissipação longa (o corte para o close em 3,88 interrompe).

### PRINCIPAL 2 — Impact Frame X Explosion Practice, 5,75 s

Fonte: https://www.youtube.com/watch?v=XWLX25o650c (16 s, Flipaclip).
Quadros extraídos: 5,00 s / 5,75 s / 6,25 s.

O que o quadro de 5,75 s mostra:

- **Silhueta:** uma estrela radial com **4–5 pontas dominantes** (magenta) e muitas pontas curtas
  (amarelo/laranja) preenchendo os vãos. As pontas dominantes são largas na base e afiadas na
  ponta.
- **Núcleo:** um ponto azul pequeno, cercado por magenta; não há núcleo branco.
- **Vazio:** os vãos entre as pontas dominantes são grandes e chapados (laranja), o que deixa a
  silhueta legível.
- **Cor:** magenta + amarelo + azul, com contorno escuro. É uma paleta gráfica, não realista.
- **Composição:** preenche o quadro, com simetria imperfeita; o centro está deslocado alguns
  pixels para a esquerda.
- **Sequência:** 5,00 s e 5,75 s são **práticas diferentes**, não a mesma animação; 6,25 s é
  outro efeito (uma montanha azul). Não há início/meio/fim contínuos neste vídeo.

**O que ela prova:** a leitura de silhueta com poucas pontas dominantes e vãos grandes; a
importância do contraste de cor. **O que ela não prova:** volume 3D, materiais ou dissipação —
é um desenho 2D.

## Referências complementares (não substituem as principais)

| Obra | Quadro | Por que não é principal |
|---|---|---|
| Guilty Gear Strive — Bone Crushing Excitement | 1,00 s | impacto radial no jogo, mas personagem pequeno, HUD e resolução baixa; serve para **posicionamento/timing**, não para a forma |
| Brais' Sketchbook — explosion | frame 43/108 | explosão com spikes finos; a leitura dominante é o **volume de fumaça**, não uma coroa |
| Deen_VFX — mesmo vídeo | 4,00 s | é um flash em X, não uma coroa; serve para **contraste de impacto** |

## Correções da primeira passada (descartada)

- **3dxdev / Impact Frames**: a página é sobre **dynamic smears** e over-animation; as imagens
  mostram o corpo deformado, não uma coroa. Não serve como referência principal de coroa.
- **VFX Apprentice / Genshin**: a capa é um **banner com personagens**; o artigo fala de impact
  frames e malhas de corte, mas a imagem não mostra uma coroa. Fica como referência de **timing
  de impacto**, não de forma.
- **Rebelway / One-Punch Man**: a capa é uma **cratera planetária**; é explosão de escala, não
  coroa. Complementar.
- **Genshin banner**: não mostra coroa. Removido.
- A folha `contatos/contato-crown.png` e o comparativo antigo foram **descartados**; a fonte
  agora é este arquivo e `COROA-QUADROS.png`.

## O protótipo atual vs. os dois quadros

O `LIB-VFX-14` atual é uma **coroa de 18 cones iguais** em um anel, com cunhas de base, flipbook
e detritos. Comparando com os quadros:

1. **Pontas uniformes:** os cones têm altura e inclinação quase iguais; os quadros mostram
   comprimentos de 0,2× a 3× o raio e inclinações diferentes.
2. **Anel fechado:** a base circular fecha a silhueta; nos quadros há **vazio** entre as pontas.
3. **Núcleo sólido:** o protótipo tem um clarão/flipbook no centro; os quadros têm um **núcleo
   quebrado** com buracos.
4. **Aditivo branco:** o protótipo satura em branco; os quadros têm **contraste** (branco vs.
   azul escuro; magenta vs. laranja).
5. **Escala única:** o protótipo tem um raio; o quadro do Deen tem **duas escalas** (pontas
   brancas curtas + linhas azuis longas).
6. **Sem hierarquia:** todos os cones têm o mesmo peso; nos quadros há 4–5 pontas dominantes e
   muitas secundárias.

## Geometria/silhueta pretendida (proposta, não aprovada)

Derivada apenas do que os quadros mostram:

- **10–14 lâminas primárias** com alturas 0,6–1,8× o raio, larguras 0,05–0,14× o raio e
  inclinações diferentes; **12–20 secundárias** curtas nos vãos.
- **Sem anel de base fechado.** A base é um núcleo quebrado, com buracos.
- **Duas escalas:** lâminas brancas curtas + linhas/streaks finos que vão mais longe.
- **Contraste:** núcleo branco-azulado, pontas azuis; ou paleta gráfica magenta/amarelo (a
  escolher com o criador). Nada de tudo branco.
- **Composição:** centrada no contato, com espaço negativo; não preencher a tela.
- **Volume 3D:** os quadros não provam o volume; a malha 3D precisa ser desenhada e vista de
  lado/detrás. Não copiar a frontal do Deen como se fosse 3D.

**Não defini durações, flash, hitstop ou número de frames.** Isso é decisão do criador.

## As 7 fases

A coroa é um **componente isolado**, não uma composição. Não forcei START → … → POST-IMPACT
neste efeito. As sete fases ficam disponíveis para quando a coroa for usada numa sequência
(ex.: DEMO-02), e não como obrigação de preencher sete animações.

## O que falta para completar a pesquisa da coroa

- **Terceira referência principal**, de preferência um **frame 3D de jogo** com coroa radial
  limpa: Guilty Gear Strive, DBFZ ou Sparking! Zero em câmera limpa (photo mode/replay), ou um
  breakdown de VFX com o frame isolado. A tentativa atual (GG counter) tem HUD e resolução baixa.
- Um quadro **de lado/trás** da mesma coroa, para provar volume.
- Um quadro de **dissipação** sem corte de câmera (o Deen corta para o close em 3,88).

Até isso existir, a pesquisa da coroa está **incompleta** e o efeito **não será reconstruído**.

## Arquivos desta passada

- `crown_frames/` — quadros extraídos (Deen 3,70/3,78/3,88/4,00; Flip 5,00/5,75/6,25; GG 1,00;
  Brais 43/108).
- `contatos/COROA-QUADROS.png` — 2 principais + 3 complementares + slot da 3ª (vazio).
- `contatos/COROA-SEQUENCIA.png` — sequência real do Deen e variantes do Flip (rotuladas).
- `contatos/COROA-COMPARATIVO.png` — protótipo atual × as 2 principais.
