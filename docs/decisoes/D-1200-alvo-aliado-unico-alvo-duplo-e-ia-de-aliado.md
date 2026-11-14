# D-1200 — Alvo aliado único, alvo duplo (primário e secundário) e a IA escolhendo aliado

- **Data:** 2026-11-12
- **Área:** Combate (seleção de alvo)
- **Origem:** Conversa
- **Estado:** aprovada; **implementada em parte** (2026-11-12): aliado único (Heal), IA de aliado e a **estrutura** do alvo duplo. Efeitos do alvo duplo e moves de exemplo seguem pendentes.

## O que o criador disse (literal)

> "Quero que você 🫵 ajeite isso, e ajeite para outras questões também como alvo duplo aliado+ inimigo e também a seleção de alvos aliados para o oponente (no caso do heal do slime)"
>
> "Não existe sukukaja de 1 aliado, use o heal do slime como exemplo" (sobre como o jogador escolhe o aliado-alvo de um move de um aliado só)
>
> "Ele escolhe o alvo primário primeiro e depois o secundário, no caso tem q clicar duas vezes (3 se incluir o fight) pode criar dois  moves genérico pras duas novas implementações" (alvo duplo)
>
> "Se baseia na vida e nos status proncipais, se o aliado tem muita STR então ele foca um buff de atk nele. Se tem um move de cura foca o com menos vida, si mesmo se ambiguo," (IA escolhendo o aliado)
>
> "Passa a curar um aliado só" (Heal do Slime)

## Decisão

1. O Sukukaja **não** é de um aliado: é em grupo (D-1198). O exemplo de alvo aliado único é o **Heal do Slime**.
2. **Heal do Slime** passa a curar **um aliado só**. Fato verificado no código: hoje o `heal` (`content/moves/heal/move.tres`, `is_aoe = true`) **não cura nada** (sem comportamento registrado, cai no fallback de `battle.gd:936-942`); quem cura todos os aliados em área é o `media` (Abra). A quantidade de cura do Heal está **pendente**.
3. O jogo passa a ter **move de alvo aliado único**, escolhido pelo jogador (hoje o alvo cai no líder; `battle.gd:243-245`, `battle_scene.gd:1114-1116`).
4. O jogo passa a ter **move de alvo duplo (aliado + inimigo)**: o jogador escolhe o **alvo primário primeiro e depois o secundário** (dois cliques de alvo; três contando o Fight).
5. Para as duas implementações novas, criar **dois moves genéricos** (um para alvo aliado único, outro para alvo duplo), reutilizáveis por qualquer personagem, time e lado (D-235).
6. **IA** escolhendo aliado-alvo: baseia-se na vida e nos status principais; aliado com muita STR recebe o buff de ATK; move de cura vai no aliado com menos vida; em caso ambíguo, em si mesma.

## Respostas do criador à rodada de recomendações (2026-11-12)

O criador disse "Sim" às recomendações 1, 2 e 4:
1. Aliado único: abre o menu `S.TARGET` ("CHOOSE TARGET") só com aliados vivos, **incluindo o próprio lançador**; alvo duplo abre dois menus em sequência (primário, depois secundário). Atalhos 1-9 e R passam pelo mesmo passo.
2. Heal do Slime: cura **um** aliado escolhido por **10 + MAG** (como o Media), `is_aoe = false`, com comportamento registrado.
4. IA: "menos vida" = **percentual de HP**, com o mínimo de 20% de HP faltante (`MIN_MISSING_TO_HEAL`); "muita STR" = o aliado de maior STR que ainda pode receber o buff; ambíguo = o próprio lançador.

## Respostas do criador à lista de pendências (2026-11-13)

1. Sobre qual metade do alvo duplo afeta o inimigo e qual o aliado, o criador disse: "descrito no texto do move, então cada move de alvo duplo pode decidir se o alvo primario é inimigo ou aliado".
2. Sobre criar os moves de alvo duplo: "eu tinha mandado uma outra sessão sua criar isso pra poder testar no jogo" (esta sessão **não** cria moves de alvo duplo).
3. O que cada menu de alvo mostra: "sigo sua recomendação" (cada Move declara o lado de cada pick; sem declarar, `ANY` = todos os vivos).
4. Textos do Heal ("Heals one ally for 10 + MAG | 2 ATB"): "ok".

Consequência no código: `MoveData.primary_side` / `secondary_side` (`TargetSide`: `ANY`, `ALLY`, `ENEMY`, relativos ao lançador; o próprio lançador conta como aliado). `Battle.use_skill` recusa um par que não respeite os lados; a cena (`_side_candidates`) só oferece nos menus os alvos do lado declarado. Nenhum move real usa isso ainda; os testes usam Skills descartáveis.

## O que foi implementado

- `MoveData.target_mode` / `Skill.target_mode` (`AUTO`, `SINGLE_ALLY`, `DUAL`). `AUTO` mantém o comportamento antigo de todos os moves existentes; só o Heal usa `SINGLE_ALLY`.
- `Battle.team_of / opponents_of / same_team` leem as listas do `Battle`, não `is_player` (D-235); usados em `use_skill`, na IA e na cena.
- `Incoming.target2`, `Combatant.queued_target2` (fila, `save_state`/`restore_state`), `Battle.use_skill/request_skill(…, target2)`.
- Telemetria: `target2` em eventos com `Incoming`, `queue` e `qt2` por quadro (ver `docs/TELEMETRIA.md`).
- IA: `BattleAI.pick_ally_target` + `MoveBehavior.ai_ally_focus()` (`&"hp"` no Heal; `&"str"` suportado, nenhum move o usa). A IA **não usa** moves `DUAL` (efeitos indefinidos).
- Alvo duplo: **só estrutura**. Cada move `DUAL` declara o lado de cada pick (`primary_side`/`secondary_side`, padrão `ANY` = qualquer vivo); o picker oferece só os alvos desse lado. Nenhum move `DUAL` existe, nenhum efeito foi definido.
- Debug (D-1204): cenários `heal_aliado` e `heal_aliado_espelhado` (`--scenario=<id> --stdout-trace --quit`, ~10 s) e a flag `--picker=<move_id> [--mirror] --shot=arquivo.png` da sala de VFX, que abre o Fight do líder com o Move, o menu `S.TARGET` e imprime `[vfx_room] picker result=ok ... targets=... all_allies=true` (precisa de janela).
- Teste da cena real: `tests/battle/test_d1200_target_menu.gd` (menu do Heal, cancelar, tecla numérica, dois menus encadeados do alvo duplo; Skill descartável do teste).
- Teste: `tests/battle/test_d1200_ally_and_dual_target.gd` (lado normal e espelhado, alvos de HP máximo diferentes; Skill `DUAL` descartável criado só no teste).

## Ambiguidades em aberto

- Alvo duplo: **resolvido na estrutura** (cada Move declara os lados). Falta só a definição de cada move real (efeitos, nomes, custos), a cargo da outra sessão que o criador mencionou.
- Qual é o efeito de cada metade de um move de alvo duplo (o que afeta o inimigo, o que afeta o aliado) e quais moves reais o usarão.
- "Muita STR" e "vida mais baixa": **resolvido** (percentual de HP, mínimo 20% faltante; maior STR que ainda recebe o buff). Nenhum move de aliado único com buff de ATK existe ainda.
- Os dois moves genéricos: o de aliado único é coberto pelo Heal; o de alvo duplo **não foi criado** (nome, custo e efeitos pendentes).
- Comparações `is_player` do alvo em outros trechos de `battle.gd` (:443, :736, :905, :924, :1102) **não foram alteradas** (fora do escopo); os caminhos novos usam `same_team`.
