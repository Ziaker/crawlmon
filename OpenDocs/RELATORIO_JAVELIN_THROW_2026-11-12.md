# Relatório de trabalho — Javelin Throw (11–12/11/2026)

- **Branch:** `wip/checkpoint-2026-11-06`
- **HEAD no momento do registro:** `108a7d0b`
- **Pasta:** `OpenDocs/` (nova, separada de `docs/`)
- **Escopo:** Javelin Throw VFX, laboratório de paridade com o HTML Card C, A/B, Dread na ponta e passagem perfurante. Também registra o estado do commit de War Cry.
- **Nada foi enviado/push (D-022).**

## 1. Resumo

O Javelin Throw deixou de ser uma reinterpretação em Godot e passou a ser um **porte literal do HTML Card C** (`javelin_throw_3d_vfx_prototype.html`), com a mesma cena, atores, câmera, luzes, chão, geometrias, materiais e timeline. O HTML foi capturado em Chromium headless para comparação A/B no mesmo instante.

Depois do porte, foram feitos ajustes pedidos pelo criador:

- correção da escala do wind-up (jogador gigante / oponente minúsculo);
- subida da javelin no wind-up e haste mais longa;
- Dread de evade na ponta da javelin, seguindo a ponta;
- javelin atravessando o alvo no impacto, em vez de ficar fincada.

## 2. O que foi feito

### 2.1 Auditoria e fonte visual

- A fonte visual oficial passou a ser o **HTML Card C** (D-1171), não os números reescritos do prompt.
- O perfil antigo do prompt ficou preservado em `scripts/vfx/combat/javelin_throw_vfx.gd` apenas para comparação.
- Auditorias separadas de HTML, prompt, API do script original e crítica da auditoria anterior.
- Documento principal: `docs/vfx/AUDITORIA_JAVELIN_THROW_HTML_C.md`.
- Referência do prompt: `docs/vfx/JAVELIN_THROW_PROMPT_REFERENCE.md`.

### 2.2 Porte literal do HTML Card C

- **`scripts/vfx/combat/html_mesh_lib.gd`**: biblioteca de malhas equivalente ao Three.js:
  - `CylinderGeometry` com a convenção `x=r·sinθ, z=r·cosθ`;
  - `ConeGeometry` (cilindro com topo 0);
  - `OctahedronGeometry` com subdivisão/normalização no raio;
  - `DodecahedronGeometry` com os 20 vértices e 36 triângulos;
  - `TorusGeometry` XY/XZ;
  - `ExtrudeGeometry` das penas;
  - linhas de `EdgesGeometry`.
- **`scripts/vfx/combat/javelin_throw_vfx_html.gd`**: `buildFusionACVFX`/`updateFusionAC` portados:
  - lança de 5 peças, haste, grip, colar, 3 penas, ponta;
  - 14 lâminas de coroa (7 internas + 7 externas);
  - estrela de 2 espinhos + núcleo;
  - feixe e retículo octaédrico;
  - 7 pós-imagens 3D;
  - cruz de 5,94 m, flash octaédrico, anel atrasado, anel de solo;
  - 8 espinhos, 10 poeiras, 8 faíscas;
  - timeline 0,75 / 1,05 / 1,85 s.
- **`scripts/debug/javelin_html_parity_lab.gd` + `scenes/debug/javelin_html_parity_lab.tscn`**: reconstrução da arena, dos atores táticos (Alpha 2,12 m / Beta 1,90 m), da câmera normal/espelhada/oblíqua, das luzes e do chão do HTML.
- **`tests/fx_lab/capture_html_reference.py`**: captura do próprio HTML em Chromium headless (Playwright), com servidor HTTP local próprio, isolando o viewport C em 1280×720.
- **`tests/fx_lab/build_ab_sheets.py`** e **`build_ab_video.py`**: folhas A/B e vídeo HTML em cima / Godot embaixo.
- Artefatos:
  - `test_captures/html_ab/` — frames do HTML;
  - `test_captures/html_parity/` — frames do Godot;
  - `test_captures/html_ab_sheets/` — 12 instantes × 2, normal/espelhado, lado A/B;
  - `test_captures/ab_video/javelin_html_vs_godot.mp4`.

### 2.3 Bug de winding (correção importante)

O Godot considera **clockwise** como face frontal; as malhas estavam sendo geradas em counter-clockwise, então cabeça, torso, javelin, cruz, flash, anéis e poeira eram renderizados pelo **lado de dentro**. Sintomas: visor inteiro por cima da cabeça, javelin estourando para branco, iluminação invertida.

Correção em `HtmlMeshLib._tri` / `_tri_n`: a normal outward continua sendo calculada como no Three.js, mas os vértices são enviados em ordem **CW** para o Godot. Depois disso:

- o visor voltou a ser uma fresta como no HTML;
- a javelin voltou a ser creme, não branca;
- a cabeça passou a ocluir o visor;
- a cruz ganhou preenchimento vermelho e o flash apareceu por cima.

### 2.4 D-1175 — escala, subida e comprimento

