<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# Auditoria e Separação: Artes Oficiais Sugimori

Este documento registra a organização e separação de todas as artes oficiais de Ken Sugimori presentes no projeto Crawlmon.

## 1. Resumo da Separação

- **Total de Arquivos Auditados**: 1858
- **Artes de Pokémon presentes em Legends: Z-A**: **646** arquivos (movidos para `res://sugimori/`)
- **Artes Principais Mapeadas por Nome**: **297** arquivos em `res://sugimori/por_nome/`
- **Artes de Pokémon sem modelo em Legends: Z-A**: **1212** arquivos (movidos para `sugimori_sem_modelo/` com `.gdignore`)

## 2. Estrutura de Pastas

### `res://sugimori/` (Ativo no Jogo)
Contém exclusivamente os Pokémon utilizáveis que possuem modelos 3D em Legends: Z-A.
- `por_nome/`: Acesso direto pelo identificador do Pokémon (`abra.png`, `gible.png`, `pancham.png`, `bulbasaur.png`, etc.).
- `Pokémon By Generation/`: Todas as artes originais separadas por geração (Gen 1 a Gen 6).
- `Alternate Versions/`: Formas específicas, Mega Evoluções e variações oficiais aplicáveis.

### `sugimori_sem_modelo/` (Arquivado)
Contém os 1212 arquivos de Pokémon que não estão presentes em Legends: Z-A.
- Protegido por `.gdignore`, garantindo que o Godot Engine não processe nem gaste memória/tempo de build com estes arquivos.
