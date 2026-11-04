# D-234 — Rodada 77 Q4 (4A): resultados finais de 0%/100% de status sem consumo de RNG

- **Data:** 2026-11-04.
- **Área:** Combate / probabilidade de status / consumo determinístico de RNG.
- **Origem:** escolha expressa do criador na Rodada 77.
- **Estado:** regra de consumo de RNG aprovada; **não implementada nesta atividade**.

## Declaração literal do criador

> 4A — Quando a chance final de status for exatamente 0% ou 100%, determinar falha ou sucesso sem consumir RNG, mantendo as demais condições de aplicação.

## Regra aprovada

- Para um **efeito probabilístico de status** que **já atendeu a todas as condições de elegibilidade**, calcular a **chance final** conforme as regras existentes; se for **exatamente 0%**, determinar **falha**, e se for **exatamente 100%**, determinar **sucesso**, **sem consumir número do fluxo de RNG de status**.
- **Preservar D-143** (chance final limitada ao intervalo de 0% a 100%), D-134 (efeitos expressamente garantidos permanecem garantidos sem rolagem probabilística adicional) e a política de LUK vigente das decisões anteriores, **sem conciliar por inferência o conflito textual histórico** ainda preservado no GDD §12.13.
- **Manter todas as condições de aplicação**: acerto válido quando necessário, esquiva resolvida antes de crítico/status (D-195), crítico e dano antes da aplicação de status condicionado ao acerto, alvo sobrevivente (D-199), teto de tentativas por efeito distinto/alvo/execução (D-210), resolução após último impacto elegível do alvo ou interrupção após acerto (D-207/D-211) e prioridade expressa caso haja incompatibilidade declarada (D-215/D-217).
- Para chances **estritamente entre 0% e 100%**, preservar o **fluxo próprio de RNG de status com seed registrada** (D-227) e a **ordem determinística de consumo** entre alvos/atacantes (D-219/D-223) e de efeitos na ficha (D-213). Saltar uma rolagem de chance extrema **não avança a sequência de RNG**.
- **Exemplo meramente matemático:** chance-base de 98% com modificadores válidos resultando em 103% é limitada a 100% por D-143 e **gera sucesso sem sorteio**, mas **somente se houve elegibilidade**. Chance final de 0% gera falha sem sorteio. **Não criar efeito para golpe errado ou alvo derrotado apenas porque a chance chegou a 100%.**

## Pendências e limites

- Não define tolerância de ponto flutuante para aproximações a 0% ou 100%, algoritmo PRNG, origem da seed, formato de logs/replay, nem ordem de eventos de outras classes.
- **Nenhum código, teste, ficha, Move, cena, VFX ou asset modificado; nenhum teste de gameplay executado.**
