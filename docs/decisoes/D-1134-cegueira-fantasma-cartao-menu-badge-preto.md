# D-1134 — Cegueira: fantasma no cartão inteiro e no menu de ações; badge BLIND preto

- **Data:** 2026-11-10.
- **Área:** UI / HUD / status BLIND.
- **Relacionadas:** D-1121 (Olhar turvo no retrato), D-980 (STUN), D-984 (badges), D-1105 (cartões), D-032/D-158 (cegueira), D-003.
- **Status:** **aprovado pelo criador** em 2026-11-11; implementado.

## O que o criador disse (literal)

> "tá mas tu ta mudando o icone e não o cartão em sí"
>
> "dê esse efeito fantasma pro cartão do personagem e pra hud de seleção de ações, mude o badge do blind pra PRETO e cor de texto BRANCA"

## Regra

1. O **cartão inteiro do personagem** (fundo, nome, HP/MP, ATB, retrato e moldura) ganha **duas cópias fantasma translúcidas** quando o dono está com BLIND. Não é só o retrato.
2. O **menu de seleção de ações** (FanMenu: Fight/Items/Evade/Tactics/Status e os submenus) ganha as **duas cópias fantasma** quando o líder está com BLIND.
3. As duas cópias **giram em círculo no sentido horário** ao redor do cartão/menu, em fases opostas (uma de cada lado), com deslocamento suave.
4. O retrato continua com o “Olhar turvo” da D-1121 dentro do cartão real.
5. O badge `BLIND` fica **fundo PRETO** e **texto BRANCO** (cartão dos aliados e etiqueta dos inimigos). O pulso continua, agora com brilho neutro.
6. HP, ATB, MP, nome, elementos, ícones e textos continuam legíveis; as cópias são translúcidas e o badge fica nítido no cartão real.
7. Regra de 35% de erro, duração, dano, ATB e MP não mudam (D-019/D-1040, D-235).

## Implementação

- `scripts/ui/battle_hud.gd`: **duas** cópias fantasma de cada `UnitCard` e **duas** do `FanMenu` do líder, translúcidas, girando **em sentido horário** em fases opostas; sincronizadas com posição/rotação/escala; badge BLIND preto/branco e nítido no cartão real.
- `scripts/ui/components/battle_hud_draw.gd`: sem mudança de regra; o retrato mantém o blur da D-1121.

## O que foi verificado

- Captura em 1280×720 com o líder BLIND: **duas cópias** do cartão inteiro e do menu de ações, em fases opostas e girando; badge `BLIND` preto com texto branco e nítido (`test_captures/d1121_blind_hud.png`).
- Vídeo de 5,4 s mostrando o movimento circular horário das cópias e a saída do efeito (`test_captures/blind_hud.mp4`).
- Captura com BLIND + STUN (`test_captures/d1121_blind_stun_hud.png`).
- `test_qol_batch.gd` e `test_status_screen_content.gd` verdes.
- Suíte `run_agent_combat_tests.py`: **16/16 PASS**.
- Lista de 28: **26/28**. As duas falhas são de **dados fora do HUD**, não desta mudança:
  - `test_d272_guard`: `Brick Break` não tem a tag `guard_break` no `content/moves/quebra_telha/move.tres`, então o Guard absorve o golpe em vez de quebrar;
  - `test_content_catalog`: divergência em `megido: elemento`.
  Nenhum desses arquivos foi alterado por esta sessão.

## O que não foi verificado

- Aprovação visual do criador.
- Build/export.
- Submenus DRAWER com o fantasma (o código copia estilo/entradas a cada frame, mas a prova visual cobre o menu FAN).
- Todos os retratos/menus do jogo.
