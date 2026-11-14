<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# CRAWLMON — Planejamento do Sistema de Pré-Jogo 3D & Arquitetura para DeepSeek

> **Estado:** Planejamento conceitual e especificação técnica **sem implementação no Godot**. Nenhum script, cena, recurso `.tres` ou `project.godot` deve ser criado ou alterado até aprovação expressa do criador.
> **Divisão de papéis:**
> - **DeepSeek (código estrutural/pesado, após aprovação):** máquina de estados do frontend, câmera 3D com auto-enquadramento por AABB, carregador/cache assíncrono de modelos, persistência de configurações (`ConfigFile`), pipeline de input/bloqueio seguro, integração com `GameState` e suíte de validação headless (`< 10 s`, D-1204).
> - **Agente Visual / UI:** composição 2D/3D, shader/iluminação de palco, animações escalonadas `-9°`, legibilidade tipográfica (peso equilibrado, sem excesso de bold) e feedback tátil/visual sem flashes de tela (D-418).

---

## 1. Auditoria Real do Repositório

Verificado em `wip/checkpoint-2026-11-06` (`HEAD: 2ae07202`):

1. **Configuração e Renderer (`project.godot`):**
   - `run/main_scene="res://scenes/exploration.tscn"` (abre direto na exploração 2D, sem tela de título ou pré-jogo).
   - Viewport base `1280x720`, `window/stretch/mode="canvas_items"`.
   - Renderer **`gl_compatibility`** (desktop e mobile) — limitações reais de pós-processamento pesado, SSR, SDFGI e múltiplos shaders complexos simultâneos.
   - Autoloads ativos: `GameState` (`scripts/autoload/game_state.gd`), `Menus` (`scripts/ui/menus.gd`), `_mcp_game_helper` (`addons/godot_ai/runtime/game_helper.gd`).
2. **Estado da Migração 3D (`D-1181` vs Código Atual):**
   - `D-1181` declara que o laboratório 3D (`scenes/debug/murky_forest_3d_lab.tscn`, herdando `third_person_3d_lab.gd`) passa a ser o jogo principal completamente 3D, porém `project.godot` e `GameState.EXPLORATION` (`res://scenes/exploration.tscn`) **ainda apontam para a cena 2D**.
   - **Divergência explícita (`D-324` × `D-1181`):** `D-324` definiu o Hub inicial como vila 2D top-down, enquanto `D-1181` define o jogo como completamente 3D. Além disso, `D-324` aponta divergência de protagonista (mapa 2D usa Pikachu; `GameState._build_party()` cria Abra + Pancham). Ambas exigem definição do criador.
3. **Menus, Persistência e Áudio Atuais:**
   - `Menus` (`scripts/ui/menus.gd`) gerencia apenas overlays in-game (`Mode.NONE, TABS, PICK, SETTINGS`), pausa a árvore e oferece só `Velocidade do diálogo` (ainda em PT-BR no arquivo, divergindo de **D-413**) + botão debug `F9`.
   - **Não existe sistema de Save/Load** em disco (`GameState.discovered_species` é explicitamente *session only*).
   - **Não existe `default_bus_layout.tres`** encontrado na raiz para buses `BGM`/`SFX` separados (apenas `Master` padrão até ser criado/aprovado).
   - **InputMap em `GameState._ready()`:** `confirm` (`Z`), `menu` (`X`), `settings` (`C`), `evade` (`Space`), `guard` (`Shift`), `new_dungeon` (`R`). Navegação via setas (`ui_up/down/left/right`) padrão do Godot.
4. **Personagens, Modelos 3D e Fontes:**
   - `CharacterCatalog` (`content/catalogs/character_catalog.tres`, D-1079) registra **6 fichas canônicas**: `gible`, `abra`, `pancham`, `dqt_slime`, `dqt_orc`, `dqt_cyclops` — com `raw_stats` (`STR`, `MAG`, `VIT`, `WIS`, `AGI`, `LUK`), `weaknesses`, `affinities` e `loadout.skills`.
   - `assets/modelos/` contém **17 pastas** (`abra`, `bulbasaur`, `charmander`, `dqt_cyclops`, `dqt_dracky`, `dqt_fungi`, `dqt_healslime`, `dqt_orc`, `dqt_platypunk`, `dqt_sabrecub`, `dqt_slime`, `eevee`, `gible`, `owl`, `pancham`, `pikachu`, `squirtle`), porém 11 delas não têm ficha no `CharacterCatalog`.
   - `CharacterModelLoader` trata duas convenções: Pokémon GLBs (`rotation_degrees.x = 90.0`, `MODEL_SCALE = 2.5`) e DQT GLBs Y-up (`native_height` de `0.83m` a `3.091m` ajustados para `target_height` de `1.4m` a `3.22m`, com `weapon_follow` em `dqt_orc` e `dqt_cyclops` e `idle_source = "32"`).
   - Fontes e UI existentes: `assets/fonts/kanit/Kanit-BlackItalic.ttf`, `SystemFont` (`Impact`, `Arial`/`Segoe UI` em `FanMenu`), componentes `SlantedPanel` e `SlantedButton` (`-9°`, sombra dura) e `EncounterShatterTransition` (`D-1172`).

