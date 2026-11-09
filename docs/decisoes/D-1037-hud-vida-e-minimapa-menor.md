# D-1037 — HUD de exploração: mini-mapa menor e badges de vida à esquerda

- **Data:** 2026-11-09
- **Área:** Exploração / HUD / mini-mapa / UI 3D
- **Origem:** depois de ver o lab da Murky Forest com o mini-mapa top-down (D-1027/D-1028), o criador pediu ajustes de tamanho/texto e uma HUD de vida.
- **Status:** **primeira versão visual implementada no lab** (mini-mapa 112 px sem texto + badges com HP demo); fonte real do HP, personagens exatos e estilo final ainda pendentes; nada de combate/2D muda; nada publicado.

## O que o criador disse (literal)

> perfeito, mas diminua o tamanho do minimapa pela metade, não precisa do texto dizendo do mini mapa

> adicione badges no extremo canto esquerdo que mostra a vida dos personagens, um hud mesmo, me dê mais ideias que poderia colocar

## Decisão

1. **Mini-mapa pela metade:** o quadro/render do mini-mapa deve ter **50% do tamanho atual** (de 224×224 para 112×112 px de exibição; o SubViewport interno pode continuar 256×256). Os marcadores ficam em 20/14/16 px (jogador/aliados/inimigo), grandes o bastante para o ícone exato ser legível no mapa de 112 px.
2. **Sem texto do mini-mapa:** remover o rótulo "MAPA — MURKY FOREST" (e qualquer título do mini-mapa). O mini-mapa fica só com o quadro e os marcadores.
3. **HUD de vida:** badges no **extremo canto esquerdo** mostrando a vida dos personagens, com nome, barra de HP e número `atual / máximo`.
4. **Primeira versão no lab:** mostrar **Abra (jogador), Pancham e Orc** — os três personagens visíveis no lab. Pancham/Orc são aliados verdes menores no mini-mapa; na HUD, os três usam o mesmo estilo de badge, com HP **demo** (o lab não tem combate). No modo solo, só o badge do Abra aparece; no party, os três.
5. **HP demo:** os valores da primeira versão são de **teste visual** (ex.: 86/100, 100/100, 46/100) e ficam num dicionário fácil de trocar. O HUD final deve ler a vida real da party (`GameState.party`/`Combatant`), o que ainda não foi ligado porque o lab é isolado.
6. **Nada de combate/2D muda:** a HUD é de exploração/lab; batalha 3D, regras, party real e jogo 2D não são alterados por esta decisão.
7. **Ideias:** o criador pediu sugestões; elas ficam listadas abaixo como **não implementadas** até escolha.

## O que ainda precisa ser definido (ambiguidades)

- **Fonte do HP:** usar a vida real da party (Abra/Pancham) ou manter valores demo no lab? O Orc é seguidor visual (D-389), não membro da party; ele deve ter badge de vida?
- **Personagens:** mostrar só a party real (Abra + Pancham), os três visíveis no lab (Abra + Pancham + Orc) ou todos os aliados que existirem no mapa?
- **Conteúdo do badge:** só HP, ou também MP, ATB, status (veneno/stun), buffs/debuffs, nível/XP, retrato?
- **Estilo:** retrato do personagem, ícone, inicial ou só nome; barra fina/grossa; cor por personagem ou verde para todos; posição vertical centralizada ou começando abaixo do texto de controles.
- **Inimigos:** mostrar vida de inimigos também? O pedido fala em "personagens"; por ora, não.
- **Mini-mapa:** manter no canto superior direito? O texto de controles no topo esquerdo continua; o mini-mapa menor não deve colidir com ele.
- **Marcadores:** 20/14/16 px são o suficiente para ler o ícone exato? Ajustar depois do vídeo.

## Ideias de HUD (primeiro lote: MP e alerta de inimigo já implementados)

