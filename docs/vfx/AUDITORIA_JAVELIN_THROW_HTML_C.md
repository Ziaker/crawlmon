# Auditoria — Javelin Throw VFX, porte literal do HTML Card C (D-1171)

> **Atualização D-1175 (2026-11-11):** o VFX oficial agora usa **haste de 2,30 m** (total **2,695 m**) e, no combate, sobe a javelin no wind-up em **0,08 m fixo + até 0,12 m automático** (folga contra o corpo). As folhas A/B abaixo foram geradas antes dessa mudança e continuam válidas para o restante do efeito; comprimento e subida atuais são a nova regra.
>
> **Atualização D-1176 (2026-11-11):** o Dread de evade agora segue a **ponta real da javelin** (exceção como o Fire Bullet, D-1029) e a javelin **atravessa o alvo** no impacto (2,6 m em 0,45 s) em vez de ficar fincada. O impacto/cruz/flash continuam no chest.

- **Data:** 2026-11-11.
- **Fonte visual oficial:** `javelin_throw_3d_vfx_prototype.html`, Card 3 ("Lança do Ponto Fraco") — escolha do criador em D-1171.
- **Método desta rodada:** portar **linha a linha** a cena, os atores, a câmera, as luzes, o chão, as geometrias, os materiais e o `updateFusionAC` do HTML; capturar o próprio HTML em Chromium headless e comparar o Godot no mesmo instante, mesma câmera, mesmas vistas e mesmos lados.
- **Implementação oficial:** `scripts/vfx/combat/javelin_throw_vfx_html.gd` (`JavelinThrowVfxHtml`).
- **Biblioteca de malhas:** `scripts/vfx/combat/html_mesh_lib.gd` (`HtmlMeshLib`).
- **Laboratório de paridade:** `scripts/debug/javelin_html_parity_lab.gd` + `scenes/debug/javelin_html_parity_lab.tscn`.
- **Captura do HTML:** `tests/fx_lab/capture_html_reference.py` (Playwright/Chromium).
- **Captura do Godot:** o próprio laboratório de paridade (`--parity-capture`).
- **Folhas A/B:** `test_captures/html_ab_sheets/`.

## 1. O que foi portado literalmente do HTML

| Bloco | Fonte no HTML | O que foi portado |
|---|---|---|
| Timeline | L457–463 | 0,75 / 0,90 / 1,05 / 1,10 / 1,85 s |
| Config C | L1826–1860 | `shaftThickness 0.86`, cores, `tipWidthScale 0.9`, `starScale 1.32`, `assemblySpeed 1.15`, `prismLengthScale 0.96`, `prismWidthScale 0.94`, `numAfterImages 7`, `arcHeightFactor 0.024`, `flightExponent 0.58`, `groundShockScale 0.85`, `crossScale 1.28` |
| Lança | L795–898 | haste 1,85 em Z=-0,02; grip 0,44; colar 0,22 em Z=0,42; 3 penas com `ExtrudeGeometry`; ponta 0,52 em Z=0,78; ápice em Z=1,30 |
| Estrela | L905–927 | 2 espinhos octaédricos 0,052 × 8,2 (vertical/horizontal) + núcleo 0,11; escala e giro do update |
| Pulso | L929–949 | octaedro 0,14 × 2,2 + luva cônica 0,16→0,06, 7 lados, aberta; 0,56–0,75 s |
| Mira | L951–993 | feixe cilíndrico r=0,020 de grip+0,45 até o chest; retículo octaédrico externo 0,32 (arestas) + interno 0,18 (wireframe) |
| Coroa | L996–1082 | 7 internas (1,08×0,96; r 0,115×0,94) + 7 externas (0,80×0,96; r 0,095×0,94), cone de 3 lados, ápice em 0, cauda em -Z; gaps 0,015→0,752 e 0,055→0,987; flare 0,14→0,56 (externa ×1,22); recuo 1,22 + 1,15 − k·0,42; roll de câmera +π/14; sem giro próprio |
| Pós-imagens | L750–775, L1084–1113 | javelin 3D completa (haste + colar + ponta + arestas), 7 unidades, frações `(i+1)/8`, alpha por idade 0,72, giro `frac·3π`, cores alternadas |
| Dardo em voo | L1485–1512 | `u^0,58`; arco `clamp(dist·0,024, 0,08, 0,72)`; giro `uRaw·5π`; feixe r=0,025 de comprimento `dist·uFlight` |
| Pinagem | L1534–1556 | grip = chest − 1,30·0,68; ponta +0,416; tremor `exp(−dt·15)·sin(dt·80)·0,055`; pós-imagens residuais até 0,14 s |
| Cruz | L1183–1208, L1688–1695 | 3 octaedros 0,145·1,28 com Y·12,5·1,28; X ±45° e longitudinal 90°; escala Y `crossStretch`, X/Z `thin`; cor #FF5555, arestas brancas |
| Flash | L1210–1218, L1697–1702 | **1** octaedro `0,62·1,28`, detalhe 1; escala 0,48→2,13; alpha `flashWindow·0,86`; cor #FEF08A → #FF3B3B em 0,09 s |
| Anel atrasado | L1220–1231, L1704–1712 | torus 0,82 / tubo 0,024 / 6×24; começa em 0,08; escala 0,35→2,60; alpha 0,95 |
| Anel de solo | L1123–1136, L1651–1662 | torus 0,62 / tubo 0,07225 / 6×14; escala 0,48+expand, Y 1,35→0,32; alpha 0,92 |
| Espinhos | L1138–1155, L1664–1671 | 8 cones 4 lados r=0,11 h=0,408; raio 0,32+0,76·expand; inclinação −0,52; pop 1,1 |
| Poeira | L1157–1177, L1673–1681 | 10 dodecaedros r=0,119; 10 ângulos; speed/lift; rotação 3D |
| Faíscas | L1233–1246, L1724–1731 | 8 octaedros 0,058 × (0,65,0,65,3,4); raio 0,25+1,95·expand; zSpread; alpha 1−1,35·u |
| Atores | L546–683 | Alpha 2,12 m / 0,54 e Beta 1,90 m / 0,47; base hexagonal; pernas, torso 6 lados, peito, cabeça octaédrica detalhe 1, visor, ombros, braço direito, punho, sockets reais |
| Arena | L688–741 | fundo #0B131B + FogExp2 0,032; ambiente #DBEAFE 0,68; key #FFF7ED 1,95 (6,12,8); rim #FF5555 1,15 (−7,5,−8); piso 14×0,4×14; grid 13,6/16; 4 monólitos |
| Câmera | L1928–2020 | normal/espelhada/oblíqua exatamente como o HTML; azimute 0°, elevação 12°; FOV 44° |
| Renderer | L531–541 | antialias, PCFSoft, ACES, exposição 1,18 |

