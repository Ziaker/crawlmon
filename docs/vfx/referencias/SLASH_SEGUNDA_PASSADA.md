# Slash Arc — protótipo verificado

**Estado: tecnicamente verificado; aguardando sua aprovação visual.** Nada foi declarado aprovado.
O Crown ficou de lado a seu pedido; este é o componente com três referências principais que mostram
a geometria.

## Referências principais (quadros reais)

| # | Obra | Fonte | O que o quadro mostra |
|---|---|---|---|
| 1 | **Lucie Travaux — Slash VFX** | https://lixsh.artstation.com/projects/ea8PrX | crescente de fogo em volta do corpo, gume branco, corpo laranja, brasas |
| 2 | **Mourad El Ghali — Fire Slash** | https://mouradzzz.artstation.com/projects/3EaexB | arco de fogo + carga branca em zigue-zague, silhueta preta |
| 3 | **Ali's Sketchbook — procedural slash (MIT)** | https://realtimevfx.com/t/alis-sketchbook/29539/6 | crescente branco/roxo, revelação e dissipação em GIF |

Complementares: **Stt Sketch #22** (arco branco fino) e **Venom Slash** (atlas de respingos).
Folhas: `contatos/SLASH-QUADROS.png` e `contatos/SLASH-COMPARATIVO.png`.

## O que foi implementado

Arquivo: `prototypes/vfx_library/src/effects/slash.js` (`createSlash`), ligado ao `LIB-VFX-20`.

- **Paleta de fogo calibrada:** gume `#fff2c4`, corpo `#ff7a12`, borda interna `#4a0f00`.
  A paleta de energia continua disponível nos controles de cor (ciano/violeta).
- **Orientação horizontal:** o arco é ancorado no **alvo** (`-dist`), na altura do peito, e o
  percurso corre em X/Z **atravessando o corpo**. A fita tem altura (0,55) e o gume na borda
  inferior. A versão anterior estava no plano XY, com o `tilt` girando o arco para cima, e o
  corpo ancorado no atacante; o `headPoint` das faíscas já usava `-dist`, o que mascarava o erro.
- **Três camadas:** under-trail escuro, corpo colorido e gume branco fino.
- **Volume cruzado:** uma segunda fita perpendicular à primeira, com 55% da largura. É o que
  mantém o arco legível de lado e de topo; sem ela, a fita sumia de perfil.
- **Textura de chama:** FBM em duas escalas + `flame` (ruído cruzado) + listras longitudinais
  + erosão na cauda.
- **Carga em zigue-zague:** tubo de 6 segmentos do punho à cauda do arco, branco aditivo,
  visível antes da revelação e apagado quando o arco abre (ref. Mourad).
- **Atlas real:** 6 respingos com `assets/vfx/flipbook_impact.png` (4×4), presos à cabeça do arco.
- **Faíscas:** duas populações (cabeça para fora; borda interna para trás) + estilhaços escuros.
- **14 controles:** ângulo, raio, espessura, inclinação, revelação, permanência, dissipação,
  faíscas, respingos, carga, under-trail, gume, corpo e borda.

## Verificação (com evidência)

| Item | Resultado | Evidência |
|---|---|---|
| Página carrega | 26 cartões, **0 erros de console** | aba `http://127.0.0.1:8126/...` |
| Inspector | 14 controles ativos | leitura do DOM |
| Carga | zigue-zague branco antes do arco | `captures/slash-final-charge.png` |
| Pico 3/4 | crescente horizontal atravessando o alvo | `captures/slash-h1.png` |
| Lado | volume visível, não some de perfil | `captures/slash-h1-side.png` |
| Trás | arco legível por trás do alvo | `captures/slash-final-back.png` |
| Topo | arco com largura e volume | `captures/slash-h1-top.png` |
| Espelhado (D-235) | arco no alvo, faíscas no lado invertido | `captures/slash-final-mirror.png` |
| DEMO-05 | rastro + arco com faíscas internas, sem as douradas antigas | `captures/demo-final.png` |
| Performance | **48 draw calls**, **12.204 triângulos**, 32 geometrias, 16 texturas; update **0,048 ms/frame** no pico (300 frames) | `renderer.info` + `bench(300)` |

## Escolhas de arte (suas, não defeitos)

- O corpo é **fogo estilizado**, não uma simulação de chama; a referência da Lucie tem mais
  turbulência e brasas soltas.
- A carga é **um zigue-zague** curto, não um prelúdio completo; se ela deve durar mais ou ter
  mais segmentos, é ajuste de direção.
- O **atlas de respingos** usa o `flipbook_impact.png` do projeto; o atlas do Venom não está no
  repositório.
- A **paleta de energia** (ciano/violeta) está a um clique nos controles de cor; a de fogo é o
  padrão.
- O arco é uma fita com volume cruzado, não um tubo fechado; é o que mantém a leitura de corte.

## Fases

O Slash é um componente isolado. Não forcei as sete fases nele; elas ficam disponíveis para
quando ele entrar numa composição (DEMO-05). Não defini durações, flash ou hitstop como regra.

## Abrir

```powershell
python prototypes/vfx_library/serve_nocache.py .
# http://127.0.0.1:8126/prototypes/vfx_library/index.html → LIB-VFX-20
```
