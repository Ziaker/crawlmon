# D-961 — Electric: posição na vista espelhada e coroas que contornam o corpo

- **Data:** 2026-11-07.

## Frase literal do criador

> no espelhado, o efeito está mal posicionado, não está na frente do personagem como é no normal, corrija isso, além disso aumentea largura do movimento das coroas de choque, se o personagem for grande pode acabar por passar por dentro dele, e isso poderá ser um erro. Quanto a iluminação e as cores do move, me sugira melhorias,

## Causa (dados)

O inimigo mede 3,9 × 6,1 m (largura × profundidade) e o ponto "à frente" usava a menor medida (1,9 m). A carga ficava em z −28,3, dentro do corpo, que vai até −27,9.

## Decisão

1. "À frente" usa a **extensão real do corpo no eixo do tiro**, mais 0,45 m; o lado visível da câmera usa a extensão transversal. Vale para qualquer corpo e qualquer lado (D-235, D-958).
2. As 5 partes de cada coroa se afastam para fora **pelo raio do corpo do atacante mais 0,6 m**, e assim passam em volta dele, nunca por dentro.
3. Iluminação e cores: o assistente propõe; nada é feito sem aprovação.
