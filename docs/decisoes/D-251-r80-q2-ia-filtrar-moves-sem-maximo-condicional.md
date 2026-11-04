# D-251 — Rodada 80 Q2 (2A): IA também filtra Moves com máximo condicional obrigatório ausente

- **Data:** 2026-11-04.
- **Área:** Combate / IA / seleção tática / completude de Moves.
- **Origem:** escolha 2A expressa do criador na Rodada 80.
- **Estado:** filtro tático aprovado; não implementado nesta atividade documental.

## Declaração literal do criador

> 2A — Excluir também os Moves sem máximo obrigatório de ocorrências condicionais da lista da IA antes da escolha tática, sem consumir ação ou recursos.

## Regra aprovada

- **Antes da avaliação e escolha tática pela IA**, remover da **lista de Moves candidatos** aqueles que tenham **plano de ocorrências condicionais incompleto por ausência do limite máximo explícito obrigatório** definido em D-233/D-238.
- Esta é uma **segunda causa expressamente aprovada** de exclusão prévia, adicional à falta de prioridade entre status declarados incompatíveis **D-232/D-215/D-217/D-221**. Não estender automaticamente a outros defeitos de ficha.
- A **exclusão** não inicia ação nem consome **ATB, Burst, MP ou oportunidade de ação**, preservando D-225/D-238. **Os custos de ações válidas confirmadas continuam regidos pelas decisões vigentes**, inclusive MP de Moves mágicos/especiais conforme D-228.
- **Exemplo apenas ilustrativo:** a IA tem três Moves disponíveis; um Move tem ocorrências condicionais variáveis, mas **não declara máximo**. Esse Move é excluído **antes da comparação tática** com os dois candidatos válidos; não é selecionado para depois ser rejeitado.
- Preservar **D-237/D-241**: se **nenhum Move válido** restar, a IA **pode considerar Tackle separadamente quando elegível**. Se **Tackle também for inelegível**, a IA **não inicia ação nem gasta recursos** e **reavalia na próxima oportunidade normal**. A presente decisão não altera os critérios de elegibilidade de Tackle nem cria fallback por Move individual.
- A regra se aplica a qualquer atacante controlado pela IA, sem dependência de espécie, lado ou posição (D-235).

## Pendências e escopo

- Não determina novos pesos táticos, quais Moves concretos carecem do máximo, a implementação do filtro, a interface de diagnóstico ou uma periodicidade adicional para decisões.
- A ausência de **outros** campos obrigatórios continua tema distinto, sem novo bloqueio genérico por inferência.
- Somente documentação; nenhum código, IA, teste, Move, ficha, cena, asset ou VFX modificado.
