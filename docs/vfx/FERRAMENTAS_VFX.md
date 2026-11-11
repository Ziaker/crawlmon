# Ferramentas de VFX — estado e uso

- **Decisão:** D-1020 (requisitos e ordem proposta); D-235 (independente de personagem/lado); D-003/D-022.
- **Estado:** a auditoria de 2026-11-09 deu **1 e 6 com ressalvas** e **reprovou a 4** (`pose_height` não reproduzível). Ferramentas 2, 3 e 5 ainda não iniciadas. **Aprovação do criador pendente**; nada foi declarado aprovado visualmente.
- **Regra:** estas ferramentas só observam e medem. Não alteram dano, alcance, tempo lógico, acerto, ATB, câmera ou qualquer regra do jogo.

## Ferramenta 1 — gravador robusto

Arquivo: `tests/fx_lab/record_move_video.py`.
Alterações de apoio na sala: `scripts/debug/vfx_room.gd` (`--preflight`, `--real-mp`, atacante por lado).

### Uso

```powershell
python tests/fx_lab/record_move_video.py "Electric Beam" test_captures/vfx_tools/electric_beam.mp4
python tests/fx_lab/record_move_video.py "Fire Bullet" test_captures/vfx_tools/fire_bullet.mp4 --clean
python tests/fx_lab/record_move_video.py "Electric Beam" out.mp4 --stun=always --cam=1
python tests/fx_lab/record_move_video.py "Electric Beam" out.mp4 --dqt-mirror
python tests/fx_lab/record_move_video.py "Tidal Surge" out.mp4 --dqt-mirror --attacker=Slime --mirror-attacker=Slime
```

O executável do Godot é procurado como `Godot_v*_console.exe` na raiz; o ffmpeg vem de `FFMPEG`, do PATH ou do fallback existente.

### O que ele faz

1. **Pré-checagem de 1 s** (`--preflight=1.0`): dispara uma vez e lê a linha
   `[vfx_room] preflight result=ok|fail ...`; se falhar, termina em segundos, sem gravar.
2. **Alvo por lado:** `--target=opponent` (padrão) escolhe o primeiro vivo do lado oposto ao atacante; nunca por índice.
3. **Atacante por lado:** `--attacker=player` (padrão) e `--mirror-attacker=enemy` (padrão) escolhem o primeiro vivo do lado; nomes explícitos ainda funcionam.
4. **Recusa visível:** lê `[vfx_room]` e imprime a razão (`(recusado pelo combate)`, atacante=alvo, Move ausente, MP insuficiente). Não chama o ffmpeg se a recusa acontecer.
5. **MP real por padrão:** passa `--real-mp`, então o combate decide com o MP de verdade; `--fill-mp` recupera o comportamento antigo de completar MP na sala.
6. **Folha por fase:** lê `CARGA começa`, `CARGA termina (release)`, `FASE STRIKE`, `FASE TRAVEL`, `IMPACTO`, `FASE RETURN`; monta `*_normal_phases.png`, `*_mirrored_phases.png` e `*_phases.png` (normal em cima, espelhado embaixo). `DONE` é descartado por ser marcador lógico, não fase visual.
7. **Vídeo único:** normal em cima, espelhado embaixo, 30 fps, 1280×720 por vista; o arquivo final tem 1280×1440.
8. **Log e manifesto:** copia o log da sala para `*_normal_log.txt` / `*_mirrored_log.txt` e grava `*_manifest.json` com opções, fases, contagem de quadros e linhas de pré-checagem.
9. **Falha rápida:** a pré-checagem tem timeout de 20 s; a gravação tem timeout generoso (o gargalo é salvar PNGs), mas nunca os 600 s antigos. `--keep-temp` mantém os quadros brutos. **Ressalva:** com DQT, dois Godot pesados em paralelo podem estourar os 20 s da pré-checagem; rodar uma gravação por vez.

### Opções principais

