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
