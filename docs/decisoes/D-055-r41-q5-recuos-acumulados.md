# D-55 — R41-Q5 (5B): Acumulação temporária dos recuos visuais

- **Data:** 2026-11-02
- **Origem:** decisão direta do criador, R41; eventuais complementos posteriores estão reproduzidos abaixo.
- **Estado:** decisão de design aprovada; nenhuma implementação afirmada por este documento.

## Declaração do criador (literal)

> 5B — Como funciona o recuo visual quando vários hits atingem o personagem em sequência?: Os recuos visuais se acumulam temporariamente e depois retornam à posição lógica.

## Regra aprovada

Hits consecutivos acumulam deslocamentos de recuo apenas na apresentação visual. Depois, o modelo retorna à posição lógica inalterada pelo recuo.

## Relações e questões de compatibilidade

- **Referências:** R40-Q5; D-019.
- **Observação:** Aplicável aos hits comuns. A morte de inimigos segue a sequência fatal específica R41-Q6.
- **Implementação:** não modificar comportamento do jogo apenas pela criação deste registro; avaliar divergências antes da implementação.
