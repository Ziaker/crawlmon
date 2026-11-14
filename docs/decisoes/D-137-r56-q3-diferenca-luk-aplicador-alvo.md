<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-137 — Rodada 56 Q3: Diferença entre Luck do aplicador e do alvo modifica a chance de status

- **Data:** 2026-11-03
- **Área:** Atributos e combate / Rodada 56.
- **Proveniência:** resposta **expressamente enviada** pelo criador, aceitando a alternativa previamente recomendada pelo assistente.
- **Estado:** decisão de design aprovada e documentada, sem implementação nesta atividade.

## Declaração literal da escolha do criador

> 3B — A Luck do alvo também influencia a aplicação de efeitos probabilísticos? A diferença entre a LUK de quem aplica e a LUK de quem recebe influencia a chance. (recomendação aceita)

## Regra aprovada e compatibilidades

- Para **efeitos de status probabilísticos declarados na ficha do Move** (D-134), a chance de aplicação deve ser influenciada pela **diferença entre Luck (LUK) do aplicador e LUK do alvo**.
- A regra envolve **ambos os personagens**, não apenas a Luck do lançador nem apenas a do alvo. Exemplo comparativo: um aplicador com LUK 65 contra alvo com LUK 30 terá uma diferença de +35; invertendo os valores, −35. **As probabilidades resultantes não foram definidas**.
- **D-134 permanece:** somente efeitos com probabilidade declarada são afetados. Efeitos garantidos **permanecem garantidos**; a decisão não lhes acrescenta chance de falha.
- **D-012 permanece:** efeitos de status de alvo único que não podem ser desviados **não ganham uma esquiva** por essa mudança; rolagem de aplicação e Evade são etapas diferentes.
- LUK também influencia crítico e esquiva automática conforme D-127, mas esta decisão não define pesos, probabilidades ou fórmulas dessas outras funções.
- Não presumir uma tabela de resistências a status nem alterar listas de afinidades elementais por esta decisão.

## Pormenores não definidos

- Chance-base por efeito, função que transforma diferença de LUK em porcentagem, valores mínimos e máximos, ordem de modificadores e arredondamento.
- **Sem alteração de código, cenas, dados de personagens, fichas de Moves, VFX ou testes** nesta atividade.

## Complemento posterior — Rodada 57 (2026-11-03)

**D-142 (R57-Q4B):** a diferença LUK(aplicador) − LUK(alvo) modifica a chance **1 ponto percentual por 10 pontos da diferença**. Exemplo aprovado: base 40%, diferença +30 => 43%. Não foram aprovadas regras de arredondamento/interpolação para diferenças que não sejam múltiplas de dez nem política explícita para chance calculada fora de 0–100%. Efeitos garantidos permanecem garantidos.
