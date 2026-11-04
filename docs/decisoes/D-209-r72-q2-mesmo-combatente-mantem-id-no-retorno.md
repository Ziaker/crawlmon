# D-209 — Rodada 72 Q2 (2A): conservar o ID do mesmo combatente quando ele retorna à batalha

- **Data:** 2026-11-04.
- **Área:** Combate / identidade estável / reentrada.
- **Origem:** aprovação expressa do criador na Rodada 72.
- **Estado:** regra condicional de identificação aprovada; **não cria mecânica de retirada ou retorno** nem está implementada nesta atividade.

## Declaração literal do criador

> 2A — O mesmo combatente conserva seu ID original ao retornar à mesma batalha.

## Regra aprovada

- Caso **o mesmo combatente** saia da participação ativa e **volte à mesma batalha**, **conservar seu ID original** nessa batalha. Não lhe atribuir um ID novo por ser um retorno do **mesmo indivíduo**.
- Preservar **D-196/D-200** (IDs únicos, estáveis, atribuídos à composição inicial pela ordem dos slots aliados e depois inimigos), e **D-206** (somente um **participante novo** recebe o **próximo ID ainda não utilizado**, sem renumeração ou reutilização de IDs).
- **Exemplo ilustrativo:** Gible recebeu ID 2 na composição inicial, saiu temporariamente e depois regressou **à mesma batalha**; Gible permanece com ID 2. Se Abra entrou pela primeira vez com ID 4 durante essa ausência, Abra continua com ID 4. Os valores absolutos são fictícios e não estabelecem ID inicial oficial.
- Os IDs continuam sendo critérios de **ordenação estável** para D-188 (candidatos empatados ao retarget) e D-192 (eventos simultâneos de retarget), **sem transformar RNG em seleção fixa por menor ID**. A D-095 mantém empate por eliminações simultâneas.

## Pendências e limites

- **Não autoriza nem define** uma mecânica de retirada temporária, substituição, reforços, reentrada ou ressuscitação; apenas estabelece a identidade **se** um retorno ocorrer por regra independente.
- Não especifica como verificar tecnicamente que se trata do **mesmo indivíduo**, o armazenamento/replay de identidades, a ordem de retornos simultâneos ou o destino de um participante em batalha distinta.
- Somente documentação; nenhum código, teste, cena, dado de Pokémon, VFX ou asset alterado.
