# D-314 — Fila de aliados: rastro exato, sem atravessar

- **Data:** 2026-11-05
- **Área:** Exploração
- **Origem:** Conversa (respostas Q1 e F2 do plano do overworld)

## O que o criador disse (literal)

> Rastro exato, sem atravessar

> Espera 1 s e reposiciona

> Sim; contato inicia batalha

## Decisão

1. Os aliados ativos seguem o **rastro exato** do protagonista, **sem atravessar** paredes/obstáculos.
2. Se um aliado ficar preso, ele **espera 1 s**; se continuar preso, vai para o **ponto livre mais próximo atrás do líder**.
3. Aliados **podem atravessar inimigos**: inimigos não são corpos sólidos e o contato de um aliado com um inimigo **inicia batalha** (R37-Q1).

## Ambiguidades em aberto

- “Ponto livre mais próximo atrás do líder” é o ponto mais próximo na trilha ou qualquer tile livre adjacente? (detalhe de implementação; seguir a trilha primeiro)

## Estado no código

Não implementado. Detalha a D-309.
