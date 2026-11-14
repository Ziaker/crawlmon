<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1050 — Empurrão 33% maior e corrida na volta

- **Data:** 2026-11-09
- **Área:** Combate / Game Feel / Animação
- **Origem:** Conversa
- **Estado:** **implementado e aprovado pelo criador** em 2026-11-09 (encerramento da sessão).

## Frase literal do criador

> deixe o empurrao um pouco mais longe e tambem faca com que na volta, ele execute a animacao de corrida ao inves de so trocar direto pro idle

Resposta do criador sobre a distância:

> +0,5 un → 2,0 (+33%)

## Decisão

1. **Empurrão:** o empurrão normal passa de **1,5** para **2,0 unidades** (+33%). O multiplicador e o teto acompanham proporcionalmente: o clamp passa de **1,1–2,4** para **1,4–3,2**; crítico/fraqueza continuam usando o multiplicador de 1,55. **D-1051 eleva o pico para 4,0 un** (clamp 1,4–6,2).
2. **Volta com corrida:** depois do hold de **0,5 s** na posição empurrada (D-1049), o alvo **vira para o ponto de retorno** e toca o clipe **`run`** enquanto o tween o leva de volta. Ao chegar, volta ao `idle` e ao facing original.
3. O hold de 0,5 s (D-1049), o slow motion do `damage` no hit-stop (D-1045) e a volta de 0,34 s não mudam.
4. **Só visual:** o recuo e a corrida de volta não mudam a posição lógica (D-019/D-045).
5. Se o modelo não tiver clipe `run`, ele mantém o comportamento anterior (volta deslizando); a posição/facing de retorno continuam corretos.

## Relações

- **D-1045:** recuo no impacto, âncora visual e retorno ao ponto desenhado.
- **D-1049:** hold de 0,5 s antes da volta.
- **D-055:** hits consecutivos renovam o hold e mantêm a âncora.
- **D-235:** mesma reação nas duas vistas e em qualquer alvo.
- **D-019/D-045:** o deslocamento é só de apresentação.

## Estado no código

- `scripts/combat/fx/fx_motion.gd`: `clampf(2.0 * mult, 1.4, 3.2)`, `_start_return_run()` (vira para o retorno e toca `run`), callback de fim restaura o facing e o idle; `_hit_react` espera a volta terminar antes de cortar para o idle.
- **Teste (normal/espelhado, relógio do FX):** pico do empurrão **2,000 un**; hold medido **0,533 s** com tolerância de 0,04 (o configurado é 0,50 s); volta começa em **0,650 s**, termina em **0,933 s**; clipe no início e no meio da volta = **`run`**; em 1,20 s = **`battle_idle`**. Normal e espelhado idênticos.
- **Não verificado:** modelos sem clipe `run` (o fallback é deslizar) e hits consecutivos durante o hold.
