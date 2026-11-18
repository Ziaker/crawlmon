<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1310 — Cascos: quantidade por nível, limite de 12 moedas visuais e lançamento

- **Data** — 2026-11-18
- **Área** — Economia / drops / apresentação em combate
- **Estado** — Aprovado em chat. Implementado no sorteio, no crédito e nas moedas visuais; o visual das moedas aguarda o julgamento do criador.
- **Relacionadas** — [D-1285](D-1285-cascos-economia-moedas-separadas-e-chances-de-drop.md), [D-1286](D-1286-cascos-bronze-drop-simultaneo-e-knock-up-visivel.md), [D-1309](D-1309-cascos-recomendacoes-aprovadas-credito-knockup-shell-balance.md).

## Frases literais do criador

> era pra dropar apenas uma moeda mesmo sendo uma recompensa com mais de uma moeda? se sim então está errado, é pra sair varias moedas, se passar de 12 moedas, para de gerar mais que 12, mas do mesmo tipo, no caso se tiver mais doq 12 de bronze, para de gerar de bronze, mas se tem 5 de prata então gera 5 de prata ainda

> depende do nivel, dividido por 2 (bronze), dividido por 3 (prata) e dividido por 4 (gold)

Respostas às perguntas de esclarecimento (opções escolhidas): o nível é o "Do inimigo derrotado"; arredondamento "Para baixo"; mínimo "No mínimo 1".

> as moedas tem que voar brilhando aos ares antes de cairem no chão com um rastro junto

> elas também tem que ficar brilhando no chão, é dificil ver sem brilho

> eu NÃO PEDI pra deixar as moedas maiores, só mais visiveis

> além disso aumente a força com que as moedas são lançadas, valores mais aleatórios com maior gravidade de descida

## Decisão

1. **Quantidade por sucesso de sorteio** = nível do inimigo derrotado ÷ divisor do tipo (Bronze 2, Silver 3, Golden 4), arredondado para baixo, no mínimo 1. Vale para o saldo e para as moedas visuais. Substitui o "uma moeda por sucesso" da [D-1286](D-1286-cascos-bronze-drop-simultaneo-e-knock-up-visivel.md), que era texto do assistente, não do criador.
2. **Limite visual**: no máximo 12 moedas visuais por tipo na batalha; passando de 12 de um tipo, esse tipo para de gerar moedas visuais (o saldo continua sendo creditado inteiro), e os outros tipos seguem gerando até o próprio limite.
3. **Apresentação**: as moedas sobem brilhando, com rastro, e caem no chão onde o inimigo estava, continuando a brilhar. O tamanho da moeda não muda (0,32 m); a visibilidade vem do brilho, da aura e do rastro.
4. **Lançamento**: força maior e mais aleatória, com gravidade de descida maior. Os valores numéricos (subida 12 a 26 m/s, lado 1,5 a 8 m/s, gravidade de descida 1,8 a 3,2 vezes) são valores de teste do assistente, não do criador.

## Implementação

`ShellDropMath.quantity`, `data/economy/shell_drop_rates.json` (`level_divisor`), `Battle._on_enemy_died_shells`, `ShellDropFx`, `tests/economy/battle_shell_drop_test.gd` e `shell_drop_fx_test.gd`.
