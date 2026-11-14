<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-112 — R52-Q1 (1C): escolha tática de Move pela IA

- **Data:** 2026-11-03
- **Origem:** decisão expressa do criador na Rodada 52.
- **Estado:** regra aprovada; implementação não declarada.

## Declaração literal do criador

> 1C — Escolha de Move pela IA: Escolher de forma tática, considerando dano, fraqueza elemental, efeitos e situação do combate.

## Regra aprovada

- A IA deve escolher o **Move** de forma **tática**, considerando **dano, fraqueza elemental, efeitos e situação do combate**, em substituição à mera rotação de habilidades disponíveis.
- Aplica-se a aliados e inimigos conduzidos pela IA, preservando Tactics e simetria (D-021).
- **D-111 preservada:** o **alvo adversário** continua sendo escolhido aleatoriamente entre vivos elegíveis quando não houver engajamento; quando houver, respeitar o adversário engajado. A decisão tática é sobre o **Move**, não sobre a seleção do alvo.
- **Fonte verificada:** `Battle._pick_skill()` em `scripts/combat/battle.gd` atualmente percorre `c.skills` em sequência, selecionando habilidade pagável. A regra aprovada ainda não foi implementada nesta atividade.

## Limites

- Não foram especificados pesos, fórmulas, prioridades fixas entre dano e suporte, critério de desempate, frequência de uso ou previsão tática. Não inventar.
- Não modificar automaticamente cura, uso de itens, custos, Tactics, decisão de alvo, Evade ou comportamento de habilidades não aprovado.
- **Escopo:** somente documentação; código e testes permanecem inalterados.

## Complemento posterior — Rodada 53

**D-114/D-115 (Rodada 53):** a escolha tática de Move agora tem ordem definida: **primeiro selecionar o alvo** aleatoriamente, respeitando engajamento, **depois escolher o Move** adequado. A escolha entre cura por poção e ataque também integra a avaliação situacional, sem prioridade rígida automática só por HP ≤ 50%; respeitar Tactics e regras de itens existentes. Pesos e fórmula continuam indefinidos.

## Complemento posterior (2026-11-03)

**D-168:** implementado em `scripts/combat/battle_ai.gd`; pesos definidos por delegação (D-116).
