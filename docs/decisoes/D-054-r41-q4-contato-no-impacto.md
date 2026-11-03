# D-54 — R41-Q4 (4A): Ajuste espacial somente no impacto

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
