# Ferramentas de VFX — estado e uso

- **Decisão:** D-1020 (requisitos e ordem proposta); D-235 (independente de personagem/lado); D-003/D-022.
- **Estado:** **ferramentas 1, 4 e 6 implementadas e testadas**; ferramentas 2, 3 e 5 ainda não iniciadas. Nada foi declarado aprovado visualmente.
- **Regra:** estas ferramentas só observam e medem. Não alteram dano, alcance, tempo lógico, acerto, ATB, câmera ou qualquer regra do jogo.

## Ferramenta 1 — gravador robusto

Arquivo: `tests/fx_lab/record_move_video.py`.
Alterações de apoio na sala: `scripts/debug/vfx_room.gd` (`--preflight`, `--real-mp`, atacante por lado).

### Uso

```powershell
python tests/fx_lab/record_move_video.py "Electric Beam" test_captures/vfx_tools/electric_beam.mp4
python tests/fx_lab/record_move_video.py "Fire Bullet" test_captures/vfx_tools/fire_bullet.mp4 --clean
python tests/fx_lab/record_move_video.py "Electric Beam" out.mp4 --stun=always --cam=1
python tests/fx_lab/record_move_video.py "Electric Beam" out.mp4 --dqt-mirror --attacker=enemy
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
9. **Falha rápida:** a pré-checagem tem timeout de 20 s; a gravação tem timeout generoso (o gargalo é salvar PNGs), mas nunca os 600 s antigos. `--keep-temp` mantém os quadros brutos.

### Opções principais

| Opção | Efeito |
|---|---|
| `--seconds` | duração da gravação (padrão 4,5 s) |
| `--attacker` / `--mirror-attacker` | `player`, `enemy` ou nome; padrões por lado |
| `--target` / `--mirror-target` | `opponent` (padrão) ou nome |
| `--hp` / `--force` | vida inicial e resultado forçado (`hit`, `dodge`, `crit`, `weak`, `random`) |
| `--clean` / `--cam=0..4` | sem HUD/props; câmera da sala (0 = do jogo) |
| `--stun=always|never` | força/evita o status do Electric |
| `--dqt` / `--dqt-mirror` | passadas ao `BattleScene`, que as lê de `OS.get_cmdline_user_args()`; não são flags do `vfx_room.gd`. `--dqt` sozinho é **rejeitado** pelo gravador (não forma par espelhado); use `--dqt-mirror` |
| `--fill-mp` | comportamento antigo de completar MP na sala |
| `--skip-preflight` | pula a pré-checagem (não recomendado) |
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
| DQT espelhado | `--dqt-mirror` funciona via `BattleScene`; Slime entrou como enemy com 20 MP (DqtTestParty), então o caso 0 MP antigo não existe mais na sala | saída do terminal (2026-11-09) |

### Limites conhecidos

- **Não testado:** `--dqt` normal + espelhado juntos (o `--dqt` sozinho é rejeitado; `--dqt-mirror` foi exercitado), recusa por MP (o DqtTestParty agora dá 20 MP; o caso 0 MP não existe na sala), outros Moves da lista aprovada, alvo grande/pequeno, Evade/morte no meio do voo.
- **Custo:** a gravação de 4,5 s leva mais tempo que 4,5 s porque salva 135 PNGs de 1280×720; a pré-checagem é que é rápida.
- **Aprovação:** o vídeo prova a ferramenta, não a arte. Nenhum efeito foi declarado aprovado por esta entrega.
- **Ferramentas 2–6:** não iniciadas; a ordem aprovada é 1 → 6 → 4 → 3 → 2 → 5.

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
| Orc | 3,17 m | 2,17 m | 2,29 m | `j_te_l` | `j_kao` | `n_buki_r_n_hara`, 2,66 m |
| Slime | 3,52 m | 2,46 m | 2,06 m | — | `j_sebo_c` (fallback) | — |
| Cyclops | 2,76 m | 3,52 m | 2,07 m | `n_hte_r` | `j_kao` | `n_buki_l_n_hara`, 1,92 m |

O `clips.csv` mostra, por exemplo, a ponta da arma do Orc a **48,06 m/s** no clipe `attack` e a mão a **12,04 m/s**; os valores exatos estão no CSV.

Sem `--dqt`, o time padrão também foi medido: **Abra** (`left_hand`, `head`) e **Pancham** (`left_hand`, `..._head_mesh_2`), mais os inimigos aleatórios daquela execução (Gible, Cyclops ou Slime, conforme o encontro), todos sem arma. Saída em `test_captures/vfx_tools/body_clip_measure_standard/`.

### Limites

- `mesh_height` é o AABB da malha (pode incluir braços/cabeça); `pose_height` é a altura dos ossos e é a leitura principal de “posado”.
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
- `manifest.json` (fonte, título, duração, trecho, elemento, efeito, tempos, hash de cada quadro).

A pasta `docs/vfx/referencias/capturas/` tem `.gdignore` para o Godot não importar as imagens de referência como assets do jogo.

### O que faz

- Aceita **vídeo local** ou **URL pública**; para URL baixa só o trecho em volta dos timestamps com `yt-dlp` e apaga o clipe no fim (salvo `--keep-clip`).
- Extrai em tempos exatos com `ffmpeg` (seek preciso), valida os timestamps contra a duração e avisa/erra se algo estiver fora.
- Opções `--crop x,y,w,h`, `--max-height`, `--title`, `--out`.
- Manifesto registra o **pré-roll** do download quando existe (ex.: 0,003 s) e o tempo local usado.
- Não guarda vídeos por padrão; só quadros + metadados, como aprovado.

### Evidência desta entrega

| Caso | Resultado | Arquivos |
|---|---|---|
| Vídeo local (`scratch/vfx_research/clips/lol_asol.mp4`) | 2 fases extraídas, folha e manifesto | `test_captures/vfx_tools/reference_capture_local/` |
| URL pública (P5R critical) | 2 fases, título/uploader/duração e pré-roll de 0,003 s no manifesto | `test_captures/vfx_tools/reference_capture_url/` |
| Caminho padrão | organização por elemento/efeito/fase | `docs/vfx/referencias/capturas/psychic/p5r_critical/` |

### Limites

- Depende de `yt-dlp` e rede para URL; local não depende de rede.
- O pré-roll do download é registrado, mas a precisão é de ~1 quadro.
- Não substitui a conferência humana da referência; só garante o quadro no tempo pedido.

## Próximas ferramentas (não implementadas)

1. Desenho estático de caminho (ferramenta 3).
2. Verificador de aprovados (ferramenta 2).
3. Custo (ferramenta 5; extensão do `agent_profile.gd`).

Cada uma será entregue isoladamente, com prova de funcionamento, antes da próxima.
