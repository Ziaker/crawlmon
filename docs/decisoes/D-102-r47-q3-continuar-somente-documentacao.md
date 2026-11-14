<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-102 — R47-Q3 (3B): Não alterar código do jogo existente; somente documentação e decisões

- **Data:** 2026-11-03
- **Origem:** decisão expressa do criador na Rodada 47.
- **Estado:** decisão aprovada; somente documentação, sem implementação afirmada.

## Declaração literal do criador

> 3B — Após registrar estas decisões, você autoriza começar a implementar a primeira etapa no código do Crawlmon?: Não. Continuar apenas com documentação e decisões, sem alterar o código.

## Regra aprovada

**Não há autorização para alterar o código do Crawlmon nesta rodada**. Continuar somente com a documentação e decisões, preservando o jogo existente e suas implementações atuais. A D-097 permanece como ordem planejada para eventual implementação futura, não como autorização para iniciar alterações agora.

## Referências e pendências

- **Referências:** D-001; D-002; D-003; D-022; D-061; D-097.
- **Pendente:** A restrição se refere a esta solicitação e não impede autorizações expressas futuras. O jogo já existe no GitHub: há arquivos project.godot, scenes/, scripts/combat/ e tests/. Não voltar a perguntar como se o projeto ainda precisasse ser criado.
- **Observação literal do criador:** “na 3 ja temos o jogo vc ao menos ve o github direito?” — registro de contexto, não regra mecânica.
- **Escopo:** exclusivamente documentação; nenhum código, VFX, teste, modelo ou dado de Move deve ser alterado por esta entrega.
