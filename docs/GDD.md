# CRAWLMON — Game Design Document (GDD)

> **Estado:** documento vivo de design, com decisões aprovadas e pendências explícitas.  
> **Revisão:** 0.1 — consolidação inicial, 2026-11-01.  
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
- **PENDENTE:** o comportamento exato do saldo após executar ações (desconto com preservação do restante versus outras regras); tempo de preenchimento, influência do atributo Velocidade, arredondamento visual, atualização durante menus/animações, conflitos entre ações simultâneas.

### 3.2 Recompensas instantâneas

- **APROVADO:** acertar **fraqueza**, causar **dano crítico** ou **desviar de um ataque** são eventos que podem conceder **1 ou 2 blocos normais de ATB de imediato**.
- **APROVADO:** o bônus é **individual**. Apenas o Pokémon responsável pelo acerto ou pela esquiva recebe os blocos. Isso inclui aliados e inimigos.
- **APROVADO:** recompensas não aumentam a taxa de preenchimento; são **acréscimos instantâneos de blocos**.
- **PENDENTE:** correspondência exata entre evento e +1/+2; acúmulo de fraqueza+crítico no mesmo golpe; teto e tratamento de excedentes; recompensas de golpes com múltiplos alvos; recompensas de fraqueza durante Burst.

**Exemplo ilustrativo, NÃO normativo:** um Pokémon com 2/5 pode receber +2 e passar imediatamente para 4/5. O exemplo não define a pontuação definitiva do evento.

### 3.3 Separação de Press Turn

**APROVADO como direção atual:** a economia de ações é a dos blocos individuais de ATB; referências a fraquezas e críticos de *SMT III* inspiram as decisões táticas, mas **não há sistema aprovado de ícones coletivos Press Turn, meias ações ou alternância rígida de fases da equipe**.

## 4. Evasão ativa, evasão automática e precisão (APROVADO)

Há dois mecanismos distintos. Um acerto evitado passivamente não se confunde com a ação reativa **Evade**.

| Situação | Custo conhecido | Resultado de acerto/evasão | Recompensa ATB | Burst |
| --- | --- | --- | --- | --- |
| **Evasão automática bem-sucedida** | Não foi definido custo de ação; é uma ocorrência passiva. | O golpe é evitado. | +1 ou +2, individual. | **Nunca**. |
| **Evade ativo bem-sucedido** | **3 blocos normais**. | O golpe é evitado. | +1 ou +2, individual. | **Sim, imediato**. |
| **Evade ativo malsucedido** | **3 blocos** (custo de Evade). | **O golpe acerta obrigatoriamente**, ignorando a precisão natural e impedindo a evasão automática *para esse ataque*. | Nenhum bônus por Evade. | Não. |
| **Sem evasão bem-sucedida** | Conforme regras da ação aplicável. | Resolução normal da mecânica de ataque. | Nenhum bônus por esquiva. | Não. |

**Exceção aprovada:** acerto garantido após Evade malsucedido **não ignora imunidades nem outras proteções aplicáveis**. O acerto garantido não é sinônimo de dano garantido.

**APROVADO:** as regras de evasão e as oportunidades de Burst alcançam tanto personagens aliados quanto inimigos. Para aliados controlados pela IA, **a decisão de realizar Evade ativo** é distinta do cálculo de evasão automática.

**PENDENTE:** como a IA decide quando arriscar Evade; como o jogo apresenta a janela de reação; quais ataques podem ser desviados; como se resolve a simultaneidade com invulnerabilidade, proteção, imunidades, multi-hit e ataques em área.

## 5. Burst — sexto bloco especial (APROVADO)

- O **Burst** é representado por um **bloco extra/sexto**, **independente dos cinco blocos normais de ATB**.
- Uma **esquiva ativa Evade bem-sucedida** libera **imediatamente** uma ação especial Burst, ainda que a barra normal esteja incompleta.
- Uma **evasão automática** nunca libera Burst, mesmo recebendo recompensa de ATB.
- Uma ação Burst pode: **aplicar buff a aliados**, **aplicar debuff a inimigos** ou **executar um Move escolhido com dano crítico**.
- O **crítico garantido por Burst ofensivo NÃO concede bônus adicional de ATB por ser crítico**.
- **Determinados ataques exigem Burst** como requisito de execução; a lista e o uso exato do bloco especial para esses ataques ainda não estão definidos.
- Aliados e inimigos podem participar das condições de Burst, conforme suas regras de esquiva ativa.

**PENDENTE, NÃO INFERIR:** se o Burst é sempre consumido imediatamente ou se um ataque que o exige pode guardar o sexto bloco; se um Move de Burst requer também saldo ATB comum; se a fraqueza provocada por esse Move gera recompensa independente; limites de encadeamento de Bursts; como priorizar Burst diante de outras ações prontas.

### Exemplo de sequência aprovada, sem números inventados

