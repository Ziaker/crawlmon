# D-1020 — Ferramentas de pesquisa e criação de VFX: requisitos e ordem aprovada

- **Data:** 2026-11-08
- **Área:** VFX / Ferramentas / Processo
- **Origem:** pedido direto do criador, depois da pesquisa dos 4 efeitos e da direção de usar Godot em cena separada (D-1017).
- **Estado:** **ordem aprovada; ferramentas 1, 4 e 6 implementadas e testadas; ferramentas 2, 3 e 5 não iniciadas**. Nada foi declarado aprovado visualmente; nenhum commit/push.

## Frase literal do criador

> "Objetivo: continuar a biblioteca própria, dentro do Godot 4.7.2 (GL Compatibility), de ferramentas para PESQUISA e CRIAÇÃO de VFX. Elas servem para os próximos agentes fazerem os elementos que faltam (Fire, Water, Wind, Earth, Nature, Psychic, Light, Dark, Sound, Mystic, Neutral) sem repetir o retrabalho do Electric. Veja docs/vfx/auditorias/AUDITORIA_ELECTRIC_BEAM.md."

> "O que já existe e deve ser reaproveitado ou consolidado, sem duplicar: ..."

> "Ferramentas que mais fariam falta (proponha a ordem ao criador antes de fazer): ..."

> "Regras: Tudo independente de personagem e de lado (D-235). Ferramentas de debug não mudam regras do jogo. Pergunte antes de qualquer ambiguidade. Uma entrega por vez, mostrando a ferramenta funcionando. Registre decisões em docs/decisoes/D-xxx. Não faça commit nem push sem pedido."

## Requisitos

1. A biblioteca é de **ferramentas para pesquisar e criar VFX**, não de um novo efeito. Ela deve reduzir o retrabalho mostrado na auditoria do Electric Beam.
2. **Reaproveitar e consolidar**, sem duplicar: `tests/fx_lab/record_move_video.py`, a sala de VFX, os kits `addons/agentkit/vfx` e `addons/agentkit/shaders`, `vfx/shaders`, `vfx/runtime`, `scripts/combat/fx/projectile_lib/`, o Motion Composer, os flipbooks de `assets/vfx/` e o mapa de clipes DQT.
3. **Independente de personagem, time, lado e posição (D-235)**: alvos e atacantes por papel/lado, nunca por índice fixo; medidas derivadas dos modelos reais.
4. **Ferramentas de debug não mudam regras**: nada de dano, alcance, tempo lógico, acerto, ATB ou câmera do jogo. Elas observam, medem e apresentam.
5. **Uma entrega por vez**, mostrando a ferramenta funcionando; sem lote de seis ferramentas de uma vez.
6. **Perguntar antes de qualquer ambiguidade**; registrar decisões em `docs/decisoes/D-*.md`; nada de commit/push sem pedido.
7. **Elementos:** o jogo tem 12 elementos oficiais (D-397/D-398). **Electric já está aprovado** (D-976) e serve de caso de regressão. Os **11 restantes** citados pelo criador são: Fire, Water, Wind, Earth, Nature, Psychic, Light, Dark, Sound, Mystic e Neutral.

## Respostas do criador (2026-11-09)

1. **Ordem aprovada:** 1 → 6 → 4 → 3 → 2 → 5, começando pela ferramenta 1.
2. **Aprovados para o verificador:** Electric Beam, Fire Bullet, Thunder Wave, Confuse, Bubble Shield e Media. Os nomes literais “Thunder Wave” e “Confuse” ainda precisam ser mapeados para os nomes do catálogo (`Shock Wave` e `Confusion` são os candidatos) quando a ferramenta 2 for fechada.
3. **Custo aceito:** usar `agent_profile.gd` (CSV com `gpu_ms`) + overdraw por fase + draw calls; RenderDoc só quando o `gpu_ms` vier 0/impreciso no GL Compatibility Windows.
4. **Desenho de caminho:** seguir a recomendação do assistente — trajeto lógico e caminho visual, com o lógico como padrão.
5. **Pesquisa de referência:** pode baixar trechos públicos com `yt-dlp` e guardar **apenas quadros + metadados** (sem vídeos) em `docs/vfx/referencias/`.

