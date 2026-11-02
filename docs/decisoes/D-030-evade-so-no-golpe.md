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
