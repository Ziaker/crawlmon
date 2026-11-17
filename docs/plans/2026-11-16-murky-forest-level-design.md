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
2. Auditoria visual em tamanho real: duas vistas; medir legibilidade do marco a 9 m.
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
3. Entregar vídeo curto (normal + espelhado) e folha de contato.

## 5. Divisão de trabalho

- **Eu:** direção espacial, métricas, curva, marcos, luz/foliagem, auditoria visual e revisão de `.patch`.
- **DeepSeek V4.1 Flash, sempre via `ds-run.mjs`:** todo GDScript de blockout, navmesh, dados de visita e cenários de debug. Nunca afirmar delegação sem `proof=` e `patch=` reais.
- **Nada de commit/push sem autorização.**

## 6. Fora de escopo

Áudio (D-1245); geração procedural 3D (D-1181); pontos de descanso (D-1245); combate, Moves, VFX de batalha, HUD, 2D e regras de atributo; bioma além de `murky_forest`.

## 7. Handoff

Com D-1245 a D-1248 registrados e todos os portões respondidos: executar com `executing-plans`, uma tarefa por vez. Opções: **(1)** nesta sessão com checagem entre tarefas; **(2)** sessão separada em worktree.

## 8. Divergências visuais finais (implementação v9, câmera real)

Referências consultadas: as três pranchas revisadas (`murky-forest-v2-opcao-1-copa.png`, `...-2-vistas-laterais.png`, `...-3-desnivel.png`), todas do mesmo mapa autoral (D-1256). Prova: `docs/referencias/exploracao/3d/mf_v9_prancha.png`, capturada no ponto `prancha` (13.5, 2.0, −10.0; yaw 90; pitch 6).

| Região | Prancha | Câmera real (jogo) | Divergência |
| --- | --- | --- | --- |
| Marco do arco | Arco de pedra isolado, atravessando o corredor | Arco em x=6.5, colunas no eixo Z (v5/v9) | Nenhuma na vista principal; nas primeiras versões ele ficou alinhado ao portão (v3–v6) e foi reposicionado |
| Aberturas na copa (prancha 1) | Feixes de luz atravessando a copa até o piso | 3 aberturas com disco emissivo, cone aditivo e `SpotLight3D` (v12) | Implementado em v12; `mf_v12_prancha.png` mostra os feixes. Antes a copa era uma caixa escura |
| Saída | Não aparece nas pranchas | Portal verde (D-1028) existe e é funcional, em x=17.7 | **Divergência mantida**: não foi removido (é a saída da sala); só suavizado (emission 1.1→0.28, luz 0.45→0.25). Fora do enquadramento da vista `prancha` |
| Luz / penumbra | Copas e fundo legíveis | exposure 0.88→1.02, ambient 0.95→1.10, fog 0.022→0.017 | **Divergência registrada**: D-1083 pedia mais escuro; D-1256 (posterior) prevalece |
| Desnível (prancha 3) | Quebra de nível no cenário | Faixa baixa de mata além da paliçada, camada 9 | **Divergência registrada**: é somente fundo cenográfico; o piso jogável e a navegação continuam em y=0 |
| Placas de nome | Ausentes | Nameplate "SLIME" aparecia na captura (D-1074/D-1105) | Ocultado **só no modo captura** desde v9 (`_capture_begin`); o jogo continua igual |
| Interface do lab | Ausente | Marcadores amarelos/"?" e faixa de instruções aparecem na captura | Artefatos da interface de debug, não do visual da mata; não removidos |

**Áreas ainda sem evidência (por instrução do criador):** conjunto completo de fotos normal/espelhada (D-235) e vídeo de rodízio v9 — itens 1 e 3 do handoff foram declarados irrelevantes e não executados nesta rodada.

## 9. Distribuição das três pranchas no percurso (pendência D-1256)

Escolha de direção espacial dentro do grafo já aprovado na §3.1 — nenhuma sala, regra ou valor novo. O criador pode trocar a posição de qualquer tratamento.

| Trecho do caminho crítico | Prancha aplicada | Por quê |
| --- | --- | --- |
| Entrada → corredor → **arco** | Prancha 2 (vistas laterais, troncos em primeiro plano) | As laterais emolduram o corredor e criam linhas convergentes para o arco, o marco de revisita (D-1247) |
| Corredor → **dossel → abrigo** (respiro) | Prancha 1 (aberturas na copa) | É o ponto de tensão 0,15 da curva; a luz que entra pelas aberturas marca visualmente o descanso antes do clímax |
| Cyclops+amuleto → **Orc → saída** | Prancha 3 (desnível cenográfico além da paliçada) | Fundo de mata mais baixa dá profundidade no trecho de maior intensidade (0,7 → 0,9), sem criar chão jogável |

