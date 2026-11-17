<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1207 — Pré-jogo v3 (C1–C8), ciclo de campanha e Hub 3D (H1–H6)

- **Data:** 2026-11-14
- **Área:** pré-jogo, hub-3d, overworld, ui-hud, debug
- **Estado:** aprovada (em implementação e auditoria dupla)
- **Relacionadas:** [D-271](D-271-selecao-protagonista-e-roleta-nature.md), [D-390](D-390-atributos-base-15-pontos-e-faixas-por-especie.md), [D-391](D-391-renomear-spi-para-wis.md), [D-392](D-392-roleta-nature-por-especie-e-calculo.md), [D-393](D-393-atributos-aleatorios-iniciais-e-level-up.md), [D-397](D-397-nomenclatura-elementos-neutral-water-nature.md), [D-418](D-418-sem-flash-tela-cheia.md), [D-440](D-440-neutral-diamond-core-e-descoberta-afinidades.md), [D-981](D-981-comparacao-afinidades-descoberta.md), [D-1027](D-1027-minimapa-overworld.md), [D-1064](D-1064-minimapa-subviewport-top-down.md), [D-1093](D-1093-retratos-protagonistas.md), [D-1098](D-1098-icones-estado-npc-overworld.md), [D-1154](D-1154-telemetria-obrigatoria.md), [D-1161](D-1161-fluxo-pre-jogo-e-expedicao.md), [D-1165](D-1165-status-screen-camada-propria-oculta-overworld-hud.md), [D-1181](D-1181-laboratorio-3d-jogo-principal.md), [D-1204](D-1204-debug-obrigacao-extrema-teste-em-menos-de-1-minuto.md)

## Frase literal do criador

> "1 - sigo suas recomendações
> 2 - todos os 6 deveriam ser jogáveis e selecionáveis desde o inicio
> 3  - ok
>
> no restante eu sigo suas recomendações, preciso do plano em MD por completo pra outra checagem"

> "sigo suas recomendações, faça questão de usar as skills necessárias do godot para uma entrega de alto nivel, antes de finalizar, faça o deepseek realizar mais uma auditoria pelo que esqueceu ou implementou incorretamente e faça-o implementar, e depois auditorie sua implementação"

## Decisão

Ficam aprovadas integralmente as recomendações consolidadas para o **Pré-Jogo v3 (`C1–C8`)** e para o **Hub 3D v1 (`H1–H6`)**, executadas com as skills Godot 4.7 relevantes e fluxo obrigatório de implementação + segunda auditoria pelo DeepSeek V4.1 Flash + auditoria final pelo agente principal:

> **Nota (2026-11-16):** o "aliado inicial complementar" citado por esta decisão e pela D-1208 foi **substituído pela D-1261** (novo jogo só com o líder; aliados recrutados e escolhidos no Gate). O texto abaixo é histórico.

### Pré-Jogo v3 (`C1–C8`)

