<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-987 — A janela de Evade passa para o início do golpe (prelúdio)

- **Data:** 2026-11-08.

## Frase literal do criador

> este é o prelude, nos milésimos do 2 pro 3 do video, por algum motivo está aparecendo mais tarde? é assim no jogo também o timing do dodge? se for então corrija isso também pois está errado

Respostas: janela no **"Início do golpe"**; "sim, 0.25, inclusive, no efeito de dread do preludio do ataque, faça com que a camada dentro do círculo gire um pouco e o circulo se separe e expanda um pouco também ao longo da duração".

## Decisão

1. **Altera D-283 (posição da janela):** o Evade funciona nos **primeiros 0,25 s** da fase de golpe (o prelúdio, quando o atacante chega e ergue o golpe), e não mais nos últimos 0,25 s antes do contato. Continua sempre perfeito, com 0,25 s.
2. A IA tenta o Evade dentro dessa nova janela (simetria, D-021).
3. O efeito estilo Dread (D-986) acompanha a janela; ao longo dos 0,25 s, a camada de dentro do círculo (estrela e raios) **gira um pouco** e o **círculo se separa** (em arcos) **e se expande um pouco**.

## Ambiguidades

- Moves cujo golpe dura menos de 0,25 s: a janela cobre o golpe inteiro (como antes).
- Os ramos de "Evade comum" sem uso (D-283 item 6) continuam sem uso.

## Estado

Implementado.
