<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-100 — R47-Q1 (1A): Nenhuma nova ação durante resolução de projéteis pendentes

- **Data:** 2026-11-03
- **Origem:** decisão expressa do criador na Rodada 47.
- **Estado:** decisão aprovada; somente documentação, sem implementação afirmada.

## Declaração literal do criador

> 1A — Quando uma equipe é eliminada, mas ainda existem projéteis em voo, os sobreviventes podem continuar atacando?: Ninguém pode iniciar novas ações durante essa espera; projéteis já lançados continuam até resolver.

## Regra aprovada

Quando uma equipe é eliminada e há projéteis já lançados em voo (D-099), **ninguém pode iniciar novas ações enquanto o resultado está pendente**, inclusive os sobreviventes. Os **projéteis já lançados continuam ativos até sua resolução**, permitindo empate se eliminarem também a outra equipe. Esta é uma exceção específica à continuidade normal do combate durante animações fatais (D-096).

## Referências e pendências

- **Referências:** D-019; D-081; D-090; D-091; D-094; D-095; D-096; D-099.
- **Pendente:** Não foi definido o tratamento de ações iniciadas antes dessa espera que ainda não resultaram em projéteis lançados. Não inferir cancelamento, continuação ou pausa.
- **Observação literal do criador:** “na 3 ja temos o jogo vc ao menos ve o github direito?” — registro de contexto, não regra mecânica.
- **Escopo:** exclusivamente documentação; nenhum código, VFX, teste, modelo ou dado de Move deve ser alterado por esta entrega.

## Conciliação posterior (2026-11-03)

**Exceção posterior D-105:** a espera por projéteis pendentes **não ocorre quando se derrota o último inimigo presente**; nesse caso, a vitória é definitiva no instante do KO e nenhum projétil pendente pode causar dano ou alterar o resultado. O alcance desta decisão antiga fora desse caso não foi redefinido.

## Complemento posterior — Rodada 49

D-107: a fase de espera por projéteis após a eliminação da última unidade de uma equipe deixa de se aplicar, tanto na vitória quanto na derrota (D-105/D-107). Este texto antigo fica preservado como registro histórico, não como regra atual para o KO final.
