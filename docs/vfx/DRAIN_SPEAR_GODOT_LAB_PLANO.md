# Plano — Laboratório Godot da Drain Spear (Orc + Motion Composer + cenários A–H)

- **Data:** 2026-11-06
- **Estado:** plano para aprovação. **Nenhum código de efeito, cena ou regra foi alterado ainda.** → **Atualização 2026-11-06:** primeira versão implementada e testada; depois os ajustes aprovados (lança no chão → mão, POV do outro lado, sem projétil, 6 faixas de aura, retorno do Badge Steal, batalha real) foram implementados. Ver `docs/vfx/DRAIN_SPEAR_GODOT_LAB_ENTREGA.md`. O plano abaixo permanece como registro do que foi aprovado e do que mudou.
- **Escopo:** protótipo visual.
- **Branch de trabalho:** `wip/checkpoint-2026-11-06` (tem o Orc, o Motion Composer V1.9 e a arena).
- **Fonte das decisões da Drain Spear:** `origin/main` (D-356 a D-372), lida por `git show`; essa documentação **não existe** no checkout local, que para em D-354. Não fiz merge nem push.

## 1. Decisões aplicáveis

Citadas por ID e, quando houver colisão de numeração, com a origem:

- **D-235** — Move/VFX independentes de personagem, time, lado e posição; testar espelhado e alvos de tamanhos diferentes.
- **D-308** — quatro fases (Wind-up, Release, Trajeto, Impacto), transição contínua, vídeo normal + espelhado, qualidade real do Godot.
- **D-322 (local, efeitos)** — refazer efeitos com o Motion Composer; **D-322 (origin/main, BattleLog)** — opção C, faixas off-white diagonais com retrato.
- **D-323 (local)** — melhorar o Composer antes de qualquer efeito; estilo estilizado/cel-shading.
- **D-327 (local)** — o Composer precisa de malhas/modelos 3D, não só texturas e formas procedurais.
- **D-331/D-333** — Quarks é exceção **apenas do atelier HTML**; no Godot, usar os recursos do jogo.
- **D-332** — fogo por shader + flipbook (referência de acabamento).
- **D-337** — fidelidade visual e sincronia com o relógio real; uma entrega por vez, aguardando aprovação.
- **D-356 (origin/main)** — ficha parcial da Drain Spear: `move_drain_spear`, 2 ATB + 12 MP, Normal, contato mid-range, dano mágico `5 + MAG` mitigado por SPI, wind-up 1,0 s / execução 1,0 s / recovery 1,6 s provisórios.
- **D-357 (origin/main)** — Normal é elemento neutro, separado da categoria de dano e da execução.
- **D-358 (origin/main)** — centro 16,3 u, faixa 15,3–17,3 u, recuo base 1,2 s reduzido por AGI, ataque mesmo sem completar o recuo.
- **D-359 (origin/main)** — Badge Steal rouba só buffs positivos e escudos com badge, antes do dano, apenas em acerto válido; não rouba debuffs.
- **D-372 (origin/main)** — imunidade mágica roubada antes do dano não protege contra o próprio impacto.
- **D-348 (origin/main)** — o plano mecânico é a autoridade dos eventos e tempos; o visual recebe os gatilhos e não decide o resultado.
- **D-268** — HUD de buffs/debuffs angular e diagonal; **D-342/D-339** — escalas do Orc aliado (1,2×) e inimigo (2,16×); **D-341** — Orc lento provisório.
- **D-044/D-045/D-043/D-046** — representações, presets, camadas ordenadas e escopo do Motion Composer.
- **D-061** — registrar as decisões aprovadas em documento próprio antes de abrir a próxima rodada.

## 2. O que entendi do pedido

Criar **um novo protótipo único, no Godot**, que:

1. use o **Orc já importado** (`assets/modelos/dqt_orc/dqt_orc.glb`) com as animações reais;
2. use a **câmera do `drain_spear (1).html`** (CINEMA: posição `(3.8, 2.875, 7.0)`, alvo `(-2, 0, -20)`, FOV 80°, Dutch 4°, com câmera livre só para inspeção);
3. use os **parâmetros de cenário do `crawlmon_prot_tipo...html`** (A–H, distâncias, badges, resultado, MAG/SPI, qualidade, alcance);
4. **misture o melhor dos dois efeitos visuais** em um efeito novo, construído sobre o **Motion Composer** e as skills de VFX/shaders/animação;
5. seja uma entrega **surpreendente**, mas sem alterar regras de combate, sem implementar a Drain Spear no jogo e sem push.

