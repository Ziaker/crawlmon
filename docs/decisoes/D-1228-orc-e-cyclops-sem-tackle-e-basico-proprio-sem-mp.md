<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1228 — Orc e Cyclops sem Tackle genérico; ataque básico próprio sem custo de MP

**Data:** 2026-11-15  
**Estado:** aprovada  
**Relacionadas:** D-998 (`basic_variant`), D-996 (`Spear Thrust`), D-1005 (`Boulder Smash`), D-235 (simetria)

## Frase literal do criador

> "remova o tackle do orc e do cyclops, o tackle deles é unico e tem nome próprio e NÃO deviam ter custo de MP"

## Decisão

1. Personagens que possuem uma variante de ataque básico (`basic_variant` — atualmente **Orc** com `Spear Thrust` e **Cyclops** com `Boulder Smash`) **não** recebem o `Tackle` genérico (`Skill.basic()`) na lista de combate, IA, menu Fight, barra de custo mínimo ou telas de Status.
2. Os Moves básicos próprios **`Spear Thrust`** (`content/moves/spear_thrust/move.tres`) e **`Boulder Smash`** (`content/moves/boulder_smash/move.tres`) passam a ter **`mp_cost = 0`** (mantendo ATB e demais propriedades).
3. Personagens sem `basic_variant` no loadout continuam recebendo `Tackle` (`Skill.basic()`). Aplica-se igualmente a aliados e inimigos (D-235).
