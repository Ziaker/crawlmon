# D-219 — Rodada 74 Q4 (4A): ordenar rolagens simultâneas de status pelo ID estável do alvo

- **Data:** 2026-11-04.
- **Área:** Combate / status / RNG / simultaneidade.
- **Origem:** escolha expressa do criador na Rodada 74.
- **Estado:** regra de ordenação aprovada; não implementada nesta atividade.

## Declaração literal do criador

> 4A — Ordenar as rolagens simultâneas de status por ID estável do alvo antes de consumir RNG, sem alterar a simultaneidade lógica dos efeitos.

## Regra aprovada

- Quando houver **rolagens de aplicação de status simultâneas** dirigidas a **alvos diferentes**, **ordenar seus consumos de números pseudoaleatórios pelo ID estável do alvo**, antes de consumir o RNG correspondente.
- Essa **ordem de consumo do RNG** não altera o **instante lógico de aplicação dos efeitos** nem cria prioridade de dano, status, KO, vitória ou derrota entre os alvos. Preservar **D-095**: eliminações simultâneas de ambas as equipes continuam empate.
- **Exemplo somente ilustrativo:** Abra (ID 2) e Pancham (ID 5) são elegíveis a rolagens de Poison no mesmo instante lógico. Para consumir o RNG de status, processar a rolagem do **ID 2 antes da do ID 5**, **sem estabelecer que o efeito do ID 2 ocorreu logicamente antes**. IDs, chances e personagens são somente didáticos.
- Preservar **D-213** para a **ordem de status distintos dentro da ficha de um Move** e **D-210/D-207/D-211** para limites individuais, elegibilidade e última ocorrência de impacto por alvo; preservar D-134/D-146/D-156 para efeitos probabilísticos de LUK e garantidos. **Não rolar efeito ineligível**, por exemplo após KO ou esquiva válida (D-199/D-195).
- **Não confundir com D-186–D-189/D-192/D-214/D-218:** essas decisões organizam o **fluxo exclusivo de RNG de retarget**. Esta regra se refere **ao RNG de status**, sem aprovar novo fluxo, seed ou algoritmo.

## Limites e pendências

- Se **várias rolagens simultâneas tiverem o mesmo alvo e pertencerem a Moves diferentes**, a ordenação **por ID do alvo não basta** para desempatar: **nenhuma prioridade adicional foi escolhida**.
- Não foram definidos algoritmo/seed/estado do RNG de status, agregação técnica de eventos simultâneos, prioridade frente a outras categorias de RNG, nem a ordem de processamento de status concorrentes de Moves diferentes. Não inferir essas decisões.
- Somente documentação; nenhum código, teste, Move, ficha, VFX, cena ou asset modificado.
