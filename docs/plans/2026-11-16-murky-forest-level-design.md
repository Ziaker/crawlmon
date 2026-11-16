# Murky Forest — Level Design de verdade (Planejamento)

> **Mapa novo (D-1256)** — Para o escopo de planta e ambientação, use o [prompt de implementação visual](PROMPT_IMPLEMENTACAO_VISUAL_MURKY_FOREST.md). A Murky Forest será autoral, construída do zero, com os três tratamentos visuais no mesmo mapa. As referências à planta física anterior neste plano descrevem o recorte original.

> **Para execução:** usar a skill `executing-plans`, uma tarefa por vez, com checagem entre elas.
> **Status: pronto para execução.** Portões todos respondidos em D-1245 (portas/descanso/gating/áudio), D-1246 (direção de revisitas), D-1247 (arco como marco, sem persistência entre expedições, recompensa só de descoberta) e D-1248 (gatilho e ordem). Nenhuma decisão de valor numérico, cor ou tempo foi inventada.

**Goal:** fazer da Murky Forest a expedição que o jogador conhece melhor — e por isso quer revisitar. Na primeira ida ele aprende a ler a floresta; nas seguintes reconhece o que mudou, antecipa encontros e alcança lugares antes inacessíveis.

**Architecture:** blockout de salas/corredores em primitivas CSG primeiro, validado por métricas do controlador/câmera e por caminhada real; a camada de eventos/ocupação entra como **dado sobre geometria estável**, não como geometria nova a cada visita. Duas escalas de retorno: dentro da mesma expedição (estado persistente, R36-Q3) e em nova expedição a partir do Hub (R29-Q3/R30-Q4). Primeiro recorte: duas expedições ligadas pelo Hub, usando corredor, abrigo da Super Poção e arco.

**Tech Stack:** Godot 4.7.2, GDScript, `CSGBox3D` (protótipo), `NavigationRegion3D`, câmera terceira pessoa D-1023, `gl_compatibility`, CLI `--scenario=<id> --summary-json`.

---

## 1. Contexto e restrições

| Fonte | O que governa aqui |
|---|---|
| D-1181 / D-1208 | Murky Forest é o overworld 3D principal; ciclo Hub → expedição → Hub. |
| D-1023 | Câmera SMT III: 3,4 m/0,85 m/8° solo, 6,2 m/1,5 m/22° grupo; triângulo 0,9 m / 1,7 m; navmesh manual em L (3 polígonos). |
| D-1028 | 1 u = 1 m; célula 3 m; corredor 6 m; parede 4,2 m; copa 5,5 m; toon; saída verde. |
| D-1133 / D-1151 | Cômodo leste; 3 salas ao sul (Cyclops+amuleto, Super Poção, Orc); portas de 2 m; provas por teleporte. |
| D-1082 / D-1083 | Folhagem ancorada, fade de oclusão, luz escura e menos contrastada, sem azul novo. |
| D-316 / D-317 | Descanso e expedição de 5 andares: **pendentes no 3D** (D-1245 mantém descanso fora). |
| D-1245 | Medir portas e alargar se necessário; gating suave; áudio fora. |
| GDD §7.20–§7.27 | R29-Q2 eventos com consequência; R29-Q3 novas expedições; R30-Q2 consequências na expedição atual; R30-Q4 incentivo para repetir; R32-Q4 revelação gradual; R33-Q3 extensão variável; R33-Q4 pistas de salas secretas; R34-Q2 prioridade de encontros/eventos; R36-Q2 eventos opcionais para o chefe; R36-Q3 estado persistente **na mesma expedição**. |
| D-235 / D-1204 | Nada depende de personagem/lado; todo teste < 1 min (mire < 10 s). |
| D-1154 | Telemetria cobre **só combate**; sem `GameTrace` de overworld — prova é por auditoria/captura. |

### Achados da auditoria

1. O mapa é um **lab**, não um nível: sem caminho crítico, curva de tensão, marcos ou gating.
2. **Risco métrico:** portas de 2 m (D-1151) podem não acomodar o triângulo (0,9 m + 1,7 m + Orc 2,1 m). Medir antes de desenhar.
3. Folhagem/luz (D-1082/1083) foram aplicadas antes da validação do fluxo — ordem invertida pela skill `level-design`.
4. Navmesh manual de 3 polígonos (D-1023) não cobre salas novas; reorganizar sem bake quebra seguidores/inimigos.
5. **Geometria nova** citada na proposta (arco de pedra sobre o corredor, passagem soterrada com entrada inferior, posto de vigia elevado) **não existe** hoje e impacta câmera (6,2 m / 22°, raycast) e navmesh. É acréscimo de escopo, não "reorganizar".