Ataque direcionado a um Pokémon → tentativa de Evade ativo com custo de 3 → esquiva bem-sucedida → ganho individual de 1 ou 2 blocos normais (quantia ainda por definir) **e** abertura da ação Burst imediata → escolha entre Move crítico, buff ou debuff. O crítico garantido não fornece recompensa de crítico ao ATB.

## 6. Protagonista, IA e comportamento de batalha

**APROVADO:** jogador controla diretamente o Pokémon protagonista; **companheiros são controlados pela IA**. O menu Tactic altera suas ordens e sua conduta. Inimigos decidem suas ações e podem obter recompensas individuais por criticar, explorar fraquezas ou esquivar.

**PENDENTE:** interface de seleção do protagonista, troca/controle de líder, quantidade de aliados ativos, se Tactic é instantâneo ou consome 2 ou outro número de blocos, catálogo de condutas, persistência das táticas e comportamento da IA sob Evade/Burst.

**Exemplos não aprovados:** “priorizar fraquezas”, “defender”, “economizar PP”, “focar alvo” e “suporte” podem ser considerados em perguntas futuras, mas não constituem um conjunto obrigatório.

## 7. Especificação de conteúdo ainda não definida

Sem decisão adicional, não fixar:

- **Pokémon e progressão:** espécies elegíveis, protagonista inicial, recrutamento, equipe máxima, evolução, atributos, habilidades e crescimento.
- **Moves:** Tackle genérico versus golpe homônimo da franquia; lista de quatro Moves por Pokémon; PP; status; efeitos; custos ATB; golpes de custo 5 e golpes que requerem Burst.
- **Combate 3D:** câmera, sequência de animações, timings, hitstop, interface gráfica final, modelos, rigging, VFX e arenas por bioma.
- **Dungeon 2D:** escala dos tiles, IA na exploração, geração, armadilhas, itens, progressão de andares, encontros e retorno.
- **Modos de batalha:** pausa na seleção, passagem de tempo durante animações e menus, prioridade de ações e tratamento de múltiplos comandos simultâneos.
- **Balanceamento:** bônus exatos, limites, acumulação, duração de buffs/debuffs, dano de crítico, tabela de tipos e interações especiais.
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

## 10. Rodada 1 — cinco perguntas aguardando resposta

**Status:** ABERTA — 0/5 respostas. Registrar respostas aqui somente depois de fornecidas pelo criador e atualizar as seções correspondentes.

**R1-Q1 — Consumo/armazenamento do Burst para ataques que o exigem.**  
A. O bloco Burst só pode ser gasto na janela **imediata após o Evade ativo**, e golpes que exigem Burst só podem ser selecionados nessa janela.  
B. O jogador pode gastar o bloco imediatamente ou **guardá-lo** para executar posteriormente um golpe que o exige; definir duração/limite em rodada futura.  
C. Outra regra, explicada pelo criador.

**R1-Q2 — Destino dos blocos normais após uma ação.**  
A. Deduz-se **somente o custo**, preservando os blocos restantes.  
B. A ação zera a barra ATB normal, mesmo quando custa menos do que o saldo disponível.  
C. Outra regra, explicada pelo criador.

**R1-Q3 — Relógio ATB durante escolha de comandos.**  
A. Congela a progressão de todos os ATBs enquanto o jogador escolhe FIGHT/ITENS/Tactic.  
B. O tempo e os ATBs continuam progredindo normalmente durante os menus.  
C. Outra regra, explicada pelo criador.  
*Esta pergunta não resolve a passagem do tempo durante animações de golpes.*

**R1-Q4 — Valor-base da recompensa por evento.**  
Informar separadamente **fraqueza: +1 ou +2**, **crítico normal: +1 ou +2**, **esquiva automática: +1 ou +2**, **Evade ativo bem-sucedido: +1 ou +2**. São quatro valores para uma única tabela de balanceamento. O crítico garantido de Burst continua sem recompensa por crítico.

**R1-Q5 — Acúmulo das recompensas por um mesmo golpe.**  
A. Se um golpe normal for simultaneamente crítico e super efetivo, **soma** as recompensas de ambos.  
B. Se for simultaneamente crítico e super efetivo, recebe **somente a maior recompensa**.  
C. Outra regra, explicada pelo criador.

## 11. Histórico de alterações do GDD

| Revisão | Data | Mudanças documentais | Rodada |
| --- | --- | --- | --- |
| 0.1 | 2026-11-01 | Criação inicial: decisões D-001 a D-020, auditoria documental do protótipo, pendências e perguntas R1-Q1 a R1-Q5. | Rodada 1 aberta |

> **Regra de preservação:** nas atualizações posteriores, não reescrever seções não relacionadas nem transformar hipóteses em decisões. Preservar este histórico, acrescentando entradas rastreáveis, e nunca afirmar que uma decisão foi implementada sem verificar o código e, quando cabível, executar testes.
