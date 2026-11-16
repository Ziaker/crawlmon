<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# Auditoria Fase 0 — Employ, Summon e Respeito (2026-11-15)

Só auditoria e documentos. **Nenhum código foi alterado.** Decisões registradas: D-1229 a D-1234.

## 1. Estado do repositório

| Item | Valor |
|---|---|
| Branch de trabalho | `wip/checkpoint-2026-11-06` @ `689450b2` |
| `origin/main` | `1d88e24f` (o SHA do briefing); o branch de trabalho está 4 commits à frente |
| `main` local | `af2df022` (antigo, divergente de `origin/main`) |
| Working tree | ~45 arquivos modificados sem commit, entre eles `battle.gd`, `battle_scene.gd`, `combatant.gd`, `game_state.gd`, `post_combat_flow.gd`, `README.md` das decisões e `REGRAS_DO_JOGO.md`; D-1222 a D-1228 ainda sem commit |
| Sobras | `scripts/combat/battle_trace.gd.orig` e `.rej` (patch antigo que falhou) |

O briefing manda usar `main`; o trabalho real do projeto está no branch `wip`. **Respondido pelo criador (2026-11-15): "Sim, no wip"** — a Fase 1 entra em `wip/checkpoint-2026-11-06`.

## 2. O que existe hoje (arquivo:linha)

| Área | Fato |
|---|---|
| Party | `GameState.party: Array[Combatant]` (`game_state.gd:28`), 2 membros na criação (`:135-158`, `:465-483`); sem máximo declarado; 3 `PARTY_SLOTS` (`battle_scene.gd:12`) |
| Identidade | Não há id individual; chave é a espécie (`species_key`, `game_state.gd:44-45`); `character_natures` usa essa chave (`:41`) |
| Líder | `party[0]`; `Combatant.is_party_leader()` (`combatant.gd:437-448`). Não existe "Traveler" |
| Atributos | `level` (`combatant.gd:61`), `str/vit/wis/agi/luk` (`:35-45`), `mag` (`:32`); `spi` é alias de `wis` (`:39-43`); consolidação em `crawlmon_attribute_math.gd:109` |
| Buffs | Só `atk_buff/def_buff/speed_buff`, −5..+5, sem duração (`combatant.gd:124-126, 701-734`), zerados no fim da luta (`battle.gd:1405`). Nenhum buff temporário por atributo |
| ATB | `BLOCKS = 5.0` + `extra` sem teto (`combatant.gd:20, 94-95`); `spend()` (`:759`), `pay()` (`:666`), `add_atb()` (`:766`); começa em 3 (`battle.gd:156`) |
| Burst | `BURST_MAX = 5` (`combatant.gd:21`); `pay()` gasta 1 Burst no lugar do custo inteiro (`:661-670`, D-033); Guard/Evade/Passos usam `spend()` direto. Ganho com Burst cheio é bloqueado |
| Menu raiz | Fight, Items, Evade/Guard, Tactics, Status (`battle_scene.gd:941-951`). "Direita" na raiz só é usada no índice 2 (Evade↔Guard, `:1284-1291`): **livre sobre TACTICS** |
| Tactics | Drawer "TACTICS // ALLY AI" (`battle_scene.gd:1251-1269`); pausa a árvore (`:905-906`) |
| Pausas | Pausa de status (`battle.gd:170, 244-247, 376`), hit-stop (`:231-238`), câmeras lentas de decisão/Evade/interrupção (`battle_scene.gd:44-50, 666-679, 743-823`) |
| Diálogo | `DialogueBox` genérico (`dialogue_box.gd:51-53, 341`), nunca usado em combate; falas por Nature em `ally_dialogue.gd:1-48` (2 por Nature) |
| Minigame / cutscene | Não existem. Só a janela de Evade (`battle.gd:128-130`), sem nota GOOD |
| Card do inimigo | `EnemyTag` (`battle_hud.gd:1396`), badges a partir de `:1454` |
| XP | `_trigger_victory_flow` (`battle_scene.gd:853-880`) → `PostCombatFlow.grant_xp(party, total_xp)` (`post_combat_flow.gd:18`), integral para cada vivo (`:35`) |
| Fim de luta | `_check_end` (`battle.gd:1371-1407`); inimigo só sai por K.O. (fora o debug, `battle_scene.gd:439-458`) |
| Persistência | Não há save em disco (`game_state.gd:31, 40`); `Battle.save_state/restore_state` (`battle.gd:1411-1435`) é só para testes |
| Expedição | Portão do hub (`hub_3d_lab.gd:2427-2432`), retirada (`game_state.gd:227`), derrota (`:312-333`). A expedição de 5 andares e a escada não existem (`game_state.gd:81`) |
| Guilda | Guild Hall no hub (`hub_3d_lab.gd:1338-1377`); "Standby Roster" é demo sem dados (`:100-104`) |
| Chefe / ameaça | Não há marcação de chefe nem índice de ameaça |
| Nature | `nature_data.gd:7-122`: `name`, `mods`, `atb_reserve_bias`, `aggression_mult`; 18 no arquivo, 8 iniciais |
| RNG | `randf()` global; `debug_roll` (`battle.gd:137`); `--seed=` (`battle_trace.gd:51-52`). Sem RNG compartilhado |
| Testes | `run_agent_combat_tests.py` usa listas fixas `SCENARIO_TESTS`/`SCRIPT_TESTS` (`:26-155`); flags `--changed --only= --report= --jobs= --cache --fail-fast --budget=`. `tests/combat` 6, `tests/exploration` 2, `tests/ui` 37 scripts `extends SceneTree` |
| Cenários | Dicts em `SCENARIOS` (`vfx_room_scenarios.gd:5-9`): `id, g, label, atk, acts, enemies, hp, pos, atb` |

