# D-199 — Rodada 69 Q4 (4A): crítico e dano antes do status dependente de acerto se alvo sobreviver

- **Data:** 2026-11-04.
- **Área:** Combate / ordem de impacto / status condicionado ao acerto.
- **Origem:** escolha expressa do criador, aceitando a recomendação na Rodada 69.
- **Estado:** regra de design aprovada e registrada; não implementada nesta atividade.

## Declaração literal do criador

> 4A — Resolver crítico e dano primeiro; aplicar status dependente de acerto somente se o alvo sobreviver.

## Regra aprovada

- **Após confirmar um acerto válido**, resolver **crítico e dano primeiro**. Um **efeito de status dependente desse acerto** só pode ser aplicado **se o alvo sobreviver ao dano desse golpe**.
- Se o dano for fatal para o alvo, **não aplicar status condicionado ao acerto ao combatente já derrotado**. Isso abrange a aplicação de um status cuja chance fosse probabilística; não consumir uma nova rolagem de aplicação ao alvo morto para esse efeito.
- Exemplo ilustrativo: Pancham acerta Abra com um golpe que pode causar crítico e Stun dependente do acerto. A esquiva automática falhou, o crítico foi resolvido e o dano causa KO em Abra. **Não aplicar nem rolar Stun condicionado àquele acerto**. Se Abra sobreviver, a tentativa de status segue as regras aplicáveis à sua ficha e à LUK (D-134/D-146/D-156).
- **D-195 permanece:** para golpes elegíveis à esquiva automática, esta é resolvida **antes** de qualquer rolagem de crítico e de status dependente de acerto; se esquivar, o golpe erra. **D-012 permanece:** Moves de debuff de alvo único não esquiváveis não recebem esquiva nova. Efeitos declarados garantidos mantêm sua garantia **quando suas próprias condições de aplicação forem cumpridas** (D-134).
- Não interpretar esta decisão como regra para **efeitos de status independentes do acerto**, buffs aliados ou efeitos especiais de Move com condições próprias, nem como nova prioridade de vitória/derrota de ataques simultâneos (D-095).

## Limites e pendências

- A regra não determina detalhadamente a sequência entre impactos de Moves multi-hit e efeitos de status entre impactos, nem o uso do HP visual de odômetro para reconhecer sobrevivência. Condições e checkpoints lógicos de sobrevivência, quando houver tempo de resolução especial, devem respeitar a mecânica aprovada, sem serem inventados aqui.
- Preservar a divergência de reapresentação da Rodada 60 para a escala de LUK: este registro não resolve D-150 versus a transcrição 2A nem D-152/D-153 versus transcrição 3A do GDD §12.13.
- Somente documentação. Nenhum código, teste, ficha de Move, cena, asset ou VFX alterado.