Sequência de intensidade (§3.2, inalterada): `0,1 → 0,4 → 0,15 → 0,7 → 0,9 → 0,1`.
O nicho opcional fica fora do caminho crítico; o arco continua como âncora e a saída verde é funcional (D-1028). Nenhuma passagem inferior nem posto de vigia neste recorte (D-1247).

**Estado desta distribuição:** a prancha 2 (troncos laterais) e a prancha 3 (desnível cenográfico) já estavam implementadas; a prancha 1 (aberturas na copa) foi implementada em v12 com disco emissivo, cone aditivo e `SpotLight3D` — prova em `mf_v12_prancha.png`. **Task 2 executada:** divisória em x=13,5 no cômodo nordeste com porta livre de 3 m (D-1245), separando o **dossel** (caminho crítico) do **nicho opcional** (ramal, §3.1). Prova: `mf_v15_nicho.png`. **Navegação ajustada:** a navmesh passou de 4 para **5 polígonos / 11 vértices** (probe headless), com o polígono antigo do cômodo nordeste dividido em dossel + nicho — nenhum agente atravessa a parede nova. Ainda não executada: a caminhada real (Task 3) e a validação de portas sem teleporte.

**Nota de técnica (D-1204):** o tool `ds-run.mjs` ganhou timeout duro de 55 s (`DS_TIMEOUT_MS`) nos dois `spawnSync`, após travamentos repetidos ao rodar dentro do repo com muitos turnos. Chamadas agora usam diretório neutro com constantes inlindas. Task 1 entregue: `tests/exploration/test_mf_layout_metrics.gd`, `PASS` com `--summary-json --strict-asserts` (ambas as vistas), `proof=b2f5af74` (+ `640d8ba2` na correção). Compliance apontou 2 falhas (D-235, D-1204) corrigidas na versão final. Task 2: `proof=cbdbb70f`; o patch não aplicou por linhas desatualizadas e foi aplicado na mão com 3 correções de API (`CULL_DISABLED`, `spot_range`, `shadow_enabled`, `clear_polygons` + `add_polygon` — `set_polygon` não existe nesta versão do Godot).

**Auditoria DeepSeek das fases 1–3:** pedido de auditoria com diff completo estourou o timeout (o modelo entra em loop de raciocínio quando precisa gerar diff longo). Reformulado como 10 perguntas binárias → resposta em 17 s, `proof=48cd97aa`. A auditoria confirmou 3 erros reais, todos corrigidos: **(a)** teste tautológico (câmera medida = esperada) — agora `_verify_sources()` lê as constantes das fontes por `FileAccess` e falha se divergirem; **(b)** falta do prefixo `METRICS_JSON:` e do tratamento de `--summary-json` — corrigidos; **(c)** navmesh do nicho compartilhava a borda inteira da divisória, permitindo travessia fora da porta — corrigido com uma **ponte de 3 m** (vão z −1,5..1,5). Probe final: **6 polígonos / 17 vértices**. Teste final: `STRICT_ASSERTS: on`, `METRICS_JSON: {"ok":true,...}`, PASS, sem erros de compilação.

**Registro de falha da ferramenta:** o "patch de correção" devolvido pelo DeepSeek (`proof=93a8686e`) estava **alucinado** — reconstruiu um arquivo diferente (constantes 5.0/4.0/1.2 que não existem no teste) e o patch saiu corrompido. Foi **rejeitado**; as correções foram aplicadas na mão com base nos achados válidos da auditoria.

### Execução das Tasks 3 e 6
- **Task 3** — `tests/exploration/test_mf_room_graph.gd` criado via DeepSeek (`proof=00fda268`, patch aplicado limpo). O teste primeiro **falhou de propósito** (`unreachable: ["niche"]`), revelando que a ponte da porta usava vértices duplicados — o Godot só conecta polígonos que compartilham **índices**. Corrigido: navmesh reconstruída com fatias do polígono base, dossel, ponte e nicho compartilhando índices. Resultado final: `GRAPH_JSON: {"ok":true,"polygons":12,"vertices":23,"reachable":["entry","corridor_arch","canopy","niche"],"unreachable":[]}`.
- **Task 6** — `_run_layout_scenario()` adicionado ao lab. DeepSeek não entregou código utilizável (`proof=f49dd5ee`, output vazio); implementado direto. Comando `--scenario=MF_LAYOUT_WALK --summary-json --quit` termina em **4,7 s**, exit 0, com `LAYOUT_JSON` contendo `rooms`, `doors`, `metrics`, `beats`, `audit`.
- **Limitação honesta:** o `MF_LAYOUT_WALK` atual audita o **grafo de navegação** (BFS por polígonos), não simula passos físicos com `wall_hits`/`cam_inside`. A travessia real sem teleporte ainda não foi medida.

