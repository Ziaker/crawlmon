<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-009 — AoE de projétil: onda única, cada alvo é atingido no seu tempo

- **Data:** 2026-11-02
- **Área:** Combate
- **Origem:** Conversa

## O que o criador disse (literal)

> A, B, B, B, ... (respostas 3 e 4 da lista de ambiguidades de AoE)

## Decisão

**3B:** AoE de projétil = **uma única onda** que atinge todos. **4B:** cada alvo é atingido **no seu próprio tempo** (conforme a chegada da onda).

## Ambiguidades em aberto (perguntar antes de agir)

Como a duração/velocidade da onda é calculada (por distância de cada alvo?) — não foi dito; perguntar antes de implementar.

## Estado no código

**Não implementado.**