## 2. Portões (🚦 — não escolher sozinho)

**Respondidos:** D-1245 — portas (medir), descanso (pendente), gating (suave), áudio (fora). D-1246 — direção de revisitas aprovada. D-1247 — E3 (recompensa só de descoberta), E4 (nenhuma persistência entre expedições), E5 (só o arco como marco; nível inferior e posto de vigia para fase 2), E6 (direção aprovada, não spec fechada).

**E1/E2 respondidos em D-1248:** gatilho = **fala curta no Hub + marca no cenário** (diegético, sem UI nova); ordem = **1ª aprender, 2ª novidade, sem tranca** (evento opcional para o chefe, R36-Q2). Texto da fala, conteúdo da marca e quantidade de eventos seguem para a implementação — sem inventar regra nova.

## 3. Estrutura proposta

### 3.1 Espaço físico (base estável)

```
[entrada] --(corredor/arco)--> [dossel] --(abrigo)--> [Cyclops+amuleto]
                                    |                      |
                                    +--> [nicho opcional]   +--> [Orc] --> [saída verde]
```

As salas de D-1133/D-1151 continuam como **palco**. O que muda entre visitas é a **ocupação** (quem está lá, o que ficou, que pista apareceu), não a geometria.

### 3.2 Primeiro recorte — duas expedições (🚦 E1–E5)

| Visita | O que mudou | O que faz valer a volta |
|---|---|---|
| **1ª expedição** | Aprender a patrulha, o abrigo da Super Poção e o risco do Amuleto perto do Cyclops. Ver o arco de pedra sobre o corredor. | Sair com um lugar específico que ainda quer alcançar. |
| **Volta com situação nova** | O abrigo aparece ocupado/abandonado; pegadas, mochila caída ou visitante além do arco — **conteúdo sujeito a E1/E2**. | Objetivo muda: procurar, escolher abordagem ou seguir pista. Recompensa é a **descoberta**, não item/recruta (D-1247). |
| **Outros exploradores** | A sala do Orc virou passagem de outro grupo; relato sobre o arco. | Circular pela floresta dá vantagem concreta de leitura — sem posto de vigia neste recorte (D-1247). |

Curva de intensidade do andar: `0.1 → 0.4 → 0.15 → 0.7 → 0.9 → 0.1` (dente de serra). Ramal opcional fora do caminho crítico; eventos são opcionais para o chefe (R36-Q2).

## 4. Tarefas

### Task 0 — Registrar decisões aprovadas
**Files:** `docs/decisoes/D-1245-*.md` (feito), `docs/decisoes/README.md` (feito), `docs/REGRAS_DO_JOGO.md` (feito).
1. Após E1–E6, criar `D-xxx` novo com as frases literais do criador.
2. **Expected:** nenhum `.gd`/`.tscn` alterado nesta tarefa.

### Task 1 — Medir as métricas (teste primeiro)
**Files:** criar `tests/exploration/test_mf_layout_metrics.gd`; referência `tests/exploration/test_follower_speed.gd`.
1. Teste que falha: vão de porta ≥ triângulo + margem; corredor ≥ 6 m.
2. Rodar headless e confirmar FAIL.
3. Delegar ao DeepSeek via `ds-run.mjs` a leitura das constantes de `scripts/debug/third_person_3d_lab.gd` e `murky_forest_3d_lab.gd`, emitindo `proof=` + `patch=` com a tabela de métricas.
4. Revisar com `ds-compliance.mjs`; reaplicar — **Expected: PASS** com números medidos.

### Task 2 — Blockout do andar (🚦 E5)
**Files:** modificar `scripts/debug/murky_forest_3d_lab.gd`, `scenes/debug/murky_forest_3d_lab.tscn`.
1. Delegar ao DeepSeek (`ds-run.mjs`) a geometria CSG do grafo da §3.1 + portas dimensionadas na Task 1. Briefing contém **só** decisões aprovadas.
2. Exigir `proof=`/`patch=`; revisar hunks: nenhuma exceção por personagem/lado (D-235).
3. Rodar `test_mf_layout_metrics.gd` — **Expected: PASS**.
4. Captura greybox `docs/referencias/exploracao/3d/mf_layout_blockout.png` (normal + espelhada).

