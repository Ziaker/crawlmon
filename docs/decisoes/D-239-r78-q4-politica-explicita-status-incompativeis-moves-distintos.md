# D-239 — Rodada 78 Q4 (4A): exigir política aprovada para status incompatíveis provenientes de Moves diferentes

- **Data:** 2026-11-04.
- **Área:** Combate / status / conflitos entre Moves / prioridade.
- **Origem:** resposta expressa do criador na Rodada 78.
- **Estado:** exigência de decisão explícita aprovada; **política de precedência concreta não definida nesta rodada**; sem implementação.

## Declaração literal do criador

> 4A — Exigir uma política explícita de prioridade entre status incompatíveis provenientes de Moves diferentes, definida e aprovada antes de resolver tal conflito; não inferir prioridade das fichas isoladas.

## Regra aprovada

- Quando **efeitos provenientes de Moves diferentes** forem **expressamente declarados incompatíveis**, será necessária uma **política explícita de prioridade entre esses efeitos**, **definida e aprovada pelo criador antes de resolver o conflito**.
- **Não inferir** qual status prevalece a partir das prioridades **isoladas** nas fichas de cada Move, da ordem declarativa de tentativas, do ID dos atacantes ou da ordem de consumo do RNG.
- Preservar **D-215/D-217/D-221** para incompatibilidade **de efeitos declarados na mesma ficha de Move**; a nova exigência **não substitui** essas regras. Preservar **D-213** quanto à ordem de tentativas dentro da ficha e **D-219/D-223/D-227/D-234** quanto à ordem e ao consumo do RNG de status. Essas ordenações **não definem prioridade lógica de aplicação** entre Moves concorrentes.
- **Exemplo puramente abstrato:** um Move aplica o efeito X, outro aplica Y, e uma regra futura estabelece que X e Y são incompatíveis. Mesmo se ambas as tentativas forem elegíveis e bem-sucedidas, **não determinar um vencedor sem a política de prioridade entre Moves aprovada**. O exemplo não declara incompatibilidade real de qualquer par de status do Crawlmon.
- **A D-095 permanece:** nenhuma prioridade nova de dano, eliminação simultânea, vitória/derrota ou cronologia dos eventos é derivada deste requisito.

## Pendências e limites

- **Não foram aprovados** o formato/local da política (global, por combinação de status, por Move ou outro), a prioridade concreta de qualquer par, o comportamento de validação/bloqueio antes de existir a política, tratamento de conflitos entre efeitos ativos e novos, ou desempates adicionais.
- Registrar o conflito como **não resolvido** até aprovação; não escolher unilateralmente entre aplicar, suprimir ou substituir efeitos e não criar bloqueio automático não aprovado.
- Somente documentação; nenhum código, teste, Move, ficha, cena, asset ou VFX modificado.
