# D-1106 — War Cry: direção visual C (pressão sônica)

- **Data:** 2026-11-10.
- **Área:** VFX / War Cry / D-308.
- **Origem:** escolha do criador entre as três direções de `docs/vfx/referencias/WAR_CRY_REFERENCIAS.md`.
- **Status:** direção escolhida; **implementação em andamento**.

## O que o criador disse (literal)

> "C"

## Decisão

1. **Direção C — Pressão sônica:** um **cone/megafone** com a ponta na boca do lançador e a boca larga na direção dos oponentes; dentro dele viajam **anéis rápidos**, com raio crescendo e opacidade caindo ao longo do tempo/distância. Além do cone: linhas de velocidade, distorção de tela leve e poeira/detritos.
2. **Fases D-308:** wind-up 0–0,30 s; release 0,30 s; anéis viajando 0,30–1,15 s; impacto por inimigo ~1,17 s; dissipação até 1,35 s.
3. **Anéis:** **6 anéis** perpendiculares ao eixo do cone, saindo da boca e correndo até os oponentes; o raio cresce de `TIP_R` até o raio do cone; a opacidade cai de ~0,95 até 0 no fim do percurso. Não são anéis radiais ao redor do lançador.
4. **Cone/linhas:** uma casca de megafone translúcida e fraca (ponta na boca, boca larga nos oponentes), com opacidade que diminui para o fim; linhas de velocidade dentro do cone.
5. **Poeira/detritos:** poeira levantada nos pés e detritos/clumps curtos; sem sujeira residual.
6. **Distorção:** leve, radial, 0,2–0,25 s no release; **sem tremor de câmera** (D-1027).
7. **Âncora:** osso de cabeça (`j_kao` no Orc; fallback `head`/altura do corpo); boca deslocada para frente/baixo; eixo derivado do centro real dos oponentes; comprimento/raio derivados da distância e do espalhamento reais, nunca de personagem/time/lado (D-235).
8. **Sincronia:** a lógica interrompe todos no instante do status (1,167 s); os anéis viajam rápido e o impacto visual coincide. Flinch (D-1105) e cartão quebrado (D-1104) continuam no instante da lógica.
9. **GL Compatibility:** sem GPUParticles, sem decals, sem sub-emitters; malhas, CPUParticles3D, quads e shaders.
10. **Composer:** opcional (D-1030); o efeito principal é hand-built.

## Segunda rodada

> "muito mais amplo cobrindo todos inimigos crie uma textura pra isso cace referencias use elden ring"

> "e pra meio qie causar um gaussian blur destorcer a vista"

- **Cone ampliado:** o raio final cobre o desvio lateral máximo de **todos** os inimigos (+1,5 m), com um leque mínimo de `comprimento × 0,65`; comprimento até o inimigo mais distante +2 m; teto de 30 m. O cone cobre a linha inimiga inteira.
- **Textura:** `assets/vfx/war_cry_wave_tex.png`, gerada por `tools/generate_war_cry_texture.py`; bandas irregulares, poeira/cinza e brasas, usada como máscara de detalhe na casca do cone. Referência: Elden Ring (rugoso, empoeirado, brasas; não neon limpo).
- **Gaussian blur + distorção:** `war_cry_distort.gdshader` agora faz warp radial + blur gaussiano radial de 9 taps; `amount` 0→0,85→0 em 0,10 + 0,22 s; a HUD fica nítida (CanvasLayer abaixo dela).
- Vídeos finais: `test_captures/vfx_tools/war_cry_white_final6_normal.mp4`, `_mirrored.mp4`, `_dqt_normal.mp4` e `_dqt_mirrored.mp4` (arquivos separados, além do stack). Prova: `w6_t0,34.png` e `w6_t0,42.png`.

## Terceira rodada

> "essas argolas não deviam ser vermelhas"

> "2 - a velocidade delas devia ser muito maior, além de mais largas, com mais massa."

> "3 - vc não deu video do outro lado, sempre dê um video do outro lado"

> "4 - eu queria que houvesse um efeito de pulsos brancos ao redor do interrupted para ESTE move em específico de alta velocidade e .35 de duração"

> "5 - essa textura não é semi-transparente além de ser vermelha por nenhuma razão"

- **Cor:** as argolas do War Cry são **brancas/creme/cinza**, não vermelhas. A textura também é branca/cinza, semi-transparente (alpha máx. 0,55), sem vermelho.
- **Velocidade e massa:** os anéis correm em **0,38 s** (antes 0,65 s), são **7**, com tubo de 10% do raio (antes 1,5–4%) — mais largos e com mais massa.
- **Pulsos brancos no interrompido:** o `WarCryVfx.impact` agora cria **2 anéis de tela + 1 anel de chão + 2 toros brancos** ao redor do personagem interrompido, alta velocidade e **0,35 s**, exclusive do War Cry.
- **Vídeos separados:** sempre entregar **normal e espelhado em arquivos separados**, além do stack. Finais: `war_cry_white_final3_normal.mp4`, `_mirrored.mp4`, e o par DQT `_dqt_normal.mp4`/`_dqt_mirrored.mp4`.
- Verdito: `--audit-leaks` = **leaks=0**; `envelope_pops` vazio.

