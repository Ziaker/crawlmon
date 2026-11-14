<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1106 — Lab: segundo inimigo não-Medroso, derrota e vídeo

- **Data:** 2026-11-10
- **Área:** Overworld 3D / lab / encontros / derrota
- **Origem:** respostas do criador às pendências da D-1100.
- **Status:** **implementado no lab 3D e testado**; vídeos gravados; aguardando aprovação visual dos valores.

## O que o criador disse (literal)

> Adicionar inimigo não-Medroso (Recomendado)
>
> Manter cores por ator (Recomendado)
>
> Voltar ao lab sem resetar (Recomendado)
>
> Uma vez por entrada (Recomendado)
>
> Manter como está (Recomendado)
>
> Testar em vídeo antes (Recomendado)

## Decisão

1. O lab mantém o Slime Medroso (D-1086) e ganha um **segundo inimigo que entra em CHASE**, para a transição vermelha existir no lab. Para o vídeo, o segundo inimigo será um **Gible** (modelo já usado pela batalha); a espécie é escolha de implementação, não regra de jogo.
2. No **empate**, a transição é branca e cada ator mantém a cor do seu VFX (azul/vermelho).
3. **Derrota no lab:** volta ao lab **sem resetar** a expedição 2D; a party é revivida. O caminho 2D de derrota continua como antes.
4. O inimigo ataca **uma vez por entrada em CHASE**; o cooldown de 4 s só impede reentrada imediata.
5. **Selo/tons mantidos:** `CONTATO`/`VANTAGEM`/`EMBOSCADA`, azul `#4d9cff`, coral `#ff624f`.
6. **Valores do avanço** (jogador 3,5 m / até 0,18 s, cooldown 0,8 s; inimigo 3,4 m / até 0,18 s; velocidade mínima 8 m/s para alvos colados) ficam como protótipo até o **vídeo no lab real**; depois o criador aprova ou calibra (D-1120).

## Implementação e testes

- `murky_forest_3d_lab.gd`: `_build_second_enemy()` cria o Gible em (5,0,-5), com cápsula, placa/anel, dust, VFX próprio, CHASE a 5 m e registro no `OverworldAttackController`.
- `game_state.gd`: `end_battle(false)` revive a party e, quando `return_scene` é o lab 3D, **não** reseta a expedição 2D.
- Teste `tests/overworld/test_overworld_attack.gd`: 66/66, incluindo o contato normal andando, o ataque total de ~0,80 s e as animações de ataque a 2,0×.
- Teste `tests/overworld/test_end_to_end_attack_flow.gd`: cobre player-first 4/2, enemy-first 2/4, Gible com VFX vermelho e clipe `attack` a 2,0×, derrota sem resetar floor/seed/inventário e party revivida.
- Animação: `attack` no início do dash do jogador/Slime/Gible a **2,0×**, com pré-avanço de **0,12 s** sem congelar e dash de **até 0,18 s** (D-1112/D-1120); impacto do Tackle de 0,5 s no contato (D-1115); speedlines no espaço do mundo, com deslize/alongamento/rotação, e VFX limpo no contato (D-1119).
- Vídeos no lab real: `docs/referencias/exploracao/3d/overworld_attack_player.mp4/.gif` (azul/`VANTAGEM`), `overworld_attack_enemy.mp4/.gif` (vermelho/`EMBOSCADA`), `overworld_attack_contact.mp4/.gif` (branco/`CONTATO`), `overworld_attack_lab_sheet.png` e o combinado `overworld_attack_3cases.mp4/.gif`. Demo limpa: `overworld_showcase_demo.mp4` (HUD oculto, câmera de lado, 120→30 fps, 4×); Slime e Gible visíveis (D-1125).

## Pendente

- Aprovação visual dos valores de avanço, do pré-avanço de **0,12 s**, do dash de **até 0,18 s**, do impacto do Tackle de 0,5 s e das speedlines no espaço do mundo (D-1112/D-1115/D-1119/D-1120) no vídeo; se aprovado, remover o rótulo de protótipo.
- Confirmar se o Gible é a espécie desejada; trocar o modelo é só uma escolha do lab.

## Estado

Implementado no lab 3D e testado; vídeos gravados; aguardando aprovação visual. Sem commit e sem push.