> **Regra explícita do criador (Mouse + Ícones canônicos):** *"permita que possa selecionar as opções com mouse também, isso vai pro jogo também, faça questão de usar os icones correspondentes dos tipos categorias e elementos também."*

### Diretriz de Mouse & Ícones (Obrigatória no Pré-Jogo e nas HUDs In-Game)

1. **Suporte completo a Mouse em todas as opções (`Pré-Jogo` + `Jogo`):**
   - Toda lista, botão, aba, slider, drawer e confirmação deve aceitar **Hover** (sincronizando `focused_index` sem duplicar foco com teclado/controle), **Left-Click** (selecionar / confirmar), **Right-Click** (equivalente a `Back / X` para cancelar/voltar), **Double-Click** opcional em listas de seleção e **Drag / Wheel** no palco 3D (`Character Selection`) para girar e aproximar o modelo.
   - **Auditoria do código atual para o DeepSeek atualizar depois:**
     - `FanMenu` (`scripts/ui/fan_menu.gd`): atualmente define `mouse_filter = Control.MOUSE_FILTER_IGNORE` (linha 78) — precisará mudar para `MOUSE_FILTER_STOP` (ou hit-test retangular sincronizado em `_gui_input`), disparando `select(i)` no `InputEventMouseMotion`, `chosen.emit(i)` no `MOUSE_BUTTON_LEFT` e `cancelled.emit()` no `MOUSE_BUTTON_RIGHT` para menus em fan, gaveta de Moves/Itens/Alvos/Táticas e botões de retorno.
     - `MenuList` (`scripts/ui/menu_list.gd`) e `Menus` (`scripts/ui/menus.gd`): adicionar `mouse_filter = MOUSE_FILTER_STOP` nos itens `Label`/linhas para permitir seleção por clique e scroll/hover no menu de pausa e Settings in-game.
     - `StatusScreen` (`scripts/ui/status_screen.gd`): já suporta clique na faixa de Moves (`D-435`), badge de Nature e satchel, e precisará estender o hit-test de clique para trocar o membro do time na lista lateral (`_draw_roster()`) e fechar via clique no botão/botão direito.
2. **Iconografia Canônica Obrigatória (`Elementos`, `Tipos/Categorias` e `Alcances`):**
   - Proibido usar texto genérico solto ou retângulos sem ícone quando houver ícone canônico no projeto:
   - **12 Elementos (`Element.Type` -> `res://assets/ui/icons/elements/<nome>.svg` + cores `StatusScreen.ELEMENT_COLORS` / `ELEMENT_GLYPH_COLORS`):** `neutral` (`Physical`), `fire` (`Fire`), `water_ice` (`Water/Ice`), `electric` (`Electric`), `psychic` (`Psychic`), `nature` (`Poison`), `sound` (`Sound`), `earth` (`Earth`), `wind` (`Wind`), `light` (`Light`), `dark` (`Dark`), `mystic` (`Mystic`).
   - **Tipos / Categorias de Move (`Skill.type_icon_name()` -> `res://assets/ui/icons/move_types/<tipo>.svg` + `MoveIcons.for_move(id)`):** `physical` (`#ef4444`), `magical` (`#0ea5e9`), `guard` (`#cbd5e1`), `dodge` (`#fcb900`), `status` (`#ffffff`, D-1190), `field` (`#22c55e`, D-1190) e ícones customizados como `res://content/moves/media/icon.svg`.
   - **Categorias de Alcance (`res://assets/ui/icons/range/<alcance>.svg`):** `melee`, `mid`, `long`, `area` (omitido em `Kind.STATUS` puro conforme `FanMenu` e `StatusScreen`).
   - **Seleção de Personagem (`Character Selection 3D`):** exibir selos parallelogram com ícone elemental nato ao lado do nome (`Combatant.get_elements()`, D-404/D-414), grade fixa de **12 elementos** estilo SMT/Persona (`D-1166`: `W`/`R`/`–`), tiras segmentadas dos Moves (`D-434`: bloco elemental + tipo + alcance + pips ATB + MP) e cartão de inspeção vivo com watermark SVG e cor de `POWER` (`#b5a5fe` para `MAG`, `#f59e0b` para `STR`/`Status`, D-1188).

---

## 2. Mapa Completo de Navegação do Pré-Jogo

