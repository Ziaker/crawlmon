# D-954 — Rodada 89B Q2 (2A): condição avaliada no instante mecânico próprio, com resultado rastreável

- **Data:** 2026-11-06.
- **Área:** Engine de Moves / condições declarativas / temporalidade / determinismo.
- **Origem:** aprovação expressa da Rodada 89B, questão 2.
- **Estado:** contrato documental aprovado; implementação e representação dos resultados pendentes.

## Declaração literal do criador

> 2A — Avaliar cada condição no instante mecânico definido para seu efeito, usando o estado autoritativo desse instante e preservando o resultado para rastreabilidade, sem reavaliação pelo VFX.

## Regra aprovada

- Cada **condição declarada de um efeito** é **avaliada no instante mecânico definido para aquele efeito**, consultando o **estado autoritativo da execução naquele instante**.
- O **resultado da avaliação deve ser preservado para rastreabilidade**. O consumidor visual **não reavalia a condição** nem interfere em sua resolução, conforme D-348 (plano mecânico autoritativo) e D-362 (eventos estruturados).
- O novo contrato integra D-374 (predicados/operadores declarativos tipados), D-361 (efeitos ordenados) e D-375 (ocorrências condicionais reservadas terminam executadas, canceladas ou não acionadas). **Registrar resultado de condição** e **registrar resultado terminal de ocorrência** são conceitos relacionados, mas não automaticamente idênticos.
- **Exemplo hipotético:** um efeito condicionado a uma interrupção usa o estado verificado **no seu instante de resolução mecânica**, não o estado anterior à declaração nem a duração de uma animação. O exemplo não cria nova condição e não muda a ficha de Fire Bullet.
- Preservar regras já aprovadas de elegibilidade, chance, resolução de status e consumo/ordem de RNG (incluindo D-234/D-267) e D-235 (qualquer atacante/lado/posição).

## Pendências e limitações

- **Não escolhidos:** formato da referência temporal, forma de capturar o estado e o resultado, política de dados ausentes, ordem de avaliação entre condições simultâneas e detalhes de serialização/replay. Não presumir segundo relógio mecânico, snapshot universal ou predicados específicos.
- **Somente documentação; nenhum código, Resource, VFX, Move, teste ou cena modificado.**
