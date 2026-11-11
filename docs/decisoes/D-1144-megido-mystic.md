# D-1144 — Megido é Mystic (correção de elemento e texto)

- **Data:** 2026-11-10
- **Área:** Moves / elemento / ficha.
- **Origem:** ordem direta do criador.
- **Estado:** implementado nesta rodada.

## Declaração literal do criador

> "vamos corrigir também"

## Regra aprovada

- **Megido** passa a usar o elemento **Mystic** (11), coerente com a ficha que já dizia "Almighty/Mystic" e com D-398 (Mystic = Almighty, dano mágico puro que ignora as afinidades elementais convencionais).
- O dano continua mágico e escala com **MAG** (D-1140).
- Textos da ficha passam de "light" para "Mystic" e de "ATK" para "MAG".
- Nenhum outro Move é alterado nesta decisão; a auditoria move a move fica na D-1145.

## Ambiguidades em aberto (perguntar antes de agir)

- Se Mystic deve ter alguma regra própria de resistência/immunidade: hoje o motor só tem fraquezas; nenhuma espécie tem fraqueza Mystic, então Megido não explora fraqueza.
- Visual do Megido continua branco-ciano; nenhuma mudança de VFX foi pedida.

## Estado no código

- `content/moves/megido/move.tres`: `element = 11` e textos Mystic/MAG.
- Teste dedicado `tests/battle/test_d1144_megido_mystic.gd` — **D1144_PASS**.
