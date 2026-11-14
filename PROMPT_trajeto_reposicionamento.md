<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# Prompt de implementação — Trajeto de ataque + Reposicionamento (Crawlmon)

Você trabalha no projeto Godot 4.7 **Crawlmon** (`C:\Users\zerke\OneDrive\Área de Trabalho\Z\crawlmon`, repositório público Ziaker/crawlmon). Implemente a especificação abaixo no combate 3D, **em fases, nesta ordem**, verificando cada uma antes da próxima. Isto é uma ordem de execução: não proponha outro plano nem reescreva o que não for pedido.

## Regra de ouro (inegociável)
**Lógica e visual andam numa só linha do tempo, perfeitamente sincronizadas.** A lógica (`scripts/combat/battle.gd`) é a única dona do estado e do relógio de cada ataque; o visual (`scripts/combat/battle_fx.gd` e `scripts/combat/fx/*.gd`) apenas **desenha** esse estado. Proibido o visual ter temporizadores ou tweens próprios que decidam *quando* algo acontece (acerto, chegada, interrupção, retorno). Pausa (`get_tree().paused`), câmera lenta (`Engine.time_scale`), interrupção e cancelamento valem igualmente para os dois porque só existe um relógio. Hoje isso é violado (o acerto sai de um temporizador de lógica enquanto o corpo corre por um tween separado) e é a causa da maioria dos bugs.

## Leia antes de editar
`README.md`, `docs/GDD.md` (versão atual; o GDD é soberano nas regras, mas o código define o que existe), `scripts/combat/battle.gd`, `combatant.gd`, `battle_scene.gd`, `battle_fx.gd`, `fx/fx_motion.gd`, `fx/fx_telegraph.gd`, `fx/fx_dodge.gd`, `fx/fx_projectiles.gd`, `battle_hud.gd`. Confira branch/HEAD e `git status`: **outras sessões editam estes mesmos arquivos** e há alterações não commitadas que não são suas. Não reverta nem commite o que não for seu; commite só os seus arquivos/trechos. Não envie (push) nada sem autorização expressa.

## Estado atual relevante (confira no código)
- Ataque: `Battle.use_skill` cria um `Incoming` com `time_left = WINDUP` (1,5 s); ao zerar, emite `attack_resolved`; o FX define `impact_delay` e o golpe só conta (`_step_landing`) quando `impact_left` zera.
- Evade: `try_evade` custa `EVADE_BLOCKS` (3), janela `NORMAL_WINDOW` 0,48 s antes do impacto, `PERFECT_WINDOW` 0,22 s; antes disso é whiff (`evade_whiffed`). Existe `Combatant.counter_ready` e `Incoming.instant` (contra-ataque sem preparação após Evade perfeito).
- A corrida física é `clamp(distância / RUN_SPEED, 0.35, 0.8)` no FX; a lógica não conhece posição nem progresso do trajeto.
- IA: `_run_ai` desvia assim que `eta() <= NORMAL_WINDOW`.
- Câmera lenta de 2 s após Evade manual do líder (`SLOWMO_SECONDS`, em `battle_scene.gd`).

## FASE 1 — Linha do tempo única (refatoração, sem mudar comportamento)
1. Mova para o `Battle` o estado de fase de cada ataque: **PREPARO → TRAJETO → GOLPE → RETORNO**, com duração em segundos de lógica e `progresso` 0..1 em cada fase. O trajeto de um golpe físico tem duração própria na lógica (hoje `run_t` do FX); o de golpes à distância é o voo do projétil.
2. O FX passa a **ler** o progresso (`inc.phase`, `inc.progress`) e posicionar o personagem por interpolação do progresso (corrida, golpe, pulo de volta), em vez de tweens com duração própria. Efeitos pontuais (poeira, anel) disparam por sinais de fase do `Battle`.
3. Todo o resto continua idêntico (mesmos tempos, mesmos resultados). Critério: capturas/trace antes e depois mostram o mesmo comportamento; acerto, HP e visual coincidem no mesmo quadro; pausar e câmera lenta congelam/escalam o corpo junto com a lógica.

