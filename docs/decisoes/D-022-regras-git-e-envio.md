<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-022 — Git: nada de push sem autorização; só commitar o que é seu

- **Data:** 2026-11-02
- **Área:** Processo
- **Origem:** PROMPT + conversa

## O que o criador disse (literal)

> Não envie (push) nada sem autorização expressa. / preciso que as coisas estejam no github / envie tudo ao GitHub

## Decisão

Não fazer `push` sem autorização expressa do criador. Conferir branch e `git status` antes de commitar; **outras sessões editam os mesmos arquivos**: não reverter nem commitar o que não é seu. Mensagens de commit terminam com a linha de coautoria. `assets/modelos/` está no `.gitignore`. O criador quer o trabalho no GitHub **quando autoriza**.

## Ambiguidades em aberto (perguntar antes de agir)

O PROMPT diz para não commitar `docs/`; `docs/GDD.md` já está versionado. Manter como está até o criador dizer.

## Estado no código

Em vigor.
