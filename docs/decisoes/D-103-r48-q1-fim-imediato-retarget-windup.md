# D-103 — R48-Q1: Último inimigo termina batalha; com outros inimigos, wind-up retargeta

- **Data:** 2026-11-03
- **Origem:** declaração literal do criador na Rodada 48.
- **Estado:** declaração recebida e registrada; **conflitos com decisões anteriores permanecem explícitos e exigem confirmação**, sem supor prioridade nem implementação.

## Declaração literal do criador

> 48 1 - se e o ultimo inimigo presente, a batalha acaba no segundo que ele for derrotado, se tiver outros, o jogo funciona normalmente e se o pikachu estiver no wind up ele apenas troca de alvo para realizar o ataque, e ainda sim pode ser atingido pelo projetil jogado

## Conteúdo explícito da declaração

- **Último inimigo:** se o inimigo derrotado era o último inimigo presente, o criador determina que a batalha **acaba no instante da derrota dele**. A interpretação técnica precisa (encerramento lógico, tela de resultado, projéteis em trânsito) está assinalada como **conflito pendente** abaixo, sem revogar silenciosamente regras anteriores.
- **Ainda existem outros inimigos:** o combate **continua normalmente**. Se Pikachu já estava no **wind-up de um ataque** e o alvo morre, Pikachu **troca de alvo para executar o ataque**; o criador não determinou um novo custo, reinício de wind-up nem política de seleção do novo alvo.
- **Projéteis lançados:** Pikachu **continua podendo ser atingido pelo projétil já disparado** nessa situação em que outros inimigos permanecem. Preserva-se D-094 para projéteis lançados após a morte do atirador, na medida em que não conflitante com o fim da batalha.

## Divergências com regras anteriormente aprovadas (sem resolução automática)

- **D-099 / D-100:** determinam esperar projéteis já lançados antes de fixar o resultado, mesmo após eliminação da equipe; a nova declaração exige terminar a batalha imediatamente ao derrotar o último inimigo. **Não foi decidido se isso substitui a espera, nem se o projétil pendente pode atingir após o último KO.** Manter os dois registros, exigir conciliação explícita.
- **D-081 / D-090:** a exibição da tela final aguarda as sequências fatais. O usuário disse que a **batalha** termina no segundo do KO, mas não disse que a **tela de resultado** precisa aparecer no mesmo segundo. Não interpretar o encerramento lógico como ordem para suprimir animações.

## Referências e pontos em aberto

- **Relacionadas:** D-004; D-019; D-037; D-081; D-090; D-094; D-096; D-099; D-100.
- **Pendências:** Se o novo encerramento imediato também vale quando a equipe aliada fica sem combatentes; qual é o destino de projéteis pendentes e do empate nesse caso; critério para selecionar novo alvo do wind-up. Nenhum deles foi definido por essa frase.
- **Escopo:** somente documentação; nenhum código, teste, animação ou FX do jogo é alterado.

## Conciliação posterior (2026-11-03)

**Conflito encerrado pela resposta expressa D-105:** a vitória ao derrotar o último inimigo é definitiva naquele instante; projéteis em voo não podem causar dano nem mudar o resultado. Isso prevalece especificamente sobre a espera de D-099/D-100 nesse caso. Permanece o cenário já documentado em que há outros inimigos, com combate normal, redirecionamento durante wind-up e possibilidade de ser atingido por projétil lançado.

## Complemento posterior — Rodada 49

D-107/D-108: a derrota da última unidade aliada também é definitiva, sem dano posterior de projéteis. Se ainda existem outros inimigos e o alvo morre durante wind-up, o jogo retargeta automaticamente para o inimigo vivo mais próximo (D-108). Nenhuma mudança adicional de custo, duração ou escolha manual foi aprovada.
