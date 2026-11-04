# D-228 — Fichas de Moves M1-Q4 (4A): MP adicional para Moves mágicos/especiais

- **Data:** 2026-11-04.
- **Área:** Fichas de Moves / economia de combate / MP.
- **Origem:** escolha expressa do criador na Rodada específica de Fichas de Moves M1.
- **Estado:** regra de design aprovada; valores individuais e implementação ainda pendentes. Nenhum código foi alterado nesta atividade.

## Declaração literal do criador

> 4A — Adotar MP como custo adicional de gameplay dos Moves mágicos/especiais, além dos recursos já aprovados, com valores individuais a definir e substituição expressa da regra sem MP da D-032.

> Observações e regras próprias: Quero exemplos de 4 moves antes de definir suas ideias

## Regra aprovada e precedência

- Os **Moves mágicos/especiais têm custo adicional de MP no gameplay**, além dos custos de **ATB/Burst aplicáveis conforme as decisões anteriores**. Cada Move terá seu **custo individual de MP**, **a definir**.
- Por determinação expressa posterior, **esta regra substitui apenas a antiga decisão de não utilizar custos de MP contida em** `docs/decisoes/D-032-balanceamento-moves-ingles-e-status.md`. **Preservar o texto e os demais requisitos de D-032 como histórico**: nomes dos Moves, poderes, windups, mecânicas de status e seus casos específicos não são revogados por esta escolha.
- A seção **14.6** de `docs/REGRAS_DO_JOGO.md` já registrava historicamente MP adicional para mágicos/especiais. A aprovação M1-Q4A resolve **expressamente a precedência do custo MP contra a exclusão específica da D-032**; outros detalhes daquela seção (máximo, recuperação, descontos em momentos específicos) **não são automaticamente revisados, re-homologados ou implementados** por esta escolha.
- **Preservar D-122:** a categoria **dano físico ou dano mágico/especial** não deve ser presumida automaticamente a partir da forma de execução `MELEE / PROJECTILE / CAST / STATUS`. **A classificação individual de Moves, os custos de MP e as exceções concretas permanecem pendentes**. Não classificar automaticamente todos os Moves de suporte como mágicos sem ficha aprovada.
- **Exemplo estritamente ilustrativo, sem custo aprovado:** um Move cuja ficha futura identifique natureza **mágica/especial** poderia ter `custo ATB: [valor aprovado]` e `MP: [valor ainda a definir]`. Esta anotação não introduz custo para nenhum Move específico.
- Não substituir por conta própria a mecânica preexistente de Burst, débito de ATB, contra-ataque, reembolso ou gasto de MP. Aplicar apenas as decisões anteriores já aprovadas, preservando conflitos históricos independentes.

## Respostas M1 que não produziram decisão

- **M1-Q1 = 1D**, **M1-Q2 = 2D** e **M1-Q3 = 3D** foram respondidas apenas com “Outra regra”, sem enunciar o novo formato escolhido. **Não há regra aprovada** para organização de textos, notação de modificadores ou modelagem de alvos nessa rodada.
- O criador **exigiu quatro exemplos de Moves antes de decidir esses três temas**. Exemplos apresentados em conversa são **demonstrativos e não aprovam valores, estrutura de campos, textos, efeitos, tipos ou novas mecânicas**.
- A série **M1** é separada das rodadas gerais numeradas. Nenhuma decisão adicional deve ser inferida de uma escolha D sem descrição.

## Estado verificado e limites

- Na `main` consultada, `scripts/data/skill.gd` define `cost` em ATB, `power`, `element`, `kind`, `windup`, `is_aoe`, `is_friendly`, `ground` e `aoe_on_contact`, mas **não contém um campo próprio de MP**. `scripts/combat/battle.gd` confirma recursos de ATB na seleção e não demonstra implementação da nova cobrança de MP.
- O número exato de MP por Move, natureza de dano de cada ficha, integração com recursos e testes de gameplay **não foram decididos nem executados**.
- **Somente documentação:** não modificar código, fichas de Move, testes, cenas, assets, VFX, dependências ou outros arquivos sem autorização.