- **C1 (Seleção de Protagonista limpa):** Os 6 protagonistas (`Abra`, `Pancham`, `Gible`, `Slime`, `Orc`, `Cyclops`) são jogáveis e selecionáveis desde o início. `CHARACTER_SELECTION` exibe apenas retrato (`D-1093`), nome, altura (`m`), elementos inatos, distribuição base de 15 pontos (`STR..LUK`, `D-390`) e Moves iniciais — **sem HP/MP (nem mesmo HP base)** e **sem Nature predeterminada**. `HP Base`, `MP Base`, `ATB Base` e a grade completa das 12 afinidades elementais ficam exclusivamente na **Advanced View**.
- **C2 (Moves iniciais):** Revisão expressa da Q3 — todo protagonista inicia com a ação universal `BASIC ACTION: Tackle` + **2 Moves iniciais distintos da espécie** (`Slime` usa `Bubble Shot` + `Heal`, alinhado ao `loadout.tres`).
- **C3 (Viewer 3D real com fallback honesto):** Quando servido sobre HTTP com acesso aos arquivos locais em `assets/modelos/` (lembrando que `assets/modelos/` está no `.gitignore` e existe apenas localmente no workspace), o protótipo HTML carrega o `.glb` real via WebGL/Three.js; na ausência de `.glb`/HTTP ou falha de carga, declara explicitamente `2D STAGE PROXY`.
- **C4 (Atalhos e UI da Advanced View):** Preservar `[Shift]` para `MATH OVERRIDE`; adicionar `[A]` / `[Tab]` e botão visível `ADVANCED DOSSIER` para abrir a `Advanced View`.
- **C5 (Política de descoberta de afinidades `D-440` / `D-981`):** O candidato inspecionado exibe suas próprias afinidades; comparações contra outras espécies/inimigos mascaram espécies não descobertas como `[ ? ] UNKNOWN (D-981)` por padrão, com toggle `[DEBUG: REVEAL ALL AFFINITIES]`. Ícone neutro = `Diamond Core` (`D-440`); nomes dos elementos corrigidos para `Neutral`, `Water`, `Nature` (`D-397`).
- **C6 (3 camadas de profundidade + 16 funcionalidades + Briefing):** Preservar todas as 16 funcionalidades aprovadas (`P0–P3`), organizadas em 3 camadas: (1) `Character Selection`, (2) `Species Dossier (Lv.1 / Lv.10 / Lv.20)`, (3) `Advanced Build Simulator (Lv.50)`. Incluir `First Expedition Briefing` (`Exploração 3D -> Strike preemptivo -> Combate ATB`). Ocultar caixas cruas `PENDING SPECIES ABILITY` fora do toggle `[DEBUG / DEV SPEC]`.
- **C7 (Fórmula de consolidação + Roleta de Nature):** Manter `maxi(1, b + o + n)` (`crawlmon_attribute_math.gd`), documentar a tabela completa das 48 combinações `(Espécie × Nature)` e valor esperado `EV` nos `16^6` offsets triangulares; rotular a roleta como `EXPEDITION NATURE (R18-Q4)`, marcar `Hardy`/`Docile` como `PURE DISCIPLINE (UNALTERED STAT BASELINE FOR THIS EXPEDITION)`, e disponibilizar simulador debug de 10–20 expedições consecutivas.
- **C8 (Separação de fluxo no PLAY Drawer e no Hub):** Separar explicitamente os três contratos: `NEW GAME`, `CONTINUE`, e `NEW EXPEDITION (HUB GATE)`.

### Hub 3D v1 (`H1–H6`)

- **H1 (Praça Central e Visibilidade):** Praça octogonal/murada (`~28m × 26m`) usando `wall_palisade_blend.gdshader`, fade de oclusão de folhagem por câmera, portal atmosférico no Portão de Expedição, preset padrão `Warm Dusk Sanctuary` e troca `F7` / `--lighting=dusk|day|night` sem nenhum flash de tela cheia (`D-418`).
- **H2 (Elenco 3D completo e Líder trocável):** Líder controlado espelha `GameState.party[0]`, trocável entre todos os 6 protagonistas via `DebugPartySelector` / `F6`. NPCs em cena com modelos reais: `pikachu` como `GUILD CLERK`, `squirtle` como `GATE WARDEN`, além de `bulbasaur`, `charmander`, `eevee` e `dqt_healslime` com nameplate `unit_card` escalado corretamente e ícones de estado `overworld_state_icon.gd` (`D-1098`).
- **H3 (Início Solo e Interação ponderada):** Início em modo Solo (com `1` / `--party` alternando seguidores); resolvedor único ponderado por distância + cone de visão frontal cobrindo `npc`, `gate`, `guild`, `plot_a` e `plot_b`.
- **H4 (HUD, Minimapa e Isolamento de Camada):** Minimapa top-down em `SubViewport` (`D-1027`, `D-1064`) dentro de `"overworld_hud"`. `StatusScreen` hospedado em `CanvasLayer` própria **fora** do grupo `"overworld_hud"`, ocultando `"overworld_hud"` ao abrir (`D-1165`).
- **H5 (Modais Neo-Brutalistas de Portão e Guilda):** Modal do `Expedition Gate` com corte neo-brutalista, faixa de retratos reais (`PortraitIcon`), suporte a mouse + teclado, `First Expedition Briefing` e `Expedition Nature (R18-Q4)`. Menu tático da `Guild Hall` com `Inspect Active Party` (abrindo `StatusScreen`), `Standby Roster & Services [Demo Preview]` e `Close`. Cena dedicada de protótipo em `scenes/debug/hub_3d_prototype.tscn`.
- **H6 (Cenários Headless < 10 s — D-1204):** Cenários determinísticos `HUB_BOOT`, `HUB_NAVIGATION`, `HUB_INTERACTION`, `HUB_GATE`, `HUB_GUILD`, `HUB_CAMERA`, `HUB_STATE` com `--summary-json --quit` e checagens de `--lighting=dusk|day|night` e `--party`.