```
[BOOT / TITLE PRESENTATION]
   │  (Input qualquer tecla/clique ou passagem suave; --skip-title pula no debug)
   ▼
[MAIN MENU]  ──(X/Esc opcional)──► [TITLE PRESENTATION]
   ├── PLAY ──────────────────────► [PLAY DRAWER]
   │                                   ├── NEW GAME ──► (Confirmação se houver save, se aplicável) ──► [CHARACTER SELECTION 3D] ──► [LOADING] ──► [CENA DE CAMPANHA]
   │                                   └── CONTINUE ──► (Somente visível/habilitado se persistência existir e for válida) ──► [LOADING] ──► [CENA DE CAMPANHA]
   ├── SETTINGS ──────────────────► [SETTINGS OVERLAY (5 Abas: VIDEO / AUDIO / CONTROLS / GAMEPLAY / ACCESSIBILITY)]
   │                                   └── (X/Esc) ──► (Confirmação se houver alteração não salva ou aplicar imediato) ──► [MAIN MENU]
   ├── CONTROLS (Ajuda rápida) ───► [CONTROLS REFERENCE OVERLAY] ──► [MAIN MENU]
   ├── CREDITS ───────────────────► [CREDITS VIEW (sobre o mesmo palco 3D)] ──► [MAIN MENU]
   └── QUIT GAME ─────────────────► [CONFIRM MODAL ("EXIT CRAWLMON?")] ──► get_tree().quit()
```

---

## 3. Especificação Detalhada de Cada Tela

> **Diretriz tipográfica & estética (D-413, D-417, D-418, D-430):** Toda UI em **Inglês**. Geometria neo-brutalista `-9°`, blocos sólidos `#0d1824` / `#f5f0e1`, acentos `#d7fd6a` (prioridade), `#62d8e7` (destaque/info), `#ff4060` (alerta), sombra dura preta. **Corrigir excesso de peso/bold:** reservar peso pesado apenas para o título principal e marcadores numéricos curtos; usar peso regular/médio (`400`–`600`) em botões, descrições, abas e fichas para leitura confortável. **Zero flashes de tela inteira (D-418).**

1. **BOOT / TITLE PRESENTATION:**
   - Inicialização assíncrona dos catálogos essenciais; câmera em dolly lento revelando o palco 3D sem corte brusco nem clarão na tela.
   - Marca tipográfica `CRAWLMON` integrada ao enquadramento + barra inferior `PRESS ANY KEY` (sem pulsar estroboscópico; pulso suave de borda/sublinhado).
2. **MAIN MENU:**
   - Coluna lateral esquerda angular com `PLAY`, `SETTINGS`, `CONTROLS` (ou dentro de Settings), `CREDITS`, `QUIT GAME`.
   - 5 estados claros por botão: Normal, Foco Teclado/Controle (deslocamento horizontal + barra limão), Hover Mouse, Confirmação (barra de corte direcional), Indisponível.
   - Lado direito aberto para o cenário 3D e composição de personagem(ns) em movimento ambiente sutil.
3. **PLAY FLOW (Drawer contextual sobre a mesma cena 3D):**
   - `NEW GAME` (sempre disponível) e `CONTINUE` (exibido/ativo **somente** quando um backend de persistência real retornar dados válidos).
   - Modais de confirmação apenas quando houver operação destrutiva real.
4. **CHARACTER SELECTION 3D:**
   - **Centro:** Palco 3D com o modelo real instanciado via `CharacterModelLoader` e câmera com enquadramento calculado pelo **AABB/altura real do modelo** (funciona de `Slime 1.4m` a `Cyclops 3.22m`).
   - **Lateral esquerda:** Galeria compacta das espécies elegíveis (conforme decisão do criador — hoje há 6 espécies em `CharacterCatalog`).
   - **Lateral direita:** Ficha tática em blocos escalonados contendo **somente dados canônicos do `CharacterData`**: `display_name`, 6 `raw_stats` (`STR`, `MAG`, `VIT`, `WIS`, `AGI`, `LUK`), badges de `weaknesses`/`affinities` e lista de `loadout.skills` (sem inventar níveis, textos de lore ou Natures não aprovadas).
   - **Rodapé:** Navegação (`←/→` ou `↑/↓`), `Z CONFIRM`, `X BACK`, `Q/E` girar modelo (opcional).
   - **Confirmação:** Câmera aproxima suavemente, toca clipe disponível (`victory` / `attack_special` / `idle` existente no modelo) e inicia transição para carregamento.
5. **SETTINGS (Modular em 5 abas):**
   - **VIDEO:** `Window Mode` (Windowed / Borderless / Fullscreen), `Resolution`, `VSync`, `FPS Cap` (`DisplayServer` / `Engine.max_fps`), `Render Scale` (`viewport.scaling_3d_scale`, verificando compatibilidade real no `gl_compatibility`).
   - **AUDIO:** `Master`, `Music (BGM)`, `SFX`, `UI` (somente ativados se os buses existirem em `AudioServer`, caso contrário marcados como pendentes).
   - **CONTROLS:** Visualização dos atalhos reais (`Arrows` navegar, `Z` Confirm, `X` Menu/Back, `C` Settings, `Space` Evade, `Shift` Guard) e eventual remapeamento seguro (sem alterar defaults sem aprovação).
   - **GAMEPLAY:** `Text Speed` (`Slow / Normal / Fast`, já existente em `GameState`), `Persist Tactics` (conforme previsão documental, marcada como proposta caso não exista flag em `GameState`).
   - **ACCESSIBILITY:** `Reduce Camera Motion`, `Text Scale` (`100% / 115% / 130%`), `High Contrast UI`, `Colorblind/Icon Labels` (não depender só de cor), `Reduce Decorative Motion` (todas identificadas como propostas até implementação).
