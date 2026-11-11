# Plano — Ataque no overworld e 3 transições de encontro

- **Data:** 2026-11-10
- **Status:** **implementado no lab 3D e testado**; vídeos gravados; pendente só a aprovação visual dos valores (D-1106).
- **Decisões aplicáveis:** D-003 (só fazer o pedido), D-022 (sem push), D-235 (independente de personagem/time/lado), D-1022/D-1023 (overworld 3D/lab), D-1042/D-1044 (suíte de debug), **D-1100** (ataque e transições) e **D-1101** (vantagem de ATB). **D-308 não se aplica** (decisão do criador).
- **Alvo confirmado:** o **lab 3D** (`scenes/debug/murky_forest_3d_lab.tscn`, herdando `scripts/debug/third_person_3d_lab.gd`). O `main_scene` continua sendo o overworld 2D (`scenes/exploration.tscn`) e não será tocado nesta etapa.

## 1. Objetivo

No lab 3D:

1. Um **botão de ataque** faz o personagem dar um **avanço curto** na direção de um inimigo próximo.
2. O contato gera a **transição de combate** com **três variantes**:
   - **branco**: contato normal;
   - **azul**: o jogador ataca primeiro e acerta;
   - **vermelho**: o inimigo ataca primeiro e acerta.
3. O inimigo também pode iniciar um **avanço rápido** contra o jogador.
4. Durante os avanços: **speedlines** no jogador e no oponente, **rastro no chão** e **dust de corrida com opacidade reduzida**.
5. Quem acerta primeiro ganha **+1 ATB**; o outro lado perde **1 ATB** (base 3 → **4 vs 2**).

## 2. Decisões confirmadas (D-1100/D-1101)

| Tema | Decisão |
|---|---|
| Alvo | Lab 3D primeiro; 2D e main scene intocados |
| Contato normal | Transição **branca** |
| Jogador ataca primeiro e acerta | Transição **azul** |
| Inimigo ataca primeiro e acerta | Transição **vermelha** |
| Empate dos dois avanços no mesmo instante | **Contato normal (branco)** |
| Input | **Z** ataca; **E/Z** interagem/falam; com inimigo, o prompt é `[Z] ATTACK` e E não ataca; inimigo tem prioridade (D-1127) |
| Vantagem | Quem acerta primeiro +1 ATB; o outro −1 (base 3 → 4 vs 2) |
| Escopo da vantagem | Todos os combatentes do lado |
| Erro do ataque | Sem batalha; só a animação |
| Ataque do inimigo | Ao entrar em CHASE; telegraph 0,4 s; cooldown 4 s |
| Dois avanços, um acerto | Quem acertou leva; os dois acertando = branco |
| Contato normal/empate | Sem ajuste de ATB: 3 vs 3 |
| Alvo do ataque | Inimigo mais próximo em raio de 4,5 m, qualquer direção |
| Dano no overworld | Nenhum; só inicia o encontro |
| Dust | Alpha reduzido só no avanço |
| Speedlines | Linhas 3D no espaço do mundo |
| Retorno | Mesma posição e direção do lab 3D |
| D-308 | Não se aplica; efeito de overworld |
| Prompt | `[Z] ATTACK` quando há inimigo no raio |

## 3. Estado atual relevante

- `scenes/exploration.tscn` é o overworld 2D principal (`Node2D`, `DungeonEnemy`, contato por distância).
- O lab 3D usa `CharacterBody3D`, `NavigationAgent3D`, câmera terceira pessoa, Slime com estados `PATROL/CHASE/SEARCH/RETURN/FLEE`, dust de passo e `lab_interact` (E/Z) para NPCs, porta e diálogo.
- `EncounterTransition` (`scripts/ui/transition.gd`) tem uma única aparência (painéis escuros + coral/lima) e `GameState.start_battle(id, pos: Vector2)` assume o overworld 2D.
- `Battle.start()` (`scripts/combat/battle.gd`) aplica `START_ATB := 3.0` a `party + enemies`; é chamado por `battle_scene.gd` na linha 181.
- `GameState.end_battle()` sempre volta para `EXPLORATION` (`scenes/exploration.tscn`), sem cena/posição 3D.
- O lab 3D não inicia batalha hoje; o Slime só persegue (e foge no protótipo Medroso, D-1086).

