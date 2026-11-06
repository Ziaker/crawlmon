# D-348 — Rodada 86B Q1 (1A): plano mecânico é a autoridade dos eventos e tempos

- **Data:** 2026-11-06.
- **Área:** Engine de Moves / eventos / sincronização mecânico-visual.
- **Origem:** aprovação expressa na Rodada 86B, questão 1.
- **Estado:** requisito de arquitetura aprovado; não implementado.

## Declaração literal do criador

> 1A — O plano mecânico é a fonte autoritativa dos eventos e tempos; a apresentação visual recebe os gatilhos correspondentes.

## Regra aprovada

- O **plano de execução mecânica do Move é a fonte autoritativa dos eventos e de seus tempos**. A apresentação visual **recebe os gatilhos correspondentes** e deve respeitar os marcos mecânicos relevantes.
- A visualização **não estabelece outra cronologia mecânica independente** e seus ajustes puramente cosméticos não podem modificar dano, custos, chance, aplicação de status, ordem dos efeitos, elegibilidade ou instante de resolução mecânica.
- **Exemplo ilustrativo:** Fire Bullet pode apresentar mão de fogo, anéis e projétil após os gatilhos definidos no plano mecânico; mudar o tempo de dissipação de anéis não desloca a resolução mecânica do impacto nem altera Burn. O exemplo **não aprova** gatilhos, durações ou efeitos novos para esse Move.
- Preservar **D-226**: índices de ocorrências possíveis, inclusive condicionais, são reservados na **declaração** do ataque. Preservar **D-242/D-252** sobre ocorrências excedentes. Preservar **D-235**: o mesmo plano e seus gatilhos servem a qualquer atacante e lado. Preservar **D-333/D-337/D-339–D-343** quanto a fichas lógicas, Resources tipados, arquivos separados, etapas VFX e migração.
- **Divergência de implementação identificada na inspeção estática da main `28816628d8a96489329369dd6740c0ffec88e877`:** `Battle.use_skill` declara o ataque e inicia Windup, mas `AttackPlanner.plan(inc)` é chamado em `Battle._resolve_incoming` depois do Windup. O código ainda não cumpre automaticamente a reserva na declaração da D-226; esta decisão não autoriza alterar o código nem presume conciliação realizada.

## Pendências e limites

- O **formato de evento/gatilho**, a representação do plano, relógio concreto, precisão temporal, mecanismos de emissão/consumo, ordem entre fases concorrentes e tratamento de cancelamentos precisam de especificação e testes posteriores. A seleção da autoridade **não escolhe silenciosamente esses detalhes técnicos**.
- **Somente documentação:** nenhum código, Resource, teste, Move, VFX ou cena modificado.
