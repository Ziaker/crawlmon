# D-991 — Rastro do tamanho da arma, alinhado nela; aviso de Evade na arma

- **Data:** 2026-11-08.

## Frase literal do criador

> o dodge notification aparece muito mais a esquerda do cyclops do que acima dele (indicando a arma), mude isso nele.
> na segunda imagem, quanto ao efeito do rastro, ele devia ser grande como a marreta e corretamente alinhado no meio

## Decisão

1. Quem segura uma arma (malha presa a um único osso com nome de arma: "buki", "weapon", "wmodel"…): o rastro do Swing cobre **o comprimento inteiro da arma**, centrado nela, seguindo sua orientação real.
2. O aviso da janela de Evade (D-986) fica **no meio da arma**, e não ao lado do corpo. Sem arma, segue a regra de D-989.
3. Nomes genéricos, nunca por espécie (D-235).

## Estado

Implementado para revisão.
