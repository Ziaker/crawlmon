# Prompt: acabamento da mecânica de olhos (piscar, BLIND, hit) e adaptação automática a modelos novos

Projeto Crawlmon (Godot 4.7, pasta de trabalho do repo). Leia `AGENTS.md`, `CLAUDE.md`, `docs/TELEMETRIA.md` (seção "Olhos") e as decisões D-340, D-1268, D-1271, D-1272, D-1295, D-235, D-1204 (use `node ~/.claude/tools/ds-decisions.mjs`; cite os IDs). Outras sessões editam o mesmo working tree: só Edit pontual, sem `git stash/checkout/reset`, commite só os arquivos desta frente (staging por hunk quando o arquivo tem mudança alheia; sem push).

## Regras de operação (aprendidas nesta frente)
- **Godot só inline** na linha de comando (`./Godot_v4.7.2-stable_win64_console.exe ...`), nunca dentro de script Python/PowerShell: o hook `--no-window` não pega e a janela rouba o foco do criador (isso foi barrado). `--headless` só para lógica; visual com captura real (`--record`, `--cam=macro --cam-height=<m>`).
- O hook `dcg` bloqueia heredocs com substituição e redirecionamentos dinâmicos: escreva scripts auxiliares com Write (scratchpad) e rode `python -I arquivo.py` por PowerShell.
- IDs de decisão colidem com outras sessões: confira `ls docs/decisoes | grep D-12` antes de criar (D-1290/D-1291 já existem; esta frente usa D-1295).
- O criador decide visual e valores: valores meus ficam "pendentes". "Ficou melhor" NÃO é aprovação. Nunca use "validado/pronto/aprovado" para visual; entregue captura e diga que aguarda o julgamento dele.
- Dados antes de imagem; duas vistas (normal e `--mirror`); nenhum teste >1 min (D-1204).

## Estado atual (commitado, sem push)
- Pikachu, Eevee, Charmander, Bulbasaur, Gible, Squirtle, Pancham: `EyeShine`/`EyeBlink` (`scripts/common/eye_shine.gd`, `eye_blink.gd`): brilho no olho chapado e pálpebra por shader; piscar aleatório, BLIND (`hold_closed`) e hit de 0,5 s (`squeeze`).
- DQT com malha de olho fechado (`Eye_Model_a` + `<X>_scale`): Slime, Dracky, Healslime via `DqtEyes` (`scripts/combat/dqt_eyes.gd`).
- DQT com ossos `*mabuta*`: Sabrecub, Cyclops seguram a pose do clipe Sleep (`<prefixo>04`) em t=0; **Orc**: flag `hide_eye_mesh_on_close` no perfil (`content/characters/dqt_orc/model_profile.tres`) pinta o olho fechado na textura da cabeça (branco repintado com a pele + linha de cílios). Resultado do Orc: criador disse "ficou melhor"; valores ainda pendentes.
- Sem solução: Platypunk (nós `OpenEye`/`CloseEye`), Fungi (sem dado de olho fechado). Ver `docs/plans/AUDITORIA_OLHOS_DQT_TACT.md`.
- Telemetria: `eyes`, `eyes_blink`, `eyes_lid` (`--eyes-trace`); controles de debug: `--status=<PAPEL>:eyes_blink|eyes_close|eyes_open|eyes_hit`, botões "Olhos: ...", `--units=a,b/c,d`, `--cam-height=<m>`; cenários `olhos_debug`, `olhos_debug_inimigo`, `olhos_debug_dqt`, `olhos_debug_quieto`; `python tests/battle/check_eyes_combat.py` (duas vistas).

