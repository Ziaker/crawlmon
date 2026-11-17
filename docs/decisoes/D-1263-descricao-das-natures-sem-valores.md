# D-1263 — Descrição das Natures nunca cita valores

- **Data:** 2026-11-16
- **Área:** pré-jogo, Natures, texto
- **Estado:** **registrada; texto aplicado nas 3 descrições que citavam valores**
- **Relacionadas:** [D-393](D-393-natures-iniciais.md), [D-1216](D-1216-dez-natures-novas.md), [D-1217](D-1217-reajuste-brave-timid-calm-adamant-para-3-status.md)

## Frase literal do criador

> "NENHUMA nature devia mencionar os valores que altera em seu texto, o texto é pra descrever resumidamente o que influencia na sua personalidade da IA e nos ganhos de level up"

## Decisão

1. O texto de toda Nature descreve, em resumo, o que ela influencia na personalidade da IA e nos ganhos de level up. Nunca cita números nem o formato `+N STAT`.
2. Isso **substitui** a regra de D-1217/D-432 de que a descrição citasse os modificadores exatos. Os modificadores em `NatureData` não mudam.
3. Aplicado em `PreGameCatalog.NATURE_DESCRIPTIONS`: Modest, Calm e Adamant (as únicas que citavam valores). O teste `_assert_nature_copy` agora falha se algum texto tiver número ou `+N STAT`.

## Ambiguidades / pendente

- As redações novas são da IA (só o conteúdo foi pedido pelo criador); o criador pode reescrevê-las.
- As demais descrições (Hardy…Careful) citam status só por nome, sem valores; mantidas.
