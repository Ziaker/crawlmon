<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-120 — Rodada 54 Q1 (C): Atributos-base por espécie com referência biológica e balanceamento próprio

- **Data:** 2026-11-03
- **Área:** Atributos e identidade de espécies / Rodada 54.
- **Proveniência:** resposta expressa do criador; os textos marcados como recomendação aceita foram originalmente sugeridos pelo assistente, mas **a alternativa foi selecionada diretamente pelo criador**.
- **Estado:** regra de design aprovada e documentada; sem implementação nesta atividade.

## Declaração literal da resposta do criador

> 1C — Usar os atributos originais como referência biológica da espécie, ajustando os valores ao equilíbrio do Crawlmon.

## Regra aprovada

- Os atributos originais de cada espécie de Pokémon são uma **referência para preservar a identidade biológica/mecânica da espécie**, mas a ficha de **cinco atributos permanentes do Crawlmon** é ajustada ao balanceamento do próprio jogo.
- A referência original **não obriga uma conversão automática 1:1**, nem modifica elementos, afinidades ou fraquezas, cuja referência principal é Shin Megami Tensei (D-118).
- Preservar escala 1–100 e as regras de Nature, progressão e papel individual da espécie.

## Referências, pendências e limitação

- **Referências:** D-001; D-118; progressão GDD R10–R14.
- **Ainda não definido:** Quais dados de referência usar, quais valores iniciais definir por espécie e qual método de conversão/equilíbrio; não fixados nesta resposta.
- **Sem implementação:** não alterar nem presumir alteração de código, recursos, dados de personagens ou testes.

## Complemento posterior — D-130/D-131 (2026-11-03)

**Complemento posterior D-130/D-131:** a lista oficial passa a ter **seis atributos permanentes**, não cinco: Strength (STR), Magic (MAG), Vitality (VIT), Spirit (SPI), Agility (AGI) e Luck (LUK). A referência biológica por espécie continua válida. Esta nota preserva a declaração histórica de cinco atributos como definição anterior, substituída apenas quanto à quantidade e nomenclatura.
