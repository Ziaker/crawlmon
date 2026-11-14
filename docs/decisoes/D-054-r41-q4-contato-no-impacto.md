<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-054 — R41-Q4 (4A): Ajuste espacial somente no impacto

- **Data:** 2026-11-02
- **Origem:** decisão direta do criador, R41; eventuais complementos posteriores estão reproduzidos abaixo.
- **Estado:** decisão de design aprovada; nenhuma implementação afirmada por este documento.

## Declaração do criador (literal)

> 4A — Como garantir contato exato se a trajetória do golpe fica fixa?: Corrigir a posição final do contato somente no instante do impacto, sem perseguir durante o restante do golpe.

## Regra aprovada

Durante a animação do golpe, não corrigir continuamente a trajetória. Somente no instante do impacto, corrigir o ponto final necessário para o contato espacial exato.

## Relações e questões de compatibilidade

- **Referências:** D-004; D-019; R40-Q4; R40-Q6.
- **Observação:** Não implementar perseguição contínua durante STRIKE.
- **Implementação:** não modificar comportamento do jogo apenas pela criação deste registro; avaliar divergências antes da implementação.