| Opção | Efeito |
|---|---|
| `--seconds` | duração da gravação (padrão 4,5 s) |
| `--attacker` / `--mirror-attacker` | `player`, `enemy` ou nome; padrões por lado |
| `--target` / `--mirror-target` | `opponent` (padrão) ou nome |
| `--hp` / `--force` | vida inicial e resultado forçado (`hit`, `dodge`, `crit`, `weak`, `random`) |
| `--clean` / `--cam=0..4` | sem HUD/props; câmera da sala (0 = do jogo) |
| `--stun=always|never` | força/evita o status do Electric |
| `--dqt` / `--dqt-mirror` | passadas ao `BattleScene`, que as lê de `OS.get_cmdline_user_args()`; não são flags do `vfx_room.gd`. `--dqt` sozinho é **rejeitado** pelo gravador (não forma par espelhado). **`--dqt-mirror` grava o par:** DQT no jogador na vista normal e DQT no inimigo na espelhada (D-1031). O atacante padrão é o primeiro vivo do lado (**Orc**); para o Slime use `--attacker=Slime --mirror-attacker=Slime`. |
| `--fill-mp` | comportamento antigo de completar MP na sala |
| `--scenario` | executa um cenário pronto da sala; **exige `--skip-preflight` explícito** (D-1035); cenário inexistente falha rápido |
| `--skip-preflight` | pula a pré-checagem (não recomendado); obrigatório para `--scenario` |
| `--keep-temp` | mantém os quadros brutos e imprime a pasta |

### Evidência desta entrega

| Caso | Resultado | Arquivos |
|---|---|---|
| Electric Beam, câmera do jogo | 135 quadros, 4,5 s, fases WINDUP/RELEASE/STRIKE/TRAVEL/IMPACT/RETURN; normal `player→enemy`, espelhado `enemy→player` | `test_captures/vfx_tools/electric_beam_robust_gamecam.mp4` e `_phases.png`, `_manifest.json` |
| Fire Bullet, câmera do jogo | 75 quadros, 2,5 s, mesmas fases | `test_captures/vfx_tools/fire_bullet_robust.mp4` e `_phases.png`, `_manifest.json` |
| Recusa (atacante = alvo) | falhou em segundos com `[vfx_room] preflight result=fail ... reason=Atacante e alvo precisam ser diferentes`; nenhum vídeo criado | saída do terminal |
| Move inexistente | falhou em segundos com `[vfx_room] preflight result=fail ... reason=Move não encontrado`; nenhum vídeo criado | saída do terminal |
| Atacante/alvo inexistente | falhou em segundos com `reason=Atacante não encontrado` / `reason=Alvo não encontrado`; nenhum vídeo criado | saída do terminal |
| Duração curta | avisou `IMPACTO não apareceu; --seconds pode ser curto` e ainda gerou a folha | saída do terminal |
| DQT espelhado | `--dqt-mirror` funciona via `BattleScene` e grava o par (DQT no jogador na normal, DQT no inimigo na espelhada). O atacante padrão é **Orc**; o Slime exige `--attacker=Slime`. DqtTestParty dá 20 MP; o caso 0 MP antigo não existe mais na sala | `test_captures/audit/dqtmirror_after2_manifest.json` e `test_captures/audit/dqtboth_manifest.json` (auditoria 2026-11-09) |

### Limites conhecidos

- **Testado na auditoria de 2026-11-09:** `--dqt --dqt-mirror` (normal Orc/player, espelhado Orc/enemy); `--dqt-mirror` sozinho agora grava o par (normal Orc/player, espelhado Orc/enemy); `--scenario` sem `--skip-preflight` falha em ~0,2 s; cenário inexistente com `--skip-preflight` falha sem vídeo em ~28 s. **Não testado:** Slime/Tidal Surge, recusa por MP (DqtTestParty 20 MP; o caso 0 MP não existe na sala), outros Moves da lista aprovada, alvo grande/pequeno, Evade/morte no meio do voo.
- **Custo:** a gravação de 4,5 s leva mais tempo que 4,5 s porque salva 135 PNGs de 1280×720; a pré-checagem é que é rápida.
- **Aprovação:** o vídeo prova a ferramenta, não a arte. Nenhum efeito foi declarado aprovado por esta entrega.
- **Ferramentas 2, 3 e 5:** não iniciadas; a ordem aprovada é 1 → 6 → 4 → 3 → 2 → 5.

## Ferramenta 4 — medição do corpo e dos clipes

Arquivo: `tests/vfx/body_clip_measure.gd`.

### Uso

```powershell
Godot --path . --fixed-fps 30 --script res://tests/vfx/body_clip_measure.gd -- --dqt
Godot --path . --fixed-fps 30 --script res://tests/vfx/body_clip_measure.gd -- --out=test_captures/vfx_tools/body_clip_measure
```

