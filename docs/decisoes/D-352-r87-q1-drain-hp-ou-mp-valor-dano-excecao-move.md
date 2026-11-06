# D-352 — Rodada 87 Q1 (1D): Drain recupera dano em HP ou MP; ambos somente por exceção expressa de Move

- **Data:** 2026-11-06.
- **Área:** Combate / afinidades elementais / Drain.
- **Origem:** regra própria expressa do criador na Rodada 87, substituindo a recomendação anterior da Q1.
- **Estado:** efeito conceitual e valor de recuperação aprovados; condições técnicas e implementação pendentes.

## Declaração literal do criador

> sigo suas recomendacoes exceto a primeira, Drain pode ser de MP ou de HP, recebendo o dano que sofreria em HP ou MP no lugar, nao pode ter um drain que tome ambos exceto se for um move especifico que permita isso

## Regra aprovada

- A afinidade **Drain** pode absorver dano elemental para recuperar **HP ou MP** do defensor, em vez de sofrer o dano correspondente.
- **O valor recebido como recuperação equivale ao dano que o defensor sofreria com o ataque**, caso não houvesse a absorção de Drain. Se a afinidade for de **HP**, essa quantidade é recebida em **HP**; se for de **MP**, é recebida em **MP**.
- **Por padrão, um mesmo Drain não recupera simultaneamente HP e MP.** A recuperação de **ambos** somente é permitida **quando um Move específico declarar expressamente essa exceção**; não presumir a exceção por afinidade, espécie, personagem, elemento ou ataque genérico.
- Esta decisão complementa **D-276** (afinidades por espécie com Null/Repel/Drain), **D-128** (afinidades definidas por espécie) e **D-235** (qualquer Move de qualquer lado/atacante). **Nenhuma espécie, elemento ou Move concreto recebeu Drain HP/MP ou exceção dupla nesta rodada.**
- **Exemplo estritamente hipotético:** diante de dano que seria de **30**, um defensor com Drain HP aplicável recuperaria **30 HP**, ou um com Drain MP aplicável recuperaria **30 MP**. **Não recebe 30 de ambos** salvo se um Move específico declarar essa exceção. O número 30 é ilustrativo; não homologa valores de dano reais.

## Pendências e limites

- Não foi definido **como calcular o valor de dano hipotético frente à mitigação, crítico, escudos, buffs ou efeitos condicionais**, nem se a recuperação pode ultrapassar máximos de HP/MP, como limitar o ganho por recurso, quais categorias de golpe são elegíveis, a ordem entre status e absorção ou o tratamento de múltiplos alvos/hits.
- **Não interpretar a exceção de um Move específico como autorização para uma afinidade de espécie recuperar os dois recursos automaticamente**. Também não fixar a divisão de recuperação quando um Move expressamente permitir ambos; isso dependerá da ficha daquele Move.
- A seleção de HP/MP e atribuição concreta de Drain às espécies ainda exigem fichas aprovadas. **Nenhum código, Move, Resource, ficha operacional, IA, HUD, VFX, teste ou cena alterado.**
