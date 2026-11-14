<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1154 — Telemetria de combate completa (opt-in)

- **Data:** 2026-11-11.
- **Área:** Debug / Combate / Testes / Observabilidade.
- **Origem:** conversa.
- **Status:** regra registrada; implementado e testado headless.
- **Leitura obrigatória:** `docs/TELEMETRIA.md` (guia canônico de eventos, campos, fila/pausa e como provar o diagnóstico).

## O que o criador pediu (literal)

> "o jogo não tem telemetria para a maioria das coisas ainda? coloque"

## Decisão

1. **Telemetria é opt-in de debug.** Ela só liga com `--trace`, `--stdout-trace`, `--strict-asserts` ou `CRAWL_TRACE=1` (D-1042/D-1044). O jogo normal não escreve arquivo nem paga o custo.
2. **O `BattleTrace` cobre o combate inteiro**, não só VFX:
   - linha do tempo de cada ataque (`telegraphed`, `resolved`, `phase`, `cancelled`, `interrupted`, `windup_interrupted`);
   - dano, cura, evasão, Evade manual/errado, Guard, ARMOR, escudo, STUN, Blind, Burn;
   - BP/ATB/Burst/recompensas, buffs/debuffs, passos, engajamento, morte, XP/level;
   - fila D-161 (`queue`, `started`, `lost`) e pausa de status D-031/D-1150;
   - quadro a quadro: posição, animação, HP/MP, ATB, Burst, status, buffs, Guard/ARMOR/escudo/Burn, fila, ataque atual, pausa e `Engine.time_scale`.
3. **Eventos e linhas carregam contexto suficiente para explicar o “porquê”**: quando a vaga muda, o evento diz se o Move começou (`started`) ou foi descartado (`lost`), qual status pausava, se o ator estava atacando/guardando/atordoado e o ATB/MP no instante.
4. **Nada de telemetria inventada pelo visual.** O trace lê o `Battle`/`Combatant`, que são donos do estado (D-019/D-1040).
5. **`--strict-asserts` continua falhando em anomalias**; novos detectores de fila/estado entram como `ANOMALY` quando forem inequívocos.

## Escopo desta rodada

- **Incluído:** combate (`BattleTrace`, sala de debug, runner).
- **Não incluído:** overworld/exploração, áudio, UI de menus fora do combate. Se o criador quiser, é uma camada separada (`GameTrace`) com os mesmos princípios.

## Estado no código

Implementado (2026-11-11):

- `scripts/combat/battle_trace.gd`: conexões de todos os sinais de combate, eventos de fila/pausa/status/buff/guard/armor/escudo/burn/MP/recompensa/XP e linha por quadro expandida.
- `scripts/debug/vfx_room.gd`: `queue_events`, `queue_started`, `queue_lost` no `SUMMARY_JSON`; `_busy()` considera a pausa.
- `scripts/debug/vfx_room_scenarios.gd` e `tests/battle/run_agent_combat_tests.py`: cenários `fila_status_pausa`, `fila_status_click`, `fila_war_cry`; **19/19 PASS**.
- Teste/validação: `--scenario=fila_status_pausa --stdout-trace --summary-json` mostra `queue` com `started`/`lost` e `status_pause_started/ended`.
- **Documentação:** `docs/TELEMETRIA.md` é a fonte canônica; `AGENTS.md` §1/§9/§10, `CLAUDE.md`, `docs/decisoes/README.md`, `docs/REGRAS_DO_JOGO.md`, `docs/vfx/FERRAMENTAS_VFX.md`, D-1042 e D-1044 apontam para ela e exigem a leitura.
- **Não verificado:** custo de performance do `--trace` em batalhas longas e a leitura humana de todos os campos novos.
