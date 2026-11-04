# D-207 — Rodada 71 Q4 (4A): status de cada alvo depois de seu último impacto

- **Data:** 2026-11-04.
- **Área:** Combate / multi-hit / status condicionado ao acerto / alvos múltiplos.
- **Origem:** escolha expressa do criador, Rodada 71.
- **Estado:** regra de design aprovada; não implementada nesta atividade.

## Declaração literal do criador

> 4A — Resolver o status de cada alvo após o último impacto destinado àquele alvo.

## Regra aprovada

- Para um Move multi-hit/multi-alvo que possua **status condicionado ao acerto**, resolver a **tentativa de status de cada alvo após o último impacto destinado especificamente àquele alvo**, **sem exigir que os impactos previstos para outros alvos terminem**.
- Complementar **D-202**, que estabelece **no máximo uma tentativa por alvo e por execução do Move**, apenas se houve acerto válido e o alvo **sobreviveu ao dano recebido**. A D-199 mantém dano/crítico antes da tentativa de status; D-195 mantém esquiva automática antes de crítico/status condicionados ao acerto. Efeitos independentes de acerto e Moves de status não esquiváveis (D-012) mantêm regras próprias.
- **Exemplo ilustrativo:** uma onda multi-alvo completa os impactos destinados a Gible antes de chegar a Abra e Pancham. Se Gible tiver sido atingido validamente e sobreviver, **sua tentativa elegível de status pode ser resolvida nesse ponto**, sem esperar os demais; Abra e Pancham resolvem as suas, se elegíveis, após seus próprios últimos impactos.
- A escolha **não** modifica o teto de recompensas de ATB por ação, o tratamento de eventos fatais simultâneos (D-095), os alvos fixados no AoE ou a aleatoriedade de status aprovada por LUK (D-134/D-146/D-156).

## Limites e pendências

- A decisão **não estabelece** uma nova política para interrupções/cancelamentos de Moves antes do último impacto previsto, para múltiplos status diferentes no mesmo Move, nem para impactos exatamente simultâneos e sua ordem de rolagem; respeitar decisões específicas vigentes sem inventar regra adicional.
- **D-203 permanece:** não usar odômetro/HP rolante como condição temporal de sobrevivência no jogo principal.
- Somente documentação; nenhum código, teste, ficha de Move, asset, cena ou VFX modificado.
