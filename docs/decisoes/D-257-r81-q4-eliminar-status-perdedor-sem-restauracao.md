# D-257 — Rodada 81 Q4 (4A): status de menor prioridade é eliminado e não restaurado

- **Data:** 2026-11-04.
- **Área:** Combate / incompatibilidade entre status de Moves distintos / matriz aprovada.
- **Origem:** decisão expressa do criador na Rodada 81.
- **Estado:** efeito da prioridade aprovada; **matriz concreta, pares e vencedores não homologados**; não implementado.

## Declaração literal do criador

> 4A — Eliminar o status de menor prioridade: se já estava ativo, removê-lo; se estava chegando, impedir sua aplicação. Não restaurá-lo quando o vencedor terminar.

## Regra aprovada

- **Somente quando existir uma entrada concreta de prioridade aprovada na matriz de pares de status incompatíveis** exigida por D-239/D-243, aplicar a precedência nela definida, tanto para **status de Moves diferentes que chegam simultaneamente** quanto para **status previamente ativo e outro aplicado depois por Move diferente** (D-253).
- O **status de menor prioridade deve ser eliminado**: **se já estiver ativo, removê-lo**; **se estiver em processo de aplicação, impedir essa aplicação**.
- **Não conservar nem reativar o status perdedor quando o efeito de maior prioridade terminar**. Não há suspensão com contagem de duração nem pausa da duração do efeito eliminado.
- **Exemplo estritamente hipotético, sem homologar incompatibilidades reais:** `Status X` já está ativo e um Move diferente tenta aplicar `Status Y`. **Se futuramente** uma matriz aprovada identificar ambos como incompatíveis e atribuir prioridade a Y, X será removido quando a regra for aplicável; X **não retornará** após o encerramento de Y. Invertida a precedência aprovada, Y **não será aplicado**. O exemplo não atribui prioridade ou regras de chance a X/Y reais.
- Preservar D-215/D-217 (prioridade expressa entre status incompatíveis declarados **dentro da mesma ficha**), D-210/D-213 (teto e ordem de tentativas), D-219/D-223/D-227/D-234 (eligibilidade, ordem e consumo de RNG), D-095 (KO simultâneo) e D-235 (independência de personagem/lado). **Ordem de RNG não decide o vencedor**; status precisam continuar sujeitos às condições de aplicação aprovadas.

## Pendências e escopo

- **Nenhuma entrada concreta da matriz, par de status incompatível ou vencedor foi aprovado nesta rodada.** A D-257 **não constitui autorização de remover, bloquear ou reescrever status concretos** até a política por pares ter aprovação.
- Ainda não foram definidas a ordem exata entre rolagem probabilística e checagem de incompatibilidade, a consequência caso falte entrada da matriz, como tratar status oriundos de um mesmo Move para além de D-215, nem rotinas de UI ou sincronização de remoção. Não inferir.
- Somente documentação: nenhum código, Move, ficha operacional, teste, IA, cena, asset ou VFX alterado.