### Execução da Task 4 (dados de ocupação)
- `BEATS` e `VISIT_DATA` + `layout_beat_report()` entregues via DeepSeek (`proof=5d2a9277`, 7,9 s, snippet limpo). Integrados ao `LAYOUT_JSON`: saída determinística com `beats` (7 entradas) e `visits.first/return`. Cenário segue em ~4,9 s.
- Curva verificada nos dados: `0,1 → 0,4 → 0,15 → 0,15 → 0,7 → 0,9 → 0,1` — há respiro (0,15) antes do clímax (0,9), e nenhum beat marca o evento como pré-requisito do chefe (R36-Q2).
- **Marca cenográfica** (D-1248): monte de pedras com runa junto ao arco, camada 9, sem colisão, exibido só com `--visit=return` no debug. **Não** é persistência entre expedições (D-1247) nem UI nova.
- **Não verificado / pendente:** a marca aparece pequena em `mf_v16_retorno.png` e não foi confirmada em close; a **fala curta no Hub** (outra cena, `scripts/hub/hub_3d_lab.gd`) ainda não foi integrada — o gatilho D-1248 está implementado só como dado + marca no lab.

### Auditoria DeepSeek das Tasks 3 e 4
Duas perguntas binárias curtas: navmesh `proof=8e2ad1fd`, dados `proof=8f4a126d`. Achados **confirmados**: conectividade entrada→corredor→dossel→nicho; ponte com aresta real; agente **não** cruza a parede fora da porta; evento opcional; sem tranca/persistência; marca sem UI/regra nova. Achados **rejeitados por contra-evidência** (o modelo errou): (a) "winding inconsistente" — conta de área assinada mostrou os 12 polígonos CW, idênticos à base; (b) "sem respiro antes do clímax" — o plano §3.2 aprova explicitamente `0,1 → 0,4 → 0,15 → 0,7 → 0,9 → 0,1`, com o respiro em 0,15; (c) "flag afeta o jogo normal" — `_cli_value("--visit")` retorna `""` sem a flag, então a marca não é construída. Nenhuma regra foi alterada por causa de falso positivo.

### Execução da Task 5 (legibilidade e marcos)
- Pontos de captura a **9 m do arco** nos dois lados: `marco_9m` (x 15,5, olhando −X) e `marco_9m_oposto` (x −2,5, olhando +X). Provas: `mf_t5_marco9m_normal.png` e `mf_t5_marco9m_oposto.png` — arco com colunas e imposta legível em ambos.
- `--mirror` no mesmo ponto **não** serve para marco estático (a câmera olha para fora do mapa); a simetria D-235 foi verificada com câmeras opostas reais, não com rotação de 180°.
- **Minimapa:** acrescentadas as duas divisórias do nicho em `_build_minimap_map()` para manter coerência com a cena (D-1027).
- **Confirmado:** não existem passagem inferior nem posto de vigia (D-1247). Âncoras presentes: arco de pedra e portal verde (funcional, suavizado).
- Julgamento visual nas duas vistas em tamanho real.

### Execução da Task 7 (revestimento e auditoria final)
- **Auditoria de caminhada real** entregue pelo DeepSeek (`proof=a2771827`, effort máximo, 30 s): `tests/exploration/test_mf_walk_audit.gd` usa `NavigationServer3D.map_get_path()` no mapa da cena instanciada. Resultado: `AUDIT_JSON: {"cam_inside":0,"ok":true,"path_min":8.0,"stack_pairs":0,"wall_hits":0}` + `PASS`. Isso **fecha** a limitação anterior (o grafo agora é validado por path real, não só BFS de polígonos).
- **Prova final:** `mf_t7_prova.mp4` (rodízio de 5 quadros) e `mf_t7_folha.png` (folha de contato 3×2) em `docs/referencias/exploracao/3d/`. Vistas: arco, marco a 9 m (normal e oposta), nicho e retorno.


