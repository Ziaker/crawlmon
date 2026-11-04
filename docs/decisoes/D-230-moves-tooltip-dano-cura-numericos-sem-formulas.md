# D-230 — Fichas de Moves: valores de dano e cura numéricos na tooltip, nunca somente fórmulas ou multiplicadores

- **Data:** 2026-11-04.
- **Área:** Fichas de Moves / descrição legível em combate / valores numéricos.
- **Origem:** correção direta, posterior e expressa do criador aos exemplos da D-229.
- **Estado:** **regra de apresentação aprovada**, sem implementar cálculos ou ficha de Move nesta atividade.

## Declaração literal do criador

> TÁ PÉSSIMO VOU SABER OQ É 1X3 O DANO BASE?? É PRA TER NÚMEROS NÚMEROS NÃO FORMULAS

## Regra aprovada

- **Nas tooltips de combate, informar o dano e a cura em números concretos de pontos**, compreensíveis sem cálculo por parte do jogador. **Não substituir o valor de dano por “1,3× dano-base”, por uma expressão de atributos ou por uma fórmula**, nem usar somente multiplicador para informar dano.
- Quando um Move possuir multiplicador, escalonamento de atributos ou modificadores, **o número de dano/cura exibido deve refletir os parâmetros verificáveis que forem aplicáveis à informação mostrada**. Multiplicadores e fórmulas podem fazer parte das regras **internas da ficha/motor**, mas **não substituem o número concreto no texto da habilidade em combate**.
- A regra complementa **D-229**: manter **custo e windup acima** e **texto de efeitos completo abaixo**, com dano, cura, probabilidades, duração, modificadores e condições narrados juntos no mesmo bloco de texto. Continuar exibindo descrição estética/visual **somente na ficha fora de combate**.
- **Não fixar automaticamente** um valor universal de dano por Move: o usuário exigiu valores numéricos **na apresentação**, mas ainda não aprovou se o valor-base de design é fixo, se os números são dinâmicos por atacante/alvo ou como mostrar os números fora do combate quando esses contextos faltam. **Não decidir a arquitetura de cálculo, a regra numérica STR/MAG nem o momento do recálculo sem aprovação**.
- Se ainda **não existir um dano/cura numérico verificável** para determinado contexto ou versão futura do Move, **marcar o número como não definido ou dependente de calibração na documentação**, e **não inventar um número oficial**, mesmo para cumprir a exigência de apresentação.

## Exemplos de números demonstráveis no código atual — não são danos-base fixos oficiais

A `main` consultada inclui `scripts/combat/battle_scene.gd` com um **Gible de ataque 9**, que possui `Bite` de potência `1,3` e `Dragon Rage` de potência `1,6`. A função atual `scripts/combat/battle.gd::_hit` calcula dano por ataque e multiplicadores, e `scripts/combat/combatant.gd::take_damage` aplica estágio de DEF. **Numa situação delimitada com alvo sem fraqueza ao elemento, sem crítico, sem modificadores de ATK/DEF e passos neutros**, estes são resultados numéricos de referência:

- **Bite — 2 ATB, windup 1,2 s:** “Morde o inimigo e causa **12 pontos de dano**, com **30% de chance de aplicar Stun por 2 segundos**.” **12** é valor verificável **para esse Gible e esse cenário**, não dano-base fixo homologado.
- **Dragon Rage — 3 ATB, windup 2 s:** “Dispara um projétil que causa **14 pontos de dano** ao inimigo inicial e, se acertar, explode e causa **14 pontos de dano** a outros inimigos atingidos, se igualmente sem modificadores defensivos.” **14** é específico do exemplo.
- **Sand Attack — 1 ATB, windup 0,75 s:** “Causa **0 pontos de dano**. Se acertar, aplica **Blind durante 4 segundos**; cada ação ofensiva do alvo nesse período possui **35% de chance de errar**.” A chance de erro sob Blind não é chance de aplicação do próprio Blind.
- **Media — 2 ATB, windup 0,5 s:** a implementação atual restaura 40% do HP máximo por aliado com mínimo 12 e arredondamento. **Um aliado com 32 HP máximo** receberia **13 pontos de cura**, respeitando o HP faltante e HP máximo; **13 não é a cura universal da habilidade**. Nenhuma escala MAG foi presumida.

Esses números são **demonstrações de comportamento da implementação atual em condições específicas**, não homologação das fichas finais nem garantia de que os resultados permanecerão após o futuro sistema de atributos VIT/SPI/STR/MAG (D-122/D-123/D-198/D-205).

## Limites, precedência e escopo

- Esta decisão é **posterior** à D-229 e esclarece que os exemplos históricos de D-229 escritos como “1,3× dano-base” ou “1,6× dano-base” **não servem como formato de tooltip ao jogador**; preservar D-229 e a D-032 como registros históricos e de regras técnicas, sem apagar ou reescrever suas decisões.
- Custos de MP individuais e modelagem técnica de alvos permanecem pendentes conforme D-228 e M1-Q3 (3D). D-122/D-123 preservam atributos ofensivos da ficha e escalonamentos apenas aprovados; D-198/D-205 estabelecem arredondamento e D-203 exclui o odômetro do jogo principal. D-061 exige preservar conflitos e não implementar sem autorização.
- **Somente documentos**: nenhum código, tooltip de HUD, ficha técnica de Move, animação, VFX, cena ou teste alterado; nenhum teste de gameplay realizado.
