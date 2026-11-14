<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-970 — Electric: pilar de choque no impacto e rastro no trajeto

- **Data:** 2026-11-08.

## Frase literal do criador

> não sei diferenciar ambas faiscas, mas eu queria mais efeitos no trajeto, faízcas soltas e descargas pequenas deixadas.
>
> quanto ao impacto, mudança de planos, ao invés de ser um leque reto, horizontal faça ser um pilar de choque envolto do inimigo que solta descargas de fáiscas pelos lados (de forma sutil)

Respostas: o pilar **fica junto** com o anel e a estrela (D-969); altura **um pouco acima** do inimigo; as descargas do trajeto ficam **no ar, ao longo do feixe**.

## Decisão

1. **Trajeto:** por onde o raio passa ficam fagulhas soltas e pequenas descargas que estalam e somem no ar, ao longo do feixe.
2. **Impacto:** um pilar de choque (raios verticais em zigue-zague girando) envolve o inimigo, do chão até um pouco acima da cabeça, medido do modelo real; solta descargas de faíscas pelos lados, de forma sutil.
3. O leque horizontal (shotgun) do plano antigo está **cancelado**.
4. As faíscas do Composer continuam desligadas (o criador não distingue as duas).

Nada depende de personagem, time ou lado (D-235): raio e altura vêm do modelo do alvo.

## Estado

Implementado para revisão em vídeo nas duas vistas.
