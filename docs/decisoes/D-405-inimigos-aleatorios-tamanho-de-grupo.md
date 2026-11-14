<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-405 — Inimigos aleatórios (Slime, Abra, Pancham, Cyclops, Orc, Gible) e chances de duplas e trios

- **Data:** 2026-11-07
- **Área:** Combate / Inimigos / Encontros / Dungeon
- **Origem:** decisão direta do criador, na conversa.
- **Estado:** implementado e validado.

## Declaração literal do criador

> "quero que adicione o slime o abra o pancham o cyclops e o orc como inimigos aleatórios ao invés de ser sempre o gible, e também adicione a chance de lutar contra uma dupla (30%) ou trio (15%)"
> "1 - sim" (Gible permanece na rotação de encontros)
> "2 - sim" (Duplicatas são permitidas em duplas e trios)

## Regra aprovada

1. **Tamanho do Grupo de Inimigos (Encontros Aleatórios):**
   - **Solo (1 inimigo):** 55% de chance ($100\% - 30\% - 15\%$).
   - **Dupla (2 inimigos):** 30% de chance.
   - **Trio (3 inimigos):** 15% de chance.
2. **Pool de Espécies Inimigas Aleatórias (6 Espécies):**
   - Slime (`dqt_slime`)
   - Abra (`abra`)
   - Pancham (`pancham`)
   - Cyclops (`dqt_cyclops`)
   - Orc (`dqt_orc`)
   - Gible (`gible`)
3. **Duplicatas de Espécies:**
   - Em encontros com duplas ou trios, é permitido sortear a mesma espécie repetida na mesma luta (ex.: dois Slimes, três Orcs).
4. **Conversão e Integridade Biológica (D-390, D-392, D-393):**
   - Cada inimigo gerado recebe conversão oficial de 15 pontos base via Hare-Niemeyer (D-390), sorteio triangular de individualidade de −3 a +3 (D-144), Nature aleatória entre as 8 canônicas (D-393) e cálculo de HP anti-hitkill (D-392).

## Ambiguidades resolvidas

- Gible permanece na rotação (confirmado pelo criador com "1 - sim").
- Duplicatas permitidas (confirmado pelo criador com "2 - sim").

## Estado no código

Implementado em:
- `scripts/combat/enemy_factory.gd`: fábrica modular canônica com pool de 6 espécies, conversão Hare-Niemeyer (15 pontos), sorteio estocástico de grupo (55% / 30% / 15%) e geração de combatente completo.
- `scripts/combat/battle_scene.gd`: integração do sorteio de encontros aleatórios em `_ready()` e delegação de `_new_gible()`.
- `tests/combat/test_enemy_encounter_generation.gd`: suíte automatizada headless com 10.000 ensaios Monte Carlo validando a convergência estatística dos grupos, conservação dos 15 pontos, fórmulas de HP/MP anti-hitkill e cobertura da pool de espécies.
