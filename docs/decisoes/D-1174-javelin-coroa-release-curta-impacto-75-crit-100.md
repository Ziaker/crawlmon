<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1174 — Javelin Throw: coroa do release mais curta e impacto normal 75% / crítico 100%

- **Data:** 2026-11-11.
- **Área:** VFX / Javelin Throw.
- **Origem:** ordem direta do criador no chat.

## O que o criador pediu (literal)

> "a espiral coroada do release devia seguir por menos tempo, mt menos tempo. O impacto do move ta enorme, diminua seu tamanho em 25% mas mantenha esse tamanho caso dê critico, trate como efeito alternativo"

## Respostas de definição (2026-11-11)

Perguntas feitas para não chutar; respostas escolhidas pelo criador:

1. **Coroa — o que encurtar:** **"Só o acompanhamento"**. A vida total da coroa continua **0,35 s**; só o tempo em que ela acompanha o dardo (hoje **0,15 s**) será reduzido. **O novo tempo ainda não foi informado.**
2. **Impacto — abrangência:** **"Cruz + flash + anéis"**. A redução de 25% vale para a **cruz**, o **flash**, o **anel atrasado** e o **anel de solo**. **Espinhos, poeira e faíscas ficam no tamanho atual** em normal e em crítico.
3. **Crítico — diferença:** **"Só o tamanho"**. No crítico, cruz/flash/anéis voltam ao tamanho atual (100%); o visual, as cores e o flash são os mesmos. Não há variante de cor.

## O que já está definido

1. **Coroa do release:** acompanhar o dardo por **muito menos tempo** que 0,15 s; a coroa inteira continua sumindo em 0,35 s depois do release. O novo tempo de acompanhamento falta.
2. **Impacto normal:** cruz + flash + anel atrasado + anel de solo a **75%** do tamanho atual; espinhos, poeira e faíscas permanecem em 100%.
3. **Impacto crítico:** cruz + flash + anel atrasado + anel de solo a **100%** do tamanho atual; espinhos, poeira e faíscas permanecem em 100%. O `crit` real do combate escolhe a variante.
4. **Efeito alternativo:** duas variantes visuais do mesmo impacto (normal 75% / crítico 100%), sem mudar dano, chance, custo, ATB, MP ou qualquer regra de D-1103.
5. **Base visual:** continua o HTML Card C (D-1171), mas estes pontos passam a ser definidos por esta decisão.

## Ambiguidade em aberto

- **Novo tempo de acompanhamento da coroa**, em segundos. Hoje são 0,15 s; o criador pediu "muito menos", mas não informou o número. A vida total continua 0,35 s.

## Estado no código

**Nenhum código alterado.** O `JavelinThrowVfxHtml` ainda não lê o `crit` no `draw()`; o driver já envia `"crit": crit` no payload. O impacto atual usa `body_scale = target_radius / 0.5`; a coroa usa 0,15 s de acompanhamento e 0,35 s de vida total. A implementação espera o novo tempo de acompanhamento.
