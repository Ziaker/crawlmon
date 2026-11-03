# D-150 — Rodada 60 Q2 (2B): crítico normal recebe 1 pp por ponto da diferença de LUK

- **Data:** 2026-11-03.
- **Área:** Combate / crítico / Luck.
- **Origem:** escolha expressa do criador.
- **Estado:** regra de design aprovada; não implementada nesta atividade.

## Declaração literal do criador

> 2B — Como LUK deve modificar a chance de Critical Hit? Preservar 10% de base e acrescentar 1 ponto percentual por ponto de diferença. No exemplo: 40%.

## Regra aprovada

- Para **crítico normal probabilístico**, preservar **10% de chance-base** e somar **1 ponto percentual por ponto da diferença de LUK (atacante − alvo)**.
- Fórmula, considerando probabilidades em porcentagem: **P_crítico = clamp(10 + LUK_atacante − LUK_alvo, 0, 100)**, aplicando os limites aprovados em **D-151**.
- Exemplo fornecido pelo criador: atacante com **LUK 70**, alvo com **LUK 40**: **10% + 30 pp = 40%**.
- Preservar D-127: LUK influencia crítico, esquiva automática e aplicação de status, cada qual com sua regra. Esta escolha **não** define o coeficiente de esquiva automática (R60-Q3D pendente).
- Preservar D-146 como regra independente de aplicação probabilística de status. Não transformar críticos já garantidos por outras regras em rolagens probabilísticas.

## Limites e pendências

- A taxa de crítico atual em código é **CRIT_CHANCE = 0.1** em scripts/combat/battle.gd; registrar uma regra não é implementá-la.
- Permanecem sem nova definição nesta questão: outros modificadores de crítico, precedência com immunidades/proteções e política de rolagem em casos simultâneos.
- Atributos LUK podem exceder 100 (D-139); isso não expande o intervalo final da probabilidade (D-151).

## Escopo

Somente registro documental. Nenhuma alteração de código, cena, ficha, VFX, teste ou configuração.
