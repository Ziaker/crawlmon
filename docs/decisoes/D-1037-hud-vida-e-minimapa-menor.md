# D-1037 — HUD de exploração: mini-mapa menor e badges de vida à esquerda

- **Data:** 2026-11-09
- **Área:** Exploração / HUD / mini-mapa / UI 3D
- **Origem:** depois de ver o lab da Murky Forest com o mini-mapa top-down (D-1027/D-1028), o criador pediu ajustes de tamanho/texto e uma HUD de vida.
- **Status:** direção registrada; **primeira versão visual a implementar no lab**; fonte real do HP, personagens exatos e estilo final ainda pendentes; nada de combate/2D muda; nada publicado.

## O que o criador disse (literal)

> perfeito, mas diminua o tamanho do minimapa pela metade, não precisa do texto dizendo do mini mapa

> adicione badges no extremo canto esquerdo que mostra a vida dos personagens, um hud mesmo, me dê mais ideias que poderia colocar

## Decisão

1. **Mini-mapa pela metade:** o quadro/render do mini-mapa deve ter **50% do tamanho atual** (de 224×224 para 112×112 px de exibição; o SubViewport interno pode continuar 256×256). Os marcadores também caem pela metade (jogador 9 px, aliados 6 px, inimigo 8 px) para manter a proporção.
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
- **Marcadores:** 9/6/8 px é o suficiente para ler? Ajustar depois do vídeo.

## Ideias de HUD (não implementadas; escolher)

- **Party:** retratos dos personagens, HP + MP, pips de ATB (só em combate), status (veneno, stun, buffs), nível/XP, ícone de fraqueza/elemento.
- **Exploração:** andar/bioma atual, objetivo/quest tracker, contador de itens/baús, ouro, chave/porta especial, indicador de inimigo próximo/consciência, clima (D-383, só visual), seed do andar.
- **Mini-mapa:** bússola/norte, névoa de guerra, ícones de porta/escada/baú, zoom, rotação com a câmera, transparência.
- **SMT III:** fase da lua (se o jogo tiver a mecânica), indicador de negociação/compêndio, contador de demônios — **só se existir regra**; não inventar mecânica.
- **Qualidade de vida:** lembrete de controles, prompt de interação (já existe), aviso de HP baixo, indicador de “sem item”, atalhos de poção.

## Estado

Direção registrada; nada implementado ainda. A primeira versão será feita no lab da Murky Forest, com HP demo e os três personagens visíveis; a fonte real do HP e o estilo final ficam pendentes. O jogo normal 2D, a batalha e as regras não mudam.
