<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# Entrega — Laboratório Godot da Drain Spear 

- **Data:** 2026-11-06
- **Branch:** `wip/checkpoint-2026-11-06`
- **Estado:** ajustes visuais da  implementados e testados; **aguardando aprovação visual do criador**. Sem commit e sem push.
- **Escopo:** protótipo visual. **Não** é a Drain Spear no combate e não altera nenhuma regra do jogo.

## 1. O que mudou nesta rodada

| Ponto do criador | O que foi feito |
|---|---|
| Personagens sem animação | A respiração (`DqtIdleBreath`) fica ligada também nas capturas; walk, ataque (clipe 11) e damage (clipe 10) tocam como no jogo. O ataque começa em **1,667 s**, e a mão mais à frente do clipe cai no contato em **2,1 s**. |
| 1 — lança alta demais | A lança nasce no **chão**, no **ponto verde do lado direito da tela**, com **2,7 m** (cabo + lâmina). O contorno é a lança inteira. |
| 2 — “espelhado” | Agora é o **POV do outro lado**: mesmos papéis (Orc atacando o Slime), câmera espelhada da CINEMA no plano do ponto médio, FOV 80° e Dutch 4°. O HUD continua normal. |
| 3 — virava tarde | Formação **0–0,8 s**; virada **0,8–1,0 s**; **corrida começa em 1,0 s**; corrida **1,0–1,8 s**; estocada **1,8–2,1 s**; impacto **2,1–2,65 s**; recovery **2,65–4,3 s**. |
| 4 — projétil | Removidos o feixe e os modos Hybrid/Elongate/Surge. É **uma lança única e conectada**: o **cabo cresce** a partir da mão, a **lâmina fica fixa na ponta**, ela **impala**, **dá ré** 0,85 m e **some lentamente em partículas**. |
| 5 — retorno do Badge Steal | Streaks reversos + **orbs extraídos** + **duas coroas/orbitas visíveis** no atacante + a órbita espiral; as **badges da HUD voam** de 2,13 s a 2,43 s. |
| 6 — aura em faixas | **6 faixas espirais** em volta da **lança inteira**, baixa opacidade, com iluminação direcional e fresnel; sparkles notáveis. Presentes no **wind-up, release e impacto/dissolução**. |

## 2. Onde testar

**Batalha real:**

```bat
Godot_v4.7.2-stable_win64_console.exe --path. res://scenes/debug/drain_spear_lab.tscn -- --realbattle
```

- Carrega `scenes/battle.tscn` com `DqtTestParty` (Slime, Orc, Cyclops), usa os modelos, o `AnimationPlayer`, a respiração e a câmera reais.
- Congela a batalha, esconde a UI do jogo, mantém só Orc e Slime no palco e desliga o `BattleFx` que reposicionaria os modelos.
- **Não** cria a Drain Spear como Move, **não** altera combate, dano, alcance ou regras.
- O flag é `--realbattle` porque `--battle` já é usado pelo `GameState` para abrir a batalha de debug.

**Laboratório isolado (mesma timeline, sem a cena de batalha):**

```bat
Godot_v4.7.2-stable_win64_console.exe --path. res://scenes/debug/drain_spear_lab.tscn
```

**Captura de um instante:**

```bat
Godot_v4.7.2-stable_win64_console.exe --path. --resolution 1280x720 res://scenes/debug/drain_spear_lab.tscn -- --realbattle --scenario=B --time=2.30 --nopanel --shot=res://test_captures/drain_spear_lab/exemplo.png
```

**Gravação:**

```bat
Godot_v4.7.2-stable_win64_console.exe --path. --resolution 1280x720 res://scenes/debug/drain_spear_lab.tscn -- --realbattle --scenario=A --nopanel --record=4.3 --step=0.0333333 --out=res://test_captures/drain_spear_lab/rec_A
```

## 3. Controles do laboratório

- **Cenários A–H** (G = POV do outro lado; H = Cyclops como alvo).
- **Distância inicial:** 22,5 / 16,3 / 8,5 / 2,6 / alvo aproximando.
- **Resultado:** acerto, evade, interrupção.
- **Atacante:** Orc, Cyclops ou Slime (prova D-235).
- **Alvo:** Cyclops, Slime ou Orc.
- **Badges:** ATK +1, escudo, imunidade mágica, DEF −1.
- **POV do outro lado** (checkbox) e **câmera livre** (arrastar/roda).
- **Rodapé:** Play/Pause, reiniciar, replay, velocidade e scrub.
- `--clean` esconde HUD e painel; `--nopanel` esconde só o painel de controles e o rodapé, mantendo o HUD/tags/badges.

## 4. O efeito no Motion Composer

- **`MotionMesh`**: `spear` (lança inteira), `spear_shaft_mesh(length)` (cabo com punho e ponteira de medidas fixas; só o miolo cresce), `spear_blade` (lâmina fixa de 1,0 m) e `helix_band` (fita espiral da aura).
- **`MotionPainter`**: `spear_part` (cabo/lâmina com reveal/dissolve próprios e espessura do cabo crescendo com o comprimento), `aura_band` (fita espiral), `light`, `shock_ring`.
- **`MotionRep`**: `spear` com `spear_part`, `blade_length`, pós-imagens; `aura` com 6 faixas; **`vortex`** com 10 faixas cônicas (D-379); `shock`; `light`; `mark`.
- **`MotionPresets.drain_spear_effect`**: **27 camadas** em windup (5), thrust (4), **drill (2)**, impact (3), impact_flash (3), steal (6) e dissolve (4). **Não existe fase `beam`.**
- **Shaders**: `mc_drain_spear.gdshader` (lança), `mc_aura_band.gdshader` (faixa/vórtice com luz/fresnel), `mc_shock_ring.gdshader`.
- **Badge Steal (D-379)**: leque **reverso** alvo→atacante (76 streaks M16 + 34 orbs brilhantes), coroas/órbitas e impacto reverso no atacante.
- **Drill (D-379)**: boost burst helicoidal no início da estocada, 0,6 s, fade após 0,4 s, giro de ventilador (4,2 voltas/s).

