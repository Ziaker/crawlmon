<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-001 — O GDD é ignorado no combate

- **Data:** 2026-11-02
- **Área:** Processo
- **Origem:** Conversa

## O que o criador disse (literal)

> O gdd tá desatualizado quanto ao combate, o ignore

## Decisão

Para regras de **combate**, o `docs/GDD.md` não vale. Valem, em ordem: o que o criador diz na conversa > `PROMPT_trajeto_reposicionamento.md` > o código/README. O GDD continua valendo para exploração, campanha, progressão e economia.

## Ambiguidades em aberto (perguntar antes de agir)

Nenhuma sobre este ponto.

## Estado no código

Aplicado em `docs/REGRAS_DO_JOGO.md` (seção 12).
