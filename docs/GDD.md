# CRAWLMON — Game Design Document (GDD)

> **Estado:** documento vivo de design, com decisões aprovadas e pendências explícitas.  
> **Revisão:** 0.2 — Rodada 1 consolidada, 2026-11-01.  
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

**APROVADO:** os aliados são controlados pela **inteligência artificial**, com ordens e mudanças de conduta transmitidas pelo menu **Tactic**. Os inimigos também participam da economia individual de ATB, das recompensas por desempenho e das regras aplicáveis de evasão/Burst.

**PENDENTE:** estilo dos sprites 2D, natureza procedural ou fixa das dungeons, personagens iniciais, número de integrantes, regras de recrutamento, evolução, inventário da exploração, derrota da expedição, formato e duração das arenas, transição/câmera e identidade narrativa. Nenhuma dessas escolhas é fixada por este GDD.

### Fluxo de experiência (somente encadeamento conceitual)

Explorar uma dungeon em 2D → encontrar um adversário → entrar na cena 3D → administrar ATB e escolhas reativas → resolver vitória/derrota/fuga, quando definidas → retornar ao contexto da dungeon.

**IMPLEMENTADO/OBSERVADO:** já existe uma transição básica 2D/3D no protótipo. Isso não confirma que o fluxo completo acima, inclusive fuga, recursos e consequências, esteja implementado.

## 2. Interface de batalha — quatro comandos (APROVADO)

| Comando | Intenção e comportamento aprovado | O que permanece indefinido |
| --- | --- | --- |
| **1 — FIGHT** | Apresenta **Tackle como ataque físico genérico** e **quatro Moves** do Pokémon para selecionar. Tackle não ocupa um dos quatro espaços de Move. | Potência, PP, precisão, classificação de cada Move, custo ATB individual, seleção de alvo e disponibilidade por espécie. |
| **2 — ITENS** | Acessa e permite usar consumíveis em batalha. | Catálogo de itens, seleção de alvos, custo de cada item, consumo/inventário e momento de uso. |
| **3 — Tactic** | Permite enviar ordens aos aliados e modificar como a IA deve agir conforme a situação. | Lista de táticas, granularidade de ordens, tempo de duração, custo ATB e limites de comando. |
| **4 — Evade** | Ação ativa e reativa de esquiva durante a execução de ataques; tem **custo de três blocos de ATB**. | Janela temporal, interface física/botão de reação, elegibilidade por alvo, animações e interações com golpes múltiplos/em área. |

**APROVADO:** todas as ações consomem blocos; a maioria custa **2**, o Evade custa **3**, determinados golpes fortes custam **todos os 5**, e alguns ataques também **exigem Burst**.

**PENDENTE:** especificação de custo exato por comando/Move e se a ação Burst imediata possui algum custo normal adicional além de seu bloco próprio. A afirmação “todas as ações consomem blocos” e o Burst como sexto bloco separado requerem detalhamento conjunto; não assumir gratuidade ou custo acumulado.

## 3. Sistema ATB — especificação aprovada

### 3.1 Capacidade, tempo e elegibilidade

- **APROVADO:** cada Pokémon possui sua **própria barra com capacidade de cinco blocos normais** (0–5).
- **APROVADO:** os blocos se preenchem **com a passagem do tempo**.
- **APROVADO (Opção A):** um Pokémon pode realizar uma ação **assim que tiver os blocos necessários para pagar seu custo**, sem precisar esperar completar 5/5. A antiga hipótese de só agir ao chegar a 5/5 está **superada** por esta decisão posterior.
- **APROVADO:** custo usual de muitas ações = 2 blocos; Evade ativo = 3; certos ataques fortes = 5.
- **DERIVADO:** se não houver autorização especial para dívida ou custo alternativo, um custo de 3 exige saldo de pelo menos 3. Exceções, caso desejadas, exigem aprovação.
- **APROVADO (R1-Q2 = A):** a execução de uma ação desconta **apenas o custo em blocos**, preservando o saldo restante. Exemplo: 5/5, ação de custo 2, saldo final 3/5 (antes de possíveis recompensas e preenchimento temporal).
- **APROVADO (R1-Q3 = C):** o combate **só pausa durante a escolha dos comandos de Tactic**. Ao escolher comandos de FIGHT e ITENS, o tempo não pausa e as barras ATB continuam seu preenchimento temporal. A pausa vale também para as escolhas de Tactic, não para a execução posterior de uma ordem. **PENDENTE:** detalhes técnicos de interrupção/retomada e ações simultâneas; não inventar pausas extras.
- **PENDENTE:** tempo-base de preenchimento, influência do atributo Velocidade, arredondamento visual, tratamento de ações simultâneas e excedentes do ATB.

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
- **PENDENTE:** teto e tratamento de excedentes; múltiplos alvos; recompensas por fraqueza durante Burst; efeitos de múltiplos acertos ou outros eventos simultâneos. O crítico **garantido** pelo Burst continua sem recompensa de crítico (D-019).