## Quarta rodada

> "estranho que vc faz certo no inicio do move mas faz errado nessas argolas que se movem, deixe elas com uma opacidade minúscula quanto mais se distanciam do jogador"

- **Opacidade por distância:** os anéis em movimento agora usam `alpha = 0,95 × (1 − progresso)^2,5`. Ficam brilhantes perto da boca e **praticamente invisíveis** ao se afastarem na direção dos oponentes.
- Vídeos finais: `war_cry_white_final4_normal.mp4`, `_mirrored.mp4`, `_dqt_normal.mp4` e `_dqt_mirrored.mp4`. Provas: `w4_t0,5.png` (anéis próximos) e `w4_t0,7.png` (quase sumiram ao longe).

## Quinta rodada

> "é pra reduzir drasticamente ao longo do tempo em altissima velocidade já no inicio, não depois, no segundo que são disparadas já reduz até 0"

- **Todos os anéis são disparados no mesmo instante** (sem stagger); offsets só distribuem o cone.
- A opacidade cai de **0,95 para 0 em 0,10 s** a partir do disparo; o deslocamento usa ease-out (rápido no começo). Em ~0,12 s os anéis já não existem; sobra a casca/blur do cone.
- Vídeos finais: `war_cry_white_final6_normal.mp4`, `_mirrored.mp4`, `_dqt_normal.mp4` e `_dqt_mirrored.mp4`. Provas: `w6_t0,34.png` (flash inicial) e `w6_t0,42.png` (anéis já sumiram).

## Sexta rodada

> "volta atrás com o final4 do war cry, eu entendi o maior problema dele, só faça esses rings brancos perderem muita opacidade quanto mais se distânciam e faça eles já iniciarem com 35% de opacidade"

- **Volta ao final4:** os 7 anéis voltam a sair em **voleio escalonado de 0,03 s**, com deslocamento linear no cone e a mesma casca/blur do final4 (sem o fade de 0,10 s do final5/final6).
- **Opacidade:** cada anel **começa em 35%** (`0,35`) e perde opacidade com a distância pela curva `0,35 × (1 − progresso)^2,5`; perto dos oponentes já está quase invisível.
- Vídeos finais: `war_cry_final7_nopause_normal.mp4`, `_mirrored.mp4`, `war_cry_final7_nopause_dqt_normal.mp4` e `_dqt_mirrored.mp4` (separados). Provas: `f7_t0,34.png` (início a 35%) e `f7_t0,60.png` (anéis quase sumiram ao longe; a casca do cone continua).
- A pausa de status do War Cry foi removida à parte, na **D-1127** (experimental).

## Ambiguidades em aberto

- Intensidade final do blur e da textura serão julgadas no vídeo.
- Número de anéis (7) e tom do branco continuam ajustáveis.
- A opacidade inicial de 35% ainda soma com o brilho aditivo do shader (`energy = 2.2`); se o criador quiser mais apagado, é ajuste novo.

## Estado no código

Implementado (2026-11-10), **aguardando aprovação visual**:
- `scripts/vfx/combat/war_cry_vfx.gd`: cone/megafone, 7 anéis viajando, casca, linhas, poeira, distorção e impacto por inimigo.
- `shaders/war_cry_cone.gdshader` (casca), `shaders/war_cry_ring.gdshader` (anéis), `shaders/war_cry_distort.gdshader` (distorção).
- `scripts/combat/battle_fx.gd`: `war_cry` inicia o VFX no início do Move (sem congelar ninguém, D-1127) e o impacto em `play_hit`.
- Vídeos finais: `test_captures/vfx_tools/war_cry_final7_nopause_normal.mp4`, `_mirrored.mp4`, `war_cry_final7_nopause_dqt_normal.mp4` e `_dqt_mirrored.mp4` (arquivos separados). Prova: `f7_t0,34.png`, `f7_t0,60.png` e `f7d_t0,34.png`.
- **Verificado:** cone amplo cobrindo os três inimigos, ponta na boca, anéis viajando, raio crescendo, opacidade caindo, textura na casca, blur radial, duas vistas, impacto e flinch/cartão; `--audit-leaks` deu **leaks=0** e o summary não registrou `envelope_pops`.
- **Não verificado ainda:** `--scale-overlay`/`--bg`, alvos de tamanhos diferentes, aprovação visual da intensidade do blur/textura.

O VFX em si não muda regra de combate; a remoção da pausa é a decisão separada D-1127.
