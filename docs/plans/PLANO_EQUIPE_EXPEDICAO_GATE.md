> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
> **MOVE = 3D, NUNCA 2D (D-1222).** Todo Move, efeito, mão, trajetória e protótipo é visualmente 3D de verdade (curvas em x, y e z, rotação de pulso/lâmina, volume, luz). É PROIBIDO tratá-lo como 2D (plano único, peça rígida deslizando, câmera 3D com movimento 2D) a não ser que o criador mande EXPLICITAMENTE, Move a Move. Referência de movimento: trajetória 3D real dos ossos dos ataques do Abra/Pancham.

# Plano: equipe da expedição no HUD do Gate (D-1261)

Prompt de continuação para a próxima sessão. Leia `AGENTS.md`, `docs/decisoes/D-1261-*.md`, `D-1229`, `D-1233`, `docs/TELEMETRIA.md` (D-1154) antes. Outras sessões editam `hub_3d_lab.gd` (gate/warp D-1260): só `Edit` pontual, sem commit, sem `git stash/checkout/reset`.

## Decisões do criador (literais em D-1261)
- Novo jogo = só o líder; elenco vazio. Recrutar = Employ (combate, D-1229) ou conversar com NPC do hub (direto, só espécies com ficha: abra, pancham, gible, slime, orc, cyclops).
- HUD de expedição (Gate): 3 badges (líder à esquerda + 2 vagas); à direita a lista dos recrutados com o **nível no canto superior direito** de cada badge; clicar e **arrastar** badges até as vagas; os aliados **vêm até o jogador** (presentes no mapa do HUD). Fora da equipe, o aliado **volta ao ponto de origem**.

## Já feito (lógica, testada)
`GameState.recruit_character / recruited_available / team_assign / team_unassign`; hub: `recruit_npc`, `team_assign`, `team_unassign`, `_sync_followers_to_party`, Z "RECRUIT" no diálogo; cenários `HUB_ALLY_CHOICE`, `HUB_RECRUIT_TALK` (`hub_3d_prototype.tscn -- --scenario=... --quit`).

## Falta
1. **[Claude, visual]** Seção da equipe no `_build_gate_panel` (`hub_3d_lab.gd`, ~2935): 3 badges + lista com nível sup. direito, arrasto com `Control.set_drag_forwarding`, estilo do Gate/Guilda. Atualizar ao abrir o Gate e a cada atribuição.
2. **[Claude, visual]** Opção "recrutar" estilizada no diálogo do NPC (hoje só o texto "Z: RECRUIT X: CLOSE").
3. **[DeepSeek]** Entradas `HUB_ALLY_CHOICE` e `HUB_RECRUIT_TALK` em `tests/battle/run_agent_combat_tests.py`.
4. **[DeepSeek]** Cenário/teste: confirmar o Gate com equipe montada mantém `GameState.party` (líder + aliados) na expedição.
5. **[DeepSeek]** Verificar Employ real em combate (`--employ=roll:win`) deixando o recruta em `GameState.get_roster()` e utilizável por `team_assign`.
6. **[DeepSeek→Claude]** Painel "Standby Roster" da Guilda ligar ao elenco real (dados: `GameState.recruited_available()`).
7. **[Claude, texto]** Notas "substituída pela D-1261" em D-1207 (C1) e D-1208 (linha 33) e em `docs/REGRAS_DO_JOGO.md`, sem apagar o histórico.

## Verificação (nada de "pronto" sem isto)
Cenários `HUB_ALLY_CHOICE`, `HUB_RECRUIT_TALK`, `HUB_BOOT`, `PREGAME_CAMPAIGN`; `python tests/battle/run_agent_combat_tests.py` (a falha "Javelin Throw D-235" já existia, de outra frente); captura do Gate em tamanho real; clique/arrasto reais não simulados ficam declarados como não verificados.
