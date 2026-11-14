<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-045 — R40-Q5 (5B): Recuo visual em qualquer hit recebido

- **Data:** 2026-11-02
- **Origem:** decisão direta do criador, R40; eventuais complementos posteriores estão reproduzidos abaixo.
- **Estado:** decisão de design aprovada; nenhuma implementação afirmada por este documento.

## Declaração do criador (literal)

> Observações: 5 - o recuo deve acontecer a QUALQUER HIT QUE LEVA, NÃO SÓ QUANDO ATACA, QUEM DISSE QUE ERA SÓ QUANDO ATACA? REESCREVE ESSA MERDA
> 
> Crawlmon — R40-Q5: B. Recuo visual em qualquer hit recebido, mantendo posição lógica. Não altere arquivos ainda.

## Regra aprovada

Todo hit recebido provoca recuo visual, independentemente de o personagem estar ou não atacando; esse recuo não muda a posição lógica. Não restringir a ataques interrompidos ou personagens em movimento.

## Relações e questões de compatibilidade

- **Referências:** D-019; D-024; R41-Q5; R41-Q6.
- **Observação:** R41-Q5: acumulação visual. R41-Q6: sequência fatal específica para inimigos.
- **Implementação:** não modificar comportamento do jogo apenas pela criação deste registro; avaliar divergências antes da implementação.
- **Sobreposta em parte por D-1073 (2026-11-09):** **projéteis** não empurram visualmente no contato; melee e mid-range (CAST) continuam empurrando. O recuo acumulado (R41-Q5/D-055) continua valendo quando o Move empurra.