6. **CREDITS / CONTROLS HELP / CONFIRM & ERROR MODALS:**
   - Cartões deslizantes `-9°` reutilizando o palco 3D ao fundo; modal reutilizável para `Quit`, `Discard Changes` e `Load Error` com mensagem legível.

---

## 4. Três Propostas de Composição Artística (3D + 2D)

| Critério | Conceito A — **TACTICAL STAGE** | Conceito B — **CHARACTER SHOWCASE** | Conceito C — **DUNGEON THRESHOLD** |
|---|---|---|---|
| **Visual** | Palco escuro inspirado no `BattleArena`: chão quadriculado teal, pilares geométricos com aura ciano, névoa baixa e iluminação de recorte. | Palco editorial minimalista: fundo escuro limpo com tipografia gigante atrás do modelo 3D em destaque (câmera próxima). | Entrada/limiar arquitetônico da dungeon 3D (inspirado em `murky_forest_3d_lab`), com vegetação/pedra e profundidade de corredor. |
| **Vantagens** | Reutiliza diretamente linguagem de `BattleArena`; contraste máximo com UI limão/marfim; barato em `gl_compatibility`. | Máximo destaque aos modelos 3D (Pokémon e DQT); transições de Character Select ficam extremamente fluidas. | Cria continuidade direta com a exploração 3D (`D-1181`) e sensação de partida para a expedição. |
| **Limitações / Riscos** | Pode parecer "arena de batalha" antes da hora se não diferenciar iluminação/câmera. | Pode parecer vazio na tela de `Title` se não houver composição cuidadosa de câmera e luz. | Maior custo de draw calls/folhagem no `gl_compatibility`; risco de poluição visual atrás do texto se a névoa/luminância não forem controladas. |
| **Recomendação** | **Recomendado como base V1** pela leveza em `gl_compatibility`, leitura imediata da UI neo-brutalista e reaproveitamento dos shaders/luzes já validados em `BattleArena`. | Ideal se o criador quiser foco total no roster desde o Boot. | Recomendado apenas após a cena 3D definitiva do overworld estar fechada. |

---

## 5. Storyboard de Transições (2D + 3D Coordenados)

1. **Title → Main Menu:** Logo desliza/encolhe suavemente para o topo esquerdo (`0.35 s`, cubic ease-out); câmera faz pan lateral sutil deslocando o foco para a direita; itens do menu entram em cascata diagonal (`-9°`, atraso de `45 ms` por item). **Zero flash.**
2. **Main Menu → Character Selection:** Coluna do menu recua para a esquerda (`0.22 s`); câmera executa dolly + órbita suave até o enquadramento calculado pela altura do primeiro personagem (`0.42 s`); somente ao concluir o bloqueio de transição, os painéis laterais (galeria + ficha) entram pelas bordas opostas e o foco de input é liberado.
3. **Troca de Personagem (dentro do Character Select):** Ficha da direita desliza `24 px` e recalibra dados em blocos escalonados (`0.18 s`); câmera interpola distância/altura alvo pelo AABB do novo modelo (`0.28 s`), evitando troca seca ou corte no topo do `Cyclops` / sobra vazia no `Slime`.
4. **Main Menu ↔ Settings / Credits:** Painéis laterais do menu recuam parcialmente (`opacity 0`, deslocamento `-40 px`); câmera aplica leve zoom-out ou deslocamento vertical para limpar o centro da tela; overlay modular entra por corte diagonal (`0.24 s`). Retorno executa o caminho inverso exato sem recarregar a cena 3D.
5. **Segurança contra Input Rápido (Mashing / Cancelamento):**
   - Estados de transição (`IDLE`, `TRANSITIONING`, `LOCKED_LOADING`) coordenam bloqueio/buffer:
     - Spam de `Confirm` durante transição **não** dispara duas ações nem pula uma tela sem querer.
     - `Back` durante transição não destrutiva reverte o tween atual em curso (`tween_back`) preservando integridade do foco anterior.
     - Alternância mouse ↔ teclado sincroniza sempre um único `focused_index` canônico.

---

## 6. Arquitetura Técnica Proposta para o DeepSeek (Somente Blueprint — Não Criar Ainda)

Organização alinhada ao projeto (`scripts/ui/`, `scripts/autoload/`), **sem criar novos autoloads desnecessários**:

1. **Controlador de Fluxo (`FrontendStateMachine` — nó local da cena de pré-jogo, não autoload):**
   - Estados: `BOOT`, `TITLE`, `MAIN_MENU`, `PLAY_DRAWER`, `CHAR_SELECT`, `SETTINGS`, `CONTROLS`, `CREDITS`, `MODAL_CONFIRM`, `LOADING_CAMPAIGN`.
   - Pilha de retorno segura (`_nav_stack`) garantindo que `Back` restaura tela e índice focado anterior.
   - Guarda de input (`_input_locked: bool`) sincronizada com os tweens de transição e com flag de reversão segura.
