<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1230 — Fórmula da chance de Employ (base inicial de calibração)

**Data:** 2026-11-15  
**Área:** combate, balanceamento  
**Estado:** **implementada** (`EmployMath` ligado ao combate pela D-1240; respeito fixo em 50 e bônus de ritmo 0 por enquanto). Coeficientes são **base inicial de calibração**, não equilíbrio comprovado.  
**Origem:** briefing "IMPLEMENTAÇÃO FASEADA DE EMPLOY, SUMMON E RESPEITO" colado pelo criador.  
**Relacionadas:** D-1229, D-1231, D-122, D-127, D-139, D-269.

## Texto literal do briefing do criador

> "Para cada aliado participante: `power_i = max(STR_i, MAG_i)`. Força conjunta: `A = sum(power_i)`. Força do alvo: `E = max(STR_enemy, MAG_enemy)`. Componente de força: `F = 45 × A / (A + E)`. Componente de nível: `N = clamp(2 × (level_traveler - level_enemy), -20, 20)`. Componente de respeito: `R = 0.16 × (respect - 50)`. Bônus de ritmo: `B = sum(note_bonus)`. Chance final: `P = clamp(F + N + R + B, 0, 100)`."

> "Os coeficientes representam a base inicial de calibração aceita na discussão de design. Isso não equivale a equilíbrio comprovado."

> "Implementar o cálculo independentemente da HUD. Não criar teto de 100 para atributos. Separar o cálculo determinístico da rolagem aleatória. Preservar regras de RNG, seeds e rastreabilidade existentes. Não executar rolagens desnecessárias para chances finais de 0% ou 100%, observadas as regras já estabelecidas. Não misturar a chance de recrutamento com crítico, dano, esquiva ou status. Não introduzir LUK como modificador adicional. Não ajustar coeficientes silenciosamente para obter resultados desejados."

## Decisão

A fórmula acima, exatamente como escrita. LUK não entra. Sem teto de atributos (coerente com D-139/D-269).

## Pendências declaradas pelo criador

- Participantes elegíveis quando há aliados nocauteados.
- Evento exato do pagamento dos 5 ATB.
- Contrato completo de RNG do recrutamento.
- "Se esses pontos impedirem um comportamento definitivo, implementar primeiro apenas a função pura e seus testes."

## Pendências achadas na auditoria (perguntar)

- **RNG:** o combate usa `randf()` global; só existem `debug_roll` (`battle.gd:137`) e `--seed=` (`battle_trace.gd:51`). Não há RNG compartilhado nem regra no código sobre pular sorteio em 0%/100%.
- **Atributos lidos:** efetivos (com Nature e pontos de nível) ou base; com ou sem buffs ativos.
- **`level_traveler`:** nível do líder (`party[0]`), já que não existe entidade "Traveler" no código.
- **Arredondamento** de `F` e `R` (a fórmula dá frações) e a forma de comparar a rolagem com `P`.

## Estado no código

Nada implementado.
