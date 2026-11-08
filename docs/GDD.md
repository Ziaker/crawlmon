# CRAWLMON — Game Design Document (GDD)

> **Estado:** documento vivo de design, com decisões aprovadas e pendências explícitas.  
> **Revisão:** 1.59 — regras do Guard e barreira reservada registradas em adendo rastreável (§12.34, 2026-11-05); histórico preservado.  
> **Repositório:** [Ziaker/crawlmon](https://github.com/Ziaker/crawlmon).  
> **Referência histórica de inspeção de código na revisão 1.29:** branch `main`, commit `1171b5f3c427edc34c486c82d42569f41fd0ea62`.  
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

**APROVADO (R23-Q5 = C):** resposta literal **“combinacao com mestres e possiveis personagens que dao hms”**. O sistema de aprendizado de Moves admite **fontes combinadas, incluindo mestres e possíveis personagens que concedem HMs**. **APROVADO posteriormente (R24-Q4 = C):** HMs e TMs são **somente para combate por enquanto**, sem funções de exploração. **ATUALIZAÇÃO R38-Q5:** a relação de HMs/TMs com **até oito Moves utilizáveis e quatro principais de hotkeys rápidas** permanece pendente, assim como obtenção e demais fontes. Não presumir custos.

**APROVADO (R25-Q3 = A):** quando um Pokémon **satisfizer os requisitos para sua evolução de espécie**, **o jogador poderá escolher quando efetuar a evolução**, em vez de ela ocorrer obrigatoriamente de forma automática assim que o requisito for atingido. **PENDENTE:** requisitos por espécie, interface, possíveis restrições e efeitos de evolução; não confundir com subida de nível ou distribuição de atributos.

**APROVADO (R26-Q1 = A) — protagonista inicial:** o jogador **escolhe seu Pokémon protagonista entre espécies iniciais disponíveis**. **PENDENTE:** quais espécies compõem o catálogo, interface de escolha e demais aspectos da apresentação. A escolha da espécie **não substitui nem altera** as regras já aprovadas de sorteio da Nature do protagonista.

**APROVADO (R26-Q2 = B) — candidatos especiais ao recrutamento:** **Pokémon normalmente hostis podem aparecer em situações especiais como candidatos a recrutamento, identificados no mapa da exploração 2D**. O candidato elegível ainda exige **interação voluntária explícita** (R24-Q2). **Encontros hostis normais continuam iniciando combate 3D por contato** (R8-Q5). **PENDENTE:** natureza da identificação visual, eventos/requisitos para aparecer como candidato e condições concretas para recrutamento. Não inferir recrutamento automático nem que todo inimigo possa ser recrutado em qualquer encontro.

**APROVADO (R26-Q3 = A) — experiência de batalha:** **todos os Pokémon ativos que participarem de uma batalha vencida recebem experiência, independentemente de aplicar o golpe final**. **PENDENTE:** quantidades, divisão de experiência, tratamento de Pokémon que ficaram na reserva, situações com membros incapacitados e demais condições especiais. A evolução por nível, a distribuição manual de pontos do protagonista e o crescimento automático de aliados permanecem inalterados.

**APROVADO (R26-Q4 = A) — depois do chefe:** **ao vencer o chefe do último andar, a dungeon é concluída, a expedição se encerra e o jogador retorna à seleção/progressão da campanha**. **PENDENTE:** recompensas, apresentação de resultados e critérios dos novos desbloqueios. Esse retorno não cria nem exige um hub implementado; a intenção de hub futuro de R25-Q2 permanece pendente.

**APROVADO (R26-Q5 = A) — salas secretas:** as **salas secretas das dungeons são descobertas opcionais voltadas a recompensas, eventos e NPCs especiais**, **sem obrigatoriedade de encontrá-las para alcançar o chefe**. **PENDENTE:** conteúdo concreto, como descobrir/acessar as salas e distribuição procedural. A prioridade dada a salas secretas em R25-Q5 permanece válida.

**APROVADO (R27-Q1 = A) — fuga de combates comuns:** o jogador **pode tentar fugir de combates comuns**, com **condições, consequências e restrições ainda pendentes**; o tratamento de combates contra chefes não está definido. A possibilidade de tentar não equivale a fuga garantida. Não presumir custo ATB/Burst, chance de sucesso ou novo comando de interface sem decisão adicional.

**APROVADO (R27-Q2 = A) — equipe inicial:** **a aventura começa somente com o Pokémon protagonista escolhido pelo jogador**, sem companheiros iniciais; o jogador **forma sua equipe mediante recrutamento** durante a aventura. Preservar equipe ativa máxima de três Pokémon (protagonista e até dois aliados IA) e regras de reserva.

**APROVADO (R27-Q3 = B) — ambientes das dungeons:** **uma mesma dungeon pode conter ambientes mistos e mudar de tema ao longo de uma expedição**. **PENDENTE:** quais biomas/temas existem, como ocorrem as mudanças, sua influência na geração e no gameplay. Esta decisão não exige que toda dungeon sempre mude de bioma e não altera a geração procedural aprovada.

**APROVADO (R27-Q4 = A) — aprendizado de Moves comuns:** **o nível e a progressão do Pokémon são a fonte principal de novos Moves comuns**, **sem excluir mestres, HMs/TMs de combate e outros meios anteriormente aprovados**. **ATUALIZAÇÃO R38-Q5 = C:** o Pokémon pode ter **até oito Moves utilizáveis em combate**, com **quatro principais para hotkeys rápidas**, além do Tackle genérico separado conforme regra anterior. **PENDENTE:** listas por espécie, requisitos, ritmo, aprendizado e gerenciamento dos Moves; não criar PP nem alterar custos ATB/Burst.

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

**APROVADO (R33-Q1 = A) — derrota definitiva da equipe:** **se todos os Pokémon ativos forem incapacitados durante uma batalha, ocorre derrota definitiva e a expedição é encerrada**, aplicando as perdas e preservações previamente aprovadas, inclusive preservação de XP/níveis e Pokémon recrutados e perda de itens obtidos na expedição que não estiverem sendo segurados. **A queda isolada do protagonista não implica derrota** enquanto aliados puderem continuar lutando (R31-Q2).

**APROVADO (R33-Q2 = A) — progressão de reservados:** **Pokémon na reserva podem progredir por treinamento ou serviços específicos disponíveis fora das expedições**. **PENDENTE:** acesso, requisitos, locais, resultados e como esses serviços concedem progressão. Reservados continuam **sem ganhar XP das vitórias da equipe ativa** (R31-Q3). Não presumir a existência ou a implementação do hub futuro (R25-Q2).

**APROVADO (R33-Q3 = B) — quantidade variável de andares:** **a quantidade de andares de uma mesma dungeon pode variar de uma expedição para outra**, conforme regras de geração ainda pendentes. **PENDENTE:** critérios da variação e quantidade de andares, sem números aprovados. Preservar geração por exploração/andar, layout estável durante uma expedição, seed reproduzível e chefe no último andar.

**APROVADO (R33-Q4 = B) — descoberta das salas secretas:** **salas secretas são descobertas principalmente por pistas, mapas especiais, NPCs ou eventos que revelem ou liberem seu acesso**. **PENDENTE:** tipos de pistas, mapas, eventos, distribuição e condições de acesso. Continuam opcionais para alcançar o chefe.

**R33-Q5 — QUESTÃO REJEITADA, NÃO APROVADA:** resposta literal do criador: **“que recursos obtidos? já começou as perguntas idiotas redundates dnv??”**. Esta é uma **objeção à pergunta**, não a aprovação da alternativa C nem autorização para definir fabricação, materiais, sistemas de crafting ou melhorias. O histórico R27-Q5 registra literalmente “moedas recursos itens” como categorias gerais de recompensas, mas **não há catálogo, identidade nem função dos recursos definida**. Não repetir essa pergunta genérica sem esclarecer primeiro o objeto de jogo; **nenhuma decisão D-185 foi criada**.

**APROVADO (R34-Q1 = B) — narrativa por dungeon:** **a campanha é organizada em histórias e missões relativamente independentes por dungeon**, com progressão geral mais aberta. **Mantém-se o desbloqueio progressivo de dungeons por conquistas e objetivos** (R25-Q1), sem inferir disponibilidade de todas as dungeons desde o início. **PENDENTE:** conteúdos e personagens das histórias e missões, vínculos entre elas e critérios de desbloqueio.

**APROVADO (R34-Q2 = B) — prioridades da exploração:** **a exploração prioriza encontros, salas e eventos narrativos, sem tornar enigmas ou armadilhas um sistema central**. Essa prioridade não proíbe desafios ambientais opcionais; tipos e ocorrências permanecem pendentes. Mantêm-se NPCs e salas secretas já aprovados.

**APROVADO (R34-Q3 = B) — sequência entre andares:** **a progressão principal entre andares da dungeon é sequencial**, com salas, corredores e opções de caminho variadas dentro de cada andar. **Mantêm-se as escadas/saídas para avançar sem eliminar todos os inimigos** (R24-Q1) e a quantidade de andares variável entre expedições (R33-Q3). Não aprovar ramificações entre andares como percurso principal.

**APROVADO (R34-Q4 = B) — chefes variáveis:** **o chefe final pode variar entre expedições da mesma dungeon**, com catálogo e condições de escolha ainda pendentes. Mantêm-se o chefe no último andar, o combate principalmente pelas regras usuais e o máximo de três inimigos ativos, incluindo eventuais aliados do chefe. Não fixar aleatoriedade específica ou exigir chefe diferente em toda repetição.

**APROVADO (R34-Q5 = C) — capacidade do inventário (regra histórica, refinada em R35-Q3):** resposta literal **“10 itens não contando segurados”**. A decisão originalmente fixou **10 itens transportados, sem contar os itens segurados**. **COMPLEMENTO E ATUALIZAÇÃO EXPRESSA (R35-Q3 = C):** o limite de 10 é **por Pokémon integrante da equipe ativa**, totalizando **até 30 itens não segurados com três integrantes ativos**, sem permitir que um único integrante carregue mais de 10. **R35-Q3 também aprovou a alternativa A para inventário cheio:** escolher um item carregado para deixar/trocar antes de recolher outro. **PENDENTE:** itens empilhados, operações entre integrantes, vagas ao mudar equipe, limite/quantidade de itens segurados, detalhes de descarte e interface. Não modificar a decisão histórica D-189, preservada no ledger.

**APROVADO (R35-Q1 = A) — aliados visíveis em 2D:** **os Pokémon aliados ativos acompanham visualmente o protagonista no mapa 2D durante a exploração**. O controle direto permanece exclusivo do protagonista; aliados continuam orientados pela IA. **PENDENTE:** formação, deslocamento, colisões, reações e comportamento visual da equipe no mapa. Não tornar reservados seguidores nem transferir controle direto a eles.

**APROVADO (R35-Q2 = A) — recrutamento comum:** **Pokémon elegíveis comuns oferecem oportunidade de recrutamento por interação voluntária direta no mapa 2D**, sujeitos a requisitos de elegibilidade ainda pendentes. **Pokémon especiais seguem exigindo tarefa/evento prévio à efetivação do recrutamento** (R32-Q5), e contatos hostis normais continuam iniciando combate 3D (R8-Q5). Não inferir recrutamento automático por aproximação nem chance de sucesso específica.

**APROVADO (R35-Q3 = C) — limite individual e inventário cheio:** resposta literal **“cada aliado tem 10 itens de limte, entao no geral tem 30 items mas cada aliado tem até 10, alias opção A”**. **Cada um dos três integrantes possíveis da equipe ativa, incluindo o protagonista, pode transportar até 10 itens não segurados**, totalizando **até 30 itens quando a equipe ativa tem três integrantes**. Nenhum integrante pode concentrar os 30 itens. **Ao encontrar novo item com o inventário correspondente cheio, é possível escolher um item carregado para deixar/trocar antes de recolher o novo** (alternativa A expressamente indicada). Mantêm-se os **itens segurados fora dessa contagem** (R34-Q5). **PENDENTE:** capacidade quando integrantes saem/entram, distribuição e transferência de itens, empilhamento, quantidade de itens segurados, consequências de descartar, interface e coleta concreta.

**APROVADO (R35-Q4 = A) — chefes sem fuga:** **não é permitida tentativa de fuga durante combates contra chefes**, ressalvadas eventuais exceções futuras a decidir. **A tentativa de fuga em combates comuns permanece permitida** (R27-Q1), com regras de êxito e fuga bem-sucedida aprovadas em R28-Q3. Não criar custos ou chances novos.

**APROVADO (R35-Q5 = B) — narrativa variável por expedição:** **histórias e missões também podem variar entre expedições da mesma dungeon por eventos e situações procedurais**, com conteúdo e regras pendentes. **Mantêm-se histórias/missões relativamente independentes por dungeon** (R34-Q1) e campanha que desbloqueia dungeons mediante conquistas/objetivos (R25-Q1). Não afirmar que todas as missões variam ou que NPCs/conteúdo sejam inteiramente aleatórios.

**APROVADO (R36-Q1 = A) — comportamento dos aliados ativos no mapa 2D:** **os aliados ativos acompanham o protagonista em grupo e permanecem próximos durante a exploração**. **PENDENTE:** formação, deslocamento, colisões, desvio de obstáculos e demais detalhes. Não transformar esse acompanhamento em exploração autônoma de áreas distantes; o protagonista segue como único controlado diretamente (R35-Q1).

**APROVADO (R36-Q2 = A) — missões secundárias e chefe:** **missões e eventos secundários não impedem o acesso ao chefe quando o jogador alcança o último andar**. A dungeon permanece concluída somente quando o chefe é vencido (R23-Q2). **PENDENTE:** conteúdo e objetivos de missões principais da campanha; não eliminar objetivos de desbloqueio de outras dungeons (R25-Q1) nem transformar salas secretas em obrigatórias (R26-Q5).

**APROVADO (R36-Q3 = A) — persistência de itens e eventos na revisita:** **itens já coletados e eventos já concluídos mantêm seu estado ao revisitar um andar na mesma expedição e não são reiniciados automaticamente**. Permanecem preservados o layout do andar (R9-Q2) e a remoção dos inimigos derrotados nessa exploração (R9-Q4). **PENDENTE:** novas expedições, eventos ainda incompletos e ocorrências especiais não especificadas. Não criar respawn ou reset implícito ao subir/descer escadas.

**APROVADO (R36-Q4 = A) — preservação dos Pokémon após retirada:** **Pokémon recrutados durante a expedição permanecem pertencendo ao jogador mesmo após retirada voluntária**, assim como após derrota definitiva (R24-Q5). A retirada continua fazendo perder **itens obtidos na expedição que não estiverem sendo segurados** (R31-Q1), mas preserva XP/níveis (R32-Q3). Não presumir que a retirada conclua a dungeon ou que preserve itens não segurados.

**APROVADO (R36-Q5 = A) — espécies características por dungeon:** **cada dungeon tem um conjunto de espécies de Pokémon característico, com variações internas por bioma**. **PENDENTE:** quais espécies, catálogos, distribuição por bioma, inclusão de espécies em mais de uma dungeon e regras de geração. Preservar a possibilidade de mudanças de bioma afetarem encontros (R28-Q4); não exigir exclusividade absoluta das espécies por dungeon.

**APROVADO (R37-Q1 = A) — contatos hostis com a equipe:** **o contato de um inimigo hostil com qualquer Pokémon da equipe ativa presente no mapa 2D pode iniciar um combate 3D**, inclusive quando o inimigo encosta em um aliado acompanhante. **PENDENTE:** resolução de múltiplos contatos simultâneos, posicionamento, transição e regras concretas da colisão. Não revogar o controle direto exclusivo do protagonista nem fazer Pokémon elegíveis para recrutamento iniciar combate por mera aproximação.

**APROVADO (R37-Q2 = A) — missões secundárias entre expedições:** **o progresso de missões secundárias fica principalmente restrito à expedição atual e normalmente é reiniciado em uma nova tentativa**. **PENDENTE:** exceções, missões concretas e quais efeitos persistem. **Na mesma expedição**, eventos concluídos e coletas registradas seguem preservados nas revisitas aos andares (R36-Q3). Não generalizar reinício às missões principais da campanha ou à progressão de XP/níveis já preservada.

**APROVADO (R37-Q3 = A) — desbloqueios principais de campanha:** **desbloquear novas dungeons depende principalmente de concluir outras dungeons e vencer seus chefes**, com objetivos narrativos funcionando como caminhos complementares. **PENDENTE:** sequência, requisitos exatos, missões e exceções. Preservar apresentação de objetivos por NPCs/personagens/acontecimentos (R31-Q4), histórias relativamente independentes (R34-Q1) e missões secundárias não obrigatórias para enfrentar o chefe (R36-Q2).

**APROVADO (R37-Q4 = A) — conjunto selecionado de iniciais:** **o jogador escolhe o Pokémon protagonista entre um conjunto selecionado de espécies iniciais**, com catálogo, critérios e interface ainda pendentes. Essa escolha não libera todas as espécies nem inventa uma lista; mantém a Nature do protagonista conforme as regras de sorteio anteriores (R26-Q1).

**APROVADO (R37-Q5 = B) — dificuldade em novas visitas:** **a dificuldade de dungeons já concluídas também pode adaptar-se à progressão ou à força atual da equipe quando revisitadas**, com critérios, alcance e limites ainda pendentes. **Mantém-se a progressão geral de dificuldade por andares e novas dungeons** (R29-Q5); não aplicar escalonamento obrigatório universal, fórmula, níveis ou multiplicadores não aprovados.

**APROVADO (R38-Q1 = B) — detecção de inimigos:** **inimigos patrulhando a exploração 2D detectam o grupo principalmente por proximidade, sem exigir linha de visão estrita**. **PENDENTE:** alcance, condições, obstáculos, comportamento de perseguição e interrupção da perseguição; não concluir que paredes nunca interferem. Mantêm-se patrulha, perseguição após detecção (R9-Q3) e início de combate por contato hostil com qualquer ativo (R37-Q1).

**APROVADO (R38-Q2 = A) — arenas 3D por ambiente:** **a arena de batalha 3D reflete visualmente o bioma e ambiente do ponto onde o encontro ocorreu no mapa 2D**. A transição continua levando a **uma cena 3D separada** (D-003). **PENDENTE:** catálogo de cenários, correspondências por bioma, variações e efeitos concretos do ambiente na jogabilidade; não presumir bônus, colisões ou modificadores por bioma.

**APROVADO (R38-Q3 = B) — capacidade da reserva:** **a reserva de Pokémon é limitada em capacidade**. **PENDENTE:** quantidade máxima, gerenciamento dos excedentes, acesso e transições entre ativos/reserva. Não escolher valor arbitrário nem revogar a possibilidade de enviar recrutas à reserva quando os três ativos estiverem ocupados (R24-Q3).

**APROVADO (R38-Q4 = A) — inventário ao mover Pokémon para reserva:** **os itens transportados permanecem associados ao Pokémon ao sair da equipe ativa e ir para a reserva**, com acesso, manuseio e restrições pendentes. A capacidade de **até dez itens não segurados por Pokémon ativo**, totalizando até trinta com três (R35-Q3), continua válida; não estabelecer novo teto ou inventário compartilhado. **A associação ao Pokémon não altera a perda de itens coletados na expedição que não estejam segurados** após derrota definitiva ou retirada voluntária (R25-Q4/R31-Q1).

**APROVADO (R38-Q5 = C) — oito Moves no combate e quatro hotkeys:** resposta literal **“Pode ter até 8 moves no combate, os 4 principais servem mais para hotkeys rapidas”**. **Um Pokémon pode ter até oito Moves utilizáveis em combate, dos quais quatro são os principais destinados a hotkeys rápidas**. A decisão **atualiza expressamente o antigo limite de quatro Moves equipados como total de opções em combate**, registrado nas rodadas anteriores. O **Tackle genérico permanece separado dos espaços de Move**, como nas regras históricas, sem uma nova decisão que o inclua entre os oito. **PENDENTE:** escolha/armazenamento de Moves conhecidos, critérios para os oito disponíveis, organização dos quatro principais, forma de acessar os demais e eventual relação das posições extras com custos já documentados. **Não alterar os custos ATB/Burst/MP previamente aprovados, nem criar PP, custos para os quatro adicionais ou hotkeys específicas sem decisão.**













 **APROVADO posteriormente (R23-Q1 = A):** movimento contínuo e livre nas quatro direções cardeais, sem movimento diagonal direto. **PENDENTE:** controles, colisão e animação.

**PENDENTE:** sprites 2D, geração procedural, seeds e passagens; **alcance e condições de detecção principalmente por proximidade** (R38-Q1), perseguição e colisões de inimigos com qualquer integrante ativo; estados de expedições, catálogo de espécies iniciais/dungeons/biomas, recrutamento, **limite numérico e gerenciamento de uma reserva de capacidade limitada** (R38-Q3), hub, evolução, XP e treinamento; **inventário de 10 itens não segurados por Pokémon ativo (até 30 com três), redistribuição/empilhamento e acesso aos itens que permanecem com o Pokémon ao ir para a reserva** (R38-Q4), itens segurados, recuperação do protagonista, **catálogo de arenas 3D visualmente correspondentes ao ambiente do encontro** (R38-Q2) e efeitos de arena não aprovados, transições, formação do grupo de aliados, missões secundárias, desbloqueios principalmente por chefes, fuga comum, **seleção e acesso a até oito Moves utilizáveis com quatro principais para hotkeys** (R38-Q5), sem PP ou custos novos, lojas e recompensas, chefes, cura e interface, dificuldade adaptativa nas revisitas. Manter missões secundárias opcionais para enfrentar o chefe, persistência de eventos dentro da mesma expedição e posse de recrutados após retirada voluntária. “Recursos” genéricos seguem indefinidos; a pergunta R33-Q5 foi rejeitada.

### Fluxo de experiência (somente encadeamento conceitual)

Explorar uma dungeon 2D em movimentação cardinal contínua → encontrar adversário → combater em 3D com ATB → retornar à exploração quando permitido ou encerrar em derrota definitiva → alcançar último andar e derrotar chefe para concluir a dungeon. Fuga e demais consequências pendentes.

**IMPLEMENTADO/OBSERVADO:** já existe uma transição básica 2D/3D no protótipo. Isso não confirma que o fluxo completo acima, inclusive fuga, recursos e consequências, esteja implementado.

## 2. Interface de batalha — quatro comandos (APROVADO)

| Comando | Intenção e comportamento aprovado | O que permanece indefinido |
| --- | --- | --- |
| **1 — FIGHT** | Apresenta **Tackle físico genérico** e, após R38-Q5 = C, **até oito Moves utilizáveis em combate**, dos quais **quatro principais são destinados a hotkeys rápidas**. Tackle segue **separado dos espaços de Move** e custa **2 ATB** (R4-Q4). Os **quatro Moves originais tinham custo-base de 2 ATB** (R6-Q5), com exceções por Move; **R38-Q5 não aprovou novos custos ou alterações para os Moves adicionais**. **Nenhuma ação usa PP** (R8-Q2); Moves mágicos/especiais consomem MP além dos demais recursos aplicáveis (R12-Q1). | Seleção/acesso dos oito Moves, organização das quatro hotkeys, custos de Moves ainda não especificados, potência, precisão, exceções, alvos e disponibilidade por espécie. **Sem PP e sem novos custos ATB/Burst definidos**. |
| **2 — ITENS** | Acessa e permite usar consumíveis em batalha; **cada utilização de item custa 1 bloco ATB** (R6-Q2 = C: “1”). A navegação em ITENS **não pausa o combate**. | Catálogo de itens, alvos, efeitos, inventário e instante preciso de cobrança ainda não definidos. |
| **3 — Tactic** | **Orienta somente a IA dos aliados**, sem ordens diretas (R2-Q4) e **sem custo ATB** (R3-Q3). As orientações persistem entre encontros da dungeon (R5-Q5). **Nas configurações, o jogador escolhe** entre reiniciar as orientações ao encerrar a dungeon ou preservá-las entre dungeons (R6-Q4); a opção **padrão é reiniciar** (R7-Q1). | A orientação de IA padrão, detalhes da interface e salvamento da preferência ainda não definidos. |
| **4 — Evade** | Ação ativa e reativa de esquiva durante ataques; seus **3 blocos de ATB são descontados na ativação**, tanto em sucesso quanto em falha (R4-Q3). | Janela temporal, interface física/botão de reação, elegibilidade por alvo, animações e interações com golpes múltiplos/em área. |

**APROVADO:** todas as ações consomem blocos; a maioria custa **2**, o Evade custa **3**, determinados golpes fortes custam **todos os 5**, e alguns ataques também **exigem Burst**.

**APROVADO (R2-Q3 = B):** um **Move executado mediante Burst** consome **o bloco especial Burst e também os blocos normais de ATB correspondentes ao custo do Move**. Ter o bloco Burst não isenta desse custo; o Move depende de saldo normal suficiente.

**APROVADO (R3-Q3 = A):** **Tactic não consome ATB**. Ajustar a orientação da IA é uma configuração de interface, **não** uma ação de combate cobrada; essa é uma exceção explícita à regra geral de consumo de blocos por ações.

**APROVADO (R4-Q4 = A + R8-Q2 = C):** **Tackle físico genérico custa 2 blocos ATB, sem PP**, permanecendo **separado dos espaços de Move**. **R38-Q5 = C atualizou para até oito Moves utilizáveis no combate, com quatro principais para hotkeys**, sem incluir explicitamente Tackle nesses oito. Potência e precisão ainda não definidas.

**APROVADO (R5-Q4 = B):** **buff/debuff via Burst consome apenas um bloco Burst, sem custo de ATB normal ou extra**. Em contraste, **Moves ofensivos via Burst continuam custando 1 Burst + o custo ATB próprio do Move** (R2-Q3).

**APROVADO (R6-Q2 = C: “1”):** **cada utilização de item em batalha custa 1 bloco ATB**, independentemente do tipo de consumível; não confundir com apenas abrir/navegar pelo menu ITENS. A escolha pelo menu não pausa a batalha (R1-Q3). O momento exato do desconto, efeitos e restrições por item seguem pendentes.

**APROVADO (R6-Q5 = A) — custo-base histórico:** os **quatro Moves originalmente equipados usam custo-base de 2 ATB**, com **exceções específicas por Move**, inclusive ataques fortes com custo de 5 blocos e Moves que requerem Burst. **R38-Q5 = C atualizou a disponibilidade para até oito Moves em combate, com quatro principais para hotkeys, sem decidir novos custos dos Moves adicionais**. Os custos anteriores não foram revogados. Se um Move for executado via Burst, preserva-se **1 Burst + custo ATB do Move** (R2-Q3). Não extrapolar custos nem determinar exceções silenciosamente.

**APROVADO (R7-Q3 = B; esclarecido por R8-Q2 = C):** **Crawlmon não utiliza PP como recurso de combate**: **nenhum dos Moves utilizáveis (até oito conforme R38-Q5) nem o Tackle genérico usa PP**, e tampouco se deve acrescentar um medidor ou custo de PP às ações do sistema. Os custos já documentados de Moves e Tackle permanecem em **ATB** e, quando cabível, **Burst/MP**, sem novos valores definidos nesta rodada. A antiga dúvida sobre PP de Tackle foi **encerrada** por R8-Q2.

**APROVADO (R12-Q1 = A):** **todos os Moves de categoria mágica/especial consomem MP**, além de seus custos de **ATB e Burst, quando aplicáveis**. **R13-Q1 = A aprovou posteriormente custo-base comum de MP, com exceções por Move**. Os números do custo-base e das exceções permanecem pendentes. Esta decisão **não** dispensa os custos já aprovados, **não** cria PP e não determina o consumo de MP por Moves de outras categorias.

**PENDENTE:** custo e propriedades das **exceções individuais de Move**, **valor do custo-base comum de MP e exceções individuais por Move**, detalhes do catálogo de itens, momento de cobrança dos consumíveis e efeitos concretos de buffs/debuffs. **Já aprovados:** Tackle (2 ATB), Moves equipados (2 ATB salvo exceções), ITENS (1 ATB por uso), Evade (3 ATB), Tactic (0), custos de Burst e **MP adicional nos Moves mágicos/especiais**. Não criar PP nem alterar ATB/Burst.

**APROVADO (Guard; ver §12.34):** o bloco do comando **4 — Evade** ganha uma **variante Guard**, trocada com a seta direita (esquerda volta ao Evade), sem criar um quinto comando. O **Guard custa 1 ATB** e **não aceita Burst como pagamento**. Esta é uma exceção explícita à regra "Burst paga a ação" e não altera os custos de Evade (3), Tackle (2), Moves (2) ou ITENS (1).

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

**APROVADO (Guard; ver §12.34):** o **Guard** é uma ação defensiva **distinta do Evade e da evasão automática**. Ele **não evita o golpe**: o golpe com dano **atinge**, o Guard **reduz o dano** e **se quebra**. Por isso o Guard **não concede** recompensa de ATB nem Burst por esquiva (tabela acima) e **não altera** a regra de Evade; golpes de status de alvo único não são bloqueados (D-012).

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

**APROVADO (Guard; ver §12.34):** **Burst não pode ser usado para o Guard**; a ação só aceita blocos ATB (normais/extras). É a única ação cujo pagamento por Burst foi expressamente proibido pelo criador; as demais regras de Burst permanecem.

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
- **Moves:** Tackle genérico versus golpe homônimo da franquia (**Tackle genérico custa 2 ATB, sem PP e permanece separado**); **até oito Moves utilizáveis em combate, dos quais quatro principais destinados a hotkeys rápidas** (R38-Q5), com seleção, catálogo, acesso e organização ainda pendentes. **Custos ATB/Burst anteriores permanecem válidos**, incluindo o custo-base histórico de 2 ATB para os quatro Moves originais e exceções documentadas; não extrapolar valores aos adicionais sem aprovação. **Nenhuma ação do Crawlmon utiliza PP** (R8-Q2). **R23-Q5 = C** aprovou aprendizado com mestres e possíveis personagens que concedam HMs; **R24-Q4 = C** fixou HMs/TMs apenas para combate. Outras fontes e regras de ensino permanecem pendentes.
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


### 7.24. Derrota da equipe, treino de reservas, andares variáveis e salas secretas — Rodada 33

**APROVADO (R33-Q1 = A) — derrota definitiva:** **quando todos os Pokémon ativos forem incapacitados, o combate termina em derrota definitiva e a exploração atual é encerrada**. Aplicam-se as regras já aprovadas de perda de itens coletados não segurados, preservação de itens segurados, Pokémon recrutados, XP e níveis. Isso **não substitui** a continuidade da batalha com aliados IA se apenas o protagonista cair (R31-Q2).

**APROVADO (R33-Q2 = A) — treino da reserva fora das expedições:** **Pokémon reservados podem progredir por treinamentos ou serviços específicos fora das expedições**. **PENDENTE:** onde, com quem, quais condições e quais efeitos. Não atribuir XP das vitórias da equipe ativa aos Pokémon reservados (R31-Q3) e não implementar ou exigir o hub futuro.

**APROVADO (R33-Q3 = B) — dungeon com extensão variável:** **a quantidade de andares de uma mesma dungeon pode variar entre novas expedições**, com critérios de geração pendentes. A geração por exploração/andar, seed reproduzível, layout persistente durante a mesma expedição e necessidade de derrotar o chefe no último andar permanecem. **PENDENTE:** quantidade, distribuição e regras concretas; não definir números.

**APROVADO (R33-Q4 = B) — pistas para salas secretas:** **pistas, mapas especiais, NPCs e eventos serão meios principais para indicar, revelar ou liberar salas secretas**. A descoberta permanece opcional e não é condição para chegar ao chefe (R26-Q5). **PENDENTE:** conteúdo das pistas, acesso e eventos concretos.

**REJEITADA SEM APROVAÇÃO (R33-Q5 = C, texto livre de objeção):** “que recursos obtidos? já começou as perguntas idiotas redundates dnv??”. **Não foi aprovada qualquer função para recursos materiais, crafting, preparação ou melhorias.** O termo “recursos” em R27-Q5 segue apenas como categoria geral de recompensa, sem definição de itens concretos. A pergunta foi rejeitada por insuficiência de contexto e redundância; **não registrar decisão D-185** nem reutilizar a questão como se houvesse escolha de alternativa.

**Estado da rodada:** **4 decisões aprovadas (D-181 a D-184), 1 pergunta rejeitada sem aprovação**. A Rodada 33 é encerrada por instrução do criador sem inventar quinta decisão. Mantêm-se todas as decisões D-001 a D-180, as regras de combate, ATB/Burst, ausência de PP, evolução e progressão já aprovadas.


### 7.25. Narrativa por dungeon, exploração, progressão, chefes e inventário — Rodada 34

**APROVADO (R34-Q1 = B) — estrutura narrativa:** **dungeons têm histórias e missões relativamente independentes entre si, em uma campanha de progressão geral mais aberta**. A campanha continua a **desbloquear dungeons conforme conquistas e objetivos** (R25-Q1); não interpretar “mais aberta” como todas as dungeons liberadas desde o começo. **PENDENTE:** histórias, NPCs, missões concretas, ligações entre arcos e desbloqueios.

**APROVADO (R34-Q2 = B) — prioridade na exploração:** **encontros, salas e eventos narrativos têm prioridade na experiência das dungeons**, **sem exigir enigmas ou armadilhas como sistemas centrais**. Desafios ambientais pontuais não ficam proibidos; sua inclusão, objetivos e efeitos seguem pendentes. Preservar salas secretas e NPCs aprovados anteriormente.

**APROVADO (R34-Q3 = B) — andares sequenciais:** **a progressão principal vai sequencialmente de um andar ao seguinte**, embora cada andar possua salas, corredores e caminhos variados. Escadas/saídas permitem avançar sem eliminar todos os inimigos (R24-Q1). O número de andares pode variar entre expedições da mesma dungeon (R33-Q3); a sequência principal permanece ordenada, sem definir ramificações entre andares.

**APROVADO (R34-Q4 = B) — chefe variável:** **o chefe final de uma mesma dungeon pode variar entre expedições**, com catálogo e condições ainda pendentes. O chefe permanece no último andar e segue principalmente o sistema comum de combate (R30-Q3), podendo contar com inimigos de apoio até o limite de três inimigos ativos (R29-Q4). Não exigir chefe diferente em toda nova expedição nem inventar regras de sorteio.

**APROVADO (R34-Q5 = C) — inventário de 10 itens (histórico):** resposta literal **“10 itens não contando segurados”**. A decisão fixou 10 itens transportados e excluiu os itens segurados da contagem. **Atualização expressa aprovada em R35-Q3 = C:** **10 itens não segurados por cada Pokémon ativo (até 30 itens com os três integrantes ativos)**; não é inventário global de apenas 10 nem uma capacidade de 30 para um único Pokémon. **Inventário cheio:** R35-Q3 também aprova a alternativa A, permitindo escolher item anterior para deixar/trocar antes da coleta. **PENDENTE:** distribuição entre membros, mudanças de composição, empilhamento, capacidade de itens segurados, destinos dos itens deixados e UI. Preservar perda/preservação já aprovada e funcionamento passivo/automático dos itens segurados.

**Preservação:** decisões D-001 a D-184 integralmente válidas. A rejeição de R33-Q5 permanece registrada. R34-Q5 é resposta personalizada C, não autorização para acrescentar sistemas de materiais, fórmulas, PP ou novos custos ATB/Burst. Apenas requisitos de documentação foram atualizados.


### 7.26. Aliados em 2D, recrutamento comum, inventário individual, fuga e histórias — Rodada 35

**APROVADO (R35-Q1 = A) — aliados acompanham visualmente:** **Pokémon aliados da equipe ativa aparecem no mapa de exploração 2D e acompanham o protagonista**. O **protagonista permanece o único controlado diretamente**; aliados usam IA. **PENDENTE:** formação, movimentação, colisões e interações durante a exploração; não definir reservados como acompanhantes.

**APROVADO (R35-Q2 = A) — recrutamento comum:** **Pokémon comuns elegíveis podem oferecer recrutamento por interação voluntária direta no 2D**, com requisitos específicos pendentes. Recrutamento especial ainda exige tarefa/evento (R32-Q5). **Inimigos hostis comuns** continuam iniciando batalha por contato (R8-Q5), sem recrutamento automático por proximidade.

**APROVADO (R35-Q3 = C) — inventário por Pokémon e coleta com espaço esgotado:** resposta literal **“cada aliado tem 10 itens de limte, entao no geral tem 30 items mas cada aliado tem até 10, alias opção A”**. **Cada integrante da equipe ativa — protagonista incluído para corresponder ao total de três — carrega até dez itens não segurados**; **com três integrantes, a capacidade agregada é até 30, distribuída em dez por Pokémon**, não trinta em um único inventário individual. **Itens segurados não entram na contagem**, conforme R34-Q5. A expressão **“alias opção A”** também aprova **permitir escolher um item carregado para deixar/trocar antes de recolher outro quando estiver cheio**. **PENDENTE:** coleta por Pokémon, redistribuição, capacidade ao mudar a equipe, pilhas, itens segurados, destino do item deixado e interface. Esta decisão **atualiza e especifica** o antigo limite geral de 10 da R34-Q5; o registro D-189 original permanece no histórico sem ser adulterado.

**APROVADO (R35-Q4 = A) — fuga de chefes:** **combates contra chefes não permitem fuga**, salvo eventuais exceções futuras explicitamente aprovadas. Em combates comuns, a fuga segue permitida conforme R27-Q1 e o retorno/stun de três segundos após êxito conforme R28-Q3. Não determinar novas chances, comandos ou custos.

**APROVADO (R35-Q5 = B) — narrativa procedural:** **as histórias e missões podem variar entre expedições de uma mesma dungeon em decorrência de eventos/situações procedurais**, com catálogo, relevância e critérios de geração pendentes. Mantêm-se a identidade narrativa relativamente independente de cada dungeon (R34-Q1) e o desbloqueio de dungeons na campanha (R25-Q1). Não presumir que todas as narrativas ou seus NPCs sejam gerados aleatoriamente.

**Preservação:** decisões D-001 a D-189 intactas, inclusive rejeição de R33-Q5; R35-Q3 complementa o requisito de inventário sem alterar decisões históricas. Não implementar nem inventar recursos materiais, PP, fórmulas, custos ATB/Burst, capacidade de pilhas ou limite de itens segurados.


### 7.27. Acompanhamento, missões secundárias, revisitas, retirada e espécies — Rodada 36

**APROVADO (R36-Q1 = A) — acompanhamento em grupo:** **os aliados ativos caminham acompanhando o protagonista e permanecem próximos a ele na exploração 2D**. **PENDENTE:** formação, movimentação, colisões e comportamento frente a obstáculos. R35-Q1 continua válido: controle direto do protagonista, aliados pela IA. Não acrescentar exploração autônoma distante como regra.

**APROVADO (R36-Q2 = A) — acesso ao chefe independente de missões secundárias:** **eventos e missões secundárias são opcionais para chegar ao chefe**; ao alcançar o último andar, o jogador não precisa concluir esses conteúdos para enfrentar o chefe. A vitória contra o chefe permanece obrigatória para concluir a dungeon (R23-Q2), e a progressão da campanha ainda exige conquistas/objetivos para desbloquear outras dungeons (R25-Q1). Não converter salas secretas em exigência.

**APROVADO (R36-Q3 = A) — estado persistente no mesmo andar/expedição:** **itens coletados e eventos concluídos não reaparecem nem reiniciam automaticamente quando o jogador revisita um andar durante a mesma expedição**. O layout também permanece estável (R9-Q2) e Pokémon inimigos derrotados continuam removidos naquela expedição (R9-Q4). **PENDENTE:** novas expedições, situações especiais, eventos inacabados e possíveis novos eventos genuinamente gerados; não inferir resets automáticos.

**APROVADO (R36-Q4 = A) — posse de recrutas após retirada voluntária:** **todos os Pokémon recrutados na expedição permanecem pertencendo ao jogador também se ele optar por abandoná-la antes de enfrentar o chefe**, como já acontecia após derrota definitiva (R24-Q5). **Não mudar** as consequências independentes: perda de itens coletados não segurados (R31-Q1) e preservação de XP/níveis (R32-Q3). **PENDENTE:** destino da equipe/reserva ao retornar e outras consequências não definidas.

**APROVADO (R36-Q5 = A) — identidade das espécies por dungeon:** **cada dungeon conta com espécies de Pokémon características, variando internamente entre seus biomas**. **PENDENTE:** catálogos, distribuições, critérios de aparição e possíveis espécies compartilhadas entre dungeons. Biomas podem afetar inimigos, eventos e recompensas (R28-Q4); não impor exclusividade absoluta ou números.

**Preservação:** decisões D-001 a D-194 mantidas, incluindo D-192 (dez itens por membro ativo, até trinta com três) e a rejeição histórica de R33-Q5. Nenhuma regra numérica, PP, recurso material não definido, custo ATB/Burst, UI ou código foi introduzido.


### 7.28. Contatos com aliados, missões, campanha, iniciais e revisitas — Rodada 37

**APROVADO (R37-Q1 = A) — contato hostil com qualquer ativo:** **o encontro 3D pode começar quando um inimigo hostil toca qualquer Pokémon da equipe ativa que acompanha o protagonista no mapa 2D**, inclusive um aliado controlado pela IA. **PENDENTE:** regras de detecção, colisões simultâneas e transição de combate. Contatos com Pokémon de recrutamento elegível continuam sujeitos à interação voluntária (R24-Q2/R35-Q2), e o protagonista segue como único controlado diretamente.

**APROVADO (R37-Q2 = A) — progresso de missões secundárias por expedição:** **as missões secundárias têm progresso principalmente limitado à expedição atual e normalmente reiniciam ao começar uma nova tentativa**. **PENDENTE:** exceções e conteúdo. Isso não reinicia eventos concluídos ou itens coletados quando o jogador somente revisita um andar **na mesma expedição** (R36-Q3), nem revoga a preservação de XP/níveis (R32-Q3) ou as missões principais da campanha.

**APROVADO (R37-Q3 = A) — desbloqueio de novas dungeons:** **a campanha avança e desbloqueia dungeons principalmente por concluir expedições e vencer chefes**, enquanto objetivos narrativos são **complementares**, com requisitos e sequência específicos pendentes. Permanecem NPCs como meio principal de apresentar objetivos (R31-Q4), dungeons com histórias relativamente independentes (R34-Q1) e missões secundárias opcionais para chegar ao chefe (R36-Q2).

**APROVADO (R37-Q4 = A) — espécie inicial selecionada:** **a escolha inicial do protagonista é feita entre um conjunto selecionado de espécies iniciais disponíveis**. **PENDENTE:** espécies concretas, número, apresentação e elegibilidade. Preservar as regras de Nature do protagonista; não inferir quais Pokémon compõem o conjunto.

**APROVADO (R37-Q5 = B) — dificuldade adaptativa nas revisitas:** **revisitar uma dungeon já concluída pode trazer dificuldade ajustada à progressão ou força atual da equipe**, com parâmetros e limites ainda pendentes. Esta possibilidade complementa o aumento de dificuldade entre andares e novas dungeons (R29-Q5) e a repetição de dungeons (R29-Q3); não exigir ajuste em toda visita nem inventar fórmulas, níveis ou multiplicadores.

**Preservação:** D-001 a D-199 integralmente preservadas, inclusive D-192 com 10 itens não segurados por integrante ativo (até 30 com três) e rejeição de R33-Q5. Não definir recursos materiais genéricos, PP ou novos custos ATB/Burst. Documentação não comprova implementação.


### 7.29. Detecção por proximidade, arenas por bioma, reserva e oito Moves — Rodada 38

**APROVADO (R38-Q1 = B) — percepção de inimigos:** **inimigos patrulhando o mapa 2D detectam o grupo principalmente por proximidade, sem exigir linha de visão estrita**. Mantêm-se patrulha, perseguição após detectar (R9-Q3) e encontros iniciados por contato com qualquer integrante ativo (R37-Q1). **PENDENTE:** distância, obstáculos, condições e perda do alvo. A ausência de exigência de linha de visão estrita não elimina todas as influências do cenário.

**APROVADO (R38-Q2 = A) — arena 3D correspondente ao ambiente:** **o cenário da batalha 3D reflete o bioma e o ambiente do ponto de encontro na exploração 2D**, embora a batalha continue em uma **cena separada** (D-003). **PENDENTE:** catálogo, efeitos visuais e possíveis características físicas das arenas; não acrescentar bônus ou modificadores de combate não aprovados.

**APROVADO (R38-Q3 = B) — capacidade limitada da reserva:** **a reserva de Pokémon possui limite de capacidade**, sem tamanho nem gerenciamento dos excedentes ainda aprovados. Permanecem o máximo de três Pokémon ativos (R6-Q3) e a possibilidade de enviar à reserva recrutados quando a equipe ativa estiver completa (R24-Q3). **PENDENTE:** valor do limite, acesso, gestão da reserva cheia e regras de troca; não introduzir número.

**APROVADO (R38-Q4 = A) — itens acompanham o Pokémon na reserva:** **os itens transportados continuam associados ao Pokémon quando ele sai da equipe ativa para a reserva**. **PENDENTE:** acesso a esses itens, uso fora da equipe ativa, movimentação/transferência e regras da reserva. Não alterar a regra de 10 itens não segurados por Pokémon ativo, até 30 com três (R35-Q3), nem os itens segurados. **A preservação da associação durante a troca não protege automaticamente de perdas após derrota/retirada** (R25-Q4/R31-Q1).

**APROVADO (R38-Q5 = C) — Moves utilizáveis em combate:** resposta literal **“Pode ter até 8 moves no combate, os 4 principais servem mais para hotkeys rapidas”**. **Um Pokémon pode dispor de até oito Moves em combate, quatro deles como principais para hotkeys rápidas**, atualizando a antiga regra em que os quatro Moves representavam a totalidade dos espaços disponíveis. O **Tackle físico genérico permanece separado** como já aprovado (R4-Q4/R8-Q2). **PENDENTE:** gerenciamento de Moves conhecidos, seleção até oito, mudança dos quatro principais e acesso aos demais; não inferir hotkeys específicas, capacidade além dos oito ou custos novos dos Moves adicionais. Os quatro Moves históricos conservam seus custos aprovados, Moves especiais continuam sujeitos a MP (R12-Q1), e **nenhum Move usa PP**.

**Conflito resolvido por decisão posterior:** o texto antigo dos registros **D-006, D-050 e D-053** documentava quatro Moves como opções de combate. Esses registros permanecem **intactos como histórico**, mas **D-209 (R38-Q5)** substitui o teto de quatro por até oito Moves utilizáveis, com quatro principais para atalhos. Não concluir como consequência que os quatro adicionais tenham exatamente os mesmos custos ou o mesmo modo de ativação.

**Preservação:** D-001 a D-204, rejeição R33-Q5, inventário R35-Q3, custos ATB/Burst/MP aprovados e ausência de PP seguem válidos. Nenhum código ou outro arquivo é alterado por esta revisão documental.

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
| D-181 | R33-Q1 = A: **todos os Pokémon ativos incapacitados causam derrota definitiva e encerramento da expedição**, aplicando perdas/preservações já aprovadas; protagonista isolado não encerra batalha. |
| D-182 | R33-Q2 = A: **reservados podem progredir por treinamento ou serviços específicos fora das expedições**, sem receber XP das vitórias dos ativos; condições pendentes. |
| D-183 | R33-Q3 = B: **quantidade de andares de uma mesma dungeon pode variar entre expedições**, geração e seed reproduzíveis preservadas; critérios pendentes. |
| D-184 | R33-Q4 = B: **salas secretas descobertas principalmente por pistas, mapas especiais, NPCs ou eventos**, acesso e regras pendentes. |
| D-185 | R34-Q1 = B: **campanha com histórias e missões relativamente independentes por dungeon, em progressão geral mais aberta**, preservando desbloqueios por conquistas/objetivos. |
| D-186 | R34-Q2 = B: **exploração prioriza encontros, salas e eventos narrativos, sem enigmas/armadilhas como sistema central**, não os proibindo. |
| D-187 | R34-Q3 = B: **progressão principal sequencial entre andares**, com salas e caminhos variados dentro de cada andar; escadas/saídas e extensão variável mantidas. |
| D-188 | R34-Q4 = B: **chefe final pode variar entre expedições da mesma dungeon**, catálogo/condições pendentes, limites de combate preservados. |
| D-189 | R34-Q5 = C — “10 itens não contando segurados”: **limite de 10 itens no inventário da exploração, excluindo os itens segurados pelos Pokémon**, regras de empilhamento e inventário cheio pendentes. |
| D-190 | R35-Q1 = A: **aliados ativos acompanham visualmente o protagonista no mapa 2D**, com controle direto exclusivo do protagonista e aliados por IA. |
| D-191 | R35-Q2 = A: **Pokémon comuns elegíveis oferecem recrutamento por interação voluntária direta**, requisitos pendentes; especiais continuam por tarefa/evento. |
| D-192 | R35-Q3 = C — “cada aliado tem 10 itens de limte, entao no geral tem 30 items mas cada aliado tem até 10, alias opção A”: **10 itens não segurados por Pokémon ativo, até 30 com três ativos**, atualizando o total da R34-Q5; **com inventário cheio, escolher item para deixar/trocar antes de recolher outro** (alternativa A). |
| D-193 | R35-Q4 = A: **não permitir fuga em combates contra chefes**, sem alterar fuga de combates comuns; possíveis exceções futuras não definidas. |
| D-194 | R35-Q5 = B: **histórias e missões de uma dungeon podem variar entre expedições mediante eventos e situações procedurais**, regras e conteúdo pendentes. |
| D-195 | R36-Q1 = A: **aliados ativos acompanham protagonista em grupo, próximos durante exploração 2D**, formação/movimentação pendentes; controle direto continua do protagonista. |
| D-196 | R36-Q2 = A: **missões e eventos secundários não bloqueiam acesso ao chefe no último andar**, mantendo vitória contra o chefe necessária para concluir. |
| D-197 | R36-Q3 = A: **itens coletados e eventos concluídos mantêm estado ao revisitar o andar na mesma expedição, sem reaparecer/reiniciar automaticamente**, preservando regras de layout/inimigos. |
| D-198 | R36-Q4 = A: **Pokémon recrutados permanecem com o jogador após retirada voluntária**, como na derrota definitiva; perdas de itens e XP/níveis preservados conforme decisões anteriores. |
| D-199 | R36-Q5 = A: **cada dungeon possui espécies características com variações internas por bioma**, catálogos/distribuições pendentes. |
| D-200 | R37-Q1 = A: **contato hostil com qualquer Pokémon ativo presente no mapa 2D pode iniciar batalha 3D**, incluindo aliados acompanhantes. |
| D-201 | R37-Q2 = A: **progresso de missões secundárias principalmente limitado à expedição atual, normalmente reiniciando em nova tentativa**, exceções pendentes. |
| D-202 | R37-Q3 = A: **desbloqueio de dungeons principalmente por conclusão de outras dungeons e vitória contra seus chefes**, objetivos narrativos complementares. |
| D-203 | R37-Q4 = A: **protagonista escolhido entre conjunto selecionado de espécies iniciais**, catálogo e apresentação pendentes. |
| D-204 | R37-Q5 = B: **dificuldade de dungeons revisitadas pode adaptar-se à progressão ou força atual da equipe**, critérios/limites pendentes. |
| D-205 | R38-Q1 = B: **detecção de inimigos principalmente por proximidade, sem linha de visão estrita**, alcance e condições pendentes. |
| D-206 | R38-Q2 = A: **arena 3D reflete bioma e ambiente do encontro no mapa 2D**, mantendo batalha em cena separada; catálogo/efeitos pendentes. |
| D-207 | R38-Q3 = B: **reserva de Pokémon com capacidade limitada**, número e gerenciamento de excedentes pendentes. |
| D-208 | R38-Q4 = A: **itens transportados permanecem associados ao Pokémon que passa da equipe ativa à reserva**, acesso/condições pendentes; perdas após derrota/retirada inalteradas. |
| D-209 | R38-Q5 = C — “Pode ter até 8 moves no combate, os 4 principais servem mais para hotkeys rapidas”: **até oito Moves utilizáveis em combate, quatro principais para hotkeys rápidas**, atualizando o antigo limite de quatro; Tackle genérico separado conforme decisões anteriores, gerenciamento e custos dos Moves extras pendentes. |

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

## 10.32. Rodada 33 — sobrevivência, reservas e exploração procedural (ENCERRADA: quatro aprovadas, uma rejeitada)

**Status:** ENCERRADA em 2026-11-01 — **4/5 decisões aprovadas (D-181 a D-184)**; **R33-Q5 rejeitada como pergunta redundante/imprecisa, sem decisão aprovada**. O pedido do criador de encerrar a rodada não deve ser interpretado como aprovação de sua alternativa C.

| ID | Resposta literal do criador | Regra aprovada / status |
| --- | --- | --- |
| **R33-Q1** | **A** — “Quando todos os Pokémon ativos forem incapacitados, ocorre derrota definitiva e a expedição é encerrada, com as regras de perdas e preservações já aprovadas.” | **Derrota definitiva quando todos os ativos caem**, aplicando consequências anteriores. |
| **R33-Q2** | **A** — “Pokémon da reserva podem progredir por treinamentos ou serviços fora das expedições, com acesso e requisitos pendentes.” | **Treinos e serviços fora das expedições para reservados**, critérios pendentes. |
| **R33-Q3** | **B** — “A quantidade de andares de uma mesma dungeon pode variar entre expedições de acordo com regras de geração ainda pendentes.” | **Andares variáveis por expedição de uma dungeon**, preservando seed e layout da exploração. |
| **R33-Q4** | **B** — “Salas secretas são descobertas principalmente por pistas, mapas especiais, NPCs ou eventos que revelam ou liberam seu acesso.” | **Descoberta por pistas, mapas, NPCs e eventos**, detalhes pendentes. |
| **R33-Q5** | **C** — “que recursos obtidos? já começou as perguntas idiotas redundates dnv??” | **REJEITADA: nenhuma decisão aprovada.** Não inferir crafting ou uso de recursos; conteúdo “recursos” não foi detalhado além da categoria de R27-Q5. |

**Preservação:** D-001 a D-180 intactas. Não criar D-185 fictícia; não fixar fórmulas, quantidades, PP ou novos custos ATB/Burst. Evitar novas perguntas sobre “recursos” genéricos enquanto os objetos concretos não estiverem definidos.

## 10.33. Rodada 34 — narrativa, estrutura dos andares e desafios das dungeons (FECHADA)

**Status:** FECHADA — 5/5 respostas aprovadas em 2026-11-01, decisões D-185 a D-189. A rejeição de R33-Q5 permanece no histórico e não foi transformada em decisão.

| ID | Resposta literal do criador | Regra aprovada e pendências |
| --- | --- | --- |
| **R34-Q1** | **B** — “A campanha é organizada em histórias e missões relativamente independentes por dungeon, com progressão geral mais aberta.” | **Histórias/missões por dungeon, com campanha mais aberta**, mantendo os desbloqueios por conquistas/objetivos. |
| **R34-Q2** | **B** — “A exploração prioriza encontros, salas e eventos narrativos, sem tornar enigmas ou armadilhas um sistema central.” | **Priorizar encontros/salas/eventos**, sem tornar enigmas e armadilhas centrais nem proibi-los. |
| **R34-Q3** | **B** — “Manter progressão principal sequencial entre andares, embora cada andar tenha salas e caminhos variados.” | **Sequência entre andares, variedade de caminhos dentro de cada andar**, com extensão variável por expedição. |
| **R34-Q4** | **B** — “O chefe final pode variar entre expedições da mesma dungeon, com catálogo e condições pendentes.” | **Chefes podem variar entre expedições**, sem exigir variação em toda repetição. |
| **R34-Q5** | **C** — “10 itens não contando segurados” | **Inventário limitado a dez itens, sem contar itens segurados**; empilhamento, interface e demais regras pendentes. |

**Preservação:** D-001 a D-184 permanecem intactas, inclusive a rejeição expressa de R33-Q5. Nenhuma regra de PP, ATB/Burst, crafting, quantidades de itens segurados ou recursos materiais foi acrescentada.

## 10.34. Rodada 35 — companheiros, recrutamento, inventário e narrativa procedural (FECHADA)

**Status:** FECHADA — 5/5 decisões aprovadas em 2026-11-02, D-190 a D-194, com atualização expressa do limite de inventário anterior. A rejeição de R33-Q5 permanece intacta.

| ID | Resposta literal do criador | Regra aprovada / pendências |
| --- | --- | --- |
| **R35-Q1** | **A** — “Os aliados ativos acompanham visualmente o protagonista no mapa 2D, sem mudar o controle direto do protagonista.” | **Aliados ativos acompanham visualmente no 2D**, controle do protagonista mantido. |
| **R35-Q2** | **A** — “Pokémon elegíveis comuns oferecem oportunidades de recrutamento por interação voluntária direta, sujeitas a requisitos pendentes.” | **Recrutamento comum por interação voluntária direta**, distinto das tarefas dos especiais. |
| **R35-Q3** | **C** — “cada aliado tem 10 itens de limte, entao no geral tem 30 items mas cada aliado tem até 10, alias opção A” | **Cada Pokémon ativo pode transportar até 10 itens não segurados, total até 30 com três ativos**; item segurado não conta (R34-Q5). **Alternativa A também aprovada:** escolher item anterior para deixar/trocar antes de recolher quando cheio. |
| **R35-Q4** | **A** — “Não permitir fuga dos combates contra chefes, com exceções futuras pendentes.” | **Sem fuga de chefes**, fuga comum preservada. |
| **R35-Q5** | **B** — “Histórias e missões também podem variar entre expedições da mesma dungeon por meio de eventos e situações procedurais.” | **Histórias/missões podem variar por expedição**, sem definir geração ou conteúdo. |

**Rastreabilidade do inventário:** D-189, aprovado na R34, permanece transcrito exatamente como decisão histórica de 10 itens não segurados. **D-192 supera a interpretação anterior de limite global de 10** ao dividir a capacidade em até 10 por integrante ativo (até 30 com equipe completa). Não inferir 30 em um único Pokémon, transferência irrestrita ou limite/capacidade de itens segurados.

**Preservação:** D-001 a D-189 intactas, inclusive rejeição expressa de R33-Q5. Não criar PP, fórmula, crafting ou custos ATB/Burst novos.

## 10.35. Rodada 36 — exploração, missões e consequências da expedição (FECHADA)

**Status:** FECHADA — 5/5 respostas aprovadas em 2026-11-02, decisões D-195 a D-199.

| ID | Resposta literal do criador | Regra aprovada e pendências |
| --- | --- | --- |
| **R36-Q1** | **A** — “Os aliados acompanham o protagonista como um grupo, permanecendo próximos durante a exploração; formação e movimentação pendentes.” | **Aliados próximos em grupo na exploração 2D**, controle do protagonista e IA preservados. |
| **R36-Q2** | **A** — “Missões e eventos secundários não impedem o acesso ao chefe ao chegar ao último andar.” | **Missões/eventos secundários opcionais para enfrentar o chefe**, derrota do chefe ainda necessária para concluir. |
| **R36-Q3** | **A** — “Itens coletados e eventos concluídos permanecem registrados ao revisitar um andar, sem serem reiniciados automaticamente.” | **Estado persistente de coletas/eventos resolvidos na mesma expedição**, sem reinício automático ao revisitar. |
| **R36-Q4** | **A** — “Pokémon recrutados durante a expedição permanecem com o jogador mesmo após retirada voluntária, como já ocorre na derrota definitiva.” | **Preservar Pokémon recrutados após retirada voluntária**, sem alterar perda de itens e preservação de XP/níveis. |
| **R36-Q5** | **A** — “Cada dungeon possui espécies de Pokémon características, com variações internas por bioma.” | **Catálogos característicos por dungeon, com variação por bioma**, detalhes pendentes. |

**Preservação:** todas as 194 decisões anteriores mantidas; D-192 continua definindo até 10 itens por integrante ativo, somando até 30 com três Pokémon. A rejeição de R33-Q5 permanece registrada. Não criar PP, fórmulas, recursos materiais indefinidos ou custos ATB/Burst.

## 10.36. Rodada 37 — combate no mapa, progressão e missões (FECHADA)

**Status:** FECHADA — 5/5 decisões aprovadas em 2026-11-02, D-200 a D-204.

| ID | Resposta literal do criador | Regra aprovada e pendências |
| --- | --- | --- |
| **R37-Q1** | **A** — “O contato de um inimigo hostil com qualquer Pokémon da equipe ativa pode iniciar combate 3D.” | **Contato hostil com qualquer membro ativo no 2D inicia encontro 3D**, critérios físicos pendentes. |
| **R37-Q2** | **A** — “O progresso das missões secundárias fica principalmente restrito à expedição atual e normalmente reinicia em nova tentativa.” | **Missões secundárias principalmente locais à expedição**, com exceções pendentes. |
| **R37-Q3** | **A** — “O desbloqueio de dungeons depende principalmente de concluir dungeons e vencer seus chefes, com objetivos narrativos complementares.” | **Concluir dungeons/chefes como via principal de desbloqueio**, narrativa complementar. |
| **R37-Q4** | **A** — “O protagonista é escolhido entre um conjunto selecionado de espécies iniciais, com catálogo pendente.” | **Conjunto selecionado de iniciais**, sem catálogo definido. |
| **R37-Q5** | **B** — “Nas revisitas, a dificuldade também pode se adaptar à progressão ou à força atual da equipe, com regras pendentes.” | **Dificuldade adaptativa possível nas revisitas**, sem fórmulas ou regras concretas. |

**Preservação:** D-001 a D-199 intactas. Inventário por Pokémon ativo (R35-Q3), rejeição expressa de R33-Q5, ausência de PP e custos ATB/Burst anteriores preservados. Nenhuma implementação de código autorizada.

## 10.37. Rodada 38 — encontros, arenas, reservas e aprendizado de Moves (FECHADA)

**Status:** FECHADA — 5/5 respostas aprovadas em 2026-11-02, decisões D-205 a D-209.

| ID | Resposta literal do criador | Regra aprovada e pendências |
| --- | --- | --- |
| **R38-Q1** | **B** — “Os inimigos detectam o grupo principalmente pela proximidade, sem exigir linha de visão estrita; alcance pendente.” | **Detecção principalmente por proximidade**, alcance e condições pendentes. |
| **R38-Q2** | **A** — “A arena 3D reflete o bioma e ambiente em que o encontro ocorreu no mapa 2D, com catálogo e detalhes pendentes.” | **Arenas 3D visualmente relacionadas ao bioma e lugar do encontro**, efeitos de gameplay não definidos. |
| **R38-Q3** | **B** — “A reserva de Pokémon possui limite de capacidade, com tamanho e gestão de excedentes pendentes.” | **Reserva com capacidade limitada**, valor e gestão pendentes. |
| **R38-Q4** | **A** — “Os itens transportados permanecem associados ao Pokémon quando ele vai para a reserva, com acesso e regras pendentes.” | **Itens continuam associados ao Pokémon na reserva**, sem proteção extra contra perdas de expedição. |
| **R38-Q5** | **C** — “Pode ter até 8 moves no combate, os 4 principais servem mais para hotkeys rapidas” | **Até oito Moves utilizáveis no combate, quatro principais para hotkeys rápidas**; antigo teto de quatro superado, sem PP nem novos custos aprovados. |

**Rastreabilidade da mudança de Moves:** preservar os registros históricos D-006, D-050, D-053 e decisões anteriores tal como originalmente aprovados. **R38-Q5 altera o número máximo de Moves utilizáveis, não os custos anteriores**. Tackle continua separado por decisão anterior; associação dos Moves extras a custos e acesso permanece pendente.

**Preservação:** D-001 a D-204 e histórico mantidos, incluindo R35-Q3 (10 itens por Pokémon ativo, até 30 com três) e a rejeição R33-Q5. Não criar fórmulas, recursos materiais não especificados, PP ou custos ATB/Burst novos.

## 10.38. Rodada 39 — configuração de Moves, arenas e consequências da progressão (cinco perguntas abertas)

**Status:** ABERTA — 0/5 respostas, nenhuma alternativa aprovada. Questões relevantes ainda pendentes, sem atribuir custos, números adicionais ou funcionalidades inventadas.

**R39-Q1 — Como um Pokémon escolhe quais Moves estarão entre os oito utilizáveis em combate?**  
A. **Selecionar previamente um conjunto de até oito Moves conhecidos para levar ao combate**, com configuração dos quatro principais para hotkeys rápidas; acesso e momento de configuração pendentes.  
B. **Ter acesso em combate a todos os Moves conhecidos, respeitando um máximo de oito utilizáveis por vez**, com critérios de disponibilidade e troca pendentes.  
C. Outra regra, descrita pelo criador.  
*R38-Q5 aprovou até oito Moves utilizáveis e quatro principais para hotkeys, mas não definiu gerenciamento dos Moves conhecidos.*

**R39-Q2 — Os ambientes das arenas 3D terão efeitos reais sobre o combate?**  
A. **O bioma influencia principalmente a aparência da arena**, sem exigir obstáculos ou efeitos de terreno com impacto mecânico.  
B. **O bioma pode influenciar também a movimentação e o combate por obstáculos ou características do cenário**, com regras concretas pendentes.  
C. Outra relação entre cenário e combate, descrita pelo criador.  
*R38-Q2 vinculou a arena 3D visualmente ao local do encontro; não decidiu se o terreno altera gameplay.*

**R39-Q3 — O que acontece ao tentar recrutar um Pokémon com a equipe ativa e a reserva já lotadas?**  
A. **Permitir reorganizar a coleção para abrir espaço, substituindo ou liberando um Pokémon existente**, com regras e salvaguardas pendentes.  
B. **Impedir a efetivação de novos recrutamentos até existir uma vaga**, mantendo outras interações possíveis.  
C. Outro comportamento, descrito pelo criador.  
*R38-Q3 aprovou reserva com capacidade limitada; excedentes, quando todos os lugares estão ocupados, permanecem sem solução.*

**R39-Q4 — Como serão recuperados HP e estados negativos da equipe entre expedições?**  
A. **Ao iniciar uma nova expedição, a equipe ativa começa com HP recuperado e estados negativos de combate removidos**, com detalhes pendentes.  
B. **HP e estados negativos podem persistir entre expedições**, exigindo recuperação por descanso, itens ou serviços, com condições pendentes.  
C. Outra política de recuperação, descrita pelo criador.  
*O GDD restaura MP ao iniciar nova expedição e define pontos seguros de descanso com HP, mas não estabelece integralmente a condição inicial de HP/status entre expedições.*

**R39-Q5 — Quais efeitos a evolução de espécie poderá ter sobre os Moves já aprendidos?**  
A. **Preservar todos os Moves conhecidos ao evoluir**, com possibilidade de aprender novos Moves conforme a espécie evoluída, regras pendentes.  
B. **A evolução pode modificar a lista de Moves disponíveis**, exigindo que alguns sejam substituídos ou deixem de ficar disponíveis, com regras pendentes.  
C. Outro comportamento, descrito pelo criador.  
*R25-Q3 permite decidir quando evoluir e R27-Q4 associa Moves à progressão; o destino dos Moves conhecidos ao evoluir não foi decidido.*

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

| 1.24 | 2026-11-01 | Rodada 33 encerrada: 4 decisões aprovadas (D-181 a D-184) e R33-Q5 rejeitada sem aprovação por pergunta imprecisa/redundante. Todos os ativos incapacitados causam derrota definitiva; treino/serviços para reservas fora das expedições; quantidade de andares pode variar por expedição; salas secretas descobertas por pistas, mapas, NPCs e eventos. Não definir função para “recursos” genéricos. Abre Rodada 34 sobre narrativa, desafios ambientais, rotas, chefes e inventário. | Rodada 33 encerrada (4 aprovadas / 1 rejeitada) / Rodada 34 aberta |

| 1.25 | 2026-11-01 | Rodada 34 (D-185 a D-189): narrativas/missões relativamente independentes por dungeon com progressão de campanha mais aberta, mas desbloqueios mantidos; priorizar encontros/salas/eventos sem enigmas/armadilhas centrais; sequência principal entre andares com caminhos internos variados; chefe final variável entre expedições; inventário de 10 itens sem contabilizar segurados (R34-Q5 C). Rejeição de R33-Q5 mantida. Abre Rodada 35 sobre representação dos aliados, recrutamento comum, inventário cheio, fuga de chefes e histórias procedurais. | Rodada 34 fechada / Rodada 35 aberta |

| 1.26 | 2026-11-02 | Rodada 35 (D-190 a D-194): aliados ativos visíveis acompanhando protagonista no 2D; recrutamento comum por interação voluntária direta; inventário 10 itens não segurados por Pokémon ativo, até 30 com três ativos, e alternativa A de deixar/trocar item quando cheio (R35-Q3 C), atualizando regra global da R34 sem reescrever D-189; proibição de fuga contra chefes; missões e histórias também variáveis entre expedições. Rejeição de R33-Q5 mantida. Abre Rodada 36 sobre comportamento de aliados, requisitos de missões, estados em revisitas, recrutamento em retirada e espécies por dungeon. | Rodada 35 fechada / Rodada 36 aberta |

| 1.27 | 2026-11-02 | Rodada 36 (D-195 a D-199): aliados acompanham protagonista em grupo próximo no 2D; missões/eventos secundários não bloqueiam chefe; itens coletados e eventos concluídos preservam estado ao revisitar andar na mesma expedição; Pokémon recrutados persistem após retirada voluntária; cada dungeon possui espécies características com variações por bioma. Mantida a atualização de inventário por Pokémon (R35-Q3) e rejeição R33-Q5. Abre Rodada 37 sobre contatos hostis na equipe, missões entre expedições, desbloqueios de campanha, espécies iniciais e dificuldade nas revisitas. | Rodada 36 fechada / Rodada 37 aberta |

| 1.28 | 2026-11-02 | Rodada 37 (D-200 a D-204): contato hostil com qualquer integrante ativo inicia encontro 3D; missões secundárias principalmente locais à expedição e normalmente reiniciadas em nova tentativa; novas dungeons principalmente desbloqueadas por conclusão e chefes, objetivos narrativos complementares; protagonista entre conjunto selecionado de iniciais; dificuldade pode se adaptar à força/progressão da equipe nas revisitas. Rejeição R33-Q5 e inventário por Pokémon R35-Q3 preservados. Abre Rodada 38 sobre percepção dos inimigos, arenas 3D, capacidade da reserva, itens em trocas de equipe e Moves aprendidos. | Rodada 37 fechada / Rodada 38 aberta |

| 1.29 | 2026-11-02 | Rodada 38 (D-205 a D-209): detecção de inimigos principalmente por proximidade, sem linha de visão estrita; arenas 3D correspondem visualmente ao bioma/ambiente do encontro; reserva de Pokémon com capacidade limitada; itens transportados permanecem associados ao Pokémon na reserva; R38-Q5 C amplia para até oito Moves utilizáveis em combate, dos quais quatro principais para hotkeys rápidas, preservando Tackle separado e custos anteriores sem criar PP. Atualização dos trechos normativos sem editar registros históricos. Abre Rodada 39 sobre gestão dos oito Moves, impacto do bioma em arenas, reserva cheia, HP entre expedições e Moves após evolução. | Rodada 38 fechada / Rodada 39 aberta |

| 1.30 | 2026-11-03 | Adendo rastreável para combate das Rodadas 39–60, com D-149, D-150 e D-151; R60-Q3D permanece pendente. Preservados os trechos anteriores, a numeração histórica do GDD e a prioridade documental da D-001. | Rodada 60 parcialmente definida / Rodada 61 proposta |

| 1.31 | 2026-11-03 | Rodada 61: cinco escolhas aprovadas e documentadas em D-152 a D-156; curva de esquiva simétrica e decrescente, captura de duração no WINDUP, recálculo por troca de alvo e LUK por evento. | Rodada 61 fechada / Rodada 62 proposta |

| 1.32 | 2026-11-03 | Rodada 62: decisões D-157 a D-161; Moves sem WINDUP, desempate por ID estável, ordem determinística para LUK, AGI de referência 50 para trajetos e referência ATB pendente. | Rodada 62 encerrada / Rodada 63 proposta |

| 1.33 | 2026-11-03 | Rodada 62 conciliada: D-162–D-166 prevalecem sobre D-157–D-161, com referências históricas preservadas. Mediana AGI sujeita a validação, ATB inverso, piso 1, TRAVEL sem WINDUP e desempate por sorteio reproduzível. | Rodada 62 conciliada / Rodada 63 proposta |

| 1.34 | 2026-11-03 | Rodada 63: amostra de espécies controláveis e AGI-base em nível comum para mediana, calibração de ATB pelo ritmo existente, AGI dinâmica por atualização de ATB e tolerância 0,01 da arena no desempate; D-167–D-171. | Rodada 63 fechada / Rodada 64 proposta |

| 1.35 | 2026-11-03 | Rodada 64: AGI-base ao nível 50, média dos dois centrais na mediana par, espécies controláveis oficialmente planejadas, comparação ATB 3→5 e 0→5, proximidade horizontal; D-172–D-176. | Rodada 64 fechada / Rodada 65 proposta |

| 1.36 | 2026-11-03 | Rodada 65: formas alternativas só com AGI-base própria distinta; mediana apenas com dados completos; precisão fracionária; medição ATB controlada 3→5 e 0→5; distância horizontal entre posições lógicas; D-177–D-181. | Rodada 65 fechada / Rodada 66 proposta |

| 1.37 | 2026-11-03 | Rodada 66: deduplicação de formas por AGI distinta intrasespécie; derivação por fórmula oficial verificável; medição ATB baixa/intermediária/alta com cinco repetições e mediana; RNG próprio de retarget; D-182–D-186. | Rodada 66 fechada / Rodada 67 proposta |

| 1.38 | 2026-11-03 | Rodada 67: seed própria registrada para retarget; candidatos ordenados por ID antes do sorteio; RNG consumido só em empate real; seis medianas ATB separadas, conversão velocidade→AGI exigida; tempo simulado e real distintos; D-187–D-191. | Rodada 67 fechada / Rodada 68 proposta |

| 1.39 | 2026-11-04 | Rodada 68: ordem de eventos simultâneos de retarget por ID do atacante; resistência natural VIT/SPI antes dos estágios de DEF; dano mínimo 1 para acerto válido salvo imunidade/bloqueio; esquiva automática antes de crítico/status dependentes do acerto; D-192–D-195. | Rodada 68 fechada / Rodada 69 proposta |

| 1.40 | 2026-11-04 | Rodada 69: IDs únicos estáveis ao iniciar combate; mitigação percentual de retornos decrescentes com estrutura comum VIT/SPI; arredondamento único final e mínimo posterior; crítico e dano antes de status condicionado ao acerto quando alvo sobreviver; D-196–D-199. | Rodada 69 fechada / Rodada 70 proposta |

| 1.41 | 2026-11-04 | Rodada 70: IDs por slots aliados depois inimigos; mitigação racional R(x)=x/(x+K) com K ainda a validar; status multi-hit máximo uma tentativa por alvo/execução após último impacto; Q4D define descarte integral do odômetro no jogo principal, sem aprovar nova aferição de sobrevivência. D-200–D-203. | Rodada 70 fechada / Rodada 71 proposta |

| 1.42 | 2026-11-04 | Rodada 71: K único compartilhado por VIT/SPI, sem valor homologado; arredondamento final exatamente em 0,5 para cima; ID crescente sem reuso em eventual entrada posterior; status após último impacto destinado a cada alvo. D-204–D-207. | Rodada 71 fechada / Rodada 72 proposta |

| 1.43 | 2026-11-04 | Rodada 72: método de K por atributo de referência e mitigação-alvo com aprovação futura; retorno do mesmo combatente conserva ID; uma tentativa por status distinto, alvo e execução; interrupção após acertos válidos usa último impacto efetivamente executado para resolver status elegível. D-208–D-211. | Rodada 72 fechada / Rodada 73 proposta |

| 1.44 | 2026-11-04 | Rodada 73: levantamento rastreável de VIT/SPI nível 50 para proposta posterior; ordem de tentativas de status conforme ficha do Move; desempate de retarget simultâneo do mesmo atacante por ordem declarativa e índice estável; prioridade explícita para status declarados incompatíveis. D-212–D-215. | Rodada 73 fechada / Rodada 74 proposta |

| 1.45 | 2026-11-04 | Rodada 74: registrar lacunas VIT/SPI nível 50 sem finalizar referência sem dados verificáveis; ficha incompleta se incompatibilidade não tiver prioridade; índices de retarget definidos no plano determinístico ao declarar ataque; consumo simultâneo de RNG de status por ID do alvo, preservando instante lógico. D-216–D-219. | Rodada 74 fechada / Rodada 75 proposta |

| 1.46 | 2026-11-04 | Rodada 75: proposta de amostra verificável de defesa baixa/média/alta sujeita à aprovação; Move com prioridade de status incompatíveis ausente bloqueado em combate com indicação precisa; índices cancelados reservados sem reuso; desempate de RNG de status para mesmo alvo por atacante, declaração e índice. D-220–D-223. | Rodada 75 fechada / Rodada 76 proposta |

| 1.47 | 2026-11-04 | Rodada 76: classificação separada dos perfis VIT/SPI para amostra física/mágica/mista; validação de Move antes de confirmar sem consumir ATB/Burst ou ação; ocorrências condicionais previstas e indexadas na declaração; RNG próprio de status com seed inicial registrada, separado do retarget. D-224–D-227. | Rodada 76 fechada / Rodada 77 proposta |

| 1.48 | 2026-11-04 | Nova série Fichas de Moves M1: somente Q4A aprovada — MP adicional para mágicos/especiais com custos individuais a definir e superação expressa da regra sem MP da D-032; Q1D/Q2D/Q3D sem nova regra, aguardando quatro exemplos. D-228. | M1-Q4 registrada / M1-Q1–Q3 abertas / M2 proposta |

| 1.49 | 2026-11-04 | Fichas de Moves: orientação posterior aprova custos/windup acima do texto, descrição mecânica de dano/efeitos/modificadores integrada estilo LoL e descrição visual apenas em ficha fora de combate. Esquema técnico de alvos, fórmulas e custos MP continuam pendentes. D-229. | Apresentação de ficha aprovada / detalhes técnicos pendentes |

| 1.50 | 2026-11-04 | Correção de tooltip dos Moves: exibir dano e cura com valores numéricos em pontos, não somente multiplicadores de dano-base ou fórmulas; preservar texto integrado da D-229, custos/windup acima e visual exclusivamente fora de combate. Valores exemplificativos contextualizados não são dano-base aprovado. D-230. | Diretriz numérica de apresentação aprovada / fórmulas e valores-base pendentes |

| 1.51 | 2026-11-04 | Rodada 77: propor faixas VIT/SPI por distribuição verificável e aprovar cortes antes da amostra; IA filtra Moves incompletos antes da escolha e sem custo; máximo explícito para ocorrências condicionais variáveis; chance final status 0%/100% sem RNG. D-231–D-234. | Rodada 77 fechada / Rodada 78 proposta |

| 1.52 | 2026-11-04 | Rodada 78: propor tercis de VIT/SPI nível 50 separadamente, aprovando cortes concretos; IA pode considerar Tackle se nenhum Move válido e se elegível; bloquear confirmação de Move com plano sem máximo antes de debitar recursos/ação; exigir política aprovada para incompatibilidades entre status de Moves diferentes. D-236–D-239. | Rodada 78 fechada / Rodada 79 proposta |

| 1.53 | 2026-11-04 | Rodada 79: VIT/SPI idênticos na mesma faixa mesmo com tercis desiguais; IA sem Move/Tackle elegíveis reavalia na próxima oportunidade normal sem agir/gastar; excedente condicional rejeitado e violação registrada preservando eventos válidos; matriz de prioridades por pares de status incompatíveis entre Moves sujeita à aprovação. D-240–D-243. | Rodada 79 fechada / Rodada 80 proposta |

| 1.54 | 2026-11-04 | Fichas de Moves M2: dano-base/categoria/escalas separados com tooltip numérica; windup/trajeto/projétil separados; seleção/facção/abrangência independentes; efeitos individuais parametrizados; visual por fases apenas fora de combate; Dispel lista remoções e exceções. D-244–D-249. | M2 fechada / M3 proposta |

| 1.55 | 2026-11-04 | Rodada 80: valor VIT/SPI coincidente com limite aprovado recebe faixa superior; IA filtra Moves sem máximo condicional antes da escolha; excedente é rejeitado/registrado, continuando eventos válidos; matriz futura de prioridades entre Moves distintos vale também para conflito de status ativo e novo. D-250–D-253. | Rodada 80 fechada / Rodada 81 proposta |

| 1.56 | 2026-11-04 | Rodada 81: cada espécie conta uma vez na distribuição VIT/SPI nível 50 com variações individuais ±3 separadas; validar e indicar conjuntamente todas as causas aprovadas de bloqueio; registrar violações com IDs estruturados de Move, atacante, declaração, máximo e excedente; eliminar status perdedor por matriz aprovada sem restaurar. D-254–D-257. | Rodada 81 fechada / Rodada 82 proposta |

| 1.57 | 2026-11-04 | Fichas de Moves M3: (base + escala STR/MAG) × potência; proibir prévia de dano em seleção; efeitos herdam alvos/facção salvo exceção; AGI não acelera automaticamente projéteis; Dispel remove todos elegíveis; todo Move exceto Tackle consome MP. D-258–D-263. | M3 fechada / M4 proposta |

| 1.58 | 2026-11-04 | Rodada 82: universo de espécies oficial verificável para VIT/SPI nível 50 com lacunas e veto a cortes não representativos; lista textual compacta de omissões em seleção aberta; identificadores diagnósticos por declaração e sequência determinística de excessos; chance/elegibilidade antes de matriz de incompatibilidade. D-264–D-267. | Rodada 82 fechada / Rodada 83 proposta |

| 1.59 | 2026-11-05 | Guard: ação defensiva de 1 ATB (sem Burst), 2 s, sem cancelamento, ATB pausado, badge azul acima da vida, hotkey Shift e variante do bloco Evade; reduz dano com arredondamento para cima (valor provisório), sem recuo ao contato, quebrado pelo Brick Break (+1 ATB ao atacante); Mold Break só registrado; hit stun +0,30 s global; IA usa o Guard; barreira em cúpula reservada para um futuro Move Protect. Decisões D-269–D-273 (Guard = D-272; renumeradas das locais D-192–D-196, §12.34). | Guard implementado localmente, aguardando commit; Protect não definido |

> **Regra de preservação:** nas atualizações posteriores, não reescrever seções não relacionadas nem transformar hipóteses em decisões. Preservar este histórico, acrescentando entradas rastreáveis, e nunca afirmar que uma decisão foi implementada sem verificar o código e, quando cabível, executar testes.


---

## 12. Adendo documental — Rodadas 39–60 de combate (2026-11-03; revisão 1.30)

> **Escopo limitado.** Este adendo registra a continuidade documental desde a última revisão estrutural do GDD (Rodada 38). **Não substitui nem reescreve as seções históricas 0–11**. Conforme D-001, regras de **combate** têm como fonte atual as decisões expressas do criador, os documentos de **docs/decisoes/** e **docs/REGRAS_DO_JOGO.md**; o restante deste GDD pode conter referências de combate desatualizadas. Regras de exploração, campanha, economia e progressão não foram revisadas neste adendo.
>
> **Atenção à numeração:** os rótulos antigos “D-xxx” usados no histórico das Rodadas 1–38 deste GDD **não são equivalentes**, por mera coincidência numérica, aos arquivos “D-xxx” da pasta **docs/decisoes/** criada posteriormente para decisões de combate. Nos parágrafos abaixo, “D-149” etc. referem-se sempre aos **arquivos reais em docs/decisoes/**.

### 12.1 Fonte rastreável das rodadas intermediárias

- **Rodadas 39–53:** decisões de combate e IA registradas individualmente em **docs/decisoes/**, reunidas nas seções **17 a 33 de docs/REGRAS_DO_JOGO.md**. Este adendo não as republica nem as transforma em regras novas.
- **Rodadas 54–59:** atributos STR, MAG, VIT, SPI, AGI e LUK; tempo de trajeto por Move com modificação de AGI; ausência de teto permanente de 100; sorteios independentes com distribuição triangular; status probabilístico modificado pela diferença de LUK; e duração fixa após iniciar o ataque. Ver **D-117 a D-148** e seções **34 a 39 de docs/REGRAS_DO_JOGO.md**. A **D-146 substituiu expressamente** a taxa histórica de status da D-142 (1 pp/10 LUK por 1 pp/1 LUK).
- Estes vínculos são de **rastreabilidade documental**. Não afirmam implementação de código nem revisão integral de conflitos históricos deste GDD.

### 12.2 Rodada 60 — decisões aprovadas (sem implementação)

| Questão | Escolha | Decisão atual | Registro individual |
|---|---|---|---|
| R60-Q1 | **1A** | Se o alvo morrer durante wind-up e a D-108 trocar para outro alvo vivo, recalcular **uma vez** a duração do trajeto nesse evento e manter a nova duração fixa; exceção específica à D-148. | [D-149](decisoes/D-149-r60-q1-recalculo-unico-trajeto-na-troca-de-alvo.md) |
| R60-Q2 | **2B** | Chance de crítico probabilístico = **clamp(10% + (LUK_atacante − LUK_alvo) pontos percentuais, 0%, 100%)**. Exemplo do criador: LUK 70 contra 40 resulta em **40%**. | [D-150](decisoes/D-150-r60-q2-critico-luk-um-ponto-percentual.md) |
| R60-Q3 | **3D** | **Ainda não há fórmula aprovada.** Intenção literal: “diferente de critico, a evasiva reduz quanto maior fica, dividindo pela metade”. Necessário esclarecer a operação matemática. | Pendente; registrada na seção 40.3 do consolidado |
| R60-Q4 | **4A** | Chances finais de **crítico e esquiva automática** ficam entre **0% e 100%**; não altera teto de LUK, status garantidos nem a reação ativa da IA. | [D-151](decisoes/D-151-r60-q4-limites-critico-esquiva-automatica.md) |

### 12.3 Pendências expressas para as próximas rodadas

1. Especificar matematicamente o que significa **“dividindo pela metade”** no crescimento ou redução da esquiva automática com LUK, sem copiar por suposição a fórmula do crítico.
2. Definir o instante técnico de captura da duração do trajeto entre declaração, WINDUP e TRAVEL, preservando a exceção de troca de alvo da D-149.
3. Definir se sucessivas mortes de alvos durante o mesmo wind-up permitem novos recálculos; isso **não** foi resolvido pela R60-Q1.
4. Preservar D-012 (status de alvo único não esquiváveis), D-021 (reação ativa da IA separada), D-134 (efeitos garantidos), D-143 (chance final de status) e D-146 (coeficiente próprio de status).
5. Nenhuma dessas perguntas pendentes constitui aprovação por omissão; a especificação executável dependerá de decisões posteriores.

### 12.4 Referências de verificação e limite de escopo

- Fonte documental verificada na **main** antes deste adendo: commit **38b2212ba4f9a50a866607be2077adebe710b8f3**.
- Na main consultada, **scripts/combat/battle.gd** declara **CRIT_CHANCE = 0.1** e **AUTO_DODGE_CHANCE = 0.10**. Esses são **valores observados no código**, não confirmação de implementação das fórmulas da Rodada 60.
- Foram preservados o histórico e as regras antigas do GDD; esta atualização **não realizou migração ou auditoria integral das Rodadas 39–59 dentro das seções antigas**.
- Nenhum arquivo de código, recurso, teste ou configuração foi alterado por esta rodada.


### 12.5 Rodada 61 — decisões aprovadas em 2026-11-03 (revisão 1.31)

As cinco escolhas da Rodada 61 foram expressamente aprovadas: **1B, 2A, 3A, 4A, 5A**, sem observações adicionais. Registradas nos arquivos de decisões individuais D-152 a D-156 e consolidadas em **docs/REGRAS_DO_JOGO.md, seção 41**. Esta seção é **aditiva**: as declarações e pendências históricas da revisão 1.30 permanecem como registro do estado anterior, mas foram respondidas quanto aos tópicos expressamente escolhidos agora.

| Questão | Escolha | Regra aprovada | Documento |
|---|---|---|---|
| R61-Q1 | **1B** | Esquiva automática por LUK: ganhos marginais de **1, 0,5, 0,25, 0,125... pp por ponto** em faixas consecutivas de dez pontos da diferença de LUK | [D-152](decisoes/D-152-r61-q1-esquiva-luk-retorno-decrescente.md) |
| R61-Q2 | **2A** | Aplicar a mesma curva em sentido contrário quando a LUK do defensor é inferior; chance-base 10%, clamp 0–100% | [D-153](decisoes/D-153-r61-q2-esquiva-luk-curva-simetrica.md) |
| R61-Q3 | **3A** | Calcular duração do trajeto ao entrar **efetivamente em WINDUP**, em complemento à D-148 | [D-154](decisoes/D-154-r61-q3-trajeto-calculo-inicio-windup.md) |
| R61-Q4 | **4A** | Recalcular duração uma vez **por evento de troca automática de alvo** ainda no WINDUP | [D-155](decisoes/D-155-r61-q4-trajeto-recalculo-cada-troca-windup.md) |
| R61-Q5 | **5A** | Consultar LUK efetiva no instante em que **cada evento probabilístico** é resolvido | [D-156](decisoes/D-156-r61-q5-luk-no-instante-da-rolagem.md) |

**Exemplo de esquiva aprovado:** LUK defensor 70, atacante 40, diferença +30 → chance-base 10% + (10 + 5 + 2,5) pp = **27,5%**. Situação inversa, LUK 40 vs 70 → 10% − 17,5 pp = −7,5% intermediários → **0% final**. Os exemplos não alteram a fórmula linear de crítico da D-150 nem a de status probabilístico da D-146.

**Exemplo de WINDUP:** o personagem inicia WINDUP contra Pancham e fixa o tempo do trajeto. Se Pancham morrer durante WINDUP, a troca para Abra recalcula uma vez. Se Abra também morrer durante WINDUP, a troca para Gible recalcula uma vez novamente. A duração mais recente permanece fixa durante o trajeto.

**Exemplo de captura de LUK:** LUK atacante varia 40 → 50 → 60 entre declaração, início de TRAVEL e resolução do impacto; LUK alvo 40 na resolução. Se ocorrer rolagem de crítico probabilístico no impacto, a chance é **30%** pela D-150, usando o valor de LUK do momento da rolagem.

**Hierarquia de fontes:** preservar D-001; o GDD permanece não normativo para combate e os registros anteriores não são reescritos. **Pendentes:** Moves sem WINDUP, desempate de alvos igualmente próximos, ordem de eventos simultâneos e referências numéricas de AGI. **Sem implementação de código ou testes de gameplay.**


### 12.6 Rodada 62 — cinco escolhas expressas (2026-11-03; revisão 1.32)

A Rodada 62 aprovou **1A, 2A, 3A, 4A e 5B**, sem observações adicionais. As decisões estão nos documentos individuais D-157–D-161 e no consolidado `docs/REGRAS_DO_JOGO.md`, seção 42. Esta atualização é **aditiva**: registros e pendências históricos do GDD permanecem no estado em que foram documentados, incluindo conflitos resolvidos posteriormente. Conforme D-001, este GDD continua **não normativo para combate**.

| Questão | Escolha | Regra ou adiamento aprovado | Registro |
|---|---|---|---|
| R62-Q1 | **1A** | Para Move instantâneo sem WINDUP, calcular duração de eventual trajeto ao **iniciar efetivamente a execução**, sem inventar WINDUP | [D-157](decisoes/D-157-r62-q1-trajeto-instantaneo-inicio-execucao.md) |
| R62-Q2 | **2A** | Empate de distância entre alvos no redirecionamento de WINDUP: usar **identificador estável de combate** e resultado determinístico no mesmo estado | [D-158](decisoes/D-158-r62-q2-desempate-alvo-identificador-estavel.md) |
| R62-Q3 | **3A** | Eventos com a mesma posição temporal seguem uma **ordem determinística única**; mudanças de LUK antes da rolagem valem, depois não | [D-159](decisoes/D-159-r62-q3-ordem-deterministica-luk.md) |
| R62-Q4 | **4A** | AGI de referência **50** para duração dos trajetos, comum às espécies; não fixar ATB | [D-160](decisoes/D-160-r62-q4-referencia-agi-50-trajetos.md) |
| R62-Q5 | **5B** | Manter **referência numérica de AGI para ATB pendente** até avaliação do ritmo; nenhum valor aprovado | [D-161](decisoes/D-161-r62-q5-referencia-atb-pendente-avaliacao.md) |

**Exemplos ilustrativos vinculados às escolhas:** ataque instantâneo sem WINDUP captura o tempo no início da execução; retarget entre Abra e Gible à mesma distância usa o ID de combate estável, sem sorteio; um buff de LUK resolvido antes de uma rolagem no mesmo instante lógico influencia essa rolagem, enquanto um buff posterior não; Move de tempo-base 1,0 s com AGI efetiva 50 mantém 1,0 s antes dos passos, e com AGI efetiva 100 fica em 0,5 s antes dos passos, usando referência **50 apenas para trajetos**.

**Compatibilidades preservadas:** D-019 (única linha do tempo), D-095 (eliminação de ambas as equipes no mesmo instante lógico permanece empate), D-108/D-155 (retarget e recálculo durante WINDUP), D-133/D-136/D-140/D-145 (fórmula de trajeto e referências separadas), D-156 (LUK no momento do evento).

**Ainda pendente:** comparação/atribuição dos IDs estáveis; ordenação concreta de eventos simultâneos; eventual recaptura de AGI alterada no WINDUP durante o retarget; fórmula e referência de ATB; calibração e arredondamento. Não converter essas pendências em escolhas automáticas.

**Validação de fonte antes desta atualização:** `main` em `af42a7d608c7eb7aaa20adf16e86d41d4a276c3b`; a consulta ao código atual mostrou tempos e probabilidades fixas, sem comprovação de implementação das novas regras. **Nenhum código ou teste de gameplay alterado ou executado nesta atividade.**


### 12.7 Rodada 62 — versão prevalente confirmada (revisão 1.33)

> **2026-11-03.** A versão de Rodada 62 registrada na seção **12.6**, com D-157–D-161, divergira da resposta enviada pelo criador nesta conversa. Ele confirmou expressamente que as suas escolhas **1C, 2A, 3B, 4A e 5A prevalecem** sobre aquela versão já publicada. Por isso, **D-162 a D-166 são vigentes** e **D-157 a D-161 e a seção 12.6 permanecem íntegros como histórico**, com conciliações posteriores. Para combate, preservar D-001: este GDD é adendo rastreável, não fonte superior às decisões individuais e ao consolidado.

| Questão | Escolha vigente | Regra aprovada | Decisão |
|---|---|---|---|
| R62-Q1 | **1C** | Referência AGI do **trajeto** por **mediana das espécies jogáveis**, com **número sujeito a validação antes da implementação**; referência 50 histórica da D-160 não prevalece | [D-162](decisoes/D-162-r62-q1-trajeto-referencia-agi-mediana-jogaveis.md) |
| R62-Q2 | **2A** | Tempo natural de preenchimento **ATB inversamente proporcional à AGI efetiva**, mantendo referência ATB numérica pendente | [D-163](decisoes/D-163-r62-q2-atb-tempo-inverso-agi.md) |
| R62-Q3 | **3B** | **AGI mínima 1 só no cálculo da regeneração ATB**, sem alterar atributo; aplicação adicional distinta do piso de trajeto D-140 | [D-164](decisoes/D-164-r62-q3-piso-agi-um-na-regeneracao-atb.md) |
| R62-Q4 | **4A** | Move com TRAVEL e sem WINDUP calcula duração **ao entrar efetivamente em TRAVEL** | [D-165](decisoes/D-165-r62-q4-sem-windup-calculo-entrada-travel.md) |
| R62-Q5 | **5A** | Entre inimigos vivos igualmente próximos no retarget de WINDUP, **sortear com aleatoriedade reproduzível**, em vez de desempate por ID | [D-166](decisoes/D-166-r62-q5-desempate-aleatorio-reproduzivel.md) |

**Conciliação:** D-157 (marco genérico) foi especificada pela D-165 (TRAVEL); D-158 (ID estável) foi substituída por D-166 (sorteio); D-159 (ordem fina dos eventos) **não foi ratificada por esta versão** e permanece histórico, sem revogar D-019/D-095/D-156; D-160 (AGI 50) foi substituída por D-162 (mediana sujeita a validação); D-161 (adiar referência numérica ATB) não é a resposta vigente Q5, embora a referência ainda não tenha número, agora coexistindo com a fórmula aprovada D-163.

**Exemplos apenas explicativos:** uma lista fictícia de AGIs 20, 30, 40, 50, 60 tem mediana 40, **não aprovada**; dobrar AGI positiva reduz à metade o tempo de preenchimento da mesma quantidade natural de ATB; AGI 45 na confirmação e 60 na entrada TRAVEL sem WINDUP usa 60 para calcular duração; alvos igualmente próximos participam de sorteio reproduzível. **Sem código ou testes de gameplay.**

**Pendências:** composição da mediana e sua validação, referência numérica ATB, detalhes de calibração, igualdade geométrica de distâncias, seed/ordem de RNG e ordenação fina de eventos simultâneos.


### 12.8 Rodada 63 — definição da amostra AGI, calibração ATB e tolerância de empate (revisão 1.34)

> **2026-11-03.** O criador aprovou expressamente **1B, 2A, 3A, 4A e 5B**, sem observações adicionais. Decisões individuais **D-167 a D-171** e consolidação em **docs/REGRAS_DO_JOGO.md, seção 44**. Esta atualização é aditiva e preserva integralmente o histórico da versão divergente da Rodada 62 nas seções 12.6/12.7; em combate, D-001 mantém a precedência das decisões do criador e do consolidado.

| Questão | Escolha | Regra vigente | Registro |
|---|---|---|---|
| R63-Q1 | **1B** | A mediana de AGI dos trajetos considera **todas as espécies diretamente controláveis pelo jogador**, **inclusive evoluções elegíveis**, não apenas iniciais | [D-167](decisoes/D-167-r63-q1-mediana-todas-especies-controlaveis.md) |
| R63-Q2 | **2A** | Usar **AGI-base de cada espécie em nível comum** sem Nature, variação individual ou buffs; **nível ainda por decidir** | [D-168](decisoes/D-168-r63-q2-agi-base-nivel-comum-sem-modificadores.md) |
| R63-Q3 | **3A** | Definir a **referência ATB** pela **calibração do ritmo existente**, apresentando o valor para aprovação **antes de implementar** | [D-169](decisoes/D-169-r63-q3-referencia-atb-calibrar-ritmo-existente.md) |
| R63-Q4 | **4A** | Consultar **AGI efetiva a cada atualização da regeneração natural do ATB**, mantendo o progresso acumulado | [D-170](decisoes/D-170-r63-q4-agi-atualizada-a-cada-tick-regeneracao-atb.md) |
| R63-Q5 | **5B** | Considerar empate de proximidade entre candidatos com **diferença de distâncias até 0,01 unidade da arena**, inclusive 0,01; sorteio reproduzível da D-166 preservado | [D-171](decisoes/D-171-r63-q5-tolerancia-empate-distancia-001-arena.md) |

**Exemplos ilustrativos, não novas especificações:** se uma espécie inicial e sua evolução forem ambas controláveis, entram ambas na mediana; AGI-base hipotética 35 em um nível comum ainda não aprovado continua 35 para a mediana, mesmo que Nature/variação alterem um indivíduo. ATB com 2 blocos já acumulados usa AGI 20 nas atualizações anteriores e AGI 40 nas seguintes após um buff válido, sem modificar os blocos anteriores. Alvos a 4,000 e 4,006 unidades são considerados empatados para o sorteio; outro a 4,020 não é.

**Pendências expressas:** o **nível comum de comparação**, a identificação das espécies controláveis e suas AGIs-base efetivas, o cálculo da mediana, a **validação do valor numérico de referência de trajetos antes de implementar**, a medição/calibração e **validação da referência ATB**, além da métrica geométrica concreta, seed e ordem de consumo de RNG. O exemplo de 0,01 usa unidades espaciais da arena, não metros físicos por suposição. **Nenhum código ou teste de gameplay foi alterado ou executado nesta atualização.**


### 12.9 Rodada 64 — nível 50, mediana par, espécies planejadas, calibração ATB e proximidade horizontal (revisão 1.35)

> **2026-11-03.** Aprovações expressas **1C, 2A, 3B, 4C e 5B**, sem observações adicionais. Decisões individuais **D-172 a D-176** e consolidação em **docs/REGRAS_DO_JOGO.md, seção 45**. Adendo estritamente documental e aditivo; **preserva** o histórico e a conciliação anteriores. O GDD não é fonte normativa de combate por D-001.

| Questão | Escolha | Regra aprovada | Documento |
|---|---|---|---|
| R64-Q1 | **1C** | AGI-base das espécies elegíveis comparada no **nível 50**, com Nature, variações e buffs excluídos só da amostra da mediana | [D-172](decisoes/D-172-r64-q1-nivel-50-mediana-agi.md) |
| R64-Q2 | **2A** | Mediana de quantidade par de espécies: **média dos dois valores centrais** ordenados | [D-173](decisoes/D-173-r64-q2-mediana-par-media-dois-centrais.md) |
| R64-Q3 | **3B** | A amostra inclui espécies **oficialmente previstas na documentação vigente para controle direto**, mesmo não implementadas | [D-174](decisoes/D-174-r64-q3-especies-controlaveis-planejadas-documentadas.md) |
| R64-Q4 | **4C** | Calibrar referência ATB medindo **ambos os intervalos de regeneração natural: 3→5 e 0→5 blocos**, comparando com o ritmo vigente | [D-175](decisoes/D-175-r64-q4-calibracao-atb-intervalos-3a5-e-0a5.md) |
| R64-Q5 | **5B** | Distância de proximidade para retarget em WINDUP: **horizontal no plano da arena**, ignorando altura | [D-176](decisoes/D-176-r64-q5-distancia-horizontal-plano-arena.md) |

**Exemplos apenas ilustrativos:** AGIs ordenadas fictícias `20, 30, 50, 60` → mediana 40 (não é referência real aprovada). Se a regeneração hipotética for 1 bloco/s, de 3→5 levaria 2 s e de 0→5 levaria 5 s (não são medições do jogo). Um inimigo a 5 unidades horizontais e 3 unidades acima é avaliado por **5 unidades** de distância para seleção de alvo (não 5,83 em 3D). A tolerância 0,01 de D-171 e o sorteio reproduzível D-166 permanecem vigentes.

**Pendentes:** verificar as espécies controláveis e oficialmente previstas, obter valores reais de AGI-base no nível 50, calcular mediana e **solicitar validação do número antes de implementar** (D-162); realizar duas medições de ATB e **submeter valor de referência à aprovação** (D-169); definir referência geométrica horizontal e detalhes de RNG; política para fichas/AGI ausentes e mediana fracionária. **Nenhum código ou teste de gameplay modificado ou executado nesta atualização.**


### 12.10 Rodada 65 — formas alternativas, mediana exata, completude, ATB controlado e posições lógicas (revisão 1.36)

> **2026-11-03.** As escolhas **1C, 2A, 3A, 4A e 5A** foram expressamente aprovadas, sem observações. Registros **D-177 a D-181** e consolidação na **seção 46** de `docs/REGRAS_DO_JOGO.md`. Esta é uma atualização **aditiva**, preservando todas as seções anteriores e a divergência histórica da Rodada 62. Por **D-001**, este adendo não torna o GDD fonte normativa para combate.

| Questão | Escolha | Regra documentada | Decisão |
|---|---|---|---|
| R65-Q1 | **1C** | Contar formas alternativas separadamente **somente quando forem controláveis e possuírem AGI-base própria distinta** | [D-177](decisoes/D-177-r65-q1-formas-alternativas-agi-propria-distinta.md) |
| R65-Q2 | **2A** | **Não finalizar mediana** se faltar AGI-base verificável **no nível 50** para qualquer espécie elegível | [D-178](decisoes/D-178-r65-q2-nao-finalizar-mediana-sem-dados-completos.md) |
| R65-Q3 | **3A** | **Preservar valor fracionário exato da mediana**, sem arredondamento | [D-179](decisoes/D-179-r65-q3-mediana-fracionaria-exata-sem-arredondar.md) |
| R65-Q4 | **4A** | Medir **3→5 e 0→5 blocos de ATB em condições controladas**, regeneração natural ativa, **sem buffs, ações, recompensas instantâneas ou pausas** | [D-180](decisoes/D-180-r65-q4-atb-medicao-controlada-sem-interferencias.md) |
| R65-Q5 | **5A** | Medir a **distância horizontal entre posições lógicas de referência dos combatentes**, não centros ou superfícies de colisão | [D-181](decisoes/D-181-r65-q5-distancia-posicoes-logicas-plano-horizontal.md) |

**Exemplos ilustrativos, não parâmetros aprovados:** forma-base controlável com AGI-base hipotética 40 e forma alternativa também controlável com AGI-base própria 65 → duas entradas; variante cosmética com AGI-base idêntica não aumenta automaticamente a amostra. Se os dois valores centrais forem 42 e 43, a mediana é **42,5** e permanece fracionária. Sob regeneração fictícia de 1 bloco/s, 3→5 demoraria 2 s e 0→5, 5 s; isso **não foi medido**. Com distâncias lógicas horizontais 4,000 e 4,006, há empate segundo a tolerância inclusiva 0,01 de D-171.

**Não resolvido:** lista real e AGI-base nível 50 de todas as espécies/formas elegíveis, completude da amostra, validação do valor da mediana para trajetos (D-162); medição real dos intervalos naturais de ATB e validação da referência ATB (D-169); identificação dos pontos lógicos de posição no código e política de RNG reproduzível. **Nenhum código, ficha, cena, teste ou VFX modificado; nenhuma medição executada.**


### 12.11 Rodada 66 — valores distintos por espécie, AGI oficial verificável, medição estratificada e RNG isolado (revisão 1.37)

> **2026-11-03.** Decisões expressas **1A, 2B, 3B, 4B e 5A**, sem observações adicionais; **D-182–D-186** e seção **47** de `docs/REGRAS_DO_JOGO.md`. Registro aditivo e de rastreabilidade; as revisões e conflitos históricos anteriores permanecem intactos. O GDD continua **não normativo para combate** por D-001.

| Questão | Escolha | Regra aprovada | Documento |
|---|---|---|---|
| R66-Q1 | **1A** | **Uma observação por AGI-base distinta dentro da mesma espécie**: não duplicar formas com valor igual, mas preservar observações de espécies diferentes | [D-182](decisoes/D-182-r66-q1-formas-um-valor-distinto-agi-por-especie.md) |
| R66-Q2 | **2B** | Valor AGI-base nível 50 pode ser **calculado por fórmula oficialmente aprovada e verificável, com entradas documentadas**; sem fórmula válida, manter pendência | [D-183](decisoes/D-183-r66-q2-agi-nivel50-por-formula-oficial-verificavel.md) |
| R66-Q3 | **3B** | Medir representantes das **faixas baixa, intermediária e alta de velocidade realmente presentes no código**, sob as mesmas condições controladas | [D-184](decisoes/D-184-r66-q3-atb-perfis-velocidade-baixa-media-alta.md) |
| R66-Q4 | **4B** | **Cinco medições para cada intervalo e combatente**, usando **mediana dos cinco tempos observados** | [D-185](decisoes/D-185-r66-q4-atb-cinco-medicoes-mediana-por-intervalo.md) |
| R66-Q5 | **5A** | Desempates de retarget usam **fluxo próprio de RNG reproduzível**, isolado dos demais sorteios do combate | [D-186](decisoes/D-186-r66-q5-fluxo-rng-exclusivo-desempate-retarget.md) |

**Exemplos exclusivamente ilustrativos:** espécie A com AGI-base 40 e duas formas controláveis com AGI própria 60 produz duas observações (`40, 60`), não três; espécie B de AGI 60 continua contribuindo separadamente. Se cinco observações de tempo forem `2,00; 2,01; 2,00; 2,18; 2,01 s`, sua mediana é **2,01 s** (não medido no jogo). Uma rolagem de crítico não deve avançar o fluxo exclusivo de RNG de retarget.

**Pendências e garantias:** identificar fontes oficiais de espécies e fórmulas de AGI-base no nível 50, formar amostra completa e **validar mediana real com o criador antes de implementar (D-162)**; selecionar perfis reais, medir 3→5 e 0→5 controladamente cinco vezes por perfil, consolidar tempos e **submeter referência ATB à validação (D-169)**; definir seed, algoritmo, ordenação e consumo de RNG. **Nenhum código ou teste alterado, nenhuma medição ou cálculo real executado nesta rodada.**


### 12.12 Rodada 67 — seed e consumo de RNG, seis medianas ATB e relógios separados (revisão 1.38)

> **2026-11-03.** O criador aprovou expressamente **1B, 2A, 3A, 4A e 5C**, sem observações adicionais. Novas decisões **D-187 a D-191** e seção **48** de `docs/REGRAS_DO_JOGO.md`. Registro **aditivo**, preservando os históricos anteriores, inclusive a divergência da Rodada 62. **D-001:** GDD não é fonte normativa de combate.

| Questão | Escolha | Regra aprovada | Decisão |
|---|---|---|---|
| R67-Q1 | **1B** | Gerar **seed exclusiva do RNG de retarget ao iniciar o combate**, registrá-la para reprodução | [D-187](decisoes/D-187-r67-q1-seed-propria-retarget-inicio-combate.md) |
| R67-Q2 | **2A** | Ordenar **candidatos empatados por identificador estável de combatente na batalha antes de sortear**, sem selecionar automaticamente o menor ID | [D-188](decisoes/D-188-r67-q2-ordenacao-candidatos-id-estavel-antes-rng.md) |
| R67-Q3 | **3A** | Consumir RNG de retarget **somente com dois ou mais candidatos empatados elegíveis** | [D-189](decisoes/D-189-r67-q3-rng-so-consumir-em-empate-real.md) |
| R67-Q4 | **4A** | Apresentar **as seis medianas de tempo ATB separadamente**; **não definir referência de AGI/ATB sem conversão verificável entre velocidade atual e AGI** | [D-190](decisoes/D-190-r67-q4-seis-medianas-atb-antes-conversao-agi.md) |
| R67-Q5 | **5C** | Registrar **tempo simulado e tempo real separadamente** por medição para diagnosticar discrepâncias | [D-191](decisoes/D-191-r67-q5-tempo-simulado-real-medições-atb-separados.md) |

**Exemplos ilustrativos, não dados reais:** IDs empatados `8, 3, 5` são ordenados `3, 5, 8` **antes do sorteio**, não selecionados deterministamente. Quando só Abra é elegível ao retarget, o fluxo isolado não consome RNG; dois empatados exigem sorteio. Uma medição hipotética de ATB com **2,00 s simulados** e **2,08 s reais** mantém os dois valores distintos. A análise dos três perfis × dois intervalos fornece **seis combinações** por tipo de relógio, sem agregá-las em referência numérica presumida.

**Pendências e limites:** seed registrada mas ainda sem algoritmo, representação, serialização ou rotina de replay escolhidos; identificadores estáveis e concorrência de sorteios ainda por verificar. ATB: obter perfis reais, executar medições, definir **conversão verificável velocidade atual→AGI**, apresentar seis medianas por tipo de relógio e **validar a referência numérica com o criador antes de implementar (D-169)**. A mediana de AGI-base dos trajetos (D-162) também continua sem resultado real homologado. **Nenhum código, teste, dado de espécie, cena ou VFX modificado; nenhuma medição executada nesta rodada.**

### 12.13 Conferência de reapresentação da Rodada 60 — divergências mantidas em aberto (2026-11-04; nota de rastreabilidade)

> **Natureza desta nota:** a solicitação de 2026-11-04 reapresenta quatro respostas da Rodada 60 e pede continuidade do registro documental. Na conferência da `main` (HEAD anterior a esta nota: `5b1564b74ec3d92c8fc8c3c77426aaa5eec11851`), a Rodada 60 já constava nas D-149–D-151 e as Rodadas 61–67 nas D-152–D-191. **Não** duplicar registros nem reabrir como inéditas perguntas já respondidas. Esta nota preserva a divergência textual para consulta do criador, **sem atribuir precedência**, sem homologar fórmula nova e sem mudar as decisões individuais ou o consolidado.

| Questão reapresentada | Texto de 2026-11-04 | Histórico documental existente | Situação |
|---|---|---|---|
| R60-Q1 | **1A:** recalcular uma vez a duração do trajeto quando há troca automática de alvo morto no WINDUP | **D-149 (1A)**; D-155 esclarece um recálculo **por cada troca efetiva** no WINDUP | **Compatível; já registrada** |
| R60-Q2 | **2A:** crítico com base 10% + **1 pp a cada 10 pontos de diferença de LUK**; exemplo LUK 70 contra 40 → **13%** | **D-150 (2B):** base 10% + **1 pp por ponto** de diferença; mesmo exemplo → **40%**. D-156 pressupõe esta fórmula. | **Divergência material pendente de confirmação** |
| R60-Q3 | **3A:** esquiva automática com base 10% + **1 pp a cada 10 pontos de diferença de LUK a favor do defensor**; exemplo 70 contra 40 → **13%** | **D-151 documenta R60-Q3D** como resposta histórica; **D-152/D-153**, aprovadas na R61, definem retorno marginal decrescente e curva simétrica; mesmo exemplo → **27,5%**. | **Divergência material pendente de confirmação** |
| R60-Q4 | **4A:** chance final de crítico e esquiva automática limitada a **0–100%** | **D-151 (4A)** | **Compatível; já registrada** |

**Confirmação necessária, sem inferência:** determinar se as escolhas **2A e 3A reapresentadas** pretendem **substituir expressamente** as regras posteriormente registradas em **D-150** e **D-152/D-153**, respectivamente, ou se foram incluídas apenas como transcrição de uma versão anterior da Rodada 60. **Nenhuma precedência é escolhida nesta nota.** Até essa resposta, as decisões publicadas continuam documentadas integralmente, sem alteração silenciosa da regra vigente nem criação de novos D-*. A D-001 permanece: para combate, a fonte normativa é o histórico de decisões do criador e `docs/REGRAS_DO_JOGO.md`, **não** o GDD.

**Escopo:** somente acréscimo desta nota de rastreabilidade no GDD. Não foram editados o índice, os documentos de decisão, as regras consolidadas, o código, os testes, assets, VFX nem as fichas de Moves. **A Rodada 68 será apresentada como questionário; nenhuma resposta futura é considerada aprovada.**

### 12.14 Rodada 68 — retarget simultâneo, defesa natural, dano mínimo e ordem das rolagens (revisão 1.39)

> **2026-11-04.** O criador aprovou expressamente **1A, 2A, 3A e 4A**, sem observações próprias. Decisões individuais **D-192 a D-195**, consolidadas na **seção 49** de `docs/REGRAS_DO_JOGO.md`. Esta seção é **aditiva**, sem reescrever as Rodadas 39–67 nem a **conferência divergente da Rodada 60 (§12.13)**. Conforme **D-001**, o GDD **não se torna fonte normativa de combate**.

| Questão | Escolha | Regra aprovada | Registro |
|---|---|---|---|
| R68-Q1 | **1A** | Ordenar eventos de retarget **simultâneos que requerem RNG exclusivo** pelo **ID estável do atacante** antes de consumir sorteios; **não** escolher automaticamente o menor ID entre alvos | [D-192](decisoes/D-192-r68-q1-ordem-retarget-simultaneo-id-atacante.md) |
| R68-Q2 | **2A** | Aplicar **resistência natural de VIT/SPI antes dos estágios de DEF**, conservando VIT para físico e SPI para mágico | [D-193](decisoes/D-193-r68-q2-resistencia-natural-antes-def.md) |
| R68-Q3 | **3A** | Golpes danosos com **acerto válido** causam **mínimo 1** após mitigação, **exceto imunidade ou bloqueio completo** | [D-194](decisoes/D-194-r68-q3-dano-minimo-um-golpe-valido.md) |
| R68-Q4 | **4A** | Resolver **esquiva automática antes** de crítico/status dependentes do acerto; se esquivar, **não rolar** esses efeitos | [D-195](decisoes/D-195-r68-q4-esquiva-antes-critico-status.md) |

**Exemplos não normativos:** (i) retarget simultâneo dos atacantes ID 2 e 5, com empate real em ambos: sorteio do 2 precede sorteio do 5; dentro de cada evento continuam válidos D-188/D-189. (ii) Dano hipotético 100, resistência fictícia de 20 pontos e estágio fictício ×0,8 produziria 64, **sem aprovar uma fórmula subtrativa**. (iii) Dano hipotético pós-mitigação 0,4 de golpe válido resulta em mínimo **1** sem imunidade/bloqueio. (iv) Esquiva automática bem-sucedida impede rolagens de crítico/status **que dependam do acerto**, preservando debuffs não esquiváveis da D-012.

**Preservações e pendências:** D-095 mantém **empate por eliminações no mesmo instante lógico**, independente da ordem de RNG; D-130/D-138 mantêm separação VIT/SPI e estágios de DEF; D-134/D-146/D-150–D-153/D-156 mantêm suas regras e o conflito textual **R60-Q2/Q3 do §12.13 permanece aberto**, sem resolução implícita nesta rodada. Fórmulas/coeficientes de resistência, arredondamento e relação com outros fatores de dano, granularidade dos eventos simultâneos e dois retargets do mesmo atacante ainda dependem de escolhas futuras. **Nenhum código, teste, Move, asset, VFX ou cenário modificado; nenhum teste de gameplay executado.**

### 12.15 Rodada 69 — IDs únicos, mitigação VIT/SPI, arredondamento final e status após dano (revisão 1.40)

> **2026-11-04.** O criador aprovou expressamente **1A, 2A, 3A e 4A**, sem regras próprias adicionais. Decisões individuais **D-196 a D-199**, consolidadas na **seção 50** de `docs/REGRAS_DO_JOGO.md`. Atualização exclusivamente documental e **aditiva**: mantém a origem normativa de combate em D-001, a divergência da Rodada 60 no §12.13 e o histórico integral das Rodadas 39–68.

| Questão | Escolha | Regra aprovada | Documento |
|---|---|---|---|
| R69-Q1 | **1A** | Atribuir **identificadores únicos ao iniciar o combate**, conforme ordem estável/documentada ainda a especificar, e **não renumerar participantes durante a batalha** | [D-196](decisoes/D-196-r69-q1-ids-unicos-estaveis-por-combate.md) |
| R69-Q2 | **2A** | Defesa natural VIT e SPI deve usar **mitigação percentual com retornos decrescentes e mesma estrutura de curva**, VIT para físico e SPI para mágico | [D-197](decisoes/D-197-r69-q2-mitigacao-percentual-retornos-decrescentes-vit-spi.md) |
| R69-Q3 | **3A** | Preservar **decimais até terminar os modificadores**, arredondar **uma vez ao final**, depois aplicar mínimo cabível segundo D-194 | [D-198](decisoes/D-198-r69-q3-arredondamento-unico-final-dano.md) |
| R69-Q4 | **4A** | Após acerto válido, resolver **crítico e dano primeiro**; aplicar **status condicionado ao acerto somente se o alvo sobreviver** | [D-199](decisoes/D-199-r69-q4-critico-dano-antes-status-alvo-sobrevive.md) |

**Exemplos estritamente ilustrativos:** (i) combatentes recebem IDs diferentes ao começar a batalha e não mudam de ID ao perder companheiros; o exemplo não aprova uma ordem de atribuição. (ii) SPI 40→50 e 90→100 oferece benefício percentual marginal cada vez menor, sem fixar valores de porcentagem. (iii) 9,4×0,7×0,8 = 5,264 → **5** após um único arredondamento; números hipotéticos, não parâmetros oficiais. (iv) um golpe crítico que derrota Abra não aplica Stun **dependente desse acerto**; se Abra sobreviver, a aplicação segue a ficha e a LUK vigente.

**Limites e rastreabilidade:** a ordem **VIT/SPI antes de DEF** (D-193), o **dano mínimo 1 salvo imunidade/bloqueio completo** (D-194) e a **esquiva automática antes do crítico/status** (D-195) permanecem. O código atual contém arredondamentos separados em `battle.gd` e `combatant.gd`, portanto a D-198 ainda **não está implementada**, e as fórmulas novas de VIT/SPI também não foram integradas. Permanecem sem aprovação: ordem concreta para atribuir IDs, coeficientes/equação de mitigação, tratamento do exato x,5, fatores restantes da cadeia de dano, condições de multi-hit e sobrevivência com HP rolante. A **divergência de LUK R60-Q2/Q3 (§12.13) continua sem resolução**. **Nenhum código, teste, dado, Move, asset, cena ou VFX alterado; nenhum teste de gameplay executado.**

### 12.16 Rodada 70 — IDs por slots, defesa racional, status por execução e descarte do odômetro (revisão 1.41)

> **2026-11-04.** Respostas do criador: **1A, 2A, 3A e 4D**, com a observação literal **“o odometro era só um teste, não usaremos ele no jogo principal, descarte toda e qualquer ideia que o envolva”**. Registros **D-200–D-203**, consolidados em **§51** de `docs/REGRAS_DO_JOGO.md`. Conforme D-001, o GDD permanece **não normativo para combate**. Este adendo não apaga decisões, trechos antigos ou arquivos de código.

| Questão | Resposta | Registro aprovado |
|---|---|---|
| R70-Q1 | **1A** | **D-200:** IDs estáveis únicos, atribuídos sequencialmente na composição inicial pelos slots da equipe do protagonista e depois pelos slots inimigos, sem renumeração durante o combate. |
| R70-Q2 | **2A** | **D-201:** mitigação natural percentual para VIT/SPI pela **função racional R(x) = x/(x+K)**, **K positivo a calibrar e validar depois**. Mesma estrutura funcional, parâmetros ainda indefinidos. |
| R70-Q3 | **3A** | **D-202:** Move multi-hit com status condicionado ao acerto permite **no máximo uma tentativa por alvo e execução**, **após último impacto** e **somente quando o alvo sobreviver** e tiver recebido acerto válido. |
| R70-Q4 | **4D + regra própria** | **D-203:** odômetro de HP pertenceu a **teste/protótipo** e está **descartado de qualquer requisito ou ideia do jogo principal**. **Não foi escolhida uma nova lógica de sobrevivência** entre 4A/4B/4C. |

**Exemplos somente ilustrativos:** slots aliados Gible/Abra e inimigos Pancham/outro → IDs em ordem sequencial ilustrativa, sem fixar número inicial; `x=50` e `K=100` fictício → `R=1/3 ≈ 33,33%`, sem homologar K; três impactos com possibilidade de Poison contra um alvo sobrevivente geram no máximo uma tentativa desse status após o último impacto, não uma por hit.

**Preservação e precedência:** a decisão histórica `docs/decisoes/D-048-rolling-hp-mother3-odometro.md` continua no repositório como evidência de **teste antigo**, **superada exclusivamente para o jogo principal** por D-203. Não confundir com a distinta `D-048-r40-q8-atb-aoe-unico.md`, relativa a recompensas AoE. Código atual ainda contém `rolling_hp_enabled`, `target_hp`, `tick_rolling_hp` e o teste correspondente, **sem qualquer autorização nesta rodada para excluir, desligar ou refatorar esses recursos**. D-199 conserva status após dano somente para sobreviventes; a origem lógica dessa sobrevivência **não foi definida na escolha 4D**. As fórmulas de LUK divergentes na reapresentação da Rodada 60 (§12.13) continuam sem precedência nova, e as demais decisões anteriores são preservadas.

**Pendências e escopo:** K e critério de calibração; entrada tardia de combatentes e número inicial dos IDs; multi-status e instantes lógicos dos impactos; meia unidade no arredondamento e desempates de retarget do mesmo atacante. **Somente documentação:** nenhum código, teste, Move, VFX, cena ou asset modificado; nenhum teste de gameplay executado.

### 12.17 Rodada 71 — K compartilhado, arredondamento exato, novos IDs e resolução de status por alvo (revisão 1.42)

> **2026-11-04.** O criador aprovou expressamente **1A, 2A, 3A e 4A** e declarou não haver observações próprias. Regras novas **D-204 a D-207**, consolidadas em **§52 de `docs/REGRAS_DO_JOGO.md`**. Esta seção é **aditiva**, sem revogar qualquer decisão histórica. Como determinado por D-001, o GDD não é fonte normativa para as regras de combate.

| Questão | Escolha | Regra aprovada | Documento |
|---|---|---|---|
| R71-Q1 | **1A** | **Um único valor numérico positivo de K**, compartilhado pela curva racional `R(x)=x/(x+K)` de VIT e SPI; **K concreto permanece pendente de calibração e validação** | [D-204](decisoes/D-204-r71-q1-k-unico-compartilhado-vit-spi.md) |
| R71-Q2 | **2A** | Em valor final de dano com parte fracionária **exatamente 0,5**, **arredondar para o inteiro superior**, após concluir todos os modificadores e antes do piso cabível | [D-205](decisoes/D-205-r71-q2-arredondamento-metade-para-cima.md) |
| R71-Q3 | **3A** | Se houver **novo participante após o início**, atribuir o **próximo ID não usado**, **sem renumerar ou reutilizar IDs anteriores**; não aprova reforços por si só | [D-206](decisoes/D-206-r71-q3-proximo-id-sem-reuso-entradas-posteriores.md) |
| R71-Q4 | **4A** | Em Move multi-alvo/multi-hit, tentar status elegível de **cada alvo após seu último impacto próprio**, sem aguardar os impactos contra os demais alvos; teto de **uma tentativa por alvo/execução** (D-202) | [D-207](decisoes/D-207-r71-q4-status-apos-ultimo-impacto-por-alvo.md) |

**Exemplos não normativos:** com `VIT=SPI=50` e **K hipotético 100**, cada categoria teria `R=1/3`; **K=100 não foi aprovado**. O desempate exato `4,5 → 5` e `5,5 → 6` esclarece D-198. Com IDs fictícios `1,2,3`, a saída do participante 2 não libera ID 2: o **novo** participante recebe o próximo número `4`. Uma onda que conclua os impactos destinados a Gible antes de atingir Abra/Pancham pode resolver o status **de Gible** após seu próprio último impacto, se ele sobreviveu a acerto válido; não antecipar ou multiplicar rolagens.

**Pendências e preservações:** não definir K numérico, efeitos de reentrada do **mesmo** combatente, duas entradas perfeitamente simultâneas, múltiplos status diferentes de um Move, ordem de impactos simultâneos ou precisão/tolerância de ponto flutuante. D-203 mantém **odômetro fora do jogo principal**; D-095 mantém empate de KO simultâneo; a divergência de LUK da reapresentação R60 (§12.13) permanece **sem nova precedência**. **Somente documentação**: nenhum código, teste, ficha, cena, asset ou VFX modificado; nenhum teste de gameplay realizado.

### 12.18 Rodada 72 — calibração de K, identidade no retorno e status sob múltiplos efeitos/interrupção (revisão 1.43)

> **2026-11-04.** Respostas expressas do criador: **1A, 2A, 3A, 4A**; observações adicionais: nenhuma. Novas decisões individuais **D-208 a D-211**, consolidadas em **§53** de `docs/REGRAS_DO_JOGO.md`. Adendo estritamente documental; D-001 mantém o GDD não normativo para combate e o histórico integral das Rodadas 39–71 não é reescrito.

| Pergunta | Escolha | Decisão aprovada | Registro |
|---|---|---|---|
| R72-Q1 | **1A** | **Calibrar K** a partir de atributo defensivo de referência e porcentagem de mitigação-alvo, **ambos submetidos posteriormente a aprovação**; não há referência, alvo nem valor numérico de K aprovados | [D-208](decisoes/D-208-r72-q1-calibrar-k-por-atributo-referencia-e-mitigacao-alvo.md) |
| R72-Q2 | **2A** | **O mesmo combatente** que retorna **à mesma batalha** mantém seu ID original; novo participante continua recebendo próximo ID não usado (D-206) | [D-209](decisoes/D-209-r72-q2-mesmo-combatente-mantem-id-no-retorno.md) |
| R72-Q3 | **3A** | Permitir **uma tentativa por status distinto declarado na ficha**, por alvo e execução, sem multiplicação de tentativas por quantidade de hits | [D-210](decisoes/D-210-r72-q3-uma-tentativa-por-status-distinto-alvo-execucao.md) |
| R72-Q4 | **4A** | Quando o Move for **interrompido depois de acertos válidos**, usar para cada alvo seu **último impacto efetivamente executado** e resolver status elegível se sobreviver; não aguardar impactos cancelados | [D-211](decisoes/D-211-r72-q4-status-apos-ultimo-impacto-efetivo-se-interrompido.md) |

**Exemplos não normativos:** um `x_ref=50` e `R_alvo=25%` hipotéticos implicariam `K=150` pela curva racional, **sem aprovar nenhum desses números**; o mesmo Gible de ID 2 volta à mesma batalha com ID 2, enquanto um participante verdadeiramente novo recebe próximo ID nunca usado; Poison e Paralysis hipotéticos, ambos condicionados a acerto válido, podem receber **cada um** uma tentativa por alvo sobrevivente; um Move interrompido após dois dos três impactos planejados pode realizar a tentativa de status elegível após o **último impacto efetivamente executado**, não após um terceiro inexistente.

**Preservação:** manter D-202/D-207 quanto ao teto e à ordem por alvo na execução normal; D-199 quanto à exigência de sobrevivência e dano antes de status; D-134/D-146/D-156 quanto à LUK; D-200/D-206 quanto aos IDs; D-203 quanto a **descartar completamente o odômetro no jogo principal**, sem removê-lo do código nesta atividade. Permanecem pendentes: números e validação para K, entrada/retorno como mecânica, ordem de status distintos e incompatibilidades, simultaneidade de impactos; a divergência de LUK **R60-Q2/Q3** da nota §12.13 permanece **sem resolução**. **Nenhum código, teste, asset, Move, VFX ou cena alterado; nenhum teste de gameplay executado.**

### 12.19 Rodada 73 — VIT/SPI verificáveis, ordem de status, retarget do mesmo atacante e prioridades (revisão 1.44)

> **2026-11-04.** O criador aprovou expressamente **1A, 2A, 3A e 4A**, sem observações próprias. Decisões individuais **D-212 a D-215**, consolidadas em **§54 de `docs/REGRAS_DO_JOGO.md`**. Seção aditiva e estritamente documental; D-001 preserva que o GDD não é fonte normativa para combate.

| Pergunta | Escolha | Regra aprovada | Registro |
|---|---|---|---|
| R73-Q1 | **1A** | Levantar **valores reais e verificáveis de VIT e SPI no nível 50** para propor um atributo de referência sujeito à **aprovação posterior**; nenhum valor ou amostra foi aprovado/levantado nesta rodada | [D-212](decisoes/D-212-r73-q1-levantar-vit-spi-reais-verificaveis-nivel50.md) |
| R73-Q2 | **2A** | Resolver tentativas de status distintos **na ordem explicitamente declarada na ficha do Move**, preservando uma tentativa por efeito distinto, por alvo e execução | [D-213](decisoes/D-213-r73-q2-status-ordem-declarada-ficha-move.md) |
| R73-Q3 | **3A** | Se eventos simultâneos de retarget tiverem **o mesmo atacante**, desempatar pela **ordem estável de declaração dos eventos** e por **índice estável da ocorrência da mesma declaração** | [D-214](decisoes/D-214-r73-q3-retarget-mesmo-atacante-ordem-declaracao-indice.md) |
| R73-Q4 | **4A** | Quando **dois status forem expressamente declarados incompatíveis**, resolver precedência usando **prioridade explicitada na ficha do Move**, sem inventar incompatibilidades concretas | [D-215](decisoes/D-215-r73-q4-prioridade-ficha-para-status-incompativeis.md) |

**Exemplos apenas ilustrativos:** atributos hipotéticos de nível 50 precisam de fontes verificadas antes de qualquer proposta e não são aqui apresentados como números reais; ordem declarada `Poison` depois `Paralysis` gera tentativas nessa sequência quando ambas elegíveis, sem mudar chances; eventos de retarget `A#1`, `A#2` e `B` do mesmo atacante seguem declaração/índice estáveis, sem trocar sorteio por preferência de alvo; prioridade `Efeito A > Efeito B` só valeria quando uma ficha futura declarasse **ambos incompatíveis**. Nenhum status real foi classificado como incompatível.

**Preservações e pendências:** D-201/D-204/D-208 exigem K compartilhado positivo **ainda sem valor numérico**, com referência de atributo e percentual-alvo dependentes de aprovação; D-210/D-211 mantêm limites de tentativas e resolução após impacto efetivo em interrupções; D-188/D-192 mantêm as demais ordenações de RNG, D-095 mantém empate por KO simultâneo; D-203 mantém odômetro fora do jogo principal. A divergência das escalas de LUK da reapresentação da Rodada 60 (§12.13) continua em aberto. Não se aprovam hierarquia universal de status, política de fichas omissas, algoritmo de PRNG ou dados de espécie faltantes. **Somente documentação:** nenhum código, teste, Move, ficha, asset, cena ou VFX alterado; nenhuma bateria de testes ou coleta quantitativa de VIT/SPI executada.

### 12.20 Rodada 74 — lacunas de VIT/SPI, fichas incompletas, índices de retarget e rolagens simultâneas de status (revisão 1.45)

> **2026-11-04.** Respostas expressamente aprovadas pelo criador: **1A, 2A, 3A, 4A**, sem observações adicionais. Registros individuais **D-216 a D-219**, consolidados em **§55** de `docs/REGRAS_DO_JOGO.md`. O GDD mantém função de **adendo histórico, não de fonte normativa de combate** conforme D-001. Nenhum texto de rodadas anteriores foi substituído.

| Questão | Escolha | Regra aprovada | Documento |
|---|---|---|---|
| R74-Q1 | **1A** | **Registrar lacunas de VIT/SPI no nível 50** e **não finalizar referência quantitativa sem dados necessários verificáveis**, sem impor amostra/estatística não aprovadas | [D-216](decisoes/D-216-r74-q1-lacunas-vit-spi-nivel50-sem-referencia-prematura.md) |
| R74-Q2 | **2A** | **Ficha do Move incompleta** enquanto faltarem prioridades expressas para **status declarados incompatíveis**; **não escolher vencedor automaticamente** | [D-217](decisoes/D-217-r74-q2-ficha-incompleta-sem-prioridade-incompatibilidade.md) |
| R74-Q3 | **3A** | **Índice estável** de ocorrência obtido a partir de **plano determinístico de eventos no instante da declaração do ataque**, mantido fixo até sua resolução | [D-218](decisoes/D-218-r74-q3-indice-retarget-plano-deterministico-na-declaracao.md) |
| R74-Q4 | **4A** | **Ordenar rolagens simultâneas de status pelo ID estável do alvo para consumir RNG**, sem **mudar a simultaneidade lógica dos efeitos** | [D-219](decisoes/D-219-r74-q4-status-rng-simultaneo-por-id-do-alvo.md) |

**Exemplos não normativos:** (i) se faltar SPI nível 50 verificável, registrar a ausência e não completar lacunas por suposição; (ii) ficha abstrata com A e B incompatíveis, mas sem prioridade definida, permanece incompleta sem vencedor automático; (iii) ocorrência `A#2` preserva o índice estabelecido no plano declarativo do ataque até sua resolução, sem ordenar pelo callback; (iv) se alvos hipotéticos ID 2 e 5 tiverem sorteios de status simultâneos, RNG do alvo 2 é consumido antes do 5, sem atribuir-lhe precedência lógica de aplicação.

**Relações e pendências:** a D-212 exige valores reais/verificáveis de VIT/SPI para futura proposta; a D-208 exige aprovação dos parâmetros de referência e mitigação-alvo antes de validar K compartilhado; D-213/D-215 continuam separando ordem das tentativas de prioridade de incompatibilidade; D-192/D-214 preservam ordenação do retarget com RNG exclusivo; D-210/D-211 preservam limites e condições de status; D-095 preserva empate por KO simultâneo. **Permanece não definido** desempate de rolagens simultâneas de status para **o mesmo alvo**, reação técnica a ficha incompleta, política de índices cancelados e dados numéricos de VIT/SPI. O conflito textual da Rodada 60 sobre LUK (§12.13) permanece **sem resolução**; D-203 continua excluindo odômetro do jogo principal. **Somente documentação:** nenhum código, teste, Move, VFX, asset ou cena modificado, nenhum teste de gameplay ou levantamento quantitativo executado.

### 12.21 Rodada 75 — amostragem defensiva, bloqueio de ficha, índices cancelados e RNG de status para mesmo alvo (revisão 1.46)

> **2026-11-04.** O criador aprovou expressamente **1A, 2A, 3A e 4A**, sem observações próprias. Registros individuais **D-220 a D-223**, consolidados em **§56** de `docs/REGRAS_DO_JOGO.md`. Aditivo histórico; conforme D-001, o GDD **não é fonte normativa de combate**. Preservar todas as versões anteriores.

| Pergunta | Escolha | Regra aprovada | Documento |
|---|---|---|---|
| R75-Q1 | **1A** | **Propor** amostra representativa com espécies de defesa **baixa, média e alta**, verificar **VIT/SPI nível 50** e submeter **composição da amostra à aprovação posterior**; nenhuma amostra ou valor oficial aprovado | [D-220](decisoes/D-220-r75-q1-amostra-defensiva-perfis-aprovacao.md) |
| R75-Q2 | **2A** | **Bloquear em combate** o Move cuja configuração de prioridade entre **status declarados incompatíveis** esteja incompleta, **indicando exatamente a prioridade faltante** | [D-221](decisoes/D-221-r75-q2-bloquear-move-prioridade-incompatibilidade-ausente.md) |
| R75-Q3 | **3A** | Em declaração de ataque, **preservar os índices reservados de ocorrências canceladas**; não reutilizá-los nem renumerar as demais ocorrências da mesma declaração | [D-222](decisoes/D-222-r75-q3-indices-cancelados-reservados-sem-reuso.md) |
| R75-Q4 | **4A** | Em rolagens de status **simultâneas dirigidas ao mesmo alvo**, desempatar **apenas consumo do RNG** pelo **ID do atacante**, seguido da **ordem da declaração e índice da ocorrência**, sem criar precedência lógica de efeitos | [D-223](decisoes/D-223-r75-q4-status-mesmo-alvo-rng-id-atacante-declaracao-indice.md) |

**Exemplos não normativos:** uma amostra futura pode ser proposta com perfis defensivos baixos/médios/altos, mas sem dados verificáveis do nível 50 nenhuma composição ou valor de K é homologado; Move hipotético com `Status A` e `Status B` incompatíveis sem prioridade **fica bloqueado**, com indicação da prioridade ausente; ocorrências fictícias `#1,#2,#3` não devem ser renumeradas ou reaproveitar `#2` se essa ocorrência for cancelada; para mesmo alvo fictício ID 3 e ataques simultâneos de IDs 2 e 5, consumir RNG da tentativa do atacante 2 antes da 5, **sem mudar simultaneidade lógica**.

**Relações e pendências:** D-212/D-216 exigem dados reais/verificáveis de VIT/SPI nível 50; D-208 exige aprovação do atributo de referência e da mitigação-alvo antes de validar K compartilhado (D-201/D-204). D-215/D-217 mantêm prioridade **expressa** e ficha incompleta quando faltar; não há status concretos declarados incompatíveis. D-218 mantém índice determinado na declaração; D-219 ordena RNG simultâneo entre alvos diferentes por ID do **alvo**, e D-223 resolve o empate quando **o alvo é o mesmo**. D-213 conserva ordem dos efeitos dentro da ficha, sem criar novo fluxo de RNG. D-095 mantém KO simultâneo como empate; D-203 exclui odômetro do jogo principal. Divergência histórica R60-Q2/Q3 sobre LUK (§12.13) permanece **sem conciliação**. Não escolher automaticamente amostras, UI do bloqueio, custos/ATB/Burst, estruturas do plano de eventos ou seeds/algoritmos novos. **Nenhum código, teste, Move, ficha, cena, asset ou VFX modificado; nenhum teste de gameplay realizado.**

### 12.22 Rodada 76 — amostragem VIT/SPI separada, validação pré-custo, índices condicionais e seed de status (revisão 1.47)

> **2026-11-04.** O criador aprovou expressamente **1A, 2A, 3A e 4A**, sem observações próprias. Registros individuais **D-224–D-227** consolidados em **§57** de `docs/REGRAS_DO_JOGO.md`. Este adendo preserva histórico e conflitos; D-001 mantém o GDD **não normativo para combate**. Atualização apenas documental.

| Questão | Escolha | Regra aprovada | Documento |
|---|---|---|---|
| R76-Q1 | **1A** | **Classificar os perfis defensivos de VIT e SPI separadamente**, garantindo representatividade **física, mágica e mista** na proposta de amostra; **composição e dados ainda sem aprovação** | [D-224](decisoes/D-224-r76-q1-perfis-defensivos-separados-vit-spi-amostra.md) |
| R76-Q2 | **2A** | **Validar Move incompleto antes de confirmar a ação e debitar ATB/Burst**; bloqueio não consome recursos nem oportunidade de ação, preservando indicação de prioridade ausente | [D-225](decisoes/D-225-r76-q2-validar-bloqueio-antes-confirmacao-sem-custos.md) |
| R76-Q3 | **3A** | O **plano determinístico inicial do ataque** deve **prever ocorrências condicionais possíveis e reservar índices na declaração**, preservando D-218/D-222 | [D-226](decisoes/D-226-r76-q3-reservar-indices-ocorrencias-condicionais-na-declaracao.md) |
| R76-Q4 | **4A** | Usar **fluxo RNG próprio para status**, com **seed gerada no início do combate e registrada para reprodução**, separado do RNG exclusivo de retarget | [D-227](decisoes/D-227-r76-q4-rng-exclusivo-status-seed-inicio-combate-registrada.md) |

**Exemplos apenas ilustrativos:** uma espécie de VIT alta e SPI baixa poderia representar especialização física sem ser classificada por média dos atributos; Move hipotético com prioridade de incompatibilidade ausente não confirma ação nem debita ATB/Burst; evento condicional `A#2` é indexado desde a declaração mesmo quando não acontecer, sem consumo fictício de RNG; sementes de status e retarget são geradas/registradas em fluxos separados, sem homologar números ou algoritmo PRNG.

**Limitações, decisões preservadas e conflitos:** a amostra concreta e os valores VIT/SPI nível 50 **não foram levantados** e os parâmetros de K único continuam pendentes de aprovação (D-208/D-216/D-220/D-224). A política de bloqueio de Move continua limitada à falta expressa de prioridade de status incompatíveis (D-215/D-217/D-221), sem definir visual do aviso ou mecanismo de editor. Índices fixos e sem reuso continuam regidos por D-218/D-222; novas exceções para ocorrências impossíveis de antecipar não foram aprovadas. D-219/D-223 continuam ordenando consumo RNG de status sem quebrar simultaneidade lógica (D-095). Algoritmo de RNG, formato de seed, consumo de chances 0%/100% e protocolo de replay não foram determinados. A divergência de LUK da Rodada 60 (GDD §12.13) permanece **não resolvida**. D-203 mantém odômetro fora do jogo principal. **Nenhum código, teste, ficha, Move, cena, asset ou VFX alterado; nenhum teste de gameplay executado.**

### 12.23 Fichas de Moves — Rodada M1: MP adicional e três decisões aguardando exemplos (revisão 1.48)

> **2026-11-04.** O criador abriu uma série independente, **Fichas de Moves**, com respostas: **1D, 2D, 3D e 4A** e observação expressa **“Quero exemplos de 4 moves antes de definir suas ideias”**. Conforme D-061, **somente Q4A** tem conteúdo decisório completo e foi registrada como [D-228](decisoes/D-228-m1-q4a-mp-adicional-moves-magicos-especiais.md), consolidada em **§58** de `docs/REGRAS_DO_JOGO.md`. O GDD continua não normativo para combate (D-001).

| Questão | Resposta | Estado real |
|---|---|---|
| **M1-Q1** | **1D** | **Nenhum formato de descrições aprovado**; o criador pediu quatro exemplos antes de escolher. |
| **M1-Q2** | **2D** | **Nenhuma notação de modificadores aprovada**; o criador pediu quatro exemplos antes de escolher. |
| **M1-Q3** | **3D** | **Nenhuma estrutura nova de alvos aprovada**; o criador pediu quatro exemplos antes de escolher. |
| **M1-Q4** | **4A** | **D-228 aprovada:** Moves **mágicos/especiais** gastarão **MP adicional em gameplay**, além dos recursos **ATB/Burst aplicáveis**; **cada custo individual continua pendente**. A regra **sem MP** de D-032 fica **expressamente superada somente quanto a esse ponto**. |

**Precedência, limites e exemplos:** preservar o conteúdo integral de `docs/decisoes/D-032-balanceamento-moves-ingles-e-status.md`, registrando a superação histórica do trecho “MP descartado” exclusivamente pelo novo D-228. §14.6 de `docs/REGRAS_DO_JOGO.md` já descrevia MP adicional, mas esta nova aprovação **não fixa custos, não altera outras regras de MP, nem implementa a funcionalidade**. `scripts/data/skill.gd` ainda carece de campo MP; classificação de dano físico/mágico não é automaticamente dada por `Skill.Kind` conforme D-122. Exemplos demonstrativos de quatro Moves são **somente referência visual/editorial**, sem escolher fichas definitivas, valores de MP, fórmulas, efeitos, alvos ou descrição padrão. D-119/D-123/D-210/D-213/D-215/D-225 permanecem em vigor. A divergência de LUK da Rodada 60 (§12.13) e demais decisões históricas são preservadas. **Nenhum código, teste, Move, ficha, VFX, cena ou asset alterado; nenhum teste de gameplay executado.**

### 12.24 Fichas de Moves — Tooltip textual integrada ao estilo LoL e descrição visual fora de combate (revisão 1.49)

> **2026-11-04.** Em resposta aos quatro exemplos da série M1, o criador determinou: **“Não, está péssimo, seja mais similar a como lol descreve suas habilidades, com toda descrição, dano e efeitos em blocos de texto junto com seus modificadores e o restante como custos e wind up acima, deixa a parte do efeito visual pra descrição na ficha fora de combate”**. Regra registrada em **[D-229](decisoes/D-229-moves-tooltip-texto-integrado-visual-fora-combate.md)** e consolidada em **§59 de `docs/REGRAS_DO_JOGO.md`**.

**Formato de combate aprovado:** custos e windup em cabeçalho acima; **texto completo em prosa**, com descrição, valores de dano/cura, status, modificadores, chances, duração, condições e exceções **integrados na mesma explicação**, de modo semelhante aos tooltips de League of Legends. **Não** criar cartões independentes de dano, status e modificadores. **Descrição de efeito visual** (animação, partículas, trajetória estética e dissipação) deve aparecer **somente na ficha consultada fora do combate**, não na tooltip de combate. Termos de trajetória mecanicamente relevantes continuam permitidos na explicação da habilidade quando necessários ao funcionamento.

**Exemplos não homologados:** Bite (2 ATB, windup 1,2 s, 1,3× dano, Stun 30% por 2 s), Sand Attack (1 ATB, windup 0,75 s, sem dano, Blind por 4 s, 35% de erro de ações ofensivas enquanto cego), Dragon Rage (3 ATB, windup 2 s, 1,6× dano, explosão em área condicionada ao impacto no alvo principal) e Media (2 ATB, windup 0,5 s, cura 40% HP máximo, mínimo 12 HP por aliado vivo) ilustram **como redigir**, não aprovam novas fichas, categorias de dano, custos MP ou efeitos. Preservar suas fontes atuais, D-032 e `scripts/combat/battle.gd`.

**Precedência e limites:** esta instrução posterior **resolve M1-Q1 e M1-Q2 no aspecto da apresentação da descrição e dos modificadores**, mas **não especifica o esquema técnico de dados para alvos (M1-Q3)** nem fórmulas internas ou categorias individuais; não escolher arquitetura por inferência. **D-228** mantém MP adicional para mágicos/especiais, custo individual ainda pendente, superando apenas a regra histórica sem MP de D-032. D-203 mantém o odômetro fora do jogo principal; o conflito de LUK da Rodada 60 (§12.13) permanece. **Atualização apenas documental: nenhum código, teste, VFX, ficha oficial, cena ou asset alterado; testes de gameplay não executados.**

### 12.25 Fichas de Moves — Valor numérico de dano/cura obrigatório nas tooltips (revisão 1.50)

> **2026-11-04.** O criador corrigiu os exemplos que apresentavam “1,3× dano-base”: **“TÁ PÉSSIMO VOU SABER OQ É 1X3 O DANO BASE?? É PRA TER NÚMEROS NÚMEROS NÃO FORMULAS”**. Nova decisão individual **[D-230](decisoes/D-230-moves-tooltip-dano-cura-numericos-sem-formulas.md)**, consolidada em **§60** de `docs/REGRAS_DO_JOGO.md`. A D-001 mantém o GDD não normativo para o combate.

**Apresentação aprovada:** uma tooltip de Move em combate deve informar **dano ou cura como quantidades numéricas em pontos**, sem forçar o jogador a fazer contas. **Multiplicadores e expressões de STR/MAG não substituem a quantidade real exibida.** Manter os metadados de **custos/windup acima**, a explicação integrada em texto com efeitos, valores de chance e duração e a **descrição visual apenas na ficha consultada fora de combate** (D-229).

**Exemplos verificáveis na implementação atual, não fichas definitivas:** Gible do código tem ataque 9. Com alvo neutro, sem crítico, fraqueza, buff, defesa ou diferença de passos, **Bite = 12 pontos de dano** e **Dragon Rage = 14 pontos de dano**; **Sand Attack = 0 pontos**; para **Media**, um aliado vivo com **32 HP máximo** e pelo menos 13 HP faltantes recupera **13 pontos de HP** conforme a rotina atual. Esses números **não definem um dano-base fixo oficial por Move**, não homologam o futuro sistema STR/MAG nem a natureza física/mágica dos Moves. A aprovação numérica da apresentação **não determina como obter valores quando o contexto de atacante/alvo não estiver disponível**, nem atualiza o sistema de HUD.

**Histórico:** a D-229 continua válida sobre o bloco textual e a separação de VFX, mas seus exemplos antigos apresentados unicamente como `1,3×` e `1,6×` devem ser considerados **insuficientes para a tooltip**. D-032 continua preservada como fonte histórica dos multiplicadores; D-228 mantém MP adicional para mágicos/especiais, valores individuais pendentes. D-198/D-205 preservam regras novas de arredondamento ainda não implementadas no código; M1-Q3 ainda não define modelagem técnica de alvos. Preservar o conflito histórico de LUK da Rodada 60 sem escolher prevalência. **Somente documentação:** nenhum código, ficha, teste, HUD, cena, asset ou VFX modificado; nenhum teste de gameplay executado.

### 12.26 Rodada 77 — faixas defensivas, IA, máximo de ocorrências e consumo RNG em chance extrema (revisão 1.51)

> **2026-11-04.** O criador aprovou expressamente **1A, 2A, 3A e 4A**, sem observações próprias. Registros individuais **D-231–D-234**, consolidados em **§61** de `docs/REGRAS_DO_JOGO.md`. Adendo aditivo, sem alterar documentação das séries anteriores; **D-001 mantém o GDD não normativo para combate**. Os adendos das fichas M1 (D-228–D-230) permanecem integralmente preservados.

| Questão | Escolha | Regra aprovada | Documento |
|---|---|---|---|
| R77-Q1 | **1A** | **Propor** limites de defesa **baixa, média, alta** a partir da distribuição verificável de **VIT e SPI no nível 50**, **separadamente**, e **submeter os limites à aprovação antes de classificar a amostra** | [D-231](decisoes/D-231-r77-q1-propor-faixas-vit-spi-por-distribuicao-verificavel.md) |
| R77-Q2 | **2A** | **Excluir Moves com configuração incompleta** da lista de candidatos da IA **antes da seleção tática**, **sem consumo de ação ou recursos**, restringindo-se à falta já normatizada de prioridade para status incompatíveis | [D-232](decisoes/D-232-r77-q2-ia-excluir-moves-incompletos-antes-selecao.md) |
| R77-Q3 | **3A** | Para Move com número variável de eventos condicionais, **exigir limite máximo explícito** e **reservar os índices de todas as ocorrências possíveis na declaração**; sem máximo, **plano incompleto** | [D-233](decisoes/D-233-r77-q3-limite-maximo-explicito-ocorrencias-condicionais.md) |
| R77-Q4 | **4A** | Para **chance final de status exatamente 0% ou 100%**, **determinar falha/sucesso sem consumir RNG**, preservando demais condições de aplicação | [D-234](decisoes/D-234-r77-q4-chance-status-extrema-sem-consumir-rng.md) |

**Exemplos hipotéticos, não valores aprovados:** faixas baixa/média/alta de VIT e SPI exigem dados de nível 50 **reais e verificáveis**, com limiares aprovados antes da classificação; ficha com `Status A` e `Status B` incompatíveis sem prioridade não é elegível à escolha tática da IA; limite **hipotético** de três ocorrências condicionais permite reservar três índices na declaração, sem executar eventos que não ocorrerem; chance final de Poison 100% após modificadores só tem sucesso **se o alvo continuar elegível**, sem consumir RNG.

**Compatibilidades e pendências:** D-212/D-216/D-220/D-224 preservam verificação de dados, amostra representativa física/mágica/mista e aprovação posterior; o K compartilhado de VIT/SPI continua sem número (D-201/D-204/D-208). D-215/D-217/D-221/D-225 exigem prioridade de status expressa e bloqueio sem gastar ação; D-232 filtra apenas esse caso na IA, sem criar fallback quando não houver Move válido. D-218/D-222/D-226 mantêm índices fixos e reservados, e D-233 declara plano incompleto sem máximo **sem aprovar bloqueio automático do Move por essa nova causa**. D-143/D-227/D-219/D-223 mantêm chance 0–100%, RNG exclusivo de status e sua ordem, com extremos 0%/100% sem sorteio (D-234). D-095 mantém empate por KO simultâneo e D-203 mantém odômetro fora do jogo principal. O conflito textual de escalas de LUK da Rodada 60 (§12.13) permanece **não resolvido**. A série M1 D-228–D-230 sobre MP e tooltips está **inalterada**. **Nenhum código, teste, ficha, Move, cena, asset ou VFX alterado; nenhum teste de gameplay realizado.**

### 12.27 Rodada 78 — tercis defensivos, Tackle da IA, plano incompleto e prioridades entre Moves (revisão 1.52)

> **2026-11-04.** O criador aprovou expressamente **1A, 2A, 3A e 4A**, sem observações próprias. Decisões individuais **D-236 a D-239**, consolidadas em **§62** de `docs/REGRAS_DO_JOGO.md`. Registro histórico aditivo; **D-001 mantém o GDD não normativo para combate**. Preservar a série M1 D-228–D-230 e a regra posterior D-235 sobre independência de Moves e VFX, sem reescrevê-las.

| Questão | Escolha | Regra aprovada | Documento |
|---|---|---|---|
| R78-Q1 | **1A** | **Propor faixas baixas/médias/altas por tercis**, separadamente para **VIT e SPI no nível 50**, usando **distribuições verificadas**, e **submeter limites concretos à aprovação** antes de classificar a amostra | [D-236](decisoes/D-236-r78-q1-tercis-separados-vit-spi-faixas-para-aprovacao.md) |
| R78-Q2 | **2A** | Se **nenhum Move válido da lista da IA** permanecer, **permitir considerar Tackle separadamente apenas se elegível**; caso contrário, reação permanece **pendente de outra regra** | [D-237](decisoes/D-237-r78-q2-ia-considerar-tackle-se-sem-moves-validos.md) |
| R78-Q3 | **3A** | **Bloquear confirmação** de Move com plano de ocorrências condicionais incompleto por **falta de máximo explícito**, **antes de consumir ação ou recursos**, **identificando a omissão** | [D-238](decisoes/D-238-r78-q3-bloquear-move-plano-sem-maximo-antes-custos.md) |
| R78-Q4 | **4A** | Exigir **política explícita de prioridade entre status declarados incompatíveis oriundos de Moves diferentes**, definida e **aprovada antes da resolução**, sem inferir prioridade das fichas isoladas | [D-239](decisoes/D-239-r78-q4-politica-explicita-status-incompativeis-moves-distintos.md) |

**Exemplos ilustrativos, não regras extras:** se as distribuições VIT/SPI nível 50 verificadas forem disponíveis, propor os respectivos cortes por tercis e **aguardar aprovação numérica**; se a IA não possuir Moves válidos, poderá considerar **Tackle elegível**, sem que isso determine a reação quando Tackle também não estiver disponível; Move com máximo de ocorrências condicionais ausente não confirma ação nem debita ATB/Burst/MP; quando dois Moves hipotéticos produzirem status X/Y declarados incompatíveis, **não determinar vencedor** sem política de precedência **entre Moves** previamente aprovada.

**Preservação e pendências:** D-216/D-220/D-224/D-231 continuam exigindo dados, cortes e amostra aprovados; valor numérico K permanece pendente (D-208). D-225/D-232 exigem filtragem/bloqueio sem custo, mas **não autorizam comportamento específico da IA sem Move/Tackle elegíveis**. D-218/D-222/D-226/D-233 mantêm plano inicial e índices reservados; exceder máximo não foi regulado. D-213/D-215/D-219/D-223/D-227/D-234 continuam válidas para status e RNG; a política entre Moves não tem forma nem prioridade concreta, e **nenhum par real de status foi declarado incompatível**. D-095 mantém empate por KO simultâneo, D-203 mantém odômetro fora do jogo principal, **D-235** mantém independência de Moves/VFX em relação a personagens e lados. A divergência histórica de LUK da Rodada 60 (§12.13) permanece **não resolvida**. **Somente documentação: nenhum código, teste, ficha, Move, IA, cena, asset ou VFX modificado; nenhum teste de gameplay realizado.**

### 12.28 Rodada 79 — valores empatados em tercis, reavaliação da IA, ocorrências excedentes e matriz de incompatibilidades (revisão 1.53)

> **2026-11-04.** O criador aprovou expressamente **1A, 2A, 3A e 4A**, sem observações próprias. Registros individuais **D-240 a D-243**, consolidados em **§63** de `docs/REGRAS_DO_JOGO.md`. Aditivo histórico; D-001 mantém o GDD não normativo para combate. Preservar integralmente D-228–D-230 sobre MP/tooltips e D-235 sobre independência de Moves/VFX de personagem, lado e posição.

| Questão | Escolha | Regra aprovada | Documento |
|---|---|---|---|
| R79-Q1 | **1A** | Espécies com **mesmo valor de VIT ou SPI** permanecem na **mesma faixa daquele atributo** mesmo se os tercis tiverem **quantidades diferentes** | [D-240](decisoes/D-240-r79-q1-igualdade-atributo-mesma-faixa-tercis.md) |
| R79-Q2 | **2A** | Se **não houver Move válido nem Tackle elegível**, IA **não inicia ação nem consome recursos**; **reavalia na próxima oportunidade normal** de decisão | [D-241](decisoes/D-241-r79-q2-ia-sem-opcoes-reavaliar-proxima-oportunidade.md) |
| R79-Q3 | **3A** | **Impedir ocorrência condicional excedente**, **registrar violação do plano** e **preservar eventos válidos previamente resolvidos** | [D-242](decisoes/D-242-r79-q3-ocorrencia-excedente-rejeitar-e-registrar-violacao.md) |
| R79-Q4 | **4A** | **Matriz explícita de prioridades por pares de status declarados incompatíveis vindos de Moves diferentes**, **sujeita à aprovação**, sem atribuir prioridade a pares não aprovados | [D-243](decisoes/D-243-r79-q4-matriz-pares-status-incompativeis-aprovacao.md) |

**Exemplos não normativos:** espécies hipotéticas com VIT 50 exatamente em um tercil fronteiriço devem receber **uma mesma classificação em VIT**, mantendo pendente qual faixa será homologada; a IA sem qualquer ação elegível **não inicia ação nem consome recursos** e consulta novamente na próxima oportunidade normal; Move com máximo fictício três que solicite uma quarta ocorrência deve **rejeitar a quarta** e registrar violação, sem desfazer eventos válidos resolvidos; a matriz por pares de status ainda **não contém pares concretos nem vencedores aprovados**, apesar de seu formato estar agora aprovado.

**Preservação e pendências:** D-212/D-216/D-220/D-224/D-231/D-236 mantêm verificação de valores VIT/SPI nível 50, tercis separados e aprovação de cortes e amostra antes de qualquer K (D-208); D-225/D-232/D-237 continuam controlando filtragem de Moves e consideração separada de Tackle pela IA. D-218/D-222/D-226/D-233/D-238 preservam o plano na declaração, índices reservados e máximo exigido; a nova D-242 não aprova como lidar com eventos posteriores ao excedente nem canal de log. D-213/D-215/D-219/D-223/D-227/D-234/D-239 mantêm tentativas, probabilidades e ordenação RNG, sem escolher vencedores de pares incompatíveis. D-095 mantém empate por KO simultâneo; D-203 exclui odômetro do jogo principal; D-235 mantém independência de Moves/VFX. A divergência de LUK da Rodada 60 (§12.13) continua **não resolvida**. **Somente documentação, sem editar código, testes, IA, fichas, Moves, cenas, assets ou VFX, sem testar gameplay ou levantar valores defensivos.**

### 12.29 Fichas de Moves — Rodada M2: dano, tempos, alvos, efeitos, visual e Dispel (revisão 1.54)

> **2026-11-04.** O criador aprovou expressamente **1A, 2A, 3A, 4A, 5A e 6A**; **sem observações próprias**. Registros individuais **D-244–D-249** consolidados em **§64** de `docs/REGRAS_DO_JOGO.md`. A D-061 exige registro individual e preservação histórica; o GDD permanece **não normativo para o combate** (D-001). Nenhum código ou ficha operacional foi modificado.

| Questão | Escolha | Regra aprovada | Documento |
|---|---|---|---|
| M2-Q1 | **1A** | Q1A: separar dano-base, categoria físico/mágico e escalas STR/MAG na ficha técnica; tooltip com dano numérico calculado | [D-244](decisoes/D-244-m2-q1-dano-base-categoria-escalas-separadas.md) |
| M2-Q2 | **2A** | Q2A: windup, tempo-base de deslocamento e velocidade de projétil separados; usar só modificadores aprovados | [D-245](decisoes/D-245-m2-q2-windup-trajeto-velocidade-projetil-independentes.md) |
| M2-Q3 | **3A** | Q3A: seleção Self/One/Two/All, facção ally/enemy/both e abrangência condicional dos efeitos como dimensões distintas | [D-246](decisoes/D-246-m2-q3-selecao-faccao-abrangencia-alvos-separadas.md) |
| M2-Q4 | **4A** | Q4A: cura, buffs/debuffs, status e Dispel como efeitos individuais com magnitude, condição, chance, duração e ordem aplicáveis | [D-247](decisoes/D-247-m2-q4-cura-buffs-status-dispel-efeitos-individuais.md) |
| M2-Q5 | **5A** | Q5A: descrição visual somente fora do combate, separada por preparação, movimento/emissão, impacto e dissipação quando aplicável | [D-248](decisoes/D-248-m2-q5-visual-preparo-emissao-impacto-dissipacao-ficha-fora-combate.md) |
| M2-Q6 | **6A** | Q6A: Move com Dispel deve listar expressamente efeitos removíveis e exceções aplicáveis | [D-249](decisoes/D-249-m2-q6-dispel-lista-explicita-removiveis-excecoes.md) |

**Aplicação e exemplos ilustrativos:** uma ficha de Bite pode manter dano-base/categoria/escalas em campos técnicos separados, enquanto sua tooltip apresenta **número calculado** do contexto (D-230), sem inventar fórmula. Dragon Rage pode selecionar um inimigo e só produzir dano em área após contato válido; isso é **separação de seleção e abrangência**, não revogação das regras gerais de AoE (D-007/D-032). Um Move com projétil possui campos distintos para windup e velocidade de voo, sem presumir como AGI influencia o projétil (D-119/D-133/D-078). Efeitos distintos são descritos individualmente conforme suas condições e ordem, sem importar status incompatíveis ou Dispel concreto (D-210/D-213/D-215/D-243). As descrições artísticas por **preparação, movimento/emissão, impacto e dissipação** ficam **somente fora de combate** (D-229/D-248).

**Proteções e pendências:** preservar **D-228** para MP adicional dos Moves mágicos/especiais, com custos específicos em aberto; preservar **D-229/D-230** para tooltip estilo LoL com dano/cura expressos em **pontos numéricos**, e **D-235** para independência de Moves/VFX de personagem, time, lado e coordenadas fixas. Não foi definida fórmula STR/MAG, valor numérico oficial por Move, escala de projétil por AGI, alcance concreto de Dispel, herança de seleção de alvo, cena ou visual específico. Divergência histórica de LUK na R60 (GDD §12.13) preservada; D-203 mantém odômetro fora do jogo principal. **Somente documentação: nenhum código, teste, ficha, Move, HUD, cena, asset, animação ou VFX alterado; nenhum teste de gameplay executado.**

### 12.30 Rodada 80 — limite de tercil na faixa superior, filtro IA, continuidade após excedente e abrangência da matriz (revisão 1.55)

> **2026-11-04.** O criador aprovou expressamente **1A, 2A, 3A e 4A**, sem observações adicionais. Decisões individuais **D-250–D-253**, consolidadas em **§65** de `docs/REGRAS_DO_JOGO.md`. Aditivo histórico: **D-001 mantém o GDD não normativo para o combate**. Preservar adendos anteriores, inclusive M2 (D-244–D-249), e D-235.

| Questão | Escolha | Regra aprovada | Documento |
|---|---|---|---|
| R80-Q1 | **1A** | Valor de VIT/SPI **exatamente igual a limite aprovado** recebe a **faixa superior**, sem separar espécies com o mesmo valor | [D-250](decisoes/D-250-r80-q1-valor-igual-limite-tercil-faixa-superior.md) |
| R80-Q2 | **2A** | Excluir também Moves sem máximo obrigatório de ocorrências condicionais **antes da seleção tática da IA**, **sem consumir ação ou recursos** | [D-251](decisoes/D-251-r80-q2-ia-filtrar-moves-sem-maximo-condicional.md) |
| R80-Q3 | **3A** | **Rejeitar e registrar somente a ocorrência excedente**; continuar eventos posteriores **validamente previstos** e preservar os eventos anteriores | [D-252](decisoes/D-252-r80-q3-continuar-eventos-validos-apos-excedente.md) |
| R80-Q4 | **4A** | Matriz por pares de status incompatíveis **aprovada futuramente** vale tanto para conflitos **simultâneos** entre Moves distintos quanto para conflito de **status ativo** com outro **aplicado depois por Move diferente** | [D-253](decisoes/D-253-r80-q4-matriz-incompatibilidade-simultaneos-e-ativos.md) |

**Exemplos hipotéticos, sem decisões numéricas:** limite fictício entre defesa baixa/média em 50 classifica `VIT=50` na faixa média; IA exclui Move que não declare máximo condicional e ainda segue D-237/D-241 se faltar opção elegível; excedente fictício `#4` é rejeitado e registrado, mas ocorrência posterior `#3` já planejada e válida continua, preservando resoluções anteriores; se efeitos X/Y de Moves distintos forem futuramente aprovados como incompatíveis na matriz, essa mesma precedência vale também se X estiver ativo antes da tentativa de Y. **Nenhum par X/Y ou vencedor foi aprovado**.

**Pendências e conflitos:** VIT/SPI de nível 50, tercis, limites, espécies, amostra e K permanecem não verificados/não aprovados (D-212/D-216/D-220/D-236/D-240); filtro IA limita-se às duas causas já decididas (D-232/D-251), sem mudar custos de ações válidas; faltam formato do registro de violação e limites por Move (D-233/D-242/D-252); matriz por pares segue sem entradas concretas (D-239/D-243/D-253), sem escolher remoções ou efeitos com menor prioridade. D-095 e D-203 preservados, assim como D-228–D-230, D-235 e D-244–D-249. A divergência histórica sobre LUK da Rodada 60 (§12.13) continua **sem resolução**. **Somente documentação:** nenhum código, teste, ficha, Move, IA, cena, asset ou VFX alterado; nenhum teste de gameplay executado.

### 12.31 Rodada 81 — unidade de amostra, validação completa, violação estruturada e status perdedor (revisão 1.56)

> **2026-11-04.** O criador aprovou expressamente **1A, 2A, 3A e 4A**, sem observações próprias. Registros individuais **D-254 a D-257**, consolidados em **§66** de `docs/REGRAS_DO_JOGO.md`. Adendo histórico aditivo; **D-001 mantém o GDD não normativo para combate**. Preservar a série de fichas de Moves D-228–D-230/D-244–D-249 e D-235 sem reescrever seu conteúdo.

| Questão | Escolha | Regra aprovada | Documento |
|---|---|---|---|
| R81-Q1 | **1A** | **Uma observação por espécie** para distribuição de VIT/SPI **no nível 50**, baseada em **valores oficiais de referência** e **separada dos desvios individuais ±3** | [D-254](decisoes/D-254-r81-q1-uma-especie-por-observacao-vit-spi-nivel50.md) |
| R81-Q2 | **2A** | Para Move com **múltiplas causas de bloqueio já aprovadas**, **identificar todas as omissões detectadas na mesma validação**, **sem debitar ação ou recursos** | [D-255](decisoes/D-255-r81-q2-identificar-todas-omissoes-de-bloqueio-juntas.md) |
| R81-Q3 | **3A** | **Registrar violação do plano de forma estruturada** com identificação estável de **Move, atacante, declaração, máximo aprovado e ocorrência excedente** | [D-256](decisoes/D-256-r81-q3-log-estruturado-violacao-plano-identificadores-estaveis.md) |
| R81-Q4 | **4A** | Sob prioridade por par concretamente aprovada, **eliminar status de menor prioridade**, **removendo se ativo ou impedindo sua aplicação se novo**, **sem restaurá-lo quando o vencedor terminar** | [D-257](decisoes/D-257-r81-q4-eliminar-status-perdedor-sem-restauracao.md) |

**Exemplos meramente ilustrativos:** dez indivíduos de uma espécie e um indivíduo de outra representam **uma observação de referência por espécie**, sem contaminar os tercis com variação ±3; ficha com prioridade obrigatória de status incompatíveis ausente e máximo condicional obrigatório ausente **indica as duas omissões na mesma validação**, antes de qualquer ação/custo; violação hipotética de máximo registra os campos Move/atacante/declaração/máximo/ocorrência com IDs estáveis sem executar o excedente; se status X/Y **futuramente** tiverem incompatibilidade e precedência aprovadas, o perdedor será removido/bloqueado e **não retornará** depois do vencedor. **Nenhuma entrada X/Y concreta foi aprovada.**

**Pendências e conflitos:** não foram verificados valores VIT/SPI no nível 50, dados oficiais por espécie, limites de tercis, amostra, mitigação ou K (D-208/D-216/D-220/D-236/D-250). A política de validação restringe-se às causas de bloqueio já aprovadas (D-221/D-238/D-255), sem novos erros ou interface fixada. O registro estruturado não define tecnologia nem formato de serialização (D-242/D-252/D-256). A matriz segue sem pares/precedências aprovados (D-239/D-243/D-253/D-257); permanece pendente quando conferir a incompatibilidade em relação ao RNG e como agir com entrada ausente. D-095 mantém KO simultâneo, D-203 mantém odômetro fora do jogo principal, D-235 mantém Moves e VFX independentes de personagem e lado. A divergência histórica da Rodada 60 sobre LUK (GDD §12.13) continua sem resolução. **Somente documentação:** nenhum código, teste, ficha, Move, IA, cena, HUD, asset ou VFX alterado; nenhum teste de gameplay realizado.

### 12.32 Fichas de Moves — Rodada M3: fórmula, alvos, projéteis, Dispel e abrangência de MP (revisão 1.57)

> **2026-11-04.** O criador respondeu expressamente **1A, 2D, 3A, 4A, 5A e 6D**. As alternativas D são especificadas apenas pela sua observação literal: **“Tudo q não é tackle consome MP , não existe previa de dano em seleção e não deve existir, pare de inventar coisa que eu não pedi”**. Registros **D-258–D-263**, consolidados em **§67** de `docs/REGRAS_DO_JOGO.md`. D-001 mantém o GDD não normativo para combate; adendo histórico sem implementação.

| Questão | Escolha | Regra aprovada | Decisão |
|---|---|---|---|
| M3-Q1 | **1A** | Q1A: aplicar (base + coeficiente STR/MAG × atributo) × potência antes de outros modificadores | [D-258](decisoes/D-258-m3-q1-formula-dano-base-escala-vezes-potencia.md) |
| M3-Q2 | **2D** | Q2D: não existe nem deve existir prévia de dano durante a seleção de alvos; tooltip numérica D-230 preservada | [D-259](decisoes/D-259-m3-q2-sem-previa-dano-na-selecao-alvos.md) |
| M3-Q3 | **3A** | Q3A: efeitos herdam seleção e facção padrão, salvo abrangência ou condição diferente expressamente declarada | [D-260](decisoes/D-260-m3-q3-efeitos-herdam-selecao-faccao-salvo-excecao.md) |
| M3-Q4 | **4A** | Q4A: AGI não altera automaticamente velocidade de projétil; velocidade própria do Move, exceções só expressas | [D-261](decisoes/D-261-m3-q4-agi-nao-altera-velocidade-projeteis-sem-excecao.md) |
| M3-Q5 | **5A** | Q5A: Dispel remove todos os efeitos elegíveis declarados na ficha, respeitando exceções | [D-262](decisoes/D-262-m3-q5-dispel-remove-todos-efeitos-elegiveis.md) |
| M3-Q6 | **6D** | Q6D: todo Move exceto Tackle consome MP; amplia a D-228 histórica, valores por Move pendentes | [D-263](decisoes/D-263-m3-q6-todos-moves-exceto-tackle-consomem-mp.md) |

**Delimitação e precedência:** a fórmula da D-258 define a parcela inicial ofensiva antes dos demais modificadores, preservando D-122/D-123/D-198/D-205; **não estabelece valores-base ou coeficientes oficiais**. D-259 veta **qualquer prévia de dano durante seleção de alvos**, mas não revoga a tooltip numérica e textual D-229/D-230 em seu contexto próprio. D-260 complementa a seleção/facção/abrangência de D-246 com **herança e exceções declaradas**; D-261 separa AGI de velocidade dos projéteis, preservando D-119/D-078 e exceções que venham a ser expressamente aprovadas. D-262 exige remover **todos os efeitos elegíveis que a ficha listar**, preservando exclusões da D-249; **não há Move concreto de Dispel definido**. D-263 estabelece **MP em todo Move exceto Tackle** e, neste aspecto, **supera expressamente a restrição a Moves mágicos/especiais de D-228**, preservando os registros históricos D-228/D-032. Os custos **individuais de MP não foram aprovados**, e a relação entre MP adicional e Burst pagar ação inteira (D-033/D-063) continua exigindo decisão específica; não escolher resposta tácita.

**Limitações e histórico:** D-235 permanece obrigatória para independência de Move/VFX de personagem, equipe, lado e câmera fixa. D-244–D-249 permanecem intactas. Não assumir categorias de dano, números de MP, velocidades, faixas de STR/MAG, listas concretas de Dispel ou estruturas de código. D-203 mantém odômetro fora do jogo principal; divergência histórica de LUK da R60 (GDD §12.13) permanece sem conciliação; D-243/D-257 não homologam pares de status concretos. **Somente documentação: nenhum código, ficha, teste, HUD, IA, cena, asset, animação ou VFX modificado; nenhum teste de gameplay executado.**

### 12.33 Rodada 82 — universo verificável, aviso textual, ID de excesso e matriz após chance (revisão 1.58)

> **2026-11-04.** O criador aprovou **1A, 2A, 3A e 4A**, sem observações próprias. Documentos **D-264–D-267**, consolidados em **§68** de `docs/REGRAS_DO_JOGO.md`. Registro histórico aditivo (D-061). **D-001 mantém o GDD não normativo para combate**; toda a série M3 (D-258–D-263) e as decisões anteriores permanecem intactas.

| Questão | Escolha | Regra aprovada | Documento |
|---|---|---|---|
| R82-Q1 | **1A** | Usar **todas as espécies oficialmente incluídas no universo de referência do Crawlmon** com **VIT/SPI verificáveis no nível 50**, **uma observação por espécie**, registrando lacunas; **não homologar cortes se a cobertura impedir representatividade** | [D-264](decisoes/D-264-r82-q1-universo-oficial-especies-vit-spi-verificaveis.md) |
| R82-Q2 | **2A** | Exibir **lista textual compacta com todas as omissões detectadas** na tentativa de confirmar Move bloqueado, **mantendo aberta a seleção de combate** | [D-265](decisoes/D-265-r82-q2-lista-textual-compacta-omissoes-selecao-aberta.md) |
| R82-Q3 | **3A** | **Identificador diagnóstico separado dos índices válidos** do plano, derivado da **declaração e sequência determinística das solicitações excedentes** | [D-266](decisoes/D-266-r82-q3-id-diagnostico-declaracao-sequencia-excedentes.md) |
| R82-Q4 | **4A** | Resolver **elegibilidade e chance** primeiro; **somente após sucesso efetivo** consultar a **matriz de incompatibilidade aprovada** e eliminar o status perdedor | [D-267](decisoes/D-267-r82-q4-elegibilidade-chance-antes-matriz-status.md) |

**Exemplos abstratos, não novos valores/regras:** espécie do universo oficial com VIT verificável e SPI ausente deve ter **lacuna SPI registrada**, sem fabricar número; Move hipotético com duas omissões de bloqueio exibe **lista textual compacta com ambas**, sem fechar a seleção nem cobrar recursos; duas solicitações de evento excedente sob uma mesma declaração recebem **IDs de diagnóstico distintos**, não índices válidos; status Y novo com chance hipotética de 20%, se **falhar**, não remove X ativo; se **tiver sucesso**, só uma **entrada de prioridade concretamente aprovada** poderá definir a eliminação do menor.

**Limites e preservações:** ainda não há universo de espécies auditado, valores VIT/SPI nível 50 verificados, limiar quantitativo de representatividade, tercis ou K aprovados (D-208/D-216/D-220/D-254/D-264). A HUD da seleção permanece sem modificação; D-259 **proíbe prévia de dano na seleção de alvos** e D-229/D-230 preservam a tooltip numérica em seu próprio contexto. O ID diagnóstico não cria eventos válidos (D-218/D-222/D-242/D-252/D-256/D-266). A matriz de status segue sem pares concretos ou vencedores, preservando D-239/D-243/D-253/D-257; D-234 continua evitando consumo de RNG para chances finais 0%/100% e D-095 mantém KO simultâneo. Preservados integralmente D-228–D-230, D-235, D-244–D-249 e D-258–D-263, incluindo MP obrigatório em Moves diferentes de Tackle (D-263); conflito de MP/Burst D-033/D-063 segue pendente. Divergência histórica de LUK da R60 (GDD §12.13) não foi conciliada. **Apenas documentação:** nenhum código, teste, ficha operacional, IA, Move, HUD, cena, asset ou VFX alterado; nenhum teste de gameplay executado.

### 12.34 Guard — ação defensiva de 1 ATB, quebra pelo Brick Break e barreira reservada (revisão 1.59)

> **2026-11-05.** Registro **aditivo** das regras do **Guard** pedidas e respondidas diretamente pelo criador na conversa de implementação, para que **nenhuma regra posterior as contradiga sem perceber**. Conforme **D-001**, este GDD **não é fonte normativa de combate**: a fonte são os documentos de decisão do Guard (**D-272**, `docs/decisoes/D-272-guard-escudo-de-1-atb.md`, e **D-273**, `docs/decisoes/D-273-barreira-hexagonal-reservada-para-protect.md`; os registros D-269–D-271 tratam de atributos/Natures) e a seção correspondente de `docs/REGRAS_DO_JOGO.md`.
>
> **Numeração:** o Guard foi criado localmente como D-195/D-196 e a seção 49 de `REGRAS_DO_JOGO.md`, números que colidiam com as Rodadas 68–82 do GitHub (D-192 a D-268). Por escolha do criador (2026-11-05) os registros locais foram **renumerados para D-269 a D-273** (seção 69 de `REGRAS_DO_JOGO.md`): D-269 sem escala 1–100, D-270 conversão de atributos, D-271 Natures flat, **D-272 Guard**, **D-273 barreira para Protect**. Nas citações antigas "D-195 = Guard" leia-se D-272.

**Regras aprovadas do Guard** (frases literais e respostas na decisão local do Guard):

| # | Regra | Valor / comportamento |
|---|---|---|
| G1 | Natureza | **Ação**, não buff: enquanto ativa, o personagem **não realiza outras ações** (Moves, Tackle, ITENS, Evade, passos de posição) até o Guard **expirar, receber contato ou ser quebrado**. |
| G2 | Custo | **1 ATB**; **Burst não pode pagar o Guard**. O ATB **não é devolvido** ao fim. |
| G3 | Duração | **2 segundos** (reduzida de 3 s pelo criador); **não pode ser cancelado** pelo jogador. |
| G4 | ATB durante o Guard | O ATB do personagem **pausa** enquanto o Guard durar. |
| G5 | Quem pode usar | **Jogador, aliados e inimigos** (D-021 simetria; D-235 independência de personagem/lado). A **IA** de aliados e inimigos pode usar o Guard. |
| G6 | O que interage | **Só golpes com dano**. Status de alvo único **não** é bloqueado (D-012). O Guard **não evita** o golpe e **não** é esquiva. |
| G7 | Redução de dano | **Porcentagem com arredondamento para cima**, baseada no atributo referente ao dano causado (VIT para físico, SPI para mágico). **Valor provisório:** o assistente escolheu **50%** como constante trocável até VIT/SPI oficiais existirem; **não é regra aprovada**. |
| G8 | Contato | O Guard **termina ao receber contato** (um escudo por personagem, quebrado pelo primeiro contato dele). O alvo em Guard **não sofre o recuo/cambaleio** do golpe. |
| G9 | Brick Break | **Quebra o Guard**, causa o **dano normal do ataque (sem redução)** e **dá +1 ATB ao atacante** quando quebra com sucesso. É o **Brick Break** (Quebra-Telha) que ganha essa trait. |
| G10 | Mold Break | **Habilidade futura**; **apenas registrada**, sem implementação nem efeito. |
| G11 | Hit stun global | A duração do **recuo/cambaleio do alvo** ao receber um golpe aumenta **0,30 s, globalmente** (todos os golpes, todos os personagens). |
| G12 | Interface | No bloco do **Evade**, **direita** troca para o bloco **Guard** (escudo sobre fundo azul flat em vez do verde), **esquerda** volta; com o Guard selecionado, **Espaço** executa o Guard no lugar do Evade. **Hotkey própria: Shift.** |
| G13 | Status visual | Ícone/badge **azul flat com escudo e o nome "Guard"** acima da vida de jogador, aliado e oponente, como os demais status. |
| G14 | Visual | **Escudo de verdade** (brasão de topo reto e ponta embaixo), **branco translúcido, flat, sem bordas**, **em pé na frente do personagem, voltado ao oponente**, com animação de construção; **rachaduras retas em fatias de pizza (8)** crescem durante os 2 s; ao contato ou ao expirar ele **quebra nas 8 fatias**; o texto **GUARD** (branco, Impact, sem borda) aparece letra a letra e, ao contato, é **disparado, cada letra em direção aleatória (todas as direções), sem quicar, e some em 0,5 s com fade nos últimos 0,2 s**. O personagem toca a animação **`charge`** em loop durante o Guard. Aprovado visualmente pelo criador. |
| G15 | Barreira em cúpula | **Não descartada**: o efeito de cúpula hexagonal fica **reservado para um futuro Move "Protect"**, **sem ligação a nenhum Move** hoje. |

**Conflitos e precedências com regras anteriores (resolvidos assim, para evitar contradição futura):**

1. **Burst paga a ação inteira** (D-033/D-063, §2/§5): o **Guard é exceção expressa** (G2). Não generalizar para outras ações; a pendência D-033/D-063 sobre MP × Burst permanece aberta.
2. **Quatro comandos** (§2): o Guard **não** é um quinto comando; é variante do bloco Evade (G12).
3. **Evade/Burst por esquiva** (§4, §5): o Guard **não gera** Burst nem recompensa ATB por esquiva e não participa da evasão automática (G6).
4. **Cadeia de dano** (GitHub D-193 VIT/SPI antes de DEF; D-194 mínimo 1; D-197 retornos decrescentes; D-198 arredondamento único final; D-258 fórmula ofensiva): o Guard reduz o dano em **porcentagem com arredondamento para cima** e **mínimo 1**. Como o criador pediu "arredondamento para cima" **e** a D-198 manda "arredondar uma vez ao final", e a posição do Guard dentro da cadeia **não foi definida**, **a implementação atual aplica `ceil(dano × (1 − redução))` sobre o dano final, mínimo 1**; isso é uma **escolha provisória do assistente, a confirmar** pelo criador. O **K da mitigação racional** (D-208/D-216/D-220) continua não aprovado e **não deve ser inventado** para o Guard.
5. **Recuo/knockback** de golpes e lançamento fatal: o alvo em Guard **não sofre recuo**, mas, se o golpe quebrar o Guard (G9) ou o dano restante for fatal, as regras de KO/lançamento continuam valendo como antes. Efeitos secundários de contato (por exemplo, Karate Chop −1 VEL, Mordida atordoa) **continuam aplicando** como antes (assunção do assistente, a confirmar).
6. **IA** (D-111, D-112, D-114, D-115): a chance de a IA acionar o Guard é de **25% quando um ataque é declarado contra ela** e ela tem reação Evade (**valor provisório do assistente**, `Battle.AI_GUARD_CHANCE`). Não há critério tático oficial do Guard; **não inferir pesos**.
7. **Hit stun:** o **+0,30 s** é global e **aditivo** a qualquer duração de recuo já aprovada; não substitui nenhuma duração por Move.
8. **Ataques em área / múltiplos alvos:** cada alvo tem **seu próprio escudo**, quebrado pelo **seu primeiro contato**; a relação detalhada com multi-hit continua indefinida (**pendente**).
9. **Guard indisponível** quando o personagem está **engajado, em ação própria, atordoado ou em pausa de status**; é uma **escolha do assistente a confirmar**, não regra literal do criador.
10. **Moves/VFX independentes de personagem, equipe e lado** (D-235, AGENTS §7): vale integralmente para o Guard, o Brick Break e a futura barreira Protect; **comportamento por `move_id`**, nunca por nome de personagem.

**Pendências abertas (não decididas):** valor oficial da redução (G7) e posição na cadeia de dano; se o Guard absorve ou concede ATB/Burst além do +1 ATB do Brick Break; interação do Guard com multi-hit, projéteis e ataques em área; tratamento de golpes com dano que não podem ser reduzidos; definição do Move **Protect** (custo, duração, o que bloqueia, se cobre o time); efeito e Move do **Mold Break**; quais outros Moves além do Brick Break terão a trait de quebrar o Guard; comportamento do Guard no mapa/exploração e em chefes; A divergência histórica de LUK da R60 (§12.13) **não foi tocada**.

**Estado de implementação (verificado no repositório local em 2026-11-05):** lógica, teste `tests/battle/test_d272_guard.gd`, menu, hotkey, badge e efeito visual existem **no repositório local**; parte da integração mora em arquivos compartilhados com outras sessões e **ainda não foi commitada**, portanto o Guard **não roda no `HEAD`** até esse commit. **Nada foi enviado ao GitHub.** Testado: Guard no Pancham, no Gible e espelhado (Gible contra Abra e Pancham). **Não testado:** Guard por Espaço/bloco azul e por Shift em jogo real (apenas por leitura de código), inimigo distante com escudo/texto em escala por distância, alvos de tamanhos diferentes além dos três personagens, interação com todos os Moves do catálogo.

## Variantes de Tackle com trait (D-998, 2026-11-08)

- **Tackle** é o golpe corpo a corpo básico e genérico de todos os personagens.
- Um personagem pode ter, no lugar do Tackle, uma **variante com outro nome**. O nome diferente sinaliza uma **trait**: uma regra própria daquele golpe.
- A trait pertence ao move (seu `move_id`), não ao personagem: quem tiver a variante usa a mesma trait (D-235).

| Variante | Quem tem hoje | Trait |
|---|---|---|
| Spear Thrust | Orc | Para a 7 unidades do alvo (as outras investidas param a 2,6) para acertar com a ponta da lança (D-996/D-997). |
