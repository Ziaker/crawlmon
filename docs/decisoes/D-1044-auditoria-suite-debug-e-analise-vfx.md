# D-1044 — Auditoria da entrega anterior (D-1042) e suíte completa de análise visual de VFX para agentes de IA

- **Data:** 2026-11-09
- **Área:** Combate / Debug / VFX / Testes Automatizados / Documentação
- **Origem:** Conversa (solicitação e aprovação do criador).
- **Status:** **Decisão aprovada e implementada**.

## O que o criador disse (literal)

> "quais outras melhorias o debug precisaria, agora em questões de analise de efeitos visuais"
> "prossiga com todos, atualize cada documento para levar estes testes em consideração MAS ANTES eu quero que faça uma checagem pelas mudanças que fez na entrega anterior, vendo o que implementou mal ou esqueceu e corrigindo"

## Decisão

### Parte 1 — Auditoria e correção da entrega anterior (D-1042)
Antes de avançar, todas as falhas e omissões da entrega anterior foram identificadas e corrigidas:
1. **Dano de teste e K.O. com reação visual real (`BattleDebug` F9/F10 e ação `damage` em `vfx_room.gd`):** na entrega anterior, `take_damage()` era chamado diretamente sem emitir `battle.hit_resolved`, o que mudava o HP em silêncio sem tocar o clipe `damage`, flash, texto flutuante, hit-stop, recuo ou lançamento balístico de K.O. (D-049/D-160/D-166). Corrigido para passar pelo pipeline completo de `hit_resolved` / `play_hit`.
2. **Ficha visual de fases por Move (`Skill.visual_phases()` e `--isolate-phase`):** na entrega anterior, os cenários `fase_*` apenas pausavam em `Tackle` ou `Fire Bullet` fixos, ignorando `--move=` e sem exibir a descrição visual de cada fase da ficha do Move. Agora `Skill` define a descrição visual estruturada das fases (`windup`, `release`, `travel`, `strike`, `impact`, `return`) para cada Move, os cenários `fase_windup`, `fase_release`, `fase_trajeto`, `fase_golpe`, `fase_impacto` e `fase_retorno` respeitam qualquer `--move=<Move>` passado, e `--isolate-phase=<fase>` exibe e valida a ficha visual da fase no painel e no log/stdout (`FICHA_FASE`).
3. **Catálogo universal de Moves na `vfx_room.gd` (D-235):** antes apenas `Tackle`, `Armored Bulk` e `Drain Spear` tinham fallback manual quando uma espécie não havia sido sorteada no encontro. Agora `_seed_full_catalog()` popula `_catalog` com todos os Moves de todas as espécies (`EnemyFactory.ENEMY_SPECIES_POOL`, `Skill.basic()`, `fire_skills()`, `library_skills()`, `element_skills()`, `smt_skills()`, `DrainSpearMove` e `Bubble Shield`), garantindo que qualquer combatente possa usar qualquer Move do jogo.
4. **Ordem de recarga e seleção de alvos em cenários com múltiplos inimigos (`_fire` / `_reload_keep_selection`):** corrigido o truncamento de índices de unidades quando `_reload_keep_selection()` rodava antes de `_prepare_world()` recriar os inimigos extras (`E2`, `E3`).
5. **Itens faltantes das 10 melhorias de debug de combate:**
   - `--stdout-trace` e `--summary-json` em `BattleTrace` e `vfx_room.gd` (emite JSON estruturado no `stdout` com hits, dano, HP antes/depois, fases atingidas, nós de VFX ativos e anomalias).
   - `--strict-asserts` em `BattleTrace` (falha imediata com código de saída `1` ao detectar qualquer anomalia de invariante lógica ou espacial).
   - Fila determinística por *ticks* físicos (`--acts-ticks=` e `--step-ticks=N`).
   - *Snapshot & Rollback* em memória (`Battle.save_state()` / `Battle.restore_state()` e `Combatant.save_state()` / `Combatant.restore_state()`).
   - Runner dedicado de simetria D-235 e matriz de cobertura de Moves (`--test-d235` e `--test-all-moves-matrix` / `tests/battle/run_agent_combat_tests.py` com asserções reais de telemetria em vez de busca superficial de rótulo).

