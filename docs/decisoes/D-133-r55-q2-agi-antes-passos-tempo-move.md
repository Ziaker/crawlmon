# D-133 — Rodada 55 Q2 (A): Redução por AGI antes do ajuste dos passos no tempo individual do Move

- **Data:** 2026-11-03
- **Área:** Atributos e progressão de Pokémon / Rodada 55.
- **Proveniência:** escolha **expressamente enviada pelo criador**, aceitando alternativa recomendada previamente pelo assistente; a decisão foi escolhida pelo criador, não deduzida de delegação à IA.
- **Estado:** decisão de design aprovada e registrada; **não implementada nesta atividade**.

## Declaração literal do criador

> 2A — Em qual ordem aplicar AGI e posicionamento ao tempo do Move? Reduzir primeiro o tempo do Move por AGI; depois aplicar o ajuste dos passos, respeitando o mínimo aprovado. (recomendação aceita)

## Regra aprovada e compatibilidade

- O cálculo do deslocamento de ataque começa pelo **tempo próprio definido na ficha de cada Move** (D-119).
- **Primeiro**, aplica-se a redução desse tempo decorrente de **Agility (AGI) e dos efeitos que aumentam AGI** (D-117/D-119). **Depois**, aplica-se o ajuste de passos posicionais já aprovado em **D-018**: subtrair **0,10 s × (pos_step do atacante + pos_step do alvo)**.
- **Ao final**, respeitar o **mínimo de 0,25 s** já aprovado em D-018. Esta decisão estabelece a ordem de operação e não substitui a fórmula histórica de passos; a regra de passos também continua influenciando dano e custo de reposicionamento como antes.
- **Notação apenas da ordem, não uma fórmula de AGI aprovada:** `t_final = max(0,25 s, t_move_apos_AGI − 0,10 s × (passo_atacante + passo_alvo))`. A função que produz `t_move_apos_AGI` **ainda não foi definida**.
- **Exemplo apenas para ilustrar a ordem:** se um Move partisse de 0,80 s, uma redução hipotética de 25% por AGI produz 0,60 s; um ajuste posicional de −0,20 s resultaria em 0,40 s. **25% não é valor aprovado**.
- **Pendências:** curva e limites de AGI, sua combinação com efeitos de buffs, calibração de ATB (D-126) e valores individuais das fichas de Moves; não alterar alcance de AGI para projéteis por suposição.

## Estado de execução

- **Documentação somente:** não alterar código, cenas, tabelas, fichas de Moves, VFX, testes ou configurações do projeto.
- As fórmulas e dados marcados como pendentes não podem ser completados por suposição.
