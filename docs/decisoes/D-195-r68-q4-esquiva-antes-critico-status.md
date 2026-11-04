# D-195 — Rodada 68 Q4 (4A): esquiva automática antes de crítico e status condicionados ao acerto

- **Data:** 2026-11-04.
- **Área:** Combate / ordem de rolagens / esquiva automática.
- **Origem:** decisão expressa do criador na Rodada 68, aceitando a recomendação.
- **Estado:** regra de design aprovada; não implementada nesta atividade.

## Declaração literal do criador

> 4A — Resolver a esquiva automática primeiro; se funcionar, não rolar crítico nem status que dependam do acerto.

## Regra aprovada

- Para um **ataque elegível à esquiva automática**, resolver **primeiro** a sua esquiva automática. Se ela for **bem-sucedida**, o ataque fica sem acerto e **não devem ocorrer rolagens de crítico probabilístico ou de aplicação de status que dependam desse acerto**.
- Se a esquiva automática falhar, esta decisão permite prosseguir à resolução de acerto e demais efeitos segundo as regras vigentes, **sem definir toda a ordem restante** dos eventos.
- Exemplo ilustrativo: Pancham usa um Move danoso com possibilidade de crítico e efeito de status probabilístico **condicionado ao acerto**. Gible consegue esquiva automática: não rolar crítico nem o status condicionado ao acerto para esse impacto.
- Preservar **D-012**: debuffs de alvo único e outros Moves de status já não esquiváveis não recebem uma nova rolagem de esquiva por esta decisão. Efeitos independentes de acerto/garantidos, se previstos em regra própria, não são transformados automaticamente em efeitos condicionados ao acerto (D-134).
- Preservar as regras próprias de probabilidade e LUK **D-146, D-150, D-151, D-152, D-153 e D-156**, sem solucionar a divergência textual da reapresentação R60 registrada no GDD §12.13.
- A implementação atual de `battle.gd` já retorna no caminho `auto_dodged` antes da rolagem de crítico em `_hit()`, mas **isso não demonstra que todas as futuras rolagens de status condicionadas ao acerto já estejam implementadas**.

## Limites e pendências

- Não estabelece a ordem entre **crítico e status depois de um acerto**, nem a interação com múltiplos impactos/alvos para efeitos com condições especiais; não muda Evade manual/perfeito, reação da IA ou benefícios de uma esquiva.
- Somente documentação. Nenhum código, configuração, ficha de Move, teste, cena ou VFX alterado.
