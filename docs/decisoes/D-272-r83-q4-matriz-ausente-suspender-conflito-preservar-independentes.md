# D-272 — Rodada 83 Q4 (4A): matriz sem entrada aprovada deixa conflito sem resolução e preserva efeitos independentes

- **Data:** 2026-11-05.
- **Área:** Combate / status incompatíveis de Moves diferentes / matriz e ausência de precedência.
- **Origem:** aprovação expressa do criador na Rodada 83.
- **Estado:** tratamento de política ausente aprovado; **não há pares ou precedências concretas homologados**; documentação apenas.

## Declaração literal do criador

> 4A — Quando faltar entrada aprovada para um par declarado incompatível, não resolver a aplicação conflitante nem eliminar status existentes; registrar a configuração pendente e preservar os demais efeitos independentes.

## Regra aprovada

- Quando **um par de status já tiver sido expressamente declarado incompatível** mas **não houver entrada de prioridade concretamente aprovada para esse par na matriz** das D-239/D-243, **não resolver a aplicação conflitante nem eliminar qualquer status existente com fundamento nesse conflito**.
- **Registrar a configuração pendente**, identificando que falta **prioridade aprovada para o par declarado incompatível**. **Preservar a resolução dos demais efeitos independentes elegíveis**, sem bloqueá-los ou descartá-los por causa da pendência desse par.
- Preservar **D-267**: resolver **elegibilidade e chance de aplicação antes de consultar a matriz**; só há conflito pendente a tratar sob essa ordem quando a tentativa chega à etapa de comparação relevante. **Não dispensar RNG ou mudar probabilidades** por ausência de entrada aprovada; chances finais exatas de 0%/100% continuam sem consumo conforme D-234.
- Preservar **D-253**: a futura matriz poderá cobrir conflitos simultâneos e status já ativos versus novos de Moves distintos. Preservar **D-257** somente **quando uma entrada de precedência já estiver aprovada**: eliminar o menor, sem restaurá-lo. **Não interpretar a ausência de entrada como aprovação implícita de um vencedor, da coexistência de status incompatíveis ou da eliminação do status existente**.
- **Exemplo abstrato e não normativa de pares reais:** X já está ativo; o novo status Y, de outro Move, é elegível e obtém sucesso. Uma regra expressa afirma que X e Y são incompatíveis, mas a matriz não tem prioridade aprovada: **não aplicar a resolução conflitante de Y nem remover X**, registrar a pendência; outro efeito Z independente e elegível do Move pode ser resolvido normalmente. Os rótulos X/Y/Z não representam status reais aprovados.

## Pendências e limites

- **Não existe ainda par concreto aprovado como incompatível nem prioridade preenchida na matriz.** Não inventar pares, regras de precedência ou novos bloqueios de Move na seleção por analogia.
- Não foi decidido se a tentativa conflitante fica armazenada para resolução posterior ou é encerrada sem reaplicação; não presumir aplicação retroativa quando a matriz vier a ser aprovada. Também permanecem pendentes **formato do diagnóstico**, tratamento de múltiplos pares simultâneos com conflitos interdependentes e política de UI.
- Preservar D-215 para prioridades expressas dentro da mesma ficha e D-095 para KO simultâneo; não extrapolar escopo a Moves/efeitos sem conflito entre si.
- Somente documentação; nenhum código, teste, ficha, Move, IA, HUD, asset, cena ou VFX modificado.
