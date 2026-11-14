<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-108 — Rodada 49, Q2 (2B): redirecionar para o inimigo vivo mais próximo durante wind-up

- Data: 2026-11-03
- Origem: resposta expressa do criador.
- Estado: regra aprovada e registrada; não implementada nesta atividade.

## Declaração literal do criador

> 2B — Como escolher o novo alvo quando o alvo original morre durante o wind-up? O jogo troca automaticamente para o inimigo vivo mais próximo.

## Regra aprovada

- Se o **alvo de um ataque iniciado** morrer durante o **wind-up** e existirem outros inimigos vivos, **o jogo troca automaticamente para o inimigo vivo mais próximo** e o ataque prossegue contra esse novo alvo (complemento da D-103).
- **Não exige uma nova seleção manual do jogador**. Não se aplica quando a morte do alvo elimina o último inimigo, caso em que se fixa a vitória (D-105).
- Não altera os alvos já definidos para um **projétil em voo** (D-047), nem o conjunto fixado de alvos de ondas AoE (D-037/D-058).

## Limites

- Nenhum novo custo, reinício do wind-up, duração ou política para empate entre distâncias iguais foi aprovado.
- Os critérios geométricos detalhados de proximidade não foram especificados além de 'inimigo vivo mais próximo'.
- Somente documentação; não alterou código, FX, dados nem testes.

## Complemento posterior — Rodada 52

**D-113 (R52):** a troca automática de alvo se restringe ao **wind-up**. Após iniciar a investida corpo a corpo, se o alvo morrer, interromper a investida e retornar imediatamente à origem, sem troca de alvo para este golpe.