## 3. O que vou construir

Uma **cena de laboratório isolada**:

- `scenes/debug/drain_spear_lab.tscn`
- `scripts/debug/drain_spear_lab.gd` (relógio único, cenários, UI, câmera, HUD)
- `scripts/vfx/drain_spear_vfx.gd` (só entrega posições, relógios e câmera ao Composer; nenhuma aparência)
- `scripts/ui/drain_spear_lab_hud.gd` (faixas, badges, BattleLog, timeline)
- extensões no Motion Composer:
 - representação `spear` (malha 3D + shader de revelação/dissolução);
 - shader `shaders/mc_drain_spear.gdshader` (núcleo, ponta, aura, borda, ruído, pulso);
 - preset `MotionPresets.drain_spear_effect(seed)` com as camadas das fases;
 - pincel `MotionPainter.spear` e o `MotionRep` correspondente.
- testes:
 - `tests/motion_composer/test_v110_drain_spear.gd` (camadas, fases, determinismo, geometria, sem sobras);
 - `tests/fx_lab/record_drain_spear_lab.py` (vídeo normal + espelhado, 1280×720).

O laboratório usa a `BattleArena` real (chão, céu, luzes, ruínas) e os modelos reais, mas **não** carrega o combate, a IA, o HUD do jogo nem a timeline de `Battle`. Ele tem relógio próprio de simulação, com scrub e captura por CLI.

## 4. O melhor de cada protótipo (mapa da mistura)

| Elemento | `drain_spear (1).html` | `crawlmon_prot_tipo...html` | Novo laboratório Godot |
|---|---|---|---|
| Câmera | CINEMA exata + órbita livre | mesmos números + debug | CINEMA exata + órbita livre; **sem zoom, tremor ou roll animado** |
| Lança | malha única facetada (lathe), shader de reveal/dissolve, aura e glow | pomo + cabo + colar + lâmina + aura + gradiente | malha facetada com silhueta mais rica (pomo, cabo, guarda, lâmina), shader portado, aura e pulso de ponta |
| Formação | revelação do cabo à ponta | sparkles, partículas orbitando a ponta, espera vertical | revelação + sparkles + órbita da ponta + modo “alvo se aproxima” |
| Reposicionamento | speedlines | modos de distância, anéis mid-range, recuo | speedlines + modos de distância + anéis + recuo com duração configurável |
| Estocada | speedlines, rastro da ponta | estocada + janela de Evade | **3 pós-imagens fantasma** da lança + speedlines + contato exato |
| Impacto comum | 78 fragmentos em streak + spray Quarks | 3 camadas (streaks rápidos, cacos, faíscas finas) | M16 + streaks customizados + cacos + faíscas + halo + poeira + marca no chão; 0,55 s |
| Badge Steal | streaks reversos que viram órbita | siphon reverso + orbs + órbita | M06 + M05: streaks reversos + orbs + coroa de badges roubadas orbitando; 0,30 s de HUD |
| Dissolução | dissolve do cabo à ponta | fade/dissolve | M18 + shader; brasas e fumaça subindo |
| HUD | tags limpas, badge rack, BattleLog | painel completo A–H, badges, log | painel do laboratório + tags flutuantes + badge rack + BattleLog opção C |
| Cenários | A–H simples | A–H completo + distâncias + badges + MAG/SPI + qualidade | A–H completo + todos os parâmetros + reach mode + qualidade |
| Personagem | substituto | substituto | **Orc real** (`dqt_orc.glb`) + clipes 32 (Ready), 01 (Walk), 11 (SkillA) |

## 5. Arquitetura do efeito (Motion Composer)

### 5.1 Fases e relógios

