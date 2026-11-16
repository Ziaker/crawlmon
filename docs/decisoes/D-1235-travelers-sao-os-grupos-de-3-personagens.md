<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1235 — Travelers são os grupos de 3 personagens; o protagonista é um deles

**Data:** 2026-11-15  
**Área:** narrativa, progressão, recrutamento  
**Estado:** **registrada; nada implementado.** Só documento (D-061).  
**Relacionadas:** D-1230 (`level_traveler`), D-1231 (Respeito "do Traveler individual"), D-1233 (3 ativos), D-1210 (equipe rival).

## Frase literal do criador

> "Travelers são os grupos de 3 personagens, o prota é um deles"

(resposta à pergunta "O Traveler é o protagonista escolhido no pré-jogo?")

## Decisão

1. **Travelers** é o nome dos **grupos de 3 personagens**.
2. O **protagonista é um dos integrantes** do grupo.

3. **O Respeito pertence ao grupo.** Pergunta: "O Respeito pertence ao grupo de Travelers ou ao protagonista?" Resposta literal do criador: > "Ao grupo"

## Conflitos e ambiguidades em aberto (perguntar antes de implementar)

- **D-1231 × D-1235 (resolvido em 2026-11-15):** o briefing dizia "O Respeito pertence ao Traveler individual. Não deve ser copiado para outro personagem quando a ordem da equipe mudar." Com a resposta "Ao grupo", o Respeito é um valor do grupo de Travelers; a frase do briefing fica preservada na D-1231 como histórico.
- **D-1230:** `level_traveler` na fórmula de Employ: nível do protagonista, média ou maior nível do grupo — não definido.
- **Composição:** se o grupo muda (Convocação, recrutas, substitutos), o que identifica "o mesmo" grupo de Travelers.
- **Rivais (D-1210):** se a equipe rival também é um grupo de Travelers com Respeito próprio.

## Estado no código

Nada implementado. `RespectState` (Fase 2) é um valor sem dono definido; a Fase 3 depende das respostas acima.
