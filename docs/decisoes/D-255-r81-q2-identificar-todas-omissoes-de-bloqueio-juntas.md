# D-255 — Rodada 81 Q2 (2A): identificar todas as causas de bloqueio já aprovadas na mesma validação

- **Data:** 2026-11-04.
- **Área:** Combate / validação de fichas de Move / recursos.
- **Origem:** decisão expressa do criador na Rodada 81.
- **Estado:** comportamento de validação aprovado; não implementado nesta atividade.

## Declaração literal do criador

> 2A — Quando um Move apresentar múltiplas causas de bloqueio já aprovadas, identificar todas as omissões detectadas na mesma validação, sem cobrar ação ou recursos.

## Regra aprovada

- Ao validar um Move, se forem detectadas **várias causas de bloqueio que já possuam aprovação expressa**, **identificar todas as omissões detectadas nessa mesma validação**, em vez de informar uma única causa e exigir nova tentativa para revelar as demais.
- A validação deve ocorrer **antes da confirmação e de qualquer consumo de ação ou recursos**; se houver bloqueio, **não consumir ATB, Burst, MP aplicável nem a oportunidade de ação**, preservando D-225/D-238.
- As duas causas de bloqueio atualmente aprovadas para este contexto são: **prioridade obrigatória ausente entre status expressamente declarados incompatíveis** (D-215/D-217/D-221), e **máximo explícito ausente para ocorrências condicionais variáveis no plano** (D-233/D-238).
- **Exemplo abstrato:** uma ficha contém efeitos `Status A` e `Status B` **declarados incompatíveis** sem prioridade e possui ocorrências condicionais variáveis sem declarar máximo. Uma **única validação** informa **ambas as omissões** e bloqueia confirmar o Move, **sem debitar ação/ATB/Burst/MP**. `Status A`/`Status B` são rótulos fictícios: nenhum par concreto se torna incompatível por este exemplo.
- Para a IA, preservar **D-232/D-251** (excluir antes da escolha tática Moves que tenham essas omissões), **D-237** (considerar Tackle separadamente quando nenhum Move válido permanecer e Tackle elegível) e **D-241** (sem Move/Tackle elegíveis, não agir nem gastar; reavaliar na próxima oportunidade normal).
- O bloqueio não altera consumo das ações válidas; preservar D-228 (MP adicional para Moves mágicos/especiais quando aplicável) e D-235 (independência de personagem/lado).

## Pendências e escopo

- **Não foram aprovados** texto ou layout da mensagem, ordem de apresentação das omissões, regra geral de bloqueio para todos os campos possivelmente faltantes, implementação de validador, API ou registro de erros.
- Identificar **todas as omissões detectadas** não autoriza inventar novas causas de bloqueio; o resultado da validação permanece limitado às regras existentes e futuras expressamente aprovadas.
- Somente documentação: nenhum código, IA, teste, Move, ficha operacional, cena, VFX ou asset modificado.