2. **Palco & Câmera 3D (`PreGameStage3D` + `PreGameCameraRig`):**
   - Gerencia `Camera3D` por presets (`Marker3D` ou alvos parametrizados: `title`, `menu`, `showcase`, `settings`, `confirm`).
   - **Enquadramento Automático por Geometria:** lê o `AABB` combinado dos `MeshInstance3D` do modelo instanciado por `CharacterModelLoader` e calcula `distance = (half_height / tan(fov_y * 0.5)) * padding` + `target_y = center_y`, garantindo enquadramento perfeito para `Slime`, `Abra`, `Gible`, `Pancham`, `Orc` e `Cyclops`.
   - **Cache Controlado de Modelos:** mantém no máximo 1 modelo ativo + pré-carga opcional do adjacente em memória controlada, liberando nós com `queue_free()` ao sair do `CHAR_SELECT` para respeitar hardware modesto.
3. **Biblioteca de Transições (`UiTransitionKit` — `RefCounted` utilitário):**
   - Helpers reutilizáveis de `Tween` (`slide_skew_in/out`, `stagger_children`, `camera_blend`) respeitando `Accessibility.reduce_motion` (encurta ou converte para cross-dissolve rápido sem mover câmera).
4. **Configurações & Persistência (`SettingsService` / extensão de `GameState`):**
   - Persistência em `user://settings.cfg` via `ConfigFile` (só grava e aplica o que o projeto realmente suportar no momento: `DisplayServer`, `GameState.text_speed`, buses de áudio existentes, `InputMap`).
   - **Persistência de Campanha:** `Continue` consulta `SaveService.has_valid_save()` — enquanto não houver save aprovado e implementado, retorna `false` de forma limpa sem inventar slots falsos.
5. **Carregamento da Campanha (`ResourceLoader.load_threaded_request`):**
   - Pré-carrega a cena de destino aprovada sem travar a thread principal, exibe progresso apenas se ultrapassar limiar perceptível (ex.: `> 250 ms`), valida erro de carregamento exibindo modal legível em caso de falha e só troca de cena após `THREAD_LOAD_LOADED`.
6. **Debug Obrigatório (`D-1204`):**
   - Flags CLI: `--skip-title` (para pular pré-jogo em testes rápidos), `--frontend-state=<estado>` (abrir direto em `char_select` ou `settings` para captura/validação em `< 10 s`).

---

## 7. Dependências e Riscos de Integração

- **Dependência de Decisão (`D-1181` vs `exploration.tscn`):** Hoje `project.godot` abre `exploration.tscn` (2D). Trocar `run/main_scene` e definir qual é a cena de destino do `New Game` depende de aprovação explícita.
- **Ausência de Backend de Save:** `CONTINUE` não pode ser ativado até existir definição e implementação real de persistência (e resolução de `D-316` / `D-324`).
- **Divergência `CharacterCatalog` (6) vs `assets/modelos/` (17):** 11 modelos não têm `CharacterData` (stats, moves, afinidades). A seleção só pode listar personagens com ficha válida ou aguardar criação das fichas restantes.
- **Buses de Áudio:** Necessário verificar/criar `default_bus_layout.tres` (`Master`, `BGM`, `SFX`, `UI`) antes de ligar sliders reais de áudio.
- **Limitações `gl_compatibility`:** Evitar luzes dinâmicas excessivas com sombra e shaders pesados sobrepostos no palco 3D para manter 60 FPS em hardware modesto.

---

## 8. Questões Pendentes para Decisão do Criador

1. **Conceito Artístico (Seção 4):** Qual direção visual prefere para o palco 3D de pré-jogo — **Conceito A (Tactical Stage, recomendado)**, **Conceito B (Character Showcase)** ou **Conceito C (Dungeon Threshold)**?
2. **Fluxo de Entrada (Boot → Menu):** Prefere tela inicial com **"PRESS ANY KEY"** animada antes do menu, ou abrir **diretamente no Main Menu** com a câmera já em movimento? (E o Boot pode ser pulado com qualquer tecla?)
3. **Cena de Destino ao iniciar `New Game` (`D-1181` × `D-324`):** O `New Game` deve entrar diretamente no **overworld 3D (`murky_forest_3d_lab.tscn`)**, numa futura cena de **Hub 3D**, ou manter `exploration.tscn` temporariamente?
4. **Regra da Seleção de Personagem (§7):** O jogador escolhe **apenas o protagonista/líder** (ex.: entre `Abra`, `Pancham`, `Gible` etc.), escolhe **uma equipe inicial completa**, ou um **starter + parceiro fixo**? E quais dos 6 personagens catalogados (ou dos 17 modelos) serão elegíveis na tela inicial?
5. **Persistência e `CONTINUE` / `Save Slots` (§6):** O jogo terá **slot único automático** (estilo *Mystery Dungeon* / roguelite) ou **múltiplos slots**, e este sistema de save entra já nesta fase ou depois da integração visual?
6. **Escopo do Menu Principal e Settings:** Além de `PLAY`, `SETTINGS`, `CREDITS` e `QUIT GAME`, deseja incluir `CONTROLS` como entrada própria ou dentro de `SETTINGS`? E podemos criar `default_bus_layout.tres` com buses `Master / BGM / SFX / UI` para o DeepSeek ligar o áudio?

