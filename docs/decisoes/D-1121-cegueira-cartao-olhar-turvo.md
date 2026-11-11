# D-1121 — Cegueira no cartão: “Olhar turvo” (retrato duplicado + vinheta)

- **Data:** 2026-11-10.
- **Área:** UI / HUD / status BLIND.
- **Relacionadas:** D-980 (STUN no cartão), D-984 (badges negativos), D-1105 (cartões), D-032/D-158 (cegueira: 35% de erro), D-003, D-019/D-1040.
- **Status:** aprovado como parte da D-1134 em 2026-11-11; implementado.

## O que o criador disse (literal)

> "ok vamos agora criar o efeito visual no cartão do personagem para a cegueira, me de 3 ideias"

Escolha: **"1"** — ideia **“Olhar turvo”**.

Escolha de alcance: **“Cartão + etiqueta dos inimigos”**.

## Regra

1. Enquanto o combatente estiver **BLIND**, o retrato do cartão (aliados) e da etiqueta (inimigos) ganha:
   - troca para uma cópia **desfocada e dessaturada** do retrato (perda real de nitidez);
   - **três cópias fantasma** deslocadas (visão dupla), que derivam devagar;
   - vinheta escura suave fechando nas bordas do retrato.
2. O badge `BLIND` **pulsa** enquanto o status dura; a pulsação acelera perto do fim do timer.
3. O efeito **entra e sai suavemente** (~0,25 s). Na saída, as cópias convergem e um flash/aro claro dá o “estalo” de foco.
4. **STUN continua legível:** as espirais e estrelas do D-980 são desenhadas por cima do efeito de cegueira.
5. HP, ATB, MP, nome, elementos e o badge `BLIND` continuam nítidos e legíveis.
6. É um efeito de **status**, não de personagem: funciona em qualquer retrato, aliado ou inimigo, perto ou longe (D-235). Não altera a regra de 35% de erro, duração ou dano.

## Implementação

- `scripts/ui/battle_hud.gd`: `_blind_k` com ease-in/out, `blind_k(c)`, `blind_snap(c)`, `blind_badge_pulse()`; chamadas no cartão grande e na etiqueta compacta; badge BLIND com brilho pulsante.
- `scripts/ui/components/battle_hud_draw.gd`: `draw_blind()` com blur/dessaturação reais (cópia processada e cacheada por retrato), três fantasmas, vinheta e flash de foco; `slant_texture()` passa a aceitar modulação de cor.

## Correção após a primeira versão

A primeira versão usava apenas duas cópias com deslocamento de ~2 px e uma camada escura; o criador respondeu **“não gostei, nem é perceptível”**. A versão atual aumenta o deslocamento para ~6 px, troca o retrato por uma cópia desfocada/dessaturada, usa três fantasmas, pulsa o badge e adiciona o estalo de foco.

## O que foi verificado

- **28/28** testes da lista de combate/UI/VFX com exit 0.
- Suíte `run_agent_combat_tests.py`: **16/16 PASS**.
- `test_qol_batch.gd` verde (HUD/descrições).
- Captura em 1280×720: cartão de Abra (aliado) e etiquetas de Orc, Cyclops e Pancham (inimigos) com o retrato desfocado/dessaturado, fantasmas visíveis, badge BLIND pulsante e HP/ATB intactos (`test_captures/d1121_blind_hud.png`).
- Vídeo de 5,4 s mostrando entrada, permanência, badge pulsando e saída com o estalo de foco (`test_captures/blind_hud.mp4`).
- BLIND + STUN juntos: o retrato continua com o efeito de cegueira e as estrelas/espirais do STUN são desenhadas por cima (`test_captures/d1121_blind_stun_hud.png`).

## O que não foi verificado

- Aprovação visual do criador.
- Build/export.
- Todos os retratos do jogo (o efeito é genérico, mas a prova visual cobre Abra e os inimigos do cenário).