### Task 3 — Navegação e caminhada real
**Files:** criar `tests/exploration/test_mf_room_graph.gd`.
1. Teste que falha: grafo alcançável e travessia de todas as portas **sem teleporte**.
2. Delegar bake da `NavigationRegion3D` a partir dos colliders (D-1023).
3. Rodar `MF_LAYOUT_WALK` (Task 6) — **Expected:** `wall_hits=0`, `cam_inside=0`, `cam_close_frames=0`, `path_min>=2`, `stack_pairs=0`, portas `near/visible/used=true`.
4. Se falhar: corrigir o blockout, não o teste (D-1154 §1.4).

### Task 4 — Eventos e ocupação (E1–E4 resolvidos em D-1247/D-1248)
**Files:** modificar o lab (tabelas `BEATS` / `ROOM_DATA` / `VISIT_DATA`).
1. Beats da §3.2 como dado: sala, tipo (`teach`/`combat`/`rest`/`climax`), intensidade, evento de revisita e persistência.
2. Fala curta no Hub + marca no cenário como gatilho (D-1248); 1ª expedição ensina, 2ª traz novidade, sem tranca. Nada de "novo evento" inventado além disso; sem recompensa nova e sem persistência entre expedições (D-1247).
3. Validar curva com respiro antes do clímax; evento nunca é pré-requisito do chefe (R36-Q2).
4. **Expected:** saída determinística com sala/tipo/intensidade/evento; sem `GameTrace` novo.

### Task 5 — Legibilidade e marcos (arco aprovado em D-1247)
**Files:** modificar o lab; capturas em `docs/referencias/exploracao/3d/`.
1. Âncora do caminho: portal verde (D-1028) e **arco de pedra como marco (D-1247)**; paliçada de raízes; anéis D-1086; minimapa D-1027 coerente. **Não** incluir passagem inferior nem posto de vigia (fase 2).
2. Auditoria visual em tamanho real: `--scale-overlay`, fundos neutros, duas vistas; medir legibilidade do marco a 9 m.
3. **Expected:** o jogador consegue dizer o próximo objetivo sem olhar o minimapa.

### Task 6 — Cenário de debug < 10 s
**Files:** modificar `scripts/debug/murky_forest_3d_lab.gd` (convenção de `scripts/hub/hub_3d_lab.gd:14`).
1. `--scenario=MF_LAYOUT_WALK --summary-json --quit` com `rooms`, `doors`, `metrics`, `beats`, `audit`.
2. `--scenario=MF_LAYOUT_SHOT --shot=<path>` para prova visual.
3. **Expected:** `__headless --path . res://scenes/debug/murky_forest_3d_lab.tscn -- --scenario=MF_LAYOUT_WALK --summary-json --quit` termina < 10 s, `exit=0`, JSON válido.

### Task 7 — Revestir e auditar (por último)
**Files:** modificar o lab (D-1082/D-1083).
1. Reaplicar folhagem/oclusão/luz ao blockout validado.
2. Auditoria: `wall_hits=0`, `cam_inside=0`, `path_min`, `stack_pairs`.
3. Entregar vídeo curto (normal + espelhado) e folha de contato; declarar o que **não** foi verificado (60 fps, mobile/web, resoluções).

## 5. Divisão de trabalho

- **Eu:** direção espacial, métricas, curva, marcos, luz/foliagem, auditoria visual e revisão de `.patch`.
- **DeepSeek V4.1 Flash, sempre via `ds-run.mjs`:** todo GDScript de blockout, navmesh, dados de visita e cenários de debug. Nunca afirmar delegação sem `proof=` e `patch=` reais.
- **Nada de commit/push sem autorização.**

## 6. Fora de escopo

Áudio (D-1245); geração procedural 3D (D-1181); pontos de descanso (D-1245); combate, Moves, VFX de batalha, HUD, 2D e regras de atributo; bioma além de `murky_forest`.

## 7. Handoff

Com D-1245 a D-1248 registrados e todos os portões respondidos: executar com `executing-plans`, uma tarefa por vez. Opções: **(1)** nesta sessão com checagem entre tarefas; **(2)** sessão separada em worktree.
