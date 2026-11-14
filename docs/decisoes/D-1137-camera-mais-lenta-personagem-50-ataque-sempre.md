<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1137 — Câmera um pouco mais lenta, personagem +50% e Z ataca sempre

- **Data:** 2026-11-10.
- **Área:** Exploração 3D / lab Murky Forest / câmera, movimento e ataque.
- **Relacionadas:** D-1130 (A/D câmera), D-1135 (ataque 2,0 m sem wind-up), D-1100/D-1127 (Z ataca).
- **Status:** **implementado/provado**; código na árvore de trabalho; **sem push**.

## O que o criador disse (literal)

> diminua um pouquinho a velocidade de virada da camera pelos butões A e D, aumente a velocidade de movimento do personagem pela metade e permita que o jogador realize o ataque a qualquer momento, mesmo sem inimigo

## Regra

1. **Giro da câmera por A/D:** `CAM_TURN_SPEED` de **3,0** para **2,6 rad/s** (um pouco mais lento).
2. **Movimento do personagem +50%:** `SPEED` de **3,2** para **4,8 m/s**.
3. **Z ataca sempre:** o Z inicia o ataque mesmo **sem inimigo**. Sem alvo, o jogador avança **2,0 m** na direção em que está virado, toca o clipe `attack`/VFX e **não inicia batalha**.
4. **Com alvo:** o Z continua usando o inimigo mais próximo em 4,5 m e a transição normal.
5. **E continua sendo interação:** falar com NPC e usar a saída é **E**; o prompt de NPC passa a mostrar **`[E] TALK`** e o HUD `Z: atacar · E: falar/saída`.
6. **Diálogo:** Z não ataca durante a conversa (`_npc_talking`).
7. **O que não muda:** câmera sem auto-follow, paredes a 40%, cômodo/Gible (D-1133), ataque 2,0 m sem wind-up (D-1135), HUD, cards, regras, batalha e 2D.

## Implementação

- `scripts/debug/third_person_3d_lab.gd`: `CAM_TURN_SPEED = 2.6`, `SPEED = 4.8`.
- `scripts/overworld/overworld_attack_controller.gd`: `attack_anytime()` e `_start_player_free_attack()`; `_tick_player` aceita dash sem alvo.
- `scripts/debug/murky_forest_3d_lab.gd`: Z chama `attack_anytime()`; prompt de NPC em E; HUD.
- `scripts/debug/overworld_prompt.gd`: tecla principal configurável (Z no ataque, E no TALK).

## Provas

- `docs/referencias/exploracao/3d/d1137_free_attack.png` — ataque sem inimigo.
- Log: `free attack call=true dashing=true`, deslocamento **2,037 m**, sem batalha.

## O que foi verificado

- Ataque sem alvo: inicia no mesmo frame, anda ~2,0 m, termina e não pede batalha.
- `test_overworld_attack.gd` e `test_end_to_end_attack_flow.gd` continuam PASS/OK com 2,0 m e sem wind-up.
- A câmera e a velocidade são constantes; o comportamento de A/D/setas não mudou.

## O que não foi verificado

- A sensação final de 4,8 m/s e 2,6 rad/s; podem ser ajustados em um número.
- Gamepad/analógico e todos os ângulos de câmera.

## Estado

Implementado e provado. Código na árvore de trabalho; **sem push**.
