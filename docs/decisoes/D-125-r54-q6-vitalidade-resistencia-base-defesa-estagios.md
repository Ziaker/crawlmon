<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-125 — Rodada 54 Q6 (A): Vitalidade influencia defesa natural mantendo estágios de Defesa

- **Data:** 2026-11-03
- **Área:** Atributos e identidade de espécies / Rodada 54.
- **Proveniência:** resposta expressa do criador; os textos marcados como recomendação aceita foram originalmente sugeridos pelo assistente, mas **a alternativa foi selecionada diretamente pelo criador**.
- **Estado:** regra de design aprovada e documentada; sem implementação nesta atividade.

## Declaração literal da resposta do criador

> 6A — Vitalidade também influencia a resistência-base a dano, preservando os estágios de Defesa.

## Regra aprovada

- **Vitalidade também influencia a resistência-base a dano** recebida pelo Pokémon; continua ligada ao HP máximo.
- Preservar modificações por estágios de Defesa já existentes (Rakunda/Rakukaja e efeitos equivalentes). Não criar sexto atributo independente de Defesa.
- Não alterar o comportamento atual dos estágios ou definir resistências elementais adicionais por presunção.

## Referências, pendências e limitação

- **Referências:** Combatant.gd; regras consolidadas §8; GDD R10-Q4.
- **Ainda não definido:** Fórmula exata, limites de mitigação, ordem com fraquezas/críticos e balanceamento para evitar Vitalidade dominante.
- **Sem implementação:** não alterar nem presumir alteração de código, recursos, dados de personagens ou testes.

## Complemento posterior — D-130/D-131 (2026-11-03)

**Substituição parcial posterior D-130:** a resistência-base derivada de **Vitality (VIT)** aplica-se **somente ao dano físico**. Para o **dano mágico**, acrescenta-se o novo atributo separado **Spirit (SPI)**, que cumpre papel defensivo análogo ao de Vitality para o tipo mágico. A frase original 'Não criar sexto atributo independente de Defesa' é histórica e cede à ordem expressa de criar Spirit, sem criar uma estatística genérica de Defesa adicional. Os estágios já aprovados de Defesa não são removidos; seu impacto em cada categoria e a fórmula permanecem pendentes.

## Complemento posterior — Rodada 56 (2026-11-03)

**D-138 (Rodada 56, Q4A):** o modificador comum por **estágios de Defense** atua **tanto em danos físicos quanto mágicos**, mas a resistência natural é separada pelo atributo: **VIT para físicos, SPI para mágicos (D-130)**. A distinção de VIT/SPI não separa automaticamente os buffs/debuffs por tipo. Fórmulas e ordem de mitigação permanecem pendentes.
