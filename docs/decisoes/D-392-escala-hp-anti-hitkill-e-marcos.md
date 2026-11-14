<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-392 — Escala de HP anti-hitkill (+10/nível, +25 marcos, +2/VIT)

- **Data:** 2026-11-07
- **Área:** Combate / atributos / balanceamento
- **Origem:** decisão direta do criador, na conversa.
- **Estado:** regra registrada; sem código.

## Declaração literal do criador

> naturalmente todos personagens a cada nivel recebem +10 de hp por nível + 25 para cada décimo nivel (1, 10, 20) + 20 para cada 10 pontos de VIT (é só um valor aleatorio eu ainda não sei como definir isso e acho melhor vc definir esse escopo numerico pra mim, a ideia é que não aja tanto dano explosivo a ponto de causar hitkill, então estes valores estão altos por conta disso)

## Regra aprovada

- Todos os personagens recebem **+10 de HP por nível**.
- Nos marcos a cada 10 níveis (níveis 1, 10, 20, 30...), recebem **+25 de HP adicional** (além dos +10 normais daquele nível).
- Cada ponto de **VIT concede +2 de HP** (proporção de +20 HP a cada 10 pontos de VIT).
- No nível 1 com VIT 2–4, o HP inicial resulta em **39 a 43 HP**, alinhado aos ~35–45 HP do jogo atual, garantindo combate sem mortes instantâneas (*hitkill*).
- Fórmula fechada:
  $$\text{HP} = 25 + 10 \times \text{Nível} + 25 \times \lfloor\frac{\text{Nível}}{10}\rfloor + 2 \times \text{VIT}$$

## Ambiguidades em aberto (perguntar antes de agir)

- Nenhuma.

## Estado no código

Nenhuma alteração.