Saída padrão: `test_captures/vfx_tools/body_clip_measure/`, com:
- `measurements.json`: corpo, malhas (com exclusão de arma/ajudantes), candidatos de mão/cabeça, arma e todos os clipes;
- `clips.csv`: uma linha por unidade/clipe com velocidades máximas/médias de mão, cabeça e ponta da arma;
- `summary.txt`: resumo legível no terminal.

### O que mede

- **Corpo:** AABB da malha em mundo, altura, centro, raio horizontal, altura de pose (ossos, sem o osso da arma) e detalhamento por malha (`mesh_rows`, com motivo de exclusão).
- **Ossos:** candidatos genéricos de mão (`hand`, `_te_`, `hte`, `wrist`) e cabeça (`head`, `neck`, `skull`, `kao`, `face`); se não houver nome de cabeça, escolhe o osso mais alto **e marca `head_source=fallback_highest`**.
- **Arma:** usa `SwingTrail.weapon_of`; reporta malha, osso, comprimento, espessura e `thin`.
- **Clipes:** comprimento, loop, velocidade máxima/média e deslocamento total de mão, cabeça e ponta da arma, amostrados em 24 pontos; `run_stride` quando o perfil DQT fornece.
- **Sem personagem:** os nomes aparecem só para leitura; a medição vem do modelo real do `Battle`, não de “modelo mais próximo”.
- **Escala real:** `model_scale` é a escala do nó no `Battle` (pode incluir multiplicadores de cena); o `profile.target_height` é só a referência do perfil DQT. O JSON mostra os dois, sem assumir que são iguais.

### Evidência desta entrega

Execução com `--dqt` (DQT trio + um inimigo aleatório):

| Unidade | Corpo (malha) | Pose (ossos) | Raio | Mão | Cabeça | Arma |
|---|---|---|---|---|---|---|
| Orc | 3,17 m | 2,17 m* | 2,29 m | `j_te_l` | `j_kao` | `n_buki_r_n_hara`, 2,66 m |
| Slime | 3,52 m | 2,46 m | 2,06 m | — | `j_sebo_c` (fallback) | — |
| Cyclops | 2,76 m | 3,52 m | 2,07 m | `n_hte_r` | `j_kao` | `n_buki_l_n_hara`, 1,92 m |

O `clips.csv` mostra, por exemplo, a ponta da arma do Orc a **48,06 m/s** no clipe `attack` e a mão a **12,04 m/s**; os valores exatos estão no CSV.

\* **Ressalva da auditoria (2026-11-09):** `pose_height` não é estável. O valor 2,17 m do Orc é uma fotografia de uma execução; repetições deram 3,422 m e 2,195/2,282 m para o mesmo modelo, porque a ferramenta lê a pose viva do esqueleto. A ferramenta 4 está **reprovada** até a leitura oficial ser definida. **D-1041:** não trocar para pose canônica; a pose canônica dos DQT é muito maior que a dos Pokémon. **D-1047/D-1054 (estado atual):** as mudanças globais de D-1043/D-1046 foram revertidas. Ficaram **Cyclops 4,00 m** (D-1054) e **Slime 1,43 m** nos perfis DQT; Orc 3,19 m e Gible 2,89 m voltaram à escala anterior. Os valores 3,17/3,52/2,76 acima são o **antes** da primeira correção; o estado atual está em `test_captures/audit/body_revert/measurements.json`.

Sem `--dqt`, o time padrão também foi medido: **Abra** (`left_hand`, `head`) e **Pancham** (`left_hand`, `..._head_mesh_2`), mais os inimigos aleatórios daquela execução (Gible, Cyclops, Slime **ou Pancham**, conforme o encontro), todos sem arma. Saída em `test_captures/vfx_tools/body_clip_measure_standard/`.

### Limites

- `mesh_height` é o AABB da malha (pode incluir braços/cabeça); `pose_height` é a altura dos ossos na **pose viva** e não é reproduzível. Até a escala/leitura oficial ser definida (D-1041), trate `pose_height` como diagnóstico, não como altura do corpo. Não trocar para pose canônica: a dos DQT é muito maior que a dos Pokémon.
- O AABB de malha com skin pode ser conservador; use `mesh_rows` para ver qual malha puxou.
- Clipes DQT aparecem com nome original e alias; isso é intencional para rastrear o alias usado pelo jogo.
- Não mede vértices deformados um a um, nem GPU. Não substitui a conferência visual.

## Ferramenta 6 — captura de referência

