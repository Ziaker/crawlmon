<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1006 — Dodge do wind-up ao contato, sempre perfeito; sem o aviso "SPACE DODGE!"; etiqueta de wind-up corrigida

- **Data:** 2026-11-08.

## Frase literal do criador

> poderia remover isso agora? alem disso permita realizaro dodge a qualquer momento e não só num momento específico
> outra mudança, o cartão tá quebrado com o icone cobrindo grande parte do nome

Respostas: dodge **"Do wind-up ao contato"**; **"Tudo perfeito"**.

## Decisão

1. **Altera D-028/D-283/D-987/D-988:** o Evade manual funciona do início do wind-up do inimigo até o contato, e **sempre é perfeito**. A janela de 0,25 s deixa de existir para a regra.
2. O efeito estilo Dread (D-986) continua só como aviso visual, no mesmo momento de antes.
3. O aviso "SPACE / DODGE!" sobre o personagem foi removido.
4. Etiqueta de wind-up: a marca d'água do elemento ficou pequena no canto e o nome do move diminui para caber antes dos ícones.

## Ambiguidade

- A IA continua tentando o Evade no momento antigo (perto do golpe); não foi mudada.

## Estado

Implementado.
