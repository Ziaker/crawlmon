# Referência auditável — prompt original do Javelin Throw (D-1162)

> Transcrição dos requisitos numéricos e comportamentais da mensagem que iniciou a implementação.
> O HTML anexado é `javelin_throw_3d_vfx_prototype.html` (Card C — "Lança do Ponto Fraco").
> O script autocontido da mesma mensagem é referido como "script original".
> Onde o prompt e o HTML divergem, este documento **não decide**: apenas registra os dois lados.

## 1. Regras arquiteturais

- D-235: nada de `is_player`, nome de personagem, time, lado, coordenada fixa. `hand`, `chest`, `feet`, `axis`, `dist`, `tip`, `target_radius` e `target_height` vêm dos nós/modelos reais.
- `impact_scale = clamp(target_radius * 1.6, 0.75, 1.65)`.
- D-308/D-019: quatro fases e linha do tempo única; o visual não decide quando o golpe acontece.
- D-1103: wind-up 0,75 s; 2 ATB / 5 MP; dano 1,2×ATK; crítico por vida; o VFX não muda regra.
- D-1030: procedimental, sem Motion Composer obrigatório.
- Proibido: Sprite3D billboard, GPUParticles de pontinhos, CanvasItem/UI 2D, decalques circulares, RibbonTrailMesh fino. Tudo é geometria 3D volumétrica.
- Escala nunca negativa; funciona em Normal, Espelhada e Oblíqua.

## 2. Paleta

| Papel | Albedo | Emissão | Energia |
|---|---|---|---|
| Ouro Solar / Branco-Dourado (núcleo/ponta) | `#FFF3C4` | `#FFD166` | 2,8–4,5 |
| Carmesim Crítico (acentos/retículo/pós-imagens/cruz) | `#FF2A55` | `#EF4444` | 3,2 |
| Âmbar de Carga (pulso/anel de solo) | `#F59E0B` | `#FBBF24` | 2,5 |
| Aço Obsidiana (haste/colar) | `#1E293B` | — | metallic 0,85; roughness 0,25 |

## 3. Orientação

`build_spear_basis(axis, camera_pos, origin)`:

1. `forward = axis.normalized()`.
2. `up_ref = UP`, ou `FORWARD` se `abs(forward·UP) > 0.98`.
3. `right = up_ref.cross(forward).normalized()`; `up = forward.cross(right).normalized()`.
4. `to_cam = (camera_pos - origin).normalized()`; `cam_proj = (to_cam - forward*(to_cam·forward)).normalized()`.
5. `cam_roll = atan2(cam_proj·right, cam_proj·up) + 0.22`.
6. `Basis(right, up, forward).rotated(forward, cam_roll)`.

Nada de billboard; a coroa não gira no próprio eixo, só usa esse roll.

## 4. Fases e números do prompt

### Fase 1 — Wind-up (0,00–0,75 s)

- Lança total 2,15 m; `SPEAR_HALF=1,075`; `radius_scale=0,82`; ápice local `Z=+1,075`, cauda `Z=-1,075`.
- Recuo: 0,00→0,70 recua `-0,28 m`; 0,70→0,75 volta.
- 5 peças, `ease_out_cubic`, escala 0,25→1, opacidade crescente:
  1. Haste: cilindro h=1,45, raio 0,018→0,023, centro Z=-0,15; obsidiana + anéis dourados.
  2. Grip: cilindro h=0,38, raio 0,030, centro Z=-0,05; carmesim/ouro.
  3. Colar: cilindro 8 lados h=0,12, top 0,044/bottom 0,028, Z=+0,58; torus outer 0,048/inner 0,032.
  4. Penas: 3 aletas 0,012×0,095×0,28, 120°, Z=-0,78; offset radial +0,32 e tilt 0,7 rad.
  5. Ponta: pirâmide 4 faces, base Z=+0,58, ápice +1,075, bottom_radius 0,052, h=0,495, flat; offset (0, 0,22, 0,55), giro Z=PI; **última peça**.