Arquivo: `tests/fx_lab/reference_capture.py`.

### Uso

```powershell
python tests/fx_lab/reference_capture.py `
  --source "https://www.youtube.com/watch?v=..." `
  --element Fire --effect "Fire Bullet" `
  --at "WINDUP=0.5" --at "IMPACT=1.2" `
  --max-height 720

python tests/fx_lab/reference_capture.py --source local.mp4 --element Mystic `
  --effect "Aurelion Sol Black Hole" --at "WINDUP=2.0" --at "IMPACT=5.0"
```

Saída padrão: `docs/vfx/referencias/capturas/<elemento>/<efeito>/`, com:
- `frames/<fase>_<tempo>.png` (quadros em tamanho real/cortado);
- `contact_sheet.png` (fases rotuladas);
- `manifest.json` (fonte, título, duração, trecho, elemento, efeito, tempos, hash de cada quadro; `source_resolution`, `output_resolution` e `resolution` como alias da saída).

A pasta `docs/vfx/referencias/capturas/` tem `.gdignore` para o Godot não importar as imagens de referência como assets do jogo.

### O que faz

- Aceita **vídeo local** ou **URL pública**; para URL baixa só o trecho em volta dos timestamps com `yt-dlp` e apaga o clipe no fim (salvo `--keep-clip`).
- Extrai em tempos exatos com `ffmpeg` (seek preciso), valida os timestamps contra a duração e avisa/erra se algo estiver fora.
- Opções `--crop x,y,w,h`, `--max-height`, `--title`, `--out`.
- Manifesto registra o **pré-roll** do download quando existe e o tempo local usado. **Corrigido em D-1049:** com `clip_start=0` não há pré-roll; o excedente é cauda e `local_time` fica exato. Para `clip_start>0`, a estimativa de pré-roll continua com precisão de ~1 quadro.
- Não guarda vídeos por padrão; só quadros + metadados, como aprovado.

### Evidência desta entrega

| Caso | Resultado | Arquivos |
|---|---|---|
| Vídeo local (`scratch/vfx_research/clips/lol_asol.mp4`) | 2 fases extraídas, folha e manifesto | `test_captures/vfx_tools/reference_capture_local/` |
| URL pública (P5R critical) | 2 fases, título/uploader/duração e pré-roll de 0,003 s no manifesto | `test_captures/vfx_tools/reference_capture_url/` |
| Caminho padrão | organização por elemento/efeito/fase | `docs/vfx/referencias/capturas/psychic/p5r_critical/` |

### Limites

- Depende de `yt-dlp` e rede para URL; local não depende de rede. Erros de login/região/URL são genéricos; não há tratamento específico.
- O pré-roll do download é registrado; para `clip_start>0` a precisão continua de ~1 quadro. Com `clip_start=0`, D-1049 garante `clip_preroll=0`.
- `--crop`/`--max-height` mudam o tamanho do quadro; o manifesto agora traz `output_resolution` real e mantém `source_resolution`.
- A saída em `test_captures/` é ignorada pelo Git, mas o Godot ainda importa os PNG/CSV dessa pasta; falta um `.gdignore` em `test_captures/`.
- Não substitui a conferência humana da referência; só garante o quadro no tempo pedido.

## Suíte de Análise Visual e Debug de Combate em Tempo Real (D-1042 / D-1044)

> **Leitura obrigatória (D-1154):** antes de usar o trace ou a sala de debug em combate, leia `docs/TELEMETRIA.md`. Ele lista os eventos, os campos de `queue` (`started` vs. `lost`), a linha por quadro e como apresentar a evidência.

Integrada diretamente à sala de combate e debug (`scenes/debug/vfx_room.tscn`, `scripts/debug/vfx_room.gd`, `scripts/combat/battle_debug.gd` e `scripts/combat/battle_trace.gd`) e ao runner `tests/battle/run_agent_combat_tests.py`:

| Flag / Atalho | O que faz |
|---|---|
| `--scenario=dano_direto\|dano_critico\|dano_weak\|dano_armor\|dano_stun\|dano_guard\|dano_ko` | Dispara cenários de dano e reação visual completa (animação `damage`, flash, texto flutuante, hit-stop, recuo e lançamento balístico de K.O.). No `BattleDebug`: `F9` (dano com reação) e `F10` (K.O. com lançamento). |
| `--phase=windup\|release\|travel\|strike\|impact\|return` / `--isolate-phase=<fase>` | Pausa na fase pedida e imprime/exibe a **Ficha Visual da Fase** (`Skill.visual_phases()`) do Move selecionado (`[vfx_room] FICHA_FASE [<fase>]: ...`). |
| `--summary-json` / `--stdout-trace` / `--strict-asserts` | Emite JSON estruturado no `stdout` com resumo completo (dano, HP antes/depois, fases atingidas, nós de VFX, fila `queue_events`/`queue_lost`, anomalias) e falha imediata (`exit 1`) se qualquer invariante for violada. |
| `--scenario=fila_status_pausa\|fila_status_click\|fila_war_cry` | Cenários da fila D-161 com pausa de status (D-1150): a vaga sobrevive à pausa real, a escolha feita durante a pausa começa depois, e o War Cry interrompe/limpa a vaga (esperado D-064). O `--summary-json` traz `queue_events` com `started`/`lost`, `queue_started` e `queue_lost`. |
| `--trace` / `--stdout-trace` | O `BattleTrace` agora registra eventos `queue`, `status_pause_started/ended`, `interrupted_windup`, dano/cura, Evade, Guard/ARMOR/escudo, STUN/Blind/Burn, buffs, MP/ATB/Burst, recompensas, XP/level e, em cada quadro, `q`/`qt`/`sp`/`sp_by`, HP/MP, status e buffs: dá para ver **quando** a vaga nasceu, mudou, começou ou foi limpa, e qual pausa estava ativa (D-1154). |
| `--acts-ticks=<tick:acao:papel:...>` / `--step-ticks=N` | Agendamento e avanço determinístico por quadros físicos exatos (60 Hz) sem depender de `float` de segundos. |
| `--audit-leaks` | **Auditor de Restos e Órfãos:** verifica `BattleFx` após o término do ataque (`RETURN`) e reporta nós residuais, partículas acesas ou `OmniLight3D` órfãs (`[vfx_audit] leaks=0`). |
| `--scale-overlay` | **Reticulado de Medição e Régua de Tela:** desenha círculos concêntricos em pixels (`50px`, `100px`, `200px`) no ponto de contato 2D e réguas métricas 3D (`0.5m`, `1.0m`, `1.2m` D-1013, `2.0m`, `2.5m` D-1033). |
| `--proof-sheet=<caminho.png>` | **Folha de Prova 2×4 D-308:** roda o Move nas vistas Normal e Espelhada, captura automaticamente *Wind-up*, *Release*, *Trajeto* e *Impacto* e gera uma prancha `2×4` anotada com tempo e contagem de nós. |
| `--bone-probe` | **Inspetor de Ancoragem e Velocidade de Osso:** rastreia ossos de mão/cabeça/ponta da arma em 3D, desenha o vetor velocidade e loga o pico de velocidade do swing vs. instante do golpe. |
| `--solo-node=<padrão>` / `--mute-node=<padrão>` | **Solo / Mute por Componente Individual:** isola ou oculta nós específicos gerados sob `BattleFx`. |
| `--cam=macro` (ou `--cam=5`) | **Impact Macro Cam:** câmera teleobjetiva (`FOV 15°`) focada no ponto de contato (`target.pos + Vector3(0, 1.2, 0)`), reduzindo a velocidade a `0.05x` no impacto. |
| `--overdraw` | **Visualizador de Overdraw:** aplica shader de densidade térmica aditiva às geometrias transparentes de VFX para expor acúmulo excessivo e estouro de branco. |
| `--bg=arena\|gray\|black\|white` | **Teste de Silhueta e Contraste:** troca o fundo entre a arena real, cinza neutro 50%, preto puro e branco puro. |
| `--envelope-graph` | **Curva de Envelope de Opacidade:** plota a evolução de `alpha` e escala em tempo real e acusa `[POP_DETECTED]` se uma camada sumir com corte seco (`delta_alpha > 0.5` em 1 quadro). |
| `--diff-with=<referencia.png>` | **Comparador Visual A/B:** compara a captura `--shot` com uma imagem de referência, salva `*_diff.png` em magenta e reporta `RMSE` e `%` de pixels alterados. |

## Próximas ferramentas (não implementadas)

1. Desenho estático de caminho (ferramenta 3).
2. Verificador de aprovados (ferramenta 2).
3. Custo (ferramenta 5; extensão do `agent_profile.gd`).

Cada uma será entregue isoladamente, com prova de funcionamento, antes da próxima.
