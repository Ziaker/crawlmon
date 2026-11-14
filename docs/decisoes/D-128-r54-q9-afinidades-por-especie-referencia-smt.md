<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-128 — Rodada 54 Q9 (A): Afinidades por espécie com SMT como referência principal

- **Data:** 2026-11-03
- **Área:** Atributos e identidade de espécies / Rodada 54.
- **Proveniência:** resposta expressa do criador; os textos marcados como recomendação aceita foram originalmente sugeridos pelo assistente, mas **a alternativa foi selecionada diretamente pelo criador**.
- **Estado:** regra de design aprovada e documentada; sem implementação nesta atividade.

## Declaração literal da resposta do criador

> 9A — Definir afinidades por espécie usando principalmente SMT como referência, preservando os elementos e as fraquezas existentes até revisão explícita.

## Regra aprovada

- As **afinidades elementais são definidas individualmente por espécie**, usando a lógica de **Shin Megami Tensei como principal referência de design**.
- Preservar os **11 elementos existentes** e as fraquezas já cadastradas até uma revisão expressa; não converter automaticamente os tipos Pokémon nem substituir o catálogo de elementos pelo de SMT.
- A aprovação não introduz automaticamente novas categorias de resistência, imunidade, absorção ou reflexão; essas regras requerem decisões específicas.

## Referências, pendências e limitação

- **Referências:** D-118; Element.gd; Combatant.gd.
- **Ainda não definido:** Tabela de afinidades de cada espécie, quais propriedades além de fraqueza existem e como a referência de SMT é adaptada a cada elemento.
- **Sem implementação:** não alterar nem presumir alteração de código, recursos, dados de personagens ou testes.
