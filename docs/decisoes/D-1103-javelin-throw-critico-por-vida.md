<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1103 — Javelin Throw: 0,75 s, 5 MP e crítico por vida do alvo

- **Data:** 2026-11-10.
- **Área:** Combate / Moves / Custos / Crítico.
- **Origem:** escolha do criador depois da rodada de opções do Javelin Throw.
- **Status:** regra registrada; **implementada**; aguardando teste in-game.

## O que o criador disse (literal)

> "wind up de .75 pro javelin throw custo de mp 5"

> "ideia C com % de chance de critico aumentado quanto menos vida o alvo tiver"

## Decisão

1. **Javelin Throw** continua `PROJECTILE`, **Physical** (ícone Physical), elemento **Neutral** (o `FISICO` do código), **long range**, **alvo único**.
2. **Custo:** **2 ATB / 5 MP**. O ATB continua 2; o MP sobe de 3 para 5.
3. **Wind-up:** **0,75 s** (era 1,0 s no `.tres`; a ficha dizia 1,30 s).
4. **Dano:** **1,2× ATK** (não muda).
5. **Opção C (crítico):** a chance de crítico **cresce conforme o HP atual do alvo cai**. Mantém os **10% base** e o crítico **×2** com **+1 ATB**.
6. **Limite:** a chance final fica em **0–100%** (D-151).
7. **Fórmula final:** `P_crit = clamp(10 + (LUK_atacante − LUK_alvo) + 20 × (1 − HP_atual/HP_máximo), 0, 100)`.
   - Os **10% base** e o **bônus de LUK** seguem a D-150 (1 pp por ponto de diferença, atacante − alvo).
   - O bônus por vida perdida é **linear**: 0 pp com o alvo cheio, até **+20 pp** quando o HP atual tende a zero.
   - O bônus de LUK **não muda** com a vida do alvo; só a parcela de 20 pp escala com a vida perdida.
   - O HP usado é o **HP atual antes do dano deste golpe**, em % do HP máximo.
   - A chance final é limitada a **0–100%** (D-151).
8. **Nada mais muda:** esquiva, fraqueza, recompensa de ATB, tipo, elemento e alcance continuam iguais.

## Segunda rodada

> "quanto ao critico do javelin throw ele deve escalar com LUK tambem, no caso e 10% base + ate 20%+LK baseado na vida perdida (o valor adicional dado pela LK nao muda, so a porcentagem aumentada pela vida reduzida)"

- Fórmula fechada como acima. **Sem ambiguidades em aberto.**

## Estado no código

Implementado (2026-11-10), **aguardando teste in-game**:
- `content/moves/javelin_throw/move.tres` (2 ATB / 5 MP / wind-up 0,75 s) e `scripts/data/skill_legacy_data.gd`.
- `Battle.crit_chance_for()` em `scripts/combat/battle.gd`; `_hit` usa essa função no lugar da chance fixa.
- Teste: `tests/battle/test_d1103_javelin_crit.gd` (passa).
- Vídeos in-game (2026-11-10): `test_captures/vfx_tools/javelin_throw_d1103_dqt.mp4` (Orc no lado do jogador na vista normal; espelhado) e `javelin_throw_d1103.mp4` (party padrão). Log normal: impacto em **2,200 s** com `crítico=true` e dano 31. VFX **genérico** de projétil; o audit de vazamentos acusou **1 nó residual** (`ScaledFx`), então não é VFX final D-308.