## 4. Regras de gameplay

### 4.1 Ataque do jogador

- Ação: **Z** ataca; **E/Z** interagem/falam. Perto de inimigo, o ataque é Z; E não ataca (D-1127). Perto de NPC, E/Z conversa. Se os dois estiverem no alcance, o **inimigo** mantém o prompt/alvo do ataque.
- O avanço é curto, na direção do inimigo próximo, com `CharacterBody3D.move_and_slide` (sem teleporte).
- O ataque só inicia a batalha se **acertar**. Se **errar**, não inicia batalha; toca só a animação.
- Alvo: inimigo mais próximo em um **raio de 4,5 m**, em qualquer direção; o personagem vira para ele.
- Distância/tempo do avanço e cooldown do jogador: **valores de protótipo a calibrar com o criador**; não são regra canônica.
- Dano/status: **nenhum**; o ataque só inicia o encontro.
- Prompt: `[Z] ATTACK` quando há inimigo no raio de 4,5 m.

### 4.2 Ataque do inimigo

- O inimigo pode dar um avanço rápido contra o jogador, com `move_and_slide`/navmesh, sem atravessar parede.
- Ele inicia o avanço ao **entrar em `CHASE`**, com **telegraph de 0,4 s** e **cooldown de 4 s**. Em `FLEE` não ataca.
- Se acertar primeiro, a transição é **vermelha** e **todos os inimigos** ganham +1 ATB.

### 4.3 Resolução das três variantes

| Evento | Variante | Cor |
|---|---|---|
| Contato comum andando | normal | branco |
| Jogador ataca e acerta; inimigo não acerta | jogador primeiro | azul |
| Inimigo ataca e acerta; jogador não acerta | inimigo primeiro | vermelho |
| Os dois avanços se encontram no mesmo instante | normal | branco |
| Jogador ataca sem alvo/erra | sem batalha | — |
| Os dois atacam e só um acerta | quem acertou | azul ou vermelho |

Se os dois acertam no mesmo instante, a transição é **branca** (empate).

### 4.4 Aplicação da vantagem no ATB (D-1101)

- Base do código: `START_ATB = 3.0` em `battle.gd`, aplicado a todos em `Battle.start()`.
- Vencedor: **4** blocos; perdedor: **2**; contato normal/empate: **3 vs 3**.
- Ponto de aplicação: depois de `battle.start(party, enemies)` em `battle_scene.gd:181`, lendo `GameState.encounter_advantage`.
- Vale para **todos os combatentes do lado**: party inteira +1 / todos os inimigos −1 (ou o contrário).
- Ataque que **erra**: sem batalha e sem vantagem.
- A regra usa o **ATB normal** (0..5), não o campo `extra`.

## 5. Transição visual

- `EncounterTransition` ganha uma variante (`NORMAL`, `PLAYER_FIRST`, `ENEMY_FIRST`).
- Cores: branco, azul e vermelho; aplicar no brilho dos painéis, no selo e no flash de revelação.
- Texto do selo: `ENCONTRO` + subtítulo `CONTATO`, `VANTAGEM` ou `EMBOSCADA`.
- Duração e troca de cena atuais mantidas (1,5 s; swap em 0,46; reveal em 0,60) até decisão em contrário.
- `GameState` guarda `encounter_advantage` e a cena/posição de retorno; `BattleScene` lê a variante.
- O caminho 2D atual (`start_battle(id, Vector2)`) continua funcionando sem variante.

## 6. VFX (propostas, não aprovadas)

### 6.1 Speedlines
- **Linhas 3D no corpo** (decisão do criador), ancoradas no ator real, não em overlay de tela.
- Linhas radiais/tangenciais curtas, com fade curto; aparência fina (quantidade, cor e tamanho) a definir com capturas na Fase 3.
- Aparecem no jogador e no inimigo durante o avanço; a cor acompanha a variante (branco/azul/vermelho) ou o time.
- D-235: nada depende de nome, `is_player` ou lado; tudo vem da posição real do ator e da câmera.