- **Party:** retratos dos personagens, HP + MP, pips de ATB (só em combate), status (veneno, stun, buffs), nível/XP, ícone de fraqueza/elemento.
- **Exploração:** andar/bioma atual, objetivo/quest tracker, contador de itens/baús, ouro, chave/porta especial, indicador de inimigo próximo/consciência, clima (D-383, só visual), seed do andar.
- **Mini-mapa:** bússola/norte, névoa de guerra, ícones de porta/escada/baú, zoom, rotação com a câmera, transparência.
- **SMT III:** fase da lua (se o jogo tiver a mecânica), indicador de negociação/compêndio, contador de demônios — **só se existir regra**; não inventar mecânica.
- **Qualidade de vida:** lembrete de controles, prompt de interação (já existe), aviso de HP baixo, indicador de “sem item”, atalhos de poção.

## Teste implementado (2026-11-09)

> **Atualização D-1064:** os PNGs do ícone e os marcadores 20/14/16 foram removidos; o mini-mapa agora usa bolinhas 12/8/10/10 (azul/branco/vermelho). O HUD de HP/MP e o alerta continuam.

- **Mini-mapa:** exibição **112×112** (metade), sem o título "MAPA"; o SubViewport interno continua 256×256 e o `TextureRect` é escalado em 0,4375. O quadro tem 120×120 e fica no canto superior direito. Marcadores em 20/14/16 px (jogador/aliados/inimigo), com o ícone exato e contorno escuro de 1 px.
- **Ícone exato:** o marcador usa quatro PNGs derivados do anexo do criador, com contorno escuro de 1 px: `marker_player.png` (20), `marker_ally.png` (14), `marker_enemy.png` (16) e `marker_npc.png` (16), em `assets/exploration/`; o desenho procedural antigo fica só de fallback. O mesmo desenho é tingido de verde/vermelho pelo `modulate`.
- **HUD:** três badges no extremo canto esquerdo, abaixo do texto de controles: **ABRA 86/100** (verde), **PANCHAM 100/100** (verde) e **ORC 46/100** (amarelo). Cada badge tem nome, barra de HP, número e uma barra de MP azul (demo: 14/20, 10/20, 8/20); painel escuro com borda dourada; a cor do HP acompanha o valor (verde >50%, amarelo 25–50%, vermelho ≤25%). No solo só o badge do Abra; no party os três.
- **HP/MP demo:** os valores são de teste visual; o lab não tem combate. A HUD final deve ler `GameState.party`/`Combatant`; o Orc é seguidor visual (D-389), então a lista final de badges ainda depende de decisão.
- **Alerta de inimigo:** um "!" vermelho no topo central aparece quando o Slime entra em `CHASE` e some quando volta a patrulhar; a auditoria confirma `false` no quadro 100 e `true` nos quadros 220/280. É a ideia de "indicador de inimigo próximo/consciência" do primeiro lote.
- **Auditoria solo:** badges=3, visíveis=1; MP=14/10/8; alerta `false` no 100 e `true` nos 220/280; ícone `res://assets/exploration/minimap_marker.png` (64×64); mini-mapa 112×112, escala 0,4375, centro (56,56), sem texto "MAPA"; 0 paredes/câmeras/paths/stack; porta e Slime em `CHASE`; toon `player=true/env=true`.
- **Auditoria party:** badges visíveis=3; MP=14/10/8; alerta `false` no 100 e `true` nos 220/280; mini-mapa com 4 marcadores visíveis; o resto igual.
- **Vídeos/stills:** `docs/referencias/exploracao/3d/murky_forest_solo.*`, `murky_forest_party.*`, `murky_forest_minimap.png`, `murky_forest_hud.png`; 11,0 s / 330 quadros.

## Estado

Primeira versão implementada no lab da Murky Forest. O mini-mapa de 112 px, o ícone exato, os badges de HP/MP e o alerta de inimigo estão no vídeo; a fonte real do HP/MP, a lista final de personagens, retratos/estilo e um NPC branco continuam pendentes. O jogo normal 2D, a batalha e as regras não mudam; nada publicado.
