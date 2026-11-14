<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-016 — Evade manual só funciona durante o trajeto; no preparo é whiff

- **Data:** 2026-11-02
- **Área:** Combate
- **Origem:** PROMPT (escrito pelo criador)

## O que o criador disse (literal)

> Evade manual (Espaço) só funciona durante o TRAJETO do ataque que mira o personagem. ... Apertar durante o PREPARO continua sendo whiff (esquiva cedo demais; perde os 2 ATB e fica vulnerável a crítico).

## Decisão

O Evade manual só funciona durante o **trajeto** do ataque que mira o personagem (a corrida ou o voo do projétil). Apertar no **preparo** é whiff: perde o custo e o golpe vira crítico. Só o Evade manual conta; a esquiva automática não dispara a sequência abaixo. O "2 ATB" do texto original foi **substituído por D-006**.

## Ambiguidades em aberto (perguntar antes de agir)

Nenhuma.

## Estado no código

Implementado (custo conforme D-006 pendente).
