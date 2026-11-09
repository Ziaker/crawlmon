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
Folhas: `contatos/SLASH-QUADROS.png` e `contatos/SLASH-COMPARATIVO.png` (refeito com o visual cel).

## O que foi implementado

Arquivo: `prototypes/vfx_library/src/effects/slash.js` (`createSlash`), ligado ao `LIB-VFX-20`.

- **Paleta de fogo calibrada:** gume `#fff2c4`, corpo `#ff7a12`, borda interna `#4a0f00`.
  A paleta de energia continua disponível nos controles de cor (ciano/violeta).
- **Linguagem cel (D-038/D-323):** o corpo usa **três bandas chapadas** (`step`) — contorno
  escuro no dorso, laranja no meio e gume quente na borda de corte — com alpha sólido
  (0,94–0,97). O under-trail escuro ficou mais largo (1,30×) e mais opaco; o gume aditivo perdeu
  o excesso de brilho (1,2×). As manchas de fogo são degraus (`step`), não gradientes.
- **Orientação horizontal:** o arco é ancorado no **alvo** (`-dist`), na altura do peito, e o
  percurso corre em X/Z **atravessando o corpo**. A fita tem altura (0,55 × escala) e o gume na
  borda inferior. A versão anterior estava no plano XY, com o `tilt` girando o arco para cima, e
  o corpo ancorado no atacante; o `headPoint` das faíscas já usava `-dist`, o que mascarava o erro.
- **Escala pelo alvo:** o raio, a espessura e a altura de base saem do `Box3` do alvo
  (`k = bodyH / 2,12`). Medido: **1,94× a altura do alvo** em 0,7×, 1,0× e 1,4×; a caixa do
  arco fica sempre em `z -4,00…-3,45` e cruza o corpo. É a lição da auditoria (D-974) para esta
  biblioteca HTML; **não** é a regra de tamanho fixo da D-308, que vale para VFX de Move em combate
  (ver “Divergência registrada”).
- **Três camadas:** under-trail escuro, corpo colorido e gume branco fino. O volume cruzado (35%
  da largura) dá espessura, mas **de perfil o arco vira uma linha**; a leitura principal é 3/4,
  espelhada e à distância.
- **Carga em zigue-zague (D-235):** o punho é derivado do `Box3` do atacante (largura, altura e
  profundidade) e a carga avança no eixo atacante→alvo, sem coordenada fixa; o comprimento usa a
  escala do atacante (`ka`), não a do alvo. No espelhado, a caixa da carga é simétrica:
  `x -1,11…0,29`, `z 0,29…2,09`.
- **Faíscas:** duas populações (cabeça para fora; borda interna para trás) + estilhaços escuros;
  os offsets usam a largura já escalada (`W`).
- **Atlas real:** 6 respingos com `assets/vfx/flipbook_impact.png` (4×4), presos à cabeça do
  arco, com vida curta (0,20 s).
- **14 controles:** ângulo, raio, espessura, inclinação, revelação, permanência, dissipação,
  faíscas, respingos, carga, under-trail, gume, corpo e borda.

## Pesquisa aplicada (2026-11-08)

- **`docs/vfx/galeria/mc_v12_fire/water/earth/air.png`, `mc_v13_fogo_cel_composer.png` e
  `mc_v15_fogo_chamas_diferentes.png`:** bandas chapadas, contorno escuro, silhueta nítida e
  paleta limitada. O Slash passou de fita luminosa para corpo sólido em três bandas.
- **`docs/vfx/ELEMENTOS_V1.md`:** a receita de fogo tem corpo, núcleo quente, línguas, brasas,
  flash e fumaça. Aqui o corpo é a fita, o núcleo é o gume e as brasas são as faíscas.
- **`docs/vfx/auditorias/AUDITORIA_ELECTRIC_BEAM.md`:** carga à frente do corpo no eixo; efeito
  no alvo proporcional ao corpo do alvo; leitura à distância testada; uma mudança visível por
  entrega; não declarar aprovado.
- **`docs/vfx/referencias/projeteis/`:** decomposição em fases e leitura a 8–37 m. O Slash é um
  componente isolado; as fases ficam para a composição (DEMO-05).
- **D-235:** carga e arco derivados do atacante/alvo; espelhado e escalas testados.
- **D-038/D-323/D-332:** cel-shading em bandas duras; fogo por shader + flipbook, não modelo 3D.
  Esta biblioteca HTML não tem Motion Composer; as lições de shader/flipbook foram aplicadas à mão.

## Verificação (com evidência)

| Item | Resultado | Evidência |
|---|---|---|
| Página carrega | 26 cartões, **0 erros de console** | aba `http://127.0.0.1:8126/...` |
| Inspector | 14 controles ativos | leitura do DOM |
| Carga (D-235) | zigue-zague à frente do punho; caixa simétrica no espelhado | `captures/cel3-charge.png` (3/4) e `captures/cel3-charge-side.png` (de perfil, o zigue-zague lê); espelhado `x -1,11…0,29`, `z 0,29…2,09` |
| Pico 3/4 | crescente horizontal atravessando o alvo, bandas chapadas | `captures/cel3-slash.png` |
| Espelhado (D-235) | mesmo arco no alvo, lado invertido, sem mudar de tamanho | `captures/cel3-mirror.png` |
| Alvo 0,7× | arco 2,86 m de largura, 0,46 m de altura; 1,94× a altura do alvo | `captures/cel3-scale-070.png` |
| Alvo 1,4× | arco 5,73 m de largura, 0,91 m de altura; 1,94× a altura do alvo | `captures/cel3-scale-140.png` |
| Câmera a 16,5 m | arco ainda legível | `captures/cel3-dist-16.png` |
| Lado | de perfil vira uma linha; o volume não preenche a seção | `captures/cel3-side.png` |
| Trás | arco legível por trás do alvo | `captures/cel3-back.png` |
| Topo | arco com largura e volume | `captures/cel3-top.png` |
| DEMO-05 | rastro + arco cel, sem as douradas antigas | `captures/demo-cel3.png` |
| Performance | **48 draw calls**, **12.204 triângulos**; update **0,009–0,016 ms/frame** no pico (300 frames, duas medições) | `renderer.info` + `bench(300)` |

## Divergência registrada (D-308)

A D-308 item 6 fixa o tamanho do VFX em metros, igual nas duas vistas, e diz que ele **não** depende
da altura do alvo. Esta biblioteca HTML é um protótipo isolado, fora do protocolo de combate, e usa
a lição oposta da auditoria (D-974): escala proporcional ao corpo do alvo. As duas regras convivem
em escopos diferentes; se você quiser que a biblioteca siga a D-308, eu troco para tamanho fixo e
refaço as capturas.

## O que não foi verificado

- Atacante com malha diferente do dummy: a carga é derivada do `Box3`, mas só testei o dummy da
  biblioteca.
- Alvo animado/rigado: a caixa usada para a escala é estática.
- Aprovação visual.

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
- A escala é proporcional ao alvo (1,94× a altura); se você preferir um crescente mais justo,
  o fator é ajuste de direção.

## Fases

O Slash é um componente isolado. Não forcei as sete fases nele; elas ficam disponíveis para
quando ele entrar numa composição (DEMO-05). Não defini durações, flash ou hitstop como regra.

## Abrir

```powershell
python prototypes/vfx_library/serve_nocache.py .
# http://127.0.0.1:8126/prototypes/vfx_library/index.html → LIB-VFX-20
```