- **Bug da escala:** o driver usava `_view_scale_at(chest)` (alvo). No jogador, o alvo está longe → 3,2 → javelin imensa; no oponente, o alvo está perto → 1,0 → javelin minúscula.
- Correção: a **javelin** usa a distância da **mão do atacante**; o voo interpola até o alvo; o **retículo/impacto** continuam usando a escala do alvo.
- **Subida no wind-up:** 0,08 m fixo + até 0,12 m automáticos calculados contra o AABB do corpo (máximo 0,20 m). A subida some suavemente no voo; no laboratório de paridade, sem corpo, é zero.
- **Comprimento:** haste de **1,85 → 2,30 m**; total **2,245 → 2,695 m**. Ponta/grip/colar mantidos; penas reposicionadas para a nova cauda (z=-1,12).
- Primeira passada; valores ajustáveis após revisão.

### 2.5 D-1176 — Dread na ponta e passagem perfurante

- **Dread:** o `FxEvadeFlash` agora reconhece o Javelin Throw como o Fire Bullet (D-1029). O aviso de evade aparece na **ponta real da javelin** (`JavelinThrowVfxHtml.javelin_tip()`), seguindo a ponta quadro a quadro. Só aparece em ataque inimigo mirando o líder (D-1168). Tamanho/timing padrão do Dread na primeira passada.
- **Passagem:** no impacto, a javelin não fica fincada. Continua no mesmo eixo por **2,6 m ao longo de 0,45 s** (escalado pelo `view_scale`), atravessa o alvo e é ocultada depois que a cauda passa. O impacto (cruz/flash/anéis/solo) continua no chest congelado.
- **Arquivos:** `fx_javelin_throw.gd` guarda o nó no `Incoming.data`; `fx_evade_flash.gd` tem o caminho Javelin; `javelin_throw_vfx_html.gd` tem `javelin_tip()` e o movimento de passagem.
- **Evidência:** `javelin_throw_orc_both_sides.mp4` (Dread na linha espelhada em ~1,50 s), `javelin_throw_target_view.mp4` (javelin atravessando), `javelin_throw_side_view.mp4`; frames `dread_check_150.png`, `pass_side_230.png`, `pass_side_250.png`.

## 3. Testes e evidências

- `godot --headless --path . --script res://tests/battle/test_javelin_vfx.gd` → **`RESULT: PASS`**.
- `--move=Javelin Throw --test-d235 --quit` → **`D235_RESULT: PASS`** (`attacker_a`, `attacker_b`, `mirrored_scaled`).
- `--move=Javelin Throw --force=hit --audit-leaks --envelope-graph --summary-json --quit` → **`[vfx_audit] leaks=0`**, **`envelope_pops: []`**.
- Suíte completa: `python tests/battle/run_agent_combat_tests.py` → **27/27**.
- A/B: `test_captures/html_ab_sheets/`, `test_captures/ab_video/javelin_html_vs_godot.mp4`.
- Combate: `test_captures/javelin_throw_orc_both_sides.mp4`, `javelin_throw_target_view.mp4`, `javelin_throw_side_view.mp4`.

## 4. Estado do commit

- **Javelin e War Cry já estão no histórico**, no checkpoint `cb113252` (VFX, move.tres, shaders, textura, cenas).
- Testes em `275c0213`; decisões/documentação em `e1069a02`.
- `git status` está limpo para os arquivos de Javelin/War Cry; não houve diff para um commit novo.
- HEAD: `108a7d0b` em `wip/checkpoint-2026-11-06`.
- O único diff vizinho é `docs/decisoes/README.md` na linha da **D-1173 (dust)**, de outra sessão; não foi stageado.
- Nenhum push (D-022).

## 5. Pendências

1. **D-1174** — a coroa do release deve acompanhar o dardo por muito menos tempo (hoje 0,15 s; vida total 0,35 s). **O novo tempo ainda não foi informado**, então a coroa e o impacto 75%/100% não foram implementados.
2. **D-1175** — 0,08 m fixo, teto automático 0,12 m e haste 2,30 m são a primeira passada; podem ser ajustados.
3. **D-1176** — timing/tamanho do Dread e velocidade/distância da passagem (2,6 m / 0,45 s) são a primeira passada.
4. **Paridade pixel a pixel** — impossível entre Three.js e Godot. O A/B usa calibração de laboratório; transmissão física do prisma não existe no `StandardMaterial3D` do Godot 4.7.
5. **Não verificado** — todos os personagens/tamanhos de alvo, Mobile/Forward+, GPU/overdraw, morte do lançador (D-094) e a API do script original (`play_move`, `set_scrub_time`, exports/sinais).

## 6. Arquivos principais

- `scripts/vfx/combat/javelin_throw_vfx_html.gd`
- `scripts/vfx/combat/html_mesh_lib.gd`
- `scripts/vfx/combat/fx_javelin_throw.gd`
- `scripts/vfx/combat/fx_evade_flash.gd`
- `scripts/debug/javelin_html_parity_lab.gd`
- `scenes/debug/javelin_html_parity_lab.tscn`
- `tests/battle/test_javelin_vfx.gd`
- `tests/fx_lab/capture_html_reference.py`
- `tests/fx_lab/build_ab_sheets.py`
- `tests/fx_lab/build_ab_video.py`
- `docs/decisoes/D-1171-*`, `D-1174-*`, `D-1175-*`, `D-1176-*`
- `docs/vfx/AUDITORIA_JAVELIN_THROW_HTML_C.md`
