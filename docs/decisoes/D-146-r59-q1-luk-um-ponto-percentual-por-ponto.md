<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-146 — Rodada 59 Q1 (A): Aplicação de status: 1 ponto percentual por ponto da diferença de LUK

- **Data:** 2026-11-03
- **Área:** Atributos / combate / Rodada 59.
- **Proveniência:** decisão escolhida expressamente pelo criador; questões 2 e 3 foram recomendações aceitas do assistente.
- **Estado:** decisão de design registrada e aprovada; sem implementação nesta atividade.

## Declaração literal do criador

> 1A — Qual escala de LUK deve prevalecer na aplicação de status? Adotar sua fórmula mais recente: 1 ponto percentual por ponto de diferença de LUK. Resultado: 47%.

## Regra aprovada e compatibilidade

- Para efeitos de status **probabilísticos com chance declarada na ficha do Move**, calcular a correção pela diferença **Luck (LUK) do aplicador − Luck (LUK) do alvo**, com razão de **1 ponto percentual por 1 ponto de diferença de LUK**.
- **D-142 é substituída expressamente quanto à taxa de escala:** a taxa histórica de **1 ponto percentual por 10 pontos** deixa de ser a regra vigente. A escolha **1A da Rodada 59** resolve a ambiguidade registrada na seção 38 do consolidado, sem apagar o histórico anterior.
- **Exemplo expressamente aprovado:** probabilidade-base de **50%**, LUK 7 do aplicador e LUK 10 do alvo resulta em **50% + 7 pp − 10 pp = 47%**.
- **D-143 preservada:** a probabilidade final é limitada ao **intervalo de 0% a 100%**. D-134/D-137 continuam válidas: somente efeitos com chance declarada têm essa rolagem; efeitos garantidos permanecem garantidos, e o cálculo não introduz Evade para Moves de status (D-012).
- **D-139 preservada:** LUK permanente não tem teto de 100; é possível que diferenças de LUK grandes saturarem a chance em 0% ou 100% pela D-143. Isso não estabelece uma nova fórmula para crítico ou esquiva automática, cuja influência de LUK (D-127) continua pendente quantitativamente.
- Como o coeficiente é de 1 pp por ponto de diferença, **não há mais a lacuna de arredondamento em blocos de 10**, embora o tratamento de LUK fracionária, caso exista futuramente, não tenha sido especificado.

## Escopo e implementação

- Esta decisão registra regras de design; **nenhum código, ficha de Move, modelo, VFX, configuração ou teste foi alterado**.
- Fórmulas, pesos e valores não especificados nas decisões anteriores permanecem pendentes.
