# D-358 — Névoa e overlay por bioma; luzes amarelas das paredes removidas

- **Data:** 2026-11-06
- **Área:** Exploração / visual / névoa / iluminação
- **Origem:** O criador achou as luzes amarelas das paredes desnecessárias e feias e pediu névoa/overlay coerentes com cada bioma.

## O que o criador disse (literal)

> quero que refaça a nevoa pra ser coerente com cada bioma e seu overlay visual também, para cada uma, inclusive remova essas iluminações amarelas estranhas nas paredes dos mapas, são desnecessárias e feias

## Decisão

1. **Luzes amarelas removidas de vez.** Não há mais `PointLight2D` de tocha no mapa. A única luz é a **luz fria do jogador** (`d6f4fb`); o resto é o `CanvasModulate` do bioma. Nada de fogueira/stick/triângulo.
2. **Névoa por bioma.** `scripts/dungeon/biome_visuals.gd` define, para os 16 biomas:
   - `AMBIENT`: a cor do `CanvasModulate` (o overlay visível do mapa);
   - `FOG`: cor da névoa, densidade, warp e drift.
   O `fog_of_war.setup()` lê `GameState.visual_biome` e o `apply_biome()` troca os parâmetros do shader; o `map_visuals` lê o `name` do perfil e aplica o `AMBIENT`.
3. **Paletas coerentes:** verde/vegetação no 4th Station, azul-gelo no 7th/dark ice/icicle/vast ice, areia no barren, rosa no deep boulder, âmbar nas cavernas de calcário, violeta no murky forest, cinza no spacial cliffs, azul-aço no Temporal.
4. **Sem mudar a regra de visão:** o raio de 7,5 tiles, a linha de visão, o explorado permanente (D-033) e o `fog` acima de jogador/inimigos/NPC continuam iguais. Só cor/overlay mudam.
5. **Teste in-game:** a mesma seed/mapa (12345) foi capturada nos 16 perfis; o `fog.apply_biome` e o `Visuals` trocam juntos. Contato em `docs/referencias/tilesets/biomes_ingame_contact.png`.
6. **Baseline de brilho atualizada:** sem as luzes amarelas o piso fica mais escuro; o `check_occluder_brightness.py` foi regerado para a nova iluminação (48,5–…), em vez de comparar com o antigo.

## Estado

Implementado: `biome_visuals.gd` (16 paletas), `fog_of_war.apply_biome`, `map_visuals` ambient por perfil, tochas/luzes amarelas removidas, 16 capturas in-game, baseline de brilho atualizada. O golden do laboratório (que não usa névoa) continua OK; paredes 6.970/0; fallback murky 688/0; decals 8,1%/0. A água decorativa continua pendente de escolha visual (D-357). Nada foi publicado.