## 2. A/B: como foi capturado

- O HTML foi aberto isolando o **viewport C** em tela cheia, com o mesmo canvas WebGL e a mesma câmera; o `#slider-timeline` foi movido para cada instante e o frame foi capturado depois do render.
- O Godot foi rodado em `gl_compatibility` (WebGL/OpenGL, o mais próximo do Three.js), 1280×720, com a mesma cena de paridade e a mesma timeline.
- Cada comparação usa o mesmo instante (`0.30, 0.60, 0.74, 0.75, 0.90, 1.00, 1.05, 1.13, 1.20, 1.35, 1.60, 1.85`), a mesma vista (`normal`, `mirrored`, `oblique`) e o mesmo lado (`A`: Alpha ataca; `B`: Beta ataca).
- Artefatos:
  - `test_captures/html_ab/` — frames originais do HTML.
  - `test_captures/html_parity/` — frames do Godot.
  - `test_captures/html_ab_sheets/ab_grid_normal_a.png` e companhia — 12 instantes × 2.
  - `test_captures/html_ab_sheets/ab_key_normal_a.png` / `ab_key_mirrored_a.png` / `ab_key_normal_b.png` — momentos-chave em 640×360.
  - `test_captures/html_ab_sheets/ab_stack_normal_a_t0.90.png` / `_t1.13.png` — HTML sobre Godot em tamanho real.
  - `test_captures/ab_video/javelin_html_vs_godot.mp4` — 38 quadros a 20 fps, HTML em cima e Godot embaixo, lado A normal.
  - `test_captures/javelin_throw_orc_both_sides.mp4` — combate real, Orc nos dois lados.

## 3. O que o A/B mostra

- **Enquadramento, atores, poses, câmera, chão, grid, monólitos, luzes e timeline** coincidem. **No laboratório de paridade**, o Godot não usa mais manequins/arena escura próprios; em combate, o VFX roda sobre os modelos e a arena do jogo.
- **Lança**: comprimento, peças, penas, ápice, cores, montagem e pinagem coincidem.
- **Mira**: feixe no ponto fraco e retículo octaédrico duplo coincidem.
- **Coroa**: 14 lâminas (7+7), abertura, recuo, flare e pós-imagens 3D coincidem na composição.
- **Impacto**: cruz gigante, flash octaédrico, anel atrasado, anel de solo, espinhos, poeira e faíscas aparecem nos mesmos instantes e posições.
- **D-235**: lado A, lado B e espelhado funcionam; o efeito não depende de personagem, time, lado ou coordenada fixa.

## 4. Bug real encontrado e corrigido: winding das malhas

