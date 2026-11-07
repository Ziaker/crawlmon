# D-385 — Neblina mais densa: visão pior e nevoeiros maiores

- **Data:** 2026-11-06
- **Área:** Exploração / visual / clima
- **Origem:** o criador viu os vídeos da neblina e pediu que ela deixasse a visão pior, aumentando o tamanho das névoas.
- **Status:** implementado; vídeos regravados; nada publicado.

## O que o criador disse (literal)

> mist devia deixar a visão pior, no caso aumentar o tamanho das nevoas

## Decisão

1. A neblina passa a ser **visualmente mais densa**: bancos maiores, véu base mais forte e bordas mais fechadas. O objetivo é a sensação de visão pior, não um simples tint.
2. **Continua só visual (D-381):** raio de visão 7,5, LOS, explorado, movimento, combate, colisão, câmera e geração não mudam. "Visão pior" aqui é a leitura visual; se o criador quiser reduzir o raio real de visão, é uma decisão separada (não implementada).
3. Parâmetros: `max_alpha` **0,40** (era 0,22), `density` **0,85** (era 0,65), `noise_scale` **1,7** (era 2,6; bancos maiores) e `edge_mist` **0,55** (borda mais densa; substitui a vinheta que clareava as bordas). O véu base fica em ~45–100% do `max_alpha` e a borda soma até +55%.
4. O ciclo, a rolagem de 20%, a duração de 20–40 s, o fade de 2 s e o mapa de biomas **não mudam**.
5. Vídeos regravados: ciclo, antes/depois, GIF e contato. A versão anterior fica superada.

## Ambiguidade

- Se "visão pior" significar **diminuir o raio de visão real (7,5) ou a LOS**, isso muda a regra e precisa de uma decisão própria; não foi feito.

## Estado

Implementado no shader/controller, vídeos regravados e docs atualizados; commits locais; nada publicado.