- **Wind-up:** `t = 0,00–1,00 s` (provisório). Lança vertical ao lado do corpo; revelação do cabo à ponta; sparkles; aura da ponta.
- **Reposicionamento:** `t = 0,35–1,55 s` (se necessário). A lança acompanha o Orc e inclina para o alvo; speedlines; anéis de mid-range opcionais.
- **Estocada:** `t = 1,55–1,85/1,95 s`. A lança avança; a ponta encontra o ponto de contato; janela de Evade.
- **Impacto comum:** `t = 1,85–2,40 s` (0,55 s). Leque de shotgun do contato para além do alvo; streaks, cacos, faíscas, halo, poeira.
- **Badge Steal:** `t = 1,88–2,18 s` (0,30 s). Fluxo reverso alvo → atacante; órbita; badges de HUD.
- **Dissolução:** `t = 1,90–2,45 s`. A lança some do cabo à ponta; brasas e fumaça.
- **Recovery:** `t = 2,45–4,05 s`. Volta ao Ready.
- **Total do laboratório:** `4,2 s` (com margem de inspeção).

Todos esses tempos são **provisórios** e ficam visíveis na timeline; o laboratório mede e mostra o instante real de cada marco.

### 5.2 Camadas do preset `drain_spear_effect`

- `windup/spear` — representação `spear`, revelação por shader.
- `windup/motes` — `spark` + M17/M18/M24 (faíscas subindo e orbitando).
- `windup/tip_orbit` — `spark` + M05 (hélice na ponta).
- `windup/ring` — `ring`/`mark` no chão, opcional.
- `thrust/spear` — representação `spear`, eixo base→ponta.
- `thrust/ghosts` — 3 cópias da lança com atraso, opacidade decrescente.
- `thrust/speedlines` — `spark` com `trail_dt` + M22 (arrasto).
- `impact/spines` — M16 + M22/M23 (leque rápido, gravidade e arrasto).
- `impact/shards` — M16 + M24 (cacos/fragmentos com turbulência).
- `impact/fines` — M16 + M22 (faíscas finas).
- `impact/flash` — `halo` no contato.
- `impact/dust` — `puff`/`smoke` de poeira.
- `impact/ground` — `mark`/`ring` no chão.
- `steal/siphon` — M06 (convergência) + M21/M24 (fluxo/turbulência) do contato ao atacante.
- `steal/orbs` — `spark`/`orb` + M06/M05.
- `steal/orbit` — M05 em volta do atacante.
- `dissolve/spear` — M18 + shader, do cabo à ponta.
- `dissolve/embers` — `spark` + M23 (gravidade).
- `dissolve/smoke` — `puff` subindo.

### 5.3 Malha e shader da lança

- Malha 3D própria (lathe de 8 lados, níveis do protótipo `(1)`, com pomo, cabo, guarda, lâmina e ponta), construída em `ArrayMesh` e reutilizada pelo pincel; **não** é textura nem fita.
- Shader `mc_drain_spear`: gradiente cabo→ponta, `reveal`/`dissolve` por posição local, borda clara, ruído de superfície, pulso da ponta, opacidade; `unshaded` com blending adequado ao GL Compatibility.
- Aura da ponta separada (halo/quad billboard) para não lavar o núcleo.
- **Tamanho do laboratório:** medido na tela. O comprimento inicial proposto é 6,4 m (o mesmo do protótipo), ajustável no laboratório e sujeito à aprovação.

### 5.4 Independência (D-235)

- Nada no efeito usa nome, espécie, time, `is_player`, lado ou coordenada fixa.
- Âncoras:
 - centro, altura e raio medidos do AABB real de cada modelo;
 - eixo atacante→alvo e vetor lateral derivados dos centros;
 - âncora da lança: osso da arma/punho quando existir; fallback para o lado do corpo (altura do quadril/peito) quando não existir;
 - ponto de contato: superfície do alvo na altura do tórax, recuada pelo raio.
- O laboratório terá um seletor de atacante (Orc/Slime/Cyclops) **só para prova**: o mesmo efeito deve rodar com qualquer um, inclusive sem arma.

## 6. Cenários do laboratório

Botões A–H (do `crawlmon_prot_tipo`), com os parâmetros visíveis e editáveis:

