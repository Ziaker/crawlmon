# D-321 — Inimigos também andam em grupo no overworld

- **Data:** 2026-11-05
- **Área:** Exploração / IA
- **Origem:** Conversa (respostas F3 sobre grupos inimigos)

## O que o criador disse (literal)

> os inimigos em grupo, também andam em grupo assim como o jogador, inimigos sozinhos andam sozinhos, soma da mesma forma que soma a do grupo do jogador

> Grupo solto

> alguns podem ter a mesma espécie, outros tem variadas, definido aleatoriamente

> O próximo vira líder

> A soma define o grupo

> o jogo é apenas entre equipes de 3, nao havera batalhas contra 4

## Decisão

1. Inimigos podem aparecer **em grupo** ou **sozinhos**. O grupo é **solto**: cada inimigo calcula o próprio caminho, mas eles se mantêm próximos.
2. O tamanho máximo é **3 inimigos** (o jogo é entre equipes de 3; não haverá 4). Inimigo sozinho = grupo de 1.
3. A composição é **aleatória**: às vezes todos da mesma espécie, às vezes espécies variadas.
4. O **nível do grupo** é a **soma dos níveis dos membros**, como a soma do grupo do jogador. Essa soma define a **ameaça do grupo**; cada membro usa o **próprio nível** para o ícone e o tamanho.
5. Quando o **líder é derrotado**, o **próximo vira líder** e o grupo continua.
6. A batalha 3D continua com o Gible fixo (D-319); o grupo é do overworld.

## Ambiguidades em aberto

- Como o grupo solto mantém coesão (raio máximo entre membros; alvo de patrulha compartilhado)?
- O contato com qualquer membro inicia batalha? (D-319: sim, mas a batalha 3D continua Gible.)
- Proporção de grupos vs sozinhos e regra de composição por bioma/seed.

## Estado no código

Não implementado.
