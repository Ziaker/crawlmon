<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1147 — War Cry: congelamento visual é feature; sem aura genérica; cone não nasce em cast cancelado

- **Data:** 2026-11-11.
- **Área:** Combate / War Cry / Pausa visual / VFX.
- **Origem:** resposta do criador à investigação de pausa de status.
- **Status:** regra registrada; implementado e testado headless.

## O que o criador disse (literal)

> "opção 1, war cry congelar a animação faz sentido com o move, não é bug, é feature"

> "tira a aura e corrige o vfx, NÃO MUDE a mecanica da pausa, é feature do move"

## Decisão

1. **O congelamento visual das animações dos outros durante o War Cry é feature.** O motor continua **sem** entrar em `_status_pause` (D-1127): ATB, preparos, IA e movimento dos outros continuam correndo. O que congela é a **animação** dos personagens que estavam em clipe de ataque/retorno, como parte do impacto do grito. Não tratar como bug.
2. **A mecânica da pausa do War Cry não muda:** `_status_pause` continua nulo; `status_pause_started`/`status_pause_ended` continuam sendo emitidos para a faixa e para o congelamento visual; `_war_cry_active` continua fechando o evento quando o Move termina ou é cancelado.
3. **Sem aura genérica:** o War Cry não recebe mais a aura/anel/estrela da D-031 no lançador. O VFX do War Cry é só o cone/anel da D-1106.
4. **Cone não nasce em cast cancelado:** se o War Cry for interrompido antes de o grito sair, o VFX do cone **não** deve ser disparado no RETURN sintético da interrupção. O cartão quebrado (D-1104) e o flinch (D-1105) continuam.
5. **Cone bem-sucedido:** o instante do cone no War Cry concluído **não muda** nesta rodada; a correção é só impedir o disparo no cast cancelado.
6. **Congelamento com dono:** cada evento de pausa (War Cry ou Move de status real) descongela apenas as animações que ele mesmo congelou. O fim de um War Cry não pode descongelar uma pausa real que começou depois, e vice-versa.

## Relação com decisões existentes

- **D-1127:** o motor do War Cry continua sem pausa. Esta decisão corrige a frase da D-1127 que dizia que o War Cry “não congela ninguém”: o congelamento **visual** é intencional.
- **D-1106:** o VFX do War Cry é o cone/anel; a aura genérica da D-031 sai.
- **D-031/D-1040:** o congelamento visual continua valendo; a pausa real e a lógica seguem na mesma linha do tempo.
- **D-1104/D-1105:** o cartão quebrado e o flinch continuam no interrupt.

## Ambiguidades em aberto

- O instante exato do cone no War Cry **concluído** (hoje no RETURN/impacto) não foi alterado; se o criador quiser o cone começando no fim do wind-up, é ajuste novo.
- A duração/tamanho do cone não mudam nesta rodada.

## Estado no código

Implementado e testado headless (2026-11-11):

- `scripts/combat/battle_fx.gd`: lotes de congelamento por `Incoming` (fim de um evento não descongela o outro); War Cry mantém o congelamento e perde a aura genérica; cone só em RETURN não interrompido; `finish()` descongela todos os lotes.
- `docs/decisoes/D-1127-war-cry-sem-pausa-de-status.md`: nota de complemento.
- `tests/battle/test_d1146_queue_and_status_pause.gd` — **passa**: War Cry com `_status_pause == null`, animação congelada, lote descongelado só no fim do próprio War Cry e cast cancelado sem cone.
- Regressão `test_d1102_war_cry.gd` — **passa**.
- **Não verificado:** vídeo in-game, duas vistas e o caso de War Cry + pausa real sobrepostos no mesmo quadro.
