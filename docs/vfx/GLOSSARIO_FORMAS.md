<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# Glossário de formas e gestos de VFX (vocabulário compartilhado)

> Objetivo: **você não precisar descrever o efeito do zero.** Você aponta para um termo/card e diz o que muda: elemento, tamanho, fase, o que não deve ter. O assistente traduz para o pipeline.
>
> O VFX continua **pausado** (D-953). Este documento é vocabulário e organização, não cria efeito.

## Como pedir

Use o **Brief de 7 linhas**:

1. **Referência:** imagem/vídeo/jogo ou “card X”.
2. **Silhueta:** um termo da seção A.
3. **Movimento:** um termo da seção B.
4. **Fases:** wind-up → **prelúdio do ataque** → release → trajeto → impacto → retorno.
5. **Impacto:** um ou dois termos da seção D.
6. **Material/escala:** fogo/água/terra/ar/físico/psíquico/luz/trevas; pequeno/médio/grande.
7. **O que NÃO deve ter:** ex. “sem fumaça sobrando”, “sem bola extra no disparo”.

Exemplo:

> “Quero um **thrust cone** + **speed lines** no dash, **dust trail** no trajeto, **shockwave ring** + **impact crown** no impacto, fogo, médio, sem fumaça sobrando.”

## A. Formas e malhas

| Termo (PT / EN) | O que é | Onde entra | Como o projeto faz hoje |
|---|---|---|---|
| **Malha de vórtice** / *Vortex Mesh* | Funil/disco com polígonos em espiral; a textura anda (UV panning) e parece sugar para o centro. | release, impacto, portal | `vortex_disc` (Splitter Flames); M05 vórtice; `surface` shell/tube |
| **Funil / Tornado** / *Tornado / Funnel Mesh* | Estrutura cônica que afina na base e abre no topo (ou o contrário). | wind-up, impacto, barreira | `surface` shell/tube + M01 hélice; `pillar` (Media) |
| **Fita / Rastro** / *Ribbon / Trail* | Malha gerada pelo movimento; a ponta desenha uma fita 3D. | trajeto, golpe, retorno | `MotionMesh.tube`, `MotionShapes.ribbon`, `spark.trail`, TrailRenderer |
| **Cilindro em hélice** / *Helix Cylinder* | Cilindro com canais retorcidos; partículas seguem um caminho helicoidal. | release, feixe, trajeto | M01 hélice + `tube`; `surface` tube |
| **Espiral de erosão** / *Erosion / Dissolve Spiral* | O efeito não apaga de uma vez: some de fora para dentro seguindo um redemoinho. | dissipação, morte | M18 dissolução + erosão do `mc_surface`; `flipbook` |
| **Coroa de impacto** / *Impact Crown / Crown Flare* | Malha com pontas afiadas para cima/fora, no frame do impacto. | impacto | **Não existe shape pronto**; precisaria de um `crown` novo ou malha importada |
| **Anel de choque** / *Shockwave Ring / Torus Mesh* | Anel/torus que se expande rapidamente do ponto de impacto. | impacto, chegada | `ring` com `expand`; torus/malha |
| **Cone de explosão** / *Blast Cone / Impact Funnel* | Funil que aponta para o lado oposto ao golpe. | impacto | `surface` shell/cone; `shock_cone` (D-041) |
| **Fratura de chão** / *Ground Fracture* | Rachadura no chão + detritos, em teia/círculos. | impacto | `mark` no chão + `fragments`; **sem decal** no GL Compatibility |

## B. Movimento e velocidade

| Termo (PT / EN) | O que é | Onde entra | Como o projeto faz hoje |
|---|---|---|---|
| **Cone de propulsão** / *Cone Flash / Thrust Cone* | Cone translúcido que envolve o personagem no avanço; distorce o fundo. | release, dash | `surface` shell/cone; `shock_cone`; distorção de tela |
| **Linhas de ação** / *Speed Lines / Action Lines* | Linhas atrás do personagem, retas ou helicoidais. | trajeto, impacto | `streaks` + M21; speed lines da câmera (D-041) |
| **Rastro de fita** / *Motion Trail / Ribbon Trail* | Fita contínua presa ao corpo/pés enquanto ele se move. | trajeto, retorno | `tube`/`ribbon`, `spark.trail`, TrailRenderer |
| **Estouro de aura** / *Aura Burst* | Explosão helicoidal para trás no instante do impulso. | release | M16 burst + halo/puff |
| **Poeira de corrida** / *Dust Trail / Dash Smoke* | Nuvens de poeira nos pés durante a corrida. | trajeto | `puff`/flipbook + M22/M23 |
| **Poeira de frenagem** / *Scuff / Brake Dust* | Poeira em cone/leque quando o personagem para. | impacto, retorno | M16 para trás + poeira; `mark` |
| **Arranhão de chão** / *Ground Scratch* | Terra/pedras subindo em espiral/linhas paralelas ao arrastar. | trajeto, frenagem | `mark` + `fragments` + poeira |

## C. Impacto e leitura

| Termo | O que é | Onde entra | Como o projeto faz hoje |
|---|---|---|---|
| **Estouro / flash** | Clarão curto no contato. | impacto | `halo`, `flipbook`, `spark` |
| **Cone direcional** | Onda de pressão que segue o golpe. | impacto | `surface` shell/cone; `shock_cone` (D-041) |
| **Anel no chão** | Onda circular rasteira. | impacto | `ring` (expand) + poeira |
| **Cratera / fratura** | Rachadura + detritos. | impacto | `mark` + `fragments`; sem decal |
| **Respingo / coroa de água** | Coroa de gotas que sobe e cai. | impacto | `surface` shell + `drops` |
| **Estilhaço / cacos** | Fragmentos que quicam no chão. | impacto | `surface` fragments + M23 com `floor_y` |
| **Fumaça / fuligem** | Resíduo que sobe e some. | impacto, dissipação | `puff`/flipbook; `mc_puff` |
| **Faíscas** | Pontos quentes com rastro. | impacto | `spark` + `trail_dt` |
| **Pulso de luz** | Luz omni curta no contato. | impacto | representação `light` (pool) |

## D. O que o Motion Composer faz bem — e o que não faz

**Faz bem:** vórtice, funil, fita, hélice, erosão/dissolução, cone, speed lines, poeira, anel, estilhaço, faísca, fumaça, pulso de luz, timing de fases.

**Não faz (ou faz mal):** coroa de impacto com pontas (precisa de shape/malha nova), fratura de chão com decal (GL Compatibility não tem decal; usar `mark`), animação do corpo/personagem, câmera/composição, bloom/post.

**Regra:** o golpe principal é **shot à mão** (animação/contato, malhas/flipbooks, câmera). O Composer entra no **secundário** e no **timing** (D-954).

## E. Próximo passo: biblioteca visual

Transformar este glossário em **cards HTML** com:

- GIF/vídeo de 3–5 s (de preferência um efeito aprovado do projeto);
- nome PT/EN;
- tags (silhueta, movimento, fase, material);
- “como o projeto faz hoje”;
- botão **copiar brief**.

Ordem: primeiro os efeitos já aprovados (Abra v9, D-041, atelier), depois os cards neutros de forma/gesto. **Nenhum efeito novo é criado.**
