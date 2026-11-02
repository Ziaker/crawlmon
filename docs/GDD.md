# CRAWLMON — Game Design Document (GDD)

> **Estado:** documento vivo de design, com decisões aprovadas e pendências explícitas.  
> **Revisão:** 1.23 — Rodada 32 de gameplay consolidada, 2026-11-01.  
> **Repositório:** [Ziaker/crawlmon](https://github.com/Ziaker/crawlmon).  
> **Referência do código no momento desta revisão:** branch `main`, commit `1171b5f3c427edc34c486c82d42569f41fd0ea62`.  
> **Implementação:** este documento registra requisitos; não implica que as mecânicas estejam implementadas.

## 0. Objetivo e regras de governança

Este GDD descreve o **Crawlmon**, um dungeon crawler inspirado na exploração de *Pokémon Mystery Dungeon* e na tomada de decisões táticas de *Shin Megami Tensei III: Nocturne*. A identidade mecânica definida para o Crawlmon é um **ATB individual de cinco blocos, consumidos por ações, com recompensas instantâneas e Evade/Burst reativos**. Não há aprovação de uma implementação literal de ícones Press Turn.

### Níveis de evidência

- **APROVADO:** regra estabelecida expressamente pelo criador na conversa de definição do jogo.
- **DERIVADO:** consequência lógica de decisões aprovadas; explicitada para revisão, não é regra adicional independente.
- **PENDENTE:** questão ainda não decidida. Opções e exemplos de perguntas não são requisitos.
- **IMPLEMENTADO/OBSERVADO:** comportamento confirmado por leitura de código no commit de referência; não equivale a teste de execução.
- **NÃO VERIFICADO:** execução no Godot, comportamento em tempo real, testes, animações e integridade de assets não foram validados nesta revisão.

### Política de atualização por rodadas de cinco respostas

1. Apresentar **cinco perguntas numeradas** por rodada, sem aprovar implicitamente respostas ausentes.
2. Após o criador responder às cinco, consultar novamente a `main`, reler este GDD e **atualizar este mesmo arquivo** no GitHub.
3. Registrar a rodada no histórico com IDs de questões, respostas, data e commit resultante.
4. Marcar cada nova regra como **APROVADO**, retirar somente as pendências efetivamente resolvidas e manter as demais intactas.
5. Quando houver contradição, preservar as duas declarações, apontar a incompatibilidade e solicitar resolução; não escolher silenciosamente uma delas.
6. Nunca interpretar documentação como comprovação de funcionalidade implementada. Preservar código e demais documentos sem solicitação expressa.
7. Não há monitoramento autônomo: a atualização ocorre quando as cinco respostas forem fornecidas na conversa e houver acesso de escrita ao repositório.

## 1. Visão do produto e experiência de jogo

**APROVADO:** o protagonista é um **Pokémon controlado diretamente pelo jogador**, não um treinador humano. O jogo alterna entre dois modos visuais e funcionais:

1. **Exploração 2D:** dungeon em mapa bidimensional, com enquadramento e identidade de exploração inspirados em *Pokémon Mystery Dungeon*. O protagonista é controlado diretamente pelo jogador.
2. **Combate 3D:** encontro em arena/cena separada, com **modelos tridimensionais dos mesmos Pokémon** que participam da exploração. A batalha tem interface própria de comandos, animações e ATB.

**APROVADO:** os aliados são controlados pela **inteligência artificial**; **Tactic somente orienta o comportamento da IA dos aliados e não envia ordens diretas** (R2-Q4, que substitui a parte de D-004 referente a ordens). Os inimigos também participam da economia individual de ATB, das recompensas por desempenho e das regras aplicáveis de evasão/Burst.

**APROVADO (R6-Q3 = A):** cada equipe ativa de aliados em combate possui **até 3 Pokémon**, incluindo **um protagonista controlado diretamente pelo jogador** e **até 2 companheiros controlados pela IA**. Isso não define a composição ou a quantidade de equipes inimigas, nem recrutamento e reservas.

**APROVADO (R7-Q4 = A):** cada batalha pode ter **até 3 Pokémon inimigos ativos simultaneamente**, assim como o limite de três Pokémon ativos na equipe do protagonista. Essa regra não define inimigos de reserva, substituições, reforços ou ondas de inimigos.

**APROVADO (R7-Q5 = A):** os mapas da exploração **2D são gerados proceduralmente por exploração/andar**, com **salas e corredores** como base de organização. Algoritmo, regras de geração, dimensão, seed, diversidade, persistência ao revisitar andares e critérios de progressão seguem pendentes; não presumir mapa fixo e desenhado manualmente como padrão.

**APROVADO (R8-Q3 = A):** a geração procedural utiliza **seed registrável/reutilizável** que permita reproduzir o **mesmo layout de dungeon** quando a seed, as regras e a versão do gerador forem as mesmas. Isso não define ainda a interface para consultar/inserir seeds nem a persistência de eventos ou inimigos.

**APROVADO (R8-Q4 = A):** **salas, corredores, suas formas, posições e conexões são construídos algoritmicamente**, em vez de exigir salas pré-desenhadas como módulos autorais. Os algoritmos e parâmetros exatos ainda não foram escolhidos.

**APROVADO (R8-Q5 = A):** os **Pokémon inimigos estão visíveis na exploração 2D**, e o **contato/colisão com um inimigo no mapa inicia o combate 3D**. Não presumir encontros aleatórios invisíveis, trajetória de patrulha ou raio de detecção sem aprovação.

**APROVADO (R9-Q2 = A):** ao **revisitar um andar na mesma exploração**, o **layout procedural gerado desse andar permanece inalterado**: salas, corredores e conexões não são regenerados só porque o jogador voltou. **PENDENTE:** estado de itens, inimigos e eventos quando o andar é revisitado; esta regra preserva o layout, não restaura automaticamente seu estado.

**APROVADO (R9-Q3 = A):** Pokémon inimigos **visíveis no mapa 2D patrulham** durante a exploração e **perseguem o protagonista após detectá-lo**. Critérios e distância de detecção, velocidades, rotas e desengajamento continuam pendentes. O encontro segue sendo iniciado por contato, não por mera detecção.

**APROVADO (R9-Q4 = A):** o **Pokémon inimigo visível derrotado em combate é removido do andar durante a exploração atual** e **não reaparece nesse andar nessa exploração**, ressalvados eventos especiais ainda não especificados. A remoção deve continuar valendo caso o jogador revisite esse andar na mesma exploração; isso não define outros encontros, spawns ou o comportamento ao iniciar outra exploração.

**APROVADO (R9-Q5 = B):** o protagonista se movimenta na exploração 2D em **quatro direções cardeais** (cima, baixo, esquerda, direita), **sem movimento diagonal direto**.

**APROVADO (R23-Q1 = A):** movimentação **contínua e livre nas quatro direções cardeais** da exploração 2D, sem diagonais diretas e sem deslocamento obrigatório por tiles/turnos.

**APROVADO (R23-Q2 = A):** uma dungeon é **concluída após chegar ao último andar e vencer um chefe**. Quantidade de andares, passagens e recompensas pendentes.

**APROVADO (R24-Q1 = A):** **avançar de andar ao encontrar escada ou saída no mapa**, sem precisar derrotar todos os inimigos. Permanece obrigatório chegar ao último andar e vencer o chefe para concluir a dungeon. Detalhes das passagens pendentes.

**APROVADO (R25-Q1 = A):** a progressão geral do jogo segue uma **campanha que desbloqueia novas dungeons conforme conquistas e objetivos**. **PENDENTE:** roteiro, requisitos concretos de desbloqueio, ordenação e possibilidade de revisitar dungeons. Cada dungeon ainda exige chegar ao último andar e derrotar seu chefe para ser concluída.

**APROVADO (R23-Q3 = A):** **derrota definitiva em batalha encerra a exploração atual**. Consequências sobre Pokémon, inventário e progresso seguem pendentes; não presumir perda permanente.

**APROVADO (R23-Q4 = B):** **Pokémon podem ser recrutados durante a exploração 2D por interações ou aproximação**. O contato com Pokémon **inimigos visíveis** continua iniciando combate 3D (R8-Q5). **PENDENTE:** diferenciar interações de recrutamento e encontros hostis, condições e reservas; não presumir recrutamento automático de inimigos por aproximação.

**APROVADO (R24-Q2 = A):** o **recrutamento de Pokémon elegível exige interação voluntária explícita do jogador**, não acontecendo automaticamente por simples aproximação. Contato com inimigo hostil continua iniciando combate 3D. Elegibilidade e condições permanecem pendentes.

**APROVADO (R24-Q3 = A):** **é possível recrutar mesmo com três Pokémon ativos, enviando o novo Pokémon para uma reserva**. Capacidade, gestão e trocas permanecem pendentes.

**APROVADO (R25-Q2 = C, resposta provisória “A po ora, vou criar um hub pra isso depois masmais tarde”):** o criador indicou **A por ora**: **permitir provisoriamente alternar Pokémon entre a equipe ativa e a reserva durante a exploração**, preservando o máximo de três ativos. **O hub é uma intenção de projeto para momento posterior**, não funcionalidade já implementada nem regra definida sobre o local definitivo das trocas. **PENDENTE:** design do hub, regras definitivas de acesso à reserva, limites e momentos de troca. Não presumir que o hub será obrigatório para trocar de equipe.

**APROVADO (R24-Q5 = A):** **Pokémon recrutados na expedição continuam pertencendo ao jogador após derrota definitiva**. Destino na equipe/reserva e perdas de itens/progresso pendentes.

**APROVADO (R25-Q4 = C, “apenas itens que estao sendo segurados nao sao perdidos”):** na **derrota definitiva de uma expedição**, entre os **itens obtidos durante aquela expedição**, **somente os itens que estiverem sendo segurados não são perdidos; os demais itens obtidos na expedição são perdidos**. **PENDENTE:** definição operacional de “segurando” e quais Pokémon/personagens podem segurar itens, regras para itens trazidos de antes da expedição e outras consequências. Não confundir essa regra de itens com o pertencimento preservado dos Pokémon recrutados (R24-Q5).

**APROVADO (R23-Q5 = C):** resposta literal **“combinacao com mestres e possiveis personagens que dao hms”**. O sistema de aprendizado de Moves admite **fontes combinadas, incluindo mestres e possíveis personagens que concedem HMs**. **APROVADO posteriormente (R24-Q4 = C):** HMs e TMs são **somente para combate por enquanto**, sem funções de exploração. **PENDENTE:** demais fontes, obtenção, requisitos, relação de HMs/TMs com os quatro Moves equipados e seus slots. Não presumir custos.

**APROVADO (R25-Q3 = A):** quando um Pokémon **satisfizer os requisitos para sua evolução de espécie**, **o jogador poderá escolher quando efetuar a evolução**, em vez de ela ocorrer obrigatoriamente de forma automática assim que o requisito for atingido. **PENDENTE:** requisitos por espécie, interface, possíveis restrições e efeitos de evolução; não confundir com subida de nível ou distribuição de atributos.

**APROVADO (R26-Q1 = A) — protagonista inicial:** o jogador **escolhe seu Pokémon protagonista entre espécies iniciais disponíveis**. **PENDENTE:** quais espécies compõem o catálogo, interface de escolha e demais aspectos da apresentação. A escolha da espécie **não substitui nem altera** as regras já aprovadas de sorteio da Nature do protagonista.

**APROVADO (R26-Q2 = B) — candidatos especiais ao recrutamento:** **Pokémon normalmente hostis podem aparecer em situações especiais como candidatos a recrutamento, identificados no mapa da exploração 2D**. O candidato elegível ainda exige **interação voluntária explícita** (R24-Q2). **Encontros hostis normais continuam iniciando combate 3D por contato** (R8-Q5). **PENDENTE:** natureza da identificação visual, eventos/requisitos para aparecer como candidato e condições concretas para recrutamento. Não inferir recrutamento automático nem que todo inimigo possa ser recrutado em qualquer encontro.

**APROVADO (R26-Q3 = A) — experiência de batalha:** **todos os Pokémon ativos que participarem de uma batalha vencida recebem experiência, independentemente de aplicar o golpe final**. **PENDENTE:** quantidades, divisão de experiência, tratamento de Pokémon que ficaram na reserva, situações com membros incapacitados e demais condições especiais. A evolução por nível, a distribuição manual de pontos do protagonista e o crescimento automático de aliados permanecem inalterados.

**APROVADO (R26-Q4 = A) — depois do chefe:** **ao vencer o chefe do último andar, a dungeon é concluída, a expedição se encerra e o jogador retorna à seleção/progressão da campanha**. **PENDENTE:** recompensas, apresentação de resultados e critérios dos novos desbloqueios. Esse retorno não cria nem exige um hub implementado; a intenção de hub futuro de R25-Q2 permanece pendente.

**APROVADO (R26-Q5 = A) — salas secretas:** as **salas secretas das dungeons são descobertas opcionais voltadas a recompensas, eventos e NPCs especiais**, **sem obrigatoriedade de encontrá-las para alcançar o chefe**. **PENDENTE:** conteúdo concreto, como descobrir/acessar as salas e distribuição procedural. A prioridade dada a salas secretas em R25-Q5 permanece válida.

**APROVADO (R27-Q1 = A) — fuga de combates comuns:** o jogador **pode tentar fugir de combates comuns**, com **condições, consequências e restrições ainda pendentes**; o tratamento de combates contra chefes não está definido. A possibilidade de tentar não equivale a fuga garantida. Não presumir custo ATB/Burst, chance de sucesso ou novo comando de interface sem decisão adicional.

**APROVADO (R27-Q2 = A) — equipe inicial:** **a aventura começa somente com o Pokémon protagonista escolhido pelo jogador**, sem companheiros iniciais; o jogador **forma sua equipe mediante recrutamento** durante a aventura. Preservar equipe ativa máxima de três Pokémon (protagonista e até dois aliados IA) e regras de reserva.

**APROVADO (R27-Q3 = B) — ambientes das dungeons:** **uma mesma dungeon pode conter ambientes mistos e mudar de tema ao longo de uma expedição**. **PENDENTE:** quais biomas/temas existem, como ocorrem as mudanças, sua influência na geração e no gameplay. Esta decisão não exige que toda dungeon sempre mude de bioma e não altera a geração procedural aprovada.

**APROVADO (R27-Q4 = A) — aprendizado de Moves comuns:** **o nível e a progressão do Pokémon são a fonte principal de novos Moves comuns**, **sem excluir mestres, HMs/TMs de combate e outros meios anteriormente aprovados**. **PENDENTE:** listas por espécie, requisitos, ritmo e seleção/aprendizado de novos Moves; continuam quatro Moves equipados mais Tackle genérico e ausência de PP.

**APROVADO (R27-Q5 = C) — recompensas de batalha:** resposta literal **“moedas recursos itens”**. **Moedas, recursos e itens** são **tipos de recompensas materiais previstas para batalhas comuns**, além da experiência já aprovada (R26-Q3). **PENDENTE:** se cada vitória sempre oferece recompensa, quais combinações são possíveis, taxas, valores, origem, uso de moedas/recursos e destino no inventário. Não inferir três recompensas garantidas em toda batalha nem taxas ou economia concreta.

**APROVADO (R28-Q1 = A) — moedas e comércio:** **moedas são usadas principalmente para comprar itens e recursos de NPCs ou lojas**. **PENDENTE:** NPCs/lojas disponíveis, locais, catálogo, preços e outros usos possíveis. Não definir moeda específica nem preços.

**APROVADO (R28-Q2 = C) — itens segurados:** resposta literal **“alguns funcionarao passivament e alguns funcionarao automaticamente sendo consumidos como berries”**. **Alguns itens segurados produzem efeitos passivos e outros são ativados automaticamente e consumidos quando cabível, como berries**, com os gatilhos e efeitos concretos ainda pendentes. Não concluir que todos os itens segurados são consumíveis ou que toda berry possui um efeito específico. A preservação de itens ainda segurados após derrota definitiva (R25-Q4) permanece válida.

**APROVADO (R28-Q3 = C) — retorno após fuga bem-sucedida:** resposta literal **“retorna ao local de encontro e stunna o inimigo por um tempo, nao pemitindo que ele se mova e encoste em vc por 3 segundos”**. Ao **fugir com sucesso de um combate comum**, o jogador **retorna ao local do encontro na exploração 2D**, e **o inimigo daquele encontro permanece imobilizado e impedido de se mover ou encostar no jogador por três segundos**. **PENDENTE:** condições para conseguir fugir, forma de solicitar a tentativa, consequências da falha e tratamento de chefes. Não estabelecer cooldown, imunidade global, distância de teleporte, custos ATB/Burst nem efeitos sobre outros inimigos.

**APROVADO (R28-Q4 = A) — biomas e conteúdo:** as **mudanças de bioma/tema dentro de uma dungeon podem alterar os tipos de inimigos, eventos e recompensas encontrados**. **PENDENTE:** catálogos por bioma, distribuição e regras concretas de transição. Não presumir mudança obrigatória de cada tipo de conteúdo em toda transição.

**APROVADO (R28-Q5 = A) — recompensa principal da dungeon:** a **conclusão de uma dungeon prioriza avanço da campanha e desbloqueio de novas dungeons**, enquanto **recompensas materiais adicionais são opcionais e permanecem pendentes**. A conclusão ainda exige alcançar o último andar e vencer o chefe, encerrando a expedição e retornando à progressão da campanha (R23-Q2/R26-Q4). Não presumir recompensa material garantida.

**APROVADO (R29-Q1 = C) — comércio em ambos os locais:** resposta literal **“ambos”**. **NPCs comerciantes e lojas podem ser encontrados dentro das dungeons, durante a exploração, e fora das expedições, na seleção/progressão da campanha.** **PENDENTE:** localização, vendedores, catálogo, preços e acesso. Não tornar obrigatório o hub futuro de R25-Q2.

**APROVADO (R29-Q2 = A) — eventos narrativos:** **eventos especiais oferecem escolhas e situações narrativas com consequências para a exploração**. **PENDENTE:** eventos, escolhas e efeitos concretos; não presumir persistência das consequências entre expedições.

**APROVADO (R29-Q3 = A) — rejogar dungeons:** **novas expedições podem ocorrer em dungeons já concluídas**, com recompensas ainda pendentes. Mantêm-se a **geração procedural por exploração/andar** (R7-Q5), o **layout persistente ao revisitar andares na mesma exploração** (R9-Q2) e a **reprodutibilidade pela mesma seed, regras e versão do gerador** (R8-Q3). Não exigir layout inédito quando a mesma seed for reutilizada.

**APROVADO (R29-Q4 = A) — chefes acompanhados:** **um chefe principal pode ter apoio de outros inimigos**, sem exceder **três inimigos ativos simultaneamente por combate** (R7-Q4). **PENDENTE:** composição do encontro, apoios e mecânicas de chefes. O chefe não precisa ter aliados em toda batalha.

**APROVADO (R29-Q5 = A) — dificuldade:** **aumentar progressivamente o desafio nos andares mais avançados e nas novas dungeons desbloqueadas na campanha**. **PENDENTE:** tipos de desafio, variação por bioma, níveis, curvas e números; sem definir fórmulas ou valores.

**APROVADO (R30-Q1 = A) — retirada voluntária:** o jogador **pode retirar-se voluntariamente da dungeon antes de derrotar o chefe e retornar à campanha**. **PENDENTE:** interface/local da retirada, consequências sobre itens, progresso, Pokémon e a expedição. A retirada **não é equiparada automaticamente a derrota definitiva** (R23-Q3) nem a fuga de combate (R27-Q1).

**APROVADO (R30-Q2 = A) — alcance de eventos:** as **consequências das escolhas em eventos narrativos ficam principalmente na expedição atual, sem persistência obrigatória entre dungeons**. Eventos continuam oferecendo escolhas e situações narrativas (R29-Q2). Não proibir expressamente exceções futuras, mas não criar persistência de campanha como requisito.

**APROVADO (R30-Q3 = B) — identidade de chefes:** **chefes são principalmente inimigos mais difíceis dentro das regras usuais do combate**, **sem obrigatoriedade de fases ou mecânicas exclusivas**. O chefe principal **pode continuar acompanhado de outros inimigos** (R29-Q4), respeitando três inimigos ativos no máximo. Isso não proíbe conteúdo especial aprovado futuramente; não fixar fases ou padrões exclusivos agora.

**APROVADO (R30-Q4 = A) — recompensas de novas expedições:** **rejogar dungeons já concluídas continua oferecendo oportunidades de obter Pokémon, itens e recursos**, com catálogo, elegibilidade, quantidades e condições pendentes. Não garantir cada recompensa em toda visita e não alterar a geração procedural nem os desbloqueios da campanha.

**APROVADO (R30-Q5 = A) — entrada imediata de recrutados:** **quando houver vaga na equipe ativa, Pokémon recém-recrutados podem entrar diretamente nela após o recrutamento bem-sucedido**, respeitando o limite de **três Pokémon ativos**. Não impor entrada automática sem escolha do jogador nem definir interface. Se a equipe estiver completa, o novo recrutado pode ir à reserva (R24-Q3); as trocas durante a expedição seguem provisórias (R25-Q2).

**APROVADO (R31-Q1 = B) — itens na retirada voluntária:** **ao abandonar voluntariamente a dungeon, os itens coletados nessa expedição que não estiverem sendo segurados são perdidos; os itens segurados são mantidos**, assim como a regra já aprovada para itens adquiridos na expedição encerrada por derrota definitiva (R25-Q4). Essa equivalência se refere **somente ao tratamento desses itens**, não a outras consequências de retirada/derrota. **PENDENTE:** tratamento de itens trazidos antes da expedição, definição exata de “segurado” e destino de outros recursos.

**APROVADO (R31-Q2 = A) — protagonista incapacitado em combate:** **se o protagonista cair durante uma batalha 3D, os aliados ainda capazes de combater continuam a batalha sob controle da IA**. **R32-Q1 = A aprovou posteriormente:** se os aliados vencerem, o protagonista **pode retornar à exploração mediante recuperação mínima**, com condições e quantidade pendentes. A queda do protagonista não equivale automaticamente à derrota definitiva (R23-Q3); não atribuir controle manual dos aliados nem recuperação completa automática.

**APROVADO (R31-Q3 = B) — experiência de vitória e reserva:** **a experiência das vitórias de combate é restrita aos Pokémon ativos participantes** (R26-Q3). **Pokémon na reserva não recebem essa experiência por estarem reservados**; sua progressão por outros meios fica a definir. Não fixar XP, curvas ou meios específicos de treinamento.

**APROVADO (R31-Q4 = A) — apresentação dos objetivos da campanha:** **objetivos e missões que orientam o desbloqueio de novas dungeons são apresentados principalmente por personagens, NPCs e acontecimentos narrativos**. **PENDENTE:** missões, personagens e requisitos concretos de desbloqueio. Não proibir que a interface também mostre o progresso; não presumir um hub implementado.

**APROVADO (R31-Q5 = A) — pontos de descanso seguros:** **pontos de descanso dentro das dungeons são locais seguros de pausa e preparação da equipe**, com serviços adicionais pendentes. A **restauração completa de MP nesses pontos permanece aprovada** (R14-Q2/R15). **R32-Q2 = A aprovou posteriormente a recuperação de HP nesses pontos**, com quantidade e regras específicas pendentes. **PENDENTE:** acesso, localização, proteção concreta contra ameaças e serviços adicionais. Não inferir restauração completa de HP, trocas de equipe nem outras funções.

**APROVADO (R32-Q1 = A) — protagonista após vitória dos aliados:** **se os aliados vencerem o combate após a queda do protagonista, ele poderá voltar à exploração mediante recuperação mínima**. **PENDENTE:** qual recuperação, quando acontece e condições de retorno. Não presumir valor de HP ou cura completa nem encerrar uma batalha automaticamente quando o protagonista cai.

**APROVADO (R32-Q2 = A) — HP no descanso:** **pontos seguros de descanso recuperam HP além de restaurar MP**. A restauração de MP continua **completa** pelas regras anteriores; a quantidade e os critérios de recuperação de **HP ficam pendentes**. Não equiparar automaticamente a cura de HP à restauração integral de MP.

**APROVADO (R32-Q3 = A) — persistência de progressão:** **XP e níveis conquistados durante a expedição são preservados após derrota definitiva ou retirada voluntária**, mesmo sem vitória contra o chefe. Mantêm-se independentemente as perdas dos **itens coletados não segurados** nesses dois desfechos (R25-Q4/R31-Q1). Não generalizar preservação para todas as moedas, materiais e demais recursos sem decisão.

**APROVADO (R32-Q4 = A) — descoberta do mapa:** **o mapa de cada andar é revelado progressivamente conforme o jogador explora**, com áreas ainda não percorridas permanecendo desconhecidas na apresentação do mapa. **PENDENTE:** meio de consulta/visualização, grau exato de revelação e persistência das áreas descobertas após nova expedição. A seed reproduzível e o layout estável ao revisitar um andar da mesma exploração permanecem válidos.

**APROVADO (R32-Q5 = B) — recrutamento especial por evento:** **interagir voluntariamente com um Pokémon especial elegível inicia uma tarefa ou evento que deve ser resolvido antes de efetivar seu recrutamento**. **PENDENTE:** natureza das tarefas, requisitos, desfechos e condições de elegibilidade. Isso não transforma encontros hostis comuns em recrutamentos nem elimina as regras de composição da equipe/reserva; não estender obrigatoriamente essa tarefa a toda forma de recrutamento.







 **APROVADO posteriormente (R23-Q1 = A):** movimento contínuo e livre nas quatro direções cardeais, sem movimento diagonal direto. **PENDENTE:** controles, colisão e animação.

**PENDENTE:** sprites 2D, geração procedural, seeds, passagens, detecção/patrulha e estados em revisitas; espécies iniciais, **tarefas/eventos concretos de recrutamento especial** (R32-Q5), reservas/hub futuro, evolução e XP numérico, treinamento dos reservados, inventário/itens segurados, outras perdas de derrota/retirada sem revogar **preservação de XP e níveis** (R32-Q3), **regras da recuperação mínima do protagonista após vitória dos aliados** (R32-Q1), arenas, transições, objetivos e narrativa, fuga, biomas, Moves, lojas e recompensas, chefes, **quantidade/condições de cura de HP nos pontos seguros de descanso** (R32-Q2), apresentação e persistência de áreas descobertas no **mapa revelado progressivamente** (R32-Q4), serviços adicionais de descanso e interface de recrutamento. Não presumir resolvidas essas pendências.

### Fluxo de experiência (somente encadeamento conceitual)

Explorar uma dungeon 2D em movimentação cardinal contínua → encontrar adversário → combater em 3D com ATB → retornar à exploração quando permitido ou encerrar em derrota definitiva → alcançar último andar e derrotar chefe para concluir a dungeon. Fuga e demais consequências pendentes.

**IMPLEMENTADO/OBSERVADO:** já existe uma transição básica 2D/3D no protótipo. Isso não confirma que o fluxo completo acima, inclusive fuga, recursos e consequências, esteja implementado.

## 2. Interface de batalha — quatro comandos (APROVADO)

| Comando | Intenção e comportamento aprovado | O que permanece indefinido |
| --- | --- | --- |
| **1 — FIGHT** | Apresenta **Tackle como ataque físico genérico** e **quatro Moves** equipados. Tackle não ocupa um dos quatro espaços de Move e **custa 2 blocos ATB** (R4-Q4). Os **quatro Moves têm custo-base 2 ATB**, com exceções por Move, incluindo ataques de custo 5 ou com requisito Burst (R6-Q5). **Os quatro Moves não usam PP** (R7-Q3). **Moves mágicos/especiais consomem MP adicional** aos recursos ATB/Burst aplicáveis (R12-Q1). | Potência, precisão, custo ATB das exceções e custo MP de cada Move mágico/especial, seleção de alvo e disponibilidade por espécie. **Não há PP no Crawlmon** (R8-Q2). |
| **2 — ITENS** | Acessa e permite usar consumíveis em batalha; **cada utilização de item custa 1 bloco ATB** (R6-Q2 = C: “1”). A navegação em ITENS **não pausa o combate**. | Catálogo de itens, alvos, efeitos, inventário e instante preciso de cobrança ainda não definidos. |
| **3 — Tactic** | **Orienta somente a IA dos aliados**, sem ordens diretas (R2-Q4) e **sem custo ATB** (R3-Q3). As orientações persistem entre encontros da dungeon (R5-Q5). **Nas configurações, o jogador escolhe** entre reiniciar as orientações ao encerrar a dungeon ou preservá-las entre dungeons (R6-Q4); a opção **padrão é reiniciar** (R7-Q1). | A orientação de IA padrão, detalhes da interface e salvamento da preferência ainda não definidos. |
| **4 — Evade** | Ação ativa e reativa de esquiva durante ataques; seus **3 blocos de ATB são descontados na ativação**, tanto em sucesso quanto em falha (R4-Q3). | Janela temporal, interface física/botão de reação, elegibilidade por alvo, animações e interações com golpes múltiplos/em área. |

**APROVADO:** todas as ações consomem blocos; a maioria custa **2**, o Evade custa **3**, determinados golpes fortes custam **todos os 5**, e alguns ataques também **exigem Burst**.

**APROVADO (R2-Q3 = B):** um **Move executado mediante Burst** consome **o bloco especial Burst e também os blocos normais de ATB correspondentes ao custo do Move**. Ter o bloco Burst não isenta desse custo; o Move depende de saldo normal suficiente.

**APROVADO (R3-Q3 = A):** **Tactic não consome ATB**. Ajustar a orientação da IA é uma configuração de interface, **não** uma ação de combate cobrada; essa é uma exceção explícita à regra geral de consumo de blocos por ações.

**APROVADO (R4-Q4 = A + R8-Q2 = C):** **Tackle físico genérico custa 2 blocos ATB, sem PP**, permanecendo fora dos quatro espaços de Move. Potência e precisão ainda não definidas.

**APROVADO (R5-Q4 = B):** **buff/debuff via Burst consome apenas um bloco Burst, sem custo de ATB normal ou extra**. Em contraste, **Moves ofensivos via Burst continuam custando 1 Burst + o custo ATB próprio do Move** (R2-Q3).

**APROVADO (R6-Q2 = C: “1”):** **cada utilização de item em batalha custa 1 bloco ATB**, independentemente do tipo de consumível; não confundir com apenas abrir/navegar pelo menu ITENS. A escolha pelo menu não pausa a batalha (R1-Q3). O momento exato do desconto, efeitos e restrições por item seguem pendentes.

**APROVADO (R6-Q5 = A):** os **quatro Moves equipados usam custo-base de 2 ATB**. Há **exceções específicas por Move**, inclusive ataques fortes com custo de 5 blocos e Moves que requerem Burst, cuja identificação e custos devem ser documentados por Move. Se um Move for executado via Burst, preserva-se a exigência já aprovada de **1 Burst + custo ATB desse Move** (R2-Q3); não determinar silenciosamente o custo de uma exceção.

**APROVADO (R7-Q3 = B; esclarecido por R8-Q2 = C):** **Crawlmon não utiliza PP como recurso de combate**: os **quatro Moves equipados e o Tackle genérico não têm PP**, e tampouco se deve acrescentar um medidor ou custo de PP às ações do sistema. Os custos dos Moves e de Tackle são em **ATB** e, quando cabível, **Burst**. A antiga dúvida sobre PP de Tackle está **encerrada** por R8-Q2. Não propor PP novamente como pendência.

**APROVADO (R12-Q1 = A):** **todos os Moves de categoria mágica/especial consomem MP**, além de seus custos de **ATB e Burst, quando aplicáveis**. **R13-Q1 = A aprovou posteriormente custo-base comum de MP, com exceções por Move**. Os números do custo-base e das exceções permanecem pendentes. Esta decisão **não** dispensa os custos já aprovados, **não** cria PP e não determina o consumo de MP por Moves de outras categorias.

**PENDENTE:** custo e propriedades das **exceções individuais de Move**, **valor do custo-base comum de MP e exceções individuais por Move**, detalhes do catálogo de itens, momento de cobrança dos consumíveis e efeitos concretos de buffs/debuffs. **Já aprovados:** Tackle (2 ATB), Moves equipados (2 ATB salvo exceções), ITENS (1 ATB por uso), Evade (3 ATB), Tactic (0), custos de Burst e **MP adicional nos Moves mágicos/especiais**. Não criar PP nem alterar ATB/Burst.

## 3. Sistema ATB — especificação aprovada

### 3.1 Capacidade, tempo e elegibilidade

- **APROVADO:** cada Pokémon possui sua **própria barra com capacidade de cinco blocos normais** (0–5).
- **APROVADO:** os blocos se preenchem **com a passagem do tempo**.
- **APROVADO (R6-Q1 = A):** **todos os Pokémon começam cada batalha com 0/5 blocos normais de ATB**, sem vantagem inicial baseada em Velocidade; a Velocidade afeta o **preenchimento temporal posterior**, conforme R2-Q5. Essa regra vale para protagonista, aliados e inimigos. Bursts e blocos ATB extras não são transferidos da batalha anterior, conforme R2-Q1 e R5-Q1.
- **APROVADO (R2-Q5 = A):** a **taxa de preenchimento natural** do ATB é influenciada pelo atributo **Velocidade individual de cada Pokémon**. As recompensas por ações continuam acréscimos instantâneos de blocos, sem alterar por si a taxa temporal.
- **APROVADO (R7-Q2 = A):** um Pokémon com a **Velocidade de referência** leva **5 segundos para preencher naturalmente a barra de 0/5 até 5/5**. Isso equivale a uma média de **1 bloco por segundo na Velocidade de referência**, sem definir a curva, os marcos de arredondamento, o valor numérico de Velocidade de referência nem a fórmula de escala para outras Velocidades. Continuam válidas a pausa exclusiva da escolha de Tactic e a restrição de que o tempo não gere blocos extras.
- **APROVADO (R8-Q1 = A):** o **tempo de preenchimento natural é inversamente proporcional à Velocidade**: dobrar a Velocidade reduz o tempo em 50% e reduzir a Velocidade à metade dobra o tempo, a partir da Velocidade de referência. **DERIVADO, somente para Velocidade positiva:** \(T(V) = 5\,\mathrm{s} \times V_{ref}/V\), sendo \(V_{ref}\) o atributo de referência ainda a definir. **PENDENTE:** valor numérico de \(V_{ref}\), limites mínimo/máximo de taxa, tratamento de Velocidade zero/não positiva e arredondamento; nenhuma dessas escolhas é presumida.
- **REGISTRADO (R9-Q1 = C; R10-Q1/Q2/Q5):** o criador adiou o **valor numérico da Velocidade de referência** até definir os atributos. Na Rodada 10 aprovou **atributos inspirados em SMT III: Nocturne**, **escala-base 1–100** e **referência numérica fixa comum** a determinar posteriormente; **nenhum valor foi escolhido**. A associação do atributo **Agilidade** de SMT3 com a **Velocidade** prevista no ATB foi **resolvida em R11-Q1 = A**: trata-se de um único atributo. A **nomenclatura apresentada ao jogador** permanece pendente. Permanecem aprovados o preenchimento em 5 segundos na referência e a proporcionalidade inversa à Velocidade.
- **APROVADO (Opção A):** um Pokémon pode realizar uma ação **assim que tiver os blocos necessários para pagar seu custo**, sem precisar esperar completar 5/5. A antiga hipótese de só agir ao chegar a 5/5 está **superada** por esta decisão posterior.
- **APROVADO:** custo usual de muitas ações = 2 blocos; Evade ativo = 3; certos ataques fortes = 5.
- **DERIVADO:** se não houver autorização especial para dívida ou custo alternativo, um custo de 3 exige saldo de pelo menos 3. Exceções, caso desejadas, exigem aprovação.
- **APROVADO (R1-Q2 = A):** a execução de uma ação desconta **apenas o custo em blocos**, preservando o saldo restante. Exemplo: 5/5, ação de custo 2, saldo final 3/5 (antes de possíveis recompensas e preenchimento temporal).
- **APROVADO (R1-Q3 = C):** o combate **só pausa durante a escolha dos comandos de Tactic**. Ao escolher comandos de FIGHT e ITENS, o tempo não pausa e as barras ATB continuam seu preenchimento temporal. A pausa aplica-se apenas à escolha das orientações de IA em Tactic, **que não envia ordens diretas**. **PENDENTE:** detalhes técnicos de interrupção/retomada e ações simultâneas; não inventar pausas extras.
- **APROVADO (R17-Q5 = A):** o **contador de MP pausa durante a seleção de Tactic** e **retoma após a pausa se permanecerem MP faltante e ATB 5/5**. Se o MP atingir o máximo ou ATB sair de 5/5, continuam os resets já aprovados. Não pausar FIGHT ou ITENS.
- **PENDENTE:** valor **numérico fixo** de referência para o ATB (R10-Q5), **nomenclatura visual do atributo único Agilidade/Velocidade** (R11-Q1), limites/condições de borda da proporcionalidade inversa, arredondamento visual, tratamento de ações simultâneas e layout para muitos blocos extras. A prioridade de consumo (R3-Q2) e quadradinhos adicionais (R4-Q2) já estão aprovados.

### 3.2 Recompensas instantâneas

- **APROVADO:** acertar **fraqueza**, causar **dano crítico** ou **desviar de um ataque** são eventos que podem conceder **1 ou 2 blocos normais de ATB de imediato**.
- **APROVADO:** o bônus é **individual**. Apenas o Pokémon responsável pelo acerto ou pela esquiva recebe os blocos. Isso inclui aliados e inimigos.
- **APROVADO:** recompensas não aumentam a taxa de preenchimento; são **acréscimos instantâneos de blocos**.
- **APROVADO (R1-Q4):** valores específicos e individuais:

| Evento recompensado | Blocos ATB normais recebidos imediatamente |
| --- | ---: |
| Golpe que explora fraqueza | **+1** |
| Acerto crítico normal (fora do crítico garantido de Burst) | **+2** |
| Evasão automática bem-sucedida | **+2** |
| Evade ativo bem-sucedido | **+1** |

- **APROVADO (R1-Q5 = A):** se um **mesmo golpe** for ao mesmo tempo **crítico normal e super efetivo**, as duas recompensas **se somam**: **+2 por crítico +1 por fraqueza = +3 blocos**, sujeitos ao tratamento de capacidade/excedente ainda pendente.
- **APROVADO (R2-Q2 = C):** quando recompensas ultrapassam a capacidade dos **cinco blocos normais**, o Pokémon **conserva os blocos excedentes como blocos extras de ATB**, distintos do bloco Burst. Esses blocos **não ocupam os cinco espaços normais** e **podem ser utilizados para realizar mais ações**. Não descartá-los nem convertê-los em Burst.
- **Exemplo derivado, não regra de interface:** um Pokémon com 4/5 que ganha +3 (crítico normal e fraqueza) passa a contar com cinco blocos normais e **dois extras**. O modelo de quadradinhos adicionais foi aprovado em R4-Q2; seus detalhes gráficos continuam pendentes.
- **APROVADO (R3-Q2 = A):** ao pagar o custo de uma ação, são **consumidos primeiro os blocos ATB extras**; se os extras não forem suficientes, desconta-se o restante dos cinco blocos normais. Exemplo: 4 normais +2 extras, ação de custo 2 → **4 normais +0 extras**. Os extras não são Burst.
- **APROVADO (R3-Q4 = A):** o preenchimento natural baseado no tempo e na Velocidade **para ao atingir cinco blocos normais**; **somente recompensas por ações** (fraqueza, crítico normal, esquivas elegíveis) podem gerar blocos ATB extras. A regeneração temporal não gera extras, mesmo quando a barra normal está completa.
- **APROVADO (R14-Q2 = C; R15-Q1/Q2 = A; R16-Q1 = B e R16-Q2 = A):** cada Pokémon com **ATB normal 5/5** recupera **25% do MP máximo a cada 3 segundos consecutivos, arredondado para baixo**, sem exceder MP máximo. Ao sair de 5/5, o contador zera. **Enquanto MP estiver no máximo, o contador permanece zerado**; com MP faltante e ATB ainda em 5/5, inicia-se novo intervalo integral de três segundos. **PENDENTE:** efeito da pausa Tactic e aplicação fora de combate. Não gerar ATB extra ou alterar custos ATB/Burst. Pontos de descanso continuam restaurando MP completamente.

**Exemplo de valores aprovados:** com 2/5, um crítico normal concede +2 e eleva a barra para 4/5. Se o mesmo golpe também explorar fraqueza, o ganho total é +3, e um saldo inicial de 2/5 alcança 5/5.

### 3.3 Separação de Press Turn

**APROVADO como direção atual:** a economia de ações é a dos blocos individuais de ATB; referências a fraquezas e críticos de *SMT III* inspiram as decisões táticas, mas **não há sistema aprovado de ícones coletivos Press Turn, meias ações ou alternância rígida de fases da equipe**.

## 4. Evasão ativa, evasão automática e precisão (APROVADO)

Há dois mecanismos distintos. Um acerto evitado passivamente não se confunde com a ação reativa **Evade**.

| Situação | Custo conhecido | Resultado de acerto/evasão | Recompensa ATB | Burst |
| --- | --- | --- | --- | --- |
| **Evasão automática bem-sucedida** | Não foi definido custo de ação; é uma ocorrência passiva. | O golpe é evitado. | **+2**, individual. | **Nunca**. |
| **Evade ativo bem-sucedido** | **3 blocos ATB descontados na ativação** (extras primeiro). | O golpe é evitado. | **+1**, individual. | **Sim, disponibilidade imediata (pode usar ou armazenar)**. |
| **Evade ativo malsucedido** | **3 blocos ATB descontados na ativação** (extras primeiro). | **O golpe acerta obrigatoriamente**, ignorando a precisão natural e impedindo a evasão automática *para esse ataque*. | Nenhum bônus por Evade. | Não. |
| **Sem evasão bem-sucedida** | Conforme regras da ação aplicável. | Resolução normal da mecânica de ataque. | Nenhum bônus por esquiva. | Não. |

**Exceção aprovada:** acerto garantido após Evade malsucedido **não ignora imunidades nem outras proteções aplicáveis**. O acerto garantido não é sinônimo de dano garantido.

**APROVADO (R4-Q3 = A):** os **3 blocos de custo do Evade ativo são descontados na ativação/tentativa**, sem depender do sucesso. Ao pagar, usar **blocos ATB extras antes dos normais** (R3-Q2). **APROVADO (R4-Q5 = A):** a IA dos aliados **decide automaticamente tentar Evade ativo** com base no contexto do ataque e ATB disponível, podendo ter sua prioridade influenciada pelas orientações de Tactic, sem receber ordens diretas.

**APROVADO:** as regras de evasão e as oportunidades de Burst alcançam tanto personagens aliados quanto inimigos. Para aliados controlados pela IA, **a decisão de realizar Evade ativo** é distinta do cálculo de evasão automática.

**PENDENTE:** critérios e pesos exatos da IA ao considerar Evade; como o jogo apresenta a janela de reação; quais ataques podem ser desviados; como se resolve a simultaneidade com invulnerabilidade, proteção, imunidades, multi-hit e ataques em área.

## 5. Burst — sexto bloco especial (APROVADO)

- O **Burst** é representado por um **bloco extra/sexto**, **independente dos cinco blocos normais de ATB**.
- Uma **esquiva ativa Evade bem-sucedida** disponibiliza **imediatamente** uma ação especial Burst, ainda que a barra normal esteja incompleta. **APROVADO (R1-Q1 = B):** o Pokémon pode **executar Burst na hora ou armazenar o bloco** para utilizar posteriormente, inclusive para golpes que exigem Burst. 'Imediato' designa a disponibilidade, **não obriga consumo instantâneo**.
- **APROVADO (R2-Q1 = A):** um bloco Burst armazenado **permanece disponível até ser usado na batalha atual**, sem prazo de expiração dentro dela, e **não é transferido para outra batalha**.
- **APROVADO (R3-Q1 = B):** um Pokémon pode **armazenar vários blocos Burst simultaneamente, sem limite fixo de quantidade durante a batalha**. Cada Burst é um bloco especial distinto dos cinco normais e dos blocos ATB extras. A nomenclatura histórica de “sexto bloco” descreve o tipo de recurso especial, **não limita seu estoque a uma única unidade**.
- **APROVADO (R2-Q3 = B):** executar um **Move via Burst** exige e consome **um bloco Burst e o custo normal de ATB do Move**; o bloco especial não substitui o gasto de ATB comum. A disponibilidade imediata de Burst não elimina o requisito de ATB do Move escolhido.
- Uma **evasão automática** nunca libera Burst, mesmo recebendo recompensa de ATB.
- Uma ação Burst pode: **aplicar buff a aliados**, **aplicar debuff a inimigos** ou **executar um Move escolhido com dano crítico**.
- **APROVADO (R5-Q4 = B):** buff/debuff usado como ação Burst **custa somente um bloco Burst**, sem consumir ATB normal ou extra. Não alterar o custo de Moves ofensivos via Burst: **1 Burst + custo ATB normal do Move**.
- **APROVADO (R3-Q5 = B):** um **Move ofensivo executado via Burst não concede bônus ATB por atingir fraqueza nem pelo crítico garantido**. A exceção ao crítico garantido já constava em D-019; a ausência de bônus por fraqueza foi adicionada nesta rodada.
- **Determinados ataques exigem Burst** como requisito de execução; a lista e o uso exato do bloco especial para esses ataques ainda não estão definidos.
- Aliados e inimigos podem participar das condições de Burst, conforme suas regras de esquiva ativa.

**PENDENTE, NÃO INFERIR:** efeitos, duração, alvos e pré-requisitos concretos de buffs/debuffs via Burst; limites de encadeamento e prioridade diante de outras ações. O **custo de buff/debuff já está definido: um Burst sem ATB adicional** (R5-Q4). O armazenamento de **vários** Bursts **não possui teto fixo** e dura até uso ou término da batalha; Moves ofensivos via Burst não geram recompensa por fraqueza nem por crítico garantido.

### Exemplo de sequência aprovada, sem números inventados

Ataque direcionado a um Pokémon → tentativa de Evade ativo com custo de 3 → esquiva bem-sucedida → ganho individual de **+1 bloco normal** **e** disponibilização imediata de Burst → o Pokémon **pode** usá-lo agora (Move crítico, buff ou debuff) **ou armazenar** seu bloco para uso posterior. O crítico garantido não fornece recompensa de crítico ao ATB.

## 6. Protagonista, IA e comportamento de batalha

**APROVADO:** jogador controla diretamente o Pokémon protagonista; **companheiros são controlados pela IA**. **Tactic somente orienta/configura o comportamento da IA; não envia ordens diretas a aliados** (R2-Q4, substituindo a parte anterior de D-004). Inimigos decidem suas ações e podem obter recompensas individuais por criticar, explorar fraquezas ou esquivar.

**APROVADO (R1-Q3 + R2-Q4):** a **escolha de orientações de IA** dentro do menu Tactic é a única ocasião aprovada de **pausa do combate**; FIGHT e ITENS não pausam. Pausar para configurar a IA **não configura uma ordem direta ao aliado**.

**APROVADO (R3-Q3 = A):** modificar a orientação em Tactic **não custa ATB**, por se tratar de configuração da IA, não de uma ação cobrada. A pausa exclusivamente durante as escolhas de Tactic continua vigente.

**APROVADO (R4-Q5 = A):** os aliados controlados pela IA avaliam autonomamente quando tentar Evade ativo de acordo com situação e ATB disponível; Tactic pode afetar essa prioridade. Não é uma ordem direta.

**APROVADO (R5-Q5 = B):** as **orientações de Tactic persistem entre batalhas da mesma dungeon até serem alteradas**. A configuração continua gratuita em ATB, não envia ordens diretas e pausa o combate somente durante a escolha. **PENDENTE:** a persistência ou reinicialização dessas orientações após sair da dungeon.

**APROVADO (R6-Q3 = A):** **máximo de três Pokémon ativos na equipe do jogador**, sendo um protagonista sob controle direto e no máximo dois aliados sob IA.

**APROVADO (R6-Q4 = C):** existe **uma opção nas configurações** que oferece os dois comportamentos anteriormente propostos para Tactic **ao sair de uma dungeon**: (A) **reiniciar as orientações para o padrão** ao encerrar a exploração ou (B) **preservar as orientações entre dungeons** até alteração do jogador. O comportamento dentro de uma dungeon permanece o de R5-Q5; a nova decisão **substitui a pendência** sobre persistência entre dungeons. **O padrão inicial da configuração foi estabelecido posteriormente por R7-Q1 = A (reiniciar)**; continuam pendentes os detalhes de salvamento da escolha e a orientação de IA considerada padrão.

**APROVADO (R7-Q1 = A):** a **opção padrão de Tactic nas configurações é reiniciar as orientações ao sair da dungeon**. O jogador **continua podendo escolher preservar as orientações entre dungeons**, como aprovado em R6-Q4. A orientação concreta que define o estado padrão da IA ainda não foi selecionada, assim como o formato de salvamento da escolha.

**APROVADO (R16-Q5 = B):** **Tactic escolhida pelo jogador prevalece integralmente no comportamento da IA enquanto ativa**, sem interferência direta das tendências de Nature sobre essas escolhas. Nature **continua influenciando atributos e crescimento**. Não criar ordens diretas. **PENDENTE:** comportamento sem Tactic escolhida.

**PENDENTE:** interface de seleção do protagonista, troca/controle de líder, regras de reservas/recrutamento além da equipe ativa de até três, catálogo de comportamentos, **persistência técnica da preferência de Tactic nas configurações e orientação-base da IA** e detalhes da lógica de decisão da IA sob Evade/Burst.

**Exemplos não aprovados:** “priorizar fraquezas”, “defender”, “focar alvo” e “suporte” podem ser considerados em perguntas futuras, mas não constituem um conjunto obrigatório.

## 7. Especificação de conteúdo ainda não definida

Sem decisão adicional, não fixar:

- **Pokémon e progressão:** espécies elegíveis, protagonista inicial, recrutamento, reservas e trocas (**equipe ativa de até 3 aprovada**), evolução, **cinco atributos inspirados em SMT3 em escala-base 1–100, Agilidade/Velocidade como atributo único, HP derivado de Vitalidade+nível e MP máximo de Magia+nível**. Ao subir de nível, **o jogador distribui manualmente os pontos apenas do protagonista**, com **1 ponto distribuível por nível (R13-Q4)**; **aliados crescem automaticamente por curvas próprias de cada espécie**, ainda sem valores/fórmulas (R13-Q5). **MP persiste entre batalhas da mesma dungeon** (R12-Q3), é recuperável por **consumíveis e pontos de descanso** (R13-Q2) e **restaurado ao máximo no início de cada nova exploração** (R13-Q3). Valor de referência do ATB e fórmulas de HP/MP seguem pendentes.
- **Moves:** Tackle genérico versus golpe homônimo da franquia (**Tackle genérico custa 2 ATB, sem PP**); lista concreta dos quatro Moves por Pokémon, status, efeitos e **exceções ao custo-base de 2 ATB**, incluindo golpes de custo 5 e requisitos Burst. **Nenhuma ação do Crawlmon utiliza PP** (R8-Q2; complementa R7-Q3). **R23-Q5 = C** aprovou aprendizado combinado com mestres e possíveis personagens que concedam HMs; **R24-Q4 = C** fixou **HMs e TMs apenas para combate por enquanto**. Outras fontes, ensino e slots continuam pendentes.
- **Combate 3D:** câmera, sequência de animações, timings, hitstop, interface gráfica final, modelos, rigging, VFX e arenas por bioma.
- **Dungeon 2D:** geração **procedural por exploração/andar, com salas e corredores** já aprovada (R7-Q5); seed reproduzível (R8-Q3), **layout persistente nas revisitas da mesma exploração** (R9-Q2), **inimigos visíveis que patrulham e perseguem após detecção** (R9-Q3), **inimigos derrotados removidos até o fim da exploração** (R9-Q4) e **movimentação cardinal em quatro direções** (R9-Q5). Permanecem pendentes parâmetros do gerador, interface/armazenamento de seeds, escala dos tiles, alcance/IA de detecção, movimentação contínua cardinal aprovada em R23-Q1, detalhes de controles/colisão, armadilhas, itens, progressão entre andares até o chefe, posicionamento e retorno.

### 7.1. Atributos e progressão dos Pokémon — decisões da Rodada 10

**APROVADO (R10-Q1 = C):** o **modelo de atributos de Crawlmon terá como referência Shin Megami Tensei III: Nocturne**, em vez dos catálogos de quatro ou seis atributos oferecidos como alternativas. A referência possui cinco atributos principais: **Strength (Força), Magic (Magia), Vitality (Vitalidade), Agility (Agilidade) e Luck (Sorte)**. No jogo de referência, HP e MP são recursos/indicadores apresentados separadamente dos cinco atributos. **Não interpretar essa observação como aprovação de MP no Crawlmon**, de cópia literal de fórmulas de SMT3 ou de uma substituição automática do atributo Velocidade aprovado para ATB.

**Referências externas consultadas (contexto de SMT3, não novas regras):** [guia de status de SMT III](https://steamcommunity.com/sharedfiles/filedetails/?id=2498200926) e [ficha de um demônio de SMT III com os cinco atributos, HP e MP](https://megatenwiki.com/wiki/Gameplay%3APrincipality).

**APROVADO (R10-Q2 = A):** escala numérica de **1 a 100 para os atributos-base** adotados no Crawlmon, antes de progressão/modificadores. Esta é uma regra própria do Crawlmon, não afirma que SMT3 usa a mesma escala nem define HP máximo, limites após progressão ou valores individuais de espécies.

**APROVADO (R10-Q3 = A):** cada Pokémon possui **nível** e seus atributos **evoluem conforme o nível**. **PENDENTE:** nível máximo, experiência, curvas/fórmulas de crescimento, limites de distribuição e diferenças entre espécies. **R13-Q4 fixou 1 ponto distribuível por nível para o protagonista** após R12-Q4. **R12-Q5 mantém a distribuição manual restrita ao protagonista e R13-Q5 estabelece curvas automáticas por espécie para os aliados**, sem valores/fórmulas aprovados.

**APROVADO (R10-Q4 = A):** buffs/debuffs alteram os atributos por **estágios discretos positivos/negativos**, não por percentuais diretos arbitrários como regra primária. **PENDENTE:** estágios permitidos, multiplicadores, acumulação, duração, atributos afetáveis e interação com o sistema ATB. O custo de buff/debuff aplicado via Burst continua sendo **1 bloco Burst e nenhum ATB adicional** (R5-Q4).

**APROVADO (R10-Q5 = A):** a **Velocidade de referência para os 5 segundos de ATB será um valor fixo** na escala de atributos escolhida, **comum a todas as espécies e níveis**; o valor numérico **fica pendente**. **R11-Q1 resolveu que Agilidade e Velocidade do ATB são um único atributo**; apenas o nome de exibição e os efeitos adicionais dessa estatística continuam em aberto.

**Nota de rastreabilidade da Rodada 10:** naquela rodada, valores numéricos específicos, fórmulas de dano/HP/MP e a criação de MP não haviam sido aprovados. **R11-Q3 aprovou posteriormente a existência de MP**, sem definir fórmula, custos, recuperação, interface ou funcionamento. R11-Q1 também resolveu a equivalência Agilidade/Velocidade. Permanecem inalteradas as regras de **ausência de PP**, o custo de ATB/Burst, a escala-base 1–100 e as demais decisões históricas.

### 7.2. Adaptação dos atributos de SMT3 — decisões da Rodada 11

**APROVADO (R11-Q1 = A) — Agilidade e Velocidade:** **Agilidade** da referência SMT3 e **Velocidade** do ATB do Crawlmon designam **um único atributo**, não dois atributos separados. O atributo único governa o preenchimento natural do ATB segundo a proporcionalidade inversa já aprovada. **PENDENTE:** nome exibido na interface (“Agilidade” ou “Velocidade”), valor numérico fixo de referência para 5 segundos e demais efeitos da estatística. Não alterar a escala-base de 1–100.

**APROVADO (R11-Q2 = A) — Vitalidade e HP:** **HP máximo é derivado da Vitalidade e do nível do Pokémon**, sem criar um atributo-base independente de HP além dos cinco inspirados em SMT3. HP continua sendo medidor de vida. **PENDENTE:** fórmula, progressão por nível, HP inicial, limites e arredondamento.

**APROVADO (R11-Q3 = B) — Magia e MP:** o atributo **Magia afeta dano e efeitos mágicos** e Crawlmon terá também um **recurso MP separado**. **APROVADO posteriormente (R12-Q1/Q2/Q3):** **todos os Moves mágicos/especiais consomem MP adicional aos custos ATB/Burst**, o **MP máximo depende de Magia e nível**, e o **MP restante persiste entre batalhas da mesma dungeon**. **APROVADO posteriormente em R13-Q1/Q2/Q3:** custo-base comum de MP com exceções individuais por Move; recuperação por consumíveis e pontos de descanso na dungeon; restauração de MP ao máximo no início de nova exploração. **PENDENTE:** fórmulas/limites de MP máximo, valores de MP e das exceções, detalhes de itens/descanso, interface e demais interações. **MP não é PP**: continua proibido introduzir PP; o MP não substitui os custos aprovados de ATB/Burst.

**APROVADO (R11-Q4 = B) — evolução de atributos:** ao subir de nível, o **jogador distribui manualmente pontos de atributo**. **APROVADO posteriormente (R12-Q4/Q5):** cada nível concede uma **quantidade fixa de pontos** e a **distribuição manual pelo jogador aplica-se somente ao protagonista**. **R13-Q4 fixou 1 ponto distribuível por nível para o protagonista; R13-Q5 definiu curvas automáticas por espécie para os aliados**, sem valores/fórmulas. **PENDENTE:** atributos elegíveis, limites, restrições, pontos não distribuídos, fórmulas das curvas e regras dos inimigos. A distribuição manual aprovada em R11-Q4 permanece válida **para o protagonista**.

**APROVADO (R11-Q5 = A) — Sorte:** **Sorte influencia probabilidades de combate**, como chance de crítico e/ou outros efeitos probabilísticos. **PENDENTE:** quais eventos exatamente são modificados e suas fórmulas/limites. Não atribuir valores de chance, modificadores de ATB nem taxas de recompensa não aprovados. As recompensas instantâneas existentes por crítico normal permanecem inalteradas.

**Separação de estado:** catálogo/escala de atributos, nível, estágio de buff/debuff, ATB, Burst e ausência de PP são regras já aprovadas. A economia de MP está **parcialmente definida por R12–R13** (consumo por Moves mágicos/especiais, MP máximo ligado a Magia+nível, custo-base comum com exceções, persistência entre batalhas, recuperação por consumíveis/descanso e restauração ao iniciar nova exploração), mas **fórmulas, valores e detalhes de recuperação ainda não estão definidos**. Não tratar a documentação como implementação técnica.

### 7.3. Economia de MP e crescimento dos atributos — decisões da Rodada 12

**APROVADO (R12-Q1 = A) — consumo de MP:** **todos os Moves mágicos/especiais gastam MP adicional**, além dos custos de **ATB e Burst já aprovados, quando aplicáveis**. Não definir aqui quais Moves concretos pertencem à categoria. **R13-Q1 aprovou posteriormente custo-base comum de MP com exceções individuais por Move, ainda sem valores**. Esta regra não autoriza substituir ATB/Burst por MP nem introduzir PP.

**APROVADO (R12-Q2 = A) — capacidade de MP:** **o MP máximo é derivado do atributo Magia e do nível do Pokémon**. **PENDENTE:** fórmula, valor inicial, multiplicadores, limites, arredondamento e comportamento se Magia ou nível mudar. Não presumir fórmula igual à de HP.

**APROVADO (R12-Q3 = B) — persistência de MP:** **o MP atual/restante é conservado entre os encontros da mesma dungeon**, em vez de ser restaurado integralmente no início de cada combate. **APROVADO depois (R13-Q2/Q3):** recuperação por consumíveis e pontos de descanso na dungeon; MP restaurado ao máximo ao iniciar nova exploração. **APROVADO depois (R14-Q2):** recuperação de MP vinculada a ATB 5/5 e descanso com MP completo. **PENDENTE:** base, cronômetro, limitações, revisitas e casos extraordinários. A regra de **início de batalha com 0/5 ATB normal** permanece independente e inalterada.

**APROVADO (R12-Q4 = A) — pontos por nível:** **cada nível concede uma quantidade fixa de pontos de atributo**; **R13-Q4 fixou posteriormente 1 ponto distribuível por nível para o protagonista**. A regra de quantidade fixa não determina limite de atributos, banco de pontos, curva de experiência ou a regra de atribuição automática dos aliados.

**APROVADO (R12-Q5 = B) — controle da distribuição:** **somente os pontos do protagonista são distribuídos manualmente pelo jogador**. Pokémon **aliados crescem automaticamente ao subir de nível**, seguindo **curvas específicas de cada espécie** (R13-Q5), com valores e fórmulas pendentes. Esta decisão esclarece o escopo de R11-Q4 e **não altera a IA de combate dos aliados**, o tamanho máximo da equipe nem define crescimento dos inimigos.

**Pendências preservadas:** números do custo-base de MP e exceções, detalhes de consumíveis e descanso, fórmula de MP máximo, tratamento de pontos não distribuídos e curvas numéricas dos aliados. **R13 resolveu restauração de MP ao iniciar nova exploração e fixou 1 ponto por nível do protagonista**. O GDD **não institui PP** e preserva os custos ATB/Burst.

### 7.4. MP e progressão por espécie — decisões da Rodada 13

**APROVADO (R13-Q1 = A):** Moves mágicos/especiais têm **custo-base comum de MP com exceções individuais por Move**. **PENDENTE:** valor do custo-base, lista de exceções e valores individuais. **ATB/Burst continuam sendo cobrados conforme as regras aprovadas**; não introduzir PP.

**APROVADO (R13-Q2 = B):** MP pode ser recuperado por **consumíveis e pontos de descanso/recuperação dentro das dungeons**. **APROVADO depois (R14-Q2):** MP recuperado completamente no descanso e recuperação periódica condicionada a ATB cheio; detalhes e condições continuam pendentes.

**APROVADO (R13-Q3 = A):** **MP é restaurado ao máximo no início de cada nova exploração**. O **MP restante continua persistindo entre combates da mesma dungeon** (R12-Q3). Esta regra não define recuperação de HP ou outras condições de início da exploração.

**APROVADO (R13-Q4 = A):** o **protagonista recebe 1 ponto de atributo distribuível por nível**, alocado manualmente pelo jogador. **R14-Q4 = B estabeleceu distribuição obrigatória do ponto na subida de nível, antes de concluir a progressão**. Limites e interface pendentes. Não acumular voluntariamente pontos nem extrapolar o ponto aos aliados.

**APROVADO (R13-Q5 = A):** atributos dos aliados **crescem automaticamente por curvas específicas de espécie**. **R14-Q5 = C acrescentou crescimento por tática/forma de lutar e Natures**, com definição aleatória de comportamento para recrutáveis. Curvas de espécie continuam como referência mas não como regra exclusiva. Fórmulas, valores e Nature pendentes; distribuição manual continua exclusiva do protagonista.

**Preservação:** as regras ATB/Burst, a ausência de PP, a escala de atributos-base 1–100 e as decisões sobre IA permanecem inalteradas.

### 7.5. Recuperação de MP, HP e táticas — decisões da Rodada 14

**APROVADO (R14-Q1 = A):** **MP de Moves mágicos/especiais é descontado na ativação**. Cancelamento, reembolso e interrupções pendentes. Não alterar custos ATB/Burst.

**APROVADO (R14-Q2 = C + A; especificado em R15-Q1/Q2 = A):** coexistem **recuperação de 25% do MP máximo após cada período de 3 segundos consecutivos em ATB normal 5/5**, com **reinício do cronômetro ao deixar 5/5**, e **restauração completa de MP nos pontos de descanso**. Mantêm-se os consumíveis de MP. **PENDENTE:** arredondamento, pausa Tactic, atuação fora de combate e condições dos pontos de descanso. Não presumir cura de HP no descanso ou gerar ATB extra. A mecânica não altera os custos ATB/Burst.

**APROVADO (R14-Q3 = A):** **HP restante de cada Pokémon persiste entre combates da mesma dungeon até ser recuperado**. Recuperação de HP, HP de nova exploração e derrota pendentes.

**APROVADO (R14-Q4 = B):** o protagonista, que recebe **1 ponto distribuível por nível**, **deve distribuí-lo ao subir de nível antes de concluir a progressão**. Não guardar pontos voluntariamente. Limites, interface e elegibilidade pendentes.

**APROVADO (R14-Q5 = C; especificado em R15-Q3 = A, R15-Q4 = B e R15-Q5 = B):** Pokémon têm **atributos-base**, e os ganhos por nível dos aliados são influenciados **conjuntamente pela tática selecionada e pelas ações efetivamente executadas em combate**; pesos e período de observação ficam pendentes. **Natures influenciam atributos, crescimento e tendências comportamentais/táticas**, ainda sem catálogo ou modificadores definidos. Para Pokémon aleatórios recrutáveis, a **tática inicial é sorteada entre opções associadas à Nature** do Pokémon, sem lista de compatibilidades ou probabilidades aprovadas. As curvas automáticas por espécie de R13-Q5 continuam sendo referência, mas não excluem tática, ações ou Nature. **PENDENTE:** ponderações e fórmulas de crescimento, ações contabilizadas, lista de Natures, vínculos entre táticas e Natures e regras concretas de sorteio.

**Prioridade documental:** regras específicas de R14 complementam R12/R13; preservar o histórico. Crawlmon permanece sem PP, com custos ATB/Burst inalterados.

### 7.6. Recuperação por ATB cheio, Natures e aprendizado — decisões da Rodada 15

**APROVADO (R15-Q1 = A):** ao manter **5/5 blocos ATB normais**, o Pokémon recupera **1/4 (25%) do seu MP máximo** ao concluir cada intervalo elegível de **3 segundos**. O MP recuperado não ultrapassa o máximo. **PENDENTE:** arredondamento da parcela fracionária; não definir uma fórmula nova para MP máximo.

**APROVADO (R15-Q2 = A):** para recuperar cada parcela, são necessários **3 segundos consecutivos em 5/5 ATB**. Se o Pokémon deixar de estar em 5/5, **o contador é zerado**, não pausado; ao encher novamente, inicia-se novo período inteiro. **PENDENTE:** o tratamento da pausa de Tactic e dos cenários fora de combate. O ATB natural continua limitado a cinco blocos e o MP não produz blocos extras.

**APROVADO (R15-Q3 = A):** o crescimento automático dos aliados considera **tanto a tática selecionada quanto as ações realmente executadas em combate**. **PENDENTE:** período de registro, critérios/ponderações das duas influências, atributos afetados, combinação com curvas específicas da espécie e fórmulas. A distribuição manual de atributos permanece exclusiva do protagonista.

**APROVADO (R15-Q4 = B):** **Natures influenciam os atributos, seu crescimento e tendências comportamentais/táticas** dos Pokémon. **PENDENTE:** catálogo de Natures, seus efeitos, modificadores, limites e interações com Tactic e IA. Não atribuir valores ou comportamentos específicos sem aprovação.

**APROVADO (R15-Q5 = B):** a **tática inicial dos Pokémon aleatórios recrutáveis é sorteada dentre opções associadas à Nature**. **PENDENTE:** catálogo de táticas por Nature, probabilidades, momento de sorteio da Nature e persistência das atribuições. O jogador continua podendo alterar orientações usando Tactic conforme regras anteriores; esta decisão não cria ordens diretas para a IA.

**Preservação:** MP nos pontos de descanso continua restaurado completamente; HP/MP persistem entre batalhas na mesma dungeon, conforme suas regras. O projeto continua **sem PP**, e os custos ATB/Burst aprovados não mudam.

### 7.7. Recuperação de MP, telemetria e Nature — decisões da Rodada 16

**APROVADO (R16-Q1 = B):** na recuperação periódica com ATB 5/5, cada parcela equivalente a **25% do MP máximo é arredondada para baixo**. Preservar intervalo de três segundos e limite do MP máximo. Nenhuma fórmula ou custo numérico adicional foi definido.

**APROVADO (R16-Q2 = A):** **contador de recuperação fica zerado enquanto MP estiver no máximo**, mesmo com ATB 5/5. Ao surgir MP faltante enquanto ATB continua 5/5, é necessário **novo período completo de 3 s**. Sair de 5/5 zera também o contador (R15-Q2). **PENDENTE:** pausa Tactic e funcionamento fora do combate.

**APROVADO (R16-Q3 = C):** haverá **telemetria de desempenho em combate que considera a maioria das ações efetuadas pelo Pokémon**, para informar o crescimento de atributos dos aliados. **Não foram escolhidas as alternativas anteriores de janela “desde o último nível” ou “histórico acumulado”**. **PENDENTE:** período, tipos de ações monitorados, critérios para identificar predominância, medidas de eficácia, ponderações, armazenamento e fórmulas. **Tática selecionada e ações efetivamente executadas continuam influenciando juntas o crescimento** (R15-Q3), com curvas específicas por espécie como referência. A distribuição manual continua exclusiva do protagonista.

**APROVADO (R16-Q4 = A):** **Nature de Pokémon recrutável aleatório é sorteada quando ele é gerado, antes do recrutamento, e permanece atribuída**. Tática inicial ainda é sorteada dentre opções associadas à Nature (R15-Q5). **PENDENTE:** probabilidades, catálogo e atribuição de Nature a outros tipos de Pokémon.

**APROVADO (R16-Q5 = B):** **a Tactic escolhida prevalece integralmente nas decisões comportamentais da IA enquanto está ativa**. Nature ainda influencia atributos e crescimento, mas não interfere diretamente no comportamento orientado pela Tactic ativa. **PENDENTE:** influência comportamental da Nature quando não houver Tactic escolhida pelo jogador.

**Preservação:** estas são decisões de design documentadas, não implementação no Godot. Sem PP, sem novos valores ou fórmulas de atributos e sem alteração dos custos ATB/Burst.

### 7.8. Telemetria acumulada, Nature e pausa do contador MP — Rodada 17

**APROVADO (R17-Q1 = B):** a telemetria usa o **histórico acumulado de ações de combate do Pokémon**, preservado entre níveis, com ponderação ainda pendente. **PENDENTE:** persistência entre dungeons/explorações, peso de ações antigas, limites de armazenamento e fórmulas. A janela de histórico acumulado supera a pendência anterior de R16-Q3.

**APROVADO (R17-Q2 = A):** ações predominantes são identificadas pela **frequência das categorias de ações executadas**, independentemente de sucesso. **PENDENTE:** categorias, critérios de contagem de ações multi-hit/multi-alvo, empates e momento da contabilização. Não presumir exigência de eficácia.

**APROVADO (R17-Q3 = B):** **a tática selecionada é a influência principal** na evolução dos atributos de aliados, e a **telemetria ajusta os ganhos conforme ações realmente executadas**. **PENDENTE:** pesos, ligação entre categorias e atributos, interações com Nature e curvas por espécie, fórmulas. O comportamento da IA durante Tactic ativa continua seguindo R16-Q5.

**APROVADO (R17-Q4 = C, “entao B”):** o criador respondeu literalmente **“o jogo é um roguelike dungeon crawler, entao B”**. Assim, **Nature é sorteada também na geração do protagonista e de Pokémon de eventos**, conforme a alternativa B explicitamente escolhida, preservando o registro de resposta personalizada **C**. **PENDENTE:** probabilidades, persistência entre explorações e momento de geração dos personagens. Não inferir permadeath, reroll em toda dungeon ou outras mecânicas apenas pela justificativa roguelike. Recrutáveis aleatórios mantêm a regra anterior de Nature sorteada na geração.

**APROVADO (R17-Q5 = A):** o **contador da recuperação periódica de MP fica pausado durante o menu Tactic** e retoma quando o combate prossegue **se ainda houver MP faltante e ATB normal 5/5**. Não adicionar tempo da pausa ao contador. Se ATB sair de 5/5 ou MP estiver no máximo, os resets já aprovados prevalecem. Continuam os três segundos consecutivos, a parcela de 25% do MP máximo com arredondamento para baixo e o limite do MP máximo.

**Preservação:** decisões documentadas, sem implementação em código. Sem PP, fórmulas ou novos custos ATB/Burst.

### 7.9. Telemetria persistente, categorias de ações e Nature do protagonista — decisões da Rodada 18

**APROVADO (R18-Q1 = A) — persistência da telemetria:** o **histórico acumulado de telemetria acompanha o mesmo Pokémon entre dungeons e explorações**, além de ser preservado entre níveis conforme R17-Q1. A persistência depende da **identidade do mesmo Pokémon**, não apenas da espécie. **PENDENTE:** política de histórico ao sair/retornar à equipe, ao deixar de existir o indivíduo, limites de armazenamento, peso temporal e fórmulas. Não aplicar a persistência automaticamente a um Pokémon novo.

**APROVADO (R18-Q2 = A) — categorias abrangentes da telemetria:** a telemetria de combate inclui **ataques físicos, ataques mágicos/especiais, defesa/esquiva, suporte e uso de itens**. A **frequência das categorias executadas** continua sendo o critério aprovado em R17-Q2, **sem exigir sucesso**. **PENDENTE:** catálogo detalhado de eventos dentro de cada categoria, classificação de ações híbridas, vínculo com atributos e regras de registro.

**APROVADO (R18-Q3 = A) — multi-hit/multi-alvo:** **uma execução de Move é contabilizada como exatamente uma ação na telemetria**, independentemente do número de impactos, golpes internos ou alvos. Não multiplicar o registro por impacto ou alvo. **PENDENTE:** tratamento de ações canceladas antes da execução e casos de ativação incompleta. Esta regra **não modifica as recompensas de ATB** de ataques multi-hit/multi-alvo aprovadas anteriormente.

**APROVADO (R18-Q4 = A) — Nature do protagonista em novas explorações:** a **Nature do protagonista é sorteada novamente no início de cada nova exploração**, com probabilidades pendentes. Esta regra complementa a aprovação de R17-Q4 (Nature sorteada na geração) e **se aplica explicitamente ao protagonista** mesmo sem decisão sobre recriar ou não o indivíduo a cada exploração. **Não estender o novo sorteio aos aliados ou Pokémon de eventos**, nem presumir reinício de nível, perda de pontos distribuídos ou alterações na identidade do Pokémon. **PENDENTE:** tabela de probabilidades, como recalcular/aplicar os efeitos sobre atributos-base, relação com estado anterior do protagonista e persistência de demais progressos.

**APROVADO (R18-Q5 = A) — Nature e atributos-base:** **Natures modificam atributos-base** dos Pokémon, além de influenciar o crescimento e tendências comportamentais já aprovados (R15-Q4). **PENDENTE:** quais atributos-base podem ser afetados, direção e magnitude das alterações, limites em relação à escala-base 1–100, momento de aplicação, efeitos de novo sorteio de Nature e interação com atributos derivados de HP/MP e buffs/debuffs. No comportamento da IA, **Tactic escolhida pelo jogador continua prevalecendo integralmente enquanto ativa** (R16-Q5).

**Preservação:** não criar fórmulas ou probabilidades, nem presumir que o protagonista perde níveis/progressão entre explorações. Não introduzir PP nem alterar custos ATB/Burst, medidores de HP/MP, teto de recompensas multi-hit ou regras de pausa de Tactic. Todas as regras acima são **decisões documentadas, não implementação**.

### 7.10. Telemetria em mudanças de equipe, duas categorias e Natures — decisões da Rodada 19

**APROVADO (R19-Q1 = A) — retorno de aliados:** **quando um Pokémon aliado sai da equipe e posteriormente retorna, ele preserva seu histórico individual de telemetria**, incluindo registros anteriores à saída. Essa regra é compatível com a persistência do histórico do mesmo indivíduo entre explorações (R18-Q1); não atribuir esse histórico a outro Pokémon da mesma espécie. **PENDENTE:** comportamento se o Pokémon deixar de existir, condições técnicas de armazenamento e eventuais ações executadas fora da equipe.

**APROVADO (R19-Q2 = C) — até duas categorias:** cada ação/execução na telemetria pode ser classificada em **no máximo duas categorias**, conforme a resposta literal do criador: **“no maxim duas categorias”**. A classificação pode admitir uma ou duas categorias, **sem obrigatoriedade de usar duas**. Esta decisão **não transforma uma execução em duas ações**: uma execução de Move continua sendo uma ação para a contagem de execuções (R18-Q3), independente de hits e alvos. **PENDENTE:** como selecionar as categorias em uma ação candidata a mais de duas; se ambas têm a mesma prioridade; como uma ação associada a duas categorias participa da frequência em cada categoria; e classificação de ações que não são Moves. Não pressupor a seleção automática de categorias ou pesos.

**APROVADO (R19-Q3 = A) — início efetivo da execução:** uma ação é registrada pela telemetria **quando sua execução efetivamente começa**, ainda que depois falhe, erre, seja interrompida ou cancelada. Uma intenção/comando confirmado **que não chegou a iniciar sua execução** não é registrada por esta regra. O sucesso continua não sendo condição de registro (R17-Q2). **PENDENTE:** evento técnico que distingue confirmação de comando e início efetivo para cada tipo de ação. Esta decisão **não altera** as regras de cobrança ou reembolso de MP, ATB e Burst.

**APROVADO (R19-Q4 = A) — distribuição preservada quando Nature mudar:** ao sortear novamente a Nature do protagonista no início de uma exploração (R18-Q4), **preservar integralmente os pontos de atributo anteriormente distribuídos pelo jogador**. **Substituir apenas os efeitos associados à Nature anterior pelos efeitos da nova Nature**, não reabrindo automaticamente a distribuição dos pontos já alocados. **PENDENTE:** recomposição numérica dos atributos-base, limites 1–100, efeitos sobre HP/MP derivados e o estado atual desses recursos; nenhuma fórmula ou reset de níveis foi escolhido.

**APROVADO (R19-Q5 = B) — modificadores flexíveis de Nature:** **Natures podem conceder bônus e penalidades aos atributos-base sem a exigência de um par fixo de atributo favorecido e atributo prejudicado**. Não exigir que toda Nature aumente necessariamente um atributo e reduza outro. **PENDENTE:** catálogo, se existem Natures neutras, atributos afetados, intensidades, combinações permitidas, limites e relação com crescimento. Os efeitos de Nature sobre crescimento e tendências comportamentais continuam aprovados (R15-Q4), e a Tactic escolhida continua prevalecendo integralmente sobre tendências de Nature durante sua vigência (R16-Q5).

**Rastreabilidade:** R19-Q2 é uma resposta **C personalizada**, não aprovação irrestrita da alternativa B anterior. O teto de **duas categorias** não substitui o teto de **uma execução** e não interfere nas recompensas ATB multi-hit/multi-alvo. R19-Q4 preserva os pontos distribuídos e esclarece a mudança de Nature; R19-Q5 deixa a estrutura de bônus/penalidades flexível sem adicionar números. **Estas são regras documentais, não implementação em código.** Permanecem inexistentes os PP, e os custos ATB/Burst não foram modificados.

### 7.11. Categorias de telemetria e efeitos de Nature — decisões da Rodada 20

**APROVADO (R20-Q1 = A) — seleção de categorias:** se uma ação/Move puder pertencer a mais de duas categorias de telemetria, registrar **as categorias principais previamente definidas na ficha da ação/Move**, respeitando o teto de **duas categorias por ação** aprovado em R19-Q2. **PENDENTE:** critérios de escolha/priorização das categorias na ficha, formato dos dados e tratamento de ações sem ficha própria. Não inferir seleção dinâmica por efeitos nem classificação obrigatória em duas categorias.

**APROVADO (R20-Q2 = A) — frequência com dupla classificação:** uma ação classificada em **duas categorias contribui com uma ocorrência de frequência em cada uma dessas categorias**. O registro continua sendo **uma única ação executada**, inclusive quando o Move possui vários hits ou alvos (R18-Q3); não contar dois Moves, duas execuções ou impactos/alvos adicionais. **PENDENTE:** como resolver empates entre categorias de frequência predominante e como as frequências se traduzem em ajustes de atributos. Não estabelecer pesos ou fórmulas de crescimento.

**APROVADO (R20-Q3 = A) — fora da equipe:** quando o Pokémon **não está na equipe**, seu **histórico individual de telemetria permanece preservado, sem acumular novas ações até seu retorno**. Ao retornar, a contagem poderá continuar a partir do histórico preservado (R19-Q1), observadas as regras de execução e categorização já aprovadas. Não inferir que o Pokémon pode ou não participar de combates fora da equipe por outros sistemas; **para a telemetria, não se acumulam eventos durante sua ausência**.

**APROVADO (R20-Q4 = A) — preservação proporcional de HP/MP:** **se a mudança de Nature do protagonista alterar o HP máximo e/ou MP máximo, o valor atual do recurso afetado deve preservar sua proporção em relação ao máximo anterior**, aplicando essa mesma proporção ao novo máximo. A regra é **condicional**: não presume que toda Nature altere HP/MP, nem substitui a regra aprovada de preservar pontos de atributo já distribuídos (R19-Q4). **PENDENTE:** arredondamento, tratamento de máximos anteriores inválidos/zero, regras numéricas de recomposição, implementação do recálculo e demais casos-limite. **Não interpretar como recuperação integral automática de HP/MP**, nem alterar sua persistência entre combates.

**APROVADO (R20-Q5 = A) — Natures neutras:** o catálogo **pode incluir Natures neutras, sem modificadores diretos nos atributos-base**. Elas **ainda podem influenciar crescimento e/ou tendências comportamentais**, conforme regras a especificar; a neutralidade nos atributos-base não define automaticamente neutralidade nos demais efeitos. **PENDENTE:** catálogo de Natures, quais são neutras, efeitos concretos, intensidades, limites e probabilidades. A Tactic escolhida continua prevalecendo integralmente sobre tendências comportamentais de Nature enquanto ativa.

**Preservação:** R20 detalha as decisões R18 e R19 sem modificá-las retroativamente: uma execução continua sendo uma ação, com até duas classificações de telemetria; pontos distribuídos não são perdidos com a troca de Nature. **Nenhum valor, fórmula de atributos, probabilidade, PP ou custo ATB/Burst foi criado nesta revisão.** As regras são documentais, não implementação do jogo.

### 7.12. Regras de categorias, desempate e Nature — decisões da Rodada 21

**APROVADO (R21-Q1 = A) — prioridade por ficha:** **a ordem de prioridade de categorias da telemetria é específica e registrada na própria ficha de cada ação/Move**. Se houver mais de duas categorias possíveis, selecionar as categorias principais conforme essa ordem da ficha, respeitando o limite anterior de **no máximo duas categorias por ação**. **PENDENTE:** ordem concreta de cada ficha, critérios de classificação e tratamento de ações que não são Moves. Não presumir prioridade global.

**APROVADO (R21-Q2 = A) — itens que também oferecem suporte:** o **uso de item que também realiza suporte é classificado somente como uso de item na telemetria**, sem marcar categoria de suporte adicional. Esta regra específica prevalece sobre a possibilidade geral de até duas categorias, sem mudar o efeito do item, seu custo ATB ou a regra de uma ação por execução.

**APROVADO (R21-Q3 = B) — empate na frequência:** a **tática selecionada é usada para desempatar categorias com frequência predominante igual**. **PENDENTE:** prioridades de categorias por tática, qual tática considerar quando houve mudanças no histórico, ausência de Tactic escolhida e eventuais empates não solucionados. A tática continua sendo a influência principal nos ganhos por nível dos aliados (R17-Q3); não se definem pesos numéricos.

**APROVADO (R21-Q4 = A) — HP/MP proporcional por Nature:** após a mudança de Nature do protagonista, se HP ou MP máximo mudar, **arredondar para baixo o valor proporcional resultante de HP/MP atual**, mantendo a proporção em relação ao máximo anterior e respeitando o **novo máximo**. Esta decisão resolve apenas o arredondamento da mudança proporcional de Nature; **não altera** o arredondamento da recuperação periódica de MP, nem presume nova fórmula dos máximos, recarga de recursos ou redistribuição de pontos manuais. **PENDENTE:** máximo anterior igual a zero/inválido, caso do HP positivo que resulte em zero e demais casos-limite.

**APROVADO (R21-Q5 = A) — Nature neutra nos atributos-base:** **Natures sem modificadores diretos nos atributos-base podem afetar crescimento e/ou tendências de comportamento**, com efeitos futuros a especificar. Neutralidade dos atributos-base não significa obrigatoriamente ausência de qualquer outro efeito. O verbo **“podem” não obriga toda Nature neutra a ter um efeito específico**. A Tactic selecionada continua prevalecendo sobre tendências de Nature no comportamento da IA enquanto ativa (R16-Q5). **PENDENTE:** catálogo, efeitos e intensidades.

**Preservação:** uma execução continua uma ação; múltiplos hits/alvos não multiplicam registros de telemetria. Itens com efeito de suporte recebem somente a categoria item. As decisões anteriores e o histórico permanecem válidos; **sem fórmulas, valores numéricos, PP ou novos custos ATB/Burst**. Esta revisão é documental, não implementação.

### 7.13. Categorias na execução, Tactic na evolução e limites de Nature — decisões da Rodada 22

**APROVADO (R22-Q1 = A) — categorias previstas na ficha:** **quando o Move iniciar efetivamente sua execução, registrar as categorias de telemetria previstas em sua ficha**, mesmo se algum componente ou efeito planejado não ocorrer ou não atingir o alvo. O sucesso não é condição para classificar a execução. Preservar o máximo de **duas categorias**, selecionadas segundo a **prioridade específica da ficha do Move**, a **contagem de uma ação por execução**, e o registro somente ao **início efetivo da execução** (R19-Q3). **PENDENTE:** especificação das categorias de cada Move e prioridade concreta nas fichas, bem como critérios técnicos para distinguir início de execução de mera confirmação.

**APROVADO (R22-Q2 = A) — ações não-Moves:** **definir classificação e prioridade da telemetria por tipo de ação**, incluindo **defesa/esquiva, itens e outros tipos**, com os critérios concretos ainda pendentes. A regra específica para **item com efeito de suporte** permanece: classificar **somente como uso de item** (R21-Q2). **PENDENTE:** catálogo dos tipos de ações, categorias e prioridades de cada um, incluindo o tratamento de ações automáticas. Não alterar efeitos ou custos das ações.

**APROVADO (R22-Q3 = A) — referência temporal no desempate:** se houver empate de frequência entre categorias predominantes da telemetria, **a tática selecionada no momento da subida de nível do aliado é a referência para desempatar**. Esta regra detalha R21-Q3 e não modifica a prioridade geral da tática sobre a telemetria no crescimento (R17-Q3). **PENDENTE:** quais categorias são favorecidas por cada tática, comportamento se nenhuma tática estiver selecionada e critérios para empate ainda não resolvido. Não usar automaticamente a tática mais frequente no histórico.

**APROVADO (R22-Q4 = A) — HP positivo após ajuste proporcional:** se um Pokémon possuía **HP positivo antes do recálculo proporcional por mudança de Nature**, e o arredondamento para baixo geraria **HP zero**, preservar **um mínimo de HP positivo**. O tratamento concreto desse mínimo e os casos-limite ainda dependem de especificação; **não fixar aqui um valor numérico**. A proteção só foi aprovada para quem tinha HP positivo; não inferir cura/reanimação de quem já estava com HP zero. Mantêm-se a preservação proporcional e o arredondamento para baixo (R20-Q4/R21-Q4).

**APROVADO (R22-Q5 = A) — escala final dos atributos-base:** os **atributos-base após aplicar modificadores de Nature devem permanecer na faixa aprovada de 1–100**. O limite é aplicado ao **valor-base modificado**, sem autorização para exceder a escala final. **PENDENTE:** o procedimento concreto para impor o limite, eventual tratamento de excedentes, relação com a distribuição manual de atributos e reaplicação após novo sorteio de Nature. Não atribuir valores a Nature ou fórmulas de crescimento.

**Preservação:** as decisões R22 refinam exclusivamente as regras pendentes. Telemetria de Move continua **uma ação por execução**, com até duas categorias e registro sem exigir sucesso; Tactic não envia ordens diretas, e seus custos permanecem os aprovados. Não introduzir PP, novos valores/fórmulas nem custos ATB/Burst.













- **Modos de batalha:** pausa **exclusiva** na seleção das orientações de Tactic já aprovada; detalhes de processamento e concorrência de ações/animações sem introduzir outras pausas, prioridade de ações e múltiplos comandos simultâneos ainda exigem especificação técnica.
- **Balanceamento:** recompensas-base (+1 fraqueza, +2 crítico normal, +2 evasão automática, +1 Evade ativo) e soma crítico normal+fraqueza aprovadas; **blocos ATB excedentes são preservados fora dos cinco normais, sem serem Burst** e são **gastos antes dos blocos normais**. O preenchimento natural não cria extras. Moves Burst não geram ATB por fraqueza nem por crítico garantido. **Extras não têm teto fixo e são exibidos em quadradinhos adicionais**, conforme R4-Q1/Q2. **R5-Q1:** os extras são descartados ao final de cada batalha. **R5-Q2/Q3:** em ataques normais multi-alvo e/ou multi-hit, no máximo +1 por fraqueza e +2 por crítico normal para a ação inteira. Permanecem pendentes duração de buffs/debuffs, dano de crítico, tabela de tipos e interações especiais.
- **Distribuição/publicação:** direitos dos personagens, modelos e demais elementos de propriedade intelectual precisam ser considerados se houver distribuição pública.


### 7.14. Exploração e progressão fundamentais — decisões da Rodada 23

**APROVADO (R23-Q1 = A):** explorar dungeons 2D com **movimentação contínua cardinal**, sem diagonal direta, preservando R9-Q5. Controles, velocidade, colisão e animações pendentes.

**APROVADO (R23-Q2 = A):** **conclusão da dungeon exige chegar ao último andar e vencer um chefe**. Transições, andares, recompensas e chefes concretos pendentes.

**APROVADO (R23-Q3 = A):** **derrota definitiva termina a exploração atual**. Consequências sobre Pokémon, itens, progresso e recursos não escolhidas.

**APROVADO (R23-Q4 = B):** **recrutamento durante exploração 2D por interação ou aproximação**. **Coexistência obrigatória com R8-Q5:** contato com Pokémon inimigo visível continua iniciando combate 3D. Critérios que diferenciam recrutáveis de inimigos e como funciona a interação ainda pendentes. Equipe ativa mantém máximo de protagonista + dois aliados IA.

**APROVADO (R23-Q5 = C):** resposta literal **“combinacao com mestres e possiveis personagens que dao hms”**. **Aprendizado combinado de Moves com mestres e possíveis personagens que concedem HMs**. **R24-Q4 = C aprovou posteriormente HMs e TMs somente para combate por enquanto**, sem uso em exploração. Permanecem pendentes fontes adicionais (nível, exploração, recompensas), função de cada HM/TM dentro do combate, formas de obtenção e ocupação de slots. Preservar Tackle genérico, ATB/Burst e ausência de PP.

**Foco:** priorizar perguntas futuras sobre experiência central do jogador, sem novas rodadas de microcasos técnicos.


### 7.15. Passagens, recrutamento, reservas e HMs/TMs — Rodada 24

**APROVADO (R24-Q1 = A):** **avançar ao próximo andar encontrando uma escada ou saída no mapa**, sem obrigação de derrotar todos os inimigos. O último andar e a vitória contra o chefe seguem necessários à conclusão (R23-Q2). Não fixar forma de geração ou localização dessas passagens.

**APROVADO (R24-Q2 = A):** **recrutamento de Pokémon elegível na exploração 2D exige interação voluntária explícita**. Simples aproximação não basta para recrutar. **Preservar R8-Q5:** contato hostil com inimigo visível inicia combate 3D. **PENDENTE:** elegibilidade e efeitos da interação.

**APROVADO (R24-Q3 = A):** **com a equipe ativa completa (três Pokémon), ainda é possível recrutar, enviando o novo Pokémon à reserva**. **PENDENTE:** limite, acesso, gestão e trocas. O máximo de três Pokémon ativos permanece intacto.

**APROVADO (R24-Q4 = C):** resposta literal **“hms e tms so para combate por ora”**. **HMs e TMs são exclusivamente para combate por enquanto**, não para superar obstáculos ou cumprir tarefas de exploração. Complementa mestres e possíveis personagens que concedem HMs (R23-Q5). **PENDENTE:** aquisição/ensino e função específica das HMs/TMs em combate, ocupação de slots, requisitos e exemplos. Não inventar PP, ATB/Burst ou papel de HMs/TMs na exploração.

**APROVADO (R24-Q5 = A):** **Pokémon recrutados na expedição continuam pertencendo ao jogador mesmo após derrota definitiva**; a derrota ainda encerra a exploração (R23-Q3). **PENDENTE:** destino na equipe/reserva e consequências para itens, níveis, experiência e outros recursos. Não generalizar a preservação dos Pokémon a todos os itens/progressos.

**Preservação:** nenhuma regra nova sobre custos de Moves, número de slots, PP ou fórmula. Esta é uma consolidação documental de cinco decisões de gameplay, não uma implementação.


### 7.16. Campanha, troca de equipe, evolução, itens e descobertas — Rodada 25

**APROVADO (R25-Q1 = A) — campanha:** a progressão geral segue **campanha com novas dungeons desbloqueadas por conquistas e objetivos**. **PENDENTE:** objetivos concretos, sequência, estrutura narrativa, desbloqueios e repetição de dungeons. Permanecem os requisitos de último andar e chefe por dungeon.

**APROVADO (R25-Q2 = C) — trocas provisórias e hub posterior:** resposta literal do criador **“A po ora, vou criar um hub pra isso depois masmais tarde”**. A referência expressa à alternativa **A por ora** permite **trocar Pokémon entre a equipe ativa e a reserva durante a exploração como comportamento provisório**, ainda com restrições não especificadas, mantendo **três ativos no máximo**. O criador pretende criar **um hub posteriormente**, mas **não aprovou agora a estrutura, funções ou a substituição futura das trocas pelo hub**. **PENDENTE:** mecânica definitiva de trocas, interface, disponibilidade da reserva e definição posterior do hub. Nenhum hub foi implementado por esta revisão.

**APROVADO (R25-Q3 = A) — evolução de espécie escolhida:** **a evolução de espécie fica disponível ao Pokémon depois que os requisitos forem atendidos, e o jogador escolhe quando realizá-la**. Não transformar a evolução em evento automático obrigatório. **PENDENTE:** requisitos por espécie, local/interface e demais efeitos. A distribuição manual de pontos do protagonista e o crescimento automático dos aliados seguem intactos.

**APROVADO (R25-Q4 = C) — derrota e itens segurados:** resposta literal **“apenas itens que estao sendo segurados nao sao perdidos”**. Em derrota definitiva, **dos itens obtidos na expedição, os que estiverem sendo segurados são preservados e os demais são perdidos**. **PENDENTE:** definição de segurar (sem presumir equivalência exata a equipado), regras para itens de posse anterior à expedição, disponibilidade de itens segurados e outras condições. Os Pokémon recrutados continuam pertencendo ao jogador após derrota (R24-Q5); não inferir perda de Pokémon.

**APROVADO (R25-Q5 = A) — prioridade do conteúdo procedural:** **priorizar eventos, salas secretas, recompensas especiais e NPCs** nas dungeons procedurais, além de inimigos e passagens já aprovados. **PENDENTE:** catálogo de eventos, papel dos NPCs, critérios de salas secretas, recompensas e distribuição por dungeon. Essa prioridade **não proíbe** armadilhas, desafios ambientais ou salas especiais de combate; esses elementos continuam sem prioridade específica aprovada nesta decisão.

**Preservação:** as decisões de R25 não definem fórmulas, valores de progressão, perdas de recursos não relacionados, PP, novos custos ATB/Burst, nem regras de TM/HM. Nenhum código ou hub foi implementado.


### 7.17. Escolha do protagonista, recrutamento especial e resultados da dungeon — Rodada 26

**APROVADO (R26-Q1 = A) — protagonista inicial:** o jogador **escolhe um Pokémon protagonista dentre espécies iniciais disponíveis**. **PENDENTE:** catálogo, apresentação da escolha e espécies elegíveis. A Nature do protagonista continua obedecendo suas próprias regras de sorteio (R17/R18), sem confundir Nature e espécie.

**APROVADO (R26-Q2 = B) — candidatos especiais:** **Pokémon normalmente hostis podem surgir em situações especiais como candidatos a recrutamento identificados no mapa 2D**, com requisitos/eventos ainda pendentes. Continua obrigatória a **interação voluntária explícita** para recrutamento (R24-Q2), e **contatos hostis normais iniciam combate 3D** (R8-Q5). Não permitir recrutamento automático por contato ou presumir que qualquer inimigo é candidato.

**APROVADO (R26-Q3 = A) — experiência:** **todos os Pokémon ativos participantes de batalha vencida recebem experiência**, **sem exigir participação no golpe final**. **PENDENTE:** valores e divisão de XP, elegibilidade de Pokémon incapacitados, Pokémon reservados, derrotas e demais exceções. Não estabelecer valores/fórmulas, não mudar o crescimento dos aliados nem os pontos manuais do protagonista.

**APROVADO (R26-Q4 = A) — conclusão de expedição:** ao **derrotar o chefe do último andar**, o jogador **encerra a expedição e retorna à seleção/progressão da campanha**, podendo prosseguir conforme os desbloqueios de campanha. **PENDENTE:** recompensas específicas, telas de resultado e regras concretas de desbloqueio; não criar hub automaticamente.

**APROVADO (R26-Q5 = A) — salas secretas:** salas secretas são **descobertas opcionais com recompensas, eventos e NPCs especiais**, **não necessárias para chegar ao chefe**. **PENDENTE:** catálogo, aparecimento, entrada, descoberta e recompensas. Não tornar sua exploração requisito de conclusão.

**Preservação:** todas as regras anteriores sobre ATB, Burst, MP, ausência de PP, limites de equipe, progressão manual/automática, Nature e condições de vitória/derrota permanecem aprovadas. Somente design documental foi acrescentado.


### 7.18. Fuga, composição inicial, ambientes, Moves e recompensas — Rodada 27

**APROVADO (R27-Q1 = A) — fuga:** o jogador **pode tentar fugir de combates comuns**. **APROVADO posteriormente (R28-Q3 = C):** na fuga bem-sucedida, retorna ao ponto do encontro e o inimigo fica imobilizado, sem poder se mover ou encostar no jogador por três segundos. **PENDENTE:** como pedir fuga, elegibilidade, chance, falha e chefes. Não acrescentar automaticamente comando novo ou custos ATB/Burst e não garantir sucesso.

**APROVADO (R27-Q2 = A) — início da aventura:** o jogador começa **apenas com o protagonista**, cuja espécie escolhe entre os iniciais (R26-Q1). **Companheiros são obtidos por recrutamento**, sem aliados concedidos automaticamente no início. Limite da equipe ativa: protagonista + dois aliados sob IA. Não mudar as regras dos recrutáveis especiais (R26-Q2).

**APROVADO (R27-Q3 = B) — variedade ambiental:** **uma dungeon pode combinar diferentes ambientes e alterar seu tema durante a mesma expedição**. **R28-Q4 = A complementou:** essas mudanças podem modificar tipos de inimigos, eventos e recompensas. **PENDENTE:** biomas concretos, distribuição e transições procedurais. Não exigir que toda dungeon tenha vários temas nem que todas as categorias mudem em cada transição.

**APROVADO (R27-Q4 = A) — aprendizado:** **Moves comuns são obtidos principalmente ao avançar de nível e pela progressão do Pokémon**, sem eliminar aprendizado combinado com mestres e possíveis personagens que concedem HMs (R23-Q5), nem HMs/TMs exclusivamente de combate por enquanto (R24-Q4). **PENDENTE:** catálogo de Moves por espécie, ritmo de aprendizado, requisitos e interface de troca/equipamento. Preservar quatro espaços equipados, Tackle separado, ausência de PP e custos ATB/Burst anteriores.

**APROVADO (R27-Q5 = C) — recompensas materiais de batalhas comuns:** resposta literal **“moedas recursos itens”**. **Moedas, recursos e itens constituem tipos de recompensa previstos para batalhas comuns**, além da experiência. A decisão **não exige** que cada vitória conceda as três categorias nem drop garantido. **R28-Q1 = A esclareceu:** moedas são usadas principalmente para **comprar itens e recursos de NPCs ou lojas**. **PENDENTE:** catálogo, preços, localização, taxas, quantidades e distribuição de recompensas.

**Preservação:** R27 não altera resultados de derrota, preservação de itens segurados, evolução, regras de equipe/reserva, HMs/TMs de combate nem ATB/Burst/MP/PP. A conclusão de dungeon segue vinculada ao último andar e ao chefe.


### 7.19. Comércio, itens segurados, fuga e biomas — Rodada 28

**APROVADO (R28-Q1 = A) — uso das moedas:** **moedas obtidas em batalhas servem principalmente para comprar itens e recursos com NPCs/lojas**. **PENDENTE:** onde e como funcionam os vendedores, catálogo e preços. Não inferir moeda nominal, fórmula econômica ou acesso obrigatório por hub.

**APROVADO (R28-Q2 = C) — modos de funcionamento de itens segurados:** resposta literal **“alguns funcionarao passivament e alguns funcionarao automaticamente sendo consumidos como berries”**. **Alguns itens segurados funcionam passivamente; outros são ativados automaticamente e consumidos, como berries**. **PENDENTE:** qual item pertence a qual grupo, gatilhos de ativação, efeitos e relação com as regras de itens utilizados via ITENS no combate. A preservação de **itens que ainda estejam sendo segurados** após derrota definitiva (R25-Q4) mantém-se. Não definir consumo automático como um novo custo ATB ou Burst.

**APROVADO (R28-Q3 = C) — fuga e proteção no mapa:** resposta literal **“retorna ao local de encontro e stunna o inimigo por um tempo, nao pemitindo que ele se mova e encoste em vc por 3 segundos”**. **Após fuga bem-sucedida de combate comum, o protagonista retorna ao local do encontro 2D, e o Pokémon inimigo daquele encontro fica imobilizado, incapaz de se mover e encostar no protagonista durante três segundos.** É uma regra aplicável à **fuga bem-sucedida**, não garantia de sucesso. **PENDENTE:** comando/condições de fuga, falha, chefes, implementação de colisão e comportamento após expirar o efeito; não atribuir efeito a outros inimigos sem aprovação. **Duração aprovada: 3 segundos**, único número adicional expressamente decidido nesta rodada.

**APROVADO (R28-Q4 = A) — impacto de biomas:** **mudanças de bioma dentro da dungeon podem alterar tipos de inimigos, eventos e recompensas disponíveis**. **PENDENTE:** quais biomas, tabelas e regras de variação. Não exigir mudanças compulsórias de todo o conteúdo sempre que o cenário mudar.

**APROVADO (R28-Q5 = A) — recompensa por conclusão:** **a principal recompensa de concluir uma dungeon é avançar na campanha e desbloquear novas dungeons**. Recompensas materiais adicionais são **opcionais e permanecem pendentes**. O encerramento após vencer o chefe e retorno à seleção/progressão da campanha (R26-Q4) seguem válidos. Não definir prêmios especiais garantidos.

**Preservação:** as decisões sobre fuga não criam novos custos ATB/Burst, imobilização de outros inimigos nem exceções automáticas para chefes. Mantêm-se Tackle, quatro Moves, ausência de PP, inventário e regras de perda de itens já aprovadas. Somente o GDD é alterado.


### 7.20. Comércio, eventos narrativos, revisitas, chefes e dificuldade — decisões da Rodada 29

**APROVADO (R29-Q1 = C):** resposta literal **“ambos”**. **Comerciantes e lojas podem existir dentro das dungeons e fora das expedições, na seleção/progressão da campanha**. O uso principal das moedas para comprar itens e recursos continua conforme R28-Q1. **PENDENTE:** localização, catálogo, preços, interface e disponibilidade. Não exigir hub já implementado.

**APROVADO (R29-Q2 = A):** **eventos especiais nas dungeons oferecem escolhas e situações narrativas com consequências para a exploração**. **PENDENTE:** decisões concretas, impactos e persistência futura. Preservar o conteúdo procedural e a prioridade de eventos/NPCs.

**APROVADO (R29-Q3 = A):** **permitir novas expedições às dungeons já concluídas**. A geração procedural ocorre por exploração/andar (R7-Q5), e a estabilidade do layout ao revisitar um andar vale **dentro da mesma exploração** (R9-Q2). A mesma seed, regras e versão de gerador continuam podendo reproduzir o mesmo layout (R8-Q3); nenhuma repetição exige obrigatoriamente mapa diferente. **PENDENTE:** recompensas, condições de acesso, escolha de seeds e variações.

**APROVADO (R29-Q4 = A):** **chefe principal pode enfrentar o jogador com outros inimigos de apoio**, preservando o máximo já aprovado de **três inimigos ativos ao mesmo tempo** (R7-Q4). **PENDENTE:** composição, mecânicas e escolha de quais chefes têm apoio. Não exigir apoio em todo confronto.

**APROVADO (R29-Q5 = A):** **dificuldade aumenta progressivamente conforme o jogador avança pelos andares e desbloqueia novas dungeons**. **PENDENTE:** tipos de desafio, curvas e escalonamento; não estabelecer fórmulas, níveis ou multiplicadores.

**Preservação:** D-001 a D-160, regras de seeds, equipe inimiga, campanha, ATB/Burst e ausência de PP permanecem intactas. Esta revisão não implementa código.


### 7.21. Retirada, eventos, chefes, expedições repetidas e recrutamento — Rodada 30

**APROVADO (R30-Q1 = A) — retirada voluntária da dungeon:** **o jogador pode encerrar voluntariamente uma expedição antes da vitória contra o chefe e voltar à campanha**. **PENDENTE:** como iniciar a retirada, se existem restrições e quais consequências se aplicam aos itens, progresso e Pokémon. **Não presumir que a retirada tem as mesmas penalidades de derrota definitiva** ou o mesmo efeito da fuga de um combate comum.

**APROVADO (R30-Q2 = A) — consequências dos eventos:** as **escolhas nos eventos narrativos afetam principalmente a exploração atual, sem exigir que persistam entre dungeons**. Mantêm-se eventos com opções e consequências reais (R29-Q2); **PENDENTE:** catálogo e efeitos concretos. Não impor decisões de campanha permanentes; também não proibir expressamente exceções futuras.

**APROVADO (R30-Q3 = B) — chefes dentro das regras usuais:** **chefes são principalmente oponentes mais difíceis no sistema de combate comum**, sem obrigação de fases ou mecânicas exclusivas. **R29-Q4 permanece válido:** podem receber apoio de outros inimigos, desde que **não ultrapassem três inimigos ativos**. **PENDENTE:** identidades, Moves, composição de encontros, escalonamento de dificuldade e possíveis exceções específicas, se aprovadas futuramente.

**APROVADO (R30-Q4 = A) — incentivo para repetir dungeons:** **novas expedições em dungeons já concluídas continuam oferecendo oportunidades de conseguir novos Pokémon, itens e recursos**. **PENDENTE:** catálogos, chances e condições. A decisão não garante recompensa a cada expedição nem revoga a geração procedural, a reprodução por seed ou a progressão de campanha previamente aprovadas.

**APROVADO (R30-Q5 = A) — Pokémon recém-recrutado com vaga:** **quando houver espaço entre os três Pokémon ativos, um novo recrutado pode integrar diretamente a equipe após o recrutamento bem-sucedido**. Isso não obriga entrada automática nem determina controles ou telas. **Com três ativos, mantém-se a possibilidade de enviar recrutados à reserva** (R24-Q3); reorganização da equipe durante a exploração continua provisória (R25-Q2). **PENDENTE:** interface, escolha do destino e condições específicas.

**Preservação:** R30 não cria fórmulas, PP, ATB/Burst adicionais, itens automaticamente perdidos na retirada ou regras novas de combate de chefes. São apenas decisões documentais; não representam implementação.


### 7.22. Itens na retirada, aliados após queda, XP, campanha e descanso — Rodada 31

**APROVADO (R31-Q1 = B) — itens após retirada voluntária:** **quando o jogador abandona voluntariamente uma dungeon, os itens coletados durante a expedição e que não estejam sendo segurados são perdidos; itens segurados são preservados**. Neste aspecto, a regra coincide com a perda de itens coletados na derrota definitiva (R25-Q4). **PENDENTE:** tratamento de itens anteriores à expedição, outros recursos e demais consequências da retirada. **Não converter retirada em derrota** nem mudar a preservação de Pokémon recrutados após derrota (R24-Q5).

**APROVADO (R31-Q2 = A) — continuidade do combate após queda do protagonista:** se o **protagonista cair em batalha 3D enquanto houver aliados capazes de lutar, a batalha continua com os aliados controlados pela IA**. **Complemento R32-Q1 = A:** com vitória dos aliados, o protagonista pode voltar à exploração mediante **recuperação mínima**, ainda sem condições ou quantidade aprovadas. **PENDENTE:** condição geral de derrota e procedimento de recuperação. Não atribuir controle direto dos aliados nem recuperação completa automática.

**APROVADO (R31-Q3 = B) — experiência dos Pokémon reservados:** **experiência de vitórias em combate somente para Pokémon ativos participantes**, conforme R26-Q3. Pokémon na reserva **não recebem experiência dessas vitórias enquanto reservados**; evolução/treinamento dos reservados por outros meios **ainda será definido**. Não fixar XP, método de treinamento ou curva.

**APROVADO (R31-Q4 = A) — objetivos da campanha:** **NPCs, personagens e acontecimentos narrativos são o principal meio de apresentar missões e objetivos de desbloqueio de novas dungeons**. **PENDENTE:** conteúdo, objetivos concretos, requisitos de desbloqueio e como acompanhar o progresso. O comércio fora da dungeon (R29-Q1) e o hub futuro (R25-Q2) não são transformados em dependências obrigatórias.

**APROVADO (R31-Q5 = A) — locais de descanso seguros:** **os pontos de descanso são lugares seguros para pausa e preparação dentro das dungeons**, e a restauração completa de MP nesses pontos permanece válida. **R32-Q2 = A aprovou também recuperação de HP**, com quantidade e regras ainda não definidas. **PENDENTE:** demais serviços, acesso, segurança concreta. Não presumir cura integral de HP, novos custos, lojas ou trocas de equipe no descanso.

**Preservação:** as cinco decisões refinam sistemas existentes sem alterar os 170 registros anteriores, a economia ATB/Burst/MP, os limites de equipe ou a ausência de PP. Nenhuma funcionalidade foi implementada no código por esta atualização.


### 7.23. Recuperação, progressão preservada, mapa e recrutamento — Rodada 32

**APROVADO (R32-Q1 = A) — retorno do protagonista:** **após os aliados IA vencerem a batalha em que o protagonista caiu, ele pode voltar à exploração mediante recuperação mínima**. **PENDENTE:** forma, momento, condição, valor e demais efeitos da recuperação. Não inferir HP total, controle dos aliados ou derrota definitiva pela queda do protagonista; R31-Q2 continua válido.

**APROVADO (R32-Q2 = A) — descanso cura HP:** **pontos seguros de descanso recuperam HP e restauram MP**. A recuperação de **MP é integral por regras anteriores**; a de **HP tem quantidade e condições ainda pendentes**. Não presumir que HP seja restaurado completamente nem aplicar esse benefício a locais que não sejam pontos de descanso.

**APROVADO (R32-Q3 = A) — manter progresso em derrotas e retiradas:** **experiência e níveis adquiridos ao longo de uma expedição permanecem com os Pokémon após derrota definitiva ou retirada voluntária**, mesmo que não vençam o chefe. **As perdas já aprovadas de itens coletados e não segurados continuam valendo** para esses desfechos; nenhuma nova política de moedas/recursos é decidida. XP de combate continua restrita aos Pokémon ativos participantes (R31-Q3).

**APROVADO (R32-Q4 = A) — revelação de exploração:** **o mapa do andar é revelado gradualmente à medida que o jogador percorre a dungeon**. **PENDENTE:** interface, grau de revelação, visibilidade de áreas não visitadas e persistência do mapa descoberto entre expedições. Permanecem geração por seed e layout persistente ao revisitar andares na mesma exploração.

**APROVADO (R32-Q5 = B) — recrutamento especial por tarefa:** **ao interagir voluntariamente com um Pokémon especial elegível, inicia-se uma tarefa/evento que deve ser resolvido antes de recrutá-lo**. **PENDENTE:** tipos de tarefas, objetivos, condições de sucesso, consequências e apresentação. Essa regra aplica-se aos **candidatos especiais** e não torna obrigatória uma missão para todo recrutamento nem substitui o início de combate ao tocar inimigos hostis normais.

**Preservação:** permanecem integralmente válidas as decisões D-001 a D-175, o máximo de três Pokémon ativos, a reserva, o sistema de combate, custos de ATB/Burst, a inexistência de PP, a geração procedural e as regras previamente aprovadas de perda de itens.

## 8. Estado real do repositório (inspeção de código, não de execução)

Referência: `main` em `1171b5f3c427edc34c486c82d42569f41fd0ea62`. Projeto **Godot 4.7**, configurado em `project.godot`, com cena inicial 2D.

| Caminho | Evidência no código consultado | Diferença para este GDD |
| --- | --- | --- |
| `scripts/combat/combatant.gd` | Medidor contínuo de `0.0` a `100.0`, preenchido por `speed * delta`; `ready_to_act` ao chegar a 100; `end_turn()` zera a barra. | **Não implementa** cinco blocos consumíveis, custos variáveis ou recompensas instantâneas. |
| `scripts/combat/battle.gd` | Loop ATB básico; pausa o avanço quando há personagem jogador aguardando comando; inimigo usa ataque simples. | **Não implementa** Evade, Burst, fraquezas, críticos, custos por ação ou IA de aliados conforme o GDD. |
| `scripts/combat/battle_scene.gd` | Batalha 3D com atores de exemplo (“Herói”, “Mago”, “Slime”, “Goblin”), modelos cápsula e botões simples de ataque. | Ainda não utiliza os mesmos Pokémon representados em 2D/3D, nem o menu FIGHT/ITENS/Tactic/Evade. |
| `scenes/battle.tscn` | Cena Node3D com câmera, iluminação e UI básica. | Apenas fundação de arena. |
| `scripts/dungeon/exploration.gd` e `scripts/dungeon/player.gd` | Mapa 2D ASCII com paredes, encontros e jogador desenhado como círculo. | Ainda não representa o mundo e os Pokémon no formato final. |
| `scripts/autoload/game_state.gd` | Transição entre cenas, posição do jogador e registro de inimigos derrotados. | Existe integração preliminar, sem sistemas completos de progressão. |
| `README.md` | Descreve o protótipo ATB, exploração 2D e combate 3D; instrui abrir no Godot 4.7+. | É uma descrição do protótipo, não das decisões completas deste GDD. |

**Escopo desta revisão:** consulta aos arquivos de código e configuração principais; **não houve execução do Godot, testes automatizados ou modificação de scripts**.

## 9. Registro de decisões aprovadas

As IDs abaixo identificam regras vigentes, não implementações. A fonte é a sequência de decisões do criador na conversa de concepção anterior a esta revisão.

| ID | Decisão aprovada |
| --- | --- |
| D-001 | Protagonista é um Pokémon controlado pelo jogador. |
| D-002 | Dungeon em exploração 2D, inspirada em Mystery Dungeon. |
| D-003 | Batalhas em cena/arena 3D separada usando modelos 3D dos mesmos Pokémon. |
| D-004 | **Registro histórico parcialmente superado por D-029:** aliados agem por IA; o texto anterior previa ordens ou mudanças de comportamento por Tactic. **D-029 exclui ordens diretas** e preserva apenas orientação da IA. |
| D-005 | Menu: FIGHT, ITENS, Tactic, Evade. |
| D-006 | FIGHT inclui Tackle físico genérico, além de quatro Moves selecionáveis. |
| D-007 | ITENS serve para utilizar consumíveis. |
| D-008 | Evade ativo é reação durante ataque inimigo. |
| D-009 | ATB individual de cinco blocos preenchidos com o tempo. |
| D-010 | Ações consomem blocos; maioria custo 2, Evade custo 3, certos ataques custo 5. |
| D-011 | Ação fica disponível ao possuir saldo suficiente para seu custo; não exige sempre 5/5. |
| D-012 | Fraqueza, crítico e esquiva concedem recompensas instantâneas de +1 ou +2 blocos, não aumento de taxa. |
| D-013 | Recompensa ATB é individual e se aplica também a inimigos. |
| D-014 | Evasão automática bem-sucedida concede ATB, nunca Burst. |
| D-015 | Evade ativo bem-sucedido concede recompensa ATB e abre Burst imediato. |
| D-016 | Evade ativo malsucedido impede evasão passiva e garante acerto do golpe, salvo imunidades/proteções; não concede bônus de esquiva nem Burst. |
| D-017 | Burst é bloco especial independente dos cinco normais, com uso imediato após Evade ativo bem-sucedido. |
| D-018 | Burst especial pode buffar aliados, debuffar inimigos ou executar Move escolhido com crítico. |
| D-019 | Crítico garantido pelo Burst ofensivo não oferece recompensa ATB por crítico. |
| D-020 | Alguns ataques dependem de Burst para execução; requisitos detalhados pendentes. |
| D-021 | R1-Q1 = B: Burst fica disponível imediatamente após Evade ativo bem-sucedido, mas pode ser usado na hora **ou armazenado**; prazo, capacidade e custos de uso futuro seguem pendentes. |
| D-022 | R1-Q2 = A: após uma ação, subtrair apenas os blocos consumidos e preservar o saldo ATB restante. |
| D-023 | R1-Q3 = C: **somente durante escolhas de Tactic** o combate pausa; escolhas em FIGHT e ITENS não pausam o combate. |
| D-024 | R1-Q4: fraqueza +1, crítico normal +2, evasão automática +2 e Evade ativo bem-sucedido +1 (ATB individual instantâneo). |
| D-025 | R1-Q5 = A: um golpe normalmente crítico e super efetivo soma +2 e +1, total +3 ATB, sujeito à regra futura para excedentes. |
| D-026 | R2-Q1 = A: Burst armazenado dura até uso **na batalha atual** e não é levado à próxima; capacidade ainda não definida. |
| D-027 | R2-Q2 = C: recompensas além de 5 blocos conservam **blocos ATB extras separados**, que não ocupam os cinco espaços normais nem são Burst e podem viabilizar ações adicionais. Teto, exibição e prioridade de gasto pendentes. |
| D-028 | R2-Q3 = B: Move executado com Burst consome **bloco Burst + custo ATB normal do Move**; ambas as condições precisam estar disponíveis. |
| D-029 | R2-Q4 = C: **Tactic não envia ordens diretas; somente orienta/configura a IA dos aliados**. Substitui a parte referente a ordens do registro D-004. Custo de configuração pendente. |
| D-030 | R2-Q5 = A: Velocidade individual do Pokémon determina a taxa temporal de preenchimento do ATB; fórmula pendente. |
| D-031 | R3-Q1 = B: é permitido armazenar **vários blocos Burst, sem limite fixo**, até o uso ou término da batalha. O termo “sexto bloco” não restringe estoque a um. |
| D-032 | R3-Q2 = A: ao pagar ações, **gastar primeiro ATB extra**, e só então os blocos normais se necessário. |
| D-033 | R3-Q3 = A: **Tactic não consome ATB**, pois apenas configura/orienta a IA; exceção explícita ao custo das ações. Mantém a pausa da seleção de Tactic. |
| D-034 | R3-Q4 = A: preenchimento natural para em 5 blocos normais; **somente recompensas por ações** geram blocos ATB extras. |
| D-035 | R3-Q5 = B: **Move executado via Burst não recompensa ATB por fraqueza nem por crítico garantido**, exceção às regras de recompensa de golpes normais. |
| D-036 | R4-Q1 = A: blocos ATB extras **sem teto fixo durante a batalha**; persistência entre batalhas permanece pendente. |
| D-037 | R4-Q2 = A: ATB extras exibidos como **quadradinhos adicionais contíguos aos cinco normais**, visualmente distintos do ATB comum e do Burst. |
| D-038 | R4-Q3 = A: **Evade desconta três ATB na ativação**, em sucesso ou falha; extras são consumidos primeiro conforme D-032. |
| D-039 | R4-Q4 = A: **Tackle genérico custa 2 blocos ATB**, além dos quatro Moves equipados do FIGHT. |
| D-040 | R4-Q5 = A: **IA dos aliados decide autonomamente tentar Evade ativo**, conforme situação e ATB; Tactic pode influenciar a prioridade sem enviar ordens diretas. |
| D-041 | R5-Q1 = A: **todos os blocos ATB extras são descartados ao término de cada batalha**; início dos cinco blocos normais na próxima batalha pendente. |
| D-042 | R5-Q2 = B: ataques normais multi-alvo recompensam **no máximo uma vez por fraqueza e uma por crítico normal por ação inteira**, sem multiplicar por alvos. |
| D-043 | R5-Q3 = B: em multi-hit normal, **uma recompensa de fraqueza e uma de crítico normal no máximo por execução e alvo**; em multi-alvo também vale o teto global por ação de D-042. |
| D-044 | R5-Q4 = B: **buff/debuff via Burst custa só um bloco Burst**, sem ATB comum/extra; Move ofensivo mantém Burst + custo ATB próprio. |
| D-045 | R5-Q5 = B: **orientações de Tactic persistem entre encontros da mesma dungeon até alteração**; persistência após sair da dungeon pendente. |
| D-046 | R6-Q1 = A: **todos os Pokémon (protagonista, aliados e inimigos) começam cada batalha com 0/5 ATB normal**. Velocidade afeta a taxa de preenchimento após o começo. |
| D-047 | R6-Q2 = C (“1”): **cada uso de item em combate custa 1 bloco ATB**; navegar no menu não pausa e não determina por si consumo de item. |
| D-048 | R6-Q3 = A: **equipe ativa de até 3 Pokémon**: protagonista controlado pelo jogador e até dois aliados sob IA. |
| D-049 | R6-Q4 = C: **configuração de Tactic** oferece reiniciar orientações ao sair da dungeon **ou** preservá-las entre dungeons; **o valor padrão não foi escolhido**. Mantém persistência durante a dungeon. |
| D-050 | R6-Q5 = A: **custo-base dos quatro Moves equipados é 2 ATB**, com exceções Move a Move, inclusive custo 5 e necessidade de Burst; não inventar lista de exceções. |
| D-051 | R7-Q1 = A: **opção padrão de persistência de Tactic = reiniciar orientações ao sair da dungeon**; opção de preservar entre dungeons permanece disponível. A orientação de IA padrão ainda é pendente. |
| D-052 | R7-Q2 = A: **tempo-base de 5 segundos para ATB 0/5 → 5/5 na Velocidade de referência**. Valor da Velocidade de referência e fórmula de escala ainda pendentes. |
| D-053 | R7-Q3 = B: **os quatro Moves equipados não utilizam PP**, gastando ATB e Burst quando aplicável. PP de Tackle não foi decidido. |
| D-054 | R7-Q4 = A: **até 3 Pokémon inimigos ativos simultaneamente** em cada batalha; reservas e reforços não definidos. |
| D-055 | R7-Q5 = A: **exploração 2D em dungeons geradas proceduralmente por exploração/andar**, baseadas em salas e corredores; algoritmo, seeds e demais parâmetros pendentes. |
| D-056 | R8-Q1 = A: **tempo de ATB inversamente proporcional à Velocidade**; dobrar Velocidade reduz o tempo pela metade. Valor de referência e limites permanecem pendentes. |
| D-057 | R8-Q2 = C: **não existe PP no Crawlmon, inclusive para Tackle**. Encerra as pendências históricas sobre PP de Tackle surgidas após D-053. Consumo de recursos se dá por ATB e, quando aplicável, Burst. |
| D-058 | R8-Q3 = A: **seed registrável e reutilizável reproduz o mesmo layout procedural**, sob as mesmas regras e versão do gerador. UX e persistência de eventos pendentes. |
| D-059 | R8-Q4 = A: **salas e corredores procedurais construídos algoritmicamente**, com formas, posições e conexões geradas; parâmetros específicos pendentes. |
| D-060 | R8-Q5 = A: **inimigos Pokémon visíveis no mapa 2D**; contato/colisão inicia a batalha 3D. Comportamento dos inimigos no mapa pendente. |
| D-061 | R9-Q1 = C: **não definir ainda o valor numérico da Velocidade de referência**; primeiro especificar os atributos (*status*) do jogo. Nenhuma das opções 50/100 foi aprovada. |
| D-062 | R9-Q2 = A: **preservar o layout de um andar procedural já visitado nas revisitas durante a mesma exploração**; estado de itens e eventos segue pendente. |
| D-063 | R9-Q3 = A: inimigos **visíveis patrulham e perseguem após detectar o protagonista**, sem regras numéricas de detecção já aprovadas. Combate continua por contato. |
| D-064 | R9-Q4 = A: ao vencer, **remover o inimigo visível derrotado do andar durante a exploração atual**, inclusive em revisitas; exceções para eventos especiais não especificados. |
| D-065 | R9-Q5 = B: protagonista se move na exploração 2D em **quatro direções cardeais, sem movimento diagonal direto**; deslocamento contínuo vs. tile/turno pendente. |
| D-066 | R10-Q1 = C: **usar como referência o catálogo de atributos de SMT III: Nocturne** (Força, Magia, Vitalidade, Agilidade e Sorte); adaptação da Velocidade do ATB, HP e eventuais recursos ainda pendente. |
| D-067 | R10-Q2 = A: **atributos-base em escala 1–100**, antes de progressão/modificadores; não define os valores individuais nem fórmulas. |
| D-068 | R10-Q3 = A: **Pokémon têm níveis e atributos evoluem conforme o nível**, sem nível máximo ou curva numérica definidos. |
| D-069 | R10-Q4 = A: **buffs/debuffs modificam atributos por estágios discretos**; valores, limites, acumulação e duração pendentes. |
| D-070 | R10-Q5 = A: **Velocidade de referência do ATB será um valor numérico fixo comum**, determinado posteriormente na escala aprovada; não escolher valor nesta rodada. |
| D-071 | R11-Q1 = A: **Agilidade de SMT3 e Velocidade usada pelo ATB são o mesmo atributo**; nomenclatura visual, valor de referência e demais efeitos ainda pendentes. |
| D-072 | R11-Q2 = A: **HP máximo deriva de Vitalidade e nível**, sem atributo-base HP independente; fórmula e valores pendentes. |
| D-073 | R11-Q3 = B: **Magia influencia dano e efeitos mágicos e existe recurso MP separado**; custos, limites e recuperação de MP pendentes; MP não é PP e não altera automaticamente ATB/Burst. |
| D-074 | R11-Q4 = B: **o jogador distribui manualmente pontos de atributo ao subir de nível**; quantidade, restrições e aplicação aos aliados ainda pendentes. |
| D-075 | R11-Q5 = A: **Sorte influencia probabilidades de combate**, incluindo crítico e/ou outros efeitos ainda a especificar; sem fórmula numérica aprovada. |
| D-076 | R12-Q1 = A: **todos os Moves mágicos/especiais gastam MP adicional aos custos ATB/Burst aplicáveis**; custos individuais de MP ainda pendentes, sem criar PP. |
| D-077 | R12-Q2 = A: **MP máximo deriva de Magia e nível**; fórmula e valores não aprovados. |
| D-078 | R12-Q3 = B: **MP restante persiste entre batalhas da mesma dungeon**; recuperação e comportamento fora da dungeon pendentes. |
| D-079 | R12-Q4 = A: **cada nível concede quantidade fixa de pontos de atributo**, cujo número ainda não foi escolhido. |
| D-080 | R12-Q5 = B: **somente o protagonista tem pontos de atributos distribuídos manualmente pelo jogador**; aliados crescem automaticamente conforme regras futuras. Esclarece o escopo de D-074. |
| D-081 | R13-Q1 = A: **MP tem custo-base comum para Moves mágicos/especiais com exceções individuais**, sem valores definidos; preservar ATB/Burst e ausência de PP. |
| D-082 | R13-Q2 = B: **MP recuperável por consumíveis e pontos de descanso/recuperação na dungeon**, detalhes pendentes. |
| D-083 | R13-Q3 = A: **MP restaurado ao máximo no início de nova exploração**; persiste entre combates da mesma dungeon (D-078). |
| D-084 | R13-Q4 = A: **protagonista recebe 1 ponto de atributo distribuível por nível**; distribuição manual exclusiva do protagonista. |
| D-085 | R13-Q5 = A: **crescimento automático de aliados por curvas específicas de espécie**, valores e fórmulas pendentes. |
| D-086 | R14-Q1 = A: **MP descontado na ativação do Move mágico/especial**; reembolso/cancelamento pendentes. |
| D-087 | R14-Q2 = C e A também: **1/4 do MP a cada 3 s com cinco blocos ATB normais cheios**, base e temporização pendentes, **e descanso restaura MP completo**. |
| D-088 | R14-Q3 = A: **HP restante persiste entre batalhas da mesma dungeon** até recuperação. |
| D-089 | R14-Q4 = B: **ponto de atributo do protagonista distribuído obrigatoriamente na subida de nível** antes de concluir progressão. |
| D-090 | R14-Q5 = C: **crescimento dos aliados conforme forma de lutar/táticas, com atributos-base; comportamento aleatório de recrutáveis e Natures**; complementa curvas por espécie (D-085), fórmulas pendentes. |
| D-091 | R15-Q1 = A: **recuperação por ATB 5/5 de 1/4 (25%) do MP máximo por intervalo de 3 s**; arredondamento pendente. |
| D-092 | R15-Q2 = A: **exigir 3 s consecutivos em ATB 5/5; ao sair de 5/5, zerar cronômetro**; pausa Tactic ainda pendente. |
| D-093 | R15-Q3 = A: **crescimento dos aliados depende conjuntamente de tática selecionada e ações efetivamente executadas**; ponderações/fórmulas pendentes. |
| D-094 | R15-Q4 = B: **Natures afetam atributos, crescimento e tendências de comportamento/tática**; detalhes pendentes. |
| D-095 | R15-Q5 = B: **tática inicial de recrutáveis aleatórios sorteada entre opções associadas à Nature**; lista e probabilidades pendentes. |
| D-096 | R16-Q1 = B: **recuperação periódica de 25% do MP máximo arredondada para baixo** por intervalo elegível. |
| D-097 | R16-Q2 = A: **contador zerado com MP máximo**; quando MP faltar com ATB 5/5, novo ciclo de 3 s. |
| D-098 | R16-Q3 = C: **telemetria de desempenho considera maioria das ações de combate** para crescimento; janela, métricas e fórmulas pendentes, mantendo tática e ações como influências conjuntas. |
| D-099 | R16-Q4 = A: **Nature sorteada na geração do recrutável aleatório e mantida** antes/depois do recrutamento. |
| D-100 | R16-Q5 = B: **Tactic escolhida prevalece integralmente sobre o comportamento enquanto ativa**; Nature permanece influenciando atributos/crescimento. |
| D-101 | R17-Q1 = B: **telemetria considera histórico acumulado das ações de combate do Pokémon entre níveis**; ponderação/persistência futura pendentes. |
| D-102 | R17-Q2 = A: **frequência das categorias de ações executadas define predominância**, sem exigir sucesso. |
| D-103 | R17-Q3 = B: **tática selecionada tem influência principal no crescimento**, com telemetria ajustando conforme ações reais; pesos pendentes. |
| D-104 | R17-Q4 = C (“o jogo é um roguelike dungeon crawler, entao B”): **Nature sorteada também na geração de protagonista e Pokémon de eventos**, conforme regra B expressamente indicada. |
| D-105 | R17-Q5 = A: **contador de recuperação de MP pausa com o menu Tactic**, retomando se requisitos válidos. |
| D-106 | R18-Q1 = A: **histórico acumulado da telemetria acompanha o mesmo Pokémon entre dungeons/explorações** e níveis; retenção e pesos pendentes. |
| D-107 | R18-Q2 = A: **categorias amplas na telemetria: ataques físicos e mágicos/especiais, defesa/esquiva, suporte e itens**, detalhamento pendente. |
| D-108 | R18-Q3 = A: **uma execução de Move conta uma única ação na telemetria**, independentemente de hits/alvos; não altera recompensas ATB multi-hit/multi-alvo. |
| D-109 | R18-Q4 = A: **Nature do protagonista sorteada novamente no início de cada nova exploração**, probabilidades pendentes; não estender reroll a aliados/eventos ou presumir reset de progressão. |
| D-110 | R18-Q5 = A: **Natures modificam atributos-base**, além do crescimento/comportamento já aprovados; atributos, limites e valores ainda pendentes. |
| D-111 | R19-Q1 = A: **Pokémon aliado que sai e retorna à equipe preserva seu histórico individual de telemetria**, inclusive os registros anteriores à saída. |
| D-112 | R19-Q2 = C — “no maxim duas categorias”: **no máximo duas categorias de telemetria por ação**, preservando uma execução como uma ação, mesmo em multi-hit/multi-alvo; escolha e frequência de categorias pendentes. |
| D-113 | R19-Q3 = A: **registrar na telemetria ao começar efetivamente a execução**, ainda que falhe ou seja interrompida; comando que não iniciou a execução não conta; cobranças ATB/MP/Burst inalteradas. |
| D-114 | R19-Q4 = A: **ao sortear nova Nature do protagonista, preservar pontos de atributos já distribuídos e substituir apenas os efeitos de Nature**, recomposição numérica pendente. |
| D-115 | R19-Q5 = B: **Natures admitem bônus e penalidades flexíveis em atributos-base, sem exigir um par positivo/negativo**; catálogo, atributos e valores pendentes. |
| D-116 | R20-Q1 = A: quando houver mais de duas categorias possíveis, **selecionar até duas categorias principais previamente definidas na ficha da ação/Move**; critérios de prioridade pendentes. |
| D-117 | R20-Q2 = A: **uma ação classificada em duas categorias soma uma ocorrência de frequência em cada categoria**, mantendo uma única ação/execução; sem novos pesos ou fórmulas. |
| D-118 | R20-Q3 = A: **fora da equipe, preservar a telemetria do Pokémon sem acumular novas ações até seu retorno**; histórico anterior mantido. |
| D-119 | R20-Q4 = A: **quando a nova Nature mudar o HP/MP máximo do protagonista, preservar a proporção do valor atual em relação ao máximo anterior**; arredondamento/casos-limite pendentes. |
| D-120 | R20-Q5 = A: **permitir Natures neutras, sem modificadores diretos nos atributos-base**, mantendo possíveis efeitos em crescimento/comportamento; catálogo pendente. |
| D-121 | R21-Q1 = A: **prioridade das categorias definida em ordem específica na ficha de cada ação/Move**, classificação concreta pendente; teto de duas categorias mantido. |
| D-122 | R21-Q2 = A: **item com efeito de suporte classificado somente na categoria uso de itens**, sem categoria de suporte na telemetria; efeitos e custos inalterados. |
| D-123 | R21-Q3 = B: **tática selecionada desempata categorias de igual frequência predominante**, segundo critérios futuros. |
| D-124 | R21-Q4 = A: **arredondar para baixo HP/MP atual proporcional** depois de mudança dos máximos por Nature, respeitando os novos máximos; casos-limite pendentes. |
| D-125 | R21-Q5 = A: **Natures neutras nos atributos-base podem afetar crescimento e/ou tendências comportamentais**, regras pendentes. |
| D-126 | R22-Q1 = A: **registrar as categorias previstas na ficha do Move no início efetivo da execução**, mesmo que algum componente não ocorra; até duas categorias e uma ação por execução, sem exigir sucesso. |
| D-127 | R22-Q2 = A: **classificação e prioridade da telemetria definidas por tipo de ação**, incluindo defesa/esquiva, itens e outros; regras concretas pendentes, preservando a exceção de item+suporte como somente item. |
| D-128 | R22-Q3 = A: **usar a tática selecionada no momento da subida de nível para desempatar categorias de telemetria**, com associações de categorias por tática pendentes. |
| D-129 | R22-Q4 = A: **se HP era positivo e arredondamento proporcional por Nature resultaria em zero, preservar HP mínimo positivo**; valor e casos-limite pendentes. |
| D-130 | R22-Q5 = A: **atributo-base após modificadores de Nature permanece na escala 1–100**; procedimento de aplicação dos limites pendente. |
| D-131 | R23-Q1 = A: **movimento contínuo livre em quatro direções cardeais na exploração 2D**, sem diagonal direta. |
| D-132 | R23-Q2 = A: **concluir dungeon exige alcançar último andar e vencer chefe**. |
| D-133 | R23-Q3 = A: **derrota definitiva em batalha encerra exploração atual**; consequências sobre itens/progresso pendentes. |
| D-134 | R23-Q4 = B: **recrutamento durante exploração 2D por interação/aproximação**; preservar R8-Q5 para encontros hostis; condições pendentes. |
| D-135 | R23-Q5 = C — “combinacao com mestres e possiveis personagens que dao hms”: **aprendizado combinado de Moves com mestres e possíveis personagens de HMs**; função/fonte detalhada pendentes. |
| D-136 | R24-Q1 = A: **avançar de andar por escada/saída encontrada no mapa**, sem derrotar todos os inimigos. |
| D-137 | R24-Q2 = A: **recrutamento de Pokémon elegível exige interação voluntária explícita**, sem revogar combate por contato com inimigo hostil. |
| D-138 | R24-Q3 = A: **recrutar com três Pokémon ativos e enviar o novo recrutado à reserva**, limites e gestão pendentes. |
| D-139 | R24-Q4 = C — “hms e tms so para combate por ora”: **HMs e TMs exclusivamente para combate por enquanto**, sem exploração. |
| D-140 | R24-Q5 = A: **Pokémon recrutados permanecem pertencendo ao jogador após derrota definitiva da expedição**, demais consequências pendentes. |
| D-141 | R25-Q1 = A: **campanha com novas dungeons desbloqueadas por conquistas e objetivos**, detalhes de progressão pendentes. |
| D-142 | R25-Q2 = C — “A po ora, vou criar um hub pra isso depois masmais tarde”: **A provisoriamente**, permitir troca equipe ativa/reserva durante exploração; hub planejado para depois, sem regra definitiva ou implementação. |
| D-143 | R25-Q3 = A: **evolução de espécie disponível após requisitos e realizada quando o jogador escolher**, requisitos e demais efeitos pendentes. |
| D-144 | R25-Q4 = C — “apenas itens que estao sendo segurados nao sao perdidos”: **itens obtidos na expedição só são preservados após derrota se estiverem sendo segurados; demais itens obtidos nela são perdidos**, outros casos pendentes. |
| D-145 | R25-Q5 = A: **priorizar eventos, salas secretas, recompensas especiais e NPCs em dungeons procedurais**, sem excluir outros conteúdos. |
| D-146 | R26-Q1 = A: **escolher espécie do protagonista entre Pokémon iniciais disponíveis**, catálogo e apresentação pendentes; Nature separada. |
| D-147 | R26-Q2 = B: **Pokémon normalmente hostis podem aparecer em eventos especiais como candidatos marcados no mapa 2D para recrutamento**, exigindo interação voluntária; encontros hostis normais continuam iniciando combate. |
| D-148 | R26-Q3 = A: **todos os Pokémon ativos participantes de batalha vencida recebem XP, sem exigir golpe final**, valores e casos especiais pendentes. |
| D-149 | R26-Q4 = A: **vencer chefe encerra expedição e retorna à seleção/progressão da campanha**, recompensas/desbloqueios pendentes, sem exigir hub. |
| D-150 | R26-Q5 = A: **salas secretas opcionais para recompensas, eventos e NPCs especiais**, não obrigatórias para alcançar o chefe. |
| D-151 | R27-Q1 = A: **permitir tentar fuga de combates comuns**, elegibilidade/consequências pendentes; chefes indefinidos. |
| D-152 | R27-Q2 = A: **começar a aventura apenas com o protagonista**, obtendo companheiros por recrutamento; limite de três ativos preservado. |
| D-153 | R27-Q3 = B: **mesma dungeon pode misturar ambientes e mudar de tema durante a expedição**, detalhes pendentes. |
| D-154 | R27-Q4 = A: **Moves comuns obtidos principalmente por nível e progressão**, sem excluir mestres, HMs/TMs e outros meios. |
| D-155 | R27-Q5 = C — “moedas recursos itens”: **moedas, recursos e itens previstos como tipos de recompensas de batalhas comuns**, sem afirmar drops garantidos ou valores. |
| D-156 | R28-Q1 = A: **moedas usadas principalmente para comprar itens e recursos de NPCs/lojas**, preços e catálogo pendentes. |
| D-157 | R28-Q2 = C — “alguns funcionarao passivament e alguns funcionarao automaticamente sendo consumidos como berries”: **itens segurados podem ser passivos ou ativados automaticamente e consumidos**, exemplos como berries; efeitos/gatilhos pendentes. |
| D-158 | R28-Q3 = C — “retorna ao local de encontro e stunna o inimigo por um tempo, nao pemitindo que ele se mova e encoste em vc por 3 segundos”: **fuga bem-sucedida retorna ao local do encontro e imobiliza o inimigo, impedindo movimento/contato por 3 segundos**. |
| D-159 | R28-Q4 = A: **biomas diferentes podem alterar inimigos, eventos e recompensas**, catálogos e distribuição pendentes. |
| D-160 | R28-Q5 = A: **concluir dungeon prioriza progresso da campanha/desbloqueios**, prêmios materiais adicionais opcionais e pendentes. |
| D-161 | R29-Q1 = C — “ambos”: **NPCs/lojas tanto dentro das dungeons quanto fora das expedições, na seleção/progressão da campanha**, detalhes pendentes. |
| D-162 | R29-Q2 = A: **eventos com escolhas e consequências narrativas para exploração**, conteúdo concreto pendente. |
| D-163 | R29-Q3 = A: **novas expedições a dungeons já concluídas**, sem revogar geração por exploração, persistência do andar na expedição e seed reproduzível. |
| D-164 | R29-Q4 = A: **chefe principal pode contar com apoio de inimigos**, até três inimigos ativos simultâneos. |
| D-165 | R29-Q5 = A: **dificuldade crescente por andares e desbloqueio de novas dungeons**, sem números aprovados. |
| D-166 | R30-Q1 = A: **permitir retirada voluntária de dungeon antes do chefe, retornando à campanha**, consequências pendentes; não equiparar automaticamente à derrota. |
| D-167 | R30-Q2 = A: **efeitos de eventos narrativos principalmente durante a exploração atual, sem persistência obrigatória entre dungeons**, eventos concretos pendentes. |
| D-168 | R30-Q3 = B: **chefes principalmente mais difíceis dentro das regras comuns de combate, sem fases/mecânicas exclusivas obrigatórias**, podendo ter apoio até três inimigos ativos. |
| D-169 | R30-Q4 = A: **novas expedições em dungeons concluídas continuam dando oportunidades de obter Pokémon, itens e recursos**, condições pendentes. |
| D-170 | R30-Q5 = A: **novo Pokémon pode entrar diretamente na equipe ativa se houver vaga após recrutamento**, até três ativos; com equipe completa mantém-se a reserva. |
| D-171 | R31-Q1 = B: **na retirada voluntária, itens coletados na expedição e não segurados são perdidos; itens segurados mantidos**, sem igualar todas as consequências de retirada e derrota. |
| D-172 | R31-Q2 = A: **queda do protagonista não encerra batalha enquanto aliados capazes de lutar continuarem sob IA**, condições de vitória/recuperação pendentes. |
| D-173 | R31-Q3 = B: **XP de vitórias restrita aos participantes ativos; Pokémon reservados não a recebem por estarem na reserva**, outros meios de progressão pendentes. |
| D-174 | R31-Q4 = A: **objetivos e missões da campanha apresentados principalmente por personagens, NPCs e acontecimentos narrativos**, catálogo e sequência pendentes. |
| D-175 | R31-Q5 = A: **pontos de descanso são locais seguros de pausa e preparação nas dungeons**, mantendo restauração de MP já aprovada; serviços e cura de HP pendentes. |
| D-176 | R32-Q1 = A: **após vitória dos aliados com protagonista caído, ele pode voltar à exploração mediante recuperação mínima**, condições e valor pendentes. |
| D-177 | R32-Q2 = A: **pontos seguros de descanso também recuperam HP além de restaurar MP**, critérios/quantidade de HP pendentes. |
| D-178 | R32-Q3 = A: **XP e níveis adquiridos na expedição são mantidos após derrota definitiva ou retirada voluntária**, sem revogar perda de itens não segurados. |
| D-179 | R32-Q4 = A: **mapa do andar revelado progressivamente conforme exploração**, apresentação/persistência entre expedições pendentes. |
| D-180 | R32-Q5 = B: **Pokémon especial elegível inicia tarefa/evento de recrutamento por interação voluntária, a resolver antes de recrutar**, conteúdos pendentes. |

## 10. Rodada 1 — cinco perguntas respondidas (FECHADA)

**Status:** FECHADA — 5/5 respostas aprovadas em 2026-11-01. Decisões D-021 a D-025 registradas nas seções técnicas acima.

| ID | Resposta do criador | Regra incorporada |
| --- | --- | --- |
| **R1-Q1** | **B** | Burst pode ser utilizado imediatamente após Evade ativo bem-sucedido **ou armazenado** para um ataque que o exija posteriormente. A capacidade e a duração do armazenamento permanecem pendentes. |
| **R1-Q2** | **A** | Toda ação desconta **somente seu custo** e preserva o ATB normal restante. |
| **R1-Q3** | **C** — “so ocorre pausa no combate durante as escolhas do tactic” | O combate **pausa apenas nas escolhas de Tactic**. Menus FIGHT e ITENS não pausam; não adicionar outras situações de pausa sem aprovação. |
| **R1-Q4** | Fraqueza **+1**; crítico normal **+2**; evasão automática **+2**; Evade ativo bem-sucedido **+1** | Bônus instantâneos individuais estabelecidos. O crítico garantido de Burst **não** recebe bônus de crítico. |
| **R1-Q5** | **A** | Crítico normal e fraqueza no **mesmo golpe** somam os respectivos bônus (2+1 = **+3**), respeitando regra futura de capacidade/excedente. |

**Pontos não resolvidos por esta rodada:** limite e duração de Burst armazenado, custo ATB normal de Moves que exigem Burst, excedente de blocos acima de 5 e especificações de execução dos menus/combate além da pausa exclusiva de Tactic.

## 10.1. Rodada 2 — cinco perguntas respondidas (FECHADA)

**Status:** FECHADA — 5/5 respostas aprovadas em 2026-11-01. Decisões D-026 a D-030 incorporadas nas seções acima.

| ID | Resposta literal/resumida do criador | Regra incorporada |
| --- | --- | --- |
| **R2-Q1** | **A** — “Armazena até ser usado durante a batalha, sem levar para outra batalha.” | Burst pode ficar guardado **até uso durante a batalha atual** e não atravessa o fim dessa batalha. Não foi definido o limite de blocos Burst armazenáveis. |
| **R2-Q2** | **C** — “fica com blocos extras assim como burst mas nao sendo burst que nao tomam o limite mas servem pra realizar mais acoes” | Excedentes do ATB são **blocos extras de ATB**, separados dos cinco normais e **distintos de Burst**; preservados além dos cinco espaços e utilizáveis para executar mais ações. A resposta **não** determina se existe um teto para esses extras ou em que ordem são consumidos. |
| **R2-Q3** | **B** — “Move Burst consome bloco Burst e também os blocos ATB normais do Move.” | Um Move usado via Burst desconta **o bloco especial** e **seu custo normal de ATB**. Não isenta custos do Move. |
| **R2-Q4** | **C** — “tactic nao envia ordens so orienta a IA dos aliados” | Tactic **não envia ordens diretas**, apenas ajusta/orienta a IA dos companheiros; substitui essa parcela da definição histórica D-004. **Não** decide custo ATB para alteração de orientação; mantém pausa aprovada durante a escolha. |
| **R2-Q5** | **A** — “Preenchimento natural do ATB depende da Velocidade.” | O atributo individual **Velocidade** determina a taxa temporal de preenchimento dos blocos normais; fórmula e base temporal seguem pendentes. |

**Pendências preservadas:** quantidade máxima de Burst armazenado, limite/consumo/exibição dos extras normais, custo de configuração de Tactic, fórmula da Velocidade, recompensa por fraqueza durante um Move de Burst e outras regras não deliberadas.

## 10.2. Rodada 3 — cinco perguntas respondidas (FECHADA)

**Status:** FECHADA — 5/5 respostas aprovadas em 2026-11-01. Decisões D-031 a D-035 incorporadas às seções acima.

| ID | Resposta do criador | Regra incorporada |
| --- | --- | --- |
| **R3-Q1** | **B** — “Permite vários Bursts armazenados sem limite fixo de quantidade durante a batalha.” | Armazenamento de **múltiplos Bursts sem teto fixo** durante a batalha; não são transferidos à batalha seguinte (R2-Q1). |
| **R3-Q2** | **A** — “Gasta primeiro os blocos ATB extras.” | Custos de ações consomem **extras primeiro** e, se faltar saldo, blocos ATB normais. |
| **R3-Q3** | **A** — “Tactic não consome ATB; é uma operação de configuração da IA, como exceção à cobrança de ações.” | Tactic é **gratuito em ATB**, apenas orienta a IA, não envia ordens e pausa o combate somente durante a seleção. |
| **R3-Q4** | **A** — “A regeneração natural para em 5 blocos normais; extras surgem apenas de recompensas.” | Tempo/Velocidade preenche até **5 normais**. Apenas os ganhos por ações premiadas podem gerar extras. |
| **R3-Q5** | **B** — “Move Burst não concede ATB pela fraqueza nem pelo crítico garantido.” | **Nenhum** desses dois bônus ATB aplica-se a Moves usados via Burst. |

**Questões ainda abertas:** teto de ATB extras, apresentação visual, critérios de recompensa em multi-alvo/multi-hit, custos de buffs/debuffs do Burst e outras regras descritas como PENDENTE nas seções acima.

## 10.3. Rodada 4 — cinco perguntas respondidas (FECHADA)

**Status:** FECHADA — 5/5 respostas aprovadas em 2026-11-01. Decisões D-036 a D-040 incorporadas.

| ID | Resposta do criador | Regra incorporada |
| --- | --- | --- |
| **R4-Q1** | **A** — “Sem limite fixo para blocos ATB extras.” | ATB extra pode acumular-se sem teto fixo durante a batalha. |
| **R4-Q2** | **A** — “Exibir blocos ATB extras como quadradinhos adicionais, distintos dos cinco normais e de Burst.” | Quadradinhos adicionais contíguos à barra normal, visualmente distintos dos normais e do Burst; aparência detalhada pendente. |
| **R4-Q3** | **A** — “Evade consome 3 blocos na ativação, tanto em sucesso quanto em falha.” | Custo de Evade descontado na ativação, em ambos os resultados, usando extras antes de normais. |
| **R4-Q4** | **A** — “Tackle físico genérico custa 2 blocos ATB.” | Tackle de FIGHT custa 2 ATB e não ocupa os quatro espaços de Move. |
| **R4-Q5** | **A** — “IA dos aliados decide automaticamente tentar Evade ativo com base na situação e ATB; Tactic pode influenciar sua prioridade.” | IA pode decidir autonomamente o Evade ativo, considerando situação e ATB; Tactic só orienta prioridade, sem ordens diretas. |

**PENDENTE:** persistência de extras entre batalhas, grandes quantidades na interface, recompensas multi-alvo/multi-hit, custos de buff/debuff via Burst e persistência das orientações Tactic.

## 10.4. Rodada 5 — cinco perguntas respondidas (FECHADA)

**Status:** FECHADA — 5/5 respostas aprovadas em 2026-11-01. Decisões D-041 a D-045 incorporadas às seções técnicas correspondentes.

| ID | Resposta do criador | Regra incorporada |
| --- | --- | --- |
| **R5-Q1** | **A** — “Os blocos ATB extras são descartados no fim de cada batalha.” | Ao terminar uma batalha, descartar o estoque extra; não determina o ATB normal inicial da próxima. |
| **R5-Q2** | **B** — “Ataques normais multi-alvo recompensam no máximo uma vez por fraqueza e uma por crítico normal por ação.” | **Limite global por ação**, ainda que vários alvos acionem fraqueza ou crítico: até +1 e +2, respectivamente. |
| **R5-Q3** | **B** — “Cada execução de Move normal concede no máximo uma recompensa por fraqueza e uma por crítico normal por alvo.” | O mesmo alvo não gera recompensas repetidas por múltiplos hits na mesma execução. **Aplicar também o teto global por ação de R5-Q2 quando houver múltiplos alvos**. |
| **R5-Q4** | **B** — “Buff/debuff usado via Burst custa somente um bloco Burst, sem custo ATB normal.” | Buff/debuff via Burst consome **1 Burst, sem ATB comum**; Moves ofensivos via Burst mantêm Burst + custo ATB do Move. |
| **R5-Q5** | **B** — “Orientações de Tactic persistem entre encontros na mesma dungeon até alteração; além da dungeon ainda pendente.” | Orientações de IA ficam ativas entre encontros da **mesma dungeon**, até modificadas. Fora da dungeon, a regra permanece pendente. |

**Interpretação conjunta R5-Q2 e R5-Q3:** R5-Q3 define o limite por alvo para golpes repetidos; R5-Q2 estabelece o limite global da ação quando há múltiplos alvos. Assim, nenhuma combinação de alvos/hits permite superar as duas recompensas possíveis (+1 de fraqueza, +2 de crítico normal) em uma única ação normal.

## 10.5. Rodada 6 — cinco perguntas respondidas (FECHADA)

**Status:** FECHADA — 5/5 respostas aprovadas em 2026-11-01. Decisões D-046 a D-050 incorporadas às seções acima.

| ID | Resposta do criador | Regra incorporada |
| --- | --- | --- |
| **R6-Q1** | **A** — “Todos os Pokémon começam cada batalha com 0/5 ATB normal.” | Protagonista, aliados e inimigos começam com **0/5 ATB normal**, acumulando depois conforme Velocidade; não herdam extras nem Burst. |
| **R6-Q2** | **C** — “1” | O comando **ITENS cobra 1 bloco ATB por utilização de item**, em vez dos custos 2 ou variável propostos. Não se presume cobrança apenas por abrir a interface. |
| **R6-Q3** | **A** — “Até 3 Pokémon ativos: protagonista e 2 aliados IA.” | **Até 3 Pokémon na equipe ativa**, sendo um protagonista sob controle direto e até dois aliados sob IA. Não define equipe inimiga ou reservas. |
| **R6-Q4** | **C** — “opçao nas configuracoes para ambas A e B” | As **configurações** oferecem escolher (A) reiniciar Tactic ao sair da dungeon ou (B) preservar orientações entre dungeons. **Não houve escolha de valor padrão**. O comportamento dentro da dungeon continua conforme R5-Q5. |
| **R6-Q5** | **A** — “Custo-base dos quatro Moves é 2 ATB, permitindo exceções individuais de custo ou Burst.” | Os quatro Moves usam **custo-base 2 ATB**, sujeito a exceções definidas nas fichas individuais; Moves que exigem Burst seguem consumindo Burst + seu custo ATB. |

**Pendências explícitas preservadas:** valor padrão da configuração de Tactic; tempo-base/fórmula de preenchimento por Velocidade; lista, custos excepcionais e PP dos Moves; regras da equipe inimiga e de recrutamento/reserva.

## 10.6. Rodada 7 — cinco perguntas respondidas (FECHADA)

**Status:** FECHADA — 5/5 respostas aprovadas em 2026-11-01. Decisões D-051 a D-055 incorporadas às seções técnicas correspondentes.

| ID | Resposta do criador | Regra incorporada |
| --- | --- | --- |
| **R7-Q1** | **A** — “A opção padrão de Tactic será reiniciar as orientações ao sair da dungeon; preservação entre dungeons continua selecionável.” | O ajuste padrão é **reiniciar orientações de Tactic ao sair da dungeon**. O jogador pode selecionar **preservar** nas configurações. Não define qual orientação de IA é o padrão. |
| **R7-Q2** | **A** — “Tempo-base de 5 segundos para preencher 0/5 a 5/5 na Velocidade de referência; fórmula e valor da Velocidade de referência pendentes.” | Um Pokémon de Velocidade de referência enche o ATB normal em **5 s, do zero ao total**. Valor de referência e curva de Velocidade ainda não decididos. |
| **R7-Q3** | **B** — “Os quatro Moves equipados não possuem PP, usando ATB e Burst quando aplicável.” | Os **quatro Moves equipados não gastam PP**; custos são ATB e Burst quando requerido. **PP de Tackle não foi especificado**. |
| **R7-Q4** | **A** — “Até três Pokémon inimigos ativos simultaneamente em cada batalha.” | Máximo de **3 inimigos ativos** em combate. Não determina reservas, ondas ou substituições. |
| **R7-Q5** | **A** — “Dungeons 2D geradas proceduralmente por exploração/andar; algoritmos e parâmetros a definir.” | Mapas da exploração 2D são **gerados proceduralmente por exploração/andar**, segundo regras de salas/corredores ainda a definir. |

**Pendências preservadas:** qual Velocidade é a referência e a fórmula de preenchimento; PP de Tackle; método e persistência dos mapas procedurais; formato dos encontros; orientação-base concreta da IA e detalhes de salvamento da configuração.

## 10.7. Rodada 8 — cinco perguntas respondidas (FECHADA)

**Status:** FECHADA — 5/5 respostas aprovadas em 2026-11-01. Decisões D-056 a D-060 incorporadas às seções técnicas acima.

| ID | Resposta do criador | Regra incorporada |
| --- | --- | --- |
| **R8-Q1** | **A** — “O tempo de preenchimento ATB é inversamente proporcional à Velocidade; dobrar Velocidade reduz o tempo pela metade, com referência e limites ainda pendentes.” | Aplicar **escala temporal inversamente proporcional à Velocidade**, preservando os **5 s** de referência. Velocidade de referência, limites e bordas pendentes. |
| **R8-Q2** | **C** — “MASS NEM TEM PP, VC AO MENOS TA LENDO AS RESPOSTAS?” | **Não existe PP em Crawlmon**, inclusive no Tackle genérico. Esta resposta **encerra a dúvida histórica sobre PP de Tackle** que permaneceu indevidamente aberta após R7-Q3. Não voltar a perguntar PP sem uma solicitação explícita de mudança. |
| **R8-Q3** | **A** — “É possível reproduzir uma dungeon procedural a partir de uma seed registrada, sob as mesmas regras e versão do gerador.” | A seed pode ser registrada/reutilizada para **reproduzir o layout** na mesma versão e com as mesmas regras; UX e persistência de encontros e eventos ainda em aberto. |
| **R8-Q4** | **A** — “Salas e corredores de dungeons são construídos algoritmicamente pelo gerador.” | Salas/corredores, posições, formas e conexões são criados pelo gerador, não exigem biblioteca de salas pré-desenhadas. |
| **R8-Q5** | **A** — “Encontros começam pelo contato com inimigos Pokémon visíveis no mapa 2D.” | Encontros ocorrem por contato com inimigos visíveis, levando ao combate 3D. Patrulha, detecção e movimentação dos inimigos ainda não definidas. |

**Correção de rastreabilidade de PP:** seções históricas de R6/R7 conservam seus textos originais, inclusive antigas afirmações de pendência. Elas **não são regras vigentes** sobre PP: **D-057 / R8-Q2 prevalece**, e a especificação atual não deve voltar a apresentar PP como indecisão. Esta correção não altera outras decisões aprovadas.

## 10.8. Rodada 9 — cinco perguntas respondidas (FECHADA)

**Status:** FECHADA — 5/5 respostas registradas em 2026-11-01; decisões D-061 a D-065. **Observação:** R9-Q1 não fixa número; fixa explicitamente o adiamento para depois da definição dos atributos.

| ID | Resposta do criador | Estado e regra |
| --- | --- | --- |
| **R9-Q1** | **C** — “vamos definir os status” | **ADIADA, por decisão expressa:** definir primeiramente os atributos e suas escalas. **Nenhum valor numérico de Velocidade de referência foi aprovado**. Permanecem válidos o tempo-base 5 s e a relação inversa com Velocidade. |
| **R9-Q2** | **A** — “Ao revisitar um andar na mesma exploração, preservar seu layout procedural.” | O layout de um andar previamente gerado permanece **idêntico durante a exploração atual** quando revisitado. Não presumir restauração de itens/inimigos. |
| **R9-Q3** | **A** — “Inimigos visíveis patrulham e perseguem o protagonista após detectá-lo; condições de detecção ainda pendentes.” | Inimigos patrulham, detectam e perseguem; distância, condições, velocidade e perda de alvo ainda exigem aprovação. |
| **R9-Q4** | **A** — “Ao vencer o encontro, remover aquele inimigo visível do andar durante a exploração atual.” | Inimigo derrotado deixa de existir no andar **até terminar a exploração**, inclusive em revisitas; não definir regras de outros spawns. |
| **R9-Q5** | **B** — “O protagonista se movimenta nas quatro direções cardeais.” | Movimento cardinal, sem diagonais diretas. Forma contínua ou em tiles/turnos ainda indefinida. |

**Não inferir:** a resposta R9-Q1 é um pedido para decidir os atributos primeiro, **não** uma escolha de Velocidade 50 ou 100 nem autorização para fixar números de atributos sem respostas adicionais.

## 10.9. Rodada 10 — definição dos atributos/status do Pokémon (FECHADA)

**Status:** FECHADA — 5/5 respostas aprovadas em 2026-11-01. Decisões D-066 a D-070 incorporadas à seção 7.1 e às referências técnicas pertinentes.

| ID | Resposta literal/resumida do criador | Regra aprovada e limites |
| --- | --- | --- |
| **R10-Q1** | **C** — “Vamos usar atributos de megaten, smt3” | O sistema de atributos toma **SMT III: Nocturne como referência**. Os cinco atributos da referência são **Força, Magia, Vitalidade, Agilidade e Sorte**; implementação/funções no Crawlmon ainda requerem detalhamento. Não inserir MP, fórmulas ou valores por suposição. |
| **R10-Q2** | **A** — “Escala de 1 a 100 para valores-base dos atributos.” | Escala-base **1–100**; não determina valores de cada Pokémon nem limites após progressão. |
| **R10-Q3** | **A** — “Pokémon possuem níveis e seus atributos evoluem com o nível; máximo e fórmulas pendentes.” | Progressão por **níveis**, com crescimento dos atributos; curvas, XP e máximo não aprovados. |
| **R10-Q4** | **A** — “Buffs e debuffs alteram atributos por estágios discretos; multiplicadores e limites a definir.” | **Estágios discretos**; multiplicadores, limites, duração e efeitos específicos pendentes. |
| **R10-Q5** | **A** — “Velocidade de referência será um valor fixo na escala de atributos aprovada, a determinar em rodada posterior.” | Referência numérica **fixa e comum** para o ATB; **não há valor aprovado**. A relação entre Agilidade e Velocidade ainda precisa de decisão. |

**Diferença entre referência e requisito:** a presença de MP em SMT3 **não autoriza implementar MP no Crawlmon**. A ausência de PP e os custos ATB/Burst já aprovados permanecem integralmente vigentes. HP e quaisquer outros recursos devem seguir decisões posteriores, sem inventar fórmulas.

## 10.10. Rodada 11 — adaptação dos atributos de SMT3 ao Crawlmon (FECHADA)

**Status:** FECHADA — 5/5 respostas aprovadas em 2026-11-01. Decisões D-071 a D-075 incorporadas à seção 7.2 e às referências técnicas relacionadas.

| ID | Resposta do criador | Regra aprovada e limites |
| --- | --- | --- |
| **R11-Q1** | **A** — “Agilidade de SMT3 e Velocidade do ATB serão o mesmo atributo; nomenclatura visual ainda a definir.” | **Agilidade/Velocidade é um atributo único**, que governa o ATB; nome de exibição e número de referência não definidos. |
| **R11-Q2** | **A** — “HP máximo derivado da Vitalidade e do nível; fórmula pendente, sem atributo-base HP independente.” | HP máximo usa **Vitalidade e nível**; não acrescentar atributo-base HP próprio nem inventar fórmula. |
| **R11-Q3** | **B** — “Magia afeta dano e efeitos mágicos e haverá recurso MP separado, com regras ainda pendentes.” | Magia afeta efeitos/dano mágicos; **MP existe como recurso separado**, mas seu cálculo, consumo e recuperação continuam pendentes. **Crawlmon permanece sem PP.** |
| **R11-Q4** | **B** — “O jogador distribui manualmente pontos de atributo ao subir de nível, com quantidade e restrições pendentes.” | Ao subir de nível, o **jogador distribui pontos manualmente**; número de pontos, restrições e escopo de Pokémon ainda a definir. |
| **R11-Q5** | **A** — “Sorte influencia probabilidades do combate, como crítico e/ou outros efeitos, com fórmula pendente.” | Sorte modifica **probabilidades de combate**, ainda sem eventos exatos e sem fórmulas aprovadas. |

**Limite da aprovação:** a existência de MP em R11-Q3 **não** implica automaticamente que os Moves consumam MP, nem elimina ou altera ATB/Burst, e não autoriza implementar PP. As decisões de catálogo e escala da Rodada 10 permanecem em vigor.

## 10.11. Rodada 12 — economia de MP e progressão manual (FECHADA)

**Status:** FECHADA — 5/5 respostas aprovadas em 2026-11-01. Decisões D-076 a D-080 consolidadas nas seções técnicas correspondentes.

| ID | Resposta do criador | Regra aprovada e limites |
| --- | --- | --- |
| **R12-Q1** | **A** — “Todos os Moves mágicos/especiais consomem MP adicional aos custos ATB/Burst; valores individuais pendentes.” | **Todos os Moves mágicos/especiais consomem MP além dos recursos ATB/Burst aplicáveis**. Custo MP de cada Move pendente. Nenhum PP. |
| **R12-Q2** | **A** — “MP máximo derivado do atributo Magia e do nível do Pokémon, com fórmula pendente.” | **MP máximo depende de Magia e nível**; fórmula, valores e limites ainda não definidos. |
| **R12-Q3** | **B** — “MP restante persiste entre batalhas da mesma dungeon; formas de recuperação ainda pendentes.” | **Persistir o MP restante entre combates da mesma dungeon**, sem restauração automática integral por batalha. Recuperação e persistência após sair da dungeon pendentes. |
| **R12-Q4** | **A** — “Cada nível concede quantidade fixa de pontos de atributo, valor ainda a definir.” | **Quantidade fixa de pontos por nível**. Nenhum número foi aprovado. |
| **R12-Q5** | **B** — “Jogador distribui pontos somente do protagonista; aliados evoluem seus atributos automaticamente por regras futuras.” | **Distribuição manual apenas para o protagonista**. **Aliados têm crescimento automático**, sem curva/fórmula aprovadas. Esclarece o escopo da decisão R11-Q4. |

**Preservação das regras anteriores:** MP é independente de PP (que não existe); o custo MP dos Moves mágicos/especiais **não substitui** ATB/Burst. Os níveis, a escala de atributos-base 1–100, o valor numérico de referência do ATB ainda pendente e as demais regras aprovadas permanecem inalterados.

## 10.12. Rodada 13 — MP e evolução dos atributos (FECHADA)

**Status:** FECHADA — 5/5 respostas aprovadas em 2026-11-01. Decisões D-081 a D-085 registradas nas seções técnicas.

| ID | Resposta do criador | Regra incorporada |
| --- | --- | --- |
| **R13-Q1** | **A** — “Moves mágicos/especiais têm custo-base comum de MP, com exceções individuais; valor-base ainda pendente.” | **Custo-base comum de MP com exceções por Move**, sem valores definidos. |
| **R13-Q2** | **B** — “MP pode ser recuperado por consumíveis e por pontos de descanso/recuperação na dungeon; detalhes pendentes.” | **Itens e pontos de descanso/recuperação na dungeon** restauram MP, com condições e efeitos pendentes. |
| **R13-Q3** | **A** — “MP é restaurado ao máximo no início de uma nova exploração; continua persistindo entre combates da mesma dungeon.” | MP **restaurado ao máximo ao iniciar nova exploração**; persiste entre batalhas na mesma dungeon. |
| **R13-Q4** | **A** — “O protagonista recebe 1 ponto distribuível de atributo por nível.” | **1 ponto distribuível ao protagonista por nível**, sem assumir quantidades numéricas para aliados. |
| **R13-Q5** | **A** — “Atributos dos aliados crescem automaticamente por curvas específicas de espécie; valores e fórmulas pendentes.” | **Curvas automáticas por espécie para aliados**, ainda sem fórmulas nem valores. |

**PENDENTE:** valor-base e exceções de MP, funcionamento dos pontos de descanso/itens, fórmula de MP máximo, pontos não distribuídos e curvas dos aliados. **ATB/Burst preservados e PP inexistente.**

## 10.13. Rodada 14 — recuperação e evolução (FECHADA)

**Status:** FECHADA — 5/5 respostas aprovadas em 2026-11-01. D-086 a D-090 incorporadas.

| ID | Resposta do criador | Regra vigente |
| --- | --- | --- |
| **R14-Q1** | **A** — “O MP é descontado na ativação do Move mágico/especial; regras de cancelamento e reembolso pendentes.” | MP cobrado na ativação, cancelamento e reembolso pendentes. |
| **R14-Q2** | **C** — “cada personagem recupera 1/4 do MP a cada 3 segundos enquanto tiver com as 5 barras cheias, é uma mecanica própria isso, mas sim opção A também” | Recuperação de 1/4 do MP a cada 3 s com ATB 5/5 e **descanso restaura MP completamente**. Base do 1/4 e contador pendentes. |
| **R14-Q3** | **A** — “HP restante de cada Pokémon persiste entre batalhas da mesma dungeon até ser recuperado.” | Persistir HP entre batalhas na dungeon. |
| **R14-Q4** | **B** — “O protagonista precisa distribuir seu ponto de atributo ao subir de nível, antes de concluir a progressão.” | Distribuição obrigatória ao subir de nível. |
| **R14-Q5** | **C** — “eles tem atributos base mas a forma com que recebem atributos por nivel é baseada na forma como lutam no jogo, definido pelas suas táticas. para pokemons aleatorios que podem entrar na equipe, isso também é uma definição aleatória, haverá também o sistema de natures de pokemon” | Ganhos por nível influenciados pela forma de lutar/táticas, definição aleatória de comportamento para recrutáveis, Natures; números e efeitos pendentes. |

**Rastreabilidade:** R14-Q2 soma duas recuperações; R14-Q5 complementa D-085, de crescimento por espécie. Sem PP, sem alterar ATB/Burst.

## 10.14. Rodada 15 — detalhes de MP e crescimento tático (FECHADA)

**Status:** FECHADA — 5/5 respostas aprovadas em 2026-11-01, registradas como D-091 a D-095.

| ID | Resposta do criador | Regra incorporada |
| --- | --- | --- |
| **R15-Q1** | **A** — “A cada 3 segundos elegíveis com ATB 5/5, recupera 1/4 do MP máximo, arredondamento pendente.” | Recuperar **25% do MP máximo** por intervalo elegível de três segundos em ATB cheio. Arredondamento pendente. |
| **R15-Q2** | **A** — “Ao sair de ATB 5/5, o contador de recuperação de MP zera; exige 3 segundos consecutivos em 5/5.” | **Zerar a contagem** ao deixar 5/5 e exigir **3 s consecutivos** por recuperação. |
| **R15-Q3** | **A** — “Crescimento dos aliados considera tanto tática selecionada quanto ações realmente executadas, com ponderação a definir.” | **Tática e ações executadas** influenciam juntas o crescimento; pesos e fórmulas pendentes. |
| **R15-Q4** | **B** — “Natures influenciam atributos, crescimento e tendências comportamentais/táticas, com regras a definir.” | **Nature afeta atributos, crescimento e tendências comportamentais/táticas**; efeitos concretos pendentes. |
| **R15-Q5** | **B** — “Tática inicial de recrutáveis aleatórios é sorteada entre opções associadas à Nature, se esta afetar comportamento.” | **Sortear tática inicial entre opções associadas à Nature**, que já foi aprovada como influenciando comportamentos; probabilidades pendentes. |

**Limites e rastreabilidade:** R15-Q1/Q2 especificam a recuperação de MP de R14-Q2 sem alterar o ATB; R15-Q3/Q4/Q5 detalham o crescimento tático, Nature e recrutamento de R14-Q5. Não foram definidos arredondamentos, pesos de ações/táticas, modificadores de Nature ou taxas de sorteio. Nenhum PP ou novo custo ATB/Burst foi introduzido.

## 10.15. Rodada 16 — MP e integração de Nature/táticas (FECHADA)

**Status:** FECHADA — 5/5 respostas aprovadas em 2026-11-01. Decisões D-096 a D-100 registradas.

| ID | Resposta do criador | Regra e limites |
| --- | --- | --- |
| **R16-Q1** | **B** — “A recuperação de 25% do MP máximo por intervalo elegível é arredondada para baixo.” | Parcela **arredondada para baixo**. |
| **R16-Q2** | **A** — “Enquanto o MP estiver no máximo, o contador de recuperação aguarda zerado; quando surgir MP faltante com ATB 5/5, inicia novo intervalo de três segundos.” | Contador **zerado com MP máximo**; novo período completo quando houver MP faltante com ATB 5/5. |
| **R16-Q3** | **C** — “vai ter um sistema de telemetria de desempenho em combate que leva em conta a maioria de suas ações efetuadas” | **Telemetria de combate considerando maioria das ações executadas**, sem janela, critérios ou fórmulas aprovados. |
| **R16-Q4** | **A** — “Nature é sorteada ao gerar o Pokémon recrutável aleatório, antes do recrutamento, e permanece atribuída.” | **Nature sorteada na geração e mantida** para recrutáveis aleatórios. |
| **R16-Q5** | **B** — “A Tactic escolhida prevalece integralmente sobre as tendências comportamentais de Nature enquanto estiver ativa; Nature continua afetando atributos e crescimento.” | **Tactic tem precedência integral no comportamento enquanto ativa**, mantendo efeito de Nature em atributos/crescimento. |

**Preservação:** telemetria não escolhe janela nem fórmula; mantém influência conjunta de táticas e ações. MP, ATB/Burst, inexistência de PP e decisões anteriores preservados.

## 10.16. Rodada 17 — telemetria, Nature e recuperação (FECHADA)

**Status:** FECHADA — 5/5 respostas aprovadas em 2026-11-01. Decisões D-101 a D-105.

| ID | Resposta literal do criador | Regra aprovada |
| --- | --- | --- |
| **R17-Q1** | **B** — “A telemetria considera o histórico acumulado de ações de combate do Pokémon, com ponderação pendente.” | **Histórico acumulado entre níveis**, ponderação ainda pendente. |
| **R17-Q2** | **A** — “A telemetria identifica ações predominantes pela frequência das categorias de ações executadas, sem considerar sucesso como condição.” | **Frequência de categorias executadas**, sucesso não obrigatório. |
| **R17-Q3** | **B** — “A tática selecionada exerce a influência principal, enquanto a telemetria ajusta ganhos conforme as ações realmente executadas; pesos pendentes.” | **Tática principal, telemetria como ajuste**, pesos pendentes. |
| **R17-Q4** | **C** — “o jogo é um roguelike dungeon crawler, entao B” | **Nature sorteada na geração também do protagonista e Pokémon de eventos**, regra B escolhida na resposta C. Sem inferir outras mecânicas roguelike. |
| **R17-Q5** | **A** — “O contador de recuperação de MP fica pausado durante o menu Tactic e retoma quando o combate prossegue, desde que os requisitos continuem válidos.” | **Contador de MP pausa em Tactic, retomando se elegível**. |

**Preservação:** não criar PP, números, fórmulas ou custos ATB/Burst adicionais. Histórico anterior inalterado.

## 10.17. Rodada 18 — persistência, contagem de ações e Natures (FECHADA)

**Status:** FECHADA — 5/5 decisões aprovadas em 2026-11-01, registradas como D-106 a D-110.

| ID | Resposta do criador | Regra aprovada e pendências |
| --- | --- | --- |
| **R18-Q1** | **A** — “O histórico acumulado de telemetria acompanha o mesmo Pokémon entre dungeons e explorações.” | **Persistência do histórico do mesmo indivíduo entre dungeons e explorações**; retenção, limites e pesos pendentes. |
| **R18-Q2** | **A** — “A telemetria considera categorias amplas de ações: ataques físicos e mágicos, defesa/esquiva, suporte e uso de itens; detalhamento pendente.” | **Incluir ataques físicos/mágicos, defesa/esquiva, suporte e itens**; eventos específicos pendentes. |
| **R18-Q3** | **A** — “Moves multi-hit/multi-alvo contam uma ação por execução, independentemente da quantidade de impactos ou alvos.” | **Cada execução de Move vale uma ocorrência na telemetria**, sem multiplicação por acertos/alvos. Não afeta bônus ATB. |
| **R18-Q4** | **A** — “A Nature do protagonista é sorteada novamente a cada nova exploração, com probabilidades pendentes.” | **Novo sorteio de Nature do protagonista a cada nova exploração**, sem presumir novos sorteios para aliados ou reset de progressão. |
| **R18-Q5** | **A** — “Natures modificam atributos-base; valores e atributos afetados pendentes.” | **Nature modifica atributos-base**, com valores, atributos afetados e interação com novo sorteio pendentes. |

**Preservação:** histórico e decisões anteriores continuam vigentes. Não foram aprovados números, fórmulas, PP ou custos ATB/Burst novos.

## 10.18. Rodada 19 — telemetria, Natures e progressão entre explorações (FECHADA)

**Status:** FECHADA — 5/5 respostas aprovadas em 2026-11-01. Decisões D-111 a D-115 incorporadas às seções técnicas.

| ID | Resposta literal do criador | Regra aprovada e limites |
| --- | --- | --- |
| **R19-Q1** | **A** — “Ao sair da equipe e retornar, o Pokémon preserva seu histórico individual de telemetria.” | **Preservar o histórico pessoal de telemetria** quando o mesmo Pokémon sair da equipe e retornar. |
| **R19-Q2** | **C** — “no maxim duas categorias” | **No máximo duas categorias por ação registrada na telemetria**. Uma execução de Move continua contando uma ação, mesmo multi-hit/multi-alvo. **PENDENTE:** quais categorias selecionar em caso de mais de duas elegíveis e como contabilizar frequência com dupla classificação. |
| **R19-Q3** | **A** — “Uma ação é registrada quando sua execução começa efetivamente, ainda que posteriormente falhe ou seja interrompida.” | **Registrar no início efetivo da execução**, independentemente de sucesso ou interrupção posterior, sem alterar custos e regras de recursos. |
| **R19-Q4** | **A** — “Após o novo sorteio de Nature do protagonista, preservar os pontos de atributos já distribuídos e substituir somente os efeitos da Nature anterior pelos da nova, com regras de recomposição ainda pendentes.” | **Manter pontos distribuídos** e **substituir somente os efeitos de Nature**; fórmulas de recomposição pendentes. |
| **R19-Q5** | **B** — “Natures podem conceder bônus e penalidades sem exigir sempre um par de atributo favorecido e atributo prejudicado, com catálogo e valores pendentes.” | **Modificadores flexíveis nos atributos-base**, sem obrigatoriedade de combinação positiva/negativa; catálogo e números pendentes. |

**Rastreabilidade:** R19-Q2 responde C com teto específico de duas categorias; não aprova classificar uma ação em um número ilimitado de categorias. R19-Q4 mantém a distribuição manual histórica. Regras de ATB/Burst e a inexistência de PP permanecem inalteradas.

## 10.19. Rodada 20 — categorias da telemetria e efeitos de Nature (FECHADA)

**Status:** FECHADA — 5/5 respostas aprovadas em 2026-11-01, registradas como D-116 a D-120.

| ID | Resposta do criador | Regra aprovada e limites |
| --- | --- | --- |
| **R20-Q1** | **A** — “Se uma ação puder pertencer a mais de duas categorias, selecionar as categorias principais previamente definidas na ficha da ação/Move; critérios de prioridade pendentes.” | **Usar até duas categorias principais da ficha da ação/Move**; critérios de seleção/prioridade ainda pendentes. |
| **R20-Q2** | **A** — “Uma ação com duas categorias contribui com uma ocorrência de frequência em cada categoria, permanecendo uma única ação executada.” | **Uma ocorrência em cada categoria** quando houver dupla classificação, mas **uma única ação executada** na telemetria. |
| **R20-Q3** | **A** — “Quando o Pokémon estiver fora da equipe, preservar o histórico sem acumular novas ações até seu retorno.” | **Histórico congelado/preservado durante a ausência da equipe**, retomando a contabilização quando retornar. |
| **R20-Q4** | **A** — “Se o HP/MP máximo mudar devido à nova Nature, conservar a proporção dos valores atuais relativamente aos máximos anteriores; regras numéricas pendentes.” | **Preservar a proporção do HP/MP atual quando o respectivo máximo mudar por Nature**; arredondamento e casos-limite pendentes. |
| **R20-Q5** | **A** — “O catálogo de Natures pode incluir Natures neutras, sem modificadores diretos nos atributos-base, mantendo possíveis efeitos no crescimento/comportamento.” | **Permitir Natures neutras nos atributos-base**, com possíveis efeitos sobre crescimento/comportamento ainda a definir. |

**Rastreabilidade:** a Rodada 20 detalha categorias, frequências, persistência e efeitos de Nature sem revogar as decisões aprovadas. Nenhuma regra numérica nova de crescimento, PP ou custo ATB/Burst foi acrescentada.

## 10.20. Rodada 21 — classificação da telemetria e efeitos de Natures (FECHADA)

**Status:** FECHADA — 5/5 decisões aprovadas em 2026-11-01, registradas como D-121 a D-125.

| ID | Resposta literal do criador | Regra aprovada |
| --- | --- | --- |
| **R21-Q1** | **A** — “A prioridade entre categorias é definida por uma ordem específica na própria ficha de cada ação/Move; regras de classificação ainda pendentes.” | **Prioridade específica na ficha de cada ação/Move**; critérios ainda pendentes. |
| **R21-Q2** | **A** — “O uso de item que também realiza suporte é classificado somente na categoria uso de itens.” | **Somente categoria uso de itens**, sem alterar o efeito do item. |
| **R21-Q3** | **B** — “A tática selecionada é utilizada para desempatar categorias de mesma frequência, seguindo critérios futuros.” | **Desempate de categorias com tática selecionada**, detalhes pendentes. |
| **R21-Q4** | **A** — “O HP/MP atual proporcional após mudança do máximo por Nature é arredondado para baixo, respeitando os novos máximos.” | **Arredondamento para baixo** no recálculo proporcional, com novos máximos respeitados. |
| **R21-Q5** | **A** — “Natures neutras nos atributos-base podem ter efeitos de crescimento e/ou tendências de comportamento, com regras pendentes.” | **Neutralidade nos atributos-base** com possíveis efeitos em crescimento e comportamento; sem efeitos concretos aprovados. |

**Preservação:** nenhuma fórmula de HP/MP máximo, quantidade de pontos, custo ATB/Burst, probabilidade ou PP foi acrescentada.

## 10.21. Rodada 22 — classificação, telemetria e casos-limite de Nature (FECHADA)

**Status:** FECHADA — 5/5 respostas aprovadas em 2026-11-01, registradas nas decisões D-126 a D-130.

| ID | Resposta literal do criador | Regra aprovada e pendências |
| --- | --- | --- |
| **R22-Q1** | **A** — “Registrar as categorias previstas na ficha quando o Move iniciar sua execução, mesmo que algum componente não ocorra; sucesso não é obrigatório.” | **Categorias da ficha registradas no início efetivo da execução**, inclusive se algum componente não ocorrer, com no máximo duas categorias e uma ação por execução. |
| **R22-Q2** | **A** — “Definir categorias e prioridades de telemetria por tipo de ação, incluindo defesa/esquiva, itens e outros tipos.” | **Classificação e prioridade por tipo de ação**, com categorias concretas pendentes; item com suporte continua apenas item. |
| **R22-Q3** | **A** — “A tática selecionada no momento da subida de nível é usada para desempatar categorias de telemetria.” | **Tática selecionada na subida de nível desempata categorias predominantes**, associações e exceções pendentes. |
| **R22-Q4** | **A** — “Se o HP proporcional arredondado for zero para um Pokémon anteriormente vivo, preservar um mínimo positivo de HP, com detalhes pendentes.” | **Preservar HP mínimo positivo** se antes havia HP positivo e o ajuste proporcional por Nature arredondaria a zero; quantidade e casos-limite pendentes. |
| **R22-Q5** | **A** — “Manter o atributo-base modificado pela Nature dentro da escala aprovada de 1–100; aplicação dos limites pendente.” | **Atributos-base modificados por Nature devem permanecer na escala 1–100**; procedimento de limites pendente. |

**Preservação:** sem definir valores mínimos de HP, valores de Nature, fórmulas, novas pausas, PP ou custos ATB/Burst. As Rodadas 1–21 e suas decisões permanecem preservadas.

## 10.22. Rodada 23 — gameplay fundamental (FECHADA; substitui perguntas não respondidas)

**Status:** FECHADA — 5/5 respostas aprovadas em 2026-11-01, decisões D-131 a D-135. As antigas perguntas técnicas desta rodada eram não respondidas e não aprovadas. Foram substituídas sem remover as decisões D-001 a D-130.

| ID | Resposta literal do criador | Regra aprovada |
| --- | --- | --- |
| **R23-Q1** | **A** — “Exploração 2D com movimentação contínua e livre nas quatro direções cardeais.” | Movimento contínuo cardinal. |
| **R23-Q2** | **A** — “Concluir uma dungeon exige alcançar o último andar e vencer um chefe.” | Último andar e chefe obrigatório para conclusão. |
| **R23-Q3** | **A** — “Ao perder a batalha de forma definitiva, encerrar a exploração atual; consequências sobre itens e progresso pendentes.” | Derrota definitiva encerra exploração, consequências pendentes. |
| **R23-Q4** | **B** — “Novos Pokémon podem ser recrutados durante exploração 2D, por interações ou aproximação, com regras pendentes.” | Recrutamento em exploração 2D; contato com inimigo ainda inicia batalha (R8-Q5). |
| **R23-Q5** | **C** — “combinacao com mestres e possiveis personagens que dao hms” | Aprendizado combinado com mestres e possíveis NPCs de HM; formas de HM e outras fontes pendentes. |

**Rastreabilidade:** R23-Q4 não revoga contato hostil de R8-Q5. R23-Q5 não determina funcionalidade de HMs nem altera PP, slots ou custos ATB/Burst.

## 10.23. Rodada 24 — progressão da dungeon, recrutamento e HMs (FECHADA)

**Status:** FECHADA — 5/5 decisões aprovadas em 2026-11-01, D-136 a D-140.

| ID | Resposta literal do criador | Regra aprovada e pendências |
| --- | --- | --- |
| **R24-Q1** | **A** — “O jogador avança de andar ao encontrar uma escada ou saída no mapa, sem precisar derrotar todos os inimigos.” | **Escada/saída sem eliminar todos os inimigos.** |
| **R24-Q2** | **A** — “O recrutamento de Pokémon elegível na exploração 2D exige uma interação voluntária explícita.” | **Interação voluntária de recrutamento.** Encontro hostil continua em combate. |
| **R24-Q3** | **A** — “Quando a equipe ativa de três estiver completa, novos Pokémon podem ser recrutados e enviados para reserva.” | **Recrutamento com equipe completa por reserva.** Limites/trocas pendentes. |
| **R24-Q4** | **C** — “hms e tms so para combate por ora” | **HMs e TMs apenas para combate por enquanto.** Nenhuma função de exploração aprovada. |
| **R24-Q5** | **A** — “Pokémon recrutados na expedição permanecem pertencendo ao jogador mesmo após derrota definitiva.” | **Recrutados preservados após derrota**, demais recursos pendentes. |

**Preservação:** as decisões D-001 a D-135 e a regra de contato hostil permanecem. A resposta personalizada C para HMs/TMs não estabelece custos, slots, lista de Moves nem exploração.

## 10.24. Rodada 25 — campanha, equipe e evolução (FECHADA)

**Status:** FECHADA — 5/5 decisões aprovadas em 2026-11-01, registradas nas decisões D-141 a D-145.

| ID | Resposta literal do criador | Regra aprovada / pendências |
| --- | --- | --- |
| **R25-Q1** | **A** — “A progressão geral segue uma campanha que desbloqueia novas dungeons conforme conquistas e objetivos.” | **Campanha com desbloqueio progressivo de dungeons**, condições concretas pendentes. |
| **R25-Q2** | **C** — “A po ora, vou criar um hub pra isso depois masmais tarde” | **Usar provisoriamente a alternativa A:** trocas entre equipe ativa e reserva durante a exploração; **hub futuro** apenas como intenção, sem estrutura ou implementação aprovada. |
| **R25-Q3** | **A** — “A evolução de espécie fica disponível após satisfazer requisitos, e o jogador escolhe quando realizá-la.” | **Evolução escolhida pelo jogador depois dos requisitos**, não automática obrigatória. |
| **R25-Q4** | **C** — “apenas itens que estao sendo segurados nao sao perdidos” | **Na derrota definitiva, preservar somente itens segurados entre os itens obtidos na expedição**; os demais obtidos nela se perdem. Tratamento de itens anteriores pendente. |
| **R25-Q5** | **A** — “Priorizar eventos, salas secretas, recompensas especiais e NPCs nas dungeons procedurais.” | **Priorizar descobertas, eventos, NPCs e recompensas especiais**, sem excluir conteúdo ambiental. |

**Preservação:** R25-Q2 e R25-Q4 são respostas C personalizadas, não aprovações irrestritas das antigas A/B; as decisões D-001 a D-140, as regras de equipe ativa, recrutamento, ATB/Burst, ausência de PP e histórico são preservadas.

## 10.25. Rodada 26 — protagonista, exploração e progressão (FECHADA)

**Status:** FECHADA — 5/5 respostas aprovadas em 2026-11-01, registradas como D-146 a D-150.

| ID | Resposta literal do criador | Regra aprovada / pendências |
| --- | --- | --- |
| **R26-Q1** | **A** — “O jogador escolhe seu Pokémon protagonista entre espécies iniciais disponíveis; catálogo e apresentação pendentes.” | **Escolha de protagonista entre espécies iniciais**; catálogo/interface pendentes, Nature independente. |
| **R26-Q2** | **B** — “Pokémon normalmente hostis podem aparecer em situações especiais como candidatos a recrutamento, identificados no mapa; encontros hostis normais continuam iniciando combate.” | **Recrutáveis especiais identificados no mapa, inclusive espécies normalmente hostis**; interação voluntária continua obrigatória. |
| **R26-Q3** | **A** — “Todos os Pokémon ativos que participam de uma batalha vencida recebem experiência, sem exigir que deem o golpe final; quantidades pendentes.” | **XP de vitória para todos os participantes ativos**, sem depender do golpe final; valores pendentes. |
| **R26-Q4** | **A** — “Após derrotar o chefe, a expedição termina e o jogador retorna à seleção/progressão da campanha; recompensas e desbloqueios pendentes.” | **Expedição encerra e retorna à seleção/progressão da campanha**, sem introduzir hub. |
| **R26-Q5** | **A** — “Salas secretas são descobertas opcionais voltadas a recompensas, eventos e NPCs especiais, sem serem exigidas para chegar ao chefe.” | **Salas secretas opcionais para descobertas/recompensas**, não bloqueiam caminho ao chefe. |

**Preservação:** as 145 decisões anteriores são mantidas. A distinção entre recrutamento especial e encontro hostil preserva R8-Q5/R24-Q2. Não acrescentar fórmulas, valores, PP, novos custos ATB/Burst ou funcionalidades não aprovadas.

## 10.26. Rodada 27 — combates, companhia e variedade de dungeons (FECHADA)

**Status:** FECHADA — 5/5 respostas aprovadas em 2026-11-01, registradas como D-151 a D-155.

| ID | Resposta literal do criador | Regra aprovada e pendências |
| --- | --- | --- |
| **R27-Q1** | **A** — “Permitir tentar fugir de combates comuns, com condições e consequências pendentes; tratamento de chefes ainda indefinido.” | **Tentativa de fuga em combates comuns**; critérios/chefes pendentes, sem custo novo. |
| **R27-Q2** | **A** — “A aventura começa somente com o protagonista; os companheiros iniciais serão obtidos por recrutamento.” | **Iniciar apenas com protagonista** e obter aliados via recrutamento. |
| **R27-Q3** | **B** — “Uma mesma dungeon pode misturar ambientes e mudar de tema ao longo da expedição; detalhes pendentes.” | **Ambientes/biomas mistos e mudanças possíveis de tema na dungeon**; como/quando pendente. |
| **R27-Q4** | **A** — “Novos Moves comuns são obtidos principalmente por nível/progressão, sem excluir mestres, HMs/TMs e outros meios aprovados.” | **Moves comuns principalmente por nível**, mantendo fontes complementares e regras anteriores. |
| **R27-Q5** | **C** — “moedas recursos itens” | **Moedas, recursos e itens como categorias de recompensa material em batalhas comuns**, não necessariamente todas em cada vitória; valores/regras pendentes. |

**Preservação:** R27-Q5 é a resposta C personalizada, sem transposição irrestrita das alternativas A/B. Regras D-001 a D-150, ATB/Burst, Nature, experiência dos participantes, slots e ausência de PP continuam válidas.

## 10.27. Rodada 28 — economia, combate e exploração ambiental (FECHADA)

**Status:** FECHADA — 5/5 respostas aprovadas em 2026-11-01, registradas como D-156 a D-160.

| ID | Resposta literal do criador | Regra aprovada / pendências |
| --- | --- | --- |
| **R28-Q1** | **A** — “Moedas são usadas principalmente para comprar itens e recursos em NPCs ou lojas; preços e catálogo pendentes.” | **Moedas para comércio com NPCs/lojas**, catálogo e preços pendentes. |
| **R28-Q2** | **C** — “alguns funcionarao passivament e alguns funcionarao automaticamente sendo consumidos como berries” | **Parte dos itens segurados concede efeitos passivos; parte é automaticamente ativada e consumida, como berries**, gatilhos/efeitos pendentes. |
| **R28-Q3** | **C** — “retorna ao local de encontro e stunna o inimigo por um tempo, nao pemitindo que ele se mova e encoste em vc por 3 segundos” | **Fuga com sucesso retorna ao local do encontro, com inimigo imobilizado e impedido de se mover/encostar por 3 segundos**; chance/chefes pendentes. |
| **R28-Q4** | **A** — “Mudanças de bioma dentro da dungeon podem alterar os inimigos, eventos e recompensas encontrados; listas e regras pendentes.” | **Biomas podem alterar encontros, eventos e recompensas**, listas pendentes. |
| **R28-Q5** | **A** — “Concluir uma dungeon concede principalmente avanço da campanha/desbloqueios; recompensas materiais adicionais permanecem opcionais e pendentes.” | **Prioridade a avanço/desbloqueios de campanha**, sem recompensa material garantida. |

**Preservação:** R28-Q2 e R28-Q3 são respostas C personalizadas, não equivalentes simplesmente às antigas alternativas A/B. Mantêm-se as 155 decisões anteriores, os custos ATB/Burst aprovados, a ausência de PP e a regra de perda de itens não segurados na derrota. Não registrar implementação sem verificação de código.

## 10.28. Rodada 29 — campanha, encontros especiais e identidade de dungeons (FECHADA)

**Status:** FECHADA — 5/5 respostas aprovadas em 2026-11-01, decisões D-161 a D-165.

| ID | Resposta literal do criador | Regra aprovada e pendências |
| --- | --- | --- |
| **R29-Q1** | **C** — “ambos” | **Lojas e NPCs comerciantes dentro e fora das dungeons**, no contexto de exploração e de progressão/seleção da campanha; detalhes pendentes. |
| **R29-Q2** | **A** — “Eventos especiais oferecem escolhas e situações narrativas com consequências para a exploração; eventos e efeitos específicos pendentes.” | **Eventos com escolhas e consequências**, catálogo pendente. |
| **R29-Q3** | **A** — “Permitir novas expedições a dungeons já concluídas, respeitando a geração procedural por exploração e com recompensas pendentes.” | **Novas expedições em dungeons concluídas**, geração por exploração, seed reproduzível e recompensas pendentes. |
| **R29-Q4** | **A** — “O chefe principal pode ter apoio de outros inimigos, mantendo no máximo três inimigos ativos.” | **Chefe pode ter inimigos de apoio**, sem exceder três ativos. |
| **R29-Q5** | **A** — “Aumentar progressivamente a dificuldade conforme o jogador avança pelos andares e desbloqueia novas dungeons; valores pendentes.” | **Escalada progressiva entre andares e dungeons**, números pendentes. |

**Preservação:** R29-Q1 é resposta C personalizada, não exige o hub futuro. A repetição de dungeons não revoga seeds nem layouts estáveis dentro de uma expedição. Decisões D-001 a D-160 preservadas; sem PP ou novos custos ATB/Burst.

## 10.29. Rodada 30 — retirada, eventos, chefes, repetição e equipe (FECHADA)

**Status:** FECHADA — 5/5 respostas aprovadas em 2026-11-01, decisões D-166 a D-170.

| ID | Resposta literal do criador | Regra aprovada e pendências |
| --- | --- | --- |
| **R30-Q1** | **A** — “Permitir retirar-se voluntariamente da dungeon antes do chefe e voltar à campanha, com consequências pendentes.” | **Saída voluntária antes do chefe**, retornando à campanha, com consequências ainda por decidir. |
| **R30-Q2** | **A** — “Consequências dos eventos narrativos ficam principalmente na expedição atual, sem persistência obrigatória entre dungeons.” | **Eventos de impacto principalmente local à expedição**, sem obrigação de persistência futura. |
| **R30-Q3** | **B** — “Chefes são principalmente inimigos mais difíceis dentro do sistema comum de combate, sem mecânicas ou fases exclusivas obrigatórias.” | **Chefes dentro das mecânicas usuais, com dificuldade maior**, sem fases especiais obrigatórias; apoio permitido conforme R29-Q4. |
| **R30-Q4** | **A** — “Novas expedições a dungeons concluídas continuam oferecendo oportunidades de obter Pokémon, itens e recursos, com regras pendentes.” | **Rejogar permite novas oportunidades de Pokémon, itens e recursos**, sem garantias de drop ou quantidades. |
| **R30-Q5** | **A** — “Pokémon recém-recrutados podem entrar diretamente na equipe ativa quando houver vaga, respeitando o máximo de três.” | **Entrada direta possível com vaga na equipe ativa**, preservando envio à reserva com equipe cheia. |

**Preservação:** as 165 decisões anteriores permanecem válidas. R30-Q1 não equipara abandono a derrota; R30-Q3 não revoga a possibilidade de inimigos auxiliares; R30-Q5 não obriga entrada automática. Não foram fixados números, fórmulas, PP nem novos custos ATB/Burst.

## 10.30. Rodada 31 — consequências de expedições, combate e progressão da equipe (FECHADA)

**Status:** FECHADA — 5/5 decisões aprovadas em 2026-11-01, registradas como D-171 a D-175.

| ID | Resposta literal do criador | Regra aprovada e pendências |
| --- | --- | --- |
| **R31-Q1** | **B** — “Ao abandonar voluntariamente, itens coletados que não estejam sendo segurados são perdidos, como na derrota definitiva.” | **Itens coletados não segurados perdidos na retirada**, preservação de itens segurados. Outros efeitos da retirada pendentes. |
| **R31-Q2** | **A** — “Se o protagonista cair em combate, a batalha continua com os aliados controlados pela IA, com condições de vitória e recuperação pendentes.” | **Aliados sob IA continuam batalha após queda do protagonista**; vitória/recuperação pendentes. |
| **R31-Q3** | **B** — “Experiência das vitórias fica restrita aos participantes ativos; reservados evoluem por outros meios a definir.” | **XP de vitória apenas aos participantes ativos**; progressão dos reservados por outros meios a definir. |
| **R31-Q4** | **A** — “Objetivos de campanha são apresentados principalmente por personagens, NPCs e acontecimentos narrativos.” | **Objetivos de campanha apresentados principalmente por NPCs e narrativa**; conteúdo pendente. |
| **R31-Q5** | **A** — “Pontos de descanso são locais seguros para pausa e preparação dentro das dungeons; serviços adicionais pendentes.” | **Pontos de descanso seguros para pausa/preparação**, MP restaurado conforme regras anteriores, demais serviços pendentes. |

**Preservação:** as 170 decisões anteriores e todo o histórico continuam válidos. Não presumir cura de HP em descanso, XP de combate para a reserva, derrota automática quando protagonista cai ou penalidades adicionais na retirada. Não inventar fórmulas, PP ou custos ATB/Burst.

## 10.31. Rodada 32 — sobrevivência da equipe, descanso e descobertas (FECHADA)

**Status:** FECHADA — 5/5 respostas aprovadas em 2026-11-01, decisões D-176 a D-180.

| ID | Resposta literal do criador | Regra aprovada e pendências |
| --- | --- | --- |
| **R32-Q1** | **A** — “Se os aliados vencerem após a queda do protagonista, ele poderá voltar à exploração mediante uma recuperação mínima, com condições pendentes.” | **Protagonista pode voltar após recuperação mínima**, condições não especificadas, vitória dos aliados sob IA preservada. |
| **R32-Q2** | **A** — “Pontos seguros de descanso também recuperam HP, além de restaurarem MP; quantidade e regras de cura de HP pendentes.” | **Descanso também recupera HP**; restauração integral de MP preservada, quantidade de HP pendente. |
| **R32-Q3** | **A** — “XP e níveis conquistados durante uma expedição são preservados após derrota definitiva ou retirada voluntária.” | **Manter XP e níveis ganhos em ambos os desfechos** sem revogar perda de itens coletados não segurados. |
| **R32-Q4** | **A** — “O mapa do andar é revelado progressivamente conforme o jogador explora.” | **Revelação gradual do mapa**, interface e persistência entre expedições pendentes. |
| **R32-Q5** | **B** — “Interagir com um Pokémon especial elegível inicia uma tarefa ou evento que precisa ser resolvido antes do recrutamento.” | **Recrutamento especial exige resolver tarefa/evento após interação**, sem estender o requisito a todo recrutamento. |

**Preservação:** 175 decisões anteriores inalteradas. Não definir valores de recuperação, fórmulas, novos PP, custos ATB/Burst, consequências adicionais de derrota ou obrigação de missões para Pokémon não especiais.

## 10.32. Rodada 33 — sobrevivência, reservas e exploração procedural (cinco perguntas abertas)

**Status:** ABERTA — 0/5 respostas. Nenhuma alternativa aprovada. Cinco questões de gameplay relevantes e ainda pendentes no GDD.

**R33-Q1 — Se todos os Pokémon ativos forem incapacitados durante uma batalha, qual será o desfecho da expedição?**  
A. **Considerar derrota definitiva e encerrar a exploração**, aplicando as perdas e preservações já aprovadas.  
B. **Oferecer uma possibilidade de resgate/continuação antes de declarar derrota definitiva**, com condições pendentes.  
C. Outro desfecho, descrito pelo criador.  
*A queda isolada do protagonista não encerra a batalha, e os aliados podem vencer; a derrota de toda a equipe ainda não tem desfecho explicitamente definido.*

**R33-Q2 — Como os Pokémon da reserva poderão evoluir e treinar sem receber XP das vitórias da equipe ativa?**  
A. **Por treinamento ou serviços específicos disponíveis fora das expedições**, com locais e regras pendentes.  
B. **Por atividades próprias ou missões de treinamento atribuídas aos reservados**, com condições e resultados pendentes.  
C. Outra forma ou combinação, descrita pelo criador.  
*O GDD exclui XP de vitória para os reservados, mas prevê progressão por outros meios ainda indefinidos.*

**R33-Q3 — Como será determinada a extensão de cada dungeon da campanha?**  
A. **Cada dungeon possui uma quantidade de andares definida pelo design**, ainda sem números aprovados; os layouts dos andares continuam procedurais.  
B. **A quantidade de andares pode variar entre expedições de uma mesma dungeon**, segundo regras de geração ainda a definir.  
C. Outro sistema, descrito pelo criador.  
*Concluir exige chegar ao último andar e derrotar um chefe, mas a quantidade de andares ainda não está definida.*

**R33-Q4 — Como o jogador descobrirá principalmente as salas secretas das dungeons?**  
A. **Pela observação do cenário e investigação de passagens escondidas**, com pistas e meios de acesso pendentes.  
B. **Por pistas, mapas especiais, NPCs ou eventos que indiquem ou liberem salas secretas**, com regras pendentes.  
C. Uma combinação ou outro mecanismo, descrito pelo criador.  
*Salas secretas já são opcionais e priorizam descobertas, NPCs e recompensas; ainda falta decidir sua descoberta.*

**R33-Q5 — Qual será a principal função dos recursos materiais recebidos em combates, além das moedas?**  
A. **Servir à fabricação ou preparação de itens e equipamentos**, com receitas, estações e catálogo pendentes.  
B. **Servir a trocas ou melhorias de Pokémon, itens e equipamentos por meio de serviços**, com regras e catálogo pendentes.  
C. Uma combinação ou outra função, descrita pelo criador.  
*Moedas já servem principalmente para compras; a utilização dos demais recursos materiais continua sem definição.*

## 11. Histórico de alterações do GDD

| Revisão | Data | Mudanças documentais | Rodada |
| --- | --- | --- | --- |
| 0.1 | 2026-11-01 | Criação inicial: decisões D-001 a D-020, auditoria documental do protótipo, pendências e perguntas R1-Q1 a R1-Q5. | Rodada 1 aberta |
| 0.2 | 2026-11-01 | Cinco respostas R1-Q1 a R1-Q5 consolidadas (D-021 a D-025): Burst armazenável, saldo residual de ATB, pausa somente em Tactic, tabela de recompensas, soma de crítico normal+fraqueza; rodada 2 aberta. Commit identificável pelo histórico Git deste arquivo. | Rodada 1 fechada / Rodada 2 aberta |
| 0.3 | 2026-11-01 | Rodada 2 (D-026 a D-030): Burst armazenado até uso na batalha, excedentes ATB extras distintos do Burst, custo duplo Move+Burst, Tactic apenas orienta IA (substitui ordens diretas), taxa de preenchimento baseada na Velocidade; abre Rodada 3. | Rodada 2 fechada / Rodada 3 aberta |
| 0.4 | 2026-11-01 | Rodada 3 (D-031 a D-035): múltiplos Bursts sem teto fixo, consumo prioritário de ATB extra, configuração Tactic gratuita, regeneração natural somente até 5 blocos normais, Moves Burst sem ATB por fraqueza ou crítico garantido; abre Rodada 4. | Rodada 3 fechada / Rodada 4 aberta |
| 0.5 | 2026-11-01 | Rodada 4 (D-036 a D-040): ATB extra sem teto fixo e com quadradinhos adicionais; Evade custa 3 na ativação; Tackle custa 2; IA decide Evade ativo e Tactic influencia prioridade. Rodada 5 aberta. | Rodada 4 fechada / Rodada 5 aberta |
| 0.6 | 2026-11-01 | Rodada 5 (D-041 a D-045): extras descartados ao fim de cada batalha; recompensas multi-alvo limitadas por ação e multi-hit por execução/alvo sob teto global; buff/debuff via Burst custa somente Burst; Tactic persiste dentro da dungeon. Rodada 6 aberta. | Rodada 5 fechada / Rodada 6 aberta |
| 0.7 | 2026-11-01 | Rodada 6 (D-046 a D-050): início de batalha com 0/5 ATB; ITENS custa 1 ATB por uso; equipe de até 3; opção configurável de reinício/persistência de Tactic ao sair da dungeon; quatro Moves com custo-base de 2 ATB e exceções. Abre Rodada 7. | Rodada 6 fechada / Rodada 7 aberta |
| 0.8 | 2026-11-01 | Rodada 7 (D-051 a D-055): padrão reiniciar Tactic ao sair da dungeon, ATB de referência 0/5 → 5/5 em 5 s, quatro Moves sem PP, até três inimigos ativos e mapas 2D procedurais por exploração/andar. Abre Rodada 8. | Rodada 7 fechada / Rodada 8 aberta |
| 0.9 | 2026-11-01 | Rodada 8 (D-056 a D-060): ATB inversamente proporcional à Velocidade; correção geral — não existe PP, inclusive em Tackle; seeds reproduzíveis; salas/corredores algorítmicos; encontros por contato com Pokémon visíveis na exploração 2D. Abre Rodada 9. | Rodada 8 fechada / Rodada 9 aberta |
| 1.0 | 2026-11-01 | Rodada 9 (D-061 a D-065): Velocidade de referência adiada até definição de atributos; layout procedural preservado ao revisitar andar; inimigos patrulham e perseguem após detecção, são removidos ao serem derrotados na exploração atual; movimento cardinal em quatro direções. Abre Rodada 10 para definir os atributos/status. | Rodada 9 fechada / Rodada 10 aberta |
| 1.1 | 2026-11-01 | Rodada 10 (D-066 a D-070): modelo de atributos de SMT III como referência; escala-base 1–100, progressão por níveis, buffs/debuffs em estágios e Velocidade de referência fixa ainda sem número. Adaptação de Agilidade/Velocidade, HP, Magia e Sorte pendente; abre Rodada 11. | Rodada 10 fechada / Rodada 11 aberta |
| 1.2 | 2026-11-01 | Rodada 11 (D-071 a D-075): Agilidade e Velocidade unificadas; HP derivado de Vitalidade+nível; Magia ligada a dano/efeitos mágicos e MP separado aprovado; pontos de atributos distribuídos manualmente por nível; Sorte influencia probabilidades de combate. Regras numéricas de MP, HP, progressão e Sorte pendentes; abre Rodada 12. | Rodada 11 fechada / Rodada 12 aberta |
| 1.3 | 2026-11-01 | Rodada 12 (D-076 a D-080): Moves mágicos/especiais consomem MP além de ATB/Burst, MP máximo derivado de Magia+nível, MP restante preservado entre batalhas na dungeon, pontos fixos por nível ainda sem valor, distribuição manual só do protagonista e crescimento automático dos aliados; abre Rodada 13. | Rodada 12 fechada / Rodada 13 aberta |
| 1.4 | 2026-11-01 | Rodada 13 (D-081 a D-085): custo-base comum de MP com exceções individuais (valores pendentes); recuperação de MP por itens e pontos de descanso; MP máximo ao iniciar nova exploração; protagonista recebe 1 ponto distribuível por nível; aliados crescem por curvas de espécie. Abre Rodada 14. | Rodada 13 fechada / Rodada 14 aberta |
| 1.5 | 2026-11-01 | Rodada 14 (D-086 a D-090): MP descontado na ativação; recuperação de 1/4 do MP a cada 3 s sob ATB 5/5 e descanso com MP completo; HP persiste entre batalhas; ponto do protagonista obrigatório na subida de nível; ganho de atributos de aliados depende de forma de lutar/táticas, aleatoriedade de recrutáveis e Natures. Rodada 15 aberta. | Rodada 14 fechada / Rodada 15 aberta |

| 1.6 | 2026-11-01 | Rodada 15 (D-091 a D-095): recuperação de 25% do MP máximo a cada 3 s consecutivos sob ATB 5/5, zerando contador ao sair de 5/5; crescimento de aliados considera tática e ações executadas; Natures influenciam atributos/crescimento/comportamento; recrutáveis aleatórios recebem tática inicial sorteada conforme Nature. Abre Rodada 16. | Rodada 15 fechada / Rodada 16 aberta |

| 1.7 | 2026-11-01 | Rodada 16 (D-096 a D-100): recuperação periódica de MP arredondada para baixo; contador zerado em MP máximo; telemetria considerando a maioria das ações, ainda sem janela/fórmula; Nature de recrutáveis aleatórios sorteada na geração; Tactic escolhida prevalece no comportamento enquanto ativa, mantendo Nature para atributos/crescimento. Abre Rodada 17. | Rodada 16 fechada / Rodada 17 aberta |

| 1.8 | 2026-11-01 | Rodada 17 (D-101 a D-105): histórico acumulado da telemetria, frequência de ações independentemente de sucesso, tática como influência principal no crescimento; Nature sorteada na geração do protagonista/eventos (R17-Q4 C indicando B); contador de MP pausa durante Tactic. Abre Rodada 18. | Rodada 17 fechada / Rodada 18 aberta |

| 1.9 | 2026-11-01 | Rodada 18 (D-106 a D-110): histórico de telemetria acompanha o mesmo Pokémon entre dungeons/explorações; categorias amplas de ataques físicos/mágicos, defesa/esquiva, suporte e itens; cada Move multi-hit/multi-alvo conta uma ação por execução na telemetria; Nature do protagonista é sorteada novamente no início de cada exploração; Natures alteram atributos-base. Abre Rodada 19 para detalhes ainda pendentes. | Rodada 18 fechada / Rodada 19 aberta |

| 1.10 | 2026-11-01 | Rodada 19 (D-111 a D-115): telemetria preservada após saída e retorno do mesmo aliado; até duas categorias por ação (R19-Q2 C), mantendo uma execução como uma ação; registro no início efetivo da execução; pontos manuais do protagonista preservados ao sortear nova Nature, substituindo apenas seus efeitos; modificadores de Nature flexíveis sem pares positivos/negativos obrigatórios. Abre Rodada 20. | Rodada 19 fechada / Rodada 20 aberta |

| 1.11 | 2026-11-01 | Rodada 20 (D-116 a D-120): categorias principais da ficha de ação/Move selecionadas quando mais de duas são possíveis (prioridade pendente); ação com duas categorias conta uma ocorrência em cada sem multiplicar execuções; telemetria preservada sem acumular ações fora da equipe; proporção de HP/MP atual preservada se novos máximos forem alterados por Nature (arredondamento pendente); Natures neutras nos atributos-base permitidas, com efeitos futuros de crescimento/comportamento possíveis. Abre Rodada 21. | Rodada 20 fechada / Rodada 21 aberta |

| 1.12 | 2026-11-01 | Rodada 21 (D-121 a D-125): prioridade de categorias definida na ficha de cada ação/Move; item com suporte classificado somente como item; tática selecionada desempata frequência igual; HP/MP proporcional após alteração do máximo por Nature arredondado para baixo; Nature neutra nos atributos-base pode afetar crescimento/comportamento. Abre Rodada 22. | Rodada 21 fechada / Rodada 22 aberta |

| 1.13 | 2026-11-01 | Rodada 22 (D-126 a D-130): registrar as categorias da ficha do Move desde o início da execução mesmo quando um componente não ocorre; classificação e prioridade por tipo de ação para não-Moves; tática selecionada na subida de nível desempata categorias; preservar HP mínimo positivo quando arredondamento proporcional por Nature produzir zero em Pokémon antes vivo; atributos-base após Nature limitados a 1–100. Abre Rodada 23. | Rodada 22 fechada / Rodada 23 aberta |

| 1.14 | 2026-11-01 | Rodada 23 reformulada (D-131 a D-135): exploração 2D cardinal contínua; último andar e chefe para conclusão; derrota definitiva encerra exploração; recrutamento por interação/aproximação em mapa 2D sem revogar encontros hostis; aprendizado combinado com mestres e possíveis NPCs que concedem HMs. Perguntas antigas não aprovadas da R23 substituídas; R24 aberta com foco em gameplay. | Rodada 23 fechada / Rodada 24 aberta |

| 1.15 | 2026-11-01 | Rodada 24 (D-136 a D-140): escadas/saídas para avançar sem limpar todos inimigos; recrutamento voluntário no mapa; reserva com equipe ativa completa; HMs e TMs exclusivamente de combate (C); Pokémon recrutados mantidos após derrota definitiva. Abre Rodada 25 com perguntas centrais de campanha, equipe, evolução e exploração. | Rodada 24 fechada / Rodada 25 aberta |

| 1.16 | 2026-11-01 | Rodada 25 (D-141 a D-145): campanha com desbloqueio progressivo de dungeons; trocas equipe/reserva provisoriamente durante exploração, hub futuro ainda não definido (R25-Q2 C); evolução de espécie mediante requisitos sob escolha do jogador; derrota preserva somente itens segurados dentre os obtidos na expedição (R25-Q4 C), perdendo os demais obtidos; priorizar eventos, salas secretas, recompensas especiais e NPCs. Abre Rodada 26 com foco em protagonista, recrutamento, XP e conclusão. | Rodada 25 fechada / Rodada 26 aberta |

| 1.17 | 2026-11-01 | Rodada 26 (D-146 a D-150): jogador escolhe espécie inicial do protagonista; Pokémon normalmente hostis podem aparecer como recrutáveis especiais identificados em mapa, preservando interação voluntária/contatos hostis; XP de vitória para todos os Pokémon ativos participantes sem exigência de golpe final; chefe do último andar encerra expedição e devolve seleção/progressão da campanha; salas secretas opcionais para recompensas/eventos/NPCs. Abre Rodada 27 sobre combates, companheiros, variedade ambiental, Moves e recompensas. | Rodada 26 fechada / Rodada 27 aberta |

| 1.18 | 2026-11-01 | Rodada 27 (D-151 a D-155): tentativas de fuga em combates comuns; aventura começa somente com protagonista e companheiros recrutados; dungeons podem misturar ambientes e mudar de tema; Moves comuns principalmente por nível sem excluir fontes combinadas; moedas, recursos e itens como categorias de recompensa de batalhas comuns (R27-Q5 C), sem drops garantidos. Abre Rodada 28 sobre economia, itens segurados, fuga, biomas e conclusão de dungeons. | Rodada 27 fechada / Rodada 28 aberta |

| 1.19 | 2026-11-01 | Rodada 28 (D-156 a D-160): moedas para comprar itens e recursos de NPCs/lojas; itens segurados passivos ou automaticamente consumidos como berries (R28-Q2 C); fuga bem-sucedida retorna ao encontro e impede inimigo de mover/encostar por 3 segundos (R28-Q3 C); biomas podem alterar inimigos/eventos/recompensas; conclusão de dungeon prioriza progressão/desbloqueios, materiais opcionais. Abre Rodada 29 sobre comércio, eventos, revisitas, chefes e dificuldade. | Rodada 28 fechada / Rodada 29 aberta |

| 1.20 | 2026-11-01 | Rodada 29 (D-161 a D-165): NPCs/lojas dentro e fora das dungeons (C — “ambos”); eventos especiais com escolhas e consequências; novas expedições a dungeons já concluídas com geração procedural e seed reproduzível; chefe principal pode ter aliados até três inimigos ativos; dificuldade progressivamente crescente por andar e campanha. Abre Rodada 30 sobre retirada, persistência de eventos, chefes, repetição e recrutamento. | Rodada 29 fechada / Rodada 30 aberta |

| 1.21 | 2026-11-01 | Rodada 30 (D-166 a D-170): permitir retirada voluntária antes do chefe retornando à campanha, sem consequências ainda definidas; escolhas narrativas com efeitos principalmente locais à expedição; chefes principalmente dentro do combate comum sem fases exclusivas obrigatórias; revisitas a dungeons concluídas ainda oferecem oportunidades de Pokémon, itens e recursos; Pokémon recrutados podem entrar diretamente na equipe quando há vaga. Abre Rodada 31 sobre retirada, derrota em equipe, reserva, campanha e descanso. | Rodada 30 fechada / Rodada 31 aberta |

| 1.22 | 2026-11-01 | Rodada 31 (D-171 a D-175): retirada voluntária perde itens coletados não segurados como na derrota, sem equiparar outros efeitos; aliados sob IA continuam combate após queda do protagonista; XP de vitórias restrita a participantes ativos, excluindo reserva; objetivos de campanha apresentados principalmente por NPCs/personagens/narrativa; descanso em locais seguros com pausa/preparação, mantendo restauração de MP já aprovada. Abre Rodada 32 sobre continuidade após queda, cura no descanso, persistência de XP, descoberta de mapas e recrutamento. | Rodada 31 fechada / Rodada 32 aberta |

| 1.23 | 2026-11-01 | Rodada 32 (D-176 a D-180): protagonista pode voltar à exploração mediante recuperação mínima após vitória dos aliados; descanso seguro cura HP além de restaurar integralmente MP; XP e níveis da expedição persistem após derrota definitiva ou retirada voluntária; mapa do andar revelado progressivamente; recrutamento especial exige resolver tarefa/evento iniciado por interação. Abre Rodada 33 sobre derrota de equipe, treino de reservas, quantidade de andares, salas secretas e uso de recursos. | Rodada 32 fechada / Rodada 33 aberta |

> **Regra de preservação:** nas atualizações posteriores, não reescrever seções não relacionadas nem transformar hipóteses em decisões. Preservar este histórico, acrescentando entradas rastreáveis, e nunca afirmar que uma decisão foi implementada sem verificar o código e, quando cabível, executar testes.