### Referência matemática consolidada das 48 combinações `(Espécie × Nature)` (`offsets=0` e `EV` em `16^6` sorteios)

Calculada diretamente sobre `consolidate_innate_attributes` (`maxi(1, b + o + n)`) de `scripts/combat/crawlmon_attribute_math.gd`:
- **Abra** (`offsets=0`: `Hardy/Docile/Brave/Jolly/Adamant=15`, `Timid=18`, `Modest/Calm=17`): `EV` `Hardy/Docile=16.75 [7..33]`, `Brave=16.44 [7..33]`, `Timid=18.62 [9..33]`, `Modest=18.25 [10..33]`, `Calm=17.94 [7..33]`, `Jolly=16.81 [8..33]`, `Adamant=16.38 [6..33]`.
- **Pancham** (`offsets=0`: `Brave=16`, `Jolly/Adamant=17`, demais `15`): `EV` `Hardy/Docile/Timid=16.06 [6..33]`, `Brave=17.38 [8..33]`, `Modest=16.44 [7..33]`, `Calm=16.38 [6..33]`, `Jolly=17.44 [6..33]`, `Adamant=17.88 [9..33]`.
- **Gible** (`offsets=0`: `Brave=16`, `Jolly/Adamant=17`, demais `15`): `EV` `Hardy/Docile=16.06 [6..33]`, `Brave=17.25 [8..33]`, `Timid=16.38 [6..33]`, `Modest=16.44 [7..33]`, `Calm=16.06 [6..33]`, `Jolly=17.56 [6..33]`, `Adamant=17.88 [9..33]`.
- **Slime** (`offsets=0`: `Jolly/Adamant=17`, demais `15`): `EV` `Hardy/Docile=15.94 [6..33]`, `Brave=16.62 [7..33]`, `Timid=16.75 [7..33]`, `Modest=16.44 [7..33]`, `Calm=16.25 [6..33]`, `Jolly=17.62 [7..33]`, `Adamant=17.69 [8..33]`.
- **Orc** (`offsets=0`: `Brave=17`, `Jolly/Adamant=18`, demais `15`): `EV` `Hardy/Docile/Timid/Modest=16.56 [6..33]`, `Brave=18.19 [9..33]`, `Calm=16.44 [7..33]`, `Jolly=18.62 [6..33]`, `Adamant=18.94 [9..33]`.
- **Cyclops** (`offsets=0`: `Brave=17`, `Jolly/Adamant=18`, demais `15`): `EV` `Hardy/Docile=16.62 [7..33]`, `Brave=18.19 [9..33]`, `Timid=16.56 [6..33]`, `Modest=16.44 [6..33]`, `Calm=16.25 [6..33]`, `Jolly=18.69 [7..33]`, `Adamant=19.00 [10..33]`.

## Ambiguidades e pontos em aberto

- A ativação definitiva do Hub 3D como tela inicial pós-Play no `project.godot` permanece fora do escopo desta entrega de protótipo/laboratório (conforme regra de não alterar `project.godot` sem pedido explícito).
- Habilidades passivas definitivas por espécie continuam pendentes de definição numérica pelo criador (ocultas fora do modo Debug em `C6`).
- Serviços definitivos de loja/forja/Standby nos lotes de expansão `plot_a`/`plot_b` aguardam definição de campanha futura (exibidos como `[Demo Preview]`).

## Referências

- `scripts/combat/crawlmon_attribute_math.gd`
- `content/characters/dqt_slime/loadout.tres`
- `scripts/hub/hub_3d_lab.gd`
- `scenes/hub_3d_lab.tscn`
- `scenes/debug/hub_3d_prototype.tscn`
- `.gitignore` (linha `assets/modelos/` excluída do versionamento Git)
