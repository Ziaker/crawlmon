# Auditoria GDD × jogo (2026-11-04)

> **Natureza:** relatório de leitura. Nenhum código nem regra foi alterado. Não registra decisão nova do criador.
> **Fontes:** `docs/GDD.md` do `origin/main` (revisão 1.38, ~1900 linhas), `docs/decisoes/README.md` e arquivos `D-xxx` de combate (R39–R52), `docs/REGRAS_DO_JOGO.md` e o código da árvore de trabalho (`scripts/`).
> **Regra aplicada:** D-001 — o GDD vale para exploração, campanha, progressão e economia; para combate valem as decisões D-xxx e o código.

## Limites desta auditoria

- Comparação feita por leitura e busca de termos no código. **O jogo e os testes não foram executados.**
- GDD lido por inteiro apenas no §1 e no §8; o §7 (rodadas R10–R38) e o adendo R39–R67 foram conferidos pelo resumo da `REGRAS_DO_JOGO.md` e pelos arquivos `D-xxx`.
- Decisões de combate lidas: R39 a R52 (D-031 a D-113). As R53–R67 (IA, atributos, fórmulas) foram conferidas só pelo índice.
- Itens marcados **(não verificado)** precisam de conferência antes de serem tratados como feitos ou como faltantes.

## 1. Resumo

O jogo é **uma fase única de exploração + um combate 3D avançado**. Quase tudo que o GDD define para campanha, equipe, progressão e economia não existe no código.

## 2. Exploração e campanha (GDD) — situação

### Já existe
| Item | Evidência |
|---|---|
| Mapa 2D procedural por seed, salas e corredores (R7-Q5, R8-Q3/Q4) | `scripts/dungeon/dungeon_generator.gd` |
| Layout guardado ao voltar de uma batalha (R9-Q2) | `GameState.dungeon_layout` |
| Névoa de guerra e mapa revelado progressivamente (R32-Q4) | `fog_of_war.gd` |
| Inimigos visíveis que patrulham, perseguem e iniciam o combate por contato (R8-Q5, R9-Q3) | `enemy.gd`, `exploration.gd` |
| Inimigo derrotado removido do andar (R9-Q4) | `GameState.defeated` |
| Movimento contínuo em 4 direções (R23-Q1) | `player.gd` |
| NPCs com diálogo; Poções coletáveis (D-033) | `npc.gd`, `pickup.gd` |
| Transição 2D ↔ 3D | `GameState.start_battle`/`end_battle` |

### Falta
1. **Dungeon:** só existe um andar. Não há escada/saída (R24-Q1), vários andares (R33-Q3), chefe (R23-Q2, R29-Q4, R30-Q3, R34-Q4), fim de dungeon (R26-Q4), campanha e desbloqueio de dungeons (R25-Q1, R37-Q3), nem rejogar dungeons (R29-Q3).
2. **Equipe:** o grupo é fixo (Abra e Pancham) e o inimigo é um Gible escrito no código (`battle_scene.gd`). Faltam escolha do protagonista (R26-Q1, R37-Q4), começar sozinho (R27-Q2), recrutamento (R23-Q4, R24-Q2, R35-Q2, R32-Q5), reserva (R24-Q3, R38-Q3), terceiro aliado (R6-Q3), aliados seguindo no mapa (R35-Q1, R36-Q1) e contato do inimigo com qualquer ativo (R37-Q1).
3. **Progressão:** não há XP, nível, pontos de atributo do protagonista, crescimento dos aliados, evolução (R25-Q3), Natures, MP (R11–R17), telemetria de ações (R16–R22), treino de reservas (R33-Q2), nem aprendizado de Moves por nível, mestres, HM/TM (R23-Q5, R24-Q4, R27-Q4). A tela de status mostra "N/D" para nível, EXP e MP.
4. **Itens e economia:** só a Poção funciona; Amuleto e Talismã não têm efeito (R28-Q2). O inventário é um único dicionário compartilhado, não 10 itens por Pokémon (R34-Q5, R35-Q3, R38-Q4). Não há berries, moedas, lojas/comerciantes (R28-Q1, R29-Q1), recompensas de batalha (R27-Q5) nem perda de itens não segurados (R25-Q4, R31-Q1).
5. **Desfechos:** `GameState.end_battle(false)` apenas volta ao mapa. Faltam derrota definitiva que encerra a expedição (R23-Q3, R33-Q1), retirada voluntária (R30-Q1), fuga de combates comuns (R27-Q1, R28-Q3, R35-Q4), pontos de descanso (R31-Q5, R32-Q2) e retorno do protagonista caído com recuperação mínima (R31-Q2, R32-Q1).
6. **Mundo:** não há biomas (R27-Q3, R28-Q4), arenas 3D por bioma (R38-Q2), espécies características por dungeon (R36-Q5), salas secretas (só uma fala de NPC; R26-Q5, R33-Q4), eventos e missões (R29-Q2, R34-Q1, R35-Q5, R36-Q2, R37-Q2), dificuldade progressiva (R29-Q5, R37-Q5) nem as regras de persistência de eventos na revisita (R36-Q3, parcial: só itens e inimigos persistem).
7. **Divergência a decidir pelo criador:** R38-Q1 diz que a detecção é principalmente por proximidade, sem linha de visão estrita; a `REGRAS_DO_JOGO.md` §14.2 descreve o código com visão que exige linha de visão (e audição a 3 tiles). **(não verificado em `enemy.gd`)**

