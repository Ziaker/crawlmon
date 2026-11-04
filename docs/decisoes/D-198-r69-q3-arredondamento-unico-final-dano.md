# D-198 — Rodada 69 Q3 (3A): precisão fracionária e um único arredondamento final de dano

- **Data:** 2026-11-04.
- **Área:** Combate / cálculo de dano / arredondamento.
- **Origem:** escolha expressa do criador, aceitando a recomendação na Rodada 69.
- **Estado:** regra de design aprovada e registrada; não implementada nesta atividade.

## Declaração literal do criador

> 3A — Manter precisão fracionária até terminar os modificadores de dano, arredondar uma vez ao final e então aplicar o mínimo quando cabível.

## Regra aprovada

- **Preservar precisão fracionária ao longo dos modificadores de dano**, **arredondar apenas uma vez** ao completar o cálculo do dano e **somente depois aplicar o mínimo de dano quando cabível** conforme D-194.
- A alternativa **3A** apresentada ao criador especificava **arredondamento ao inteiro mais próximo**. Não usar arredondamentos intermediários entre resistência natural VIT/SPI, estágio de DEF ou outros multiplicadores de dano. **Não foi escolhido um critério de desempate para resultados terminados exatamente em 0,5**, nem precisão numérica de implementação.
- Exemplo estritamente hipotético e **não uma fórmula autorizada**: 9,4 × 0,7 × 0,8 = 5,264; arredondar **uma vez ao final** resulta em **5**, enquanto arredondamentos após cada fator podem divergir. Os fatores não são coeficientes oficiais de VIT, SPI ou DEF.
- Se um golpe danoso acertar validamente e não houver imunidade ou bloqueio completo, preservar **mínimo de 1** após o arredondamento (D-194). Imunidade/bloqueio completo permanece como exceção; a regra não cria dano em golpes que erraram ou foram esquivados (D-195).
- **D-193 preservada:** o cálculo da resistência natural precede o dos estágios de DEF. **D-197 preservada:** mitigação percentual de retornos decrescentes, sem curva numérica aprovada.

## Divergência com o código atual e limites

- Na `main` consultada, `scripts/combat/battle.gd` arredonda com `roundi` em `_hit()` antes de chamar `target.take_damage(dmg)`, e `scripts/combat/combatant.gd` arredonda novamente `amount * def_mult`. Isso **não satisfaz a nova exigência de arredondamento único global**, e o código ainda não integra a mitigação natural VIT/SPI. **Apenas registrar a divergência, sem corrigir código.**
- A questão não determina outros detalhes da cadeia de dano, ordem de fraqueza/crítico relativa à defesa, nem o comportamento de exceções ainda não especificadas.
- Somente documentação. Nenhum arquivo de código, testes, cenas, assets, VFX ou dados foi alterado.
