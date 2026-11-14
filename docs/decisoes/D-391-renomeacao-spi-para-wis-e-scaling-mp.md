<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-391 — Renomeação de SPI para WIS (Wisdom) e scaling de HP/MP

- **Data:** 2026-11-07
- **Área:** Personagens / atributos
- **Origem:** decisão direta do criador, na conversa.
- **Estado:** regra registrada; sem código.

## Declaração literal do criador

> O Hp agora aumenta com VIT e  o MP com WIS, inclusive vamos mudar o nome de Spirit pra WIS de WISDOM

## Regra aprovada

- O atributo **SPI** (*Spirit*, de D-130 e D-131) é oficialmente renomeado para **WIS** (*Wisdom*).
- O conjunto oficial dos seis atributos passa a ser: **STR, MAG, VIT, WIS, AGI, LUK**.
- O **HP** aumenta com a Vitality (**VIT**).
- O **MP** aumenta com a Wisdom (**WIS**).

## Ambiguidades em aberto (perguntar antes de agir)

- Nenhuma.

## Estado no código

Nenhuma alteração.
