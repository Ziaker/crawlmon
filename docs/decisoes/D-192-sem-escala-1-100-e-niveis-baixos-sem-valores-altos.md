# D-192 — Sem escala 1–100; personagens em níveis baixos não têm valores exorbitantes

- **Data:** 2026-11-04 (corrigida no mesmo dia)
- **Área:** Personagens / atributos
- **Origem:** decisão direta do criador, na conversa.
- **Estado:** regra registrada; **sem implementação**. Numeração: D-192 evita os IDs usados nas duas séries (GitHub até D-191; local até D-170).

## Declaração literal do criador

> eu digo que nao e pra ter valores exorbitantes pra personagens em niveis baixos, essa regra de 1-100 e idiota e ja mandei remover ela de tudo

> PARA COM ISSO DE LIMITE DE 10 VC NAO ENTENDEU O QUE EU QUIS DIZER PARA DE LEVAR COMO REGRA AFF

## Regra aprovada

- **A escala-base de 1 a 100 deixa de valer.** Isso encerra o que restava dela depois da D-139: a escala-base inicial 1–100 da R10-Q2 / D-067 do GDD e o limite 1–100 da D-129.
- **Personagens em níveis baixos não têm valores exorbitantes**; os valores crescem com o nível.
- **Não existe "limite de 10" como regra.** O criador disse antes "no inicio do jogo nao e pra ter valor base maior que 10 no nivel 1" e depois corrigiu: aquilo **não é uma regra** e foi mal interpretado como tal. O número 10 não vale como teto, piso ou valor-alvo.
- Preservados: os seis atributos (STR, MAG, VIT, SPI, AGI, LUK, D-131), a ausência de teto máximo permanente (D-139) e a separação dos buffs (D-129, parte histórica).

## Ambiguidades em aberto (perguntar antes de agir)

- Qual é a ideia que o criador quis dizer com o "10" e com "valores exorbitantes": que ordem de grandeza ou que referência define um valor baixo para o nível 1? Não presumir um número.
- Se a regra vale para HP e MP (o criador respondeu "é obvio que eles sao, pq nao seriam", ainda sem o sentido do "10" esclarecido).
- Se vale para todos os Pokémon, inclusive inimigos.

## Estado no código

Nenhuma alteração. O módulo `scripts/combat/crawlmon_attribute_math.gd` não usa a escala 1–100 como teto (só o piso 1 do cálculo).
