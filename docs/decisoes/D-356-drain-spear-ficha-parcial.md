# D-356 — Drain Spear: ficha parcial e requisitos próprios do Move

- **Data:** 2026-11-06.
- **Área:** Fichas de Moves / contato / dano / VFX / integração.
- **Origem:** ficha técnica enviada pelo criador, respostas DS1 e confirmações DS2.
- **Estado:** requisitos específicos aprovados; ficha **ainda incompleta**, sem implementação ou validação in-game.

## Declarações literais do criador (trechos)

> **ID Interno:** `move_drain_spear`
>
> **Nome de Exibição:** Drain Spear
>
> **Escopo do Move:** Global (Primeiro usuário: Orc)
>
> 12MP, tipo fisico, elemento Normal
>
> **Fórmula de Dano:** `5 + MAG, dano magico (corrigido)`
>
> 1 - obviamente baseado no dano, ou seja, SPI
>
> 3 5 + o status de mag atual, se o usuario tem 10 de mag entao o dano e 15
>
> 7 por ora sim, preciso da referencia visual de como ficara in-game
>
> Drain spear ao invés de usar o nome drain, use como keyword, "Badge Steal" sigo suas recomendações

## Identidade, custo e dano aprovados

- **Nome:** Drain Spear. **Identificador estável solicitado:** `move_drain_spear`. O primeiro usuário planejado é Orc, mas o Move é **global** e independente de espécie, lado e anatomia (D-235).
- **Seleção:** um alvo oponente. **Execução:** ataque de **contato** por estocada de lança mágica. **Alcance:** mid-range segundo D-358.
- **Elemento:** **Normal**, conforme D-357, sem substituir silenciosamente o identificador legado `FISICO`.
- **Custo normal:** **2 ATB + 12 MP**; preservar D-270 quando Burst paga a ação inteira.
- **Dano:** **mágico**, escalado por **MAG atual** do atacante, mitigado naturalmente por **SPI**, e sujeito aos demais modificadores aplicáveis já aprovados. Parcela-base expressa `5 + MAG`; com MAG atual 10, a parcela corresponde a 15 antes de outros modificadores. Não inserir fator de potência extra, escala STR nem fórmula suplementar não escolhida.
- A expressão histórica **«tipo físico»** na ficha inicial não deve transformar o dano em físico ou fazê-lo usar VIT: a execução é contato, ao passo que o dano foi explicitamente corrigido para mágico. Se houver uma etiqueta de UI «categoria física» separada de execução, seu destino ainda requer conciliação na ficha final.
- **Efeito especial:** keyword **Badge Steal**, D-359; não confundir com afinidade **Drain** de recuperação de HP/MP da D-352.

## Trajeto e temporização

- **Distância-alvo do Move:** 16,3 unidades entre centros, aceitando faixa de 15,3–17,3 unidades, conforme D-358 e as confirmações **«mid-range A»**.
- Fora da faixa, o atacante se aproxima se estiver longe, recua se estiver perto ou permanece quando o deslocamento do oponente já torna a faixa válida; não precisa alcançar o ponto central exato quando estiver na faixa aprovada.
- Ao atingir a faixa válida antes de esgotar o reposicionamento, **para de se mover e prossegue para a estocada quando os pré-requisitos temporais de execução estiverem cumpridos**. Se o **recuo** não alcançar a faixa no prazo, executa o Move mesmo assim, conforme regra própria expressa do criador.
- O **recuo** possui tempo-base declarado de **1,2 s**, com redução por AGI pelas regras de deslocamento existentes (D-119/D-133/D-136/D-140/D-148), sem calibrar por suposição o valor numérico da AGI de referência. O que acontece com o tempo total quando a posição se torna válida antes do prazo requer teste e especificação de gatilhos.
- **Wind-up 1 s, execução 1 s, recovery 1,6 s:** aceitos **por ora**, como referência provisória para teste visual, não homologados como duração final comprovada. Preservar separação de preparação, deslocamento, contato e retorno conforme D-245.
- O Evade contra ataque de contato se mantém na fase do golpe até o impacto, **não** na aproximação, conforme D-030; preservar demais regras de Tackle apenas quando compatíveis com as exceções declaradas.

## VFX e HUD — somente descrição aprovada

- Lança mágica de ponta azul se forma **verticalmente, do cabo à ponta**, junto ao corpo do usuário, com brilho, sparkles e aura de baixa opacidade junto à ponta; independe de arma física no modelo.
- Quando apropriado, inclina-se para o alvo e acompanha o deslocamento, com speedlines azuis; **se o adversário se desloca em direção ao usuário durante o ajuste de posição**, a lança pode permanecer ereta, com os efeitos de preparação, até estar apta a realizar a estocada.
- Na fase de contato, a lança avança e atinge o alvo. O efeito do impacto foi corrigido pelo criador: **spray curto em leque semelhante à dispersão de uma shotgun**, partindo do ponto acertado, **não** um cone geométrico contínuo. A referência de dissipação do efeito é **0,55 s**; a lança dissipa a partir do cabo, reduzindo opacidade.
- Havendo roubo efetivo de efeitos positivos, a energia visual do **Badge Steal** se orienta **do alvo em direção ao usuário**, ao contrário da dispersão comum, e orbita o atacante.
- As **badges** transferidas na HUD percorrem visualmente **alvo → atacante em aproximadamente 0,3 s**, inspiradas no feedback de recompensas ATB/Burst; os eventos do motor continuam autoritativos sobre o instante mecânico, segundo D-348.
- O mockup de referência criado na conversa **não representa a orientação/ângulo real da câmera do jogo**. VFX e UI devem ser relativos a atacante, alvo, dimensões corporais e camera real, conforme D-235/D-334/D-338.
- **BattleLog:** preservar a opção C de D-322 (ícone do personagem, faixas diagonais claras, posição superior direita); o criador aceitou recomendações para registro de uso, acerto, roubo e ausência de efeitos. Textos exatos ainda não são contrato final de mensagens.

## Pendências e limites

- Definir o **contato mecânico** da lança a 16,3 unidades sem converter automaticamente o Move em projétil e sem teletransportar o atacante até 2,6 unidades; distinguir trajetória visual da lança, janela de Evade e colisão autoritativa.
- Resolver o caso em que uma **imunidade a dano mágico conferida por badge é roubada antes do dano**: o golpe passa então a causar dano normalmente, ou a imunidade ainda vale para o mesmo impacto? Não decidir sem o criador.
- Determinar eventos exatos e sobreposições entre Wind-up, aproximação/recuo, animação de 1 s, contato, dissipação 0,55 s, deslocamento da badge 0,3 s e recovery 1,6 s; verificar cenários de alvo móvel, interrupção, KO e engajamento após Evade.
- Fixar âncoras anatômicas e fallbacks para modelos distintos, além da verificação in-game nos lados espelhados e tamanhos diferentes.
- A graduação de MAG e SPI, a afinidade específica de Normal, o tratamento de efeitos roubados com magnitudes dependentes de atributos e as reservas de escudos ainda dependem de sistemas e decisões externas.
- O Move, o elemento Normal, o sistema de escudos, o sistema completo de atributos e os Resources de Moves não estão implementados nesta documentação. Não modificar código nem presumir que o protótipo visual constitui prova de funcionamento.

## Relações

D-001, D-003, D-019, D-022, D-030, D-061, D-119, D-122, D-133, D-136, D-140, D-148, D-149, D-194, D-195, D-199, D-235, D-244–D-249, D-258, D-263, D-268, D-270, D-322–D-325, D-333–D-343, D-348–D-352, D-357–D-359.
