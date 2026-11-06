# D-346 — Terrain nativo e seletor de bioma por andar (Bloco 1)

- **Data:** 2026-11-06
- **Área:** Exploração / visual / tilesets
- **Origem:** Triagem das 10 melhorias; Bloco 1 aprovado

## O que o criador disse (literal)

> Pode prosseguir com o Bloco 1. Ao concluir, apresente as capturas do laboratório e a confirmação das decisões verificadas.

Bloco 1 aprovado:

> 1. **Terrain Nativo com Blob 47 (Fusão dos Itens 1 e 2):** utilizar a legenda de máscaras dos sheets do PMD Sky para gerar um `TileSet` nativo do Godot com `terrain_set` e peering bits configurados (Match Corners and Sides). Atualizar `map_visuals.gd` para utilizar o autotiling nativo do Godot (`set_cells_terrain_connect` ou pintura equivalente), eliminando o limite ortogonal de 4 vizinhos e tratando diagonais e quinas perfeitamente.
> 2. **Seletor de Bioma por Andar (Item 4 — D-312 e D-317):** ligar os 16 perfis de biomas existentes ao ciclo da expedição: trocar o tileset/atlas a cada 5 andares, conforme D-317. Manter um fallback seguro para `temporal_tower` e permitir troca manual rápida via tecla de debug no laboratório.

## Decisão

1. O `TileSet` passa a ter **terrain set nativo** com `MATCH_CORNERS_AND_SIDES`, dois terrains (parede e chão) e peering bits de 8 vizinhos. O `map_visuals.gd` pinta com `set_cells_terrain_connect`; a máscara manual de 4 vizinhos sai.
2. O seletor usa os **16 perfis** existentes, troca no **5º andar** (passo `floor / 5`) e tem fallback `temporal_tower`.
3. O laboratório ganha troca manual de perfil por tecla e uma auditoria de terrain (0 side / 0 corner).
4. Nada de câmera, 48 px, combate, movimento, colisão ou regras muda. Sem commit/push.

## Limites que a folha impõe (importante)

- O bloco 3×3 das folhas do Sky tem **9 peças de borda** (centro, 4 lados, 4 cantos), não um blob 47 completo. As linhas extras são **formas prontas** (cruz, T, ponta), não 38 variantes únicas. O terrain nativo usa as 9 peças reais e cobre diagonais/cantos que a máscara de 4 vizinhos errava. Não vou inventar 38 peças que não existem.
- As 16 folhas são tratadas como **pool de variações**; a D-312 nomeia 3 biomas (floresta, fortaleza, caverna). O pool de 16 amplia a variedade; se o criador quiser restringir a 3, é uma lista de configuração.
- A expedição real de 5 andares (D-316) ainda não existe no código. O seletor usa um **contador visual de andar** que avança a cada nova dungeon (`new_dungeon`); quando o andar real existir, é só passar o número verdadeiro.

## Auditoria do Bloco 1 (2026-11-06)

- **Seletor de bioma: implementado.** `BiomeSelector` lê o `biome_pool.json` com os 16 perfis, mantém Temporal Tower nos andares 1–4, troca no 5º andar (`floor / 5`), não repete o passo anterior e tem fallback. O contador `visual_floor` avança em `new_dungeon`. Teste de 1–15 andares e captura in-game do 5º andar (barren_valley).
- **Terrain nativo: implementado no laboratório, não no jogo.** O `TileSet` tem terrain set de 8 bits e o laboratório pinta com `set_cells_terrain_connect`; o atlas ativo ganhou 11 peças extras de parede detectadas (29 tiles no Temporal Tower).
- **0 side / 0 corner não foi alcançado.** A auditoria do laboratório dá **27 side / 49 corner** no Temporal Tower e **26 / 53** nas outras folhas. A causa é estrutural: o bloco 3×3 tem **9 peças reais** (centro, 4 lados, 4 cantos); as linhas extras são **formas prontas**, não um conjunto completo de 47 máscaras. O `set_cells_terrain_connect` não encontra peça exata para pontas de parede/curvas diagonais e deixa o centro, o que ficou **pior** que o renderer aprovado.
- **Decisão de segurança:** o `map_visuals.gd` do jogo **continua com a máscara manual de 4 vizinhos** aprovada (D-330), que usa as 9 peças e mantém o visual. O terrain nativo fica no laboratório para a próxima etapa. Não inventei as 38 peças que a folha não tem.
- **Para chegar a 0/0:** decodificar as formas extras em máscaras (proposta 1 do Bloco 2) ou aceitar o conjunto de 9 peças. O seletor de bioma já está pronto para os 16 perfis.

## Atualização 2026-11-06 — derrota

A derrota encerra a expedição atual (R23-Q3/R33-Q1). A nova tentativa começa no **andar 1**, com **nova seed de dungeon e novo bioma** (D-316/D-317): `visual_floor = 1` e `biome_seed = 0` antes de `new_dungeon(0, false)`. O comportamento anterior — preservar o bioma na derrota — fica substituído por esta atualização. O restante do seletor (troca a cada 5 andares) não muda.

## Estado

Bloco 1 **parcial**: seletor de bioma implementado; terrain nativo no laboratório com o limite da folha documentado; o jogo mantém o renderer aprovado. **A D-347 (Bloco 2) removeu o terrain nativo e as peças extras do atlas/laboratório ativo** e adicionou `ground_alt_1/2` ao piso orgânico. Nada foi commitado ou publicado.
