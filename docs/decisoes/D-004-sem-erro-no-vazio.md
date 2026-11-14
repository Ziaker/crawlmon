<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-004 — Ataques e projéteis acertam o alvo mesmo fora do trajeto original

- **Data:** 2026-11-02
- **Área:** Combate
- **Origem:** Conversa

## O que o criador disse (literal)

> remova isso dos projéteis e ataques não acertarem os alvos caso eles estiverem fora do trajeto original definido quando seus oponentes estiverem carregando, principalmente quanto a projéteis, já que não funciona direito

## Decisão

Não existe mais "errar o vazio" porque o alvo saiu do ponto original. Ataques e projéteis seguem o alvo e acertam. Revoga a regra do `PROMPT` que fazia os golpes já partidos errarem o vazio.

## Ambiguidades em aberto (perguntar antes de agir)

Nenhuma.

## Estado no código

Implementado (`void_miss` removido).