## 3. Matriz de requisitos

**A. Aprovado e já implementado:** nada dos três sistemas. Bases reaproveitáveis: ATB/`spend()`, menu FanMenu com sinal `side`, `DialogueBox`, badges do `EnemyTag`, `grant_xp`, cenários da sala de debug.

**B. Aprovado, não implementado (D-1229 a D-1234):** custo de Employ (5 ATB) e Summon (2 ATB) sem Burst; aba alternativa em TACTICS; fluxo de 7 passos; notas 1/2/3 com +5/+10 pp; fracasso → BOOST + bloqueio; Respeito 0–100 com a tabela de ganhos; regras de troca do Summon; 3 ativos + 2 substitutos + estacionados; retorno à guilda; EXP Share 50%.

**C. Base de calibração (não é balanceamento homologado):** coeficientes da fórmula (45, 2, ±20, 0,16) e os valores do BOOST.

**D. Pendente (declarado pelo criador):** categorias elegíveis; timing, MISS, teclas e interrupção do minigame; Burst cheio no BOOST; participantes com aliados em K.O.; instante do pagamento; contrato de RNG; índice de ameaça e limiar; falas por Nature; Summon com protagonista em K.O., interrupções, ações em trânsito, ATB de quem entra, posicionamento, efeitos temporários; XP de quem troca de categoria, de recruta da própria luta e de substituto em K.O.

**E. Conflitos com regras existentes:**

| # | Conflito | Fontes |
|---|---|---|
| E1 | SPI × WIS (Spirit foi renomeado) | briefing × D-391 |
| E2 | Reservas não recebem XP × substitutos recebem 50% | `REGRAS_DO_JOGO.md` §14.5 (GDD R26-Q3/R31-Q3) × D-1234 |
| E3 | Recrutado entra na equipe ativa se houver vaga × só entra por Convocação | §14.3 (GDD R30-Q5) × D-1232 |
| E4 | Escada do 5º andar inicia nova expedição mantendo a equipe × recrutados voltam à guilda na vitória | D-316 × D-1233 |
| E5 | Vitória ao derrotar o último inimigo × último inimigo recrutado | D-105 × D-1229 |
| E6 | Todo texto em inglês × falas de NPC em português | D-413 × D-1085 |
| E7 | Perder a corrida de rivais tira Respeito × tabela nova não tem essa linha | D-1210 × D-1231 |
| E8 | Nature do líder apagada na derrota × identidade/dados dos recrutas íntegros | `game_state.gd:312-333`, D-1219 × D-1233 |

## 4. Dependências por fase

| Fase | Precisa de | Arquivos |
|---|---|---|
| 1 Estado | Identidade individual; branch definido | novos em `scripts/progression/`; `game_state.gd` (campos novos); `tests/combat/`; `vfx_room_scenarios.gd` |
| 2 Cálculos puros | SPI/WIS (E1); arredondamento | novo script de fórmula + teste; nenhum arquivo de combate |
| 3 Respeito persistente | O que é "Traveler"; o que é "persistente" sem save; chefe/desafio/expedição | `game_state.gd` |
| 4 Menu | Desenho da aba (protótipo HTML antes) | `battle_scene.gd`, `fan_menu.gd`, `battle_hud.gd` |
| 5 Fluxo Employ | Tipo de pausa; elegibilidade; E5 | `battle.gd`, `battle_scene.gd`, `battle_trace.gd`, `TELEMETRIA.md` |
| 6 Minigame e visual | Timing/MISS; protótipo; D-308/D-1218/D-1222 | UI nova, `battle_fx.gd` |
| 7 BOOST | Buff por atributo; Burst cheio; D-1026 | `combatant.gd`, `battle_hud.gd` |
| 8 Summon | Todos os contratos pendentes do Summon | `battle.gd`, `battle_scene.gd`, `battle_hud.gd` |
| 9 EXP Share | E2; casos de troca de categoria | `post_combat_flow.gd`, telas de pós-combate |
| 10 Dungeon/guilda | E4, E8; expedição de 5 andares ainda não existe | `game_state.gd`, hub, overworld 3D |

## 5. Não verificado

- Não rodei testes nem o jogo (Fase 0 é só leitura).
- Não conferi se o `BattleTrace` registra cada sorteio.
- A lista de decisões "talvez aplicáveis" do resumo do DeepSeek (80 IDs) não foi aberta uma a uma.
