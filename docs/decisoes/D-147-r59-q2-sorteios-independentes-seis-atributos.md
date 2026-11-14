<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-147 — Rodada 59 Q2 (A): Sorteios individuais independentes nos seis atributos

- **Data:** 2026-11-03
- **Área:** Atributos / combate / Rodada 59.
- **Proveniência:** decisão escolhida expressamente pelo criador; questões 2 e 3 foram recomendações aceitas do assistente.
- **Estado:** decisão de design registrada e aprovada; sem implementação nesta atividade.

## Declaração literal do criador

> 2A — As variações aleatórias dos seis atributos são sorteadas independentemente? Sortear cada atributo independentemente, usando os mesmos pesos triangulares aprovados. (recomendação aceita)

## Regra aprovada e compatibilidade

- Realizar **um sorteio independente para cada atributo-base** (STR, MAG, VIT, SPI, AGI, LUK) em cada indivíduo. O resultado de um atributo **não modifica a probabilidade** dos resultados dos outros.
- **Preservar D-132 e D-144:** cada resultado pertence ao intervalo inteiro −3..+3, com pesos triangulares **1:2:3:4:3:2:1**, sorteado uma única vez por atributo/indivíduo e persistente.
- Não exigir soma fixa ou compensação obrigatória entre atributos. **Exemplo ilustrativo:** obter STR +3 não impede SPI +3, 0 ou −2, e não altera os pesos de SPI.
- **D-139 preservada:** os atributos permanentes podem exceder 100; a regra de independência não cria teto. O mecanismo de seed, persistência técnica, identificação e ordem de geração continuam não especificados.

## Escopo e implementação

- Esta decisão registra regras de design; **nenhum código, ficha de Move, modelo, VFX, configuração ou teste foi alterado**.
- Fórmulas, pesos e valores não especificados nas decisões anteriores permanecem pendentes.
