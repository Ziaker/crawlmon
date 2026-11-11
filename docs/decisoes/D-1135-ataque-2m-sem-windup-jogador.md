# D-1135 — Ataque do Z: teto de 2,0 m e sem wind-up do jogador

- **Data:** 2026-11-10.
- **Área:** Overworld 3D / lab Murky Forest / ataque / timing.
- **Relacionadas:** D-1100, D-1112, D-1114 (substituída na parte do intervalo), D-1115, D-1120, D-1127.
- **Status:** **implementado/provado**; código na árvore de trabalho; **sem push**.

## O que o criador disse (literal)

> inclusive faça uma mudança no ataque, reduza a distancia percorrida pra 2M para ambos jogador e inimigos e também remova o wind-up pra esse ataque do botão Z no overworld

## Regra

1. **Teto de 2,0 m:** o avanço máximo do jogador e de cada inimigo passa a **2,0 m**. O código continua parando no contato, na parede ou no alvo mais próximo; 2,0 m é o **limite**, não um teleporte fixo.
2. **Sem wind-up no Z do jogador:** o `PRE_DASH_TIME` de 0,12 s deixa de existir **só para o ataque do jogador**. `player_dash_started` continua sendo emitido e o clipe `attack` continua tocando a 2,0× no início do avanço (D-1112).
3. **Inimigo mantém o telegraph e o pré-avanço:** 0,4 s de telegraph + 0,12 s de pré-avanço continuam (D-1100/D-1114). Não zerar `PRE_DASH_TIME` global.
4. **Impacto de 0,5 s e alcance de 4,5 m continuam** (D-1115/D-1100). Um alvo longe demais pode ser adquirido e o avanço de 2,0 m errar, como já previsto.
5. **Empate (branco) continua existindo** (D-1100): a mudança de timing altera quando ele ocorre, não a regra. Os testes que montavam o empate durante o pré-avanço do jogador precisam ser ajustados para o momento dos dois dashes.
6. **D-235:** o teto vale para qualquer ator/lado; a ausência de wind-up é só do input Z do jogador, não uma dependência de personagem/time.

## Implementação

- `scripts/overworld/overworld_attack_controller.gd`: `PLAYER_DASH_MAX = 2.0`, `ENEMY_DASH_MAX = 2.0`; `_start_player_windup` captura a origem e emite `player_dash_started`, depois chama `_start_player_dash()` imediatamente; o inimigo continua em `PRE_DASH_TIME`.
- Testes de ataque: atualizar o tempo total do jogador (~0,68 s), a janela de cooldown e o cenário de empate; manter os testes do inimigo.

## Provas

- `tests/overworld/test_overworld_attack.gd`: **PASS** (todas as linhas), incluindo `player starts the advance immediately (D-1135, no wind-up)`, `player dash is already active on the first frame`, `attack reaches the battle in ~0.68 s (0.18 + 0.5): 42 frames` e o empate branco com o inimigo já em dash.
- `tests/overworld/test_end_to_end_attack_flow.gd`: **END_TO_END_ATTACK: OK** (player-first, enemy-first e Gible/derrota).

## O que foi verificado

- O jogador entra no dash no mesmo frame do Z; o clipe `attack` continua tocando a 2,0× e o ponto de retorno é capturado antes do dash.
- O inimigo mantém telegraph de 0,4 s + pré-avanço de 0,12 s.
- `PLAYER_DASH_MAX` e `ENEMY_DASH_MAX` valem 2,0 m; o ataque continua parando no contato/parede.
- O impacto de 0,5 s e o alcance de 4,5 m não mudaram.

## O que não foi verificado

- Se o teto de 2,0 m deixa o ataque curto demais na prática; o alcance de aquisição continua 4,5 m e alvos acima de ~3,3 m podem ser adquiridos e errar.
- A sensação visual do empate com o novo timing.

## Estado

Implementado e provado. Código na árvore de trabalho (o controller ainda não está commitado pela outra sessão); **sem push**.
