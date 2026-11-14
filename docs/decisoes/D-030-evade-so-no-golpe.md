<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-030 — O Evade só pode ser feito durante o golpe em si

- **Data:** 2026-11-02
- **Área:** Combate
- **Origem:** Conversa

## O que o criador disse (literal)

> E VC AINDA NÃO CORRIGIU O NEGOCIO DO DESVIO ACONTECER NO ANUNCIO E NÃO DURANTE O ATAQUE, É PRA ACONTECER DURANTE O ATAQUE, É PRA SÓ PODER SER REALIZADO DURANTE O O ATAQUE
>
> only the strike itself.

## Decisão

O Evade (e o aviso ESPAÇO/DESVIAR) só existe **durante o golpe em si**: a fase que termina com o acerto. No corpo a corpo é o **golpe** (antecipação + golpe até o contato), **não** a corrida. Fora disso (preparo/anúncio e corrida) não há Evade. O desvio **perfeito** continua sendo os **últimos 0,22 s** dessa janela. Substitui a janela "no trajeto" de D-016, D-027 e D-028.

## Ambiguidades em aberto

- ~~Projéteis~~ — respondido: "Sim, o voo". Em projéteis, a janela é o **voo** do projétil.
- O custo de 2 ATB continua valendo quando quem desvia está **correndo** no próprio ataque (D-006), não durante o golpe dele.

## Estado no código

Implementado (`Incoming.can_evade_now`: fase de impacto; IA também).