## O que já existe (mapa de reaproveitamento)

| Peça existente | O que já faz | O que falta para a ferramenta |
|---|---|---|
| `tests/fx_lab/record_move_video.py` | **implementado:** normal + espelhado, pré-checagem de 1 s, falha rápida, atacante/alvo por lado, folha por fase, log e manifesto | ver `docs/vfx/FERRAMENTAS_VFX.md` para uso e limites |
| `scripts/debug/vfx_room.gd` | `--target=opponent` (por lado), `--clean`, `--cam`, `--stun`, `--scenario`, `--record`, `--shot`, `[vfx_room]`, `sheet.png`; novos `--preflight` e `--real-mp` | **`--dqt`/`--dqt-mirror` não estão aqui**: são lidos por `battle_scene.gd`; o gravador já repassa e a pré-checagem imprime os lados |
| `addons/agentkit/vfx/vfx_capture.gd` | captura por tempo exato, overdraw, AABB, câmera, `--fixed-fps` | existe, mas **não é chamado por nenhum outro `.gd`/`.py`**; o gravador não usa; falta integração |
| `addons/agentkit/vfx/vfx_audit.gd` | auditoria estática de emissores, colisão, AABB, decals, luzes | não mede tempo de GPU nem compara quadros aprovados |
| `addons/agentkit/agent_profile.gd` | CSV por frame com `frame_ms`, `cpu_ms`, `gpu_ms`, `draw_calls`, primitivas, memória; já chama `viewport_set_measure_render_time`/`viewport_get_measured_render_time_gpu` | não está integrado ao gravador nem mede por fase; validar `gpu_ms` no GL Compatibility Windows |
| `addons/agentkit/vfx/vfx_selftest.gd` | hit-stop, ciclo de vida, projétil, sub-emissor | não é regressão visual de efeitos aprovados |
| `scripts/vfx/perception/vfx_perception.gd` | A/B, silhueta, fundo claro/escuro, cobertura, draw calls, repetibilidade | não desenha caminho estático nem lê vídeo de referência |
| `scripts/combat/fx/swing_trail.gd` | acha mão/arma por partes genéricas, mede arma | usado pela ferramenta 4; a folha visual de poses ainda falta |
| `scripts/combat/dqt_model_profiles.gd` | perfis DQT, `_bone_global_at`, stride dos pés, weapon follow | usado pela ferramenta 4 para expor as medidas por clipe |
| `scripts/combat/character_model_loader.gd` | instancia modelos e aliases de animação | usado pela ferramenta 4 no `Battle`; o modo “medir sem batalha” ainda falta |
| `scripts/combat/vfx_lib.gd` | `flipbook_tex`, malhas, outline, ghost, burst | é a base de render das ferramentas, não a ferramenta |
| `docs/IMPORTACAO_MODELOS_DQT.md` | mapa de clipes 00, 01, 10, 11, 12, 30, 32, 50 | falta medir e versionar os clipes de cada modelo |

## Correções da auditoria do criador (2026-11-09)

O criador auditou o relatório e apontou dois erros e uma omissão:

1. **`--dqt`/`--dqt-mirror`:** não existem no `vfx_room.gd`; só `--mirror`. Correção: a tabela não os atribui mais ao `vfx_room`. Eles são lidos por `scripts/combat/battle_scene.gd` via `OS.get_cmdline_user_args()` (linhas 88–96). O gravador repassou `--dqt-mirror` em 2026-11-09 e o Slime entrou como enemy; o teste normal+espelhado completo com DQT ainda não foi feito.
2. **Ferramenta 5:** `addons/agentkit/agent_profile.gd` já mede `gpu_ms`; a tabela não o listava. Correção: a ferramenta 5 é **extensão/integração** do que existe, não construção do zero.
3. **D-019:** o arquivo existe no checkout desta sessão, mas a `AUDITORIA_PROIBICOES.md` (A2) registra que ele foi apagado e o trata como redação do agente. A formulação anterior (“consta no índice”) era imprecisa; a divergência fica preservada.

## Ordem aprovada (2026-11-09)

