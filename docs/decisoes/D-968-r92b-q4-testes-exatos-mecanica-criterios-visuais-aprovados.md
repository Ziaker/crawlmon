# D-968 — Rodada 92B Q4 (4A): conformidade mecânica determinística exata e critérios visuais específicos aprovados

- **Data:** 2026-11-07.
- **Área:** Engine de Moves / testes de conformidade / sincronização mecânico-visual.
- **Origem:** decisão expressa da Rodada 92B, questão 4.
- **Estado:** critérios normativos aprovados; testes ainda não implementados ou executados.

## Declaração literal do criador

> 4A — Exigir correspondência determinística exata para identidades, ordem e marcos mecânicos; para apresentação visual, usar critérios mensuráveis específicos e previamente aprovados, sem inventar tolerâncias.

## Regra aprovada

- Exigir **correspondência determinística exata de identidade, ordem e marcos mecânicos** nos testes de conformidade da engine, respeitando os contratos normativos e eventos efetivamente previstos.
- Para **apresentação visual**, validar por **critérios mensuráveis próprios e previamente aprovados**, adequados ao caso visual, **sem presumir tolerâncias genéricas**, tempos, números de frames ou limites não autorizados.
- Não usar margem visual arbitrária para aprovar divergências de identidade, ordem ou marcos mecânicos. A existência de variações visuais aceitáveis requer critério concreto previamente aprovado.
- Preservar **D-351** (testes automatizados de identidade, eventos, ordem, tempos e integração visual em interrupções, variantes, lados espelhados e anatomias distintas), **D-235**, **D-348/D-362** (plano mecânico autoritativo e eventos estruturados), **D-956/D-959** (fluxo e IDs determinísticos) e **D-967** (rastros reproduzíveis).
- **Exemplo abstrato:** teste compara exatamente os IDs e a ordem de eventos mecânicos; partículas e dissipação são avaliadas por medidas aprovadas para o respectivo efeito visual, não por um valor universal arbitrário.

## Pendências e limites

- **Não definidos:** conjunto exato de casos, implementação de harness Godot, tolerância visual específica de cada Move/efeito, método de medição visual, critérios de regressão de frames ou aprovação de Move piloto. Sem esses dados, **não alegar que a engine já foi validada**.
- **Somente documentação**: nenhum código, Resource, VFX, Move ou teste modificado/executado.
