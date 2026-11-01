# CRAWLMON — Game Design Document (GDD)

> **Estado:** documento vivo de design, com decisões aprovadas e pendências explícitas.  
> **Revisão:** 0.3 — Rodada 2 consolidada, 2026-11-01.  
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

**PENDENTE:** estilo dos sprites 2D, natureza procedural ou fixa das dungeons, personagens iniciais, número de integrantes, regras de recrutamento, evolução, inventário da exploração, derrota da expedição, formato e duração das arenas, transição/câmera e identidade narrativa. Nenhuma dessas escolhas é fixada por este GDD.

### Fluxo de experiência (somente encadeamento conceitual)

Explorar uma dungeon em 2D → encontrar um adversário → entrar na cena 3D → administrar ATB e escolhas reativas → resolver vitória/derrota/fuga, quando definidas → retornar ao contexto da dungeon.

**IMPLEMENTADO/OBSERVADO:** já existe uma transição básica 2D/3D no protótipo. Isso não confirma que o fluxo completo acima, inclusive fuga, recursos e consequências, esteja implementado.

## 2. Interface de batalha — quatro comandos (APROVADO)

| Comando | Intenção e comportamento aprovado | O que permanece indefinido |
| --- | --- | --- |
| **1 — FIGHT** | Apresenta **Tackle como ataque físico genérico** e **quatro Moves** do Pokémon para selecionar. Tackle não ocupa um dos quatro espaços de Move. | Potência, PP, precisão, classificação de cada Move, custo ATB individual, seleção de alvo e disponibilidade por espécie. |
| **2 — ITENS** | Acessa e permite usar consumíveis em batalha. | Catálogo de itens, seleção de alvos, custo de cada item, consumo/inventário e momento de uso. |
| **3 — Tactic** | **Orienta somente a IA dos aliados**, alterando seus padrões de comportamento. **Não envia ordens diretas** (R2-Q4). | Lista de orientações, persistência, interface e possível custo ATB da configuração — ainda não definido. |
| **4 — Evade** | Ação ativa e reativa de esquiva durante a execução de ataques; tem **custo de três blocos de ATB**. | Janela temporal, interface física/botão de reação, elegibilidade por alvo, animações e interações com golpes múltiplos/em área. |

**APROVADO:** todas as ações consomem blocos; a maioria custa **2**, o Evade custa **3**, determinados golpes fortes custam **todos os 5**, e alguns ataques também **exigem Burst**.

**APROVADO (R2-Q3 = B):** um **Move executado mediante Burst** consome **o bloco especial Burst e também os blocos normais de ATB correspondentes ao custo do Move**. Ter o bloco Burst não isenta desse custo; o Move depende de saldo normal suficiente.

**PENDENTE:** especificação de custo de cada comando/Move e dos custos das opções de Burst para buff ou debuff, além do custo de uma configuração de Tactic. Não atribuir custos não aprovados a essas opções.

## 3. Sistema ATB — especificação aprovada

### 3.1 Capacidade, tempo e elegibilidade