O Godot considera **clockwise** como face frontal; o Three.js usa a convenção oposta na geração das geometrias. A primeira versão da biblioteca gerava triângulos outward em CCW, então todas as malhas procedurais (cabeça, torso, lança, cruz, flash, anéis, poeira) estavam sendo renderizadas pelo **lado de dentro**. Sintomas: o visor aparecia inteiro por cima da cabeça, a lança estourava para branco e a iluminação dos atores ficava invertida.

A correção foi feita em `HtmlMeshLib._tri` / `_tri_n`: a normal outward continua sendo calculada como no Three.js, mas os vértices são enviados em ordem **CW** para o Godot. Depois disso:

- o visor voltou a ser uma fresta como no HTML;
- a lança voltou a ser creme, não branca;
- a cabeça passou a ocluir o visor e a receber luz pelo lado certo;
- a cruz ganhou o preenchimento vermelho e o flash passou a aparecer por cima;
- o A/B de 0,60/0,75/0,90/1,13/1,50 ficou muito mais próximo.

## 5. Diferenças reais que restam (renderer, não geometria)

1. **Shading/tone mapping**: Three.js e Godot não respondem igual. Para o A/B, o laboratório de paridade usa uma calibração de luz (`ambient 0.06`, `key 0.90`, `rim 0.06`, `exposure 1.0`, fundo `#18202A`) que aproxima a imagem do HTML; esses valores são **do laboratório**, não do jogo.
2. **Transmissão do prisma**: `StandardMaterial3D` do Godot 4.7 não tem `transmission`; a coroa usa alpha + emissão (0,92/0,80) como o HTML, mas sem refração física.
3. **Espessura de linha**: Godot desenha linhas de 1 px; o Three.js também ignora `linewidth` e desenha 1 px. A diferença é a cobertura/AA do backend.
4. **Ordem de transparência**: o HTML ordena por profundidade; no Godot foi necessário `render_priority` para o flash aparecer sobre a cruz, as arestas sobre o preenchimento e as faíscas por cima. Sem isso, a cruz cobria o flash.
5. **Anel de solo**: a emissão do HTML é 0,95; no Godot ela foi reduzida para 0,45 para o anel ficar no tom palha do HTML em vez de amarelo saturado. O valor do HTML está registrado aqui; é uma compensação de renderer.
6. **Brilho do visor/ator**: com o winding corrigido, o visor voltou a ser uma fresta; no A/B o emissivo do ator foi reduzido de 0,45 para 0,15 **no laboratório** para igualar o brilho do HTML. É calibração do laboratório, não do VFX.
7. **Pixel-idêntico**: não é possível entre Three.js e Godot. O que foi entregue é o **mesmo código/medidas/tempos/câmera** com A/B no mesmo instante.

## 6. Provas

- Teste dedicado: `godot --headless --path . --script res://tests/battle/test_javelin_vfx.gd` → `RESULT: PASS` (14 lâminas, 7 pós-imagens, 8 faíscas, estrela 2+core, colar vermelho, retículo octaédrico, flash, cruz, zero sobras).
- D-235: `--move=Javelin Throw --test-d235 --quit` → `D235_RESULT: PASS` com `attacker_a`, `attacker_b`, `mirrored_scaled`.
- Vazamentos: `--move=Javelin Throw --force=hit --audit-leaks --envelope-graph --summary-json --quit` → `[vfx_audit] leaks=0 nodes=[]`, `envelope_pops: []`.
- Suíte completa: `python tests/battle/run_agent_combat_tests.py` → **27/27**.
- A/B em vídeo: `test_captures/ab_video/javelin_html_vs_godot.mp4` (38 quadros, HTML em cima, Godot embaixo, lado A normal).
- A/B em folhas: `test_captures/html_ab_sheets/` (12 instantes × 2, normal/espelhado, lado A/B).
- Vídeo de combate: `test_captures/javelin_throw_orc_both_sides.mp4` (Orc nos dois lados, 135 quadros por vista).
- Folha de fases: `test_captures/javelin_throw_orc_both_sides_phases.png`.

## 7. O que não foi verificado

- Todos os personagens e todos os tamanhos de alvo (a matriz cobre Orc, Abra, Gible, Pancham e Cyclops em amostra).
- Mobile/Forward+ e custo de GPU/overdraw.
- Pixel-idêntico (impossível entre os dois renderers).
- A API do script original (`play_move`, `set_scrub_time` no VFX, exports e sinais) continua ausente; a integração é `BattleFx` + laboratório.
- D-094: a batalha ainda cancela o `Incoming` quando o lançador morre; o visual para. É regra de combate, não alterada.
- O texto do Card C diz "7 lâminas"; o código cria **14** (7+7). A implementação segue o código, como D-1171 declarou.
