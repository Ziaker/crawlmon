# CRAWLMON — Game Design Document (GDD)

> **Estado:** documento vivo de design, com decisões aprovadas e pendências explícitas.  
> **Revisão:** 0.9 — Rodada 8 consolidada, 2026-11-01.  
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

**PENDENTE:** estilo dos sprites 2D, detalhes do algoritmo procedural de salas e corredores, interface/armazenamento de seeds e progressão dos andares, personagens iniciais, regras de recrutamento e reserva de Pokémon além dos **3 membros máximos da equipe ativa**, evolução, inventário da exploração, derrota da expedição, formato e duração das arenas, transição/câmera e identidade narrativa. Nenhuma dessas escolhas é fixada por este GDD.

### Fluxo de experiência (somente encadeamento conceitual)

Explorar uma dungeon em 2D → encontrar um adversário → entrar na cena 3D → administrar ATB e escolhas reativas → resolver vitória/derrota/fuga, quando definidas → retornar ao contexto da dungeon.

**IMPLEMENTADO/OBSERVADO:** já existe uma transição básica 2D/3D no protótipo. Isso não confirma que o fluxo completo acima, inclusive fuga, recursos e consequências, esteja implementado.

## 2. Interface de batalha — quatro comandos (APROVADO)

| Comando | Intenção e comportamento aprovado | O que permanece indefinido |
| --- | --- | --- |
| **1 — FIGHT** | Apresenta **Tackle como ataque físico genérico** e **quatro Moves** equipados. Tackle não ocupa um dos quatro espaços de Move e **custa 2 blocos ATB** (R4-Q4). Os **quatro Moves têm custo-base 2 ATB**, com exceções por Move, incluindo ataques de custo 5 ou com requisito Burst (R6-Q5). **Os quatro Moves não usam PP** (R7-Q3). | Potência, precisão, custo das exceções por Move, seleção de alvo e disponibilidade por espécie. **Não há PP no Crawlmon** (R8-Q2). |
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

**PENDENTE:** custo e propriedades das **exceções individuais de Move**, detalhes do catálogo de itens, momento de cobrança dos consumíveis e efeitos concretos de buffs/debuffs. Os custos-base de Tackle (2), Moves equipados (2, salvo exceções), ITENS (1 por uso), Evade (3), Tactic (0) e Burst já aprovados não estão pendentes.

## 3. Sistema ATB — especificação aprovada

### 3.1 Capacidade, tempo e elegibilidade