### 6.2 Rastro no chão
- Fita/ribbon no plano do chão (`y ≈ 0,04`), seguindo o caminho do avanço.
- Um rastro por atacante; some ao fim da transição.
- Largura, comprimento e tempo de fade: a definir com capturas na Fase 3.

### 6.3 Dust
- Reutilizar o `FootDust` existente do lab, mas com **alpha reduzido** durante o avanço.
- Burst de arranque no ponto de partida e de chegada; sem poeira infinita.
- **Só no avanço**; a corrida normal continua como está. O alpha exato fica para a iteração visual da Fase 3.

### 6.4 Verificação
- Capturas em `--fixed-fps 60`, quadros em 0,03 / 0,1 / 0,2 / 0,4 / 0,7 s.
- Vista normal e espelhada (jogador atacando e inimigo atacando), alvos de tamanhos diferentes.
- Procurar o que **não** deveria existir: speedline parada, rastro no ar, dust preso, linha atravessando parede.
- **D-308 não se aplica** (decisão do criador): é efeito de overworld. A verificação usa os frames/vídeo da skill de VFX, sem o protocolo de Move.

## 7. Mundo 3D e retorno

- O avanço usa `CharacterBody3D` + `move_and_slide`; respeita paredes e chão.
- O inimigo usa navmesh/`NavigationAgent3D` para se aproximar; o avanço final é uma linha reta curta com checagem de parede.
- Câmera atual mantida; sem corte brusco na transição.
- Rastro no chão e dust são ancorados no chão real (`raycast`), não na altura do corpo.
- O retorno da batalha precisa saber se veio do lab 3D: `return_scene` + posição 3D no `GameState`. Sem isso, `end_battle()` volta para o 2D.
- **Confirmado:** voltar para a **mesma posição e direção** do lab 3D; guardar `return_scene`, `return_pos_3d` e `return_yaw` no `GameState`.

## 8. Contrato entre agentes

### Interface compartilhada

```gdscript
# scripts/overworld/encounter_rules.gd (proposto)
class_name EncounterRules
enum Advantage { NORMAL, PLAYER_FIRST, ENEMY_FIRST }

# GameState
var encounter_advantage: int = EncounterRules.Advantage.NORMAL
var return_scene := ""          # "" = EXPLORATION (2D)
var return_pos_3d := Vector3.ZERO
var return_yaw := 0.0

# EncounterTransition
func play_to(scene_path: String, advantage: int = EncounterRules.Advantage.NORMAL) -> void

# BattleScene (depois de battle.start, linha 181)
# lê GameState.encounter_advantage e aplica a regra aprovada no início da batalha.
```

### Divisão de arquivos

- **Agente A — gameplay/contrato (eu):**
  - `scripts/overworld/encounter_rules.gd` (resolvedor puro + enum).
  - `scripts/autoload/game_state.gd` (vantagem, retorno 3D).
  - `scripts/ui/transition.gd` (variantes de cor/texto).
  - `scripts/combat/battle_scene.gd` (aplicar a vantagem depois de `battle.start`).
  - Testes de regra/estado; não mexe nos VFX.
- **Agente B — VFX:**
  - `scripts/overworld/vfx/*` (speedlines, rastro, dust).
  - Hooks `begin_dash(actor, from, to)`, `tick`, `finish`.
  - Capturas e auditoria de frames; não mexe na regra nem no `GameState`.
- **Agente C — mundo/lab 3D:**
  - `scripts/debug/third_person_3d_lab.gd` e `scripts/debug/murky_forest_3d_lab.gd`.
  - Colisão, câmera, chão, estados do Slime e retorno da batalha.
  - Não edita as mesmas funções de ataque/transição; usa os componentes dos agentes A/B.

## 9. Fases

