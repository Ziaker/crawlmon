<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1011 — Líder sempre visível; menu e cartão do líder acompanham, sempre à esquerda dele

- **Data:** 2026-11-08.
- **Origem:** Conversa (depois da etapa 1 da D-1010, em que o líder correndo passou atrás do menu).

## Frase literal do criador

> o modelo do lider sempre deve estar visível e o menu também deve acompanhar ele, sempre mais a sua esquerda, corrija isso

Respostas às perguntas:

- O que se move: **"Menu + cartão do líder"**.
- Como acompanha: **"Só horizontal, suave"** (mesma altura de hoje; desliza no x, logo à esquerda do líder, com limite na borda da tela).
- Líder visível: **"Câmera afasta/abre"** (se o líder chega perto da câmera ou da HUD, a câmera recua/abre o FOV rápido o bastante).
- Lâmina de info do move (Fight): **"outro agente esta mexendo nela no momento, ignore"** — não mexer nela.

## Revisão (mesma data)

> não gosto da forma como ele se movimenta junto do personagem, não precisa se movimentar pra direita toda vez que ele vai realizar um move

Escolha do criador: **"Fixo, mas desvia se cobrir"**. O menu e o cartão ficam no x fixo (28) e só se deslocam (para a direita do líder) se o líder ficaria atrás deles. Corridas, golpes e voltas do líder não movem o bloco. Os itens 1 abaixo ficam substituídos por isto; o resto vale.

## Revisão 2 (mesma data)

> vamos voltar atrás com a hud, deixe fixo e não faça ela ficar se movendo, só a obrigue a reduzir opacidade caso o personagem fique dentro dela, pra 55% de opacidade

Respostas: aciona **qualquer personagem** (vivo, aliado ou inimigo); o fade vale **"apenas menu"** (a lista de comandos; o cartão do líder não). Menu e cartão ficam **fixos** em x=28 (nada de se deslocar nem desviar). Quando o corpo de qualquer personagem cruza o retângulo do menu, o menu cai para 55% de opacidade (suave) e volta a 100% ao sair. Substitui a Revisão 1 e o item 1 abaixo.

## Decisão

1. O menu (lista de comandos) e o cartão do líder acompanham a posição do líder na tela só no eixo horizontal, com deslizamento suave, ficando sempre à esquerda do líder, com limite na borda esquerda.
2. O modelo do líder fica sempre inteiro na área segura (D-1010); a câmera recua/abre o FOV com rapidez quando ele se aproxima, e só volta a aproximar devagar.
3. Os demais personagens não podem ficar atrás do bloco menu + cartão.
4. A lâmina de info do move não é tocada.

## Ambiguidades em aberto

- Fight: a lâmina de info abre ao lado do menu (x fixo 296) e pode cobrir o líder; fora de escopo por pedido do criador.

## Estado

Implementado para revisão (ver código em `battle_hud.gd`, `battle_camera.gd`, `battle_scene.gd`).