- Janelas: haste 0,00–0,22; grip 0,12–0,35; colar 0,25–0,48; penas 0,36–0,58; ponta 0,46–0,68.
- Offsets iniciais: (0,0.35,-0.45)/(0.8,0.4,0); (0.28,-0.22,-0.15)/(0,0,1.4); (-0.25,0.28,0.30)/(-0.9,0.5,0); penas radial; (0,0.22,0.55)/(0,0,PI).
- Pulso 0,58–0,75: torus + cilindro curto translúcido raio 0,055, da empunhadura Z=-0,15 até o ápice 1,075.
- Estrela 0,60–0,75: 3 octaedros alongados X/Y/Z, tamanhos `(0.42,0.055,0.055)`, `(0.055,0.42,0.055)`, `(0.055,0.055,0.42)`, ancorada em `tip`, curva elástica, gira em Z, não some: alimenta a coroa.
- Linha de mira 0,05–0,75: cilindro núcleo r=0,010 branco-dourado + casca r=0,024 carmesim translúcida, de `tip` até `chest`; comprimento 0→100% entre 0,05 e 0,30; pulsa em intensidade.
- Retículo 0,15–0,75: anel octogonal 3D + 4 cunhas piramidais em `chest`, orientado por `axis`; distância radial 0,55×S→0,18×S; gira 180°; trava em 0,72.

### Fase 2 — Release / Coroa (0,75–1,10 s; dt_rel 0,00–0,35)

- Nasce em dt_rel=0; acompanha o dardo até 0,15; some em 0,35.
- 7 lâminas prismáticas triangulares (`radial_segments=3`, top 0,004, bottom 0,048, flat) + aresta/contorno emissivo.
- Internas (0,2,4,6): L=0,58, radial +0,00, longitudinal 0,00.
- Externas (1,3,5): L=0,46, radial +0,042, longitudinal -0,055.
- Ápices convergem no `tip` real em dt=0. (O prompt também define `radial_gap=0,025` em dt=0; há uma tensão interna.)
- Sem giro longitudinal; somente `cam_roll`.
- Posição: dt≤0,15 acompanha `javelin_tip_pos(t)` e recua `0,68 m` com `ease_out_cubic`; depois desprende da posição em 0,90 e recua mais `0,38 m` com desaceleração cúbica.
- `p_open=clamp(dt/0.35)`; `ease_open=1-(1-p)^2.4`.
- Gap radial: 0,025 em dt=0; 0,25+layer em dt=0,15; 0,46+layer em dt=0,32.
- Flare: 9° em 0; 25° em 0,15; 36° em 0,32.
- Opacidade 0,85→0,65 até 0,22; cai a 0 em 0,35; espessura afina nos últimos 0,08.

### Fase 3 — Trajeto (0,75–1,05 s)

- `u=clamp((t-0.75)/0.30)`; `u_flight=pow(u,0.88)`.
- `arc_height=min(dist*0.035,0.28)`; `pos=hand.lerp(chest,u_flight)+UP*4*u_flight*(1-u_flight)*arc_height`.
- `tangent` por diferença de posições; `javelin_spin=u*TAU*3.5`.
- 7 pós-imagens 3D completas; `u_ghost=u-k*0.095` (k=1..7); ativas se `u_ghost>0` e `t<1.16`.
- Cores k=1..3 `#FFF3C4`, k=4..7 `#FF2A55`; alpha `(1-k/7.5)*0.55`.
- Feixe octogonal 3D de `hand` até o dardo, `top_radius=0.018`, `bottom_radius=0.042`, ativo 0,75–1,05 e decai até 1,22.

### Fase 4 — Impacto (1,05–1,85 s; dt_imp 0,00–0,80)

- Dardo fincado em `chest`, ponta +0,32 além do chest; vibração da cauda `sin(dt*65)*exp(-dt*14)*0.08` nos primeiros 0,22; dissolve 1,65–1,85.
- Cruz 3D:
  - 2 lâminas em X (+45°/-45° no plano ortogonal a `axis`, 15° para frente), comprimento 2,65×S, espessura central 0,14×S, pontas a zero.
  - 1 lâmina longitudinal ao longo de `axis`, 2,95×S, espessura 0,16×S.
  - Expansão 0,06; depois alonga e afina; cor branco-ouro→carmesim até 1,55.