---

## 9. Plano de Implementação em Etapas Verificáveis (Pós-Aprovação)

- **Etapa 1 — Auditoria & Contratos (Concluída neste documento):** Mapa de fluxo, lista de lacunas e contratos desacoplados.
- **Etapa 2 — Aprovação das Decisões (Pendente):** Criador escolhe conceito artístico, regra de personagem inicial, cena de destino e escopo de save; registro em `docs/decisoes/D-xxx-*.md`.
- **Etapa 3 — Protótipo Navegável Refinado (Visual):** Ajustar o protótipo visual conforme escolhas do criador (tipografia menos carregada, zero flashes, estados de câmera e seleção 3D).
- **Etapa 4 — Infraestrutura Backend (DeepSeek):** Implementar `PreGameCameraRig` (enquadramento por AABB), `SettingsService` (`ConfigFile`), `SaveService` (se aprovado), `ResourceLoader` threaded e flags `--skip-title` / `--frontend-state=`.
- **Etapa 5 — Camada Visual Godot & Transições (Agente Visual):** Construir a cena de pré-jogo 3D + HUDs `-9°` em `CanvasLayer`, conectadas exclusivamente aos sinais dos serviços do DeepSeek.
- **Etapa 6 — Validação, Performance e Cutover:** Executar bateria automatizada `< 1 min` (D-1204), revisão visual em 1280×720, checagem de vazamento de memória ao sair da tela e troca segura de `run/main_scene` somente após aprovação final.

---

## 10. Critérios de Aceitação e Plano de Testes

- **Navegação & Input (`tests/ui/test_pregame_navigation.gd`):** Percorrer todas as telas por teclado (`↑/↓/←/→`, `Z`, `X`, `C`) e por **mouse** (`MouseMotion` + `MOUSE_BUTTON_LEFT` + `MOUSE_BUTTON_RIGHT` para voltar), inclusive em `FanMenu`, `MenuList` e `StatusScreen` in-game, sem perda de foco; spam de `Confirm` e `Back` durante transição não gera estado travado nem chamada dupla.
- **Iconografia Canônica (`tests/ui/test_pregame_icons.gd`):** Validar que todos os personagens elegíveis carregam seus ícones SVGs reais de elementos natos, grade de 12 afinidades (`D-1166`), e Moves com ícones correspondentes de `move_types/*.svg` / `range/*.svg` / `MoveIcons.for_move()`, com zero texturas nulas.
- **Enquadramento 3D (`tests/ui/test_pregame_framing.gd`):** Instanciar todos os personagens elegíveis (`Slime` até `Cyclops`), verificar que o `AABB` projetado pela `Camera3D` cabe integralmente dentro da área útil da viewport sem cortar cabeça/pés nem invadir os painéis laterais.
- **Persistência & Settings (`tests/ui/test_pregame_settings.gd`):** Alterar valores em `VIDEO / AUDIO / CONTROLS / GAMEPLAY / ACCESSIBILITY`, salvar em `ConfigFile` temporário, recarregar e confirmar valores idênticos; verificar que `CONTINUE` permanece bloqueado quando não há save válido.
- **Carregamento & Memória:** Transição até a cena de campanha via `load_threaded_request` sem travamento perceptível e com contagem de nós órfãos/modelos liberados = 0 (`D-1204`, execução individual `< 10 s`).

---

## 11. Exigências Adicionais de Validação (§18 — Assets, Multi-Resolução e Fidelidade Visual)

> **Regra de Governança (§18.3):** Aprovação visual **não pode ser presumida** pelo Antigravity nem pelo DeepSeek. Esta seção documenta as provas técnicas e o protocolo de validação; a integração ao jogo principal depende de avaliação explícita e aprovação do criador.

### 11.1. Compatibilidade Real de Assets no HTML e Proveniência Canônica (`§18.1`)

Caminhos `res://` do Godot não são resolvidos diretamente em iframes/navegadores comuns (`<agent-embed>`). Para eliminar erros 404, requisições bloqueadas e imagens quebradas sem alterar os arquivos originais do repositório, o script de empacotamento (`build_pregame_assets.py` -> `build_pregame_html.py`) lê diretamente os **38 assets canônicos** do projeto, replica pixel a pixel o recorte `PortraitIcon` (`scripts/ui/portrait_icon.gd`, `D-1093` / `D-1167`), embute os **23 SVGs vetoriais oficiais** e gera data-URIs WebP nítidas preservando a proporção exata de cada asset (`maxAspectErr = 0.000`).

