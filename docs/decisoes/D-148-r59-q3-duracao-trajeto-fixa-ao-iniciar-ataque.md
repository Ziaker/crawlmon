# D-148 — Rodada 59 Q3 (A): Duração de trajeto calculada no início do ataque e fixa até seu término

- **Data:** 2026-11-03
- **Área:** Atributos / combate / Rodada 59.
- **Proveniência:** decisão escolhida expressamente pelo criador; questões 2 e 3 foram recomendações aceitas do assistente.
- **Estado:** decisão de design registrada e aprovada; sem implementação nesta atividade.

## Declaração literal do criador

> 3A — Quando a AGI usada no tempo de ataque deve ser calculada? Calcular a duração do trajeto ao iniciar o ataque, preservando-a até o fim desse trajeto. (recomendação aceita)

## Regra aprovada e compatibilidade

- **Calcular a duração do trajeto ao iniciar o ataque** e **mantê-la fixa até o fim desse trajeto**. A AGI efetiva, incluindo os efeitos de aumento aplicáveis naquele cálculo, não provoca recálculo retroativo do tempo já estabelecido quando mudar posteriormente durante o trajeto.
- **Preservar D-119, D-133, D-136, D-140 e D-018:** começar pelo tempo próprio da ficha do Move, aplicar redução inversamente proporcional pela AGI efetiva (valor de cálculo mínimo 1), depois a correção de passos táticos e finalmente respeitar o mínimo de **0,25 s**.
- **Preservar D-145:** ATB e trajeto podem usar referências numéricas distintas de AGI; esta decisão não aprova valores concretos nem altera a taxa de regeneração de ATB.
- **Exemplo ilustrativo:** se a duração de uma investida foi fixada usando AGI efetiva 60, um buff que mude AGI enquanto o mesmo trajeto está em andamento **não altera sua duração fixa**. Um novo ataque realizará seu próprio cálculo quando começar.
- **Pendência de fase técnica:** a expressão literal do criador é **'ao iniciar o ataque'**. O código atual possui WINDUP e fases de TRAVEL; esta escolha **não especifica explicitamente se a captura técnica é no comando/declaração da ação, no começo do WINDUP ou na entrada em TRAVEL**. A interpretação técnica desse instante será confirmada antes da implementação caso altere o comportamento.
- Não alterar velocidades de projéteis, ondas AoE ou regras de Evade pela simples adoção desta decisão; trata da duração do trajeto do ataque conforme o escopo de AGI já aprovado.

## Escopo e implementação

- Esta decisão registra regras de design; **nenhum código, ficha de Move, modelo, VFX, configuração ou teste foi alterado**.
- Fórmulas, pesos e valores não especificados nas decisões anteriores permanecem pendentes.
