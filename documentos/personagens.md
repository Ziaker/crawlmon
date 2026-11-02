# Biblioteca de Personagens (Sprites e Retratos) — Crawlmon

Este documento registra a organização das imagens de personagens no projeto **Crawlmon**, divididas entre os Pokémon prontos para o jogo (com modelo 3D disponível) e os que aguardam modelos futuros.

---

## 1. Visão Geral e Separação de Pastas

Como o Crawlmon utiliza **batalhas 3D** (`scenes/battle.tscn`) e **exploração 2D** (`scenes/exploration.tscn`), somente os Pokémon que possuem tanto sprites 2D quanto modelo 3D podem entrar no jogo ativo.

- **`personagens/` (Ativos no Jogo):**
  - **303 espécies** de Pokémon com modelo 3D disponível (300 de Legends Z-A + 3 do Arenamon chars: Drowzee, Vigoroth e Croagunk).
  - **3.933 arquivos PNG** (ícones, retratos e sprites overworld de caminhada).
  - Importados e indexados automaticamente pelo Godot (`res://personagens/`).

- **`personagens_sem_modelo/` (Arquivados / Aguardando Modelos):**
  - **418 espécies** que não possuem modelo 3D no momento e não poderão ser utilizadas no jogo atual.
  - **7.252 arquivos PNG** separados preservando toda a estrutura original de diretórios (`icons/`, `conquest/`, `overworld/`).
  - Contém um arquivo `.gdignore` para evitar que a engine gaste memória ou gere arquivos `.import` desnecessários para assets que não entrarão no jogo.

---

## 2. Estrutura de Pastas dos Personagens Ativos (`personagens/`)

```text
crawlmon/
└── personagens/
    ├── portraits/               # Retratos oficiais de diálogo estilo Pokémon Mystery Dungeon (PMDCollab)
    │   └── *.png                # Retratos 40x40 para caixas de texto (ex: bulbasaur.png, pikachu.png)
    │
    ├── icons/                   # Ícones de equipe e menu dos 303 Pokémon ativos
    │   ├── *.png                # Ícone padrão (ex: bulbasaur.png, greninja.png)
    │   ├── female/              # Variantes femininas com diferenças visuais
    │   ├── right/               # Variantes viradas para a direita
    │   ├── old/                 # Ícones clássicos
    │   └── old/female/          # Ícones clássicos femininos
    │
    ├── conquest/                # Retratos estilo Pokémon Conquest (cards de batalha)
    │   └── *.png
    │
    └── overworld/               # Sprites 2D top-down nas 4 direções + 2 quadros de caminhada
        ├── down/ (e down/frame2/)
        ├── up/ (e up/frame2/)
        ├── left/ (e left/frame2/)
        ├── right/ (e right/frame2/)
        ├── female/
        ├── shiny/
        └── shiny/female/
```

---

## 3. Estrutura dos Arquivados (`personagens_sem_modelo/`)

Contém as mesmas subpastas (`icons/`, `conquest/`, `overworld/`), permitindo que, caso um modelo 3D seja adicionado futuramente (por exemplo, criando um modelo no Blender ou importando de outro jogo), os sprites correspondentes possam ser movidos de volta para `personagens/` com um simples comando.

---

## 4. Exemplos de Uso em GDScript (Godot 4)

### 4.1 Carregar ícone ativo
```gdscript
func get_character_icon(pokemon_name: String) -> Texture2D:
	var path := "res://personagens/icons/%s.png" % pokemon_name.to_lower()
	if ResourceLoader.exists(path):
		return load(path)
	return null
```

### 4.2 Carregar textura de caminhada na Masmorra
```gdscript
func get_walk_texture(pokemon_name: String, direction: String, frame: int) -> Texture2D:
	var frame_suffix := "/frame2" if frame == 2 else ""
	var path := "res://personagens/overworld/%s%s/%s.png" % [direction.to_lower(), frame_suffix, pokemon_name.to_lower()]
	if ResourceLoader.exists(path):
		return load(path)
	return null
```

---

## 5. Documentos Relacionados

- [`documentos/modelos_za_comparativo.md`](modelos_za_comparativo.md): Auditoria completa do comparativo entre o elenco do Crawlmon e o banco de dados do Legends Z-A.
- [`documentos/pokedex_manifest.json`](pokedex_manifest.json): Manifesto com a flag `usable_in_game` para cada uma das 722 espécies, indicando quais estão em `personagens` e quais estão em `personagens_sem_modelo`.
