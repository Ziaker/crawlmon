# D-383 — Rodada 91 Q3 (3B): furtividade ambiental, esconderijos e coberturas na exploração

- **Data:** 2026-11-06.
- **Área:** Exploração 2D / detecção de inimigos / furtividade ambiental.
- **Origem:** aprovação expressa do criador na Rodada 91.
- **Estado:** possibilidade de furtividade ambiental aprovada; implementação e parâmetros pendentes.

## Declaração literal do criador

> 3B — Permitir furtividade ambiental na exploração, como esconder-se e aproveitar coberturas para evitar a detecção antes do contato hostil.

## Regra aprovada

- **Permitir ao jogador aproveitar esconderijos e coberturas no ambiente durante a exploração para tentar evitar a detecção inimiga antes do contato hostil.**
- Preservar **D-205 / GDD R38-Q1**: a detecção dos inimigos é **principalmente por proximidade, sem exigir linha de visão estrita**. A presença de cobertura ou esconderijo poderá ser considerada nas **condições de furtividade** ainda a definir, mas **não altera a regra geral para um sistema universal de visão/linha de visão estrita**.
- Preservar patrulha/perseguição após detecção (**GDD R9-Q3**) e início de combate por **contato hostil com qualquer integrante ativo** (**GDD R37-Q1**); a furtividade não concede imunidade automática a combate depois desse contato.
- **Exemplo hipotético:** o jogador utiliza uma cobertura em um corredor com patrulha para tentar passar sem ser percebido. A geometria, alcance, efetividade e comportamento real da patrulha não foram definidos por este exemplo.
- Não inferir automaticamente uso de HMs/TMs fora de combate, pois **GDD R24-Q4** mantém essas ferramentas restritas ao combate por enquanto.

## Pendências e limites

- Não definidos: condições específicas de esconder-se, que objetos fornecem cobertura, alcance/ângulos de detecção, efeitos sobre a detecção por proximidade, interação com aliados em fila, velocidade, agachamento, estados de alerta, duração e consequência de falha.
- A decisão não cria comandos, animações, itens, bônus de iniciativa ou mecanismos de distração.
- **Somente documentação:** nenhum mapa, cena, tileset, código, navegação, IA, UI, asset, teste ou VFX modificado.
