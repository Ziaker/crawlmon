# HUD do escudo em combate — revisão e protótipo com solução

- **Data:** 2026-11-12.
- **Autor:** agente de IA (sessão OpenCode).
- **Branch/worktree:** `wip/checkpoint-2026-11-06` em `crawlmon`.
- **Escopo:** revisão do indicador de escudo no HUD de combate e protótipo com solução (arco no retrato).
- **Publicação:** um commit local (`6860efa3`), sem `push`; o relatório em si não foi commitado.
- **Decisões aplicáveis:** D-235, D-1154 (li `docs/TELEMETRIA.md`), D-1010/D-1011, D-272 e D-1169.

## 1. Objetivo

Sair do anel 3D flutuante + badge duplicado e apresentar uma solução para a poluição do HUD durante o combate, mantendo o valor do escudo legível para o jogador, os aliados e os inimigos.

## 2. Diagnóstico da poluição

No cenário de comparação (DQT: Abra x Cyclops/Slime/Orc):

- **Antes:** 4 anéis 3D flutuantes + 4 badges (`S 37 | 45.0s` / `SHIELD 37 | 45.0s`) para 4 valores — **8 elementos**.
- O mesmo dado aparecia duas vezes.
- Os anéis ficavam na arena e competiam com o banner grande do Move, as etiquetas de ataque, os números de dano e o marcador de alvo.
- Cada anel tinha brilho/onda constante, mesmo sem mudança de valor.

## 3. Solução implementada (não é mockup)

O escudo passou a ser **um arco no retrato real** do cartão/etiqueta:

- **Jogador e alvo atual:** arco cheio, número maior, ícone de escudo e halo de pulso.
- **Aliados e demais inimigos:** arco fino + número pequeno no retrato.
- **Badge antigo removido** no modo novo (`S ... | ...s` e `SHIELD ... | ...s`).
- **Animação só quando o valor muda**; sem brilho/onda ociosa.
- **Sem anel 3D** nesse modo; a arena fica livre para VFX, ataque e dano.
- O timer saiu do combate; o arco representa a reserva atual / máximo.

### Implementação

- `tests/vfx/shield_portrait_overlay.gd` — desenha o arco no retrato real (cartão ou etiqueta), com número, ícone, halo e pulso.
- `scripts/ui/battle_hud.gd` — flag `hide_shield_badges` (padrão `false`) suprime os dois badges antigos; só o laboratório liga.
- `tests/vfx/shield_value_lab.gd` — laboratório com `--combat`, `--portrait`, `--no-shield`, `--b-only`, `--dqt-mirror` e `--seconds=`.
- `shaders/proto/shield_ring.gdshader` e `shaders/proto/shield_panel.gdshader` — mantidos para os modos antigos (B com anel 3D e C do protótipo inicial).
- `docs/decisoes/D-1169-indicador-de-escudo-opcao-b.md` — direção, revisões e limites.

## 4. Evidência visual

- **Antes (30 s, combate real):** `test_captures/shield_hud_combat_30s.mp4`
- **Depois (30 s, combate real, arco no retrato):** `test_captures/shield_hud_combat_30s_portrait.mp4`
- **Revisão antes/depois com os mesmos 4 combatentes DQT:** `test_captures/shield_hud_review.png`

Os vídeos/folha são locais (`test_captures` é ignorado pelo Git).

## 5. Testes

- `tests/ui/test_qol_batch.gd` — exit 0.
- `tests/ui/test_status_screen_content.gd` — exit 0.
- `python tests/battle/run_agent_combat_tests.py` — **27/27**.
- `--check-only` em `battle_hud.gd`, `shield_value_lab.gd` e `shield_portrait_overlay.gd` — sem erro de parse.

## 6. Commit

**`6860efa3`** — `feat(hud): shield review prototype with the arc on the portrait`

Entraram 8 arquivos:

1. `scripts/ui/battle_hud.gd` (só a flag + 2 guards)
2. `tests/vfx/shield_portrait_overlay.gd`
3. `tests/vfx/shield_value_lab.gd`
4. `shaders/proto/shield_ring.gdshader` (+ `.uid`)
5. `shaders/proto/shield_panel.gdshader` (+ `.uid`)
6. `docs/decisoes/D-1169-indicador-de-escudo-opcao-b.md`

**Ficou de fora, de propósito:**

- O resto do worktree compartilhado (outras sessões): dezenas de scripts/docs modificados.
- A linha do D-1169 no `docs/decisoes/README.md` (o arquivo tem mudanças de outras sessões).
- Os vídeos e a folha em `test_captures` (locais/ignorados).

Se for necessário um checkpoint de **tudo**, avisar: ele incluirá trabalho das outras sessões.

## 7. Como reproduzir

```powershell
# Antes (anel 3D + badge)
.\Godot_v4.7.2-stable_win64_console.exe --path . --resolution 1280x720 --fixed-fps 30 `
  --write-movie saida_antes.avi --script res://tests/vfx/shield_value_lab.gd -- `
  --combat --seconds=30

# Depois (arco no retrato, sem badge antigo)
.\Godot_v4.7.2-stable_win64_console.exe --path . --resolution 1280x720 --fixed-fps 30 `
  --write-movie saida_depois.avi --script res://tests/vfx/shield_value_lab.gd -- `
  --combat --portrait --seconds=30

# A/B com os mesmos combatentes DQT (1 jogador + 3 inimigos)
... -- --combat --dqt-mirror --seconds=6
... -- --combat --dqt-mirror --portrait --seconds=6
```

## 8. Limitações / não verificado

- **Troca de alvo** não testada: o alvo é `hud._target` ou o primeiro inimigo vivo até o jogador escolher outro.
- **Quebra e renovação** do escudo (novo escudo depois de zerar) não testadas.
- **3+ aliados**, outras resoluções/aspectos e telas menores não testados.
- **Timer** removido do combate; se for necessário, precisa de uma linha fina no arco.
- O arco do aliado compacto usa número de 11 px; o do jogador/alvo, 14–17 px.
- O modo novo ainda é **laboratório**: `hide_shield_badges` é `false` por padrão e o HUD do jogo não foi integrado.

## 9. Próximo passo

1. Aprovar a solução do arco no retrato.
2. Integrar no HUD do jogo (flag padrão verdadeiro ou remoção do badge antigo).
3. Definir a troca de alvo, a quebra/renovação e o comportamento com 3+ aliados.
4. Gravar o vídeo final e atualizar a decisão.