- **APROVADO:** cada Pokémon possui sua **própria barra com capacidade de cinco blocos normais** (0–5).
- **APROVADO:** os blocos se preenchem **com a passagem do tempo**.
- **APROVADO (R6-Q1 = A):** **todos os Pokémon começam cada batalha com 0/5 blocos normais de ATB**, sem vantagem inicial baseada em Velocidade; a Velocidade afeta o **preenchimento temporal posterior**, conforme R2-Q5. Essa regra vale para protagonista, aliados e inimigos. Bursts e blocos ATB extras não são transferidos da batalha anterior, conforme R2-Q1 e R5-Q1.
- **APROVADO (R2-Q5 = A):** a **taxa de preenchimento natural** do ATB é influenciada pelo atributo **Velocidade individual de cada Pokémon**. As recompensas por ações continuam acréscimos instantâneos de blocos, sem alterar por si a taxa temporal.
- **APROVADO (R7-Q2 = A):** um Pokémon com a **Velocidade de referência** leva **5 segundos para preencher naturalmente a barra de 0/5 até 5/5**. Isso equivale a uma média de **1 bloco por segundo na Velocidade de referência**, sem definir a curva, os marcos de arredondamento, o valor numérico de Velocidade de referência nem a fórmula de escala para outras Velocidades. Continuam válidas a pausa exclusiva da escolha de Tactic e a restrição de que o tempo não gere blocos extras.
- **APROVADO (R8-Q1 = A):** o **tempo de preenchimento natural é inversamente proporcional à Velocidade**: dobrar a Velocidade reduz o tempo em 50% e reduzir a Velocidade à metade dobra o tempo, a partir da Velocidade de referência. **DERIVADO, somente para Velocidade positiva:** \(T(V) = 5\,\mathrm{s} \times V_{ref}/V\), sendo \(V_{ref}\) o atributo de referência ainda a definir. **PENDENTE:** valor numérico de \(V_{ref}\), limites mínimo/máximo de taxa, tratamento de Velocidade zero/não positiva e arredondamento; nenhuma dessas escolhas é presumida.
- **APROVADO (Opção A):** um Pokémon pode realizar uma ação **assim que tiver os blocos necessários para pagar seu custo**, sem precisar esperar completar 5/5. A antiga hipótese de só agir ao chegar a 5/5 está **superada** por esta decisão posterior.
- **APROVADO:** custo usual de muitas ações = 2 blocos; Evade ativo = 3; certos ataques fortes = 5.
- **DERIVADO:** se não houver autorização especial para dívida ou custo alternativo, um custo de 3 exige saldo de pelo menos 3. Exceções, caso desejadas, exigem aprovação.
- **APROVADO (R1-Q2 = A):** a execução de uma ação desconta **apenas o custo em blocos**, preservando o saldo restante. Exemplo: 5/5, ação de custo 2, saldo final 3/5 (antes de possíveis recompensas e preenchimento temporal).
- **APROVADO (R1-Q3 = C):** o combate **só pausa durante a escolha dos comandos de Tactic**. Ao escolher comandos de FIGHT e ITENS, o tempo não pausa e as barras ATB continuam seu preenchimento temporal. A pausa aplica-se apenas à escolha das orientações de IA em Tactic, **que não envia ordens diretas**. **PENDENTE:** detalhes técnicos de interrupção/retomada e ações simultâneas; não inventar pausas extras.
- **PENDENTE:** valor numérico da Velocidade de referência e limites/condições de borda da proporcionalidade inversa já aprovada, arredondamento visual, tratamento de ações simultâneas e detalhes de layout para grandes quantidades de blocos excedentes. A prioridade de consumo foi aprovada em R3-Q2 e o formato-base de quadradinhos adicionais em R4-Q2.

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
- **APROVADO (R4-Q1 = A):** os **blocos ATB extras gerados por recompensas não têm limite fixo de armazenamento durante a batalha**. São distintos dos cinco normais e dos blocos Burst; sua persistência entre batalhas segue pendente.
- **APROVADO (R4-Q2 = A):** exibir os extras como **quadradinhos adicionais contíguos aos cinco blocos normais**, visualmente distintos dos blocos normais e do Burst. **PENDENTE:** detalhes gráficos e visualização quando houver um grande número de extras.
- **APROVADO (R5-Q1 = A):** **o estoque de blocos ATB extras é descartado no término de cada batalha**. Nenhum extra é carregado ao próximo encontro, inclusive dentro da mesma dungeon. O estado inicial dos **cinco blocos normais** da batalha seguinte permanece pendente.
- **APROVADO (R3-Q5 = B):** um **Move executado com Burst** não concede recompensa de ATB por atingir uma fraqueza, **nem pelo crítico garantido** do Burst. Essa é uma exceção às recompensas comuns de fraqueza e crítico; não altera os respectivos bônus de golpes normais.
- **APROVADO (R5-Q2 = B):** em um ataque **normal multi-alvo**, a **ação inteira** concede no máximo **uma recompensa de fraqueza (+1)** e **uma de crítico normal (+2)**, mesmo que múltiplos alvos satisfaçam os critérios. Se ocorrerem ambos, a ação gera no máximo **+3 ATB**. Não multiplicar o benefício pela quantidade de alvos.
- **APROVADO (R5-Q3 = B):** em um Move **normal com múltiplos hits contra o mesmo alvo**, a **execução** concede no máximo **uma recompensa por fraqueza e uma por crítico normal referentes àquele alvo**, independentemente do número de hits. **Interação com R5-Q2:** a limitação por alvo não autoriza a somar recompensas por vários alvos; para Moves multi-alvo, prevalece o **teto global por ação** definido em R5-Q2.
- **Exemplo derivado:** um Move normal com três hits contra dois alvos fracos, com pelo menos um crítico normal, gera no máximo **+1 fraqueza +2 crítico = +3 ATB** no total da ação, não +3 por alvo/hit. Moves via Burst continuam excluídos dessas recompensas.
- **PENDENTE:** apresentação visual de grande quantidade de extras; detalhes de eventos simultâneos, acertos anulados e interrupções. **Já definidos:** todos começam cada batalha com 0/5 ATB normal (R6-Q1), extras são descartados ao terminar a batalha (R5-Q1) e recompensas multi-alvo/multi-hit têm teto global por ação (R5-Q2/Q3).

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

**PENDENTE:** interface de seleção do protagonista, troca/controle de líder, regras de reservas/recrutamento além da equipe ativa de até três, catálogo de comportamentos, **persistência técnica da preferência de Tactic nas configurações e orientação-base da IA** e detalhes da lógica de decisão da IA sob Evade/Burst.

**Exemplos não aprovados:** “priorizar fraquezas”, “defender”, “focar alvo” e “suporte” podem ser considerados em perguntas futuras, mas não constituem um conjunto obrigatório.

## 7. Especificação de conteúdo ainda não definida

Sem decisão adicional, não fixar:

- **Pokémon e progressão:** espécies elegíveis, protagonista inicial, recrutamento, reservas e trocas (**equipe ativa de até 3 aprovada**), evolução, atributos, habilidades e crescimento.
- **Moves:** Tackle genérico versus golpe homônimo da franquia (**Tackle genérico custa 2 ATB, sem PP**); lista concreta dos quatro Moves por Pokémon, status, efeitos e **exceções ao custo-base de 2 ATB**, incluindo golpes de custo 5 e requisitos Burst. **Nenhuma ação do Crawlmon utiliza PP** (R8-Q2; complementa R7-Q3).
- **Combate 3D:** câmera, sequência de animações, timings, hitstop, interface gráfica final, modelos, rigging, VFX e arenas por bioma.
- **Dungeon 2D:** geração **procedural por exploração/andar, com salas e corredores** já aprovada (R7-Q5). Permanecem pendentes parâmetros do gerador algorítmico de salas/corredores, interface/armazenamento da seed reproduzível, revisita de andares, escala dos tiles, IA de inimigos visíveis na exploração, armadilhas, itens, progressão de andares, posicionamento e retorno. **Encontros são por contato com inimigos visíveis** (R8-Q5).
- **Modos de batalha:** pausa **exclusiva** na seleção das orientações de Tactic já aprovada; detalhes de processamento e concorrência de ações/animações sem introduzir outras pausas, prioridade de ações e múltiplos comandos simultâneos ainda exigem especificação técnica.
- **Balanceamento:** recompensas-base (+1 fraqueza, +2 crítico normal, +2 evasão automática, +1 Evade ativo) e soma crítico normal+fraqueza aprovadas; **blocos ATB excedentes são preservados fora dos cinco normais, sem serem Burst** e são **gastos antes dos blocos normais**. O preenchimento natural não cria extras. Moves Burst não geram ATB por fraqueza nem por crítico garantido. **Extras não têm teto fixo e são exibidos em quadradinhos adicionais**, conforme R4-Q1/Q2. **R5-Q1:** os extras são descartados ao final de cada batalha. **R5-Q2/Q3:** em ataques normais multi-alvo e/ou multi-hit, no máximo +1 por fraqueza e +2 por crítico normal para a ação inteira. Permanecem pendentes duração de buffs/debuffs, dano de crítico, tabela de tipos e interações especiais.
- **Distribuição/publicação:** direitos dos personagens, modelos e demais elementos de propriedade intelectual precisam ser considerados se houver distribuição pública.

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

## 10.8. Rodada 9 — cinco perguntas aguardando resposta

**Status:** ABERTA — 0/5 respostas. Nenhuma alternativa abaixo está aprovada. O tema PP não volta a ser questionado.

**R9-Q1 — Qual valor numérico da Velocidade será a referência para os 5 segundos de ATB?**  
A. **Velocidade 100** como referência de preenchimento em 5 segundos; demais Velocidades usam a proporção inversa já aprovada.  
B. **Velocidade 50** como referência de preenchimento em 5 segundos; demais Velocidades usam a proporção inversa já aprovada.  
C. Outro valor/critério, especificado pelo criador.  
*Essa decisão não escolhe limites de velocidade mínima/máxima.*

**R9-Q2 — Ao voltar para um andar já visitado na mesma exploração, o mapa deve permanecer igual?**  
A. **Sim:** layout previamente gerado permanece o mesmo na revisita durante a exploração atual, sem necessariamente restaurar inimigos e itens às posições iniciais.  
B. **Não:** a revisita gera novamente o layout procedural, podendo mudar a configuração das salas e corredores.  
C. Outra regra de revisita.  
*A reprodução por seed em novas explorações continua aprovada.*

**R9-Q3 — Como os Pokémon inimigos visíveis se comportam enquanto o jogador explora?**  
A. **Patrulham e perseguem o protagonista quando o detectam**; critérios de detecção e velocidade ainda pendentes.  
B. **Permanecem em posição até o contato com o protagonista**, sem patrulha/perseguição autônoma.  
C. Outro comportamento, especificado pelo criador.  
*O combate ainda começa por contato com um inimigo visível.*

**R9-Q4 — O que acontece com um inimigo visível após o jogador vencer seu encontro?**  
A. **É removido da exploração atual** e não reaparece no mesmo andar durante essa exploração, salvo eventos ainda não definidos.  
B. **Pode reaparecer no andar** segundo sistema de respawn; intervalo e condições ainda pendentes.  
C. Outra regra.  
*Isso não define o comportamento na derrota do jogador.*

**R9-Q5 — Como o protagonista se move na exploração 2D?**  
A. **Oito direções** (cardeais e diagonais) diretamente, mantendo o mapa 2D.  
B. **Quatro direções** (cima, baixo, esquerda, direita), sem movimento diagonal direto.  
C. Outro sistema de movimentação, especificado pelo criador.  
*Esta pergunta não fixa se o deslocamento é livre/contínuo ou baseado em turnos/tiles.*

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

> **Regra de preservação:** nas atualizações posteriores, não reescrever seções não relacionadas nem transformar hipóteses em decisões. Preservar este histórico, acrescentando entradas rastreáveis, e nunca afirmar que uma decisão foi implementada sem verificar o código e, quando cabível, executar testes.
