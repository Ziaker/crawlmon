<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1032 — Pré-checagem e gravação podem sortear encontros diferentes

- **Data:** 2026-11-09
- **Área:** VFX / Ferramentas / D-1020
- **Origem:** resposta do criador à pergunta 3 da auditoria.

## Frase literal do criador

> "3 - é aceitável sortear"

## Decisão

1. A pré-checagem e a gravação **podem** rodar em processos separados e sortear encontros diferentes. Não é obrigatório fixar seed nem repetir o mesmo alvo entre as duas.
2. A seleção continua **por lado/papel**, nunca por índice fixo (D-235). O atacante é o primeiro vivo do lado pedido; o alvo `opponent` é o primeiro vivo do lado oposto.
3. O log de cada vista registra o alvo real da gravação; o manifesto guarda a linha da pré-checagem. Se o alvo gravar diferente da pré-checagem, isso é aceitável; o vídeo e o log da gravação são a prova do que foi gravado.
4. Não há exigência de igualar o encontro entre a vista normal e a espelhada.

## Ambiguidades em aberto

Nenhuma.

## Estado

Regra registrada. Nenhuma mudança de código necessária. Sem commit/push.