- **APROVADO:** cada Pokémon possui sua **própria barra com capacidade de cinco blocos normais** (0–5).
- **APROVADO:** os blocos se preenchem **com a passagem do tempo**.
- **APROVADO (R2-Q5 = A):** a **taxa de preenchimento natural** do ATB é influenciada pelo atributo **Velocidade individual de cada Pokémon**. As recompensas por ações continuam acréscimos instantâneos de blocos, sem alterar por si a taxa temporal.
- **APROVADO (Opção A):** um Pokémon pode realizar uma ação **assim que tiver os blocos necessários para pagar seu custo**, sem precisar esperar completar 5/5. A antiga hipótese de só agir ao chegar a 5/5 está **superada** por esta decisão posterior.
- **APROVADO:** custo usual de muitas ações = 2 blocos; Evade ativo = 3; certos ataques fortes = 5.
- **DERIVADO:** se não houver autorização especial para dívida ou custo alternativo, um custo de 3 exige saldo de pelo menos 3. Exceções, caso desejadas, exigem aprovação.
- **APROVADO (R1-Q2 = A):** a execução de uma ação desconta **apenas o custo em blocos**, preservando o saldo restante. Exemplo: 5/5, ação de custo 2, saldo final 3/5 (antes de possíveis recompensas e preenchimento temporal).
- **APROVADO (R1-Q3 = C):** o combate **só pausa durante a escolha dos comandos de Tactic**. Ao escolher comandos de FIGHT e ITENS, o tempo não pausa e as barras ATB continuam seu preenchimento temporal. A pausa vale também para as escolhas de Tactic, não para a execução posterior de uma ordem. **PENDENTE:** detalhes técnicos de interrupção/retomada e ações simultâneas; não inventar pausas extras.
- **PENDENTE:** tempo-base de preenchimento, fórmula/mapeamento do atributo Velocidade para a taxa temporal, arredondamento visual, tratamento de ações simultâneas e detalhes de exibição/consumo dos blocos excedentes.

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
- **Exemplo derivado, não regra de interface:** um Pokémon com 4/5 que ganha +3 (crítico normal e fraqueza) passa a contar com cinco blocos normais e **dois extras**. A forma visual de exibir e a ordem de consumo ainda não foram aprovadas.
- **PENDENTE:** possível limite de quantidade dos blocos ATB extras; prioridade de gasto entre blocos normais e extras; se o preenchimento pelo tempo gera extras quando os cinco blocos normais já estão cheios; múltiplos alvos; recompensas por fraqueza durante Burst; múltiplos acertos e outros eventos simultâneos. O crítico **garantido** pelo Burst continua sem recompensa por crítico (D-019).

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
- **APROVADO (R2-Q1 = A):** um bloco Burst armazenado **permanece disponível até ser usado na batalha atual**, sem prazo de expiração dentro dela, e **não é transferido para outra batalha**. Isso não define quantos Bursts podem ser armazenados ao mesmo tempo.
- **APROVADO (R2-Q3 = B):** executar um **Move via Burst** exige e consome **um bloco Burst e o custo normal de ATB do Move**; o bloco especial não substitui o gasto de ATB comum. A disponibilidade imediata de Burst não elimina o requisito de ATB do Move escolhido.
- Uma **evasão automática** nunca libera Burst, mesmo recebendo recompensa de ATB.
- Uma ação Burst pode: **aplicar buff a aliados**, **aplicar debuff a inimigos** ou **executar um Move escolhido com dano crítico**.
- O **crítico garantido por Burst ofensivo NÃO concede bônus adicional de ATB por ser crítico**.
- **Determinados ataques exigem Burst** como requisito de execução; a lista e o uso exato do bloco especial para esses ataques ainda não estão definidos.
- Aliados e inimigos podem participar das condições de Burst, conforme suas regras de esquiva ativa.

**PENDENTE, NÃO INFERIR:** capacidade/empilhamento de blocos Burst simultâneos, custo e pré-requisitos de buffs/debuffs usados via Burst, se a fraqueza provocada por Move Burst gera recompensa independente, limites de encadeamento de Bursts e prioridade diante de outras ações prontas. O armazenamento dura até uso ou término da batalha; a quantidade máxima armazenável continua em aberto.

### Exemplo de sequência aprovada, sem números inventados

Ataque direcionado a um Pokémon → tentativa de Evade ativo com custo de 3 → esquiva bem-sucedida → ganho individual de **+1 bloco normal** **e** disponibilização imediata de Burst → o Pokémon **pode** usá-lo agora (Move crítico, buff ou debuff) **ou armazenar** seu bloco para uso posterior. O crítico garantido não fornece recompensa de crítico ao ATB.

## 6. Protagonista, IA e comportamento de batalha

**APROVADO:** jogador controla diretamente o Pokémon protagonista; **companheiros são controlados pela IA**. **Tactic somente orienta/configura o comportamento da IA; não envia ordens diretas a aliados** (R2-Q4, substituindo a parte anterior de D-004). Inimigos decidem suas ações e podem obter recompensas individuais por criticar, explorar fraquezas ou esquivar.

**APROVADO (R1-Q3 + R2-Q4):** a **escolha de orientações de IA** dentro do menu Tactic é a única ocasião aprovada de **pausa do combate**; FIGHT e ITENS não pausam. Pausar para configurar a IA **não configura uma ordem direta ao aliado**.

**PENDENTE:** interface de seleção do protagonista, troca/controle de líder, quantidade de aliados ativos, custo ATB (se houver) da **configuração de Tactic** — a resposta R2-Q4 sobre não enviar ordens **não determina custo ou gratuidade** —, catálogo de comportamentos, persistência das orientações e atuação da IA sob Evade/Burst.

**Exemplos não aprovados:** “priorizar fraquezas”, “defender”, “economizar PP”, “focar alvo” e “suporte” podem ser considerados em perguntas futuras, mas não constituem um conjunto obrigatório.

## 7. Especificação de conteúdo ainda não definida

Sem decisão adicional, não fixar:

- **Pokémon e progressão:** espécies elegíveis, protagonista inicial, recrutamento, equipe máxima, evolução, atributos, habilidades e crescimento.
- **Moves:** Tackle genérico versus golpe homônimo da franquia; lista de quatro Moves por Pokémon; PP; status; efeitos; custos ATB; golpes de custo 5 e golpes que requerem Burst.
- **Combate 3D:** câmera, sequência de animações, timings, hitstop, interface gráfica final, modelos, rigging, VFX e arenas por bioma.
- **Dungeon 2D:** escala dos tiles, IA na exploração, geração, armadilhas, itens, progressão de andares, encontros e retorno.
- **Modos de batalha:** pausa **exclusiva** na seleção das orientações de Tactic já aprovada; detalhes de processamento e concorrência de ações/animações sem introduzir outras pausas, prioridade de ações e múltiplos comandos simultâneos ainda exigem especificação técnica.
- **Balanceamento:** recompensas-base (+1 fraqueza, +2 crítico normal, +2 evasão automática, +1 Evade ativo) e soma crítico normal+fraqueza aprovadas; **blocos ATB excedentes são preservados fora dos cinco normais, sem serem Burst**. Permanecem pendentes limite/ordem de consumo dos extras, duração de buffs/debuffs, dano de crítico, tabela de tipos e interações especiais.
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

## 10.2. Rodada 3 — cinco perguntas aguardando resposta

**Status:** ABERTA — 0/5 respostas. Nenhuma alternativa a seguir está aprovada.

**R3-Q1 — Quantos blocos Burst podem ser armazenados simultaneamente por Pokémon?**  
A. **Apenas 1**: existe somente um espaço de Burst reservado por Pokémon; outra esquiva ativa bem-sucedida não acumula Burst adicional enquanto esse espaço estiver ocupado.  
B. **Vários, sem limite fixo de quantidade** durante a batalha.  
C. **Um limite personalizado**, especificado pelo criador (número e regra desejada).  
*A duração até uso ou fim da batalha já foi aprovada e permanece inalterada.*

**R3-Q2 — Ao gastar ATB tendo blocos normais e excedentes, qual saldo é consumido primeiro?**  
A. **Extras primeiro**, preservando os cinco blocos normais enquanto houver reserva extra.  
B. **Normais primeiro**, deixando os extras para quando faltarem blocos normais.  
C. Outra regra de prioridade/combinação.  
*Exemplo: 4 normais +2 extras, ação de custo 2. A => 4 normais +0 extras; B => 2 normais +2 extras. Os blocos extras não são Burst.*

**R3-Q3 — Alterar a orientação de IA via Tactic deve consumir ATB?**  
A. **Não custa ATB**: configurar Tactic é uma operação de interface, não uma ação de combate cobrada; é uma exceção explícita à diretriz geral de que ações consomem blocos.  
B. **Custa 2 blocos ATB** do protagonista por mudança de orientação aplicada.  
C. Outro custo ou regra, especificado pelo criador.  
*Em todas as opções, Tactic **somente orienta a IA** e a seleção permanece como a única pausa de combate.*

**R3-Q4 — O preenchimento natural pode gerar blocos ATB extras quando os cinco normais já estão cheios?**  
A. **Não**: ao chegar a cinco normais, o preenchimento natural aguarda; apenas recompensas por ações geram extras.  
B. **Sim**: o preenchimento natural continua e cria extras enquanto o Pokémon ainda não gasta blocos, segundo regras de limite a especificar.  
C. Outro funcionamento.  
*Essa decisão não define a quantidade máxima dos extras, que permanecerá pendente.*

**R3-Q5 — Fraqueza explorada por um Move executado com Burst também concede ATB?**  
A. **Sim**: se o Move Burst atingir uma fraqueza, recebe o **+1 bloco por fraqueza**, mas o crítico garantido pelo Burst continua sem bônus de crítico.  
B. **Não**: um Move executado com Burst não concede recompensa ATB pela fraqueza, além de não conceder pelo crítico garantido.  
C. Outra regra, especificada pelo criador.

## 11. Histórico de alterações do GDD

| Revisão | Data | Mudanças documentais | Rodada |
| --- | --- | --- | --- |
| 0.1 | 2026-11-01 | Criação inicial: decisões D-001 a D-020, auditoria documental do protótipo, pendências e perguntas R1-Q1 a R1-Q5. | Rodada 1 aberta |
| 0.2 | 2026-11-01 | Cinco respostas R1-Q1 a R1-Q5 consolidadas (D-021 a D-025): Burst armazenável, saldo residual de ATB, pausa somente em Tactic, tabela de recompensas, soma de crítico normal+fraqueza; rodada 2 aberta. Commit identificável pelo histórico Git deste arquivo. | Rodada 1 fechada / Rodada 2 aberta |
| 0.3 | 2026-11-01 | Rodada 2 (D-026 a D-030): Burst armazenado até uso na batalha, excedentes ATB extras distintos do Burst, custo duplo Move+Burst, Tactic apenas orienta IA (substitui ordens diretas), taxa de preenchimento baseada na Velocidade; abre Rodada 3. | Rodada 2 fechada / Rodada 3 aberta |

> **Regra de preservação:** nas atualizações posteriores, não reescrever seções não relacionadas nem transformar hipóteses em decisões. Preservar este histórico, acrescentando entradas rastreáveis, e nunca afirmar que uma decisão foi implementada sem verificar o código e, quando cabível, executar testes.