## 4b. Correções da D-379 (esta rodada)

- **Impacto de direção oposta:** o Badge Steal agora tem um leque M16 de **76 streaks** (cone 24°, tamanho 0,42, rastro longo) saindo do contato e convergindo no atacante, mais **34 orbs brilhantes** (cone 16°, tamanho 0,58) que viajam **junto das badges** (2,13–2,43 s) e continuam até ~2,52 s. As coroas/órbitas e o impacto reverso no atacante (halo + anel + luz) continuam.
- **Vórtice helicoidal da estocada:** 10 faixas cônicas em volta da frente da lança (raio 0,72 m → 0,10 m), **4,2 voltas/s** (ventilador), **0,6 s** a partir de 1,8 s; **após 0,4 s** a opacidade cai até sumir em ~0,58 s; 28 faíscas de burst no início.

## 5. Animações e determinismo

- Respiração ligada em todas as capturas (o `DqtIdleBreath` é um Tween do jogo; o quadro não é 100% determinístico no tempo da respiração, mas o resto é).
- Walk do Orc: clipe 01, 0,5333 s, em loop por `seek`; corrida de 1,0 a 1,667 s.
- Ataque: clipe 11 inteiro a partir de 1,667 s; o pico da mão (0,433 s) coincide com o contato em 2,1 s.
- Alvo: clipe 10 (`damage`) a partir do contato, depois volta ao `battle_idle`. Sem KO.
- Fim do efeito em 4,3 s: **0 nós e 0 luzes** no `MotionPainter.stats`.

## 6. Verificação executada

- `tests/motion_composer/test_v110_drain_spear.gd`: **162 checks, PASS**.
 - malha da lança inteira, cabo, lâmina e fita espiral;
 - shaders `mc_drain_spear` e `mc_aura_band` com todos os uniforms;
 - 27 camadas, 6 faixas de aura, **10 faixas de vórtice**, 3 camadas de lança, **nenhuma camada de feixe**;
 - leque reverso do Badge Steal (M16) presente;
 - avaliação determinística de todas as composições.
- Cena carregada e capturada em 1280×720, no laboratório isolado e no palco da batalha real (`--realbattle`).
- Fim em 4,3 s sem sobras no laboratório e na batalha.
- Cenários A–H capturados; D (evade) e interrupção sem impacto.
- D-235: Slime como atacante e Orc como alvo; Cyclops como alvo (H).
- **Vídeos em tamanho cheio, um por lado** (batalha real, HUD visível, painel oculto; **regravados com o leque reverso e o vórtice da D-379**):
 - `test_captures/drain_spear_lab/DrainSpear_normal_completo.mp4` — normal, 1280×720, 30 fps, **6,67 s** (impacto 0–4,30 s + Badge Steal a partir do contato 4,30–6,67 s).
 - `test_captures/drain_spear_lab/DrainSpear_outro_lado_completo.mp4` — outro lado, 1280×720, 30 fps, **6,67 s**, mesma estrutura.
- **Quatro vídeos por cenário** (4,33 s cada, 1280×720):
 - `DrainSpear_impacto_normal.mp4`
 - `DrainSpear_impacto_outro_lado.mp4`
 - `DrainSpear_badge_steal_normal.mp4`
 - `DrainSpear_badge_steal_outro_lado.mp4`
- **Vídeo empilhado** (normal em cima, outro lado embaixo): `DrainSpear_battle_normal_outro_lado.mp4`, 1280×1440, 6,67 s.
- **Folhas de contato:**
 - `test_captures/drain_spear_lab/RB_contact_impact.png`
 - `test_captures/drain_spear_lab/RB_contact_badge.png`

## 7. O que não foi verificado

- Desempenho/GPU, memória, várias resoluções e hardware fraco.
- Todos os controles da HUD de forma interativa.
- Áudio, gamepad, foco de UI e acessibilidade.
- Integração da Drain Spear como Move real, IA, Evade/contra-ataque e fichas definitivas.
- Fórmula real de dano/mitigação: a HUD mostra `5 + MAG` e o SPI como **simulação local**.
- Aprovação artística e aprovação do criador.
- **Falha pré-existente de outra sessão:** `tests/motion_composer/test_v11_tubos_e_receitas.gd` falha no efeito de fogo. Não é o teste da Drain Spear; não alterei o fogo.

## 8. Diferenças em relação ao plano original

- O palco principal agora é a **batalha real** (`--realbattle`); o laboratório isolado continua disponível.
- A lança no chão tem **2,7 m** (o plano citava 6,4 m como referência do HTML). O HTML lançava uma lança de 4,86 m; aqui ela é **conectada à mão** e o cabo cresce até o alvo, sem projétil.
- As âncoras do palco continuam `NEAR (2, 0, −2)` e `FAR (−6,09, 0, −16,16)`, 16,3 u entre centros.
- O “espelhado” mudou de semântica: **não troca mais os papéis**; é o POV do outro lado.
- O comprimento do cabo é dinâmico (2,7 m → ~16 m) e a espessura cresce com o comprimento para o cabo não ler como um fio/feixe.

## 9. Próximo passo

Aguardar a aprovação visual. Se algo estiver errado, ajusto **um item por vez**, com quadro em tamanho real nas duas vistas, antes de dizer que está pronto.
