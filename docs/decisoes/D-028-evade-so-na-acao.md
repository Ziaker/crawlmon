# D-028 — O Evade só aparece durante a ação, não na chamada

- **Data:** 2026-11-02
- **Área:** Combate
- **Origem:** Conversa

## O que o criador disse (literal)

> a proposta pra desvio tá acontecendo na chamada ao invés da ação, não é pra acontecer na chamada

## Decisão

O aviso de desvio (ESPAÇO / DESVIAR) e o botão Evade só existem **durante a ação** do ataque (o trajeto: a corrida ou o voo), **não durante a chamada** (o preparo). Durante o preparo o Evade não é oferecido.

## Ambiguidades em aberto (perguntar antes de agir)

- Consequência: apertar Espaço no preparo deixa de fazer qualquer coisa, então o **whiff** de D-016 (perder ATB e levar crítico) deixa de existir. Confirmar com o criador.

## Estado no código

Implementado (`battle_evade.gd`: só ataques no trajeto são oferecidos/aceitos).
