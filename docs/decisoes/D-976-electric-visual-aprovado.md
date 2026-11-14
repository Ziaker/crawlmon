<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-976 — Electric Beam: visual aprovado

- **Data:** 2026-11-08.

## Frase literal do criador

> na verdade acho que já está bom o bastante, eu considero esse move perfeitamente feito visualmente
>
> agora é a questão mecânica.

## Decisão

O visual do Electric Beam (v20: D-957 a D-975) está **aprovado**. Os efeitos de luminosidade propostos (poeira elétrica, névoa no chão, halo no trajeto, poeira no wind-up) **não** entram. Próximo passo: a parte mecânica, a definir com o criador.

## Estado

Aprovado. Nada commitado.
