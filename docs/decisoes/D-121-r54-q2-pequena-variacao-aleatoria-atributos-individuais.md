<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-121 — Rodada 54 Q2 (B): Pequenas variações aleatórias individuais nos atributos-base

- **Data:** 2026-11-03
- **Área:** Atributos e identidade de espécies / Rodada 54.
- **Proveniência:** resposta expressa do criador; os textos marcados como recomendação aceita foram originalmente sugeridos pelo assistente, mas **a alternativa foi selecionada diretamente pelo criador**.
- **Estado:** regra de design aprovada e documentada; sem implementação nesta atividade.

## Declaração literal da resposta do criador

> 2B — Adicionar pequenas variações aleatórias individuais nos atributos-base.

## Regra aprovada

- Dois Pokémon da **mesma espécie e nível** podem ter **atributos-base diferentes** por uma **pequena variação aleatória individual**, além de Nature e crescimento.
- A variação não equivale automaticamente ao sistema de IVs da franquia; nenhum algoritmo, semente, distribuição ou amplitude numérica foi aprovado.
- Preservar a faixa permanente 1–100 aprovada na questão 10 e os critérios já aprovados de progressão e Natures.

## Referências, pendências e limitação

- **Referências:** D-129 (limite permanente 1–100); GDD R10–R17 (progressão, Natures e crescimento).
- **Ainda não definido:** Amplitude considerada pequena, distribuição estatística, momento do sorteio, persistência, arredondamento e eventual relação com a Nature.
- **Sem implementação:** não alterar nem presumir alteração de código, recursos, dados de personagens ou testes.

## Complemento posterior — Rodada 55 (2026-11-03)

A decisão posterior **D-132 (R55-Q1, 1A)** fixa **até ±3 pontos em cada atributo-base**, inclusive **Spirit (SPI)**, sorteados **uma única vez por indivíduo e persistentes**. Não define probabilidades dos deslocamentos, critério de correção nos limites 1–100 ou sementes; preserve a escolha original D-121.
