# D-356 — Biomas restantes, porta, decals exatos, golden 2D e occluder medido

- **Data:** 2026-11-06
- **Área:** Exploração / visual / tiles / ferramentas
- **Origem:** O criador pediu mais 10 frentes e autorizou todas.

## O que o criador disse (literal)

> me diz mais 10 coisas que pode fazer

E, depois da lista:

> possiga com tudo

## Decisão

1. **Fallback dos 12 perfis sem contrato de face:** quando `side_contract_ok=false`, o jogo não usa a assinatura medida; usa a **tabela de papéis** (a mesma nas 16 folhas) e as **peças reais** por nome: strip, island, tips, cross, alt centres. O `murky_forest` foi testado como amostra: **688 células, 0 divergências**.
2. **Revisão visual dos 16 biomas:** uma captura de sala por perfil (`scratch/tilesets/<nome>_room.png`) e a folha de contato `docs/referencias/tilesets/biomes_contact.png`. As paletas são as das folhas; a forma da sala/porta é a mesma.
3. **Porta no laboratório:** um corredor de 1 tile atravessa a parede esquerda (`DOOR_CELLS`), mostrando wall tip + borda de chão juntos. A sala antiga não tinha porta.
4. **Decals exatos por andar:** o mapa de decals é pré-computado com alvo **4% + 4%**, shuffle determinístico e exclusão de 1 tile. Medição em 10 seeds: **8,1% totais**, **0 pares adjacentes** (antes variava 6,4–11,5%).
5. **Golden 2D + occluder medido:** o golden agora compara também 2D (corr 0,61; MAE2D 0,65) e o `check_occluder_brightness.py` usa uma baseline por seed. Medição: centro do piso 51,1–68,5; qualquer mudança >12% falha.
6. **Sintonia do Wall Alt:** o laboratório captura **0+0%, 2+3%, 5+5% e 7+8%** (`tileset_lab_alt_*.png`); o jogo mantém 5+5% até o criador escolher outro valor.

## O que foi investigado e não mudou

- **Cantos internos do chão:** a folha não tem peças reais de canto interno de chão. O `Unused Ground` (C21..23) tem **um** tile em C22R1 (mancha de pedra), não um conjunto; o `Ground Alt. 1/2` são decals isolados. Sem peça real, o fallback continua `ground_c`; não se sintetiza nada (D-354).
- **Water / Unused Ground:** Water exige células de água, colisão e regra de mapa (D-312), então ficou **bloqueado** por falta de decisão de design. O tile C22R1 não foi usado como decal porque o significado dele muda por folha.
- **Padding:** o atlas é 48 px com `nearest` e sem filtro; não há sangria visível. Adicionar padding exigiria margens/separação no TileSet e não resolve um problema atual; ficou adiado.
- **Performance:** benchmark de construção (80×60, 4.800 células): **44–69 ms** por andar. O TileMap é estático (2 layers), sem redraw por frame; não foi medido FPS de GPU.
- **Commit:** o worktree tem mudanças de outras sessões (heal/combate/protótipos) e o `docs/decisoes/README.md` mistura linhas não commitadas. Não commitei nada para não incluir trabalho de outra sessão; o push continua proibido sem autorização.

## Estado

Implementado e testado: fallback dos 12 perfis (murky_forest 0 divergências), 16 capturas de bioma, porta no lab, decals 8,1% sem adjacentes, golden 2D OK, baseline de occluder OK, 4 variantes de Wall Alt, benchmark 44–69 ms. A folha ativa continua com **30 tiles** e o gate do Temporal segue **pendente** até o criador revisar a folha de componentes e os 16 biomas. Nada foi commitado ou publicado.
