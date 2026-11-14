<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-974 — Electric: pilar proporcional ao alvo, anel no chão e esfera que pulsa na release

- **Data:** 2026-11-08.

## Frase literal do criador

> está otimo mas seu raio está grande demais pra um oponente pequeno como o gible, o ideal é reduzir o tamanho para não dar a entender q pode acertar o seu aliado. Adicione um anel no chão de impacto de duração de .35 segundos ao impacto também
>
> alias , na release, eu queria que a esfera, por .25 segundos, duplicasse de tamanho (sem ficar imensa)

Respostas: a esfera **incha e volta** ao tamanho em 0,25 s e depois se dissolve até os 0,6 s; limite de **1,4 m** de raio.

## Decisão

1. **Pilar proporcional ao alvo:** a abertura, a subida, o comprimento dos raios e a espessura das coroas passam a ser medidos do corpo real do alvo (D-235), para um alvo pequeno não parecer atingir o aliado ao lado.
2. **Anel no chão:** no contato, um anel fino no chão sob o alvo, 0,35 s, abrindo e sumindo.
3. **Esfera na release:** em 0,25 s incha até o dobro (no máximo 1,4 m de raio) e volta ao tamanho; depois se dissolve até 0,6 s após o disparo (D-968).

## Estado

Implementado para revisão em vídeo nas duas vistas.
