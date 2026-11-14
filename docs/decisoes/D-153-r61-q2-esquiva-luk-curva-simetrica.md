<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-153 — Rodada 61 Q2 (2A): aplicar curva de esquiva de forma simétrica a diferenças negativas de LUK

- **Data:** 2026-11-03.
- **Área:** Combate / esquiva automática / LUK.
- **Origem:** escolha literal do criador na Rodada 61.
- **Estado:** decisão aprovada e registrada documentalmente; não implementada.

## Declaração literal do criador

> 2A — aplicar simetricamente a curva escolhida, reduzindo a chance quando LUK do defensor for inferior.

## Regra aprovada

- Adotar **a mesma curva de ganhos marginais decrescentes da D-152** para a magnitude absoluta da diferença **LUK defensor − LUK atacante**.
- Diferença positiva **aumenta** a chance-base de esquiva; diferença negativa **reduz** a chance-base pelo mesmo valor absoluto de correção. Diferença zero mantém **10%**.
- Expressão descritiva: **P_esquiva = clamp(10% + sinal(Δ) × F(|Δ|), 0%, 100%)**, com **Δ = LUK_defensor − LUK_atacante** e **F(x)** a soma dos ganhos marginais por faixas de 10 definidos na D-152.
- Exemplo ilustrativo da questão: defensor LUK **40**, atacante LUK **70**: **Δ = −30**, **F(30) = 17,5 pp**; **10% − 17,5 pp = −7,5%**, limitado a **0%** pela D-151.
- Para **Δ = −5**, a correção é **−5 pp** e a chance final fica **5%**. Para **Δ = +5**, fica **15%**.

## Limites

- A regra não altera a reação ativa da IA (D-021), os custos de Evade, o crítico normal (D-150) ou a aplicação probabilística de status (D-146).
- A chance-base histórica de D-005 passa a ser base, não chance final imutável, conforme D-127.
- LUK não tem teto permanente 100 (D-139), mas a chance final tem limite (D-151).

## Escopo

Registro documental apenas; sem implementação.
