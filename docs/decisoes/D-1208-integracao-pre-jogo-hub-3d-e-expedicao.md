<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1208 — Integração completa no Godot: Pré-Jogo v3 → Hub 3D → Murky Forest 3D ↔ Combate 3D

- **Data:** 2026-11-14
- **Área:** pré-jogo, hub-3d, overworld, campanha, debug
- **Estado:** aprovada e em implementação
- **Relacionadas:** [D-1181](D-1181-overworld-3d-e-o-jogo-principal.md), [D-1204](D-1204-debug-obrigacao-extrema-teste-em-menos-de-1-minuto.md), [D-1207](D-1207-pre-jogo-v3-ciclo-campanha-e-hub-3d.md), [D-1161](D-1161-fluxo-pre-jogo-e-expedicao.md), [D-1154](D-1154-telemetria-obrigatoria.md)

## Frase literal do criador

> "perfeito, integre ao jogo"
> *(após as 5 recomendações enumeradas de integração)*: "sim"

## Decisão

Fica aprovada a integração completa no jogo Godot (`GL Compatibility`, Godot 4.7):

1. **Escopo de ponta a ponta:** Portar o **Pré-Jogo v3 (`C1–C8`)** para cena Godot real (`scenes/pre_game.tscn` + `scripts/ui/pre_game_screen.gd`), com Title Screen, `PLAY Drawer` (`NEW GAME`, `CONTINUE`, `NEW EXPEDITION`), `Character Selection` dos 6 protagonistas (`Abra`, `Pancham`, `Gible`, `Slime`, `Orc`, `Cyclops`) com palco 3D `.glb` real em `SubViewport`, `Advanced Dossier [A / Tab]` em 3 camadas (incluindo comparador `D-981`, simulador Lv.50 e tabela das 48 combinações), `Confirm Character` e modal da Roleta `EXPEDITION NATURE (R18-Q4)`. Conectar o ciclo completo `Pré-Jogo v3 → Hub 3D ↔ Expedição 3D (Murky Forest) ↔ Combate 3D`.
2. **Cena principal e atalhos (`project.godot` e `GameState`):**
   - `run/main_scene` em `project.godot` passa a ser `res://scenes/pre_game.tscn`, preservando atalhos CLI rápidos (`--hub`, `--forest`, `--battle`, `--scenario=...`) para testes `< 10 s` (`D-1204`).
   - `F10` em `GameState` passa a abrir o **Hub 3D** (`res://scenes/hub_3d_lab.tscn`). As cenas 2D (`scenes/exploration.tscn`, `scenes/hub_test.tscn`) permanecem preservadas no repositório como histórico/fallback (`D-1181`).
3. **Transição real no Portão (`EXPEDITION GATE`) e Roleta `EXPEDITION NATURE (R18-Q4)`:**
   - Confirmar `NEW GAME` no Pré-Jogo instancia a party inicial em `GameState` e entra no **Hub 3D**.
   - No `EXPEDITION GATE` do Hub 3D (ou via `NEW EXPEDITION` no `PLAY Drawer`), confirmar `MURKY FOREST — 5 FLOORS (AUTHORIZED)` dispara a roleta `EXPEDITION NATURE (R18-Q4)` (animação pulável sem alterar o resultado travado), aplica a Nature sorteada e atributos consolidados (`maxi(1, b + o + n)`) em `GameState.party`, restaura HP/MP e estoque base da expedição (`revive_party()`, `reset_expedition_inventory()`, limpa `defeated`) e entra em `res://scenes/debug/murky_forest_3d_lab.tscn`.
4. **Composição inicial da `GameState.party`:**
   - O protagonista escolhido assume a posição de líder (`GameState.party[0]`) acompanhado de **1 aliado inicial complementar** (`Pancham` por padrão, ou `Abra` se o protagonista escolhido for `Pancham`), mantendo o combate em dupla calibrado e permitindo inspeção/expansão futura via `Standby Roster` da Guilda.
5. **Retorno da `Murky Forest 3D` para o Hub 3D:**
   - Interagir (`Z`/`E`) na Porta de Saída da `Murky Forest 3D` (`"Z/E: RETURN TO HUB"`, `D-413`) encerra a expedição e retorna ao Hub 3D (`res://scenes/hub_3d_lab.tscn`) preservando XP, níveis e itens.
   - Em derrota em combate (`end_battle(false)`) durante expedição originada pelo fluxo Hub 3D, aplicar `revive_party()` + `reset_expedition_inventory()` e retornar ao Hub 3D.

## Ambiguidades e pontos em aberto

- Persistência real em disco para o botão `CONTINUE` (save slots reais entre sessões) permanece desabilitada/reservada quando não houver save em disco, utilizando estado de campanha ativo em sessão quando disponível ou `NEW GAME`.
- Serviços definitivos de loja/forja e recrutamento nos lotes `plot_a`/`plot_b` e `Standby Roster` aguardam especificação própria.

## Referências

- `project.godot`
- `scripts/autoload/game_state.gd`
- `scenes/pre_game.tscn` / `scripts/ui/pre_game_screen.gd`
- `scenes/hub_3d_lab.tscn` / `scripts/hub/hub_3d_lab.gd`
- `scenes/debug/murky_forest_3d_lab.tscn` / `scripts/debug/murky_forest_3d_lab.gd` / `scripts/debug/third_person_3d_lab.gd`