### Auditoria final e fechamento de D-1248
- **Auditoria DeepSeek** (`proof=114d9bfa`, effort máximo, 52 s): 9 de 10 itens confirmados (arco isolado, 3 pranchas, desnível só cênico, navmesh sem travessia, testes < 1 min, gating suave, sem persistência/item, iluminação D-1256). A Q10 respondeu "não falta nada", mas estava **errada**: a fala curta no Hub (D-1248) ainda não existia.
- **Correção:** fala curta implementada em `scripts/hub/hub_3d_lab.gd` via DeepSeek (`proof=db30a632`, 4 s): `HUB_LINE: O arco de pedra ainda está lá. Volte quando quiser reconhecê-la.` — sem UI nova, sem `await`, sem persistência entre expedições e sem tranca. Parse do Hub e do lab: OK.
- **Estado:** D-1248 está coberto no código — gatilho = fala curta no Hub + marca no cenário; ordem 1ª aprender / 2ª novidade como dado (`VISIT_DATA`), sem tranca.

### D-1256 — planta autoral reconstruída do zero
- Novo módulo `scripts/debug/murky_forest_layout.gd` (`proof=38d4064c`): uma única tabela explícita (`ROOMS`, `WALLS`, `PILLARS`, `DOORS`, `ROOM_ORDER`) define todo o mapa — **sem geração procedural**. `build()` cria pisos/paredes/pilares com `BoxShape3D` explícita (removido `create_trimesh_collision()` para não varrer QuadMesh da vignette); `build_navmesh()` devolve os 23 vértices / 12 polígonos autorais.
- O lab agora chama `MurkyForestLayout.new().build(...)` em `_build_room()` e `build_navmesh()` em `_build_navigation()` (`proof=5288dfa6`, `647cec42`). A geometria herdada do `third_person_3d_lab.gd` foi **removida** — o mapa não depende mais do lab base.
- Dois bugs reais encontrados e corrigidos via DeepSeek: `_nav_region` não era criado sem `super()` (navmesh zerada); `create_trimesh_collision` quebrava em QuadMesh.
- Validação: PARSE OK; `metrics` PASS, `graph` PASS (12 polígonos/23 vértices), `walk` PASS (`wall_hits=0`, `cam_inside=0`, `path_min=8,0`); `LAYOUT_WALK` reporta `navmesh_polygons=12, navmesh_vertices=23`. Prova visual: `mf_t7_layout_autoral.png`.
- **Honestidade:** a tabela reproduz a geometria anterior (occupants e câmeras intactos) — a mudança é estrutural (mapa autoral em dados), não um redeseno visual das salas.

## Game feel da exploração
- Modulo `scripts/debug/mf_game_feel.gd` (`proof=a044083a`): trauma 0..1 com `shake = trauma²`, decaimento 1,6/s, seno amostrado (nao rand por quadro) e offsets na camera — shake suave e autofinal. Tiers: small 0,12 / medium 0,25 / large 0,45. Sem som (fora do escopo) e sem regra/movimento/colisao.
- Ligado ao lab (`proof=45b14dbf`): `impulse("large")` na chegada, `medium` ao coletar item, `small` quando a orb chega; `step(delta)` no `_process`. Nada depende de personagem/time/lado (D-235).
- Teste `tests/exploration/test_mf_game_feel.gd` (`proof=2556e17c`): `GF_JSON: {"start":0.45,"end":0.0,"offset_zero":true,"ok":true}` + PASS. Confirma que o feedback retorna ao repouso.
- Parse do lab OK; os tres testes de exploracao continuam PASS.

## Direção de mapa aberto (pedido do criador, KH2/KH3)
O criador pediu ambientes amplos e exploráveis estilo Kingdom Hearts 2/3, com poucas paredes (ainda com paredes no perímetro) em vez de corredores fechados e claustrofóbicos, e delegou a busca de referências.

Referências consultadas (web):
- **KH2** favoreceu áreas mais largas e menos verticais (GameRant): "larger scenarios with greater freedom of movement"; câmera um pouco mais distante para ver os arredores.
- **KH3 / Tebas** (Engadget): ruas largas e grandes praças, seções que variam muito de formato e tamanho; marcos visíveis de longe.
- **Nomura/Co-diretor** (IGN/KH13): qualidade e tamanho de cada mundo sobre quantidade; verticalidade dá sensação de espaço expandido.
- **Ressalva acadêmica** (Loading, journal): em KH a "abertura" costuma ser ilusão — poucos caminhos reais. Aqui a abertura é **real**: linhas de visão longas e mobilidade, não só aparência.

