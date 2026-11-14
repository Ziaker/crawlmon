<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

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

## Complemento posterior — Rodada 56 (2026-11-03)

**D-136 (Rodada 56, Q2A):** a redução por **AGI efetiva** deve ser **inversamente proporcional**, usando uma **AGI de referência comum a todas as espécies**. Preservar a ordem já aprovada nesta D-133: tempo próprio do Move → redução por AGI (incluindo buffs) → correção por passos D-018 → piso de 0,25 s. O valor de AGI de referência, arredondamento e tratamento de zero/não positivo continuam indefinidos.
