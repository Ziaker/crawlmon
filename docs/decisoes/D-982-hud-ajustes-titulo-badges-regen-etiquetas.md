# D-982 — HUD: sem título de ação, badges maiores, regen ao lado da câmera, etiquetas mais altas

- **Data:** 2026-11-08.

## Frase literal do criador

> remove esse texto de choose your action
> o movimento dos cartões enquanto stunnado ainda é mt rapido, reduz mais um pouco
> os badges do nosso personagem estão mt colados e também mt pequenos, tem como aumentar eles 15% e afastar um pouco do cartão?
> além disso a info de regeneração não deve ficar dentro do cartão mas sim ao lado da camera direction para os 3 aliados
> alinhe melhor os pontos de interrogação no ícone
> não é necessário existir este texto de player
> os cartões dos inimigos ainda estão mt proximos deles, precisam ficar mais pra cima, eles obstruem informação, inclusive eles também precisam (o cartão de fundo preto apenas) estar com opacidade reduzida

## Decisão

1. Sai o título "01 / CHOOSE YOUR ACTION" do menu; fica só "QUEUE: <move>" quando houver um move na fila.
2. Balanço do cartão em STUN mais lento: 0,5 → 0,3 ciclo/s.
3. Badges de status do nosso personagem 15% maiores e um pouco mais afastados do cartão.
4. A contagem de regeneração de MP sai do cartão e vai para um painel "MP REGEN" à esquerda de CAMERA DIRECTION, uma linha por aliado (até 3).
5. "?" centralizado no ícone.
6. Sai o rótulo "PLAYER" do cartão do jogador ("ALLY | AI" do aliado continua).
7. Etiquetas dos inimigos mais altas (16 → 44 px acima do ponto da cabeça) e o fundo preto mais translúcido (0,62 → 0,40); o fundo claro do alvo selecionado não muda.

## Estado

Implementado para revisão.
