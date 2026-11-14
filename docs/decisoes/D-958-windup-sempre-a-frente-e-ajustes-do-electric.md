<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-958 — Wind-up sempre à frente do personagem; ajustes do feixe Electric v1

- **Data:** 2026-11-07.
- **Área:** VFX (todos os Moves) / Biblioteca de projéteis (D-957).
- **Estado:** item 1 em correção; itens 2 e 3 em proposta.

## Frases literais do criador

> favor fazer video em ambos lados toda vez que fazer uma entrega para minah verificação

> 1 - o wind up não está sendo criado na frente do personagem, ele está sendo criado dentro, corrija, leve em conta isso para efeitos futuros, sempre criar a frente do personagem exceto se for dito o oposto no documento de implementação do vfx do move

> 2 - eu gostei mas os efeitos do wind up e do release estão muito basicos. Me proponha um efeito visual interessante e espetacular para o release do move, no momento do disparo.

> 3 - o impacto podia ser um leque como um tiro de shockrun de raios que passam pelo corpo todo do oponente no impacto

## Decisão

1. **Regra geral de VFX:** o wind-up (a carga) sempre nasce **à frente do personagem**, fora do corpo, no eixo atacante→alvo. A exceção só vale se o documento de implementação do VFX do Move disser o contrário. O ponto vem do corpo real (D-235).
2. **Toda entrega de VFX** inclui vídeo das duas vistas, normal e espelhada (reforça a D-308).
3. Electric: o criador gostou do feixe, mas achou o wind-up e o release básicos. O assistente propõe um release "interessante e espetacular" no instante do disparo, e o criador decide.
4. Electric: o impacto vira um **leque de raios**, como um tiro de shotgun, que **atravessa o corpo todo do oponente**. Leitura do assistente: "shockrun" = shotgun; confirmar.

## Release escolhido (2026-11-07)

> coroa de raios que se expande e se separa pra trás em 5 partes, sumindo lentamente, inclusive deixe o raio mais iluminado

- Release: no disparo, uma **coroa de raios** em volta da boca do disparo **se expande** e depois **se separa em 5 partes que vão para trás** (sentido oposto ao tiro), **sumindo lentamente**.
- "Deixe o raio mais iluminado": leitura do assistente = o **feixe** fica mais claro (mais núcleo claro e um halo translúcido em volta), sem Glow (D-957). Confirmar.
- Impacto em leque: ainda aguarda confirmação ("shockrun" = shotgun?).
