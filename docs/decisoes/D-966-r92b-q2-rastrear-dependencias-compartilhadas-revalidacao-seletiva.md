# D-966 — Rodada 92B Q2 (2A): dependências explícitas e revalidação seletiva de Moves afetados

- **Data:** 2026-11-07.
- **Área:** Engine de Moves / dependências compartilhadas / invalidação e validação.
- **Origem:** decisão expressa da Rodada 92B, questão 2.
- **Estado:** requisito aprovado; sem implementação ou testes.

## Declaração literal do criador

> 2A — Manter dependências explícitas e, quando um componente compartilhado mudar, invalidar e revalidar os Moves efetivamente dependentes dele antes de disponibilizar as novas configurações.

## Regra aprovada

- A engine deve **manter referências explícitas às dependências reutilizadas pelos Moves**, inclusive componentes mecânicos e visuais compartilhados conforme as definições aplicáveis.
- **Quando um componente compartilhado mudar**, invalidar os resultados de validação dos **Moves efetivamente dependentes dele** e **revalidá-los antes de disponibilizar suas configurações atualizadas**.
- O contrato não estabelece uma revalidação indiscriminada de todos os Moves em cada alteração, nem autoriza ignorar alterações indiretas de componentes dos quais uma configuração efetivamente dependa.
- Preservar **D-340/D-341** (efeitos reutilizáveis e pipeline visual), **D-955/D-957** (validação e invalidação de resultados obsoletos), **D-965** (ativação do par validado) e **D-235** (independência de personagem/lado).
- **Exemplo hipotético:** um VFX compartilhado por cinco Moves muda; os Moves cuja configuração realmente depende daquele componente têm sua validação invalidada e refeita antes de ativar uma versão que o utilize. O exemplo não aprova novos VFX, recursos ou alterações reais.

## Pendências e limites

- **Não definidos:** formato do grafo de dependências, política de dependências transitivas, identificação de alterações, tratamento de ciclos e falhas, escopo de dependências opcionais, concorrência de invalidadores ou representação do resultado de validação. Não inventar algoritmo específico.
- **Somente documentação**: nenhum script, Resource, VFX, Move, teste ou cena alterado.
