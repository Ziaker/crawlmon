# D-165 — Rodada 62 Q4 (4A, versão prevalente): trajeto sem WINDUP calculado na entrada em TRAVEL

- Data: 2026-11-03.
- Origem: resposta expressa do criador e confirmação de prevalência desta versão da Rodada 62.
- Estado: decisão aprovada, ainda não implementada.

## Declaração literal

> 4A — Calcular a duração ao entrar efetivamente em TRAVEL, quando o Move não tiver WINDUP.

## Regra vigente

- Para Move que **não possui WINDUP, mas possui trajeto TRAVEL**, calcular e **fixar duração ao entrar efetivamente em TRAVEL**, usando a AGI efetiva aplicável nesse marco.
- Para Moves com WINDUP, preservar D-154: calcular ao entrar efetivamente em WINDUP. Preservar o recálculo excepcional por troca de alvo ainda em WINDUP, conforme D-149/D-155.
- Esta escolha **prevalece sobre o marco genérico “início efetivo da execução” da D-157** publicada na versão divergente. A D-157 permanece histórica, sem prevalência quando divergir do marco TRAVEL.
- Preservar tempo próprio de Move, AGI inversa, ajuste de passos e piso de 0,25 s (D-119/D-133/D-136/D-140/D-018). A referência de trajeto **não é 50 automaticamente**: vale o critério de mediana e validação da D-162.
- Exemplo ilustrativo: AGI efetiva 45 na confirmação e 60 ao entrar em TRAVEL sem WINDUP → usar **60** para capturar duração.
- Não autorizar recálculo contínuo durante TRAVEL, nova janela de retarget ou mudança de projéteis/ondas.

## Pendências e escopo

- A decisão não define fallback para Moves sem WINDUP **e sem TRAVEL**.
- Documentação somente, sem código, testes ou VFX.
