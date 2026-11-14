<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-385 — Neblina mais densa: visão pior e nevoeiros maiores

- **Data:** 2026-11-06
- **Área:** Exploração / visual / clima
- **Origem:** o criador viu os vídeos da neblina e pediu que ela deixasse a visão pior, aumentando o tamanho das névoas.
- **Status:** implementado; densidade e cantos ajustados; vídeos regravados; nada publicado.

## O que o criador disse (literal)

> mist devia deixar a visão pior, no caso aumentar o tamanho das nevoas

## Decisão

1. A neblina passa a ser **visualmente mais densa**: bancos maiores, véu base mais forte e bordas mais fechadas. O objetivo é a sensação de visão pior, não um simples tint.
2. **Continua só visual (D-381):** raio de visão 7,5, LOS, explorado, movimento, combate, colisão, câmera e geração não mudam. "Visão pior" aqui é a leitura visual; se o criador quiser reduzir o raio real de visão, é uma decisão separada (não implementada).
3. Parâmetros: `max_alpha` **0,40** (era 0,22), `density` **0,85** (era 0,65), `noise_scale` **1,7** (era 2,6; bancos maiores) e `edge_mist` **0,75** (borda mais densa; substitui a vinheta que clareava as bordas). O véu base fica em ~45–100% do `max_alpha` e a borda soma até +75%.
4. O ciclo, a rolagem de 20%, a duração de 20–40 s, o fade de 2 s e o mapa de biomas **não mudam**.
5. Vídeos regravados: ciclo, antes/depois, GIF e contato. A versão anterior fica superada.

## Ajuste dos cantos (2026-11-07)

O criador pediu que a névoa nos cantos se expandisse e ficasse maior:

> ea pra nevoa nos cantos se expandir e ficar maior também

- `edge_mist` **0,55 → 0,75**; o degradê da borda começa em **0,14** (antes 0,24) e é modulado pelo ruído (`0,75 + 0,25 * n1`). O véu de borda/cantos fica maior e entra mais para o centro; o centro continua legível.
- Continua só visual: raio 7,5/LOS/explorado intactos.
- Vídeos da neblina regravados com o novo edge.

## Ambiguidade

- Se "visão pior" significar **diminuir o raio de visão real (7,5) ou a LOS**, isso muda a regra e precisa de uma decisão própria; não foi feito.

## Estado

Implementado no shader/controller, vídeos regravados e docs atualizados; commits locais; nada publicado.