| Grupo | Qtd | Origem Real no Repositório (`res://`) | Regra / Tratamento Aplicado |
|---|---|---|---|
| **Retratos Canônicos Pokémon** | 3 | `res://sugimori/por_nome/{abra,pancham,gible}.png` | Recorte exato `FACE_CROP` (`Rect2(300,120,320,360)`, `(300,40,680,760)`, `(30,100,490,560)`) + fundo `BG_STOPS` (`#77c7d7` → `#e7f7b7`), 1:1 (`128×128`), `D-1093`. |
| **Retratos Canônicos DQT** | 3 | `res://personagens/portraits/{slime,orc,cyclops}.png` | Proporção nativa 1:1 (`256×256` → `128×128`), mesmo degradê `#77c7d7` → `#e7f7b7`, `D-1093` / `D-1167`. |
| **Artes de Corpo Inteiro** | 6 | `res://sugimori/por_nome/{abra,pancham,gible}.png` e `res://sugimori/dqt_web/fandom/DQVIII_{Slime,Orc,Cyclops}.png` | Trim de alpha preservando aspect-ratio original (altura/largura máx. `420 px`) sobre o palco 3D rotativo (`D-1167`). |
| **Ícones Elementais (SVG)** | 12 | `res://assets/ui/icons/elements/{neutral,fire,water_ice,electric,psychic,nature,sound,earth,wind,light,dark,mystic}.svg` | SVGs inline 1:1 com cores `StatusScreen.ELEMENT_COLORS` / `ELEMENT_GLYPH_COLORS` (`D-1166`). (`physical.svg` e `water.svg` existem como aliases idênticos em disco.) |
| **Ícones de Tipo de Move (SVG)** | 7 | `res://assets/ui/icons/move_types/{physical,magical,guard,dodge,status,field}.svg` e `res://content/moves/media/icon.svg` | Injetados em toda tira de Move (`D-434`) e cartão vivo (`D-1188` / `D-1190`). |
| **Ícones de Alcance (SVG)** | 4 | `res://assets/ui/icons/range/{melee,mid,long,area}.svg` | Omitidos em `Kind.STATUS` puro conforme `FanMenu` e `StatusScreen` (`D-416`). |
| **Capturas Aprovadas de HUD** | 3 | `res://test_captures/aff_final.png`, `res://test_captures/05_status_screen_abra_detail_z.png`, `res://test_captures/d1134_menu_orbit.png` | Usadas apenas no comparador lado a lado **`Fidelity Proof (§18.3)`**, mantendo os PNGs originais intactos. |

- **Regra para o DeepSeek no Godot:** usar exatamente `PortraitIcon.get_icon(character_id)` (`D-1093`), `MoveIcons.for_move(move_id)` e `StatusScreen._get_element_icon(elem)`, configurando todos os `TextureRect` de retrato e ícone com `expand_mode = EXPAND_IGNORE_SIZE` + `stretch_mode = STRETCH_KEEP_ASPECT_CENTERED` para impedir qualquer distorção ao mudar de resolução.

### 11.2. Validação Multi-Resolução Verificada (`1280×720`, `1600×900`, `1920×1080` e `960×540`)

Validado ao vivo em Chromium headless (Playwright) sobre o protótipo `prototypes/pre_game_hud.html`, com o pior caso de altura (**Gible — 8 Moves em 2×4 + Cartão Vivo + Botão Confirm**) exibindo `0` erros de console, `0` erros de página, `0` imagens quebradas e **0px de sobreposição**:

| Preset de Janela | Sobreposições (`Roster ↔ Palco ↔ Ficha`) | Gap Lateral (`Roster→Palco` / `Palco→Ficha`) | Folga Abaixo do `Confirm` | Imagens Quebradas | Erro Máx. Proporção | Preservação de Foco (`Menu→Settings→Esc`) |
|---|---|---|---|---|---|---|
| **Compacta (`960×540`)** | `0 px` | `46 px` / `46 px` | `+40 px` | `0 / 7` | `0.000` | Preservado (`menuIndex = 1`) |
| **HD Base (`1280×720`)** | `0 px` | `63 px` / `63 px` | `+94 px` | `0 / 7` | `0.000` | Preservado (`menuIndex = 1`) |
| **HD+ (`1600×900`)** | `0 px` | `81 px` / `81 px` | `+157 px` | `0 / 7` | `0.000` | Preservado (`menuIndex = 1`) |
| **Full HD (`1920×1080`)** | `0 px` | `98 px` / `98 px` | `+219 px` | `0 / 7` | `0.000` | Preservado (`menuIndex = 1`) |

- **Contrato de layout responsivo no Godot (`DeepSeek`):**
  1. Manter `project.godot` em `window/stretch/mode="canvas_items"` com `aspect="keep"` e margens/larguras adaptativas por proporção de viewport (`roster_w <= 22%` da largura útil, `sheet_w <= 37%`, deixando `>= 36%` centrais livres para a projeção AABB da `Camera3D`).
  2. Garantir no `Character Select` que controles de rotação central permaneçam em linha única sem quebrar linha mesmo a `960×540`.
  3. Toda transição (`MainMenu ↔ Settings`, `MainMenu → PlayDrawer → CharSelect`) deve salvar `(screen_id, focused_index, active_tab)` na `_nav_stack` para restaurar foco exato no retorno via mouse (`Right-Click`) ou teclado (`X` / `Esc`).