## FASE 2 — Trajeto: Evade no caminho e contra-ataque engajado
- **Evade manual (Espaço) só funciona durante o TRAJETO** do ataque que mira o personagem (a corrida ou o voo do projétil). Custa **2 ATB** (não 3). Apertar durante o PREPARO continua sendo whiff (esquiva cedo demais; perde os 2 ATB e fica vulnerável a crítico, como hoje). Só o Evade **manual** conta; esquiva automática não dispara nada disto.
- **Golpes à distância** são teleguiados (sem trajeto no chão) e também podem ser desviados durante o voo do projétil, com a mesma regra.
- **Evade bem-sucedido:** (a) o atacante é **interrompido** onde está (cambaleia no ponto atual; o ataque dele é cancelado, não termina a corrida nem erra o vazio); (b) o personagem que desviou ganha +1 Burst e **chega imediatamente** ao atacante interrompido, sem percorrer trajeto; (c) o primeiro golpe seguinte não tem preparo (`Incoming.instant`) e é **golpe de graça**: o Burst paga a ação inteira (comportamento atual de `can_pay`/`pay`; o GDD R2-Q3 diz outra coisa, **mantenha o atual e registre a divergência no relatório**).
- **Estado engajado:** após chegar, o personagem fica junto do oponente enquanto durar a **câmera lenta do Burst** (hoje 2 s reais). Se realizar uma ação nesse tempo (golpe, item), continua engajado, sem voltar e sem percorrer trajeto; ações seguintes via Burst também são imediatas. Se **não agir** até a câmera lenta acabar, **volta ao ponto original com o pulo rápido**. Também volta se o oponente morrer.
- **Vários atacantes:** os ataques que **já partiram** miram o ponto onde o alvo estava quando partiram; se o alvo saiu dali (engajado), esses golpes **erram o vazio** (sem dano), e o atacante faz o retorno normal. Só um novo ataque pode alcançá-lo.
- **Simetria:** tudo vale para inimigos e aliados. A IA reage dentro do trajeto com chance igual à velocidade (SPD) do personagem, em vez de sempre desviar no primeiro quadro; o contra-ataque da IA segue as mesmas regras.

## FASE 3 — Reposicionamento (passos)
- **Estado por personagem:** `posicao` inteira de **−2 a +2** (0 = meio; positivo = à frente). Um passo por comando; pode alternar livremente dentro do intervalo (ficar no meio, ir 1 ou 2 atrás, voltar 1 à frente etc.). Vale para jogador, aliados e inimigos; a IA usa os passos conforme a Tactic.
- **Custo:** **1 ATB** por passo, sem nenhum outro efeito. Fica dentro do botão **Tactics** (que pausa o jogo): adicione ali a escolha do passo para frente/trás (setas esquerda/direita) e mostre cinco marcas de posição sob o cartão de cada personagem no HUD.
- **Trajeto de cada par:** o tempo do trajeto de um ataque de A em T = `base − 0,10 s × (posição de A + posição de T)`, com mínimo de **0,25 s**. Dar passo à frente encurta os trajetos em que você participa; dar passo atrás os alonga. A posição visual de cada personagem deve acompanhar a lógica (deslocamento fixo por passo, p.ex. 3 unidades no eixo do confronto), sem que o FX decida por conta própria.
- **Dano:** +10% no dano que você **causa** por passo à frente; −10% no dano que você **recebe** por passo atrás (por passo, até 2). Combine multiplicativamente com fraqueza/crítico já existentes.
- **Bloqueios:** não é possível dar passo enquanto prepara/executa o próprio ataque, enquanto há ataque em curso que o envolva (como atacante ou alvo) ou enquanto engajado.

## Regras do projeto
- Não invente mecânicas, números ou textos além do especificado; o que for ambíguo, registre e pergunte no relatório em vez de decidir sozinho.
- Preserve o que existe: ATB, itens, Tactics, Burst, esquiva automática, crítico, fraquezas, câmera (Cinema/Tática/Impacto), HUD, efeitos e pausa do Status/Tactics. Não reintroduza movimento ocioso dos personagens (foi removido a pedido) nem tremor/zoom de câmera.
- Textos 3D de esquiva e de ATB foram removidos a pedido; o `miss_text` fica. Não os recoloque.
- `assets/modelos/` está no `.gitignore` e não pode ir ao Git. Não commite `personagens/`, `docs/` nem `tools/`.
- Mensagens de commit terminam com: `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>`.

## Verificação obrigatória em cada fase
Rode o jogo de verdade (não só `--headless`): `./Godot_v4.7.2-stable_win64_console.exe --path . res://scenes/battle.tscn --resolution 1280x720`, com um script de teste em cena temporária (apague depois) que dirija a batalha por `Input.parse_input_event` e grave capturas (`get_viewport().get_texture().get_image().save_png`) e traces de posição/fase por tempo. Prove, com números e capturas: (1) lógica e visual coincidem no mesmo quadro (acerto, interrupção, chegada, retorno); (2) o Evade no trajeto interrompe o atacante e o contra-ataque é imediato; (3) engajado sem agir volta com o pulo; (4) ataques já partidos erram o vazio; (5) os passos alteram trajeto e dano nas proporções acima e respeitam os limites e bloqueios. Valide sem erros de script no console. Se algo não puder ser validado, diga exatamente o quê.

## Entrega
Relatório curto: o que mudou em cada fase (arquivos), como lógica e visual ficaram sincronizados, evidências (traces/capturas), divergências com o GDD (custo do Burst; Evade a 2 ATB; passos e trajeto não existem no GDD), pontos ambíguos que precisam de decisão, e o que ficou inalterado. Não alegue conclusão de uma fase sem a verificação acima.
