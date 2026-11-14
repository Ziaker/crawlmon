<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-319 — F3 muda só o overworld; a batalha 3D continua com o Gible fixo

- **Data:** 2026-11-05
- **Área:** Exploração / escopo
- **Origem:** Conversa (resposta Q11 do plano do overworld)

## O que o criador disse (literal)

> Só o overworld

## Decisão

A F3 implementa espécie, nível e ameaça **apenas no overworld**. A batalha 3D continua com o **Gible fixo** por enquanto; nenhuma mudança de combate, de VFX ou de Move nesta fase.

## Ambiguidades em aberto

Nenhuma.

## Estado no código

Não implementado. Preserva o escopo da D-235 (nada de Move/VFX de combate nesta fase).
