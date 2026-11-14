<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-113 — R52-Q2 (2C): alvo morre durante investida corpo a corpo

- **Data:** 2026-11-03
- **Origem:** decisão expressa do criador na Rodada 52.
- **Estado:** regra aprovada; implementação não declarada.

## Declaração literal do criador

> 2C — Alvo morre durante a investida corpo a corpo: Pikachu interrompe a investida e retorna imediatamente à posição de origem.

## Regra aprovada

- Se o alvo morrer **durante uma investida corpo a corpo já iniciada**, o atacante **interrompe a investida e retorna imediatamente à posição de origem**. Não retargetar o golpe durante esta investida.
- **D-108 preservada:** se a morte ocorrer no **wind-up**, antes do início da investida, ocorre troca automática para o inimigo vivo mais próximo, desde que existam outros inimigos vivos.
- **D-105/D-107 preservadas:** se a morte eliminar o último integrante da equipe adversária, o resultado é definitivo no KO; não permitir que investida pendente altere isso.
- **Fonte verificada:** `Incoming.Phase.TRAVEL` e `AttackMotion.update()` em `scripts/combat/incoming.gd` / `attack_motion.gd` representam o trajeto. O comportamento futuro ainda não foi implementado.

## Limites

- 'Retorna imediatamente à posição de origem' define a ação desejada, mas não determina explicitamente se há teleporte visual ou início imediato da animação de retorno. Não inventar FX, duração ou trajetória.
- Não modifica o comportamento de alvos que morrem depois do trajeto, durante a fase STRIKE, nem de ataques sem investida corporal.
- **Escopo:** somente documentação, sem alteração de código, animações ou testes.

