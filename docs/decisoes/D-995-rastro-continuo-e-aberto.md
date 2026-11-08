# D-995 — Rastro do Swing contínuo e aberto

- **Data:** 2026-11-08.

## Frase literal do criador

> o movimento do rastro está desligando e ligando ao invés de seguir como uma animação completa
> nas duas imagens, a forma como vc fez (em vermelho) está erro, o trajeto tem que estar aberto eamplo como na segunda imagem

## Decisão

1. O membro seguido é **travado** assim que escolhido (a troca de mão a cada quadro fazia o rastro piscar).
2. O rastro vira uma **faixa aberta e larga ao longo do caminho da mão** (centrada na mão, abrindo para fora do centro do corpo), não mais a cunha estreita do antebraço que se fechava junto ao corpo.
3. Vale para todos os atacantes com mão (inclui o Abra, que precisa ser reconferido).

## Em aberto

- Parada estranha entre as animações (corrida → pulo/golpe) do Pancham entre 2 e 3 s: a investigar.

## Estado

Implementado para revisão.