## Tarefa 1 — Acabamento da mecânica
1. Rodar `python tests/battle/run_agent_combat_tests.py` (em segundo plano) e separar: Javelin Throw D-235 (já falhava antes), Summon UI D-1244 e hub (estouro do limite de 10 s com a máquina carregada; rode isolados 3x). Reportar o que for novo e consertar o que for desta frente.
2. Interpretação pendente (D-1272): golpe totalmente absorvido por escudo não fecha os olhos. Verificar com cenário e perguntar ao criador se quer o contrário (uma pergunta só).
3. Robustez: modelo morto/KO (olhos?), troca por Summon (D-1244) com modelo novo no lugar, `hold_closed` preso se o BLIND acaba junto com o hit, vários hits seguidos (squeeze não acumula além de 0,5 s), pausa de status/Tactics (o `_process` do piscar roda pausado?), espelhado e todos os lados.
4. Cyclops e Sabrecub: capturas com enquadramento fixo (`--cam-height`) aberto/fechado e, se algum parecer ruim, aplicar a técnica de pintura na textura (como no Orc) em vez de pose de osso.
5. Limpeza: código morto em `dqt_eyes.gd` (`_eye_bones`, constantes), nomes (`hide_eye_mesh_on_close` passa a significar "pintar olho fechado na textura": renomear para algo honesto com migração do `.tres`), comentários em inglês coerentes, `TELEMETRIA.md` atualizada para DQT (hoje diz "DQT não emitem"; agora emitem `eyes`).

## Tarefa 2 — Feature: olho fechado para todos os modelos sem flag por espécie
Hoje o Orc depende de uma flag no perfil. Objetivo: o jogo escolher sozinho a estratégia por dado do modelo, sem nome de espécie no código (AGENTS.md §7.2).
1. Criar um detector único (ex.: `EyeStrategy.detect(root)`) que devolva, por modelo: `shader_lid` (superfície `*_eye`, EyeBlink), `decal` (malha `Eye_Model_*` + `<X>_scale`, DqtEyes), `open_close_nodes` (nós `OpenEye`/`CloseEye`, Platypunk), `bone_lids` (ossos `*mabuta*` cujo Sleep fecha de fato), `painted_texture` (branco do olho na textura da cabeça + sticker de pupila: Orc) ou `none`.
2. Critério de dado para escolher entre `bone_lids` e `painted_texture` sem flag (ex.: medir se a pose Sleep dos ossos muda a área visível do branco; ou se o branco ainda está visível depois da pose). Se não houver critério confiável, deixar a flag no perfil mas gerada/validada por ferramenta, e dizer isso.
3. Platypunk: implementar `open_close_nodes` (mesma regra do `<X>_scale`, trocando qual dos nós aparece). Fungi: decidir com o criador (sem dado; recomendar pintar na textura como o Orc ou nada).
4. Qualquer estratégia deve expor a mesma interface (`hold_closed`, `squeeze`, `blink_now`, `lid_k`, `blinks`) para o `BattleFx`, e emitir `eyes`/`eyes_blink`/`eyes_lid` iguais.
5. Cenário e check: estender `tests/battle/check_eyes_combat.py` para rodar todos os modelos do catálogo em `--units=` e afirmar fechar/hit/BLIND por dado; cenário <10 s por modelo.

## Tarefa 3 — Adaptação a modelos novos (ferramenta + documentação)
1. Ferramenta de onboarding: `tests/overworld/diag_eye_strategy.gd` (ou comando da sala) que, dado `res://assets/modelos/<id>/<id>.glb`, imprime a estratégia detectada, o que faltou (superfícies, ossos, malhas, nós), e salva um quadro aberto/fechado com câmera fixa. Rodar em TODOS os modelos de `assets/modelos/` e entregar a tabela.
2. Documento curto `docs/plans/COMO_ADICIONAR_MODELO_COM_OLHOS.md`: convenções de nome que o detector entende (`*_eye`, `Eye_Model_*`, `*_scale`, `OpenEye/CloseEye`, `*mabuta*`), o que o extrator Tact (`C:\Games\Tact`, SÓ LEITURA) já entrega e como conferir (`audit_eyes.py`-like, guardado em `tests/` e não só no scratchpad), e o que fazer quando nada existe.
3. Se faltar dado que existe no bundle mas não no GLB exportado, apontar a correção do extrator sem aplicá-la.

## Pronto quando
Tabela de todos os modelos com estratégia e captura aberto/fechado; suíte rodada com o que é novo separado do que é antigo; D-1295 e `TELEMETRIA.md` atualizados; commit só desta frente; lista honesta do que NÃO foi verificado e dos valores pendentes de aprovação (ritmo do piscar, 0,5 s, rampas, arco/espessura da linha do Orc, limiar de branco).
