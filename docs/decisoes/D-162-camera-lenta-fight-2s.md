# D-162 — Câmera lenta de decisão: 2 s no Fight; Itens continua com 3 s

- **Data:** 2026-11-03
- **Área:** Combate / UI / Game Feel
- **Origem:** Conversa

## O que o criador disse (literal)

> reduza o timer de camera lenta ao selecionar fight pra 2 segundos ao invés de 3

Pergunta: vale para qual menu? Resposta: "Só Fight".

## Decisão

Ao abrir **Fight**, a câmera lenta de decisão dura **2 s** reais. Em **Itens** continua **3 s**. O resto de D-047 não muda: 0,2x, uso único por ação, fim ao confirmar ou cancelar.

## Ambiguidades em aberto

Nenhuma.

## Estado no código

Implementado (`battle_scene.gd`).