### 11.3. Prova de Fidelidade Visual Lado a Lado (`§18.3`)

O protótipo embute a aba **`Fidelity Proof (§18.3)`** comparando lado a lado as novas telas do Pré-Jogo contra capturas reais aprovadas do Crawlmon, reutilizando explicitamente:

| Sistema Visual Reutilizado | Uso no Novo Pré-Jogo (`pre_game_hud.html`) | Origem Real Aprovada no Crawlmon |
|---|---|---|
| **Tipografia & Hierarquia** | Títulos condensados caixa alta (`600–700`) + métricas monospace (`ATB`, `MP`, `W/R`, `AABB`) sem excesso de peso no corpo | `StatusScreen` (`aff_final.png`), `FanMenu` |
| **Paleta Cromática Canônica** | Azul-marinho `#0d1824` / `#091b26`, marfim `#f5f0e1`, limão `#d7fd6a`, ciano `#62d8e7`, coral alerta `#ff4060` + cores `ELEMENT_COLORS` | `StatusScreen` (`aff_final.png`), `BattleHud` (`d1134_menu_orbit.png`) |
| **Geometria & Sombras** | Painéis e badges inclinados `-9°` / `-6°`, bordas `#000000` e sombra sólida deslocada (`4px–7px`, zero blur/glassmorphism) | `SlantedPanel`, `SlantedButton`, `FanMenu`, `StatusScreen` |
| **Retratos Canônicos** | Retratos quadrados `1:1` (`D-1093` / `D-1167`) com gradiente `#77c7d7 → #e7f7b7` no roster lateral e cabeçalho da ficha | Coluna esquerda do time em `StatusScreen` (`aff_final.png`) |
| **Grade de 12 Afinidades (`D-1166`)** | Mesma ordem dos 12 elementos com `W` (`#ff746c`), `R` (`#63d9ec`) e neutros atenuados (`opacity 0.28`) | Rodapé da área de status em `StatusScreen` (`aff_final.png`) |
| **Tiras & Cartão Vivo de Moves** | Tiras segmentadas (`D-434`: coluna elemental + pips ATB ciano + MP) + cartão expandido com watermark SVG, chips inclinados e cor lilás `#b5a5fe` (MAG) vs âmbar `#f59e0b` (STR) | `StatusScreen` + Dossiê `Z` (`05_status_screen_abra_detail_z.png`, `D-416`, `D-419`, `D-1188`, `D-1190`) |

### 11.4. Contrato de Teste Headless Pós-Aprovação (`tests/ui/test_pregame_section18.gd`)

Quando o criador aprovar o visual e autorizar a etapa de implementação no Godot, o DeepSeek deve incluir em `tests/ui/test_pregame_section18.gd` (execução `< 10 s`, `D-1204`) a verificação automática nas 4 resoluções (`Vector2i(960, 540)`, `(1280, 720)`, `(1600, 900)`, `(1920, 1080)`):
1. Todas as `TextureRect` de retratos (`PortraitIcon`) e os 23 ícones SVG (`elements/`, `move_types/`, `range/`, `media/icon.svg`) carregam com `texture != null` e aspect-ratio preservado (`abs(ratio_tex - ratio_rect) < 0.02`);
2. `roster_rect.intersects(stage_3d_rect) == false` e `stage_3d_rect.intersects(sheet_rect) == false`;
3. `confirm_button.get_global_rect().end.y <= viewport_height` inclusive no personagem com maior lista de Moves (`Gible`, 8 Moves);
4. Navegação `MainMenu → Settings → Back` e `MainMenu → PlayDrawer → CharSelect → Back` preserva exatamente o controle focado e índice selecionado tanto via eventos de teclado quanto `InputEventMouseMotion` / `InputEventMouseButton`.

### 11.5. Protótipos HTML para Avaliação Visual do Criador

- `prototypes/pre_game_hud.html` — Protótipo aprovado preservado integralmente (`SHA-256: 88bebc8806559552c1e06976eb59ddb7d0f099344a542d85cd96b581f54ff4c2`).
- `prototypes/pre_game_hud_s18_validacao.html` — Cópia dedicada com a **Central de Validação (§18)**: `GodotResBridge` com todos os 40 assets reais do repositório (`6` retratos `D-1093`, `6` artes Sugimori/DQT, `23` ícones SVG canônicos, `5` capturas HUD aprovadas de `test_captures/`) e Lupa `1x/2x/4x` (§18.1), Matriz `960×540` / `1280×720` / `1600×900` / `1920×1080` + modo `X-Ray CAD` + `Run Focus & Transition Macro` (§18.2), e Estúdio de Fidelidade Visual lado a lado + cortina interativa `A/B Wipe` para todas as 6 telas do pré-jogo com pinos sincronizados `①..⑦` (§18.3). Aprovação visual exclusiva do criador antes de qualquer implementação no projeto principal.
