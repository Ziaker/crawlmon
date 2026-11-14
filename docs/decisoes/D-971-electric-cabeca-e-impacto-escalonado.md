<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-971 — Electric: cabeça do raio e impacto escalonado

- **Data:** 2026-11-08.

## Frase literal do criador

> prossiga

Resposta à recomendação "começar pelos itens 1 e 4" da revisão com a skill `scenario-godot-vfx`.

## Decisão

1. **Cabeça:** na ponta do raio, durante o trajeto, uma bolinha de energia mais clara que o feixe, com tremulação e brilho falso, para o olho seguir o disparo. Some no contato.
2. **Impacto escalonado:** clarão em 0 s → estrela em 0,03 s → pilar subindo em 0,06 s → anel e fagulhas em 0,09 s.

Itens 2 (pausa/tremor, mexe no tempo do combate), 3, 5, 6, 7 e 8 **não** aprovados ainda.

## Estado

Implementado para revisão em vídeo nas duas vistas.
