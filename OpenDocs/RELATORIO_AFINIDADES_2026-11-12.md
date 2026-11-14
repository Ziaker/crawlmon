# Relatório de trabalho — Afinidades, ficha e UI

- **Data:** 2026-11-12
- **Escopo:** protótipo da matriz de afinidades, tabela de afinidades no jogo, UI de afinidades e ficha de personagem.
- **Estado:** tudo local; **nada commitado ou enviado** (D-022).
- **Decisões registradas:** D-1163, D-1164, D-1165, D-1166, D-1167.

---

## 1. Matriz de afinidades (protótipo HTML)

Arquivo: `prototypes/affinity_matrix.html` (~308 KB, standalone, abre por `file://`).

### O que foi implementado

**Prompt das 15 melhorias** (`docs/PROMPT_AFFINITY_MATRIX_15_MELHORIAS.md`), itens 1–6:

1. **Cadastro de personagem** por modal: ID único, nome, retrato, DQT + zoom, upload, prévia e validação.
2. **Busca** por nome/ID/papel, sem acento, com destaque, contador e atalho `/`.
3. **Só novos**: badge NEW, filtro com contador, “Revisar visíveis” e persistência do filtro.
4. **Visão por personagem**: card com as 12 linhas de elemento.
5. **Edição**: nome, ID (com migração das afinidades), retrato, DQT e ativo/inativo.
6. **Ações em massa**: tudo neutral, copiar de outro, duplicar e excluir com confirmação.

**Ficha de personagem (D-1167)** — nova visão “Ficha”, em duas colunas:

- **Ícone e render separados**: upload de ícone (256 px) e render (1024 px), com remover.
- **Fundo Pokémon**: degradê ciano→verde atrás de ícones transparentes.
- **Elements**: 12 elementos, até 2 por personagem.
- **Nature**: as 8 natures do jogo com modificadores.
- **Attributes**: 6 atributos, base de nível 1, orçamento de 15 pontos.
- **Affinities**: 12 tiles, clique alterna N → W → R.
- **Moves**: os 38 moves do jogo, filtro, até 8 escolhidos.
- **Faixa de personagens** para trocar a ficha.

**Visual**: barra bicolor lima/coral no topo da página, do card e do modal; marcadores laterais nos títulos; tiles de afinidade inclinados; elementos como badges parallelogram ao lado do nome.

**Dados reais usados como seed**: alocação de 15 pontos, elementos e loadout dos 6 personagens já implementados (`species.tres` / `loadout.tres`).

### Exportação

`schema: crawlmon.affinities.v1`, agora com `nature`, `stats`, `elements`, `moves`, `iconData`, `renderData` e `iconBg` por personagem. `portraitData` antigo é lido como `iconData`.

### Evidências

- `test_captures/aff_final.png` e `aff_final_none.png` — grade de afinidades na StatusScreen.
- `prototypes/_preview_ficha.png` — ficha completa + ícone com fundo Pokémon.
- `prototypes/_sheet_v3.png` e `_sheet_mobile2.png` — ficha desktop e mobile.
- Testes de navegador: criação, edição, filtro, elementos (máx. 2), moves (máx. 8), upload, exportar/importar e mobile 390 px sem rolagem horizontal.

---

## 2. Tabela de afinidades no jogo (D-1165)

- Fonte: export do criador, `content/affinities/crawlmon_affinities.json` (13.507 bytes, 16 personagens, **32 Weak / 28 Resist**).
- `tools/apply_affinities.py` lê o JSON e grava `affinities` com as 12 entradas explícitas + `weaknesses` sincronizado.
- Aplicado nas **6 espécies que têm `species.tres`**: abra, pancham, gible, dqt_slime, dqt_orc, dqt_cyclops.
- **Não aplicado** nas 10 sem `species.tres`: bulbasaur, charmander, squirtle, pikachu, eevee, dqt_dracky, dqt_healslime, dqt_sabrecub, dqt_platypunk, dqt_fungi.
- Verificação no Godot: 6 recursos carregados, 12 entradas cada, nenhuma ausente.
- Testes: `test_d1157_affinity_schema.gd` (**D1157_PASS**) e `test_d1152_damage_golden.gd` (**D1152_PASS**).

