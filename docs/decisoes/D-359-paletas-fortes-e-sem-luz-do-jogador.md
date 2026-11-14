<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-359 — Paletas de bioma fortes e luz do jogador removida

- **Data:** 2026-11-06
- **Área:** Exploração / visual / névoa / iluminação
- **Origem:** O criador viu o contato dos 16 biomas e achou as diferenças minúsculas; pediu diferenças fortes por bioma e a remoção da luz natural do personagem.

## O que o criador disse (literal)

> tá mas na imagem que tu colocou, todos são iguais, a diferença é minuscula... eu pedi pra serem diferentes entre cada baseado no bioma, bem diferentes. Remova a iluminação natural do personagem também

## Decisão

1. **16 paletas fortes, não tons pastel.** `scripts/dungeon/biome_visuals.gd` agora usa cores saturadas e distintas:
   - 4th Station verde; 7th Station ciano; icicle teal; dark ice azul; peak índigo; vast ice azul-aço; peak lavanda;
   - barren areia; dark wasteland marrom; deep boulder rosa/magenta; deep limestone laranja; limestone amarelo;
   - murky violeta; spacial cinza; temporal spire azul-ardósia; temporal tower azul-aço.
   O `AMBIENT` (CanvasModulate) é o overlay visível; o `FOG` usa a mesma família de cor, mais escura, com densidade/warp/drift próprios.
2. **Luz do jogador removida.** O `_player_light` (`PointLight2D`) saiu do `map_visuals`; não há mais luz dinâmica do personagem. A sala é iluminada só pelo `CanvasModulate` do bioma. As luzes de tocha já tinham saído em D-358. A única `PointLight2D` restante é a **vermelha dos inimigos** (sinal de aggro, não é de parede).
3. **Temporal e Spire compensados.** Sem as luzes dinâmicas, o `AMBIENT` do Temporal subiu para `c8dce8` e o do Spire para `a0b0c8`; os outros 14 já ficaram legíveis com as cores fortes.
4. **Sem mexer na regra:** raio de 7,5, LOS, explorado permanente, ordem de desenho, câmera 2,3×, 48 px e geração procedural continuam iguais.
5. **Laboratório também recebe o ambiente.** O `tileset_lab` aplica o mesmo `AMBIENT` do bioma num `CanvasModulate`; os 16 contatos do laboratório deixaram de ser cinza. A névoa em si só existe na cena do jogo (`exploration.tscn`), porque o laboratório não tem névoa/explorado.
6. **Duas cores e ruído por bioma (D-360).** A névoa ganhou `color`/`color_b`, `side_mix` e um `NoiseTexture2D` com tipo/frequência/escala/seed próprios; o lado esquerdo e o direito são diferentes dentro do mesmo bioma, e cada bioma tem um padrão de névoa distinto.

## Estado

Implementado: 16 `AMBIENT`/`FOG` fortes, luz do jogador removida, laboratório com ambiente por bioma, 16 capturas in-game + 16 do laboratório regeneradas (`docs/referencias/tilesets/biomes_ingame_contact.png` e `biomes_contact.png`), baseline de brilho regerada. `--check` OK; paredes 6.970/0; fallback 688/0; decals 8,1%/0; golden do laboratório 0,60/0,61. A água decorativa continua pendente de escolha (D-357). Nada foi publicado.