**Exemplo de valores aprovados:** com 2/5, um crítico normal concede +2 e eleva a barra para 4/5. Se o mesmo golpe também explorar fraqueza, o ganho total é +3, e um saldo inicial de 2/5 alcança 5/5.

### 3.3 Separação de Press Turn

**APROVADO como direção atual:** a economia de ações é a dos blocos individuais de ATB; referências a fraquezas e críticos de *SMT III* inspiram as decisões táticas, mas **não há sistema aprovado de ícones coletivos Press Turn, meias ações ou alternância rígida de fases da equipe**.

## 4. Evasão ativa, evasão automática e precisão (APROVADO)

Há dois mecanismos distintos. Um acerto evitado passivamente não se confunde com a ação reativa **Evade**.

| Situação | Custo conhecido | Resultado de acerto/evasão | Recompensa ATB | Burst |
| --- | --- | --- | --- | --- |
| **Evasão automática bem-sucedida** | Não foi definido custo de ação; é uma ocorrência passiva. | O golpe é evitado. | **+2**, individual. | **Nunca**. |
| **Evade ativo bem-sucedido** | **3 blocos normais**. | O golpe é evitado. | **+1**, individual. | **Sim, disponibilidade imediata (pode usar ou armazenar)**. |
| **Evade ativo malsucedido** | **3 blocos** (custo de Evade). | **O golpe acerta obrigatoriamente**, ignorando a precisão natural e impedindo a evasão automática *para esse ataque*. | Nenhum bônus por Evade. | Não. |
| **Sem evasão bem-sucedida** | Conforme regras da ação aplicável. | Resolução normal da mecânica de ataque. | Nenhum bônus por esquiva. | Não. |

**Exceção aprovada:** acerto garantido após Evade malsucedido **não ignora imunidades nem outras proteções aplicáveis**. O acerto garantido não é sinônimo de dano garantido.

**APROVADO:** as regras de evasão e as oportunidades de Burst alcançam tanto personagens aliados quanto inimigos. Para aliados controlados pela IA, **a decisão de realizar Evade ativo** é distinta do cálculo de evasão automática.

**PENDENTE:** como a IA decide quando arriscar Evade; como o jogo apresenta a janela de reação; quais ataques podem ser desviados; como se resolve a simultaneidade com invulnerabilidade, proteção, imunidades, multi-hit e ataques em área.

## 5. Burst — sexto bloco especial (APROVADO)

- O **Burst** é representado por um **bloco extra/sexto**, **independente dos cinco blocos normais de ATB**.
- Uma **esquiva ativa Evade bem-sucedida** disponibiliza **imediatamente** uma ação especial Burst, ainda que a barra normal esteja incompleta. **APROVADO (R1-Q1 = B):** o Pokémon pode **executar Burst na hora ou armazenar o bloco** para utilizar posteriormente, inclusive para golpes que exigem Burst. 'Imediato' designa a disponibilidade, **não obriga consumo instantâneo**.
- Uma **evasão automática** nunca libera Burst, mesmo recebendo recompensa de ATB.
- Uma ação Burst pode: **aplicar buff a aliados**, **aplicar debuff a inimigos** ou **executar um Move escolhido com dano crítico**.
- O **crítico garantido por Burst ofensivo NÃO concede bônus adicional de ATB por ser crítico**.
- **Determinados ataques exigem Burst** como requisito de execução; a lista e o uso exato do bloco especial para esses ataques ainda não estão definidos.
- Aliados e inimigos podem participar das condições de Burst, conforme suas regras de esquiva ativa.

**PENDENTE, NÃO INFERIR:** duração de armazenamento do Burst, capacidade/empilhamento, se um Move de Burst requer também saldo ATB comum, se a fraqueza provocada por esse Move gera recompensa independente, limites de encadeamento de Bursts e prioridade diante de outras ações prontas. O armazenamento foi aprovado, mas seus limites não.

### Exemplo de sequência aprovada, sem números inventados

Ataque direcionado a um Pokémon → tentativa de Evade ativo com custo de 3 → esquiva bem-sucedida → ganho individual de **+1 bloco normal** **e** disponibilização imediata de Burst → o Pokémon **pode** usá-lo agora (Move crítico, buff ou debuff) **ou armazenar** seu bloco para uso posterior. O crítico garantido não fornece recompensa de crítico ao ATB.

## 6. Protagonista, IA e comportamento de batalha

**APROVADO:** jogador controla diretamente o Pokémon protagonista; **companheiros são controlados pela IA**. O menu Tactic altera suas ordens e sua conduta. Inimigos decidem suas ações e podem obter recompensas individuais por criticar, explorar fraquezas ou esquivar.

**APROVADO (R1-Q3):** a **escolha** de ordens ou comportamentos no menu Tactic é a única ocasião aprovada de **pausa do combate**; FIGHT e ITENS não pausam.

