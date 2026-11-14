<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-241 — Mach Punch acerta 0,20 s depois de chegar ao alvo (clipe de ataque acelerado)

- **Data:** 2026-11-05
- **Área:** Combate / tempo de golpe / animação
- **Origem:** Conversa. Depois da investigação da D-240 (todo golpe corpo a corpo espera 0,87 s no alvo antes de acertar), o criador escreveu:

> teoricamente os 3 moves não deviam ter esse .87 segundos pra realizar o ataque

e, às perguntas desta rodada, respondeu (frases dele):

- Escopo: "é pra ocorrer no momento que chega no alvo e a animação correspondente é realizada"
- Tempo: "na verdade apenas o match punch com .20"
- Animação: escolheu "Acelerar o clipe para o contato cair no novo tempo".

## Decisão (interpretação aplicada)

1. **(Substituído acima pela extensão ao Karate Chop e ao Brick Break.) Só o Mach Punch muda**: depois de chegar ao alvo ele acerta em **0,20 s**, sem a antecipação de 0,08 s (antes: 0,87 s). Karate Chop e Brick Break **continuam em 0,87 s**: a primeira frase citava 3 moves, mas o criador corrigiu com "na verdade apenas o match punch".
2. O clipe de ataque do atacante toca **mais rápido durante o golpe** (velocidade = tempo de contato atual do clipe ÷ 0,20 s, ~4×), então o soco visual acerta junto com o dano. Ao sair do golpe a velocidade normal volta.
3. Vale para o Mach Punch de **qualquer personagem** que o tenha e também quando o atacante já está engajado ao lado do alvo (D-235: por `move_id`, não por personagem).
4. Nada mais muda: wind-up (0,2 s), custo, dano, tempo de corrida (0,18 s base), hit-stop e VFX ficam como estavam.

## Ambiguidades em aberto

- Se Karate Chop e Brick Break devem mesmo ficar em 0,87 s (a frase inicial dizia que "os 3 moves não deviam ter" esse tempo; a correção diz "apenas o match punch").
- O 0,20 s é o tempo **total** de espera no alvo (inclui o que antes era antecipação); a fórmula "contato do clipe ÷ 0,20" é a mesma suposição de contato que o planejador já usa para os outros golpes (metade do clipe, limitada a 0,8 s), não o contato medido do clipe do Pancham (~0,64–0,72 s).

## Extensão ao Karate Chop e ao Brick Break (2026-11-05, escolhas expressas)

Depois do teste dos tempos o criador respondeu "sim" a reduzir a espera de Karate Chop e Brick Break e escolheu:

- Tempo: **"0,45 s os dois"** depois da antecipação.
- Antecipação: **"Manter 0,08 s de antecipação"** (não acertam direto como o Mach Punch).

Aplicado: a espera no alvo (STRIKE) do Karate Chop e do Brick Break passa de 0,88 s para **0,53 s** (0,08 de antecipação + 0,45), com o clipe de ataque ~1,8× mais rápido para o contato cair nesse tempo. Isto **substitui** o item 1 da decisão original ("só o Mach Punch muda"). A tabela `BattleSpace.STRIKE_HIT` guarda os três tempos por `move_id` (D-235: vale para qualquer personagem que tenha o Move).

Medido (`tests/vfx/test_melee_timers_karate_brick.gd`, 6 combinações de atacante e alvo por Move, Gible, Abra e Pancham):

| Move | wind-up | corrida | espera no alvo | release → acerto |
|---|---|---|---|---|
| Mach Punch | 0,20 s | 0,36 s | 0,20 s | 0,56 s |
| Karate Chop | 1,00 s | 0,57 s | 0,53 s | 1,09 s |
| Brick Break | 1,51 s | 0,36 s | 0,53 s | 0,89 s |

O teste também encontrou duas falhas da **sala de VFX** (não do jogo), corrigidas: a vida da party era multiplicada por 4 a cada recarga (estourava depois de ~12 recargas e a party morria), e o Fire Bullet era somado de novo à lista a cada recarga.

## Teste pedido pelo criador (2026-11-05): Karate Chop e Brick Break feitos por Gible, Abra e Pancham

"faz um teste, mande gibble e abra realizarem karate chop e brick break e analise os timers". `tests/vfx/test_melee_timers_karate_brick.gd` dá os dois Moves aos três personagens (D-235) e mede 6 combinações de atacante e alvo por Move na sala de VFX:

| Move | wind-up | corrida (TRAVEL) | espera no alvo (STRIKE) | release → acerto |
|---|---|---|---|---|
| Karate Chop | 1,00 s | 0,57 s | 0,88 s | 1,45 s (acerto em 2,45 s) |
| Brick Break | 1,51 s | 0,36 s | 0,88 s | 1,25 s (acerto em 2,76 s) |

Resultado: **os tempos são do Move, não do personagem**: wind-up, corrida e espera são iguais para Gible, Abra e Pancham e nos dois sentidos (variação máxima de 0,01 s, arredondamento de quadro). Esses dois Moves usam um tempo de corrida fixo (0,45 s e 0,24 s de base, menos 0,10 s por passo de posição), então a corrida não depende nem da distância. A espera de 0,88 s no alvo vale 61% do tempo pós-release do Karate Chop e 70% do Brick Break.

## Estado

Implementado (`BattleSpace.MACH_PUNCH_HIT`, `Incoming.strike_speed`, `AttackPlanner`, `FxMotion._boost_strike`). Medido na sala de VFX: STRIKE do Mach Punch 0,20 s (0,565 → 0,765 s); Karate Chop segue 0,88 s. Sem commit.