- **A — Impacto comum:** sem badges roubáveis; spray normal.
- **B — ATK +1 e escudo:** Badge Steal; duas badges transferidas; spray reverso + órbita.
- **C — Imunidade mágica:** badge removida antes do dano; mostrar a ordem visual (D-372).
- **D — Evade:** sem contato, sem spray, sem transferência.
- **E — Atacante muito próximo:** recuo até a faixa; lança vertical durante o recuo.
- **F — Alvo se aproximando:** lança vertical enquanto espera a faixa.
- **G — Espelhado:** Orc inimigo distante atacando alvo próximo; mesmo efeito.
- **H — Anatomias diferentes:** Orc vs Slime/Cyclops; alvos de tamanhos diferentes; opção de trocar o atacante para provar D-235.

Parâmetros extras:

- **Distância inicial:** distante 22,5 / na faixa 16,3 / próximo 8,5 / melee 2,6 / alvo aproximando.
- **Recuo simulado:** 0,5–1,6 s (base 1,2).
- **Reach mode:** `hybrid` (padrão), `elongate`, `surge` — marcados como **experimentais**, não homologados (D-358).
- **Resultado:** acerto, evade, interrupção.
- **Badges:** ATK +1, escudo 18/30, imunidade mágica, DEF −1 (não roubável).
- **MAG** 5–25, **SPI** 0–10, prévia `5 + MAG` mitigado.
- **Qualidade:** baixa/média/alta (afeta contagens de partículas, não os shaders principais).
- **Câmera:** CINEMA / órbita livre.
- **Anéis mid-range:** visíveis/ocultos.
- **Escalas:** escalas do jogo (D-339/D-342) ou mesma escala para comparação.
- **HUD:** completa / mínima / oculta.

## 7. UI do laboratório

- Cabeçalho com contrato do Move (2 ATB + 12 MP, Normal, mid-range, Badge Steal).
- Palco 3D ocupando a tela; painel discreto e recolhível (não cobre o centro do combate).
- Timeline com scrub, play/pause/restart/replay, velocidade 0,25×/0,5×/1×/2× e salto por fase.
- Leitura de fase, distância atual, tempo e modo de alcance.
- Tags flutuantes do atacante e do alvo projetadas do 3D.
- Badge rack + voo das badges em 0,3 s.
- BattleLog no canto superior direito, faixas off-white diagonais com retrato (D-322 origin/main).
- Painel de checklist técnico do protótipo (o que está sendo demonstrado, o que é provisório).

## 8. Orc: modelo e animações

- `assets/modelos/dqt_orc/dqt_orc.glb`, perfil `dqt_orc` (altura nativa 1,772 m, alvo 2,1 m, rotação Y 180°, escala aliada 1,2×, escala inimiga 2,16×).
- `DqtModelProfiles.apply_anim_aliases` + `setup_weapon_follow` + `DqtEyes` + `start_idle_breath`.
- Mapa proposto:
 - **Wind-up/recovery:** clipe `32` (Ready / battle idle).
 - **Reposicionamento:** clipe `01` (Walk), com root motion removido e passo casado.
 - **Estocada:** clipe `11` (SkillA — a estocada de lança), com velocidade/offset ajustados para o contato cair no marco da timeline.
 - **Reação do alvo:** clipe `10` (Damage) e recuo curto.
 - **KO (opcional):** clipe `30` (Die), se o cenário permitir.
- A lança mágica usa o osso da arma/punho do Orc como âncora quando disponível; o fallback sem arma é obrigatório e será testado com Slime.

## 9. Verificação obrigatória

1. Rodar os testes do Composer em headless.
2. Rodar o laboratório em janela, 1280×720, `--fixed-fps 60`.
3. Capturar **quadros em tamanho real** nos instantes: 0,50; 1,00; 1,55; 1,85; 2,00; 2,30; 3,00; 4,20 s, nas vistas **normal e espelhada**.
4. Percorrer os cenários A–H e conferir:
 - lança vertical do cabo à ponta;
 - distância 16,3 u (faixa 15,3–17,3);
 - recuo quando perto; espera vertical quando o alvo se aproxima;
 - estocada e contato legíveis;
 - spray de shotgun normal;
 - spray reverso + órbita no Badge Steal;
 - badges em 0,3 s;
 - sem transferência em evade/interrupção;
 - dissolução e recovery;
 - **zero sobras** na tela ao fim (contar nós por pincel com `MotionPainter.stats`).