0. **Decisões** — concluída: alvo, cores, empate, input, prioridade, erro, gatilho do inimigo, escopo, vantagem, alvo 4,5 m, dano, dust, speedlines, retorno, D-308 e prompt confirmados (D-1100/D-1101).
1. **Contrato** — concluída: enum, resolvedor puro, transição colorida e testes (24/24); sem VFX e sem cena.
2. **Lab sem VFX** — concluída: ataque do jogador, ataque do inimigo, contato normal andando, animação de ataque a 2,0× e transição (66/66), com wind-up de 0,12 s e dash de até 0,18 s (D-1120).
3. **VFX** — implementado: speedlines 3D, rastro e dust; 64/64 headless e 100/100 com captura normal/espelhada (dummies), incluindo o gate de overdraw e a asserção de movimento das linhas (D-1119); vídeos no lab real gravados (azul e vermelho); aprovação visual dos valores pendente.
4. **Batalha** — concluída: vantagem 4/2 e 2/4; retorno na mesma posição/yaw; ponta a ponta nas duas variantes, com Gible (segundo inimigo) e derrota sem resetar o 2D.
5. **Produção** — pendente: só quando o overworld 3D substituir o 2D; não tocar no main 2D antes disso.

## 10. Testes e critérios de aceite

- Resolvedor: matriz de eventos, empate, sem alvo, cooldown, diálogo/menu.
- Headless `--fixed-fps 60`: ataque do jogador, ataque do inimigo, contato; assert da variante e da cena.
- Transição: cor/texto por variante; 2D continua igual.
- 3D: sem atravessar parede, sem cair do chão, câmera estável, dash na direção do alvo.
- VFX: sem restos após 2 s, rastro no chão, speedlines nas duas vistas, dust com alpha reduzido.
- Regressão: lista de 28 e suíte 16/16 continuam verdes.
- D-235: jogador e inimigo, lado normal e espelhado, alvos de tamanhos diferentes.

### Resultados (2026-11-10)

- `tests/overworld/test_encounter_rules.gd`: **24/24**, exit 0.
- `tests/overworld/test_dash_vfx.gd`: **64/64** headless e **100/100** com captura, exit 0; o teste mede o transform local das mesmas linhas (39/39 deslizam e 39/39 alongam/encolhem) e o gate de overdraw fica em p99 4,37 / máximo 5,46 (D-1119).
- `tests/overworld/test_overworld_attack.gd`: **66/66**, exit 0, incluindo o contato normal andando, o ataque total de ~0,80 s (0,12 + 0,18 + 0,5) e as animações de ataque a 2,0×.
- `tests/overworld/test_end_to_end_attack_flow.gd`: player-first **4/2**, enemy-first **2/4**, Gible com VFX vermelho e clipe `attack` a 2,0×, derrota sem resetar floor/seed/inventário e party revivida; retorno exato, exit 0.
- Animação: clipe `attack` no início do dash do jogador, do Slime e do Gible a **2,0×**, com pré-avanço de **0,12 s** sem congelar e dash de **até 0,18 s** (D-1112/D-1120); impacto do Tackle de 0,5 s no contato (D-1115); speedlines no espaço do mundo, com deslize/alongamento/rotação, e VFX limpo no contato (D-1119).
- `tests/battle/run_agent_combat_tests.py`: **16/16**.
- `test_d040_1atb.gd`: falha alheia (MP/Sand Attack), não usa este contrato.
- Vídeos no lab real: `docs/referencias/exploracao/3d/overworld_attack_player.mp4/.gif` (azul/`VANTAGEM`), `overworld_attack_enemy.mp4/.gif` (vermelho/`EMBOSCADA`), `overworld_attack_contact.mp4/.gif` (branco/`CONTATO`), `overworld_attack_lab_sheet.png` e o combinado `overworld_attack_3cases.mp4/.gif`. Demo limpa: `overworld_showcase_demo.mp4` (HUD oculto, câmera de lado, 120→30 fps, 4×) e os casos `overworld_showcase_case_player/enemy/contact.mp4`; Slime e Gible visíveis (D-1125).

## 11. Pendências de aprovação

1. **Resolvidas por D-1106:** segundo inimigo não-Medroso (Gible) para o vermelho; empate com cores por ator; derrota no lab sem resetar o 2D; reataque uma vez por entrada em `CHASE`; selo/tons mantidos.
2. **Pendente:** aprovação visual dos valores de avanço, do clipe de ataque, do pré-avanço de **0,12 s**, do dash de **até 0,18 s**, do impacto do Tackle de 0,5 s e das speedlines no espaço do mundo (D-1112/D-1115/D-1119/D-1120) no vídeo do lab real. Se aprovado, os valores deixam de ser protótipo.

Implementado no lab 3D e testado; demo em slow motion gravada; nada commitado ou enviado.
