<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1158 — Fase 3: `RESIST` a 0,5×

- **Data:** 2026-11-11
- **Área:** Combate / afinidades / dano / UI / telemetria.
- **Origem:** o criador mandou auditar a Fase 2 e começar a Fase 3.
- **Estado:** implementado e testado; comportamento dos dados atuais preservado.

## Declaração literal do criador

> "auditorie a fase 2 e comece a fase 3"

## Regra aprovada

1. **RESIST = 0,5×.** O multiplicador entra na **mesma expressão única** da ofensa, junto de fraqueza/crítico/passos:
   `round(stat × poder × afinidade × crítico × passos)`, mínimo 1.
2. **Ordem:** afinidade ofensiva → WIS → Guard → escudo → `def_buff`. É a mesma posição da WEAK.
3. **Exceções:** Drain Spear (`5 + MAG − SPI`), Burn/dano fixo e status não usam afinidade. `NULL` e `REPEL` ficam reservados e sem uso (D-1161); `DRAIN` não está implementado.
4. **Semântica explícita:** uma entrada em `affinities` vence, inclusive `NEUTRAL` e `WEAK`. `weaknesses` é o fallback legado para Combatants manuais e dados antigos. O VFX room sincroniza as duas fontes ao forçar/restaurar fraqueza.
5. **UI:** a ficha de combate mostra `RESIST 0.5×`; a lista de Moves mostra `RESIST`; o `LevelUpHUD` passou a ler `affinity_for()` em vez das siglas hardcoded. As telas de Status/StatusPanel/Menus ainda usam a lista antiga de fraquezas e ficam para a rodada de UI.
6. **Telemetria:** o `info` do evento `hit` carrega `affinity`, `affinity_mult` e `affinity_applied`; o log mostra `RESISTIU! (x0.5)`. Campos documentados em `docs/TELEMETRIA.md` (D-1154).

## Escopo

- **Entra:** RESIST 0,5×, semântica explícita de `affinities`, telemetria e UI principal de combate.
- **Não entra:** NULL/REPEL (reservados, D-1161), DRAIN, dados de resistência por espécie, VIT física, correção do HUD `info.dmg` × HP, Brick Break/Guard break.

## Estado no código

- `Affinity.RESIST_MULT = 0.5` e `damage_multiplier(RESIST)`.
- `Combatant.affinity_for()` honra `NEUTRAL`/`WEAK` explícitos.
- `Battle._hit` adiciona `affinity`, `affinity_mult`, `affinity_applied` ao `info` e loga `RESISTIU!`.
- `SkillInfoPanel` e `BattleScene` mostram RESIST.
- `VFX room` força/restaura a afinidade na tabela, não só em `weaknesses`.
- Testes: D-1152 (golden com caso RESIST) e D-1157 (schema + NEUTRAL/WEAK explícitos + RESIST) passam.
- Nada de commit/push sem autorização (D-022).
