<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-124 — Rodada 54 Q5 (B): HP máximo por Vitalidade e nível com coeficientes de espécie

- **Data:** 2026-11-03
- **Área:** Atributos e identidade de espécies / Rodada 54.
- **Proveniência:** resposta expressa do criador; os textos marcados como recomendação aceita foram originalmente sugeridos pelo assistente, mas **a alternativa foi selecionada diretamente pelo criador**.
- **Estado:** regra de design aprovada e documentada; sem implementação nesta atividade.

## Declaração literal da resposta do criador

> 5B — Uma fórmula baseada em Vitalidade e nível, com coeficientes próprios de cada espécie.

## Regra aprovada

- O **HP máximo** é derivado de **Vitalidade** e **nível** e inclui **coeficientes próprios de cada espécie** para preservar diferenças naturais de resistência.
- Não criar um sexto atributo-base chamado HP: HP máximo continua sendo um recurso derivado.
- A regra é compatível com persistência de HP entre combates da dungeon e a evolução já aprovada.

## Referências, pendências e limitação

- **Referências:** GDD R11-Q2; R14-Q3; D-001.
- **Ainda não definido:** Função exata, coeficientes, limites, arredondamento e tratamento de alteração de máximo com HP atual.
- **Sem implementação:** não alterar nem presumir alteração de código, recursos, dados de personagens ou testes.

## Complemento posterior — D-130/D-131 (2026-11-03)

**Compatibilidade D-130:** Vitality (VIT) continua responsável pelo HP máximo em função do nível e dos coeficientes da espécie, conforme esta decisão, e fica especificamente associada à **mitigação de dano físico**. O novo Spirit (SPI) atua na **mitigação de dano mágico**, sem regra aprovada de participação no HP ou MP. Isso não cria um sexto atributo chamado HP.