## 3. Combate — situação por decisão (R39–R52)

### Conferido no código: implementado
| Decisão | Evidência |
|---|---|
| D-031 ATB inicial 3/5 | `START_ATB = 3.0` |
| D-033 Burst paga a ação inteira, máx. 5 | `BURST_MAX = 5` |
| D-034 / D-006 custo do Evade 3 parado e 2 no trajeto | `EVADE_STILL`, `EVADE_ON_RUN` |
| D-038 / D-060 / D-031(antiga) pausa nos golpes de status | `_status_pause`, `STATUS_WINDUP`, `STATUS_VFX_TAIL` |
| D-042 janela de 2 s após Evade perfeito | `ENGAGE_SECONDS = 2.0` |
| D-051 / D-052 golpe extra enfileirado | `queued_skill`, `_run_queued()` |
| D-105 / D-107 resultado imediato no KO do último, sem projéteis pendentes | `_check_end()` limpa `incoming` e `_landing` |
| D-056 / D-157 / D-160 / D-166 lançamento fatal | testes `test_d049`, `test_d157`, `test_d160_d164` |

### Conferido no código: não implementado ou divergente
| Decisão | O que o código faz |
|---|---|
| **D-039 / D-050 / D-015** todos os inimigos sempre visíveis | O enquadramento existe (`frame_mode`), mas nasce **desligado** (`OFF`) e só o painel de debug o liga. |
| **D-036 / D-007 / D-057–D-059 / D-066 / D-067 / D-075 / D-077 / D-078 / D-083–D-086** AoE sem alvo principal, onda de velocidade espacial constante, janela perfeita única | Não achei lógica de onda. O AoE ainda tem alvo principal e `_retarget_aoe`. |
| **D-091 / D-095** empate quando as duas equipes caem juntas | `_check_end()` emite `battle_ended(enemies_dead)`: se as duas caem, o resultado é "Vitória!". Não há empate. |
| **D-108 / D-103** trocar para o inimigo vivo **mais próximo** se o alvo morre no wind-up | `_retarget_aoe()` só vale para AoE e escolhe o **primeiro** vivo da lista; golpe de alvo único cujo alvo morre é cancelado. |
| **D-106 / D-104** Evade termina como golpe que erra, sem interrupção nem cambaleio | O código ainda tem `Phase.STAGGER` e "atacante interrompido" no Evade. |
| **D-072 – D-074 / D-082** estorno de custo do contra-ataque cancelado; crédito de excedente | Não achei lógica de estorno nem de crédito separado. |
| **D-032** até 8 Moves, 4 hotkeys, Tackle separado | Cada personagem tem 7 Moves; o Tackle existe em `Skill`. |
| **D-089** lançamento fatal que bate em parede e cai | Não achei detecção de colisão no lançamento. |
| **D-111 / D-114** alvo aleatório da IA; **D-115** cura situacional | `battle_ai.gd` não sorteia alvo; a cura usa limite fixo de 50% (`AI_HEAL_BELOW`). |
| **D-117 – D-156** atributos, AGI no ATB e no trajeto, LUK em status, crítico e esquiva | Não existem atributos no código. Crítico e esquiva automática são fixos em 10%. |

### Não verificado
D-035, D-041, D-043–D-047, D-053–D-055, D-062–D-065, D-068–D-070, D-079–D-081, D-087, D-088, D-090, D-092–D-094, D-096, D-098–D-101, D-109, D-110, D-112, D-113 e as rodadas R53–R67 além do que consta acima.

## 4. Problemas de documentação

- O índice `docs/decisoes/README.md` está desatualizado em pontos: a D-006 consta como "Não implementado", mas o código já tem os custos 3 e 2.
- Os IDs **D-031 a D-049 aparecem duas vezes** no índice, em duas séries diferentes (por exemplo, D-031 é "status pausa o motor" e também "R39-Q1 ATB inicial").
- O §8 do GDD ("estado real do repositório") descreve o commit `1171b5f3` e hoje está errado.
- Conflitos pendentes entre decisões já registrados: D-017 × D-106 (resolvido em D-106), D-099/D-100 × D-105/D-107 (resolvido), D-103/D-104 (conflito de compatibilidade pendente).
- A `main` local está 7 commits atrás do `origin/main` (Rodadas 65–67).
