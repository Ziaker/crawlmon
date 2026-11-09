# D-1010 — Estilo do rastro do Swing por personagem

- **Data:** 2026-11-08.

## Frase literal do criador

> mas pq não pode ter os dois? o que que vc fez no codigo que faz com que ambas decisões não possam existir? eram pra existir, afinal é específico para cada personagem, não tem logica mudar 1 coisa em 1 e isso acabar mudando nos outros também exceto se for algo global...

## Causa

Eu tinha feito uma regra automática única (medir quanto a mão anda) para escolher entre "seguir a mão" e "arco"; ela dependia do trecho do clipe e trocava os dois personagens.

## Decisão

1. O estilo do rastro do Swing é **definido por personagem** (o criador aprova um a um; mudar um não muda os outros).
2. Hoje: **Pancham = arco** (D-1009). Os demais usam o estilo automático por tipo de corpo: mão (Abra, aprovado), arma grossa (Cyclops, aprovado), ponta da lança (Orc, aprovado), linhas de velocidade (Slime).
3. Revertido o salto do início do clipe de ataque (D-997 item 2): não resolveu a pausa (a causa era a D-999) e mudava o Abra aprovado.
4. **Exceção registrada à D-235** apenas para o estilo visual do rastro, a pedido do criador.

## Estado

Implementado.
- D-1011: Abra volta ao rastro aprovado (sem a trava de membro da D-995, que agora não é usada).
