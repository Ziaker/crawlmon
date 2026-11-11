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