**PENDENTE:** interface de seleção do protagonista, troca/controle de líder, quantidade de aliados ativos, custo de ATB para execução de Tactic (a pausa do menu **não define** gratuidade), catálogo de condutas, persistência das táticas e comportamento da IA sob Evade/Burst.

**Exemplos não aprovados:** “priorizar fraquezas”, “defender”, “economizar PP”, “focar alvo” e “suporte” podem ser considerados em perguntas futuras, mas não constituem um conjunto obrigatório.

## 7. Especificação de conteúdo ainda não definida

Sem decisão adicional, não fixar:

- **Pokémon e progressão:** espécies elegíveis, protagonista inicial, recrutamento, equipe máxima, evolução, atributos, habilidades e crescimento.
- **Moves:** Tackle genérico versus golpe homônimo da franquia; lista de quatro Moves por Pokémon; PP; status; efeitos; custos ATB; golpes de custo 5 e golpes que requerem Burst.
- **Combate 3D:** câmera, sequência de animações, timings, hitstop, interface gráfica final, modelos, rigging, VFX e arenas por bioma.
- **Dungeon 2D:** escala dos tiles, IA na exploração, geração, armadilhas, itens, progressão de andares, encontros e retorno.
- **Modos de batalha:** pausa **exclusiva** nas escolhas de Tactic já aprovada; detalhes da progressão de ATB durante animações, prioridade de ações e tratamento de múltiplos comandos simultâneos ainda exigem especificação técnica.
- **Balanceamento:** recompensas-base (+1 fraqueza, +2 crítico normal, +2 evasão automática, +1 Evade ativo) e soma crítico normal+fraqueza aprovadas; permanecem pendentes limites/excedentes, duração de buffs/debuffs, dano de crítico, tabela de tipos e interações especiais.
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
| D-004 | Aliados agem por IA e recebem ordens/mudanças de comportamento por Tactic. |
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

## 10.1. Rodada 2 — cinco perguntas aguardando resposta

**Status:** ABERTA — 0/5 respostas. Questões propostas; **nenhuma alternativa está aprovada**.

**R2-Q1 — Duração de um Burst armazenado.**  
A. Burst armazenado permanece disponível **até ser utilizado**, durante a batalha; não atravessa o fim da batalha.  
B. Burst armazenado **expira após um prazo**; indicar quantos segundos.  
C. Outra regra, especificada pelo criador.  
*Essa pergunta não define se é possível guardar mais de um bloco Burst.*

**R2-Q2 — Recompensas que ultrapassam a capacidade de cinco blocos.**  
A. Limitar o ATB a **5/5**; excedentes são descartados.  
B. Manter excedentes **em reserva invisível**; indicar ou definir posteriormente limite e modo de uso.  
C. Outra regra, especificada pelo criador.

**R2-Q3 — Custo de um Move executado com Burst.**  
A. Consome **somente o bloco especial Burst**, sem exigir blocos normais adicionais.  
B. Consome o **bloco Burst e também o custo ATB normal do Move** escolhido.  
C. Outra regra, especificada pelo criador.

**R2-Q4 — Custo das ordens de Tactic.**  
A. Cada ordem/comando de Tactic efetivado tem **custo fixo de 2 blocos normais**.  
B. Custos **variam conforme a ordem**; tabela será especificada futuramente.  
C. Outra regra, especificada pelo criador.  
*A pausa durante a escolha de Tactic é mantida em todas as opções.*

**R2-Q5 — Preenchimento temporal dos blocos.**  
A. A taxa de preenchimento depende do **atributo Velocidade** de cada Pokémon.  
B. Todos os Pokémon preenchem blocos **à mesma taxa básica**; Velocidade pode ter outra função a ser definida.  
C. Outra regra, especificada pelo criador.  
*Os bônus instantâneos de R1 não são multiplicadores de velocidade.*

## 11. Histórico de alterações do GDD

| Revisão | Data | Mudanças documentais | Rodada |
| --- | --- | --- | --- |
| 0.1 | 2026-11-01 | Criação inicial: decisões D-001 a D-020, auditoria documental do protótipo, pendências e perguntas R1-Q1 a R1-Q5. | Rodada 1 aberta |
| 0.2 | 2026-11-01 | Cinco respostas R1-Q1 a R1-Q5 consolidadas (D-021 a D-025): Burst armazenável, saldo residual de ATB, pausa somente em Tactic, tabela de recompensas, soma de crítico normal+fraqueza; rodada 2 aberta. Commit identificável pelo histórico Git deste arquivo. | Rodada 1 fechada / Rodada 2 aberta |

> **Regra de preservação:** nas atualizações posteriores, não reescrever seções não relacionadas nem transformar hipóteses em decisões. Preservar este histórico, acrescentando entradas rastreáveis, e nunca afirmar que uma decisão foi implementada sem verificar o código e, quando cabível, executar testes.
