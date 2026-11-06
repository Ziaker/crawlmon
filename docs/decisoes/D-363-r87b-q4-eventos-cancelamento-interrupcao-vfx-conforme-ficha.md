# D-363 — Rodada 87B Q4 (4A): cancelamento e interrupção explícitos com reação visual aprovada por Move

- **Data:** 2026-11-06.
- **Área:** Engine de Moves / ciclo de vida de ocorrências / VFX / cancelamentos.
- **Origem:** aprovação expressa da Rodada 87B, questão 4.
- **Estado:** comunicação de cancelamento aprovada; rotinas concretas por Move não implementadas.

## Declaração literal do criador

> 4A — Propagar eventos explícitos de cancelamento e interrupção; a apresentação encerra ou dissipa os efeitos segundo regras visuais já aprovadas para o Move, mantendo casos não definidos como pendentes.

## Decisão aprovada

- O plano/execução mecânica deve **propagar eventos explícitos de cancelamento e de interrupção** aos consumidores visuais, com correlação ao Move e à ocorrência correspondente conforme o contrato da **D-358**.
- A apresentação **encerra ou dissipa efeitos visuais conforme a especificação já aprovada para aquele Move**. Quando o resultado visual de um cancelamento/interrupção ainda **não estiver definido**, registrar a lacuna como **pendente** em vez de inventar animação, duração ou comportamento universal.
- A notificação visual **não altera** os resultados mecânicos, não executa impacto cancelado, não reinicia ocorrências, não altera custos nem permite uso de RNG além das regras aprovadas (**D-222/D-226/D-242/D-252/D-348**).
- Preservar **D-235**: mesmo tratamento deve funcionar com qualquer atacante/alvo e em lados espelhados; **D-351** exige testar interrupções, variantes quando houver e integração mecânico-visual.
- **Exemplo hipotético:** um ataque é interrompido antes de seu impacto. O consumidor visual recebe o evento de interrupção e segue **a regra específica aprovada de dissipação**, se existente. Se nenhuma dissipação foi especificada, isso **continua pendente**, sem determinar desaparecimento imediato nem conclusão normal por padrão.

## Pendências e limites

- Não foram definidos como identificar o conjunto exato de VFX vivos por ocorrência, a política universal de cleanup, as fases de dissipação para Moves sem especificação, fila de eventos, ordenação no mesmo instante, formato do evento ou comportamento do runtime diante de recursos ausentes.
- Somente documentação: nenhum código, Resource, Move, VFX, HUD, cena ou teste criado/alterado.