Efeitos que merecem atenção: Abra é fraco a Mystic (Megido 1,5×); Gible, Orc e Cyclops resistem a Neutral.

---

## 3. UI de afinidades (D-1166)

- **StatusScreen**: grade dos 12 elementos na base da arte, em células iguais (ícone + `W`/`R`/`–`), sobre uma cunha escura inclinada com fade. Não colide com a descrição da nature (x≥848) nem com as Skills (y≥574).
- **StatusPanel**: “WEAKNESSES” virou “AFFINITIES”.
- **Menus**: “Fraquezas:” virou “Afinidades:”.
- **Seletor de alvo em batalha**: o selo “WEAK” agora vem de `affinity_entries()`.
- `Combatant` ganhou `affinity_entries()` e `affinity_text()`.

Evidência: `test_captures/aff_final.png`, `aff_final_none.png`; `tests/ui/capture_affinity_block.gd`.

---

## 4. Riscos e pendências encontrados

1. **O builder de conteúdo apaga as afinidades.** `tools/build_content_catalog.gd` cria um `CharacterData` novo e salva por cima do `species.tres` sem `affinities`. Se rodar, a tabela aplicada some e as fraquezas voltam às listas fixas do script. **Correção recomendada e ainda não feita.**
2. **10 espécies fora do jogo**: têm afinidades definidas, mas não têm `species.tres` (stats/loadout/modelo).
3. **`save_state`/`restore_state`** não capturam afinidades (identidade fica fora do snapshot).
4. **StatusPanel e Menus** não foram vistos em tela; só compilaram.
5. **Protótipo**: imagens ficam em `localStorage` (quota ~5 MB). Render de 1024 px em WebP ficou ~72 KB por personagem; muitas imagens podem encher o armazenamento.
6. **Recorte de imagem** não existe: ícone e render entram inteiros (sem zoom/posição).

---

## 5. O que não foi feito

- Itens 7–15 do prompt da matriz: dashboard, undo/redo, baseline/diff, importação em lote, JSON v2 validado, templates, acessibilidade completa e performance para 100+.
- Editor de imagem (crop/zoom) e ordenação de moves na ficha.
- Migração de StatusScreen/StatusPanel/Menus para remover `weaknesses` do modelo (hoje `affinities` vence, `weaknesses` é fallback sincronizado).
- Correção do `build_content_catalog.gd`.
- Commit/push.

---

## 6. Arquivos tocados

| Arquivo | O que mudou |
|---|---|
| `prototypes/affinity_matrix.html` | Matriz + ficha (itens 1–6, D-1167), visual, assets |
| `content/affinities/crawlmon_affinities.json` | Export oficial da tabela (novo) |
| `tools/apply_affinities.py` | Conversor JSON → `species.tres` (novo) |
| `content/characters/*/species.tres` | `affinities` + `weaknesses` nas 6 espécies |
| `scripts/combat/combatant.gd` | `affinity_entries()` e `affinity_text()` |
| `scripts/ui/status_screen.gd` | Grade de afinidades na base da arte |
| `scripts/ui/status_panel.gd` | Linha AFFINITIES |
| `scripts/ui/menus.gd` | Texto “Afinidades:” |
| `scripts/combat/battle_scene.gd` | Selo WEAK via `affinity_entries()` |
| `tests/ui/capture_affinity_block.gd` | Captura do protótipo da grade (novo) |
| `docs/decisoes/D-1163…D-1167` | Decisões e índice |
| `docs/REGRAS_DO_JOGO.md` | Itens D-1163 a D-1166 |
| `docs/PROMPT_AFFINITY_MATRIX_15_MELHORIAS.md` | Prompt original |

---

## 7. Como reproduzir

```powershell
# conferir a tabela sem gravar
python tools/apply_affinities.py

# aplicar de novo (idempotente)
python tools/apply_affinities.py --write

# testes
.\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/battle/test_d1157_affinity_schema.gd
.\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/battle/test_d1152_damage_golden.gd

# capturas da grade de afinidades
.\Godot_v4.7.2-stable_win64_console.exe --path . --script res://tests/ui/capture_affinity_block.gd
```
