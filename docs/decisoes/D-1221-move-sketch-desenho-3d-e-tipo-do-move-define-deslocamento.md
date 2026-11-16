<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1221 — Move Sketch: o criador desenha o movimento do Move em 3D, e o tipo do Move define se o corpo se desloca

- **Data:** 2026-11-15
- **Relacionadas:** D-1206 (Move Forge), D-308 (quatro fases), D-235 (Move independente de personagem e lado), D-1218 (dados antes de imagens), D-999 (avanço do corpo no golpe corpo a corpo).

## Frases literais do criador

> "agora eu quero que planeje um sistema onde eu possa desenhar o movimento de moves pra IA usar como referência para a implementação de moves"

> "tá mas isso é 2D, não tem como fazer algo assim 3D"

> "tem que saber como definir se é um move melee, se é um move de status e se é um move mid-range ou long range (define se o boneco se desloca ou não"

> "ainda está mt básico, não é utilizável"

## Decisão

- Haverá uma ferramenta (protótipo HTML em `prototypes/move_sketch/`) onde o criador desenha o movimento de um Move em 3D; o desenho é referência para a IA implementar o Move.
- A ferramenta tem de permitir definir se o Move é **melee**, **status**, **mid-range** ou **long range**.
- Essa escolha **define se o boneco se desloca ou não.**

## Correção do criador (2026-11-15), literal

> "mid-range DESLOCA, LÊ OS DOCUMENTOS"

A primeira versão da ferramenta fazia o mid-range ficar parado (erro da IA, que se baseou só no comentário de `skill.gd`). Corrigido: **mid-range desloca o corpo.**

## O que as decisões já dizem (lidas em 2026-11-15)

- **D-395:** o Alcance de um Move é Melee, Mid Range, Long Range ou nenhum (status).
- **D-1194** (criador): "moves que envolvem moimentacao no caso os melee e mid range" / "projeteis tem sim trajeto mas nao sao afetados por agi" / "mid-range = `Skill.Kind.CAST` (D-1073)". Portanto melee e mid-range têm movimentação; projétil (long range) tem trajeto do projétil, não do corpo.
- **D-420 / D-436:** o deslocamento do atacante é descrito por Move (estacionário, corrida corpo a corpo, recuo, teleporte, projétil, feixe).
- **D-996 / D-997:** a distância de parada vem da ficha do Move: o padrão é `STAND_GAP` 2,6; o Spear Thrust para a 7,0.
- **D-1220:** os arquétipos de movimento (`melee_strike`, `projectile_travel`, `aoe_wave`, `status_aura`) têm checagem cinemática; o JSON do Move Sketch é a referência a ser comparada por ela.

## Confirmação do criador (2026-11-15), literal

À pergunta "Long range e status ficam parados e o corpo para onde defino por Move?", o criador respondeu:

> "Sim, confirmado"

Vale para as duas partes da pergunta: (a) long range e status não deslocam o corpo; (b) onde o corpo para é definido por Move (item 2 abaixo). Os números de trabalho (84%, 60%, tempos das fases) **continuam sendo da IA, não do criador**.

## Pedido do criador sobre fases (2026-11-15), literal

> "está faltando fases de moves ainda"

Fases já decididas nos documentos: **D-308** (Wind-up, Release, Trajeto, Impacto); **D-956** (para VFX de projétil, seis fases: Start, Wind-up, Release, Trajectory, Impact, Post-impact; Start dispara o wind-up, Post-impact é a dissipação do impacto); **motor** (`Phase.TRAVEL/STRIKE/RETURN`, `--phase=windup|release|travel|strike|impact|return`, AGENTS §9.2).

A ferramenta passou a ter as **8 fases** (Start, Wind-up, Release, Travel, Strike, Impact, Post-impact, Return), cada uma com caixa de ligar/desligar e duração. O conjunto ligado por tipo é **recomendação da IA, não decisão**: melee e mid-range = Wind-up, Release, Approach, Strike, Impact, Return; long range = as seis de D-956; status = as quatro de D-308.

## Pedido do criador sobre o prelúdio (2026-11-15), literal

> "falta o prelude do impacto"

O **prelúdio do ataque** (Hit-windup, "dodge prelude") já existe nas decisões: D-953 (nome adotado), D-990 ("Swing" e "Hit-windup" são a mesma fase), D-987/D-988 (janela do Evade = primeiros 0,25 s da fase de golpe), D-1014 ("moves de mid-range ainda tem os delays e preludios dos moves melee"), D-1016/D-1017 (Drain Spear, 0,2 s). A ferramenta ganhou a fase **Prelude** (nº 5, entre Approach e Strike), 250 ms de trabalho (D-987). Ligada por recomendação em melee e mid-range; desligada em long range e status (D-965 e D-1029 falam de prelúdio também em projétil: a confirmar).

## Pedido do criador sobre formas (2026-11-15), literal

> "falta também uma ferramenta de criação de formas geometricas, quadrado, circulo, losango, paralelepipedo e outras, quero mais 20 formas além destas"

> "tá mas oq q é isso? eu disse FORMAS, não emojis, formas de verdade"

A primeira versão (ícones minúsculos e planos numa paleta) foi **rejeitada** pelo criador. Refeita como ferramenta de criação: formas sólidas (as planas ganham espessura), com arestas, criadas **arrastando na cena** para dar o tamanho, e editadas com alças de mover, girar e escalar, números de largura/altura/profundidade, poses de início e fim (a forma se transforma ao longo das fases) e parâmetros por forma (lados, raio interno, furo, espessura). 24 formas: as 4 pedidas (quadrado, círculo, losango, paralelepípedo) + 20 escolhidas pela IA (triângulo, pentágono, hexágono, octógono, estrela, anel, cruz, seta, meia-lua, esfera, cubo, cilindro, cone, pirâmide, tetraedro, octaedro, dodecaedro, icosaedro, toro, prisma). **As 20 foram escolha da IA, sem aval do criador.**

## Em aberto (nada disto está decidido)

0. Quais fases cada tipo usa (acima) e as durações padrão (Start 150, Wind-up 400, Release 120, Travel 300, Strike 150, Impact 260, Post-impact 200, Return 400 ms, todas valores de trabalho da IA).
1. Mapa dos tipos para o motor: melee = MELEE, mid-range = CAST, long range = PROJECTILE, status = STATUS (D-1194 confirma mid-range = CAST; long range = PROJECTILE é leitura da IA).
2. Onde o corpo para no mid-range e no melee: a ferramenta tem um controle "parar a X% do caminho" com valores de trabalho da IA (melee 84%, mid-range 60%), que **não são regra**. A distância real em unidades do jogo vem da ficha do Move (D-996/997).
3. Tempos padrão das fases (400/120/300/260 ms): valores de trabalho da IA, editáveis.
4. ~~Long range e status ficam parados~~ — confirmado pelo criador (acima).

## Estado

Registrada. Protótipo `prototypes/move_sketch/move_sketch.html` corrigido (mid-range desloca). Nada no Godot.
