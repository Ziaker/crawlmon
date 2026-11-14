<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-066 — R42-Q5 (5A): Janela perfeita compartilhada na onda AoE

- **Data:** 2026-11-03
- **Área:** Combate
- **Fonte:** declaração expressa do criador na Rodada 42.
- **Estado:** decisão de design aprovada; implementação não verificada.

## Declaração literal do criador

> 5A — Como funciona o Evade perfeito contra a onda AoE?: Todos compartilham também uma única janela de Evade perfeito.

## Decisão aprovada

Na onda de projéteis AoE, **todos os alvos compartilham a janela comum de Evade e também uma única janela de Evade perfeito**, preservando a resposta individual de cada alvo e a inexistência de alvo principal.

## Relações e questões abertas

- **Referências:** D-007, D-009, D-030, D-059.
- **Pendente de conciliação:** a D-030 estabelece os últimos 0,22 s antes do contato individual, enquanto alvos da onda são atingidos em tempos diferentes. O marco temporal da janela perfeita global não foi definido.
- **Escopo:** este documento registra a regra, sem autorizar alteração de código ou testes.
