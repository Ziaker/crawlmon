# D-099 — R46-Q3 (3A): Aguardar projéteis em voo antes do resultado definitivo

- **Data:** 2026-11-03
- **Área:** Combate / Rodada 46
- **Estado:** decisão de design e sequenciamento aprovada por aceitação das recomendações; implementação não afirmada.
- **Proveniência:** o usuário aceitou expressamente as recomendações 1B, 2A e 3A; o conteúdo da alternativa foi recomendado pelo assistente, não digitado individualmente pelo criador.

## Declaração literal do criador

> Crawlmon — Rodada 46: sigo suas recomendações 1B, 2A e 3A. Registre imediatamente no GitHub conforme D-061, preserve as decisões anteriores, não modifique código, valide a publicação e inclua as perguntas importantes da próxima rodada na MESMA resposta.

## Pergunta e alternativa recomendada aceita

- **Pergunta:** Se o último personagem de uma equipe morrer, mas ainda houver projéteis lançados em voo, quando encerrar a batalha?
- **Alternativa:** **3A — Aguardar a resolução dos projéteis já lançados antes de determinar o resultado final, permitindo empate.**

## Regra aprovada

Se a última unidade de uma equipe morrer **enquanto ainda houver projéteis previamente lançados em voo**, **adiar a determinação definitiva do resultado da batalha até a resolução dos projéteis já lançados**, que continuam ativos mesmo se o lançador morreu (D-094). Caso os projéteis pendentes eliminem também a outra equipe, **permitir empate sem vencedor**; não declarar vitória ou derrota antes de resolver esses ataques pendentes. A exibição da tela de resultado continua aguardando as sequências fatais pertinentes.

## Referências e limitações

- **Referências:** D-019, D-047, D-081, D-090, D-091, D-094, D-095, D-096.
- **Questões em aberto:** Esta decisão contempla a exceção de projéteis pendentes à comparação estrita de mortes no mesmo instante lógico da D-095; não generalizar para novos ataques lançados após a eliminação. **Não foi decidido se os personagens sobreviventes ainda podem iniciar novas ações durante essa espera**. Preservar D-096 para lutas logicamente em andamento sem esse caso-limite.
- **Escopo desta entrega:** criar somente documentação. Nenhum código de jogo, FX, teste ou configuração foi alterado.
