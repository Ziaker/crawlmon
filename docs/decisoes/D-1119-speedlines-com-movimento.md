<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1119 — Speedlines com movimento visível no avanço

- **Data:** 2026-11-10
- **Área:** Overworld 3D / lab / VFX / ataque
- **Origem:** o criador observou que as speedlines pareciam paradas.
- **Status:** **implementado e testado** (100/100 VFX, incluindo o gate de overdraw; 66/66 controlador; ponta a ponta PASS); demo em slow motion regravada.
- **Nota de numeração:** esta decisão nasceu como D-1116, mas o ID já pertencia à D-1116 de paredes/paliçada de outra sessão; foi renumerada para **D-1119** sem alterar a decisão de paredes.

## O que o criador disse (literal)

> ta mas essas speedlines nem se movem, cade a animação delas

## Decisão

1. As speedlines 3D do avanço precisam se mover de verdade, não ficar paradas no ar.
2. Cada linha desliza para trás do ator a **0,55–1,55×** a velocidade do dash, nasce à frente do corpo e atravessa-o para trás; alonga de **1,60→0,50** ao longo da vida, gira em torno do próprio eixo (**−3,2..3,2 rad/s**), vive **0,20–0,36 s** e tem alpha maior (**0,95** nas cores escuras / **0,82** no branco).
3. As linhas ficam **presas ao ator só nos primeiros 0,04 s** do dash; depois vivem no **espaço do mundo**: o emissor acompanha o ator apenas para os **novos** spawns, as linhas já nascidas ficam para trás e o ator atravessa. O efeito **termina no contato** (D-1120/D-1127).
4. A malha é um **diamante em cruz** (duas faces perpendiculares), para a linha não desaparecer de perfil em nenhuma câmera; o comprimento é **0,20-0,45 × a altura do ator**, a espessura **0,018-0,040 × a altura** e o raio em torno do corpo é **1,05-1,80×** o raio medido do ator (D-1127). O mesmo efeito roda com 34 linhas iniciais (pool 56) e nasce/spawna com semente fixa.
5. Vale para jogador e inimigo, em qualquer lado (D-235); a direção vem do ator→alvo real.
6. É VFX de overworld; **D-308 não se aplica** (D-1100 item 15).

## Implementação

- `scripts/overworld/vfx/overworld_dash_speedlines.gd`: nó `top_level` com origem global fixa, emissor que acompanha o ator só para os novos spawns, malha em cruz, deslize forte para trás, alongamento/rotação por linha e fade mais visível; `finish_now()` limpa as linhas no contato.
- O teste `tests/overworld/test_dash_vfx.gd` ganhou uma asserção que mede o transform local das mesmas linhas em dois instantes: **39/39** deslizam e **39/39** alongam/encolhem, sem depender de olhar o PNG.
- Gate de overdraw da captura D-1044: **p99 4,37 / máximo 5,46** nas duas vistas (limites 5 / 6,5); **100/100** checks.
- Controlador: **66/66**; ponta a ponta PASS (jogador primeiro, Gible/vermelho e derrota).
- Demo em slow motion (`overworld_showcase_demo.mp4`, 120 fps gravados, 30 fps, 4×) e o combinado `overworld_attack_3cases.mp4` substituído; os casos `overworld_showcase_case_player/enemy/contact.mp4`; folhas `overworld_attack_speedlines_player/enemy_sheet.png` mostram as linhas em quadros consecutivos; Slime e Gible visíveis (D-1125).

## Estado

Implementado e testado; pendente aprovação visual. Sem commit e sem push.
