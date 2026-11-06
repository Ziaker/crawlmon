# D-344 — Rodada 86 Q1 (1A): Repel devolve golpe de alvo único ao atacante original, sem cadeia de reflexões

- **Data:** 2026-11-06.
- **Área:** Combate / afinidades elementais / Repel.
- **Origem:** escolha expressa do criador na Rodada 86.
- **Estado:** regra de destino de Repel para alvo único aprovada; outros comportamentos e implementação pendentes.

## Declaração literal do criador

> 1A — Repel devolve o golpe ao atacante original uma vez, sem reflexões em cadeia.

## Regra aprovada

- Se um **golpe de alvo único** for atingido pela afinidade **Repel** aplicável, o golpe deve **ser devolvido ao seu atacante original**, **uma única vez**.
- **Impedir reflexões em cadeia** do mesmo golpe: não refletir novamente a reflexão que já ocorreu, evitando repetição indefinida. O golpe não é redirecionado automaticamente a outro aliado nem substituído por um contra-ataque diferente.
- Esta regra especifica **destino e limite da reflexão**, complementando **D-276** (Repel como afinidade possível por espécie/elemento), **D-118/D-128** (afinidades inspiradas em SMT) e **D-235** (Moves iguais funcionam para qualquer personagem, lado e posição).
- **Exemplo hipotético:** um combatente lança Fire Bullet contra um alvo com **Repel de fogo**, caso essa afinidade venha a ser aprovada para tal espécie. O golpe de alvo único **retorna ao lançador original**, sem gerar segunda reflexão do próprio golpe. Nenhuma espécie real recebeu Repel nesta decisão.
- A reflexão não torna o Move exclusivo de um usuário ou time. Preservar os custos e demais regras do Move original até definição explícita de como a reflexão os afeta.

## Pendências e limites

- Não foram definidos **dano refletido, velocidade/tempo/trajeto do projétil, chances de esquiva/crítico/status, alteração do alvo de outros efeitos, interações com Null/Drain, status/escudos, recompensas ATB/Burst ou implicações de mortes simultâneas**; não completar por analogia.
- **AoE e multi-hit** não foram abrangidos pela escolha de alvo único e dependem de regra própria; não extrapolar.
- **Somente documentação:** nenhum código, ficha, Resource, Move, teste, IA, cena, shader, asset ou VFX alterado.
