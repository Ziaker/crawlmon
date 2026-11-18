> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** Teste em <10 s: `python tests/battle/check_eyes_combat.py --models` (um modelo por rodada, duas vistas).

# Como adicionar um modelo com olhos que piscam e fecham (BLIND, hit)

Decisões: D-340, D-1268, D-1271, D-1272, D-1295. Nada no código usa nome de espécie (AGENTS.md §7.2): o jogo escolhe a estratégia pelos dados do GLB em `EyeStrategy.detect` (`scripts/common/eye_strategy.gd`).

## 1. Conferir o que o modelo tem
```powershell
./Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/overworld/diag_eye_strategy.gd -- --ids=<id>
```
Sem `--ids` lista todos de `assets/modelos/`. A tabela mostra a estratégia, quantas superfícies `*_eye`, as malhas `Eye_Model_*`, os pares `<X>_scale`, os ossos `OpenEye`/`CloseEye` e `*mabuta*`, e se o clipe Sleep (`<prefixo>04`) existe.

## 2. Convenções que o detector entende
| Dado no GLB | Estratégia | Quem fecha |
|---|---|---|
| material de superfície chamado `*_eye` | `shader_lid` | `EyeShine` + `EyeBlink` (pálpebra por shader, pisca sozinho) |
| malha `Eye_Model_*` com `<X>_scale` e Sleep com escala > 0,5 | `decal` | `DqtEyes` mostra o adesivo de olho fechado (pisca sozinho) |
| ossos `OpenEye` e `CloseEye` | `open_close_bones` | `DqtEyes` segura a pose Sleep dos ossos |
| ossos `*mabuta*` com trilhas no Sleep | `bone_lids` | `DqtEyes` segura a pose Sleep dos ossos |
| nada disso | `none` | o modelo não fecha os olhos |

Todas expõem a mesma interface ao `BattleFx` (`hold_closed`, `squeeze(s)`, `blink_now()`, `lid_k`, `blinks`) e emitem `eyes`, `eyes_blink`, `eyes_lid` (docs/TELEMETRIA.md, seção Olhos).

## 3. Registrar o modelo
- Modelos DQT: perfil em `content/characters/<id>/model_profile.tres` com `clip_prefix` (o Sleep é `<prefixo>04`). Se a pose dos ossos não cobre o branco do olho (caso do Orc), `"paint_closed_eye": true` (e `eye_cover_color` como reserva): pinta o olho fechado na textura da cabeça. O dado não diz sozinho se a pálpebra cobre o branco; a ferramenta só aponta `paint_candidate`. Decida olhando a captura.
- Teste: acrescente o id em `CATALOG` de `tests/battle/check_eyes_combat.py` (e em `NO_OWN_BLINK` se ele não pisca sozinho) e rode `--models`. Captura aberto/fechado: `--scenario=olhos_debug_quieto --units=gible/<id>,gible --cam=macro --cam-height=<m> --no-panel --record=3.6 --step=0.6 --out=res://test_captures/eyes_combat/<tag>` (rode o Godot direto na linha de comando; hook `--no-window`).

## 4. O extrator Tact (`C:\Games\Tact`, SÓ LEITURA)
Os GLB saem em `C:\Games\Tact\monstros\00\<id>_<nome>\modelo_3d\*.glb`. O que o extrator entrega: malhas `Eye_Model_*`, nós/ossos `<X>_scale`, `OpenEye`/`CloseEye`, ossos `*mabuta*` e clipes `<prefixo>NN` (04 = Sleep). Confira os nomes no GLB original antes de pensar que falta dado; se um nome existe no bundle mas não no GLB importado, aponte a correção do extrator, sem aplicar. Fungi (`0038_obakekinoko`) não traz olho fechado: o dado não existe lá.

## 5. Quando nada existe
Deixe `none` (o modelo não pisca nem fecha) e diga isso. As opções (adesivo, pintura na textura, pálpebra por shader) são decisão do criador, que também valida o visual; valores meus ficam pendentes.
