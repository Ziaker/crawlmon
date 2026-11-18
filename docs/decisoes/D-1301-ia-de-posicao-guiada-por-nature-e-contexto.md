<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1301 — IA de posição guiada pela Nature e pelo contexto do combate

- **Data:** 2026-11-17
- **Área:** Combate / IA / Natures
- **Estado:** em implementação (conceito em `docs/plans/2026-11-17-ia-de-posicao-por-nature.md`).
- **Relacionadas:** D-1299 (passos sem custo/trava), D-393 (Natures e IA), D-111 (alvo aleatório da IA), D-168.

## O que o criador disse (literal)

> "eu quero um planejamento mt melhor na questão destas estratégias, um conceito que leva em conta principalmente a própria nature mas também o contexto do combate atual"

> "sigo suas recomendações"

## Decisão (o "sigo suas recomendações" vale para as recomendações do conceito)

1. A Nature muda como a IA pesa a conta de posição, por 5 eixos lidos dos campos que já existem (`aggression_mult`, `atb_reserve_bias`, mods de AGI/STR/MAG/WIS), sem campo novo.
2. Cada Nature tem um **puxão leve** de posição preferida, do tamanho de meio passo de preço, derivado de STR−MAG e da audácia.
3. **A escolha de alvo da IA também considera a posição do inimigo e a Nature** (peso estocástico, nunca determinístico; engajamento continua obrigando o alvo). Isto altera a regra antiga de alvo aleatório da D-111 por escolha do criador.
4. **Reação à desvantagem por Nature:** as ofensivas (alta audácia) dobram a aposta; as evasivas/defensivas fecham a defesa.
5. **Só debug e telemetria** mostram por que a IA se moveu (evento `pos_decision`); nada na HUD.
6. **Sem mecânica nova de formação.**
7. Sinais de contexto: janela do inimigo (atacando/atordoado/ATB vazio), Taunt, rumo da luta (soma de vida), foco da equipe (golpe de aliado já em voo), Guard, Nature do inimigo (ritmo esperado).

## Ambiguidades em aberto

Nenhuma sobre o que foi aprovado. Os números (pesos, limites) são escolha técnica minha, ajustáveis.