- Flash crítico 3D: 2 poliedros concêntricos, núcleo branco-ouro r=0,38×S, casca carmesim r=0,62×S; expande até 0,08 e colapsa/dissipa até 0,30.
- Anel fino atrasado: invisível 1,05–1,13; nasce em 1,13; raio 0,18×S→1,85×S com `ease_out_quart`; tubo 0,022×S; centrado em `chest`, inclinado 18°; ouro/carmesim.
- Anel rasteiro: em `feet+0.04`; raio 0,22×S→1,45×S; tubo 0,065×S; 0,00–0,65.
- 10 blocos 3D de poeira/rocha (0,06–0,13 m), arcos parabólicos com gravidade real e rotação 3D.
- 12 faíscas críticas 3D (comprimento 0,24, raio 0,022) ejetadas de `chest` em +axis com cone.

## 5. API / controles do script original

- `class_name JavelinThrowVFX extends Node3D`.
- `play_move(attacker: Node3D, target: Node3D, camera: Camera3D)`.
- `set_scrub_time(t: float)` determinístico 0,00–1,85.
- `auto_spawn_sandbox`, `loop_playback`, `attacker_node`, `target_node`, `active_camera`, `ground_y`.
- Sandbox com dois rigs 2,12 m e 1,90 m, views Normal/Espelhada/Oblíqua, troca de lado, pausa, quadros 0,75/0,90/1,05/1,07, scrub, azimute/elevação.
- Sinais `move_windup_completed`, `move_hit_triggered`, `move_finished`; telemetria `--stdout-trace`/`--summary-json`.

## 6. HTML Card C — valores próprios (para comparação, não para substituir o prompt sem decisão)

- Haste 1,85 m, centro Z=-0,02; tipLocalZ=1,30; ponta 0,52; colar Z=+0,42; penas Z=-0,68.
- Janelas de montagem 0,00–0,16 / 0,11–0,27 / 0,22–0,38 / 0,33–0,49 / 0,44–0,58; drawback 0,36; `easeOutBack`.
- Estrela: 2 octaedros + núcleo (não 3 octaedros).
- Coroa: internas L=1,08, externas L=0,80; gap 0,015→0,80 (inner) e 0,055→1,05 (outer); recuo 1,22 + 1,15; flare 0,14→0,56 rad.
- Pós-imagens: posições por fração `(idx+1)/(N+1)`; alpha `(1-fadeAge)*0,72`; giro `frac*PI*3`; 7 no Card C.
- Dardo: giro `uRaw*PI*5.0`.
- Cruz: escala Y=`crossStretch`, X/Z=thin; flash único; anel atrasado 0,35→2,60; solo 0,48+2,35.
- Espinhos de solo: 8 cones 4 lados (r=0,11, h=0,48), poeira 10 dodecaedros.
- Arestas 3D na ponta e na cruz.

## 7. Conflitos já identificados (não decidir sozinho)

1. Lança 2,15 m / ápice 1,075 (prompt) vs 2,60 m / 1,30 (HTML).
2. Haste 1,45 / centro -0,15 / ponta base 0,58 (prompt) vs 1,85 / -0,02 / 0,78 (HTML).
3. Coroa 0,58/0,46 e gap 0,25/0,46 (prompt) vs 1,08/0,80 e gap 0,80/1,05 (HTML).
4. Recuo da coroa 0,68/0,38 (prompt) vs 1,22/1,15 (HTML).
5. Estrela 3 octaedros (prompt) vs 2 espinhos+núcleo (HTML).
6. Pós-imagens 0,095 em u / alpha 0,55 (prompt) vs frações / alpha 0,72 (HTML).
7. Giro do dardo TAU*3,5 (prompt) vs PI*5 (HTML).
8. Janelas de montagem e drawback (prompt vs HTML).
9. Cruz 3 lâminas explícitas (prompt) vs escala Y (HTML).
10. Anéis/flash (prompt) vs escalas do HTML.
