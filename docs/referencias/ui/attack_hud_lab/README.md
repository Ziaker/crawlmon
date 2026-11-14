<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# HUD de ataque — GLIFO (opção C)

Protótipo de redesign completo da HUD de ataque do overworld. Nenhum conceito é
uma placa/retângulo: a HUD vive no alvo, no jogador ou entre os dois.

**Escolhida:** **GLIFO** — um Z grande flutuando ao lado do jogador, com arco de
recarga e uma linha fina até o inimigo. Já está integrada no lab do overworld no
lugar do prompt `[Z] ATTACK`; o prompt de conversa continua `[E] TALK`.

## Os 4 conceitos

| # | Nome | Onde vive | Leitura |
|---|------|-----------|---------|
| 1 | **MIRA** | no inimigo | retículo aberto, anel tracejado, medalhão hexagonal do Z, nome/distância acima, ATTACK abaixo |
| 2 | **SELO** | no chão, sob o inimigo | sigilo em perspectiva, runas girando, Z na borda da frente, pilar de luz |
| 3 | **GLIFO** | ao lado do jogador | Z grande flutuante, arco de recarga, linha fina até o alvo |
| 4 | **FITA** | entre jogador e alvo | fita curva com Z no começo, tracejados correndo e seta no alvo |

Estados: **pronto** e **recarga** (arco/progresso). Sem inimigo no alcance a HUD
**some por completo**; não existe Z fantasma nem “SEM ALVO”. O ataque é sempre
**Z**; E não aparece.

## Integração no overworld

- `scripts/debug/murky_forest_3d_lab.gd`: cria `_attack_hud`, atualiza alvo,
  distância, estado e cooldown todo frame; o Z chama `attack_anytime()` e
  `play_press()`; o prompt antigo de ataque foi escondido.
- `scripts/overworld/overworld_attack_controller.gd`: novo getter read-only
  `get_player_cooldown_ratio()` (0..1); nenhum timing mudou.
- O HUD usa `get_attack_target()` e os âncoras `eff_head`/`eff_body`/`eff_floor`;
  não há coordenada fixa de personagem, time ou lado.

## Como abrir

```powershell
.\Godot_v4.7.2-stable_win64_console.exe --path . --resolution 1280x720 `
  --position -4000,0 res://scenes/debug/attack_hud_lab.tscn
```

Controles: **1–4** conceito · **Espaço** testa o Z · **T** estado ·
**G** alvo (Slime/Gible) · **M** espelha · **Esc** sai.

## Arquivos

- `scripts/ui/attack_hud.gd` — componente dos 4 conceitos.
- `scripts/debug/attack_hud_lab.gd` + `scenes/debug/attack_hud_lab.tscn` — lab.
- `tests/ui/test_attack_hud.gd` — 30 checks headless.
- `tests/ui/capture_attack_hud.gd` — capturas.
- `tests/ui/make_attack_hud_sheet.gd` — folha de contato.
- `tests/ui/record_attack_hud.gd` — gravação da demo.

## Mídia

- `contact_sheet.png` — as 4 opções.
- `A_mira.png`, `B_selo.png`, `C_glifo.png`, `D_fita.png` — quadros cheios.
- `*_press.png` — impacto do Z.
- `attack_hud_options.mp4` — demo com troca de conceito, estados, Gible e espelho.
- `glifo_final.mp4` — vídeo focado na opção escolhida (pronto, Z, recarga, Gible e espelho); a HUD desaparece sem alvo.
- `glifo_gate_near.png` / `glifo_gate_far.png` — prova: com inimigo perto a HUD aparece; longe, some por completo (sem Z fantasma e sem “SEM ALVO”).
- `docs/referencias/exploracao/3d/diag_gamecam_slime.png` / `diag_gamecam_gible.png` — GLIFO com a câmera real do jogo.

## Testes

- `tests/ui/test_attack_hud.gd` — 30/30.
- `tests/ui/test_attack_hud_integration.gd` — 9/9.
- `tests/overworld/test_overworld_attack.gd` — 66/66.
- `tests/overworld/test_dash_vfx.gd` — 64/64.
- `tests/overworld/test_end_to_end_attack_flow.gd` — OK.

## O que não foi verificado

- O GLIFO foi verificado no lab 3D (câmera do jogo e câmera de lado), não numa
  build final do overworld.
- Regras de combate/alcance/transição não foram alteradas.
- O posicionamento usa os âncoras `eff_head`/`eff_body`/`eff_floor` do ator e,
  sem eles, o AABB das malhas; não há coordenada fixa de personagem, time ou lado.
