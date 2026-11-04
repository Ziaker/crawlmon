# D-193 — Rodada 68 Q2 (2A): resistência natural VIT/SPI antes dos estágios de DEF

- **Data:** 2026-11-04.
- **Área:** Combate / mitigação física e mágica.
- **Origem:** decisão expressa do criador na Rodada 68, aceitando a recomendação.
- **Estado:** regra de design aprovada; não implementada nesta atividade.

## Declaração literal do criador

> 2A — Aplicar a resistência natural de VIT/SPI antes do modificador de estágios de DEF.

## Regra aprovada

- Ao resolver dano que utiliza a defesa do alvo, calcular/aplicar **primeiro a mitigação pela resistência natural do atributo defensivo apropriado** e **depois o modificador correspondente aos estágios de Defense (DEF)**.
- Preservar **D-130/D-138**: para **dano físico**, resistência natural usa **VIT**; para **dano mágico/especial**, usa **SPI**; os mesmos estágios de DEF afetam as duas categorias. Não criar dois novos buffs de defesa nem alterar a categoria ofensiva dos Moves (D-122).
- Exemplo puramente matemático, não fórmula aprovada: dano hipotético de **100**, resistência natural hipotética subtrativa de **20** e estágio DEF hipotético **×0,8** → **(100 − 20) × 0,8 = 64**. A subtração de 20 e o multiplicador 0,8 são apenas ilustrativos; **a decisão fixa a ordem, não a operação matemática real da resistência**.
- Preservar as regras de fraqueza elemental, crítico, posicionamento e demais fatores já aprovados, sem estabelecer por esta escolha a ordem entre esses fatores e as duas etapas defensivas.

## Limites e pendências

- Não foram aprovadas fórmula numérica de VIT/SPI, coeficientes, limites, saturação, arredondamento nem posição relativa de fraqueza/crítico em toda a cadeia de dano; mínimos e imunidades são tratados separadamente em D-194.
- D-125/D-138 registravam a ordem de mitigação como pendente; esta escolha fecha **somente a ordem resistência natural → DEF** e preserva seu histórico anterior.
- Somente documentação. Não modificar código, dados, testes, cenas ou VFX.