5. Provar D-235: mesmo efeito com Orc, Slime e Cyclops; atacante sem arma; lado espelhado; alvos de tamanhos diferentes.
6. Gravar **um vídeo único** com normal em cima e espelhado embaixo, em resolução cheia (D-308), e um segundo vídeo curto com os cenários A–H, se aprovado.
7. Dizer o que **não** foi verificado (desempenho, outros hardwares, aprovação artística, etc.).

## 10. O que não vou fazer

- Não alterar `battle.gd`, `attack_planner.gd`, `battle_camera.gd`, `battle_hud.gd`, regras de combate, GDD ou `REGRAS_DO_JOGO.md` para fazer o protótipo.
- Não criar Skill/Resource de Drain Spear no jogo, nem ligar o efeito ao combate.
- Não usar Quarks no Godot (a exceção D-331/D-333 é só do HTML do atelier).
- Não usar formas planas/fitas finas como efeito principal; não usar partículas de GPU no GL Compatibility.
- Não mexer nos assets modificados do working tree; não commitar nem fazer push sem autorização.
- Não inventar regra, tempo, ângulo ou comportamento onde a ficha ainda está pendente; o que for experimental fica marcado.

## 11. O que vai surpreender

> Estas são **propostas visuais experimentais** do laboratório, não regras homologadas. Se alguma não agradar, ela sai sem afectar as outras.

1. A lança mágica **desenrola da lança física do Orc** e se estende em uma lâmina de cristal azul (com fallback para modelos sem arma).
2. **Três pós-imagens** da lança na estocada, como um rastro de velocidade mágico.
3. Impacto em **duas escalas**: um leque branco-azul curto e rápido + um leque lento de cacos/brasas que cai com gravidade.
4. Badge Steal **inverte o leque** em um sifão espiral que termina em uma **coroa de badges orbitando** o Orc.
5. Modo **“prova de independência”**: troca o atacante para Slime/Cyclops e espelha a cena sem mudar uma linha do efeito.
6. **Congelamento no contato** (pausa + órbita de inspeção) para ver o impacto em 3D, sem alterar a timeline.

## 12. Dúvidas para confirmar antes de codar

**Respostas aprovadas em 2026-11-06:** 1A, **2A corrigido** (a lança mágica envolve a lança física de **qualquer** usuário de lança, não só do Orc; fallback para o corpo), 3A, 4A, 5A, 6A, 7A, 8A. O laboratório será implementado com essas escolhas.

Responda no formato `1A, 2A...` (ou descreva a sua escolha):

1. **Escopo:** (A) laboratório isolado novo, sem tocar no combate **[recomendado]**; (B) dentro da `vfx_room`; (C) os dois.
2. **Lança mágica:** (A) envolve/aprimora a lança física do Orc quando existir, com fallback para o corpo **[recomendado]**; (B) sempre separada ao lado do corpo; (C) substitui a lança física.
3. **Animação da estocada:** (A) clipe `11` (SkillA) sincronizado ao 1,0 s de execução **[recomendado]**; (B) clipe `12` (SkillB); (C) clipe `11` em velocidade natural (1,73 s) e timeline provisória ajustada.
4. **Modo de alcance a 16,3 u:** (A) `hybrid` padrão + os três modos no laboratório **[recomendado]**; (B) só `hybrid`; (C) só `elongate`; (D) só `surge`.
5. **Mistura visual:** (A) seguir a tabela da seção 4 **[recomendado]**; (B) usar o impacto do `(1)` também; (C) usar a lança do `tipo` também; (D) outra combinação (descreva).
6. **Escalas:** (A) escalas do jogo (Orc 1,2× aliado / 2,16× inimigo) **[recomendado]**; (B) mesma escala nas duas vistas para comparar.
7. **HUD:** (A) completa, com tags, badges e BattleLog **[recomendado]**; (B) mínima, só timeline e badges; (C) sem HUD.
8. **Primeira entrega:** (A) laboratório interativo + primeiro vídeo + folha de quadros, e depois esperar aprovação **[recomendado]**; (B) primeiro um quadro estático para aprovação, depois o vídeo; (C) só o efeito em uma cena de teste, sem UI.

## 13. Prompt de autoexecução (para eu enviar a mim mesmo depois do seu OK)

