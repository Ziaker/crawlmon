<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1160 — Interrupção visual só para interrupção real; desvio automático é erro

- **Data:** 2026-11-11.
- **Área:** HUD / Combate / Feedback de interrupção.
- **Origem:** o criador relatou cartões sendo destruídos com `INTERRUPTED` em Moves que funcionavam normalmente e em desvios automáticos.
- **Status:** regra registrada; implementada e testada headless. Corrige o escopo da D-1104.

## O que o criador disse (literal)

> "tem moves com o efeito de interrupção e destruição ocorrendo mas que funcionam normalmente, corrija esse bug, tem moves que não estão realmente sendo interrompidos mas tem a notificação visual de que estão, além de também aparecer interrupções para desvios automáticos, isso tá incorreto, interrupção não funciona assim"

## Decisão

1. **Interrupção visual = interrupção real.** O cartão só é destruído (9 estilhaços + eco `INTERRUPTED`) quando a ação é **realmente parada no meio**:
   - um golpe cancela o **wind-up**;
   - um golpe para o **trajeto/golpe antes do impacto**;
   - **War Cry**/status cancela o wind-up;
   - um **choque** entre corredores para a ação.
2. **Desvio manual e desvio automático não são interrupção.** O ataque é um **erro** (D-104/D-106): continua a animação e termina normalmente; o cartão usa a saída normal (`leave()`), sem estilhaços e sem `INTERRUPTED`.
3. **Golpe durante o retorno não é interrupção da ação.** A ação já atingiu o alvo e está voltando; o cartão sai normalmente. O `interrupted` mecânico continua sendo usado para encerrar o retorno.
4. **Fim de batalha, morte do atacante, limpeza e restauração de estado não são interrupção.** Não destroem cartão nenhum.
5. **Fonte única:** o HUD lê apenas `Incoming.interruption_feedback`, marcado exclusivamente nos caminhos de interrupção real. `Incoming.interrupted` continua sendo o estado mecânico e **não** deve ser usado sozinho para o feedback visual.
6. **Simetria D-235:** vale para qualquer personagem, time, lado e vista.
7. **A D-1104 continua valendo** para o efeito em si (9 estilhaços, eco centralizado, 0,55 s, tipografia e flash); o que muda é **quando** ele acontece.

## Relação com decisões

- **D-1104:** o item 2 listava Evade manual e Evade automático como interrupção. Esta decisão **corrige esse item**: Evade é erro (D-104/D-106), não interrupção. O restante da D-1104 (efeito, duração, eco, estilhaços) permanece.
- **D-104/D-106:** Evade é evasão, não defesa perfeita; os ataques desviados terminam como golpes que erraram, sem animação de interrupção.
- **D-019/D-1040:** apenas feedback de HUD; nenhuma regra de combate muda.
- **D-1154:** o trace ganhou o campo `interruption_feedback` em `_inc`; `interrupted` sozinho não prova interrupção visual.

## Ambiguidades em aberto

- **Choque:** foi tratado como interrupção real porque a corrida é parada e não golpeia. Se o criador não quiser o efeito de cartão destruído no choque, é ajuste local.
- **Várias interrupções no mesmo quadro:** não verificado em vídeo; o efeito já suporta vários cartões.
- **Verificação visual:** o teste é headless; falta assistir em vídeo nas duas vistas.

## Estado no código

Implementado e testado headless (2026-11-11):

- `scripts/combat/incoming.gd`: novo campo `interruption_feedback`.
- `scripts/combat/battle.gd`: marca o campo em War Cry, golpe que cancela wind-up, golpe que para o trajeto antes do impacto e choque; **não** marca no retorno, no fim de batalha nem na limpeza.
- `scripts/combat/battle_evade.gd`: Evade cancela a própria corrida com `interrupted` mecânico, **sem** `interruption_feedback`.
- `scripts/ui/battle_hud.gd`: `shows_interruption_feedback(inc)` e os dois gatilhos de `_sync_incoming` usam só o novo campo.
- `scripts/ui/attack_tag_shatter.gd`: comentário de escopo corrigido.
- `scripts/combat/battle_trace.gd`: `interruption_feedback` no evento.
- Teste: `tests/ui/test_d1160_interruption_feedback.gd`.

## Verificação (2026-11-11)

- Teste D-1160: **18/18 PASS** (`D1160_INTERRUPTION_FEEDBACK_TEST_PASS`).
- Suíte `python tests/battle/run_agent_combat_tests.py`: **23/23 PASS**.
- Desvio automático forçado (`--move=Tackle --force=dodge --preflight=9 --stdout-trace`): o trace mostra `auto_dodged:true`, `interrupted:false`, `interruption_feedback:false`.
- Interrupção real (`--scenario=mach_interrompe_windup --stdout-trace`): `ev:"cancelled"` com `interrupted:true` e `interruption_feedback:true`.
- **Não verificado:** vídeo do HUD nas duas vistas; muitos cartões quebrando no mesmo quadro; desempenho.

