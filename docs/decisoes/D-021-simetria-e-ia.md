<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-021 — Simetria total e IA de reação

- **Data:** 2026-11-02
- **Área:** Combate
- **Origem:** PROMPT + README

## O que o criador disse (literal)

> Tudo vale para inimigos e aliados. A IA reage dentro do trajeto com chance igual à velocidade (SPD) do personagem.

## Decisão

Toda mecânica do jogador vale para inimigos e aliados. A IA reage **dentro do trajeto**, com chance igual à velocidade, e o contra-ataque da IA segue as mesmas regras. Inimigos usam as mesmas Tactics dos aliados.

## Ambiguidades em aberto (perguntar antes de agir)

Nenhuma.

## Estado no código

Implementado.