A ordem segue dependência e dor real da auditoria: primeiro o que impede perder tempo, depois o que impede construir errado, depois o que protege o que já foi aprovado.

1. **Gravador robusto** (ferramenta 1 do criador).
   - Fundação de todas as outras: sem captura confiável, nenhuma comparação vale.
   - Reusa `record_move_video.py` + `vfx_room.gd`; `vfx_capture.gd` fica para as ferramentas de captura/custo.
   - Entrega: pré-checagem de 1 s, falha rápida, alvo por lado (`--target=opponent`), atacante por papel, aviso de recusa lendo `[vfx_room]`, folha automática por fase, vídeo normal+espelhado, log preservado.
2. **Pesquisa de referência** (ferramenta 6) — **implementada em 2026-11-09**.
   - Independente do Godot e do combate; destrava os 11 elementos.
   - Entrega: script que recebe vídeo local ou URL + elemento + efeito + fase + timestamps, extrai quadros em resolução cheia, monta folha rotulada e grava manifesto (fonte, timestamp, elemento, fase, hash).
   - Corrige a lição da auditoria: referência velha/print ruim não serve; o trecho exato manda.
3. **Medição do corpo e dos clipes** (ferramenta 4) — **implementada em 2026-11-09**.
   - Corrige a raiz do erro "modelo mais próximo" e das três buscas diferentes.
   - Reusa `CharacterModelLoader`, `DqtModelProfiles`, `SwingTrail` e `docs/IMPORTACAO_MODELOS_DQT.md`.
   - Entrega: JSON + CSV com altura posada, centro/raio do corpo, ossos de mão/cabeça/arma, comprimento da arma e velocidade de cada osso por clipe; nada por nome de personagem.
4. **Desenho estático de caminho** (ferramenta 3).
   - Depende da medição do corpo para ancorar início, alvo e altura.
   - Entrega: o trajeto inteiro, parado e opaco, em 3 vistas (lado, topo, 3/4), com fases coloridas, setas, início/fim, silhueta do alvo e distância; PNG + JSON.
   - Serve para o criador aprovar a forma **antes** de animar.
5. **Verificador de aprovados** (ferramenta 2).
   - Depende do gravador e de uma lista de aprovados definida pelo criador.
   - Entrega: re-grava os aprovados, compara com os quadros de referência (diff, SSIM/PSNR, silhueta, cobertura, caixa, brilho, draw calls) e emite PASS/WARN/FAIL com imagem de diferença; nunca atualiza a referência sozinho.
6. **Custo** (ferramenta 5 — parcialmente existente).
   - Depende do gravador e de uma cena limpa.
   - **Não construir de novo:** `addons/agentkit/agent_profile.gd` já grava `frame_ms`, `cpu_ms`, `gpu_ms`, `draw_calls`, primitivas, memória e usa `viewport_set_measure_render_time`/`viewport_get_measured_render_time_gpu`.
   - Entrega: ligar o `agent_profile` ao gravador, medir por fase, somar overdraw (debug view do `vfx_capture`/Viewport), reportar CSV + resumo. **Validar `gpu_ms` no GL Compatibility Windows**; se vier 0/impreciso, complementar com RenderDoc e dizer no relatório.

**Estado da ferramenta 1 (2026-11-09):** implementada em `tests/fx_lab/record_move_video.py`, com apoio de `vfx_room.gd` (`--preflight`, `--real-mp`, atacante por lado). Testada com Electric Beam (135 quadros, 4,5 s, fases WINDUP/RELEASE/STRIKE/TRAVEL/IMPACT/RETURN), Fire Bullet (75 quadros, 2,5 s), recusa por atacante=alvo, Move inexistente, atacante/alvo inexistente e duração curta (aviso de IMPACTO ausente). `--dqt` sozinho é rejeitado; `--dqt-mirror` foi exercitado. Evidência em `test_captures/vfx_tools/` e uso em `docs/vfx/FERRAMENTAS_VFX.md`. Não testado: `--dqt` normal+espelhado, recusa por MP (o DqtTestParty agora dá 20 MP; o caso 0 MP não existe na sala), Evade/morte no voo, alvos de tamanhos diferentes, aprovação visual.