### Parte 2 — 10 Ferramentas de Análise de Efeitos Visuais (VFX Debug)
Implementadas na sala de combate e debug (`scripts/debug/vfx_room.gd` e `scripts/combat/battle_debug.gd`):
1. **Auditor Automático de "Restos e Órfãos" (`--audit-leaks`):** verifica `BattleFx` após o término do ataque (`RETURN` + margem) e reporta qualquer nó residual, malha/partícula visível com `alpha > 0` ou `OmniLight3D` órfã (`[vfx_audit] leaks=0`).
2. **Reticulado de Medição e Régua de Tela (`--scale-overlay`):** desenha círculos concêntricos em pixels (`50px`, `100px`, `200px`) centrados na projeção 2D do alvo para validar tamanho em tela na distância de 30–37 m, além de réguas métricas 3D (`0.5m`, `1.0m`, `1.2m` D-1013, `2.0m`, `2.5m` D-1033).
3. **Gerador Automático de Folha de Prova das 4 Fases (`--proof-sheet=<caminho.png>`):** executa o Move nas vistas Normal e Espelhada capturando automaticamente *Wind-up*, *Release*, *Trajeto* e *Impacto* (D-308) e monta uma folha de contato `2×4` com carimbo de tempo, contagem de nós e caixa delimitadora em pixels.
4. **Inspetor de Ancoragem e Velocidade de Osso (`--bone-probe`):** rastreia ossos de mão/cabeça/ponta da arma em tempo real, desenhando o vetor velocidade 3D e registrando no log o pico de velocidade do swing vs. instante do golpe.
5. **Modo Solo / Mute por Componente Individual (`--solo-node=<padrão>` / `--mute-node=<padrão>` e árvore na aba Câmera/VFX):** permite isolar ou silenciar nós filhos específicos gerados dentro de `BattleFx`.
6. **Câmera Lenta com Foco Fechado no Ponto de Contato (*Impact Macro Cam*, `--cam=5` ou `--cam=macro`):** câmera teleobjetiva (`FOV 15°`) travada no ponto de impacto do alvo (`target.pos + Vector3(0, 1.2, 0)`), reduzindo automaticamente a velocidade para `0.05x` na janela de impacto.
7. **Visualizador de *Overdraw* e Densidade de Transparência (`--overdraw`):** aplica material de diagnóstico aditivo térmico às geometrias de VFX para expor acúmulo excessivo de transparências e estouro de branco.
8. **Teste de Silhueta e Contraste com Fundos Alternativos (`--bg=arena|gray|black|white`):** alterna o fundo entre a arena real, cinza neutro 50%, preto puro e branco puro preservando combatentes e VFX.
9. **Gráfico e Detector da Curva de Envelope de Opacidade (`--envelope-graph`):** monitora a evolução de `alpha` e escala dos nós de VFX quadro a quadro, desenhando o envelope na tela e acusando `[POP_DETECTED]` no log se uma camada sumir abruptamente (`delta_alpha > 0.5` em 1 quadro).
10. **Comparador Visual A/B (`--diff-with=<referencia.png>`):** compara o quadro capturado (`--shot`) com uma imagem de referência, gerando imagem de diferença em magenta (`*_diff.png`) e reportando `RMSE` e percentual de pixels alterados no `stdout`.

### Parte 3 — Atualização Documental Obrigatória
Atualizados `AGENTS.md`, `docs/REGRAS_DO_JOGO.md`, `docs/vfx/PROTOCOLO_VFX_OBRIGATORIO.md`, `docs/vfx/FERRAMENTAS_VFX.md`, `docs/decisoes/D-1042-suite-debug-e-cenarios-de-teste-para-agentes.md` e `docs/decisoes/README.md` para exigir o uso dessas ferramentas pelos agentes de IA sempre que trabalharem em combate ou VFX.

## Ambiguidades em aberto

Nenhuma.

## Estado no código

Implementado em `scripts/debug/vfx_room.gd`, `scripts/combat/battle_debug.gd`, `scripts/combat/battle_trace.gd`, `scripts/combat/battle.gd`, `scripts/combat/combatant.gd`, `scripts/data/skill.gd` e `tests/battle/run_agent_combat_tests.py`.

> **Complemento D-1154 (2026-11-11):** a fonte canônica dos eventos e campos de telemetria é **`docs/TELEMETRIA.md`**. Leia antes de usar a suíte; em especial `queue.started` (o Move começou) vs. `queue.lost` (vaga descartada).
