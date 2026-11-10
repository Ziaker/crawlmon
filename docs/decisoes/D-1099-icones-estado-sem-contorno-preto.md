# D-1099 — Ícones de estado sem contorno preto

- **Data:** 2026-11-10.
- **Área:** Exploração / overworld 3D / arte dos 5 ícones de estado (`?`, `!`, fúria, suor, conversado).
- **Relacionadas:** D-1098 (ícones 3D), D-1086 (ícones de estado), D-1090 (ícones +25%), D-1095 (medalhão/retrato, que **não** muda), D-1097 (Flat Card A, que **não** muda), D-235 (nada depende de personagem/time/lado).
- **Status:** **implementado/provado e aprovado** pelo criador ("muito melhor, aprovo", 2026-11-10); commit local; **sem push**.

## O que o criador disse (literal)

> eu tirava o outline preto dos ícones

> muito melhor, aprovo

Na pergunta de esclarecimento, escolheu:
- **Quais ícones:** “Estado 3D: contorno da arte” — os 5 ícones de estado, não o medalhão do retrato.
- **Como tirar:** “Preencher com a cor do ícone” — o preto vira a cor do próprio ícone; o tamanho e o relevo 3D continuam.

## Regra

1. **Os 5 ícones de estado perdem o contorno preto da arte.** O contorno é preenchido com a **cor do próprio ícone** (a base é branca e recebe o tint do estado em jogo), então o desenho fica mais cheio, do tamanho atual, sem a linha preta.
2. **Nada de silhueta menor:** a alpha e o tamanho de 1,00 m continuam; a malha 3D **não** é refeita. O relevo, a lateral/fundo escuros, o yaw de -28°, o tint, o “pop” e a escala por distância (`0,55 + dist/16`) ficam como na D-1098.
3. **Altura:** continua `altura + 1,75 m` (D-1098); o inimigo continua com placa em `2,20 m` e ícone em `1,05 m`.
4. **O que não muda:** medalhão/retrato e sua borda preta (D-1095), Flat Card A (D-1097), batalha, 2D, HUD/status, cards, regras, falas, câmera e retratos.

## Implementação

- Editar `assets/ui/overworld_icons/state_question.png`, `state_alert.png`, `state_anger.png`, `state_sweat.png` e `state_talked.png`: todo pixel visível vira branco (o tint do estado colore em jogo), mantendo a alpha original; as texturas viram máscaras brancas.
- Reimportar as texturas no Godot; as malhas `assets/ui/overworld_icons3d/*.obj` continuam as mesmas (a alpha não mudou).
- Regerar as provas de frente, lado, fundo, os 5 estados e o cenário; na prova do cenário, usar um ângulo/fase em que o arbusto não cubra o ícone (ele balança com o vento).

## Provas

- `docs/referencias/exploracao/3d/state_icon_3d_states.png` — os 5 estados sem contorno.
- `docs/referencias/exploracao/3d/state_icon_3d_front.png` — o `?` 3D sem contorno.
- `docs/referencias/exploracao/3d/state_icon_3d_side.png` — lateral 3D.
- `docs/referencias/exploracao/3d/state_icon_3d_back.png` — fundo.
- `docs/referencias/exploracao/3d/state_icon_3d_inworld.png` — no cenário, acima do Flat Card A.
- `docs/referencias/exploracao/3d/ACEITACAO_D1098_D1099.md` — aceitação no lab (5 estados no NPC/inimigo, perto/longe/espelho); folhas `acceptance_d1098_*.png`.
- `docs/referencias/exploracao/3d/murky_forest_lab_state_icons.mp4` — vídeo de 35,8 s; GIF dos 5 estados do inimigo: `murky_forest_lab_enemy_states_preview.gif`.

## O que foi verificado

- As 5 texturas continuam com a **mesma alpha** (silhueta) e agora só têm RGB branco; o contorno preto virou a cor do ícone.
- Os 5 estados (`question`, `alert`, `anger`, `sweat`, `talked`) renderizam em 3D sem contorno, com o tint de cada estado.
- O `?` no cenário, sem contorno, na mesma altura `+1,75 m` e acima do Flat Card A.
- Aceitação: 5 estados no NPC e no inimigo, perto/médio/longe/espelho; o ícone do inimigo aparece acima do Slime na câmera alta; vão do NPC **0,58/0,45/0,025 m** a 3,0/4,4/9,0 m.
- Vídeo de 35,8 s (walkthrough real + inspeção); o `✳` de fúria do inimigo encosta no topo do Slime; o `?` e o `!` ficam acima.
- `scenes/debug/murky_forest_3d_lab.tscn` headless: `exit=0`; check do script OK.

## O que não foi verificado

- Todos os estados em todas as distâncias e no inimigo em jogo. A aceitação cobre a câmera alta, perto/médio/longe/espelho; **câmera baixa, o inimigo em patrulha real e as 10 alturas de NPC** ficam fora.
- Mobile/60 fps/resoluções e a cena principal completa (VFX de outra sessão).

## D-1105 (posterior)

O card mudou de base e de escala por distância, e o ícone passou a ficar acima dele. A arte sem contorno desta decisão permanece.

## Estado

Implementado, provado e aprovado. Commit local; **sem push**.