Pranchas obrigatórias relidas em tamanho completo: `murky-forest-v2-opcao-1-copa.png` (clareira ampla, paliçada baixa, arco ao fundo), `...-2-vistas-laterais.png` (troncos em ritmo vertical, mata lateral, arco entrando/saindo), `...-3-desnivel.png` (borda baixa com mata mais baixa além, corredor largo ao arco).

Tradução para o mapa autoral (D-1256, sem procedural): uma **clareira central ampla** com o arco como âncora distante; alas laterais abertas (dossel/nicho/abrigo) em vez de corredores-caixa; paredes **só no perímetro** com vãos largos; troncos como ritmo vertical, não como barreira; desnível cenográfico além da borda baixa. Os papéis das salas (D-1133/D-1151) e as três pranchas seguem presentes.

**Planta executada** (`proof=6621bea6`): `ROOMS` trocados por 7 clareiras — entrada 26×24 m, corredor do arco 26×16 m, alas oeste/leste 12×24 m, nicho 8×10 m, baias sul 14×12 m. `WALLS` reduzidas de 21 para 8 (só periódicas + duas divisorias curtas). `PILLARS` passam a 8 troncos de 0,7 m como ritmo vertical. Navmesh reescrita: 16 vértices, **6 polígonos** conectados (clareira→alas→passagem→arco→área sul). Um polígono degenerado (vão central, área zero, vértices colineares em z=−40) foi **removido por contra-evidência** (conta de área assinada) antes de aplicar; o modelo já incluía correção automática de winding. A copa foi estendida para 54×56 m e as 3 aberturas de luz reposicionadas na clareira, no corredor e no dossel.

### Execução da planta aberta (pedido KH2/KH3)
Todos os trechos abaixo via DeepSeek com effort máximo e sem timeout (regra 2026-11-17):
- `proof=6621bea6` — `MurkyForestLayout` reescrito: clareira 26×24, corredor 26×16→20, alas 12×24, nicho 8×10, baias sul 14×12. Paredes 21→8 (só perímetro), pilares 4→8. Navmesh 12→6 polígonos.
- `proof=917fc175` — arco reposicionado em (0,−28) atravessando o corredor no eixo X e 10 pontos de captura reescritos para a planta nova.
- `proof=74438d64` — `_build_foliage`, `_build_vertical_foliage`, `_build_minimap_map` adaptados às bordas perimetrais e à clareira ampla.
- `proof=0887a984` — ocupantes (Cyclops/Orc/Amuleto/Poção/NPCs) movidos para as baias sul e laterais da clareira.
- `proof=53171b0d` — trigger da saída em `third_person_3d_lab.gd` trocado para (0, 0.9, −36).
- Correção visual direta (agente visual): copa 54×56 com 3 aberturas reposicionadas; fundo de mata e desnível movidos para z≈−45; troncos de primeiro plano nas bordas; portão verde no vão central sul.
- Bug real encontrado por captura: **vão de 4 m no piso** entre z=−14 e z=−18 (navmesh contínua, piso faltando) — corrigido (`proof=c1f00942`). Bug de enquadramento: vista oposta do arco ficava preta porque a câmera ficava atrás do fundo do portão — ponto de captura deslocado para x=6.
- Prova final: `mf_final_prancha.png`, `mf_final_marco_9m.png`, `mf_final_marco_9m_oposto.png`, `mf_final_nicho.png`; vídeo `mf_open_final.mp4` e folha `mf_open_folha.png`.
- Validação final: PARSE OK; `metrics` PASS, `room_graph` PASS (6 polígonos/16 vértices), `walk` PASS (`wall_hits=0`, `cam_inside=0`, `path_min=8,0`, `stack_pairs=0`), `game_feel` PASS.
- **Resultado visual:** clareira ampla contínua, poucas paredes (só perímetro), arco visível de longe com feixe de luz, mata de fundo nas duas vistas — direção KH2/KH3 pedida pelo criador, com as três pranchas presentes.

## Remocao determinada pelo criador
Toda mencao a mobile/web, resolucoes, limiar numerico de legibilidade, `--scale-overlay` e fundos neutros foi **removida** dos documentos desta frente (plano de level design e docs associados). O protocolo de VFX de combate nao foi tocado: la essas ferramentas sao exigidas por D-1044 e sao outra decisao.
