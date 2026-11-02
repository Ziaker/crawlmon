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
