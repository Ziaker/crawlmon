<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-056 — R41-Q6 (6D): Lançamento fatal cinematográfico e desaparecimento

- **Data:** 2026-11-02
- **Origem:** decisão direta do criador, R41; eventuais complementos posteriores estão reproduzidos abaixo.
- **Estado:** decisão de design aprovada; nenhuma implementação afirmada por este documento.

## Declaração do criador (literal)

> 6D — E quando o hit é fatal?: Outra regra.
> 
> Crawlmon — Complemento R41-Q6D, hit fatal: o inimigo é lançado pra trás, voando até cair no chão e sumir, meio dragonball-esco ou smash bros. Preserve as demais decisões das Rodadas 39, 40 e 41. Não altere arquivos ainda.

## Regra aprovada

Se um hit mata um inimigo, exibir lançamento para trás pelo ar, queda ao chão e desaparecimento posterior, com estética exagerada inspirada em Dragon Ball / Super Smash Bros. Trata-se da sequência visual fatal do inimigo.

## Relações e questões de compatibilidade

- **Referências:** D-024; D-025; R40-Q5; R41-Q5.
- **Observação:** Substitui a permanência do corpo no chão para inimigos. Não define alcance, tempo, FX exato ou regra equivalente para aliados.
- **Implementação:** não modificar comportamento do jogo apenas pela criação deste registro; avaliar divergências antes da implementação.

## Complemento posterior (2026-11-03)

**D-166:** para inimigos, o modelo encolhe e some ainda no ar, sem queda ao chão.
