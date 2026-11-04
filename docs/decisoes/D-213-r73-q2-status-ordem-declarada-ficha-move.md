# D-213 — Rodada 73 Q2 (2A): ordem das tentativas de status conforme a ficha do Move

- **Data:** 2026-11-04.
- **Área:** Combate / status distintos / resolução por Move.
- **Origem:** escolha expressa do criador na Rodada 73.
- **Estado:** regra de design aprovada, não implementada nesta atividade.

## Declaração literal do criador

> 2A — Resolver as tentativas de status distintos na ordem explicitamente declarada na ficha do Move.

## Regra aprovada

- Quando a ficha de um **Move declarar dois ou mais efeitos de status distintos**, **resolver as respectivas tentativas na ordem explicitamente declarada nessa ficha**.
- Complementar **D-210**: manter **no máximo uma tentativa por efeito de status distinto, por alvo e por execução**. Preservar **D-202/D-207/D-211** quanto aos requisitos de acerto válido, sobrevivência, último impacto do próprio alvo e tratamento de interrupções. Preservar **D-199/D-195** (dano/crítico antes de status; esquiva antes dos efeitos dependentes do acerto).
- **Exemplo somente ilustrativo:** a ficha de um Move hipotético declara primeiro `Poison` e depois `Paralysis`, ambos com condições de tentativa satisfeitas. **A tentativa de Poison é resolvida antes da de Paralysis**. O exemplo **não define uma ficha real nem a chance de sucesso** de qualquer efeito.
- A ordem declarada **não muda por si só** as chances previstas na ficha, as regras de Luck (D-134/D-146/D-156), o caráter garantido de efeitos previamente garantidos ou o número máximo de tentativas.
- **D-215 distingue a ordem das tentativas da prioridade de efeitos incompatíveis:** quando incompatibilidade estiver expressamente declarada, a regra específica de prioridade na ficha do Move deverá ser respeitada. **Não supor** que a ordem de tentativa equivalha automaticamente à prioridade de incompatibilidade.

## Limites e pendências

- Não foi especificado o tratamento de uma **ficha omissa quanto à ordem**, nem o modelo técnico/serialização da ficha, nem a existência de uma lista global de IDs de status.
- Não inventar regras de combinação, cancelamento ou incompatibilidade de status não aprovadas; a relação com o efeito já ativo, a ordem entre alvos simultâneos e consumo de RNG continuam assuntos distintos.
- Registro documental somente; nenhum código, teste, Move, ficha, cena, asset ou VFX alterado.
