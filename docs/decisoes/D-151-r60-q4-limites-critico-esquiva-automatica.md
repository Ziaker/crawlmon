<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-151 — Rodada 60 Q4 (4A): crítico e esquiva automática limitados a 0–100%

- **Data:** 2026-11-03.
- **Área:** Combate / limites de probabilidade.
- **Origem:** escolha expressa do criador, aceitando recomendação.
- **Estado:** regra de design aprovada; não implementada nesta atividade.

## Declaração literal do criador

> 4A — Quais limites aplicar às chances finais de crítico e esquiva automática? Limitar ambas as probabilidades finais ao intervalo de 0–100%. (recomendação aceita)

## Regra aprovada

- A **chance final de crítico probabilístico** é limitada ao intervalo inclusivo **0%–100%**, após aplicar modificadores.
- A **chance final de esquiva automática** também é limitada ao intervalo inclusivo **0%–100%**, após aplicar os modificadores que vierem a ser definidos.
- Exemplos ilustrativos: crítico calculado em 130% fica **100%**; esquiva automática calculada em −6% fica **0%**.
- O limite **não** é um teto do atributo LUK, cujo crescimento permanece sem limite máximo permanente (D-139).
- Compatível com a regra equivalente de chance final de aplicação probabilística de status (D-143); não altera a natureza garantida dos efeitos sem rolagem (D-134).

## Ressalva expressa — R60-Q3D não resolvida

- Na mesma rodada, o criador escolheu **3D — Outra regra** para esquiva automática e escreveu literalmente: **“3 - diferente de critico, a evasiva reduz quanto maior fica, dividindo pela metade”**.
- A frase indica uma diferença importante em relação à curva do crítico, mas **não define inequivocamente como efetuar a divisão pela metade**: pode ser um coeficiente constante de 50% do bônus de LUK ou uma redução progressiva por faixas/limiares. A fórmula será decidida na rodada seguinte.
- **D-005:** preservar 10% como chance-base histórica/atual até a definição da curva; **D-021:** a reação ativa da IA durante trajetos é separada da esquiva automática. Não atribuir a essas mecânicas a fórmula de crítico.
- Esta D-151 aprova **apenas o limite** de 0–100%, não um coeficiente para a questão 3D.

## Escopo

Somente registro documental. Nenhuma alteração de código, cena, ficha, VFX, teste ou configuração.
