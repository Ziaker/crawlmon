# Contact sheets dos tilesets (D-345)

Esta pasta é **documentação**, não asset do jogo. O `.gdignore` impede o Godot
de importar as imagens.

Cada uma das 16 folhas do Sky tem:

| Arquivo | Para que serve |
|---|---|
| `<nome>_contact.png` | 18 cartões: índice no atlas, categoria, papel, coluna e linha da folha. É o primeiro gate de revisão. |
| `<nome>_atlas_labeled.png` | O atlas de 18 tiles em 2× com o papel de cada índice. |
| `<nome>_labels.png` | A faixa de labels original da folha (Walls, Ground, etc.). |
| `<nome>_preview.png` | O preview/composição do canto superior direito da folha. |

O **laboratório no Godot** (`scenes/tileset_lab.tscn`) mostra a sala de máscaras
no 48 px real e na câmera 2,3×. Para capturar as 16:

```bash
Godot_v4.7.2-stable_win64_console.exe --path . scratch/capture_tileset_lab.tscn
```

As capturas vão para `scratch/tilesets/` (ignorado pelo Godot).

## Como aprovar

1. Olhe o `_contact.png`: os papéis e as coordenadas batem com as labels?
2. Olhe o `_labels.png`: a categoria “Walls”/“Ground” é a que você espera?
3. Olhe a sala em `scratch/tilesets/<nome>_room.png`: cantos, bordas e piso contínuos?
4. Só então o atlas pode ser o ativo em `map_visuals.gd` (`PMD_PROFILE`).

Duplicatas de tiles são **avisos**, não erros: em arte uniforme, uma borda pode
ser idêntica ao centro. O que falha é tile vazio, ciano/teal dentro do recorte,
tamanho errado ou hash divergente.
