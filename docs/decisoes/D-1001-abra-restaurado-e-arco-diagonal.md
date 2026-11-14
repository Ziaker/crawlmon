<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1001 — Rastro do Abra restaurado; arco do Pancham diagonal ao lado do corpo

- **Data:** 2026-11-08.

## Frase literal do criador

> Pq tu piorou o efeito do abra sendo que ele já estava perfeito antes? eu não pedi pra vc mudar o abra
> O efeito do pancham não está diagonal assim, ele está completamente vertical...

## Decisão

1. **Erro meu:** D-993 (janela maior) e D-995 (faixa larga) foram aplicadas a todos e mudaram o Abra, já aprovado. O modo "seguir a mão" volta ao visual aprovado da D-990: cunha antebraço→mão, últimos 0,16 s, começando 0,3 s antes do contato. A trava do membro (D-995) fica (só evita piscar).
2. **Arco próprio (D-1000):** em vez de vertical por cima da cabeça, varre em **diagonal ao lado do corpo**, do lado da mão que golpeia: sai do ombro, abre para o lado e desce até o contato (giz verde do criador).

## Lição

Mudança pedida para um atacante não pode alterar outro já aprovado: conferir os aprovados antes de entregar.

## Estado

Implementado para revisão.