```text
Você é o agente do projeto Crawlmon. Execute o plano aprovado em
docs/vfx/DRAIN_SPEAR_GODOT_LAB_PLANO.md (ou o plano imediatamente acima).

ANTES DE QUALQUER LINHA:
1. Cite as decisões aplicáveis: D-235, D-308, D-322 (local, efeitos), D-322
 (origin/main, BattleLog), D-323, D-327, D-331/D-333, D-332, D-337,
 D-356, D-357, D-358, D-359, D-372, D-348 (origin/main), D-268,
 D-339, D-341, D-342, D-044/D-045/D-043/D-046, D-061.
2. Leia AGENTS.md, docs/decisoes/README.md, os D-*.md locais relevantes,
 docs/vfx/PROTOCOLO_VFX_OBRIGATORIO.md, docs/vfx/MOTION_COMPOSER_V1.md,
 os dois protótipos HTML e as decisões D-356..D-372 via
 `git show origin/main:docs/decisoes/...` (elas não existem no checkout).
3. Carregue as skills com a ferramenta Skill: scenario-godot-vfx,
 scenario-godot-shaders, scenario-godot-animation e scenario-godot-expert.
4. Escreva o checklist literal do efeito (cada frase do criador vira uma
 linha verificável).
5. Trabalhe na branch wip/checkpoint-2026-11-06. Não faça merge, commit ou
 push. Não altere o combate, o HUD do jogo, o GDD nem REGRAS_DO_JOGO.
6. Se qualquer detalhe novo for ambíguo, PARE e pergunte; não invente.

OBJETIVO:
Criar um laboratório Godot isolado da Drain Spear que una o melhor dos dois
protótipos HTML, use o Orc real e as animações reais, a câmera CINEMA do
drain_spear (1).html e os cenários A–H do crawlmon_prot_tipo, com o efeito
construído com malhas, shaders e animação reais.

PARÂMETROS FIXOS:
- Câmera CINEMA: pos (3.8, 2.875, 7.0), alvo (-2, 0, -20), FOV 80°,
 Dutch 4°; câmera livre só para inspeção.
- Orc: assets/modelos/dqt_orc/dqt_orc.glb; clipes 32 (Ready), 01 (Walk),
 11 (SkillA); escala aliada 1,2× e inimiga 2,16×; weapon follow.
- Mid-range: 16,3 u; faixa 15,3–17,3 u; recuo base 1,2 s.
- Fases provisórias: wind-up 1,0 s; execução 1,0 s; recovery 1,6 s;
 spray 0,55 s; badges 0,30 s.
- Cenários A–H + distâncias 22,5/16,3/8,5/2,6/aproximando + reach modes
 hybrid/elongate/surge + badges ATK+1/escudo/imunidade mágica/DEF−1 +
 resultado acerto/evade/interrupção + MAG/SPI + qualidade.
- Tamanho do VFX: medido na tela. Nada dependente de
 personagem, time, lado ou câmera (D-235).

ENTREGA:
1. Cena interativa scenes/debug/drain_spear_lab.tscn.
2. Efeito no Motion Composer (representação `spear`, shader
 mc_drain_spear, preset drain_spear_effect, pincel no MotionPainter).
3. Controlador que só entrega posições, relógios e câmera.
4. HUD do laboratório (timeline, tags, badges, BattleLog opção C).
5. Teste headless do Composer.
6. Vídeo único normal + espelhado em 1280×720; folha de quadros.
7. Relatório: o que foi verificado, como, o que não foi verificado e o que
 ficou fraco.

VERIFICAÇÃO:
- Quadros em tamanho real nos instantes 0,50; 1,00; 1,55; 1,85; 2,00;
 2,30; 3,00; 4,20 s, nas duas vistas.
- A–H completos; Orc/Slime/Cyclops; atacante sem arma; alvos de tamanhos
 diferentes; nada sobra na tela no fim.
- Não afirmar que testou sem executar.

PARE depois da primeira entrega completa e espere a aprovação do criador.
Um ajuste por vez; não remende sem achar a causa com dados.
```

## 14. Próximo passo

Se o plano estiver aprovado, responda as 8 dúvidas (ou diga “vai com os recomendados”). Eu registro as respostas em um documento de decisão do protótipo, atualizo o índice e só então começo a implementar.
