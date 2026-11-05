# D-273 — Rodada 84 reformulada Q1 (C): transição direta no protótipo, chefes obrigatórios nas dungeons de campanha do jogo completo

- **Data:** 2026-11-05.
- **Área:** Exploração / estrutura das dungeons / protótipo e campanha.
- **Origem:** escolha expressa **C** da resposta literal do criador `C C C A` à Rodada 84 reformulada.
- **Estado:** decisão de design aprovada; **não implementada nesta alteração documental**.

## Pergunta e alternativa aprovada

**Pergunta:** "O que realmente acontece no 5º andar?"

> C — Separar protótipo e jogo completo: por enquanto, transição direta após cinco andares; no jogo completo, as dungeons de campanha continuam exigindo chefes.

**Resposta literal do criador:** `C C C A` (primeiro **C**).

## Regra aprovada

- **No protótipo/escopo provisório de exploração**, preservar a transição direta ao utilizar a escada após **cinco andares**, iniciando nova dungeon/expedição de acordo com a **D-316**, **sem exigir chefe nessa transição provisória**.
- **No jogo completo**, preservar a regra histórica de campanha **GDD R23-Q2, R24-Q1 e R26-Q4**: **concluir uma dungeon de campanha exige vencer seu chefe no último andar**. A passagem provisória automática do protótipo **não equivale** a substituir essa regra da campanha.
- Preservar as regras independentes da **D-316** para a nova expedição (andar 1, nova seed, MP cheio, Natures novas, mantendo equipe, itens e HP) no escopo provisório aprovado, e **D-317** para a passagem de biomas; não alterar outros parâmetros.
- **Exemplo:** durante o protótipo, o jogador alcança a escada do 5º andar e inicia a nova expedição sem chefe obrigatório. Em uma dungeon de campanha do jogo completo, a conclusão requer enfrentar o chefe final, conforme a regra histórica de campanha.

## Pendências e limites

- Não foi aprovado **quando** o protótipo dará lugar ao fluxo completo, quantos andares cada dungeon final terá, como integrar a escada e o encontro do chefe no mesmo andar, quais chefes existem nem o efeito de chefes na geração procedural ou recompensas.
- A escolha **não autoriza implementação** ou modificação do combate 3D, overworld, cenas, assets, VFX, fichas ou conteúdo; não declarar mecânica implementada.
- Histórico preservado: **D-316 e regras de campanha continuam documentadas**, com escopos distintos explicitados nesta D-273.
