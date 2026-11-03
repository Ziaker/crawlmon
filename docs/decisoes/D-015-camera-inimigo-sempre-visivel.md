# D-015 — Câmera: o inimigo deve estar SEMPRE visível (estilo Kill la Kill IF)

- **Data:** 2026-11-02
- **Área:** Câmera
- **Origem:** Conversa

## O que o criador disse (literal)

> há problemas do movimento da câmera, regras originalmente definidas de se assemelhar a forma q kill la kill if trata o movimento de câmera estão ma implementadas, o inimigo devia estar SEMPRE visível na câmera

## Decisão

A câmera de batalha deve se comportar como no *Kill la Kill: IF* e **o inimigo deve estar sempre visível**. As regras atuais de câmera estão mal implementadas.

## Resposta do criador (2026-11-02)

Pergunta "todos os inimigos ou só o alvo?":

> Sim, todos inimigos

Então o enquadramento tem de conter **todos os inimigos vivos**, não só o alvo da ação.

## Ambiguidades em aberto (perguntar antes de agir)

Não existe documento com as regras originais. Continua em aberto:
- **Comportamento do movimento:** a câmera segue os inimigos continuamente (suave) ou só se mexe quando um deles sairia do quadro (zona morta com histerese)? Não decidido; o criador disse que precisa de referência visual para decidir.
- **Margem para a HUD:** quanto da tela é reservado (HUD ocupa a parte de baixo/direita).
- **Zoom/dolly:** proibidos por D-020. Com os inimigos sempre em quadro, o pan/tilt tem de bastar; se não bastar, perguntar antes de usar zoom.

## Estado no código

**Experimento de teste (não é a decisão final).** O criador escolheu "Toggle no jogo" para
ver as variantes antes de decidir. Para isso existe, só no painel de debug (F1):

- **K** cicla o enquadramento: `OFF` (o de hoje, fixo) → `SUAVE` (a câmera gira o mínimo
  para todos os inimigos vivos caberem, seguindo de perto) → `ZONA MORTA` (só reage quando
  um inimigo passa da borda larga e só solta quando todos voltam para dentro).
- **L** liga/desliga a câmera reagir a um golpe com o menu de alvo aberto (TATICA).
- **M** liga/desliga a prioridade: um golpe no líder segura a câmera até o enquadramento acabar.
- **H** acrescenta 2 inimigos de teste **parados** nos slots seguintes (copias exatas do inimigo
  atual, política HOLD, sem esquiva); **Shift+H** os remove. Eles entram na batalha como
  inimigos de verdade (ocupam vaga, podem ser alvo, contam como vivos), só não andam nem atacam.
- **J** empurra o primeiro inimigo de teste 5 unidades para o lado (**Shift+J** para o outro),
  para ver o enquadramento ligar na hora em que ele cruzaria a borda. Só mexe nos de teste.

O enquadramento só gira a mira (pan/tilt); posição e FOV nunca mudam (D-020). Com os toggles
desligados e sem os inimigos de teste, o caminho da câmera é exatamente o de antes.

**Medição headless (2026-11-02):** com a batalha atual (1 inimigo, Gible em x=8, z=-30) o
inimigo nunca chega perto da borda — o pior caso medido num combate de 900 quadros foi
0,51 da meia-tela (a borda segura é 0,88). Com os 2 inimigos de teste nos slots (x=13 e x=18)
o pior caso sobe para **0,80**, ainda sem cruzar: em 600 quadros com golpes forçados o
enquadramento **nunca precisou agir**. Ou seja, **nesta arena o desenho de hoje já cumpre
D-015** enquanto os inimigos ficarem nos slots.

Empurrando um de teste com **J** (x=18 → 23 → 28 → 33 → 38), o enquadramento passa a agir
exatamente quando ele cruzaria a borda: o ponto fica preso em **0,94** (a borda segura, com
o inimigo em x=33–48, que é bem fora do que a câmera de hoje mostra) e `SUAVE` volta sozinho
ao enquadramento base (offset 0) quando ele retorna; `ZONA MORTA` segura o desvio enquanto
ele está fora.

**O que o criador ainda precisa ver na tela:** qual dos três comportamentos (OFF / SUAVE /
ZONA MORTA) parece com o *Kill la Kill IF* — e se a câmera deve reagir com o menu de alvo
aberto (L) e como resolver pedidos simultâneos (M). Decisão pendente dele.

**Teclas:** as três ficaram em K/L/M porque **F9 é tecla global do jogo**
(`game_state.gd`: entra/reinicia a batalha). F10/F11 também foram evitadas por precaução.
H/J foram conferidas: não são usadas em combate.
