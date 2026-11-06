# D-938 — Batalha de teste DQT: modelos 30% menores, personagens centralizados e chão mais largo

> **Renumerada em 2026-11-06:** D-336 → D-938. O ID D-336 já pertence a outra decisão no `origin/main`; o conteúdo local foi preservado com o novo ID.


- **Data:** 2026-11-05
- **Área:** Combate / Visual / Piloto de crossover (Dragon Quest Tact)
- **Origem:** Conversa

## O que o criador disse (literal)

> "1 - eles estao muito grandes
> 2 - tem como deixar TODOS personagens mais pro meio do mapa, eles ficam muito perto uns dos outros tambem, inclusive aumente o tamanho do chao do mapa pra n ficarem dentro dos pilares"

Respostas às perguntas de esclarecimento:

- Tamanho: **"Só os 3 DQT, −30%"**.
- Onde vale: **"teste"** (só a batalha de teste DQT: `--dqt`, `--dqt-mirror`, F11).
- Layout: **"Centrar em x=0, 12 entre eles"**.
- Chão: **"Largura 60 (HALF_W=30)"**.

## Decisão

1. Os 3 modelos DQT (Slime, Orc, Cyclops) ficam 30% menores: `target_height` ×0,7 (Slime 1,4; Orc 2,1; Cyclops 3,22). Pokémon não mudam.
2. Só na batalha de teste DQT, todos os personagens (aliados e inimigos) ficam centralizados em x=0, com 12 unidades entre os do mesmo lado. As outras batalhas mantêm os slots de hoje.
3. O chão da arena passa de largura 44 (HALF_W=22) para 60 (HALF_W=30); os pilares acompanham a borda (hoje HALF_W−3). Profundidade igual.

4. **Tudo visível na câmera (2ª e 3ª rodadas).** Com aliados a 12 de distância o Slime ficava atrás do card do HUD e o Cyclops cortado. O criador respondeu **"Afastar da câmera"**; com o recuo de 12 em z + 12 de espaçamento ele reclamou: **"NAO DA PFRA VER NADA, OS BONECOS TAO MT LONGE DE ONDE DEVIAM TA"** e **"tudo tem que ficar visivel na camera..."**. Regra: **todos os personagens da batalha DQT têm de aparecer na câmera, fora dos cards do HUD.** Medido com a câmera do início da batalha (borda segura x≈400–950 px, cards do HUD à esquerda e à direita embaixo): o maior espaçamento dos aliados que cabe é 7 com recuo −8, 5,5 com recuo −6 e 3,5 com recuo −4. Medição refeita com retângulos reais do HUD: o maior espaçamento que cabe é `1 + |recuo|` (recuo −3 → 4; −4 → 5; −6 → 7). 4ª rodada: o criador disse **"ELES TÃO MT LONGE TRÁS ELES PRA PERTO DNV"**. Aplicado: aliados DQT com `DQT_PARTY_Z_SHIFT = −3` e `DQT_PARTY_SPACING = 4` (centrados em x=0); o Cyclops fica parcialmente sobreposto ao Orc na tela; inimigos continuam a 12. Aliados não-DQT (ex.: Abra na `--dqt-mirror`) não recuam.

## Ambiguidades em aberto

- A câmera de cinema se move durante a batalha; a visibilidade foi medida só no enquadramento inicial. Garantir "tudo visível" o tempo todo exigiria mudar o enquadramento (D-015/D-020), o que não foi pedido.
- 4 de espaçamento entre os aliados é o limite para caberem na tela; o criador pediu menos amontoado, e as duas coisas conflitam com a câmera atual.

- O criador não disse se o chão mais largo vale também para as outras batalhas. Foi aplicado **só** quando o trio DQT está em campo, para não mudar as demais; confirmar.
- Não foi dito qual a distância (z) entre as linhas de aliados e inimigos; mantida a de hoje (`TEAM_DISTANCE` = 30).
- Os aliados não-DQT (Abra) na batalha `--dqt-mirror` entram na mesma regra de centralização.

## Estado no código

Ver o commit/alterações em `dqt_model_profiles.gd`, `battle_scene.gd` e `battle_arena.gd`.
