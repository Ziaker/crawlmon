# D-208 — Rodada 72 Q1 (1A): calibrar K por atributo defensivo de referência e mitigação-alvo

- **Data:** 2026-11-04.
- **Área:** Combate / VIT / SPI / calibração da curva racional.
- **Origem:** aprovação expressa do criador na Rodada 72.
- **Estado:** **método de calibração aprovado**; referência, alvo e K numérico **não aprovados nem calculados para o jogo**. Nenhuma implementação nesta atividade.

## Declaração literal do criador

> 1A — Calibrar K a partir de um valor de atributo defensivo de referência e de uma porcentagem de mitigação-alvo, ambos submetidos posteriormente à aprovação.

## Regra aprovada

- Para a curva natural de mitigação **R(x) = x/(x+K)** (D-201), com **K > 0** e **valor único compartilhado por VIT/SPI** (D-204), **calibrar K a partir de dois parâmetros de referência**: (i) um **valor de atributo defensivo de referência** e (ii) uma **porcentagem de mitigação-alvo** para esse atributo.
- **Ambos os parâmetros devem ser apresentados para aprovação posterior do criador**; não selecionar silenciosamente quaisquer números ou tratar um exemplo como referência oficial. O valor de **K resultante também deverá ser apresentado e validado antes de ser adotado**, preservando a D-201 e a D-204.
- **Exemplo somente algébrico, sem aprovação de números:** para atributo hipotético `x_ref=50` e mitigação-alvo hipotética `R=25%=0,25`, `0,25=50/(50+K)`, portanto `K=150`. **Os números 50, 25% e 150 são fictícios**; não configuram parâmetros ou metas do Crawlmon.
- **Consequência matemática, não nova regra de balanceamento:** quando `x_ref>0` e a mitigação pretendida estiver entre `0%` e `100%`, a expressão invertida é `K = x_ref × (1-R_alvo)/R_alvo`. Pontos de calibração incompatíveis com `K>0` não podem ser impostos por inferência.
- Preservar: **VIT para dano físico e SPI para dano mágico** (D-130), resistência natural antes dos estágios de DEF (D-193), arredondamento único final (D-198/D-205), mínimo após acerto válido salvo imunidade/bloqueio total (D-194) e atributos permanentes sem teto máximo (D-139).

## Pendências e limite de execução

- Faltam **atributo de referência e porcentagem-alvo aprovados**, seleção de amostra/verificação que os sustente e **homologação posterior do valor calculado de K**. Esta rodada **não autoriza qualquer valor numérico de K** nem altera a fórmula.
- Nenhum teste de balanço ou gameplay executado; nenhum código, teste, Move, cena, asset ou VFX modificado.