**Estado da ferramenta 6 (2026-11-09):** implementada em `tests/fx_lab/reference_capture.py`. Testada com vídeo local (2 fases) e URL pública do P5R (2 fases, com pré-roll de 0,003 s registrado no manifesto). Saída em `test_captures/vfx_tools/reference_capture_local/`, `.../reference_capture_url/` e no caminho padrão `docs/vfx/referencias/capturas/psychic/p5r_critical/`; uso em `docs/vfx/FERRAMENTAS_VFX.md`. Não testado: crop em produção, vídeos com duração menor que o timestamp, fontes bloqueadas por login/região e aprovação da organização por elemento.

**Estado da ferramenta 4 (2026-11-09):** implementada em `tests/vfx/body_clip_measure.gd`. Testada com `--dqt` (Orc, Slime, Cyclops) e com o time padrão (Abra/Pancham + inimigos aleatórios): separa arma/ajudantes do corpo, acha mão/cabeça/arma genéricas, marca cabeça por fallback quando não há nome e mede 10–23 clipes por unidade. Saída em `test_captures/vfx_tools/body_clip_measure/` e `.../body_clip_measure_standard/` (`measurements.json`, `clips.csv`, `summary.txt`); uso em `docs/vfx/FERRAMENTAS_VFX.md`. Não testado: todos os modelos do jogo, vértices deformados um a um, folha visual de poses, GPU e aprovação dos nomes de ossos.

## Conflitos e cuidados

- **D-019:** o arquivo existe no checkout desta sessão, mas a `AUDITORIA_PROIBICOES.md` (A2) registra que ele foi apagado e o trata como redação do agente (origem `PROMPT`), não como frase do criador. A divergência fica preservada; não é usado como regra. As ferramentas **não** criam relógio/timeline de combate: apenas leem as fases e os tempos reais do `Battle`.
- **D-308 item 6** (tamanho fixo em metros) é tratado na auditoria como leitura ambígua; a ferramenta de medição reporta **mundo e tela**, sem decidir tamanho.
- **Motion Composer:** D-953/D-954 o colocam como movimento secundário; a ferramenta não deve obrigar nenhum efeito a passar por ele. O gravador funciona com efeito à mão ou com Composer.
- **D-235:** todo seletor de alvo/atacante é por papel/lado; nada de índice fixo. O `vfx_room` tem `--target=opponent` e o gravador usa; a pré-checagem imprime `attacker_side` e `target_side` (por exemplo, `player→enemy` no normal e `enemy→player` no espelhado).
- **D-022:** nada de commit/push.
- **D-003:** nenhuma ferramenta altera regra, tempo, dano ou visual do jogo.

## Pendências para a próxima ferramenta

1. **Aprovação das entregas das ferramentas 1 e 6** (gravador e captura de referência): os vídeos/quadros provam as ferramentas, não a arte.
2. **Nomes literais da lista aprovada:** “Thunder Wave” e “Confuse” precisam ser mapeados para `Shock Wave` e `Confusion` (ou o nome real do catálogo) antes do verificador.
3. **Ferramentas 2, 3 e 5:** não iniciadas; a próxima da ordem é a 3 (desenho estático de caminho), salvo o criador preferir outra.

## Estado

Ferramenta 1 implementada em `tests/fx_lab/record_move_video.py` e testada em `Electric Beam` e `Fire Bullet`, mais recusa por atacante=alvo, Move inexistente, atacante/alvo inexistente e duração curta. Ferramenta 6 implementada em `tests/fx_lab/reference_capture.py` e testada com vídeo local e URL. Ferramenta 4 implementada em `tests/vfx/body_clip_measure.gd` e testada com `--dqt`. Nada foi commitado ou enviado. A árvore está modificada e sem commit. O que **não** foi verificado: `--dqt` normal+espelhado, recusa por MP (o DqtTestParty agora dá 20 MP; o caso 0 MP não existe na sala), Evade/morte no voo, alvos de tamanhos diferentes, crop em produção, todos os modelos do jogo e aprovação visual. A próxima ação é a ferramenta 3 (desenho estático de caminho).
