# Crawlmon — Regras do jogo (consolidado)

> **Atualização documental de 2026-11-02:** as decisões de combate das Rodadas 39, 40 e 41, incluindo complementos de R40-Q1, R40-Q5 e R41-Q6, estão registradas na [seção 17](#17-rodadas-39-40-e-41-decisões-de-design-aprovadas). Onde houver divergência entre o histórico abaixo e as decisões mais recentes, consultar as entradas individuais D-031 a D-060 e os conflitos identificados na seção 17. **A documentação nova não representa implementação do código.**

> **Para que serve:** este é o índice único de **todas as regras já decididas ou implementadas**, para que nenhuma seja esquecida ou quebrada por uma mudança. Ele **não substitui** o `docs/GDD.md` (soberano nas regras de design, com os IDs das rodadas) — resume e cruza as fontes.
> **Gerado em:** 2026-11-02, a partir do GDD rev. 1.27, do `PROMPT_trajeto_reposicionamento.md`, do README, do código da branch `feat/smt-moves` e do que o criador disse nesta conversa.
> **[CONVERSA 2026-11-02] O GDD está desatualizado quanto ao COMBATE e deve ser IGNORADO nele.** As linhas marcadas [GDD] nas seções de combate (3 a 9) ficam só como histórico, sem valor de regra. Para combate valem: [CONVERSA] > [PROMPT] > [CÓDIGO]/README. O GDD continua valendo para exploração, campanha, progressão e economia (seções 14).
> **Regra deste documento:** nada aqui foi inventado. Onde duas fontes se contradizem, **as duas ficam escritas** e o caso vai para a seção 12 (Conflitos). Ninguém (nem eu) escolhe um lado em silêncio.

## 0. Como ler

| Etiqueta | Significado |
|---|---|
| **[GDD Rn-Qm]** | Aprovado pelo criador no GDD, com o ID da rodada/pergunta. |
| **[PROMPT]** | Especificação escrita pelo criador em `PROMPT_trajeto_reposicionamento.md`. |
| **[CONVERSA]** | Dito pelo criador nesta conversa (2026-11-02). Vale como decisão; fica registrado com a frase original quando importa. |
| **[MEMÓRIA]** | Preferência/regra do criador guardada da conversa anterior. |
| **[CÓDIGO]** | O jogo faz isso hoje. **Não é aprovação**: pode estar certo, errado ou provisório. |
| **[CONFLITO n]** | Fontes divergem. Ver seção 12. |
| **[PENDENTE]** | Ainda não decidido. Não inventar. |

Hierarquia usada para *ler*, não para decidir: o que o criador disse por último na conversa > GDD aprovado > PROMPT > código. Quando isso muda o que o código faz, o item aparece em **Conflitos**.

---

## 1. Regras de trabalho (como mexer neste projeto)

1. **[MEMÓRIA]** Fazer exatamente o que foi pedido, nada além. Qualquer ambiguidade é **perguntada antes** de alterar código. Nunca preencher a lacuna com palpite, exemplo inventado ou "remoção sensata". Nunca atribuir ao criador frases que ele não disse.
2. **[MEMÓRIA]** Ao relatar um bug, reproduzir com o gravador de trace (`-- --trace`, `user://battle_trace.jsonl`) e confirmar que bate com as palavras do criador antes de corrigir.
3. **[PROMPT] Regra de ouro:** **lógica e visual andam numa só linha do tempo, sincronizadas.** A lógica (`battle.gd`) é a única dona do estado e do relógio de cada ataque; o visual (`battle_fx.gd`, `fx/*`) **só desenha**. Proibido o visual ter temporizador/tween próprio que decida *quando* algo acontece (acerto, chegada, interrupção, retorno). Pausa e câmera lenta valem para os dois porque só existe um relógio.
4. **[PROMPT]** Preservar: ATB, itens, Tactics, Burst, esquiva automática, crítico, fraquezas, câmera (Cinema/Tática/Impacto), HUD, efeitos e pausa do Status/Tactics. **Não reintroduzir** movimento ocioso dos personagens (removido a pedido) **nem tremor/zoom de câmera**.
5. **[PROMPT]** Os textos 3D de esquiva e de ATB foram removidos a pedido; o `miss_text` (letras "MISS!") **fica**. Não recolocar os outros.
6. **[PROMPT]** `assets/modelos/` está no `.gitignore` e não vai ao Git. O PROMPT diz para não commitar `personagens/`, `docs/` e `tools/`; **hoje `docs/GDD.md` e estes documentos estão versionados no GitHub** (o GDD já estava; `COMBATE_ARQUITETURA.md` e este foram adicionados nesta sessão). Se isso não é desejado, avisar.
7. **[PROMPT]** Mensagens de commit terminam com a linha de coautoria. Nada é enviado (push) ao GitHub sem autorização expressa do criador.
8. **[GDD §0]** Política de rodadas: cinco perguntas numeradas por rodada; nada é aprovado por omissão; contradição = preservar as duas e pedir resolução. **O GDD descreve requisitos, não afirma que estejam implementados.**
9. **[GDD R7-Q3/R8-Q2]** **Não existe PP** em nenhum ponto do jogo. Não propor PP de novo.
10. **[CONVERSA]** Arquitetura de combate: ver `docs/COMBATE_ARQUITETURA.md` (o motor decide posição e tempo; o FX desenha).

---

## 2. Visão geral

- **[GDD §1]** Dungeon crawler inspirado em *Pokémon Mystery Dungeon* (exploração) e *Shin Megami Tensei III: Nocturne* (decisão tática). Identidade: **ATB individual de cinco blocos consumidos por ações, recompensas instantâneas e Evade/Burst reativos**. Não é Press Turn.
- **Dois modos:** exploração **2D** (mapa de dungeon) e combate **3D** (arena separada, com os modelos 3D dos mesmos Pokémon).
- O protagonista é **um Pokémon controlado pelo jogador** (não um treinador). Aliados são controlados pela **IA**. Inimigos também têm ATB individual, recompensas e Evade/Burst.
- **[GDD R6-Q3, R7-Q4]** Equipe ativa: **até 3** (1 protagonista + até 2 aliados IA). Inimigos ativos por batalha: **até 3**. **[CÓDIGO]** hoje a cena de batalha tem 1 inimigo (Gible) e 2 aliados (Abra líder, Pancham).
- **[GDD R6-Q1 = A]** Todos os Pokémon começam cada batalha com **0/5** ATB normal.

---

## 3. Combate — comandos e custos

### 3.1 Os quatro comandos (**[GDD §2]**)
| Comando | Regra |
|---|---|
| **FIGHT** | Tackle (físico genérico, **fora** dos 4 espaços de Move, custa **2 ATB**) + 4 Moves equipados (**custo-base 2 ATB**, com exceções por Move: ataques de custo 5 ou que exigem Burst). Sem PP. Moves mágicos/especiais gastam **MP adicional** (ver §8). |
| **ITENS** | Cada uso de item custa **1 ATB**. Navegar no menu **não** pausa o combate. |
| **Tactic** | Só orienta a IA dos aliados; **sem ordens diretas**; **sem custo ATB** (R3-Q3). Persiste entre combates da dungeon (R5-Q5). Opção nas configurações: reiniciar ao sair da dungeon (**padrão**, R7-Q1) ou preservar (R6-Q4). Tactic escolhida prevalece integralmente sobre tendências de Nature (R16-Q5). |
| **Evade** | Ação reativa de esquiva. Custo e regras na §3.5. |

- **[GDD R2-Q3 = B]** Move via Burst consome **1 Burst + o custo ATB normal do Move**. **[GDD R5-Q4 = B]** buff/debuff via Burst custa **só 1 Burst**.
- **[CÓDIGO]** Custos hoje: ITENS 1; Evade 2; Tackle/skill = `cost` de cada skill (1, 2 ou 3); passo 1.

### 3.2 Pausa
- **[GDD R1-Q3 = C]** O combate **só pausa durante a escolha das orientações de Tactic**. FIGHT e ITENS não pausam.
- **[CÓDIGO]** Tactics **e Status** pausam o jogo inteiro (`get_tree().paused`). **[PROMPT]** lista "pausa do Status/Tactics" como algo a preservar.
- **[CONVERSA — nova regra]** **Golpes de status pausam o jogo durante a ativação**, pausando ATBs e preparações; continuam após a conclusão do efeito visual do golpe. (Ainda **não implementado**; detalhes na §13.)

---

## 4. ATB, extras e recompensas

### 4.1 Barra
- **[GDD]** Cada Pokémon tem sua barra de **5 blocos normais** que enche com o tempo. Pode agir assim que tiver os blocos do custo (não precisa de 5/5). A execução desconta **só o custo**, preservando o saldo (R1-Q2).
- **[GDD R2-Q5, R7-Q2, R8-Q1]** Taxa de enchimento depende da **Velocidade** individual: na Velocidade de referência a barra vai de 0 a 5 em **5 s** (1 bloco/s); tempo **inversamente proporcional** à Velocidade (T = 5 s × Vref / V). Valor numérico de Vref: **[PENDENTE]** (R9-Q1, R10-Q5).
- **[GDD R3-Q4]** O enchimento natural **para em 5 blocos normais** e nunca cria extras.
- **[CÓDIGO]** `tick`: `atb += speed × delta`, teto 5.0. Velocidades hoje: Abra 0,50; Pancham 0,45; Gible 0,42 (blocos/s).
- **[CÓDIGO]** O ATB do atacante fica **travado** enquanto ele prepara/executa a própria ação (`is_winding_up`).

### 4.2 Blocos extras
- **[GDD R2-Q2 = C]** O que passar de 5 vira **bloco extra**, separado dos normais e **diferente de Burst**; permite mais ações. **Sem teto** (R4-Q1). Exibidos como quadradinhos adicionais contíguos (R4-Q2). **Descartados no fim de cada batalha** (R5-Q1).
- **[GDD R3-Q2 = A]** Ao pagar um custo, gastam-se **primeiro os extras**, depois os normais.
- **[CÓDIGO]** Implementado (`extra`, `spend`, `add_atb`).

### 4.3 Recompensas instantâneas (individuais; só quem causou/esquivou)
| Evento | **[GDD R1-Q4]** | **[CÓDIGO]** |
|---|---:|---:|
| Golpe em fraqueza | **+1** | **+2** |
| Crítico normal | **+2** | **+1** |
| Esquiva automática | **+2** | **+1** |
| Evade manual bem-sucedido | **+1** | (Burst; ver §3.5) |
**[CONFLITO 4].** O README descreve os valores do código (fraqueza +2, crítico +1).
- **[GDD R1-Q5]** Crítico normal + fraqueza no mesmo golpe **somam** (+3 no GDD).
- **[GDD R5-Q2/Q3]** Multi-hit/multi-alvo: **no máximo +1 por fraqueza e +2 por crítico normal por ação inteira** (por alvo no multi-hit). **[CONVERSA]** reafirmado para AoE: "uma vez por golpe".
- **[GDD R3-Q5 = B]** Move ofensivo via Burst **não** dá ATB por fraqueza nem por crítico garantido.
- Recompensas "voam" até a HUD num relógio próprio; a lógica credita o bloco na hora (`pending_*` só controla o que a HUD mostra). **[CÓDIGO]**

---

## 5. Burst

- **[GDD §5]** Bloco especial, **independente** dos 5 normais e dos extras. Gerado por **Evade ativo bem-sucedido**, disponível na hora: pode **usar já ou guardar** (R1-Q1). Guardado até o fim da **batalha atual**, sem expirar, **não passa para outra batalha** (R2-Q1). **Vários simultâneos, sem teto** (R3-Q1). Esquiva automática **nunca** dá Burst.
- Ação Burst pode: buff em aliados, debuff em inimigos, ou Move com **crítico garantido**.
- **[CÓDIGO]** `Combatant.burst`, `BURST_MAX = 5`; `can_pay = burst > 0 or blocks ≥ custo`; `pay`: se há Burst, **gasta 1 Burst e nenhum ATB**. **[PROMPT]** manda manter o atual.
- **[CÓDIGO]** O Burst é limitado a 5 no código (`BURST_MAX`); o GDD diz "sem limite fixo".

---

## 6. Evade manual, desvio e sequência do ataque

### 6.1 Linha do tempo de um ataque (**[PROMPT]** Fase 1; **[CÓDIGO]**)
`PREPARO → TRAJETO → GOLPE → RETORNO`, tudo no relógio do `Battle`.
- **PREPARO:** `WINDUP = 1,5 s`; o ATB do atacante fica travado. Todo ataque, de qualquer lado, tem preparo e pode ser desviado (README).
- **TRAJETO:** corpo a corpo = a **corrida** até o alvo; à distância = o **voo do projétil** (teleguiado, sem trajeto no chão).
- **GOLPE:** o dano conta no **fim da fase de impacto** (corpo a corpo: no quadro de contato do clipe de animação; projétil: ao chegar). **[CÓDIGO]**
- **RETORNO:** o atacante volta ao ponto de passo com o pulo.
- Durações (**[CÓDIGO]**): corrida base por distância/`RUN_SPEED` entre 0,6 e 1,1 s, com tempos fixos por golpe rápido; voo base por distância entre 0,25 e 0,7 s; **menos 0,10 s por passo de (atacante + alvo)**, mínimo **0,25 s** (**[PROMPT]**). A duração do golpe depende do clipe de animação do modelo.

### 6.2 Quando o Evade funciona
- **[PROMPT]** O Evade manual (Espaço) só funciona **durante o TRAJETO** do ataque que mira o personagem (corrida ou voo do projétil). Apertar no PREPARO = **whiff**: "esquivou cedo demais", perde o custo e fica **vulnerável a crítico** (o golpe contra o qual apertou cedo demais é crítico). Só o Evade **manual** dispara a sequência abaixo; esquiva automática não.
- **[GDD §4]** Evade **malsucedido**: o golpe acerta obrigatoriamente (sem esquiva automática nesse ataque), mas **não ignora imunidades/proteções**. Custo descontado na ativação, sucesso ou não (R4-Q3).
- **[GDD R4-Q5]** A IA dos aliados decide sozinha quando tentar Evade (Tactic pode influenciar a prioridade).
- **[CONVERSA] Dois Evades diferentes, com custos diferentes:**
  - **Evade parado** = o personagem **não** está realizando ação que envolva deslocamento em trajeto → custa **3 ATB**.
  - **Evade em trajeto** = o personagem desvia **durante o trajeto do próprio ataque** (contra um inimigo) → custa **2 ATB**.
  - Frases do criador: *"A ideia sempre foi poder desviar durante o trajeto do próprio ataque ao custo de 2atb, eu fiz essa regra"* e *"só gasta 2atb se for durante um ataque do usuário contra um inimigo; se não estiver realizando uma ação que envolva deslocamento em trajeto, é 3atb"*.
- **[CÓDIGO — diverge, a corrigir]** Hoje o Evade custa 2 sempre e é **bloqueado** enquanto o personagem ataca (`find_evadable`/`try_evade` recusam se `is_attacking`) e enquanto engajado. Isso **contradiz** as duas regras acima (o parado deveria custar 3; o em trajeto deveria ser permitido). O comentário no código ("tiraria o corpo da corrida") era suposição, **não** regra do criador.
- **[PROMPT]** dizia "2 ATB (não 3)" para o Evade em geral: **superado** pela distinção acima.

### 6.3 Evade bem-sucedido contra corpo a corpo (**[PROMPT]** Fase 2)
1. O atacante é **interrompido onde está** (cambaleia; o ataque dele é **cancelado**, não termina a corrida).
2. Quem desviou ganha **+1 Burst** e **chega imediatamente** ao atacante interrompido, sem trajeto.
3. O primeiro golpe seguinte **não tem preparo** (`instant`) e é **golpe de graça**: o Burst paga a ação inteira (comportamento atual; o GDD R2-Q3 diz outra coisa —).
- **[MEMÓRIA — regra final do criador]** Depois de um Evade perfeito o personagem **só aparece ao lado do inimigo quando ele então ATACA em trajeto (o contra-ataque)**. Parado/sem fazer nada/sem atacar: **nunca** teleporta para lugar nenhum.
- **[MEMÓRIA]** O criador quer o **desvio visual** (o personagem some e reaparece ao lado e volta) e o texto **MISS!**; remover isso foi erro já cometido.

### 6.4 Estado engajado (**[PROMPT]**)
- Após chegar, o personagem fica junto do oponente durante a **câmera lenta do Burst** (`ENGAGE_SECONDS = 2,0 s` reais). Se agir (golpe, item), continua engajado, sem voltar e sem trajeto; ações seguintes via Burst também são imediatas. Se **não agir** até acabar a câmera lenta, **volta ao ponto original com o pulo rápido**. Também volta se o oponente morrer.
- **[CÓDIGO]** Engajado só age sobre o oponente ao lado; não pode dar passo.
- **[CÓDIGO]** Câmera lenta após Evade manual do líder: `SLOWMO_SCALE = 0,3`, até 2 s reais ou até a contra-ação do jogador.

### 6.5 Vários atacantes / alvo que saiu do lugar
- **[PROMPT]** (original) Ataques que já partiram miravam o ponto onde o alvo estava; se o alvo saiu dali (engajado) **erravam o vazio**.
- **[CONVERSA]** **Revogado:** *"remova isso dos projéteis e ataques não acertarem os alvos caso eles estiverem fora do trajeto original"*. Projéteis e ataques **seguem a posição do alvo** (teleguiados) e acertam; **não existe mais "erro no vazio"** (`void_miss` removido). **[CÓDIGO]** implementado: o atacante persegue a posição viva do alvo até o impacto.
- **[GDD §4]** Esquiva só se perde se houver esquiva (manual ou automática); dano e efeito acontecem se não houver.

### 6.6 Esquiva automática
- **[GDD §4]** Passiva, sem custo; **+2 ATB**, nunca Burst; desativada num ataque cujo alvo deu Evade cedo demais.
- **[CONVERSA]** *"reduz o desvio automático pra 10%"* → **10% por golpe, igual para todos** (`AUTO_DODGE_CHANCE`). **[CÓDIGO]** implementado. README ainda diz "igual à velocidade" (desatualizado). A recompensa no código é +1 ATB (**[CONFLITO 4]**).
- **[CÓDIGO]** Golpes de status e golpes amigáveis não são esquivados automaticamente.

### 6.7 IA de reação
- **[PROMPT]** A IA reage **dentro do trajeto**, com chance igual à Velocidade (SPD) do personagem, não sempre no primeiro quadro. O contra-ataque da IA segue as mesmas regras. **[CÓDIGO]** implementado (`_roll_ai_evade`, 25–75% do trajeto).
- **[PROMPT]** Simetria total: tudo vale para inimigos e aliados.

---

## 7. Posição, passos e dano

- **[PROMPT] Passos (Reposicionamento):** posição inteira de **−2 a +2** (0 = meio; + = à frente) para todo personagem. Um passo por comando, pode alternar livremente. **Custo 1 ATB por passo, nenhum outro efeito.** Fica no botão **Tactics** (que pausa): setas esquerda/direita; cinco marcas de posição sob o cartão de cada personagem. A IA usa os passos conforme a Tactic (`tactic_pos`).
- **Trajeto por par:** `base − 0,10 s × (posição de A + posição de T)`, mínimo **0,25 s**. Passo à frente encurta; atrás alonga. O deslocamento visual por passo acompanha a lógica (hoje `STEP_DIST = 1,5` unidades; **[PROMPT]** sugeria "p.ex. 3").
- **Dano:** **+10%** no dano **causado** por passo à frente; **−10%** no dano **recebido** por passo atrás (até 2 passos), multiplicando com fraqueza/crítico.
- **Bloqueios:** não dá passo enquanto prepara/executa o próprio ataque, enquanto há ataque em curso que o envolva (atacante ou alvo), enquanto engajado ou enquanto anda (`STEP_TIME = 0,35 s`).
- **[CÓDIGO]** O dano usa a posição de passo **do momento do impacto**.
- **Espaço (CONVERSA, Fase 2):** `Combatant.pos` é a posição autoritativa; o modelo só segue. Corpo a corpo termina a `STAND_GAP − 0,22 = 2,38` unidades do alvo no contato. Ver `COMBATE_ARQUITETURA.md`.

---

## 8. Dano, elementos, crítico, fraqueza, buffs

- **[README/CÓDIGO]** 11 elementos: Físico, Fogo, Água/Gelo, Raio, Psíquico, Veneno, Som, Terra, Vento, Luz, Trevas.
- **Fraqueza:** dano ×**1,5** (`WEAKNESS_MULT`). **Crítico:** **10%** de chance (`CRIT_CHANCE`), dano ×**2** (`CRIT_MULT`); `whiff` (Evade cedo) torna o golpe seguinte crítico. **[CÓDIGO]**
- **Dano base [CÓDIGO]:** `round(ataque × potência × fraqueza × crítico × passos)`, mínimo 1, depois o alvo aplica defesa (buff de defesa ±25% por estágio, mínimo ×0,4).
- **Sorte [GDD R11-Q5]:** influencia probabilidades de combate (crítico etc.). **[PENDENTE]** o que exatamente e fórmulas. **[CÓDIGO]** hoje o crítico é fixo em 10%.
- **Buffs/debuffs [GDD R10-Q4]:** por **estágios discretos**, não percentuais arbitrários. **[CÓDIGO]** estágios −2..+2 para ataque, defesa e velocidade, **25% por estágio** (ataque ×0,4 mín., velocidade ×0,3 mín.), zerados no fim da batalha. **[PENDENTE]** duração, acumulação e demais atributos.
- **Atributos [GDD R10–R11]:** cinco atributos inspirados em SMT III (Força, Magia, Vitalidade, Agilidade, Sorte), escala base **1–100**; Agilidade = Velocidade do ATB (atributo único); HP máx derivado de Vitalidade + nível; MP máx de Magia + nível; nível sobe atributos. **[CÓDIGO]** hoje só existem HP, ataque e velocidade por personagem (valores fixos).

---

## 9. Golpes em área (AoE) e golpes de status — **regras ditas pelo criador nesta conversa**

Registradas, **ainda não implementadas** (ver §13 para a ordem de trabalho).
1. **[CONVERSA]** **Não existe alvo principal em AoE: todos os alvos são atingidos ao mesmo tempo.**
2. **[CONVERSA]** **Todos podem desviar**, cada um por si. O desvio de um **não cancela** o golpe nem o efeito para os outros: *"pra poderem receber dano e efeito mesmo se um dos dois desviou, não ser cancelada"*.
3. **[CONVERSA]** AoE corpo a corpo: o atacante **fica parado** (como golpe lançado). Quem desvia ganha **Burst**, mas **não interrompe** o atacante nem fica engajado.
4. **[CONVERSA]** AoE de projétil: **uma única onda** que atinge todos; cada alvo é atingido **no seu próprio tempo** (por distância).
5. **[CONVERSA]** Dano: **todos os alvos levam o mesmo (100%)**. Entra no golpe **quem estava vivo** (momento exato — declaração × impacto — **[PENDENTE]**).
6. **[CONVERSA]** Recompensa de ATB do atacante por fraqueza/crítico: **uma vez por golpe** (**[GDD R5-Q2]** idem: +1 fraqueza, +2 crítico, global por ação).
7. **[CONVERSA]** AoE amigável (Media, Tarukaja) afeta a equipe toda, **incluindo o lançador**. Golpes amigáveis **não são esquiváveis**.
8. **[CONVERSA]** Debuffs de alvo único (Rakunda, Sukunda) **não são esquiváveis** ("são efeitos de status").
9. **[CONVERSA]** Quem é atingido por AoE tem o **próprio ataque interrompido** (como num golpe comum). Quem desvia não é interrompido.
10. **[CONVERSA]** Visual: **um único hit-stop** por rodada de impactos; a câmera e o aviso mostram o grupo inteiro.
11. **[CONVERSA]** **Golpes de status pausam o jogo durante a ativação**, congelando ATB e preparações; retomam após o efeito visual. (Inclui os debuffs de alvo único.)
- **[CÓDIGO]** Hoje: AoE corre até o "alvo principal"; só ele pode desviar; um desvio manual dele cancela o AoE inteiro; os demais levam 85%. O bug de fogo amigo (equipe errada) foi corrigido; AoE com alvo morto mira o próximo. **Essas regras de código divergem de 1–5.**
- **Movimentos AoE/status existentes [CÓDIGO]:** Media (cura 40% do HP máx, mín. 12, equipe), Tarukaja (+1 estágio de ataque na equipe), Rakunda (−1 defesa), Sukunda (−1 velocidade), Mabufula, Megido (projéteis em área), Hassou Tobi, Titanomachia (físicos em área).

---

## 10. Itens, IA e Tactics

- **[CÓDIGO]** Itens: **Poção** (consumível, +30 HP), **Amuleto** e **Talismã** (segurar; sem efeito ainda). Inventário inicial do grupo: 3 Poções, 1 Amuleto, 1 Talismã. O líder usa o inventário compartilhado; o inimigo tem 1 Poção. IA bebe Poção quando HP ≤ **50%** e tem 1 ATB.
- **[GDD R28-Q2]** Alguns itens segurados têm efeito passivo, outros são consumidos automaticamente (como berries). **[PENDENTE]** efeitos.
- **[GDD R34-Q5, R35-Q3]** Cada integrante da equipe ativa carrega **até 10 itens não segurados** (até 30 com três); ninguém concentra 30. Inventário cheio: escolher um item para deixar/trocar antes de recolher outro. Itens segurados fora da contagem.
- **Tactics [README/CÓDIGO]:** "agir" = **Atacar / Habilidades / Segurar**; "reagir" = **Nada / Esquivar**; mais a posição desejada. O jogador controla o líder (`party[0]`); aliados seguem as Tactics; inimigos usam **as mesmas** Tactics (Habilidades + Esquivar).
- **[GDD R16-Q3, R17, R18–R22]** Telemetria de ações para crescimento dos aliados: histórico acumulado por indivíduo; frequência por categoria (físico, mágico/especial, defesa/esquiva, suporte, item); até **2 categorias** por ação, prioridade na ficha do Move; uma execução = uma ação; registra quando a execução **efetivamente começa**; empate resolvido pela Tactic do momento da subida de nível; fora da equipe não acumula; Tactic é a influência principal e a telemetria ajusta. **[PENDENTE]** pesos/fórmulas.

---

## 11. Câmera

- **[CÓDIGO]** `battle_camera.gd`: modos **Cinema** (padrão: diagonal atrás-à-direita do grupo, olhando para a esquerda do campo, inclinação fixa 4°, FOV 80), **Tática** (vista elevada ao escolher alvo), **Impacto** (mira no ponto da ação sem dolly e sem zoom, depois volta ao Cinema), **Status** (enquadramento do personagem, FOV 50). **Sem zoom, sem tremor, sem rolagem animada**; só linhas de velocidade em golpes fortes e pós-processo de impacto.
- **[CONVERSA]** *"regras originalmente definidas de se assemelhar a forma que Kill la Kill IF trata o movimento de câmera estão mal implementadas, **o inimigo devia estar SEMPRE visível na câmera**."*
- **[PENDENTE — não há documento dessas regras no repositório]** Como o inimigo deve ficar visível (todos os inimigos? o alvo? margem para HUD?), se o zoom/dolly passa a ser permitido, e em quais momentos o inimigo saiu de quadro.

---

## 12. Conflitos

**Resolvidos por ordem do criador (GDD ignorado no combate):** ATB inicial (3 no código), enchimento do ATB, recompensas de ATB (fraqueza +2, crítico +1, esquiva automática +1), Burst paga a ação inteira (e `BURST_MAX = 5`), custos por skill (1, 2 ou 3; 7 skills por personagem), pausa (Tactics e Status), quantidade de inimigos. **Valem os valores do código/README/PROMPT** descritos nas seções 3–8.

**Resolvidos por fala do criador:**
- Esquiva automática: **10% fixo** (README ainda diz "igual à velocidade": desatualizado).
- Alvo que saiu do lugar: o golpe **acerta** (o "erro no vazio" do PROMPT foi revogado).
- Custo do Evade: **parado 3 ATB; em trajeto (no próprio ataque) 2 ATB**.

**Ainda divergem do código (precisam ser implementadas):**
| # | Tema | Regra do criador | Código hoje |
|---|---|---|---|
| A | Evade parado | custa 3 ATB | custa 2 |
| B | Evade em trajeto do próprio ataque | permitido, 2 ATB | bloqueado |
| C | AoE | sem alvo principal, todos ao mesmo tempo, desvio individual, desvio de um não cancela os outros, dano 100%, ATB do atacante uma vez por golpe, atacante parado, onda única que chega em tempos diferentes | corre até um "alvo principal"; só ele desvia; o desvio dele cancela tudo; os outros levam 85% |
| D | Golpes de status | pausam o jogo na ativação (ATB e preparações parados; seguem após o efeito visual) | não pausam |
| E | Câmera | o inimigo sempre visível (estilo Kill la Kill IF) | enquadramento fixo; o inimigo pode sair de quadro |

---

## 13. Ordem de trabalho acordada e pendências de resposta

**Já feito (Fases 0–2 + auditorias):** linha do tempo única; posições autoritativas no motor; planejamento e cinemática no motor; hit-stop sincronizado; testes (`tests/battle`); correção do fogo amigo do AoE; amigáveis não esquiváveis.

**Pedido do criador e ainda não implementado** (aguardando as respostas abaixo, para não inventar):
1. Regras de AoE da §9 (itens 1–10) e pausa dos golpes de status (item 11).
2. Evade durante o próprio trajeto (§6.2) e o custo correspondente.
3. Câmera: inimigo sempre visível (§11).
4. Fase 3 (testes de mecânica/sincronia): só depois das acima.

**Perguntas ainda abertas:**
- Evade: o custo fora de ataque é 3 (conversa) ou 2 (PROMPT)? Evade durante o próprio trajeto **interrompe o próprio ataque** ou o corpo continua?
- AoE: "quem estava vivo" é na declaração ou no impacto? Recompensa de ATB com alvos fracos e não fracos: soma a regra global (+1/+2 por ação)?
- Pausa de status: a partir de quando (efeito aplicado ou preparo)? Pausa também a câmera/efeitos de outros ataques ou só a lógica? Debuffs de alvo único também pausam?
- Câmera: qual a regra concreta (todos os inimigos? o alvo? margem de HUD?), pode haver zoom/dolly, em que momentos o inimigo some.

---

## 14. Exploração 2D e campanha (GDD; aprovados)

### 14.1 Mapa e movimento
- **[GDD R7-Q5, R8-Q3/Q4]** Mapas **gerados proceduralmente por exploração/andar**, com salas e corredores; **seed reutilizável** reproduz o mesmo layout (mesma seed + regras + versão do gerador); formas, posições e conexões algorítmicas.
- **[GDD R9-Q2, R36-Q3]** Ao **revisitar um andar** na mesma exploração, o layout **não muda**; itens já coletados e eventos concluídos **mantêm o estado**; inimigos derrotados **continuam removidos** (R9-Q4). Sem respawn ao subir/descer escadas.
- **[GDD R9-Q5, R23-Q1]** Movimento **contínuo e livre nas 4 direções cardeais**, sem diagonal direta.
- **[GDD R32-Q4]** O mapa do andar é **revelado progressivamente**. **[CÓDIGO]** névoa de guerra com raio de visão 7,5 tiles; o explorado fica na memória e sobrevive às batalhas.
- **[CÓDIGO]** Geração: 7–11 salas (4×4 a 9×7), 4–6 inimigos, 2–3 NPCs; tile de 48 px; o layout fica em cache no `GameState`.

### 14.2 Inimigos no mapa
- **[GDD R8-Q5, R9-Q3]** Inimigos **visíveis** no mapa; **patrulham** e **perseguem** após detectar; **o contato inicia o combate 3D** (não a mera detecção).
- **[CÓDIGO]** Patrulha 42 px/s, perseguição 105 px/s; detecção por visão a 6,5 tiles (precisa de linha de visão), audição a 3 tiles, perde o rastro a 9 tiles; contato a 26 px; desiste após 4 s; raio de patrulha 4 tiles; **graça pós-batalha de 1,25 s**. Jogador 180 px/s.
- **[GDD R9-Q4]** Inimigo derrotado é removido do andar nesta exploração.

### 14.3 Dungeon, campanha e desfechos
- **[GDD R23-Q2, R24-Q1]** Concluir uma dungeon = chegar ao **último andar e vencer o chefe**; avança-se de andar pela **escada/saída sem precisar matar todos**. Progressão entre andares **sequencial** (R34-Q3). Quantidade de andares **varia** entre expedições (R33-Q3). Chefe pode variar entre expedições (R34-Q4). Chefes: inimigos mais difíceis dentro das regras usuais, podem vir com apoio, máximo 3 inimigos ativos (R29-Q4, R30-Q3). **Missões/eventos secundários nunca impedem o acesso ao chefe** (R36-Q2).
- **[GDD R25-Q1, R34-Q1, R35-Q5]** Campanha que **desbloqueia dungeons** por conquistas/objetivos; histórias relativamente independentes por dungeon, com variação procedural por expedição.
- **[GDD R26-Q4, R28-Q5]** Vencer o chefe encerra a expedição e volta à campanha; a recompensa principal é o **avanço/desbloqueio**; recompensas materiais são opcionais. **[GDD R29-Q3, R30-Q4]** Dungeons concluídas podem ser **rejogadas** com recompensas.
- **[GDD R23-Q3, R33-Q1]** **Derrota definitiva** (todos os ativos incapacitados) **encerra a exploração**. A queda só do protagonista **não** é derrota enquanto aliados lutarem sob IA (R31-Q2); se os aliados vencerem, ele volta com **recuperação mínima** (R32-Q1). Em derrota/retirada: **XP e níveis preservados** (R32-Q3), **Pokémon recrutados continuam do jogador** (R24-Q5, R36-Q4), **itens obtidos na expedição e não segurados são perdidos** (R25-Q4, R31-Q1); segurados são mantidos.
- **[GDD R30-Q1]** Retirada voluntária permitida (não equivale a derrota nem a fuga).
- **[GDD R27-Q1, R28-Q3, R35-Q4]** Pode-se **tentar fugir de combates comuns**; fuga bem-sucedida **volta ao local do encontro e imobiliza o inimigo por 3 s**; **chefes não permitem fuga**. **[PENDENTE]** condições, falha, interface.
- **[GDD R27-Q3, R28-Q4, R36-Q5]** Dungeons com **biomas mistos** que alteram inimigos/eventos/recompensas; cada dungeon tem espécies características. **[GDD R29-Q5]** Dificuldade cresce nos andares avançados e nas dungeons novas.
- **[GDD R29-Q2, R30-Q2]** Eventos narrativos oferecem escolhas, com consequências **principalmente na expedição atual**. **[GDD R26-Q5, R33-Q4]** Salas secretas: opcionais, reveladas por pistas/mapas/NPCs/eventos.
- **[GDD R30-Q5, R24-Q3, R25-Q2]** Recrutado entra na equipe ativa se houver vaga (máx. 3); senão vai para a **reserva**. Troca ativa↔reserva é **provisoriamente** permitida na exploração (um hub virá depois). **[GDD R26-Q1/Q2, R27-Q2]** O jogador **escolhe o protagonista** entre iniciais e **começa sozinho**; forma a equipe por recrutamento.

### 14.4 Recrutamento
- **[GDD R23-Q4, R24-Q2, R35-Q2]** Exige **interação voluntária explícita** (nunca automático por aproximação). Pokémon **especiais** exigem uma tarefa/evento antes (R32-Q5). Hostis normais seguem iniciando combate. Candidatos especiais são identificados no mapa (R26-Q2).

### 14.5 Progressão, XP e economia
- **[GDD R26-Q3, R31-Q3]** Todos os **ativos que participaram** de uma batalha vencida recebem XP, mesmo sem dar o golpe final; reservas **não** recebem XP das vitórias, mas podem progredir por treinamento/serviços fora das expedições (R33-Q2).
- **[GDD R11-Q4, R12-Q5, R13-Q4/Q5, R14-Q4]** Subir de nível: o **protagonista** recebe **1 ponto por nível** e **é obrigado a distribuí-lo** na hora; **aliados** crescem automaticamente por curvas da espécie, influenciadas por **Tactic e ações executadas**, e por Natures. Evolução de espécie: o jogador escolhe **quando** (R25-Q3).
- **[GDD R27-Q4]** O nível/progressão é a fonte principal de novos Moves; mestres, HMs/TMs (**só para combate por enquanto**, R24-Q4) e outras fontes também (R23-Q5).
- **[GDD R27-Q5, R28-Q1, R29-Q1]** Recompensas de batalha: **moedas, recursos, itens**; moedas compram itens/recursos de NPCs e lojas, que existem dentro das dungeons e fora delas. **[R33-Q5 REJEITADA]** recursos materiais genéricos/crafting **não estão definidos**.

### 14.6 MP, HP e descanso
- **[GDD R11-Q3, R12-Q1/Q2/Q3, R13-Q1/Q2/Q3, R14-Q1/Q2/Q3, R15–R17]** Existe **MP** separado: Moves mágicos/especiais gastam MP **além** de ATB/Burst; custo-base comum com exceções; MP máx = Magia + nível; MP e HP **persistem entre combates da mesma dungeon**; MP é restaurado ao máximo no **início de cada exploração** e nos **pontos de descanso** (que também recuperam HP, quantidade pendente — R32-Q2); MP descontado na ativação (R14-Q1).
- **Recuperação por ATB cheio [GDD R14-Q2, R15, R16, R17-Q5]:** com ATB normal 5/5, **25% do MP máximo a cada 3 s consecutivos**, arredondado para baixo; o contador zera ao sair de 5/5 e fica zerado com MP cheio; **pausa durante o menu Tactic**.
- **[CÓDIGO]** Hoje o jogo mostra `MP N/D`: MP **não** existe ainda.

### 14.7 Natures
- **[GDD R14-Q5, R15-Q4/Q5, R16-Q4, R17-Q4, R18-Q4/Q5, R19-Q4/Q5, R20-Q4/Q5, R21-Q4/Q5, R22-Q4/Q5]** Natures modificam atributos-base (bônus e penalidades flexíveis; podem ser neutras), influenciam crescimento e tendências táticas. Sorteadas na geração de recrutáveis aleatórios, do protagonista (**de novo no início de cada exploração**, preservando os pontos distribuídos e a proporção de HP/MP, arredondando para baixo, mínimo de HP positivo) e de Pokémon de evento. Atributos finais ficam em **1–100**. A Tactic escolhida **prevalece** sobre Natures no comportamento da IA.

---

## 15. Dados implementados hoje (somente observação do código)

| Personagem | HP | Ataque | Velocidade | Fraquezas | Skills (custo ATB) |
|---|---:|---:|---:|---|---|
| Abra (líder) | 32 | 12 | 0,50 | Trevas, Som | Confusão 2, Raio Psíquico 3, Onda de Choque 2, Teleporte Rápido 1, Media 2, Sukunda 1, Megido 3 |
| Pancham | 45 | 10 | 0,45 | Psíquico, Vento | Soco Rápido 2, Golpe de Caratê 2, Quebra de Telha 3, Provocação 1, Tarukaja 2, Hassou Tobi 3 |
| Gible (inimigo) | 38 | 9 | 0,42 | Água/Gelo | Mordida 1, Tiro de Areia 2, Fúria do Dragão 3, Investida Subterrânea 2, Rakunda 1, Mabufula 2, Titanomachia 3 |

- Fora do combate: modelos `TEAM_DISTANCE = 30` entre as equipes; escala de modelo 2,5 (inimigos ×1,8); posições do grupo fixas na arena.
- Tipo de golpe: corpo a corpo (corre), projétil (voa; "no chão" rola pelo piso), lançado (acerta de onde está), status (sem dano). Cada golpe tem seu id (`move_id`) para efeitos e tempos próprios.

---

## 16. Como manter este documento

- Toda decisão nova do criador entra aqui **no mesmo dia**, com a etiqueta e, quando possível, a frase literal.
- Toda mudança de código que altere uma regra da §3–§9 atualiza a tabela de conflitos da §12.
- Antes de mexer em combate, ler as seções 3 a 9 e 12.

---

## 17. Rodadas 39, 40 e 41 — decisões de design aprovadas

> **Fonte vigente para o combate:** decisões expressas pelo criador nas Rodadas 39–41 e respectivos complementos. **Não é relatório de implementação.** O GDD permanece ignorado como fonte de combate (D-001). Os parágrafos anteriores foram preservados como histórico, inclusive quando há divergências.

### 17.1 Matriz de decisões

| Decisão | Alternativa | Regra aprovada |
|---|---|---|
| [R39-Q1](decisoes/D-031-r39-q1-atb-inicial.md) | 1A | Barra ATB começa em 3/5. Uma ação pode começar quando o personagem possui ATB suficiente para pagar seu custo. |
| [R39-Q2](decisoes/D-032-r39-q2-moves-hotkeys.md) | 2A | Disponibilizar até oito Moves; quatro hotkeys e Tackle em comando separado. |
| [R39-Q3](decisoes/D-033-r39-q3-burst-pagamento.md) | 3A | Uma unidade de Burst paga integralmente uma ação; limite de cinco unidades de Burst. |
| [R39-Q4](decisoes/D-034-r39-q4-evade-janela.md) | 4A | Evade manual só opera durante golpe corpo a corpo ou voo de projétil; fora da janela, apertar o botão não produz efeito. Custa 3 ATB parado ou 2 ATB durante o próprio trajeto de ataque. |
| [R39-Q5](decisoes/D-035-r39-q5-ataque-continua.md) | 5B | O ataque próprio não é cancelado após o Evade perfeito aplicável; o golpe extra não começa antes de terminar o ataque original. |
| [R39-Q6](decisoes/D-036-r39-q6-aoe-individual.md) | 6A | Preservar D-007 a D-013: nenhum alvo principal; potência integral por alvo; Evade independente e sem cancelar impactos dos demais. |
| [R39-Q7](decisoes/D-037-r39-q7-aoe-alvos-declaracao.md) | 7A | A lista de alvos participantes do AoE é determinada pelos alvos vivos na declaração do Move. |
| [R39-Q8](decisoes/D-038-r39-q8-status-pausa.md) | 8A | A pausa começa na ativação do efeito de status; as outras ações congelam enquanto o FX é executado; retomam ao fim. |
| [R39-Q9](decisoes/D-039-r39-q9-camera-inimigos.md) | 9A | Todos os inimigos devem permanecer visíveis na câmera, inclusive durante momentos cinematográficos. |
| [R39-Q10](decisoes/D-040-r39-q10-fase2-arquitetura.md) | 10B | Aprovação da arquitetura reintegrada da Fase 2; não aprova indistintamente mudanças mecânicas não autorizadas. |
| [R40-Q1](decisoes/D-041-r40-q1-fim-do-golpe.md) | 1A | A observação posterior esclarece o término: golpe efetuado e animação do golpe concluída, antes do pulo/teleporte de volta à posição original. Não equiparar automaticamente esse término ao instante de dano se a animação ainda não acabou. |
| [R40-Q2](decisoes/D-042-r40-q2-contra-ataque-dois-segundos.md) | 2B | A escolha do golpe extra deve acontecer durante os dois segundos reais de câmera lenta após Evade perfeito. |
| [R40-Q3](decisoes/D-043-r40-q3-contra-ataque-manual.md) | 3A | O jogador escolhe manualmente o Move do golpe extra. A restrição de escolher só depois do término foi complementada pela R41-Q2B, que admite seleção antecipada, mas não execução antecipada. |
| [R40-Q4](decisoes/D-044-r40-q4-perseguicao-corrida.md) | 4B | A perseguição do alvo ocorre durante a corrida. Ao começar o golpe físico, sua trajetória deixa de acompanhar continuamente o alvo. |
| [R40-Q5](decisoes/D-045-r40-q5-recuo-visual.md) | 5B | Todo hit recebido provoca recuo visual, independentemente de o personagem estar ou não atacando; esse recuo não muda a posição lógica. Não restringir a ataques interrompidos ou personagens em movimento. |
| [R40-Q6](decisoes/D-046-r40-q6-contato-motor.md) | 6A | O contato espacial entre atacante e alvo é determinado exatamente pelo motor. |
| [R40-Q7](decisoes/D-047-r40-q7-projetil-guiado.md) | 7A | Determinar o alvo do projétil na declaração e persegui-lo durante o voo. |
| [R40-Q8](decisoes/D-048-r40-q8-atb-aoe-unico.md) | 8A | Em cada Move AoE, conceder no máximo uma recompensa de fraqueza e uma de crítico por ação, quando pelo menos um alvo satisfizer a condição respectiva; não multiplicar pelo número de alvos. |
| [R40-Q9](decisoes/D-049-r40-q9-hitstop-onda.md) | 9A | Uma onda AoE de projéteis causa um único hit-stop quando atinge o primeiro alvo; os impactos seguintes não repetem o hit-stop. |
| [R40-Q10](decisoes/D-050-r40-q10-camera-zoom.md) | 10A | Zoom e deslocamento da câmera são autorizados para manter todos os inimigos visíveis; tremor permanece proibido. |
| [R41-Q1](decisoes/D-051-r41-q1-contra-ataque-fila.md) | 1B | A seleção manual dentro da janela de dois segundos reserva o golpe extra, que executará após terminar a animação original, mesmo que a janela de seleção já tenha encerrado. |
| [R41-Q2](decisoes/D-052-r41-q2-selecao-antecipada.md) | 2B | O Move extra pode ser escolhido durante o ataque original; fica na fila e não executa até o ataque original terminar. |
| [R41-Q3](decisoes/D-053-r41-q3-custo-contra-ataque.md) | 3A | O golpe extra respeita o custo normal do Move escolhido: gasta uma unidade de Burst disponível ou ATB suficiente. |
| [R41-Q4](decisoes/D-054-r41-q4-contato-no-impacto.md) | 4A | Durante a animação do golpe, não corrigir continuamente a trajetória. Somente no instante do impacto, corrigir o ponto final necessário para o contato espacial exato. |
| [R41-Q5](decisoes/D-055-r41-q5-recuos-acumulados.md) | 5B | Hits consecutivos acumulam deslocamentos de recuo apenas na apresentação visual. Depois, o modelo retorna à posição lógica inalterada pelo recuo. |
| [R41-Q6](decisoes/D-056-r41-q6-fatal-lancamento.md) | 6D | Se um hit mata um inimigo, exibir lançamento para trás pelo ar, queda ao chão e desaparecimento posterior, com estética exagerada inspirada em Dragon Ball / Super Smash Bros. Trata-se da sequência visual fatal do inimigo. |
| [R41-Q7](decisoes/D-057-r41-q7-onda-velocidade.md) | 7A | A onda AoE se propaga no espaço a velocidade constante, atingindo cada alvo conforme a distância e o instante de chegada. |
| [R41-Q8](decisoes/D-058-r41-q8-alvo-morto.md) | 8A | O alvo incluído por estar vivo na declaração permanece referenciado, mas, se morrer antes da chegada da onda, a passagem não causa novo dano nem reação. Não selecionar alvo substituto. |
| [R41-Q9](decisoes/D-059-r41-q9-evade-onda.md) | 9B | Todos os alvos possuem a mesma janela geral de Evade durante o voo da onda AoE, mantendo as decisões de esquiva individual e de efeitos individuais. |
| [R41-Q10](decisoes/D-060-r41-q10-status-idle-camera.md) | 10B | Durante o efeito visual de status, as outras ações lógicas permanecem congeladas; animações ociosas continuam e a câmera acompanha o efeito de status. |

### 17.2 Complementos que integram as respostas

- **R40-Q1:** o ataque original termina quando o golpe foi efetuado e a animação do golpe acabou, **antes** do pulo/teleporte de retorno. Essa explicação complementa a escolha 1A; não reduzir o término ao frame do dano se a animação continua.
- **R40-Q5:** o recuo ocorre a **qualquer hit recebido**, mesmo se o atingido não estiver atacando; é **somente visual**, sem mudar a posição lógica (escolha B posterior). R41-Q5 determina o acúmulo visual de hits consecutivos, seguido de retorno à posição lógica.
- **R41-Q6D:** um **inimigo morto por hit fatal** voa para trás, cai ao chão e desaparece em sequência exagerada estilo Dragon Ball / Super Smash Bros. É exceção específica à regra histórica de cadáver ficar no chão; os aliados não foram abrangidos por essa definição.

### 17.3 Relações com decisões anteriores e conflitos a preservar

1. **D-025 × R39-Q10:** a reintegração da **arquitetura** da Fase 2 foi aprovada. A reversão histórica da D-025 permanece registrada, mas não deve bloquear essa aprovação posterior. Nenhuma mudança mecânica anteriormente não autorizada fica automaticamente aprovada.
2. **D-016/D-027/D-030 × R39-Q4/R40-Q2/R41-Q1-Q3:** Evade fora da janela não tem efeito. Contra-ataque extra só executa após terminar o golpe original; o Move pode ser selecionado dentro dos **2 segundos reais** e enfileirado até depois. Cobra o custo normal. Pendente definir momento da cobrança e o comportamento se o saldo mudar entre a escolha e a execução.
3. **D-004 × R40-Q4/R40-Q6/R41-Q4:** perseguição apenas durante a corrida; golpe mantém trajetória fixa; correção espacial autoritativa pontual **no contato**. Não confundir com perseguição contínua durante a animação do golpe.
4. **D-007/D-009/D-011 × R39-Q6-Q7/R41-Q7-Q9:** AoE sem alvo principal e Evade individual. A **onda de projétil** é o caso em que impactos chegam em instantes diferentes com velocidade espacial constante. Alvos são fixados pela condição de vida na declaração; alvos que morram depois não sofrem novo hit nem geram substituição. A janela comum de Evade durante o voo precisa ser conciliada com a janela perfeita de **0,22 s** relativa a impactos individuais (D-030); **não decidido** se a janela perfeita é comum ou individual.
5. **D-010 × R40-Q8:** no AoE, o atacante recebe no máximo uma recompensa por fraqueza e uma por crítico por execução, quando houver pelo menos um alvo com cada condição. Não multiplicar recompensas por alvo.
6. **D-013 × R40-Q9:** na onda de projétil AoE, exatamente um hit-stop no primeiro impacto, sem repetir nos alvos seguintes. Preservar interrupção de alvos efetivamente atingidos, não dos que desviaram.
7. **D-014/D-019/D-020 × R39-Q8/R41-Q10:** pausa de status começa na ativação do efeito; outras ações congelam, enquanto as animações ociosas continuam e a câmera acompanha o FX. Essa continuidade **não autoriza** reintroduzir locomoção ociosa removida. A arquitetura de relógio e a compatibilidade técnica ainda precisam de implementação/validação.
8. **D-015/D-020 × R39-Q9/R40-Q10:** é obrigatório enquadrar todos os inimigos, inclusive na cinematografia. Zoom e deslocamento ficam permitidos para isso; tremor de câmera continua proibido. A regra posterior altera só essa restrição visual.
9. **D-024/D-025 × R40-Q5/R41-Q5-Q6:** recuo de **qualquer** hit é cosmético e cumulativo, sem modificar a posição lógica. O lançamento fatal com desaparecimento **somente do inimigo** substitui a manutenção visual do corpo caído para esse caso. A regra de derrota dos aliados continua não definida.
10. **Código atual × especificação:** trechos anteriores da seção 9 documentam a implementação antiga de AoE com alvo principal e 85%; são diagnóstico histórico, **não** decisão vigente. A implementação não foi alterada por esta atualização documental.

### 17.4 Pendências ainda sem decisão (não preencher automaticamente)

- No golpe extra enfileirado, **quando** debitar Burst/ATB e o que fazer se o saldo mudar antes da execução.
- Na onda AoE, como compatibilizar janela comum de Evade com os últimos 0,22 s de perfeição e chegadas não simultâneas.
- Parâmetros cinematográficos exatos do lançamento fatal do inimigo (tempo, distância, curva, desaparecimento); efeitos de derrota para aliados.
- Diferença operacional entre animação ociosa mantida durante o FX de status e locomoção ociosa previamente proibida.
- Revisar a execução de uma seleção antecipada de contra-ataque frente à morte do ator/alvo ou interrupções antes de o golpe original terminar.

### 17.5 Registro contínuo obrigatório

A diretriz **[D-061](decisoes/D-061-registro-continuo-das-decisoes.md)** determina que cada decisão aprovada seja registrada no GitHub imediatamente, com atualização do índice e deste consolidado, **sem modificar código automaticamente**. Antes da próxima rodada, conferir que as decisões anteriores estão publicadas. Nenhum teste de jogo é substituído por essa documentação.
---

## 18. Rodada 42 — decisões aprovadas e complementos às Rodadas 39–41

> **2026-11-03.** A Rodada 42 foi registrada em D-062 a D-071. Este adendo **preserva integralmente** as seções anteriores e as decisões das Rodadas 39, 40 e 41. As pendências históricas da §17.4 foram escritas **antes da Rodada 42**; para os temas retomados, usar as decisões posteriores a seguir. A aprovação de design **não significa implementação no Godot**.

### 18.1 Matriz de decisões aprovadas

| Decisão | Alternativa | Regra |
|---|---|---|
| [R42-Q1](decisoes/D-062-r42-q1-custo-na-selecao.md) | 1A | Descontar o ATB ou Burst do Move extra **no momento da seleção manual**, mesmo que o contra-ataque fique enfileirado até terminar o ataque original. |
| [R42-Q2](decisoes/D-063-r42-q2-burst-antes-atb.md) | 2A | Quando **Burst e ATB são ambos suficientes**, consumir **Burst primeiro**, preservando o ATB. Manter que **1 Burst paga a ação inteira**, no máximo 5 unidades acumuladas. |
| [R42-Q3](decisoes/D-064-r42-q3-interrupcao-cancela-extra.md) | 3A | Se o ataque original for interrompido após a seleção do golpe extra, **cancelar o contra-ataque enfileirado**; ele não pode executar posteriormente. |
| [R42-Q4](decisoes/D-065-r42-q4-alvo-morre-cancela-extra.md) | 4A | Se o **alvo do Move extra morrer antes de começar sua execução**, **cancelar** o contra-ataque de alvo único; não selecionar outro alvo automaticamente. |
| [R42-Q5](decisoes/D-066-r42-q5-onda-evade-perfeito-comum.md) | 5A | Na onda de projéteis AoE, **todos os alvos compartilham a janela comum de Evade e também uma única janela de Evade perfeito**, preservando a resposta individual de cada alvo e a inexistência de alvo principal. |
| [R42-Q6](decisoes/D-067-r42-q6-onda-alvos-posicao-atual.md) | 6A | A onda AoE considera a **posição atual de cada alvo durante a propagação**, mesmo que ele se movimente, **mantendo velocidade espacial constante**. O conjunto de alvos continua fixado na declaração, sem alvo principal. |
| [R42-Q7](decisoes/D-068-r42-q7-aliado-lancado-nao-some.md) | 7C | No hit fatal de um **aliado**, ele é **lançado para trás e cai no chão**, **sem desaparecer**. Para **inimigos**, conservar D-056: lançamento, queda e desaparecimento. |
| [R42-Q8](decisoes/D-069-r42-q8-intensidade-fatal-padronizada.md) | 8A | O **lançamento visual por hit fatal possui intensidade padronizada**, idêntica para todos os Moves, sem aumentar por dano, crítico ou fraqueza, nem variar por tipo de Move. |
| [R42-Q9](decisoes/D-070-r42-q9-apenas-idle-ja-existente.md) | 9A | Durante o FX de status, **somente as animações idle já existentes continuam**; não há **deslocamento pelo cenário**. Outras ações ficam congeladas e a câmera acompanha o efeito, conforme R41-Q10. |
| [R42-Q10](decisoes/D-071-r42-q10-cronometro-pausado-hitstop-status.md) | 10B | **Suspender o cronômetro dos dois segundos para selecionar o golpe extra durante hit-stop e pausas de Moves de status**. Retomar a contagem quando a pausa terminar, sem perder o tempo restante. |

### 18.2 Compatibilidade com decisões anteriores

1. **Contra-ataque e pagamento — D-062/D-063:** o custo é debitado na seleção antecipada, ainda que o Move aguarde a execução. Havendo Burst e ATB suficientes, Burst tem prioridade e paga a ação inteira (D-033 e D-053). O prazo de seleção e a conclusão do golpe original continuam definidos em D-041, D-042 e D-051–D-052.
2. **Contra-ataque cancelado — D-064/D-065:** interromper o ataque original cancela o Move extra enfileirado; a morte do alvo do Move extra antes da execução também cancela o extra. Não há redirecionamento automático de alvo único. **Não foi decidido se o custo já debitado é reembolsado.**
3. **AoE e Evade perfeito — D-066/D-067:** a janela geral de Evade **e a janela de Evade perfeito** são compartilhadas entre todos os alvos de uma onda de projéteis, sem eliminar a esquiva individual. A onda consulta a posição atual dos alvos, com velocidade espacial constante. R39-Q7 preserva os participantes vivos na declaração; D-007 impede alvo principal. **A janela perfeita global precisa ser conciliada com a regra dos últimos 0,22 s antes do impacto individual de D-030**, dado que a onda atinge os alvos em tempos diferentes.
4. **Hit fatal — D-068/D-069:** inimigos são lançados, caem e desaparecem (D-056); aliados são lançados, caem e permanecem visíveis. O lançamento fatal é padronizado, igual para todos os Moves. Isso altera apenas a **apresentação visual** aprovada; não permite deslocamento lógico autoritativo do recuo (D-045).
5. **Animações de status — D-070:** enquanto as demais ações param, continuam exclusivamente as animações idle **já existentes**, sem deslocamento pelo cenário. A câmera acompanha o Move de status (D-060); a proibição de reintroduzir locomoção ociosa segue válida (D-020).
6. **Cronômetro da janela extra — D-071:** os 2 segundos de escolha do Move extra são **suspensos durante hit-stop e pausa de status**, voltando a contar após o fim da pausa. A seleção antecipada continua válida e a execução segue enfileirada após o golpe original (D-051/D-052).

### 18.3 Pendências ainda abertas

- **Restituição de recursos:** quando um Move extra já pago é cancelado por interrupção do ataque original ou morte do alvo, não foi decidido se ocorre devolução de ATB/Burst.
- **Momento da janela perfeita AoE global:** falta determinar o início/fim da janela de perfeição compartilhada frente aos vários impactos em tempos diferentes e ao parâmetro de 0,22 s de D-030.
- **Parâmetros cinematográficos do hit fatal:** faltam números para velocidade/altura/distância/tempo/queda e efeitos de desaparecimento; apenas a intensidade uniforme entre Moves foi definida.
- **Geometria e velocidade concreta da onda AoE:** os critérios de propagação por posições atuais e velocidade constante estão aprovados, mas o método geométrico e os valores específicos ainda não foram fixados.
- **Outros casos de invalidação do contra-ataque:** não presumir comportamento para situações não respondidas, como morte do próprio atacante antes da execução.

### 18.4 Estado desta documentação

As dez decisões estão registradas como **especificação de design**, não como funcionalidades implementadas. Nenhum arquivo de código, VFX, teste ou configuração do jogo foi alterado pela Rodada 42.

---

## 19. Rodada 43 — recomendações aceitas por delegação do usuário

> **Fonte literal do usuário (2026-11-03):** “Sigo suas recomendações”. **Nota de proveniência:** as alternativas abaixo foram selecionadas e recomendadas pelo assistente após essa aceitação geral; o usuário **não escreveu individualmente** as letras 1A–10A. Os dez registros D-072 a D-081 preservam essa distinção e não representam implementação no Godot. Se houver dúvida sobre o alcance dessa delegação, confirmar com o criador antes de implementar mecânicas.

### 19.1 Matriz de recomendações aceitas

| Decisão | Alternativa recomendada | Regra registrada |
|---|---|---|
| [R43-Q1](decisoes/D-072-r43-q1-estorno-interrupcao.md) | 1A | Quando o contra-ataque extra já foi selecionado e pago, mas o ataque original é interrompido antes da execução, cancelar o extra (D-064) e **devolver integralmente o Burst ou o ATB que foi descontado por esse extra**. |
| [R43-Q2](decisoes/D-073-r43-q2-estorno-alvo-morto.md) | 2A | Se o alvo do contra-ataque extra morrer antes de sua execução, cancelar o golpe extra sem redirecionar o alvo (D-065) e **devolver integralmente o recurso debitado na seleção**. |
| [R43-Q3](decisoes/D-074-r43-q3-personagem-morre-estorno.md) | 3C | Se o personagem que selecionou e pagou o contra-ataque extra morrer antes de o golpe começar, **cancelar o Move extra**. Aplicar **a mesma regra de reembolso da interrupção do ataque original**: devolução integral do recurso pago (R43-Q1A / D-072), ainda que o personagem esteja derrotado. |
| [R43-Q4](decisoes/D-075-r43-q4-janela-perfeita-primeiro-impacto.md) | 4A | Para a onda de projéteis AoE, a **única janela compartilhada de Evade perfeito dura 0,22 segundos e termina imediatamente antes do primeiro impacto da onda**. Todos os alvos participantes podem tentar o Evade perfeito nessa mesma janela, inclusive os que receberiam impacto depois. Preservar o Evade comum durante a janela geral de voo. |
| [R43-Q5](decisoes/D-076-r43-q5-evade-visual-imediato.md) | 5A | Na onda AoE, quando um personagem aciona um Evade válido, **a esquiva visual acontece imediatamente ao apertar o botão**. O motor **registra o resultado desse Evade para a resolução do impacto posterior da mesma onda**, mesmo que a frente ainda não tenha alcançado o personagem. A resolução continua individual, sem cancelar danos dos outros alvos. |
| [R43-Q6](decisoes/D-077-r43-q6-geometria-por-move.md) | 6D | **Não impor uma única geometria universal** às ondas de projéteis AoE. **Cada Move determina sua geometria**, respeitando as regras comuns: onda única para o Move, sem alvo principal, participantes vivos na declaração, Evade compartilhado com resoluções individuais, velocidade espacial constante, e consideração das posições atuais dos alvos. |
| [R43-Q7](decisoes/D-078-r43-q7-velocidade-configuravel-move.md) | 7A | Cada Move de projétil AoE possui **sua própria velocidade de propagação configurável**, que se mantém **constante durante a onda** de sua execução, inclusive quando os alvos mudam de posição. |
| [R43-Q8](decisoes/D-079-r43-q8-lancamento-fatal-oposto-atacante.md) | 8A | O personagem atingido por um hit fatal é lançado **para longe da posição de quem aplicou o golpe fatal**. Preservar intensidade visual padronizada para todos os Moves (D-069): inimigos caem e desaparecem; aliados caem e permanecem visíveis. |
| [R43-Q9](decisoes/D-080-r43-q9-desaparecimento-particulas.md) | 9C | Após o lançamento e a queda fatal, **o inimigo desaparece em uma explosão visual estilizada de partículas e fumaça**. Esta regra não se aplica aos aliados derrotados, que permanecem visíveis no chão. |
| [R43-Q10](decisoes/D-081-r43-q10-resultado-apos-fatal.md) | 10A | Quando a batalha terminar em consequência de um hit fatal, **mostrar a tela de vitória ou derrota somente depois da conclusão da sequência fatal do personagem derrotado**. Para inimigos inclui lançamento, queda e desaparecimento; para aliados inclui lançamento e queda, sem desaparecimento. |

### 19.2 Compatibilidade e prioridades

1. **Contra-ataque com pagamento antecipado (D-072/D-073/D-074):** manter desconto na seleção (D-062), Burst prioritário (D-063), cancelamento quando o original é interrompido ou o alvo morre (D-064/D-065). Nesses casos, o recurso pago pelo extra é restituído integralmente. Se o próprio ator morrer antes do golpe extra, cancelar e devolver conforme a mesma política; a restituição não revive o personagem.
2. **Janela AoE e animação de Evade (D-075/D-076):** todos compartilham uma janela perfeita de 0,22 s imediatamente antes do **primeiro impacto** da onda; conserva-se a janela geral compartilhada. Cada personagem que desvia exibe imediatamente o efeito visual, e o resultado fica registrado para o impacto posterior dessa onda. A regra dos 0,22 s por alvo individual (D-030) permanece para golpes comuns, não para essa onda AoE.
3. **Forma e propagação da onda (D-077/D-078):** a geometria e a velocidade configurável são determinadas **por Move**; dentro de cada execução a velocidade espacial permanece constante. Mantém-se onda única, alvos vivos na declaração, sem alvo principal, impacto por chegada e posição atual do alvo (D-007/D-009/D-037/D-057/D-067).
4. **Derrota visual e tela final (D-079/D-080/D-081):** lançar a vítima fatal para longe do atacante com intensidade padronizada (D-069). Inimigos caem e desaparecem em partículas/fumaça; aliados caem sem sumir. Quando o hit fatal encerra a batalha, só apresentar a tela de resultado após concluir a sequência fatal aplicável.

### 19.3 Pendências não decididas por esta rodada

- Reembolso de recurso quando o medidor de ATB/Burst **já voltou ao máximo** antes do cancelamento: não há regra de capacidade/excesso aprovada para essa situação particular. Não presumir perda ou armazenamento extra sem esclarecimento.
- O primeiro impacto **previsto** da onda não se realizar (por exemplo, o alvo morrer antes de ser alcançado): definir se o marco da janela perfeita de 0,22 s permanece no instante inicialmente previsto ou se muda. Não presumir novo alvo principal.
- A geometria e os valores concretos de velocidade precisam ser definidos individualmente para cada Move AoE, conforme D-077/D-078; a categoria não fixa uma geometria universal.
- Lançamento e desaparecimento fatal: faltam distância, altura, duração, parâmetros de colisão e características do efeito. Intensidade uniforme, direção relativa e tipo de desaparecimento já estão definidos.
- Encerramentos que não sejam por hit fatal, múltiplos hits fatais e KO simultâneo: a D-081 não acrescenta uma regra nova para esses casos.

### 19.4 Estado documental

Essas escolhas foram aceitas **por delegação às recomendações** e estão registradas como requisitos. Nenhum código de combate, VFX, testes ou arquivo prévio foi modificado nesta rodada, além da inclusão dos dez registros e da atualização do índice/consolidado.

---

## 20. Rodada 44 — recomendações do assistente aceitas pelo criador

> **Data: 2026-11-03.** Resposta literal do usuário: **“Sigo suas recomendações e já faça as próximas perguntas na próxima mensagem também”**. As escolhas R44-Q1 a Q10 foram **recomendadas pelo assistente e aceitas por delegação**, não escritas individualmente pelo usuário. Foram registradas nos documentos D-082 a D-091. Mantidas as regras e o histórico das Rodadas 39–43. Esta seção não afirma implementação no jogo.

### 20.1 Matriz das dez decisões

| Decisão | Escolha recomendada | Regra |
|---|---|---|
| [R44-Q1](decisoes/D-082-r44-q1-credito-estorno-excedente.md) | 1A | Se a restituição integral de Burst ou ATB decorrente do cancelamento de um contra-ataque extra exceder o limite normal do medidor (5), guardar a parcela excedente como **crédito separado daquele recurso**, sem elevar o valor mostrado da barra acima do limite. O crédito é **consumido antes do recurso normal correspondente** no pagamento de ações. Não descartar o excedente. |
| [R44-Q2](decisoes/D-083-r44-q2-janela-aoe-primeiro-falha.md) | 2A | Se o primeiro impacto previsto de uma onda AoE não chegar a ocorrer, por exemplo devido à morte daquele alvo, a **única janela perfeita compartilhada** continua ligada ao **instante de impacto originalmente previsto**; a morte não desloca o marco temporal para outro alvo. Preservar 0,22 s de duração e ausência de dano/reação em alvos mortos. |
| [R44-Q3](decisoes/D-084-r44-q3-onda-recalculo-primeiro-impacto.md) | 3A | Enquanto os alvos da onda AoE mudam de posição, recalcular continuamente a **previsão do primeiro impacto** para temporizar o Evade perfeito, respeitando posições atuais, velocidade espacial constante e **uma única janela compartilhada** de 0,22 s para toda a onda. Não criar janelas independentes por alvo. |
| [R44-Q4](decisoes/D-085-r44-q4-onda-sem-alvos-vivos.md) | 4B | Mesmo que todos os alvos participantes de uma onda AoE morram antes de serem alcançados, a **propagação visual da onda continua até completar sua sequência**. Não aplicar dano adicional, nova reação ou redirecionamento para substitutos. |
| [R44-Q5](decisoes/D-086-r44-q5-burst-evade-onda.md) | 5B | Cada personagem que tiver **Evade bem-sucedido** contra uma determinada onda AoE, **comum ou perfeito**, recebe **+1 Burst, uma única vez por onda**, individualmente. Não multiplicar o prêmio por cada impacto de uma mesma onda ou pelo número de alvos. |
| [R44-Q6](decisoes/D-087-r44-q6-duracao-fatal-global.md) | 6A | A sequência de **lançamento fatal** utiliza uma **duração global configurável**, aplicada igualmente a todos os personagens, preservando a intensidade padronizada entre Moves. A duração é um parâmetro visual compartilhado; não modificar HP, posições lógicas ou condições de derrota por essa decisão. |
| [R44-Q7](decisoes/D-088-r44-q7-arco-fatal-cinematografico.md) | 7A | O personagem atingido fatalmente segue uma trajetória visual de **arco aéreo exagerado**: sobe, desloca-se para longe de quem o atingiu e cai no chão. Preservar a intensidade e a duração compartilhadas; inimigos posteriormente desaparecem, enquanto aliados permanecem no chão. |
| [R44-Q8](decisoes/D-089-r44-q8-colisao-fatal-obstaculos.md) | 8A | Se o personagem visualmente lançado por hit fatal atingir uma **parede ou obstáculo durante o voo**, **interromper o deslocamento aéreo na colisão e fazê-lo cair naquele local**. Preservar a sequência final: desaparecimento do inimigo após a queda ou permanência do aliado. |
| [R44-Q9](decisoes/D-090-r44-q9-resultado-apos-multiplos-fatais.md) | 9A | Se o mesmo AoE derrotar vários personagens e a batalha terminar, **aguardar a conclusão de todas as sequências visuais fatais relevantes antes de exibir a tela de resultado**. Inimigos terminam após o desaparecimento com partículas e fumaça; aliados, após a queda, sem desaparecer. |
| [R44-Q10](decisoes/D-091-r44-q10-ko-simultaneo-empate.md) | 10B | Se um mesmo AoE causar a derrota simultânea de **todas as unidades das duas equipes**, o resultado é **empate, sem vencedor**, com a batalha encerrada. Não estabelecer reinício automático ou um critério de desempate não aprovado. A tela de resultado aguarda as sequências fatais concluírem, conforme D-090. |

### 20.2 Compatibilidade com regras anteriores

1. **Ressarcimento e limite — D-082:** a restituição integral exigida por D-072 a D-074 preserva o limite visível de 5; eventuais excessos viram **créditos separados**, consumidos antes do recurso normal correspondente. A prioridade de Burst sobre ATB continua sendo D-063. A duração e a prioridade cruzada dos créditos ainda não foram decididas.
2. **Janela perfeita AoE — D-083 e D-084:** se o primeiro impacto previsto deixar de ocorrer por morte do alvo, preservar o marco anteriormente previsto. Quando os alvos se movimentarem, recalcular continuamente a previsão do primeiro impacto, mantendo uma **única janela perfeita** de 0,22 s. Há casos-limite temporais ainda abertos quando a previsão muda durante/depois da janela, ou o alvo morre após um recálculo; nenhuma segunda janela foi autorizada.
3. **AoE sem alvos e recompensa — D-085 e D-086:** se todos os alvos morrerem antes de a onda chegar, ela completa o seu efeito **visual**, sem aplicar novos hits ou reações. Cada personagem que executar Evade comum ou perfeito bem-sucedido contra uma onda recebe **+1 Burst, uma vez por onda**. Isso não concede invulnerabilidade adicional contra outros Moves.
4. **Lançamento fatal — D-087 a D-089:** duração global configurável; arco aéreo exagerado com subida, deslocamento para longe do atacante e queda. Colisão contra obstáculo interrompe o voo e causa queda no ponto de contato visual. Inimigos continuam desaparecendo após cair; aliados permanecem visíveis. Nenhum dano ou mudança de posição lógica foi introduzido.
5. **Resultados — D-090 e D-091:** se AoE derrubar vários personagens e encerrar a batalha, esperar todas as animações fatais terminarem para mostrar o resultado. Se **ambas as equipes** forem eliminadas simultaneamente por um AoE, declarar **empate sem vencedor**, encerrando a batalha; nenhuma repetição automática foi aprovada.

### 20.3 Pendências remanescentes, sem aprovação implícita

- **Créditos de estorno:** duração e persistência entre batalhas, prioridade relativa de créditos de Burst/ATB e apresentação na HUD.
- **Janela única de Evade perfeito:** como proceder quando a previsão do primeiro impacto muda enquanto os 0,22 s estão correndo ou após o fim da janela, respeitando a impossibilidade de uma segunda janela.
- **Primeiro alvo morto após movimento:** definir qual previsão fica congelada para D-083 após os recálculos de D-084, evitando escolher silenciosamente um marco de tempo.
- **Movimentos cinematográficos:** valor da duração global, altura/distância do arco e efeitos físicos/cosméticos de colisões precisam de especificação. Nenhum movimento lógico permanente foi aprovado.
- **Empate e término:** recompensas/progressão após empate ou AOEs com resultados múltiplos que não eliminem as duas equipes não receberam regras novas além das já documentadas.
- **Moves AoE:** geometria e velocidade numéricas continuam a ser definidas individualmente por Move (D-077/D-078).

### 20.4 Estado

As dez regras acima são **decisões documentais** aceitas por delegação. Nenhum código, arte, VFX, parâmetro de Move ou teste do jogo foi alterado durante esta rodada.

---

## 21. Rodada 45 — cinco decisões expressas (Q2–Q6)

> **Registradas em 2026-11-03.** O criador respondeu explicitamente **R45-Q2, Q3, Q4, Q5 e Q6**, todas com alternativa A. **R45-Q1 não recebeu resposta** e não foi aprovada. As cinco decisões estão em D-092 a D-096. Nenhuma regra anterior foi substituída além dos esclarecimentos expressos nesta rodada; o registro não equivale à implementação no código.

### 21.1 Decisões aprovadas

| Questão | Escolha | Regra |
|---|---|---|
| [R45-Q2](decisoes/D-092-r45-q2-evade-ataques-sobrepostos.md) | 2A | Um Evade bem-sucedido pode evitar **ambos os ataques de dois inimigos** quando os impactos dos dois coincidirem com a esquiva do personagem. Isso não exige dois Evades separados para esses impactos coincidentes. |
| [R45-Q3](decisoes/D-093-r45-q3-contra-extra-unico-varios-atacantes.md) | 3A | Quando um personagem realiza Evade perfeito contra vários atacantes, ganha **um único contra-ataque extra**, direcionado a **um dos atacantes**. Não ganha automaticamente um golpe extra por atacante. |
| [R45-Q4](decisoes/D-094-r45-q4-projetil-apos-morte-lancador.md) | 4A | Um projétil **já lançado** continua ativo após a morte de quem o lançou e **pode atingir normalmente seu alvo**. Não cancelar o projétil exclusivamente pela morte posterior do lançador. |
| [R45-Q5](decisoes/D-095-r45-q5-empate-mesmo-instante-logico.md) | 5A | Se **as duas equipes forem totalmente eliminadas no mesmo instante lógico**, o resultado é **empate sem vencedor**, inclusive quando os golpes que provocaram a eliminação forem diferentes. A regra de empate por um único AoE (D-091) permanece. |
| [R45-Q6](decisoes/D-096-r45-q6-combate-continua-durante-morte.md) | 6A | Enquanto uma sequência visual de morte cinematográfica é exibida, **o combate continua normalmente entre personagens vivos**, desde que a batalha ainda esteja logicamente em andamento. **Somente a exibição da tela de resultado aguarda** a conclusão das sequências fatais pertinentes. |

### 21.2 Compatibilidade e restrições

1. **D-092:** um Evade bem-sucedido pode evitar dois ataques de inimigos cujos impactos coincidam com a mesma esquiva. A definição de coincidência não concede invulnerabilidade ilimitada.
2. **D-093:** Evade perfeito contra múltiplos atacantes concede **somente um contra-ataque extra**, com um dos atacantes como alvo. Preservar escolha manual do **Move** (D-043), seleção antecipada, custo, fila e cancelamento; não presumir o método de escolha do **alvo**.
3. **D-094:** morte do lançador **depois que um projétil foi lançado** não extingue o projétil, que pode atingir o alvo conforme as regras do Move. Não aprova continuar ataques ainda em preparação.
4. **D-095:** eliminação simultânea de ambas as equipes no **mesmo instante lógico** significa empate sem vencedor, mesmo com ataques diferentes. Generaliza o caso de único AoE já registrado em D-091, sem alterar os critérios de derrota de cada alvo.
5. **D-096:** animações fatais **não congelam as ações dos sobreviventes** enquanto a batalha continua; apenas a apresentação do resultado aguarda as sequências fatais. Depois do encerramento lógico da batalha, não há autorização para novas ações; manter outras pausas aprovadas.

### 21.3 Pergunta não respondida e pendências reais

- **R45-Q1 — próximo escopo de implementação:** não respondida. As opções apresentadas foram implementação integral das Rodadas 39–44, implementação por sistemas completos ou testes de divergências antes das correções. **Nenhum método foi aprovado.**
- **R45-Q3:** não está definido **quem escolhe entre os atacantes** o alvo do contra-ataque extra único.
- **R45-Q2:** critério temporal preciso da sobreposição entre ataques e Evade; manter a condição aprovada sem criar janela numérica não solicitada.
- **R45-Q5:** a granularidade técnica do instante lógico requer validação na arquitetura do motor; não premiar a ordem arbitrária de processamento.
- As pendências das seções anteriores permanecem visíveis como histórico; nenhuma foi resolvida por omissão.

### 21.4 Estado

Cinco decisões **de design** documentadas (D-092–D-096), com atualização do índice e deste consolidado. **Nenhum arquivo de código, teste, VFX ou configuração de gameplay foi alterado.**

---

## 22. Rodada 46 — implementação por sistemas, escolha de alvo e projéteis pendentes

> **Data: 2026-11-03.** O criador escreveu literalmente **“Crawlmon — Rodada 46: sigo suas recomendações 1B, 2A e 3A”** e ordenou registrar os documentos, preservar as decisões e **não modificar código**. As três alternativas foram recomendadas pelo assistente e **explicitamente aceitas por número e letra**, e não transcritas como se o criador tivesse redigido suas descrições. Registros: **D-097 a D-099**. Esta atualização é apenas documental.

### 22.1 Matriz das decisões aprovadas

| Decisão | Alternativa | Regra |
|---|---|---|
| [R46-Q1](decisoes/D-097-r46-q1-implementacao-por-sistemas-testados.md) | 1B | Adotar **implementação sequencial por sistemas completos e testados**, na ordem: **(1) ATB, Evade e contra-ataque; (2) AoE; (3) animações e câmera**. Concluir e validar cada sistema antes de avançar ao seguinte; preservar as regras já aprovadas nas Rodadas 39–45. Esta decisão **aprova o sequenciamento**, não autoriza editar código nesta atividade de registro. |
| [R46-Q2](decisoes/D-098-r46-q2-alvo-contra-extra-multiplos.md) | 2A | Quando um personagem obtém **um único contra-ataque extra** ao evitar perfeitamente ataques de vários agressores (D-093), **o jogador escolhe manualmente um dos atacantes como alvo** se controlar o personagem; **a IA escolhe um dos atacantes** se controlar o personagem. Preservar escolha manual do Move, pagamento e enfileiramento já aprovados. |
| [R46-Q3](decisoes/D-099-r46-q3-projetil-pendente-resultado.md) | 3A | Se a última unidade de uma equipe morrer **enquanto ainda houver projéteis previamente lançados em voo**, **adiar a determinação definitiva do resultado da batalha até a resolução dos projéteis já lançados**, que continuam ativos mesmo se o lançador morreu (D-094). Caso os projéteis pendentes eliminem também a outra equipe, **permitir empate sem vencedor**; não declarar vitória ou derrota antes de resolver esses ataques pendentes. A exibição da tela de resultado continua aguardando as sequências fatais pertinentes. |

### 22.2 Compatibilidade e alcance

1. **D-097 — plano de implementação:** o escopo foi aprovado **por sistemas completos e testados**, nesta ordem: ATB/Evade/contra-ataque → AoE → animações/câmera. A sequência é requisito de planejamento, **não** autorização para tocar no código agora. Preservar a documentação e as regras de simetria da IA (D-021).
2. **D-098 — Evade perfeito múltiplo:** como previsto em D-093, só existe **um golpe extra**; se houver múltiplos atacantes, o jogador escolhe manualmente **um dos atacantes** como alvo, ou a IA escolhe quando controla o personagem. A escolha manual do Move (D-043), a fila, os custos e os cancelamentos continuam vigentes.
3. **D-099 — projéteis após derrota da equipe:** um projétil lançado permanece válido após morte de seu dono (D-094). Se uma equipe ficar sem combatentes enquanto esses projéteis estiverem em voo, a decisão final **aguarda os projéteis lançados serem resolvidos**, inclusive para permitir empate se eliminarem a outra equipe. A regra de empate por **mesmo instante lógico** da D-095 segue válida como regra geral; D-099 estabelece **um caso adicional específico**, sem reinterpretar retroativamente outros golpes. A tela de resultado espera as sequências fatais (D-081, D-090).

### 22.3 Pendências relevantes (sem decisão implícita)

- **Fase 1 de implementação:** a D-097 aprova sequência, mas não define autorização de alteração de código neste turno. Testes de gameplay e critérios de aceitação precisam ser demonstrados quando a implementação for autorizada.
- **Contra-ataque múltiplo:** não foi definido se o jogador deve escolher o alvo dentro da mesma janela de 2 segundos da seleção do Move ou se pode escolher depois. A lógica com que a IA prioriza atacantes também não foi especificada.
- **Resultado aguardando projéteis:** falta decidir se os combatentes ainda vivos podem iniciar novas ações enquanto projéteis em voo mantêm o resultado pendente. A D-096 mantém combate entre vivos nas mortes não terminativas, mas D-099 cria um estado específico de resultado ainda não definitivo.
- **Empate e resolução temporal:** D-099 permite empate causado por projéteis pendentes mesmo se o impacto posterior não coincidir exatamente com o primeiro KO; não estender esse comportamento a ataques futuros ou não lançados.
- Pendências anteriores de geometria e velocidade AoE por Move, créditos de estorno e parâmetros cinematográficos permanecem como registradas, sem modificações silenciosas.

### 22.4 Estado

**3 documentos de decisão criados, índice e consolidado atualizados; nenhum código, teste ou VFX modificado.**

---

## 23. Rodada 47 — projéteis pendentes, seleção do contra-ataque e somente documentação

> **2026-11-03.** O criador decidiu expressamente **1A, 2A e 3B**. Declarou que o Crawlmon **já é um jogo existente** e proibiu alterações no código nesta atividade. As decisões foram registradas em D-100 a D-102, preservando integralmente as seções e registros anteriores. Não representam implementação.

### 23.1 Matriz de decisões

| Decisão | Escolha | Regra |
|---|---|---|
| [R47-Q1](decisoes/D-100-r47-q1-sem-novas-acoes-projeteis-pendentes.md) | 1A | Quando uma equipe é eliminada e há projéteis já lançados em voo (D-099), **ninguém pode iniciar novas ações enquanto o resultado está pendente**, inclusive os sobreviventes. Os **projéteis já lançados continuam ativos até sua resolução**, permitindo empate se eliminarem também a outra equipe. Esta é uma exceção específica à continuidade normal do combate durante animações fatais (D-096). |
| [R47-Q2](decisoes/D-101-r47-q2-move-alvo-dentro-dois-segundos.md) | 2A | Quando um Evade perfeito contra vários atacantes concede um único golpe extra (D-093), **o jogador deve escolher o Move e qual atacante será alvo dentro da mesma janela de dois segundos**. A escolha aceita é enfileirada e a execução aguarda o fim do ataque original (D-051/D-052). Preservar a suspensão do relógio durante hit-stop e pausa de status (D-071). |
| [R47-Q3](decisoes/D-102-r47-q3-continuar-somente-documentacao.md) | 3B | **Não há autorização para alterar o código do Crawlmon nesta rodada**. Continuar somente com a documentação e decisões, preservando o jogo existente e suas implementações atuais. A D-097 permanece como ordem planejada para eventual implementação futura, não como autorização para iniciar alterações agora. |

### 23.2 Compatibilidade

1. **D-100 (R47-Q1A):** após uma equipe ser eliminada, quando projéteis já lançados mantêm o resultado pendente (D-099), ninguém pode iniciar novas ações; os projéteis em voo resolvem normalmente. Isso constitui exceção específica à regra geral D-096 de permitir que sobreviventes ajam durante sequências fatais enquanto há batalha em andamento.
2. **D-101 (R47-Q2A):** o jogador escolhe Move e atacante-alvo na **mesma janela de dois segundos** do contra-ataque extra contra vários agressores. Mantém-se um único golpe extra, com escolha do alvo conforme D-098, fila conforme D-051/D-052 e pausa do cronômetro conforme D-071.
3. **D-102 (R47-Q3B):** o usuário **não autoriza implementação nem modificações do código**; apenas documentação e decisões neste turno. A D-097 continua sendo um sequenciamento planejado, não um pedido de criar um jogo novo. A inspeção da main confirmou a presença de project.godot, scenes/, scripts/combat/ e tests/.

### 23.3 Pendências importantes ainda abertas

- **Ações já iniciadas** antes do estado de projéteis pendentes, mas ainda não lançadas como projétil: a R47-Q1A veda iniciar novas ações, sem definir se ações em andamento devem continuar, pausar ou ser canceladas.
- **Seleção incompleta** de Move ou atacante-alvo ao fim dos dois segundos: não houve regra aprovada de cobrança/cancelamento/reembolso nessa hipótese.
- **IA diante de múltiplos atacantes:** o algoritmo para escolher qual atacante será alvo não foi estabelecido; a D-098 define apenas quem faz a escolha.
- As pendências documentais de outras rodadas continuam históricas e não foram resolvidas por omissão.

### 23.4 Estado e escopo

**Somente cinco arquivos documentais**: novos D-100, D-101 e D-102; atualização do índice e do consolidado. Nenhum código, FX, configuração ou teste do jogo alterado. As perguntas da Rodada 48 são apresentadas separadamente ao usuário e não estão aprovadas por antecedência.

---

## 24. Rodada 48 — novas declarações e conflitos com regras anteriores

> **2026-11-03.** Duas declarações foram recebidas literalmente sobre: (1) encerramento quando o último inimigo cai e troca de alvo durante wind-up; (2) Evade de múltiplos ataques como evasão, com ataques visualmente concluídos e sem animação de interrupção. Foram registradas como D-103 e D-104. **Conflitos com decisões anteriores estão mantidos sem atribuir prevalência automática a uma delas.** O código não foi alterado.

### 24.1 Declarações registradas

| Referência | Origem | Conteúdo |
|---|---|---|
| [R48-Q1](decisoes/D-103-r48-q1-fim-imediato-retarget-windup.md) | Declaração expressa | **Último inimigo:** se o inimigo derrotado era o último inimigo presente, o criador determina que a batalha **acaba no instante da derrota dele**. A interpretação técnica precisa (encerramento lógico, tela de resultado, projéteis em trânsito) está assinalada como **conflito pendente** abaixo, sem revogar silenciosamente regras anteriores. **Ainda existem outros inimigos:** o combate **continua normalmente**. Se Pikachu já estava no **wind-up de um ataque** e o alvo morre, Pikachu **troca de alvo para executar o ataque**; o criador não determinou um novo custo, reinício de wind-up nem política de seleção do novo alvo. **Projéteis lançados:** Pikachu **continua podendo ser atingido pelo projétil já disparado** nessa situação em que outros inimigos permanecem. Preserva-se D-094 para projéteis lançados após a morte do atirador, na medida em que não conflitante com o fim da batalha. |
| [R48-Q2](decisoes/D-104-r48-q2-evade-termino-visual-sem-stagger.md) | Declaração expressa | **Ataques simultâneos:** ao realizar o Evade contra dois agressores, o criador diz que **ambos são interrompidos**, porém esclarece que o **Evade é evasão, não defesa perfeita/parry**: visualmente, **os ataques dos dois agressores devem terminar antes de serem tratados como interrompidos**, sem reproduzir uma animação de interrupção em razão somente da esquiva. **Animação de interrupção:** só ocorre se o atacante **receber um ataque durante o trajeto ou o wind-up de um ataque**. Apenas desviar de sua investida não deve produzir essa animação. **Contra-ataque extra:** conserva-se D-093 (somente um golpe extra quando vários ataques são evitados perfeitamente), enquanto o modo exato de encerrar logicamente os ataques desviados permanece pendente. |

### 24.2 Conflitos que exigem conciliação

1. **Último KO versus projéteis pendentes (D-103 × D-099/D-100):** a nova regra declara que a batalha acaba quando cai o último inimigo. D-099/D-100 determinam aguardar projéteis em voo para possível empate. **Não resolver por suposição se o projétil desaparece, ainda acerta, ou pode alterar o resultado**. O caso de ainda existirem outros inimigos é explícito: combate continua, Pikachu em wind-up troca de alvo e pode ser atingido pelo projétil já lançado.
2. **Encerramento da batalha versus tela de resultado (D-103 × D-081/D-090):** a expressão 'batalha acaba no segundo' não estabelece automaticamente que a tela de resultado interrompe as animações fatais. Preservar a regra documental anterior da exibição tardia até que seja esclarecida.
3. **Evade versus animação de interrupção (D-104 × D-017):** o criador diz que ambos os ataques são interrompidos, mas devem **terminar visualmente antes**, **sem animação de interrupção por causa do Evade**. A animação de interrupção ocorre quando o atacante é **atingido por ataque durante trajeto ou wind-up**. D-017 antes determinava interrupção/cambaleio por Evade. Preservar ambos os registros e não definir silenciosamente se o resultado lógico da esquiva é cancelamento ou falha normal.
4. **Compatibilidade com Evade simultâneo (D-092/D-093):** a esquiva pode evitar ambos os ataques e um Evade perfeito contra vários agressores concede no máximo um golpe extra. A nova declaração não altera explicitamente esse limite.

### 24.3 Pendências importantes, sem assumir resposta

- Quando cai **o último inimigo**, projéteis lançados anteriormente devem ainda poder atingir alguém ou alterar o resultado, conforme D-099, ou o fim da batalha é definitivo mesmo com projéteis em voo?
- Se os ataques terminam visualmente após o Evade, o que significa 'ambos interrompidos' no **motor**: marcar como falhas concluídas ou cancelá-los logicamente só após a animação?
- O critério para selecionar novo alvo quando um alvo morre durante o **wind-up**, se outros inimigos seguem vivos, ainda não foi escolhido; o fato de trocar alvo está registrado.
- Se 'o último inimigo' foi derrotado, a **tela de resultado** continua aguardando animações fatais conforme D-081/D-090? Não assumir que a frase suprimiu essa espera.

### 24.4 Estado

**Dois arquivos de decisão adicionados**, índice e consolidado atualizados, sem mexer no histórico, sem alterar código, configurações, FX ou testes. A publicação documental dos conflitos não representa aprovação de um comportamento técnico contraditório.

---

## 25. Rodada 48 — conciliação expressa dos dois conflitos

> **2026-11-03.** Resposta literal do criador: **“1A — A vitória é definitiva ao derrotar o último inimigo; o projétil não pode causar dano nem alterar o resultado.”** e **“2A — Os ataques desviados terminam como golpes que erraram, sem interrupção mecânica adicional.”** Esta seção é a regra atual para esses casos específicos; o histórico D-017, D-099, D-100, D-103 e D-104 permanece, anotado com o esclarecimento posterior. Nenhum código foi alterado.

### 25.1 Resultado: último inimigo derrotado

- **[D-105](decisoes/D-105-r48-esclarecimento-vitoria-ultimo-inimigo.md):** a derrota do **último inimigo presente** fixa **vitória definitiva imediatamente**. Projéteis já lançados e ainda em voo **não podem causar dano nem alterar o resultado** depois disso.
- **Exceção sobre D-099/D-100:** não aguardar projéteis para decidir a vitória por eliminação do último inimigo. Manter a regra histórica de espera para outros cenários onde ela seja aplicável, sem extrapolar para a derrota do último aliado.
- **Compatibilidade com D-103:** quando há mais inimigos vivos, o combate continua normalmente; alvo morto durante wind-up pode ser substituído, e projéteis previamente lançados ainda podem causar dano.
- **Compatibilidade com D-081/D-090:** a vitória pode ser logicamente definitiva no KO, mesmo que a tela de resultado espere a sequência visual fatal. Não inferir a eliminação dessa sequência visual.

### 25.2 Evade: golpe errado, não interrupção

- **[D-106](decisoes/D-106-r48-esclarecimento-evade-ataque-erra.md):** ataques desviados **concluem como golpes que erraram**, sem interrupção mecânica adicional nem animação de cambaleio disparada pelo Evade.
- **Prevalência sobre D-017/D-104:** a antiga interrupção imediata e o cancelamento lógico posterior à animação ficam **substituídos exclusivamente no caso de ataques evitados pelo Evade**. As outras decisões de Burst, golpe extra, custo, janela e IA continuam em vigor quando compatíveis.
- **Interrupção genuína:** receber um ataque durante wind-up ou trajeto é o caso indicado pelo criador para interrupção/animação própria; não atribuir esse efeito à mera evasão.
- **Ataques simultâneos:** a D-092 continua permitindo evitar dois impactos coincidentes com uma mesma esquiva; D-093 mantém um só contra-ataque extra.

### 25.3 Pontos ainda não decididos

- **Derrota da última unidade aliada:** a exceção D-105 está expressamente redigida para a derrota do último inimigo. Não definir por suposição se projéteis próprios em voo podem transformar uma derrota em empate.
- **Projéteis sem dano após vitória:** não foi escolhido se desaparecem visualmente de imediato ou terminam a trajetória puramente cosmética.
- **Novo alvo no wind-up quando outros inimigos sobrevivem:** o redirecionamento está aprovado em D-103, mas não o critério de escolha de alvo.
- Os pontos de outras rodadas que não sejam estes dois conflitos permanecem como documentados.

### 25.4 Estado

Dois registros novos (D-105/D-106), seis documentos antigos com **notas aditivas** de conciliação, índice e consolidado atualizados. **Sem alterações de código, VFX, testes ou configurações.**

---

## 26. Rodada 49 — derrota definitiva e seleção automática de alvo no wind-up

> **2026-11-03.** O criador escolheu expressamente **1A** e **2B**. As decisões são exclusivamente documentais, preservam as anteriores e estão registradas em D-107 e D-108.

### 26.1 Decisões

| Pergunta | Escolha | Regra |
|---|---|---|
| [R49-Q1](decisoes/D-107-r49-q1-derrota-definitiva-ultimo-aliado.md) | 1A | A morte da **última unidade aliada** fixa a **derrota definitiva imediatamente**. Projéteis já lançados por essa equipe não podem causar dano nem alterar o resultado depois do KO. |
| [R49-Q2](decisoes/D-108-r49-q2-inimigo-vivo-mais-proximo-no-windup.md) | 2B | Se o alvo do ataque morrer durante o **wind-up**, com outros inimigos vivos, o jogo **redireciona automaticamente para o inimigo vivo mais próximo**. |

### 26.2 Compatibilidade e histórico

1. **D-105/D-107 — KO final de qualquer equipe:** ao morrer o último inimigo, a vitória é definitiva; ao morrer o último aliado, a derrota é definitiva. **D-099/D-100 deixam de reger a espera por projéteis em ambos os KOs finais**, sem exclusão de seus textos históricos. Projéteis que atingiriam depois não causam dano nem mudam o resultado.
2. **D-095 e D-091 — empate simultâneo preservado:** ambas as equipes eliminadas no **mesmo instante lógico** continuam empatadas. Esta regra não cria empate por projétil que atinge depois do resultado definitivo.
3. **D-103/D-108 — novo alvo:** enquanto outros inimigos sobrevivem, o ataque cujo alvo morreu **no wind-up** passa automaticamente para o inimigo vivo mais próximo. Não implica redirecionamento de projéteis **já disparados**, nem refaz a lista de alvos da onda AoE (D-037, D-058).
4. **D-081/D-090 — tela final:** vitória/derrota é fixada no KO, mas apresentação aguarda as sequências fatais já aprovadas. Não foi escolhida a apresentação visual de projéteis residuais sem dano.

### 26.3 Pendências ainda não decididas

- Projétil de alvo único **já disparado** cujo alvo morre antes do impacto, enquanto outros inimigos permanecem vivos: não foi decidido se procura novo alvo, desaparece ou conclui trajeto sem dano.
- Obstáculos sólidos: não foi especificado nesta rodada o tratamento de ondas AoE que encontram paredes ou cobertura; preservar as geometrias específicas por Move (D-077).
- Com a batalha já encerrada, não foi decidido se projéteis que perderam a capacidade de causar dano devem sumir visualmente ou concluir sua animação.
- Empate em distâncias exatamente iguais entre alvos elegíveis não foi especificado.

### 26.4 Escopo documental

Criados D-107 e D-108; seis documentos anteriores receberam **somente notas aditivas** de compatibilidade. Índice e consolidado atualizados. **Nenhum código, FX, teste ou configuração alterado.**

---

## 27. Rodada 50 — alvo morto de projétil; pergunta sobre paredes sem regra aprovada

> **2026-11-03.** O criador respondeu **1A** sobre projétil de alvo único e **2D — Outra regra**, mas não especificou uma nova regra sobre paredes/obstáculos na observação. A observação literal **“2????????????????????? vc ao menos ta lendo o github ao menos ta vendo alguma coisa ou so ta mentindo esse tempo todo?”** sinaliza objeção à pergunta, **não uma autorização para criar física de paredes**. Esta rodada registra apenas a regra **D-109**. Nenhuma alteração de código foi autorizada.

### 27.1 Decisão aprovada

| Referência | Resposta | Regra |
|---|---|---|
| [R50-Q1](decisoes/D-109-r50-q1-projetil-alvo-morto-em-voo.md) | 1A | Se o **alvo de um projétil de alvo único já disparado morrer** antes do impacto, o projétil **perde o alvo e termina sem causar dano nem escolher substituto**. |

### 27.2 Compatibilidade e fonte de verdade

1. **Wind-up versus voo:** D-108 permite selecionar automaticamente o inimigo vivo mais próximo apenas se o alvo morrer **durante o wind-up**. **D-109 não redireciona um projétil já lançado** cujo alvo morreu. D-004/D-047 continuam permitindo acompanhar um alvo vivo.
2. **Lançador morto versus alvo morto:** D-094 determina que o projétil já disparado permanece ativo se o **lançador** morrer e a batalha continuar, o que é diferente de morrer o **alvo** do projétil (D-109). Finais de batalha seguem D-105/D-107.
3. **Ondas AoE:** D-037/D-058/D-077 mantêm os alvos participantes fixados na declaração do Move e sem seleção de substitutos quando um deles morre. D-109 se refere somente ao **projétil de alvo único**.
4. **Pergunta R50-Q2:** resposta **2D — Outra regra**, sem nova regra explícita. Ao conferir o código atual, `BattleSpace` usa posições planas do combate e `BattleArena` gera pilares e parede como geometria visual, sem estabelecer colisão física/oclusão deles para AoE. A pergunta anterior pressupunha uma mecânica não verificada e **não se converte em requisito**. A geometria de AoE segue definida por Move (D-077).

### 27.3 Pendências sem decisão implícita

- Os efeitos visuais de um projétil que perde seu alvo após disparo não foram definidos; a regra aprovada é **terminar sem dano e sem substituição de alvo**.
- A pergunta R50-Q2 está **sem regra nova aprovada**. Não se deve presumir existência de paredes físicas no combate nem iniciar discussão de cobertura sem necessidade comprovada pelas mecânicas reais.
- Diferenças entre o código Godot existente e as decisões documentadas exigem implementação em outra atividade autorizada, não nesta rodada.

### 27.4 Estado

Novo documento **D-109**, índice e consolidado atualizados. **Nenhum arquivo de código, FX, teste ou configuração foi alterado**. As perguntas seguintes devem ser fundamentadas em código/mecânicas reais, com exemplos claros, sem pressupor sistemas inexistentes.

---

## 28. Rodada 51 — interceptação por personagens e seleção aleatória de alvos pela IA

> **2026-11-03.** Duas respostas expressas: **1A** (manter interceptação existente de projéteis por personagens na linha do ataque) e **2C** (IA seleciona aleatoriamente um adversário vivo, exceto quando engajada). Ambas foram conferidas no código atual e registradas em **D-110** e **D-111**, sem mudança de arquivos de jogo.

### 28.1 Matriz das decisões

| Referência | Resposta | Regra aprovada |
|---|---|---|
| [R51-Q1](decisoes/D-110-r51-q1-manter-interceptacao-personagens.md) | 1A | Preservar a interceptação de projéteis de alvo único por **outro adversário que esteja na linha antes do alvo**, para os Moves em que a interceptação já se aplica. **Não** adicionar interceptação dinâmica durante o voo por esta resposta. |
| [R51-Q2](decisoes/D-111-r51-q2-alvo-aleatorio-ia.md) | 2C | Personagens controlados pela **IA (aliados e inimigos)** escolhem **aleatoriamente entre adversários vivos elegíveis** quando não engajados. Se engajados com um adversário vivo, atacam esse adversário. Preservar Tactics, escolha de Move e simetria. |

### 28.2 Código consultado e compatibilidade com decisões anteriores

- **Interceptação real:** `scripts/combat/attack_planner.gd`, métodos `redirect_if_blocked()` e `interceptor()`, encontram um adversário na linha antes do alvo na **declaração do ataque**; `Battle.use_skill()` chama essa lógica. Existem exceções de Moves no código. A D-110 **mantém** a interceptação existente; não autoriza novas físicas, paredes ou interceptação em voo. Preservar D-047, D-108 e D-109.
- **Seleção de alvos real:** `scripts/combat/battle.gd`, método `_run_ai()`, escolhe atualmente `c.engaged_with` se vivo, caso contrário `_first_alive(foes)`. A D-111 aprova a substituição **futura** do fallback por seleção aleatória entre vivos para personagens com IA. `use_skill()` impede escolher outro alvo se ainda engajado. Preservar D-021 e suas regras de simetria e Tactics.
- **Separação de responsabilidades:** interceptação de projétil não é colisão de cenário. A decisão da R50-Q2D permaneceu sem regra nova; não a reutilizar como autorização para criar parede/oclusão de área.

### 28.3 Limites não definidos por estas respostas

- **D-110:** não acrescentar interceptação dinâmica durante o voo; a situação de personagens mudando de posição depois do disparo não foi alterada pela escolha de manter o comportamento atual.
- **D-111:** nenhuma fórmula de pesos, prioridade de alvo por HP, proximidade ou inteligência preditiva foi escolhida. A resposta define aleatoriedade **respeitando engajamento**, não altera a escolha de Moves.
- A documentação registra requisitos e estado do código consultado; não afirma que as regras da Rodada 51 estejam implementadas.

### 28.4 Estado

**Dois documentos novos, índice e regras consolidadas atualizados.** Nenhum arquivo de código, configuração, teste, animação ou VFX foi modificado. As próximas perguntas requerem aprovação separada.

---

## 29. Rodada 52 — IA tática e retorno quando o alvo morre durante investida

> **2026-11-03.** Duas decisões expressas **1C** e **2C**, documentadas em D-112 e D-113. O código foi consultado para verificar fases e escolha atual de habilidades, mas não alterado.

### 29.1 Decisões

| Referência | Alternativa | Regra |
|---|---|---|
| [R52-Q1](decisoes/D-112-r52-q1-escolha-tatica-de-moves-ia.md) | 1C | A IA escolhe o **Move** com avaliação **tática** de dano, fraqueza elemental, efeitos e situação do combate. A **seleção do alvo permanece aleatória**, respeitando engajamento, conforme D-111. |
| [R52-Q2](decisoes/D-113-r52-q2-interromper-investida-alvo-morto.md) | 2C | Se o alvo de uma investida corpo a corpo **morrer durante o trajeto**, interromper essa investida e **retornar imediatamente à posição de origem**, sem redirecionar. |

### 29.2 Regras coexistentes e distinção de fases

- **IA (D-021, D-111, D-112):** tanto aliados quanto inimigos seguem as Tactics. `_run_ai()` e `_pick_skill()` em `scripts/combat/battle.gd` mostram que o código atual escolhe o primeiro alvo vivo, exceto engajamento, e percorre Skills pagáveis em sequência. As decisões D-111/D-112 especificam o comportamento futuro — **alvo aleatório** e **Move tático**, respectivamente — mas não foram implementadas.
- **Morte no wind-up (D-108):** se houver outros inimigos vivos, redirecionar o ataque ao inimigo vivo mais próximo antes do começo da investida.
- **Morte durante investida (D-113):** interromper a investida corpo a corpo e retornar imediatamente à origem, sem escolher outro alvo nessa fase. O motor já representa as fases WINDUP, TRAVEL, STRIKE e RETURN (D-019).
- **Finais de batalha (D-105/D-107):** vitória e derrota são fixadas quando a última unidade adversária ou aliada morre; não criar impacto tardio que modifique resultado.

### 29.3 Questões não definidas

- **IA:** não foram aprovados pesos matemáticos ou prioridade rígida entre dano, fraqueza e buffs/debuffs. A exigência tática não permite inferir fórmulas.
- **Retorno à origem:** a decisão não especifica se o retorno é visualmente instantâneo ou se inicia imediatamente uma animação, nem define duração ou efeito.
- **Morte durante STRIKE:** a resposta cobre apenas o trajeto da investida, não o momento depois que a investida termina e antes de acertar.
- Todas as outras decisões permanecem válidas, salvo exceções expressas das rodadas anteriores.

### 29.4 Escopo

**D-112 e D-113 criados; três documentos anteriores receberam notas aditivas; índice e consolidado atualizados. Nenhum código, teste, VFX ou configuração de gameplay foi modificado.**

---

## 30. Rodada 53 — recomendações de IA aceitas por delegação e escopo futuro

> **2026-11-03.** Declaração literal do criador: **“sigo suas recomendacoes quanto a forma que a IA deve agir, ate mesmo para as proximas perguntas”**. As perguntas da Rodada 53 não apresentavam alternativas previamente marcadas como recomendação. Após verificar `scripts/combat/battle.gd`, D-021, D-111 e D-112, o assistente **recomendou 1A e 2B** para as duas perguntas já formuladas. São **recomendações do assistente aceitas pela delegação do criador**, e não escolhas individuais de letras digitadas por ele. Documentos D-114, D-115 e D-116. Código inalterado.

### 30.1 Recomendações concretas para a Rodada 53

| Decisão | Recomendação do assistente aceita por delegação | Regra |
|---|---|---|
| [D-114](decisoes/D-114-r53-q1-alvo-antes-move-tatico.md) | **R53-Q1 — 1A** | **Primeiro** escolher o adversário-alvo aleatoriamente entre vivos elegíveis, respeitando engajamento (D-111); **depois** selecionar taticamente o Move adequado contra ele (D-112). Não substituir aleatoriedade do alvo por preferência de fraqueza. |
| [D-115](decisoes/D-115-r53-q2-cura-situacional-da-ia.md) | **R53-Q2 — 2B** | Integrar a escolha entre **poção e Move** à avaliação da situação do combate, em vez de usar poção sempre que HP ≤ 50%. Preservar Tactics, custos, estoque e regras de itens existentes. Pesos e fórmulas não foram definidos. |

### 30.2 Delegação de próximas decisões sobre IA

- **[D-116](decisoes/D-116-delegacao-recomendacoes-ia.md):** o criador estendeu a aceitação das recomendações a **futuras perguntas sobre como a IA deve agir**. Não repetir baterias artificiais de perguntas de IA quando uma recomendação fundamentada nas regras e no código for possível.
- As recomendações futuras **não são aprovadas antecipadamente como regras inexistentes**: cada questão concreta deve ser formulada, fundamentada, atribuída corretamente ao assistente, documentada em arquivo individual, indexada e consolidada conforme D-061. Conflitos de escopo ou com decisões anteriores não serão resolvidos por suposição.
- A delegação não autoriza modificar **código**, arquitetura, FX, recursos do jogo ou regras fora do domínio de decisões sobre IA. Alterações de código continuam sujeitas a ordem expressa.

### 30.3 Código verificado e diferenças de implementação

- Em `_run_ai()` de `scripts/combat/battle.gd`, a IA **atualmente prioriza poção** se HP ≤ 50% e existe item/ATB, **antes** de avaliar Moves; isso não implementa D-115.
- `_run_ai()` chama `_pick_skill()` antes de definir um alvo (engajado ou `_first_alive`); isso não implementa D-114 nem a escolha aleatória do alvo de D-111.
- Tactics `ATTACK`, `SKILL` e `HOLD`, custo de item, inventário, engajamento e política de seleção manual do líder permanecem sem modificação.

### 30.4 Estado

Três novos arquivos de decisão (D-114, D-115 e D-116); duas notas aditivas em decisões anteriores; índice e consolidado atualizados. **Nenhum código, teste, VFX, configuração ou asset alterado.**

---

## 31. Rodada 54 — esclarecimentos parciais sobre Agilidade e elementos

> **2026-11-03.** O criador esclareceu duas regras enquanto a lista de dez perguntas da Rodada 54 ainda estava em discussão. **São esclarecimentos expressos, não a aprovação das dez recomendações pré-selecionadas**. Apenas D-117 e D-118 são registrados nesta seção. Não houve autorização para alterações no código.

### 31.1 Declarações e regras registradas

| Decisão | Declaração do criador | Regra |
|---|---|---|
| [D-117](decisoes/D-117-r54-esclarecimento-agi-atb-e-trajeto.md) | “AGI funciona diferente, afeta ambas a regeneração de ATB como também a velocidade de movimento do Pokémon durante seus trajetos de ataque” | **Agilidade** influencia **ambos**: regeneração natural de ATB e **velocidade de movimento do Pokémon em seus trajetos de ataque**. O efeito de posicionamento de D-018 continua; fórmula conjunta ainda não definida. |
| [D-118](decisoes/D-118-r54-referencia-elementos-smt.md) | “Quanto aos elementos, são baseados mais em shin megami tensei que pokémon” | O sistema elemental usa **Shin Megami Tensei como inspiração principal**, mais do que Pokémon. Nenhuma conversão automática Pokémon → Crawlmon nem cópia literal de uma tabela de SMT foi aprovada. |

### 31.2 Comparação com as implementações

- **ATB:** `Combatant.tick()` já preenche ATB conforme `speed`, derivada de `base_speed`. Ainda não existe integração dos cinco atributos permanentes.
- **Trajetos de ataque:** `Battle.travel_seconds()` varia por duração-base e passos táticos (D-018), sem dependência de Agilidade. `AttackMotion.update()` desenha o deslocamento no tempo de `TRAVEL`. D-117 acrescenta uma exigência que **não está implementada**.
- **Elementos:** `Element.Type` inclui Físico, Fogo, Água/Gelo, Raio, Psíquico, Veneno, Som, Terra, Vento, Luz e Trevas. D-118 muda a **referência de design**, não aprova modificar o catálogo existente ou as fraquezas já cadastradas.

### 31.3 Pendências e preservação

- **AGI:** fórmula, limites de velocidade de trajeto, comportamento sob buffs/debuffs e sua combinação com o cálculo de passos táticos (D-018) continuam pendentes.
- **Elementos:** falta especificar concretamente afinidades/fraquezas por espécie no sistema inspirado principalmente em SMT; não usar tabela Pokémon como substituto automático.
- As outras oito perguntas da Rodada 54 e as opções previamente recomendadas continuam **não respondidas** pelo criador; a pergunta 7 e a pergunta 9 precisam ser reformuladas considerando as duas declarações acima.
- Não houve modificação de código, testes, VFX, modelos, configurações nem valores de personagens.

---

## 32. Rodada 54 — tempo de deslocamento individual por Move e retorno ao questionário

> **2026-11-03.** Declaração literal do criador: “Tempo de deslocamento é uma variável própria dita na ficha dos moves também, ela é reduzida pela agi e efeitos que aumentam AGI. Voltamos as perguntas anteriores a minhas duas respostas”. Regra registrada como [D-119](decisoes/D-119-r54-tempo-trajeto-por-move-reduzido-agi.md). **Não equivale a aprovar as dez escolhas do questionário da Rodada 54**, que o criador pediu para retomar.

### 32.1 Regra e compatibilidade

- **Tempo de deslocamento por Move:** a ficha de cada Move deve declarar **sua própria variável de tempo de deslocamento**, não um valor global único. **AGI reduz esse tempo; efeitos que aumentam AGI também o reduzem**. D-117 mantém a segunda influência de AGI sobre ATB.
- **Posicionamento tático D-018:** continua existindo, com ajuste de 0,10 s por soma de passos e mínimo histórico de 0,25 s. Não foi aprovada a fórmula que combina essa regra e a redução por AGI, nem um coeficiente de redução de AGI.
- **Código verificado:** `Skill` ainda não declara `travel_time` por Move. `AttackPlanner` configura alguns tempos específicos em lógica por identificação de Move e chama `Battle.travel_seconds()`, que atualmente só usa tempo-base e posição, **sem AGI**. A documentação descreve requisito e lacuna, não implementação.
- **Elementos D-118:** continuam prioritariamente inspirados em Shin Megami Tensei, não em conversão dos tipos de Pokémon.

### 32.2 Questões pendentes

- Coeficiente matemático e limites de redução de tempo por AGI e buffs; interação específica com os passos de D-018.
- A Rodada 54 original continua aberta; apenas AGI e o referencial dos elementos receberam esclarecimentos expressos. As outras opções do questionário não foram escolhidas pelo criador.

### 32.3 Escopo

Um registro novo D-119, nota aditiva em D-117, índice e regras consolidadas atualizados. Nenhum código, configuração, arquivo de Move, teste, VFX ou modelo modificado.

---

## 33. Rodada 54 — dez decisões de atributos e identidade mecânica por espécie

> **2026-11-03.** O criador respondeu expressamente as **dez perguntas**, escolhas **1C, 2B, 3A, 4B, 5B, 6A, 7A, 8C, 9A e 10A**. A formulação das alternativas tinha recomendações prévias do assistente, mas as **dez seleções foram enviadas diretamente pelo criador**, diferentemente da delegação apenas à IA (D-116). Preserve-se a íntegra do histórico D-001 a D-119. Registro documental, não implementação.

### 33.1 Matriz consolidada das escolhas

| Decisão | Escolha | Regra expressa do criador |
|---|---|---|
| [D-120](decisoes/D-120-r54-q1-atributos-base-especie-referencia-biologica.md) | 1C | Usar os atributos originais como referência biológica da espécie, ajustando os valores ao equilíbrio do Crawlmon. |
| [D-121](decisoes/D-121-r54-q2-pequena-variacao-aleatoria-atributos-individuais.md) | 2B | Adicionar pequenas variações aleatórias individuais nos atributos-base. |
| [D-122](decisoes/D-122-r54-q3-forca-dano-fisico-magia-dano-magico.md) | 3A | Força determina a base do dano físico; Magia determina a base do dano mágico/especial. |
| [D-123](decisoes/D-123-r54-q4-magia-efeitos-por-move-escalaveis.md) | 4B | Magia aumenta dano mágico e somente os efeitos que cada Move definir como escaláveis. |
| [D-124](decisoes/D-124-r54-q5-hp-vitalidade-nivel-coeficientes-especie.md) | 5B | Uma fórmula baseada em Vitalidade e nível, com coeficientes próprios de cada espécie. |
| [D-125](decisoes/D-125-r54-q6-vitalidade-resistencia-base-defesa-estagios.md) | 6A | Vitalidade também influencia a resistência-base a dano, preservando os estágios de Defesa. |
| [D-126](decisoes/D-126-r54-q7-calibrar-agi-atb-tempos-moves.md) | 7A | Calibrar AGI para preservar inicialmente os ritmos atuais de ATB e os tempos próprios dos Moves, introduzindo a redução por AGI sem alterar silenciosamente o equilíbrio. |
| [D-127](decisoes/D-127-r54-q8-sorte-critico-esquiva-automatica-status.md) | 8C | Sorte modifica críticos, esquiva automática e aplicação de efeitos de status. |
| [D-128](decisoes/D-128-r54-q9-afinidades-por-especie-referencia-smt.md) | 9A | Definir afinidades por espécie usando principalmente SMT como referência, preservando os elementos e as fraquezas existentes até revisão explícita. |
| [D-129](decisoes/D-129-r54-q10-atributos-permanentes-1-a-100-buffs-separados.md) | 10A | Os atributos permanentes ficam entre 1 e 100 após progressão e Nature; buffs temporários atuam separadamente. |

### 33.2 Prevalência e compatibilidade das regras

1. **Referências das espécies versus elementos (D-120/D-128/D-118):** atributos biológicos originais são referência para o perfil de espécie, **não** conversão elementar Pokémon. Afinidades seguem design inspirado principalmente em SMT; os elementos/fraquezas já cadastrados continuam até revisão explícita.
2. **Identidade e limite permanente (D-121/D-129):** pequenas variações aleatórias de atributos por indivíduo coexistem com Nature/progressão, mas os cinco atributos permanentes permanecem **entre 1 e 100**. Ainda faltam amplitude, distribuição, seed e resolução do teto.
3. **Ofensiva e defesa (D-122 a D-125):** Força fornece dano físico; Magia fornece dano mágico e os efeitos **marcados por Move** como escaláveis. Vitalidade participa de HP máximo com coeficiente por espécie e também da resistência-base, preservando buffs de Defesa e multiplicadores já aprovados. Fórmulas ficam pendentes.
4. **Agilidade, trajeto e posicionamento (D-126 + D-018/D-117/D-119):** AGI governa preenchimento ATB e reduz o **tempo de deslocamento definido em cada ficha de Move**, inclusive por efeitos que aumentam AGI. Calibrar valores inicialmente contra ritmo atual. Preservar a influência dos passos táticos e o piso da D-018; **a fórmula combinada, os coeficientes, a referência de ATB e o tratamento de limites ainda não foram definidos**.
5. **Sorte versus esquiva fixa (D-127 × D-005):** a D-005 fixou esquiva automática em **10% por golpe** para todos, valor **ainda implementado**. A decisão posterior D-127 **aprova que Sorte altere essa probabilidade**, além de crítico e chances de aplicação de status. A universalidade da porcentagem fixa passa a ser histórica neste ponto, mas **não se estabelece novo valor/fórmula**. A reação de IA durante trajeto segue outra regra (D-021).
6. **Sorte e status versus D-012:** um Move de debuff de alvo único **não ser esquivável** permanece verdadeiro. A probabilidade de um efeito de status ser aplicado é uma etapa distinta; a resposta 8C **não especifica quais efeitos são garantidos e quais possuem testes de aplicação**. Não converter todas as aplicações garantidas para chances de falha silenciosamente.
7. **Crescimento do protagonista e teto (D-129 versus GDD R13-Q4/R14-Q4):** distribuir 1 ponto de atributo a cada nível continua obrigatório, mas o limite permanente 100 exige regra para quando não existe atributo elegível para receber o ponto. A decisão não autoriza perder, guardar ou redirecionar automaticamente o excedente.

### 33.3 Diferenças verificadas no código atual

- `scripts/combat/combatant.gd` ainda usa `base_attack`, `base_speed`, `max_hp`, fraquezas e buffs de ATK/DEF/Velocidade; os cinco atributos permanentes e suas fichas por espécie **não foram integrados**.
- `scripts/combat/battle.gd` aplica chance fixa de crítico `0.10` e de esquiva automática `0.10`, e `travel_seconds()` considera a duração-base e a posição tática sem AGI; D-126/D-127 ainda não estão implementadas.
- `scripts/data/skill.gd` não especifica tempo de deslocamento individual em campo de ficha nem escala de efeito mágico por Move; D-119/D-123 são requisitos documentais.
- `scripts/data/element.gd` contém 11 elementos atuais e não foi modificado.

### 33.4 Pormenores técnicos ainda não aprovados

- Valores iniciais e curvas individuais de cada espécie, amplitude e distribuição das variações aleatórias; escalas das fórmulas físicas/mágicas, Vitalidade/HP/defesa, Magia/efeitos e impacto quantitativo das Natures.
- Integração matemática entre AGI, duração individual por Move e posicionamento tático sem quebrar o piso histórico; calibração de ATB.
- Probabilidades de crítico, esquiva automática e aplicação de status derivadas da Sorte, efeitos de status garantidos versus rolados, tratamento do limiar e do teto de atributos permanentes.
- As dez respostas fecham **direções de design**, não os detalhes numéricos; não há autorização para inventar coeficientes ou implementar código.

### 33.5 Escopo

Dez arquivos individuais de decisões, índice e regras consolidadas atualizados. O documento histórico D-005 recebe somente nota aditiva sobre a regra posterior de Sorte; D-117/D-118/D-119 e outras decisões permanecem intactas. Nenhum código, dado de Move/personagem, VFX, teste ou configuração alterado.

---

## 34. Novo atributo Spirit e nomes de atributos em inglês

Referências diretas: [D-130](decisoes/D-130-separacao-vitality-fisico-spirit-magico.md) e [D-131](decisoes/D-131-nomes-atributos-em-ingles.md).

> **2026-11-03.** O criador determinou a separação da defesa física e mágica, pediu um **novo atributo com nome inglês e sigla de três letras** e exigiu nomes de atributos em inglês. O assistente, autorizado a escolher o nome, selecionou **Spirit (SPI)**. A alteração do catálogo foi registrada em D-130 e D-131, sem modificar código. O questionário da Rodada 55 continua com as perguntas remanescentes.

### 34.1 Catálogo atualizado — seis atributos permanentes

| Attribute | Abbr. | Papel principal |
|---|---|---|
| **Strength** | **STR** | Base de dano físico |
| **Magic** | **MAG** | Base de dano mágico/especial; efeitos escaláveis definidos por Move; MP máximo conforme regra existente |
| **Vitality** | **VIT** | **Mitigação apenas de dano físico** e HP máximo derivado de Vitality+nível+espécie |
| **Spirit** | **SPI** | **Mitigação de dano mágico/especial**, analogamente à mitigação física por Vitality |
| **Agility** | **AGI** | Regeneração ATB e tempo individual de deslocamento dos Moves |
| **Luck** | **LUK** | Crítico, esquiva automática e chance de aplicação de status |

### 34.2 Conciliação com histórico e regras previamente aprovadas

1. **D-120, D-125, D-129 e GDD R10-Q1:** o antigo conjunto de **cinco** atributos foi **expressamente ampliado para seis**. A antiga vedação a um segundo atributo de defesa natural dá lugar ao novo **Spirit**, com domínio exclusivo mágico. Preservar redações anteriores como histórico; seguir D-130/D-131 no design atual.
2. **D-124:** Vitality mantém o cálculo do HP máximo; a restrição 'apenas para dano físico' descreve a **mitigação**, sem aprovar mudança de HP. Spirit **não** recebe função em HP ou MP por analogia.
3. **D-122/D-123:** Strength e Magic continuam atributos **ofensivos**, distintos de Vitality e Spirit **defensivos**.
4. **D-125:** os estágios de Defense atuais continuam existindo. A nova divisão VIT/SPI não especifica se os estágios de DEF se aplicam a ambos os tipos de dano, nem sua fórmula, sem decisão ulterior.
5. **D-129:** faixa permanente **1–100** agora abrange seis atributos; buffs temporários continuam separados. A quantidade de **1 ponto obrigatório por nível** para o protagonista não foi aumentada.
6. **D-131:** os nomes usados nos atributos da **ficha e UI** devem estar em inglês: STR/MAG/VIT/SPI/AGI/LUK. Não reescrever citações históricas e não presumir renomeação de Moves/efeitos de status fora da ficha.

### 34.3 Pendências expressas

- Fórmula, coeficiente, teto e interação dos estágios de Defesa com mitigação física (VIT) e mágica (SPI).
- Crescimento/variação individual de Spirit e sua participação na distribuição obrigatória por nível; curva das espécies.
- Se novos Moves/buffs de Spirit poderão alterar o atributo temporariamente; sem criar novo Move ou status automaticamente.
- As perguntas da Rodada 55 sobre variação individual, AGI+passos, aplicação probabilística de status e teto da progressão continuam abertas. A antiga pergunta sobre se VIT reduz dano mágico foi respondida pela nova regra: **não**, quem reduz dano mágico é SPI.

### 34.4 Escopo

Dois documentos novos (D-130/D-131), quatro notas posteriores em decisões históricas, índice e consolidado atualizados. **Nenhum código, jogo, UI, VFX, dado ou teste foi modificado.**

---

## 35. Rodada 55 — variação individual, AGI e posicionamento, LUK em status e teto de atributos

> **2026-11-03.** Respostas expressas do criador: **1A, 2A, 3A, 5A**. A antiga questão **4** não foi reapresentada porque o criador já aprovou a separação defensiva: **Vitality (VIT) mitiga apenas dano físico; Spirit (SPI) mitiga dano mágico** (D-130/D-131). As quatro novas escolhas estão documentadas individualmente em D-132 a D-135. Apenas documentação foi atualizada; nenhuma implementação foi autorizada.

### 35.1 Matriz de escolhas aprovadas

| Referência | Escolha | Regra aprovada |
|---|---|---|
| [D-132](decisoes/D-132-r55-q1-variacao-individual-mais-menos-3.md) | 1A | Até ±3 pontos por atributo-base, sorteados uma vez e persistentes. |
| [D-133](decisoes/D-133-r55-q2-agi-antes-passos-tempo-move.md) | 2A | Reduzir primeiro o tempo do Move por AGI; depois aplicar o ajuste dos passos, respeitando o mínimo aprovado. |
| [D-134](decisoes/D-134-r55-q3-luk-somente-status-com-chance.md) | 3A | LUK modifica apenas efeitos cuja ficha declare chance de aplicação; efeitos garantidos continuam garantidos. |
| [D-135](decisoes/D-135-r55-q5-seis-atributos-no-teto-sem-distribuicao.md) | 5A | Dispensar excepcionalmente a distribuição quando todos os atributos estiverem no limite. |

### 35.2 Compatibilidade e limites concretos

1. **Variação D-121/D-132:** sortear **uma única vez por indivíduo e persistir** modificadores de **até ±3 pontos por atributo-base**, agora para os seis atributos oficiais STR, MAG, VIT, SPI, AGI, LUK. A faixa final **1–100 (D-129)** permanece; escolha de *clamp* ou novo sorteio nos limites e distribuição de probabilidade não foram aprovadas.
2. **AGI D-018/D-117/D-119/D-126/D-133:** primeiro reduzir **o tempo próprio da ficha de cada Move** pela AGI do Pokémon e pelos efeitos que a aumentam; depois aplicar o ajuste posicional **−0,10 s × (passo do atacante + passo do alvo)** da D-018; finalmente respeitar mínimo **0,25 s**. A curva quantitativa de AGI **não foi definida**; o valor de referência ATB e a calibração continuam pendentes.
3. **LUK D-012/D-127/D-134:** LUK pode modificar **apenas efeitos de status com chance explicitamente declarada** na ficha. Efeitos garantidos continuam com aplicação garantida, sem nova rolagem por LUK. A decisão **não** elimina a influência de LUK em crítico e esquiva automática; **não** torna debuffs de alvo único esquiváveis.
4. **Progressão D-129/D-130/D-131/D-135:** a distribuição obrigatória de 1 ponto pelo protagonista ao subir de nível é **dispensada somente quando todos os seis atributos permanentes estão em 100**. O nível continua avançando. Não inventar pontos compensatórios, conversão ou armazenamento dos pontos dispensados; o crescimento automático de aliados permanece conforme decisões anteriores.
5. **Separação defensiva D-130/D-131 mantida:** VIT para mitigação física e HP máximo; SPI para mitigação mágica. A questão 4 da rodada anterior foi respondida por decisão própria e não recebeu documento repetido nesta rodada.

### 35.3 Diferenças em relação ao código verificado

- `scripts/combat/battle.gd` calcula duração de trajeto considerando tempo-base e passos (`TRAVEL_PER_STEP = 0.10`, `TRAVEL_MIN = 0.25`), **sem primeiro aplicar AGI** como D-133 exige.
- `scripts/data/skill.gd` ainda não declara explicitamente um campo de tempo de deslocamento próprio de cada Move, nem chance de aplicação por efeito; essas especificações continuam requisitos não implementados.
- `scripts/combat/combatant.gd` ainda não contém os seis atributos permanentes, suas variações individuais persistentes nem a lógica de progressão do protagonista.
- Crítico e esquiva automática ainda usam probabilidades fixas no código de combate (D-127 e D-134 são decisões de design não implementadas).

### 35.4 Decisões ainda pendentes, sem extrapolação

- Formato da distribuição de probabilidade para ±3 e como preservar 1–100 quando o sorteio excederia o teto/piso; momento exato da geração do indivíduo.
- Fórmula da redução do tempo do Move por AGI, valores de referência, arredondamento e interação detalhada com buffs; a **ordem** foi fixada nesta rodada.
- Probabilidade-base dos efeitos de status não garantidos, contribuição de LUK e definição das fichas de Moves.
- Tratamento de ganhos automáticos que ultrapassam 100 em aliados, além do caso especial de pontos do protagonista.

### 35.5 Escopo

Quatro decisões novas (D-132 a D-135), cinco notas aditivas aos documentos antigos (D-121, D-119, D-126, D-127 e D-129), índice e consolidado atualizados. **Sem edição de código, testes, VFX, fichas ou assets.**

---

## 36. Rodada 56 — AGI inversa, diferença de LUK, Defense abrangente; teto em conflito

> **2026-11-03.** O criador escolheu expressamente **2A, 3B e 4A**. Também respondeu **1D — Outra regra**, acrescentando a observação literal: **“n tem problema ultrapassar 100 de status, n precisa se preocupar com isso”**. A questão 1 está **em conflito de escopo com D-129 e D-135**; o significado da exceção a 100 não pode ser fixado sem esclarecer se é restrita ao sorteio ±3 ou se revoga o teto de todos os atributos permanentes. Para preservar decisões anteriores, **nenhuma regra nova sobre ultrapassar 100 é declarada aprovada nesta seção**. Documentos individuais D-136, D-137 e D-138 registram apenas 2A/3B/4A.

### 36.1 Decisões aprovadas e documentadas

| Documento | Escolha | Regra |
|---|---|---|
| [D-136](decisoes/D-136-r56-q2-agi-inversamente-proporcional.md) | 2A | Usar proporcionalidade inversa à AGI efetiva, com uma AGI de referência comum a todos os Pokémon. |
| [D-137](decisoes/D-137-r56-q3-diferenca-luk-aplicador-alvo.md) | 3B | A diferença entre a LUK de quem aplica e a LUK de quem recebe influencia a chance. |
| [D-138](decisoes/D-138-r56-q4-defense-estagios-fisico-magico.md) | 4A | Manter os estágios atuais de Defense afetando dano físico e mágico, enquanto VIT e SPI fornecem resistências naturais separadas. |

### 36.2 Conciliação com decisões anteriores

1. **D-136 / D-117 / D-119 / D-133 / D-018:** tempo individual de Move é reduzido **inversamente à AGI efetiva**, referenciada por um valor comum entre as espécies. Depois, descontar **0,10 s × soma dos passos**, mantendo mínimo **0,25 s**. Não definir numericamente a AGI de referência, arredondamento ou o caso AGI ≤ 0.
2. **D-137 / D-127 / D-134 / D-012:** a chance de **aplicação de status probabilístico** depende da **diferença entre LUK do aplicador e do alvo**. Apenas efeitos com chance declarada na ficha são afetados; efeitos garantidos continuam garantidos. Não criar Evade para debuffs de alvo único, nem definir fórmula percentual arbitrária.
3. **D-138 / D-125 / D-130 / D-131:** os estágios existentes de **Defense** atuam tanto sobre dano físico como mágico, mas a resistência **natural** usa **VIT apenas para físico** e **SPI apenas para mágico**. Buffs não são automaticamente divididos em duas categorias.

### 36.3 Conflito não resolvido — R56-Q1D

- **Mensagem literal:** “1D — O que fazer se a variação de ±3 ultrapassar o limite 1–100? Outra regra.” **Observação:** “n tem problema ultrapassar 100 de status, n precisa se preocupar com isso”.
- **D-129:** os seis atributos permanentes têm limite de **1–100**. **D-132:** sorteio persistente de até ±3 pontos por atributo. **D-135:** quando todos os seis estão em 100, dispensa-se a distribuição obrigatória na subida de nível. Uma permissão geral para ultrapassar 100 modificaria **D-129 e D-135**; uma exceção somente ao sorteio individual modificaria **D-129/D-132** mas não necessariamente a regra de progressão.
- **Duas interpretações plausíveis:** (A) apenas a **variação inicial de ±3** pode deixar o atributo temporária ou permanentemente acima de 100, preservando o teto para progressão; (B) o teto 100 deixa de existir como limite geral, inclusive para o crescimento por nível. O criador **não especificou qual alcance**. Nenhuma delas foi selecionada por este registro.
- **Ação pendente:** perguntar objetivamente qual alcance da ultrapassagem de 100 deve prevalecer; preservar ambas as fontes históricas, sem remendar a D-129 nem a D-135 por suposição.

### 36.4 Código consultado e escopo

- `scripts/combat/battle.gd`: `travel_seconds()` ainda desconta apenas passos e impõe piso de 0,25 s; não possui redução inversamente proporcional por AGI.
- `scripts/data/skill.gd`: não há campo formal de tempo individual de Move nem chance de aplicação por efeito.
- `scripts/combat/combatant.gd`: `def_buff` é aplicado genericamente em `take_damage()`, sem campos de VIT/SPI; não há fórmulas de LUK e progressão ainda integradas.
- **Somente documentação:** 3 novas decisões D-136..D-138, 4 complementos históricos, índice e regras consolidadas. Nenhuma mudança em código, cenas, dados, assets, VFX, testes ou configuração.

---

## 37. Rodada 57 — atributos sem teto, AGI mínima, sorteio central e coeficiente de LUK

> **2026-11-03:** o criador aprovou **1B, 2A, 3B e 4B**. A resposta 1B resolveu expressamente a ambiguidade da Rodada 56: o limite máximo permanente de 100 é abolido, inclusive para progressão, Nature e variações individuais. Regras individuais D-139 a D-142; preservado o histórico.

### 37.1 Decisões aprovadas

| Decisão | Escolha | Regra |
|---|---|---|
| [D-139](decisoes/D-139-r57-q1-atributos-sem-teto-100.md) | 1B | Atributos permanentes podem ultrapassar 100 sem teto máximo |
| [D-140](decisoes/D-140-r57-q2-agi-minimo-1-formula.md) | 2A | AGI efetiva mínima de 1 apenas para o cálculo inverso do Move |
| [D-141](decisoes/D-141-r57-q3-sorteio-individual-central.md) | 3B | Distribuição do sorteio individual favorece valores perto de zero |
| [D-142](decisoes/D-142-r57-q4-luk-1pp-cada-10.md) | 4B | Status probabilístico: 1 ponto percentual para cada 10 pontos de diferença LUK |

### 37.2 Relação explícita com D-129 e D-135

- **D-129:** o limite permanente de **100** está **revogado** pela D-139. Não inventar limite substituto. A separação entre buffs temporários e atributos permanentes continua; a escala de valores-base de referência 1–100 não foi expressamente alterada.
- **D-135:** a dispensa obrigatória de 1 ponto por nível só ocorria se todos os atributos estivessem **no teto de 100**. **Sem teto permanente**, o pré-requisito da exceção deixou de existir; a dispensa baseada no antigo teto **fica superada**. O protagonista continua distribuindo 1 ponto obrigatoriamente a cada nível, mesmo se os seis atributos forem exatamente 100. O texto da D-135 continua preservado como histórico.
- **D-132/D-141:** variações individuais inteiras de −3 até +3 persistentes; distribuição favorece valores perto de zero, ±3 mais raros. Um atributo pode passar de 100; pesos e simetria não foram definidos.

### 37.3 Fórmulas parciais e pendências

- **D-140/D-136/D-133/D-018:** ao calcular a duração do trajeto por proporcionalidade inversa, utilizar AGI efetiva mínima **1 para essa operação**, sem modificar o atributo. Referência AGI comum ainda sem número. Aplicar depois a correção posicional `−0,10 s × soma de passos`; mínimo final `0,25 s`. Nenhuma alteração automática da regra de ATB.
- **D-142/D-137/D-134:** apenas efeitos de status com chance declarada recebem correção pela diferença LUK(aplicador) − LUK(alvo), à razão de **1 ponto percentual a cada 10 pontos LUK**. Exemplo aprovado **40% + 3 pp = 43%** com +30 LUK. Efeitos garantidos continuam garantidos; nenhuma esquiva nova. Arredondamento/interpolação de diferenças não múltiplas de 10 e limites da chance calculada permanecem pendentes.
- **Crescimento e integração:** não foram especificados pesos estatísticos para o sorteio, fórmulas de evolução por espécie/Nature, valor da AGI de referência nem políticas de apresentação de atributos elevados.

### 37.4 Código consultado e escopo de edição

- `scripts/combat/battle.gd` ainda usa tempo de trajeto com passos e mínimo de 0,25 s, sem AGI; chances de crítico e esquiva permanecem fixas no código.
- `scripts/combat/combatant.gd` ainda usa atributos simplificados, não os seis atributos permanentes e progressão; `scripts/data/skill.gd` não possui ficha de chance de status por efeito.
- **Somente documentação:** quatro documentos D-139..D-142 criados, notas aditivas em D-129, D-135, D-132, D-136, D-137, índice e consolidado atualizados. Nenhum código, teste, cena, Move ou asset alterado.

---

## 38. Rodada 58 — probabilidades válidas, sorteio triangular e referências distintas de AGI

> **2026-11-03.** O criador aprovou diretamente as alternativas **2A, 3A e 4B**. Também respondeu **1D — Outra regra**, acompanhada da observação literal: **“não entendi a 1, 50% + 7 luck = 57% - 10luck do oponente = 47% de chance no total”**. Como ela contradiz o fator da D-142 sem indicar expressamente se está revogando a regra, **a questão 1 permanece pendente de esclarecimento**; nenhuma fórmula nova de LUK foi consolidada como aprovada. D-143, D-144 e D-145 registram somente as três escolhas inequívocas.

### 38.1 Regras expressamente aprovadas

| Documento | Escolha | Regra |
|---|---|---|
| [D-143](decisoes/D-143-r58-q2-probabilidade-status-0-100.md) | 2A | Probabilidade final de status limitada ao intervalo 0–100% |
| [D-144](decisoes/D-144-r58-q3-sorteio-triangular-1-2-3-4-3-2-1.md) | 3A | Sorteio individual triangular com pesos 1:2:3:4:3:2:1 |
| [D-145](decisoes/D-145-r58-q4-referencias-agi-distintas-atb-trajeto.md) | 4B | Referências numéricas distintas para ATB e trajetos com AGI única |

### 38.2 Compatibilidade e restrições

- **D-143 (Q2A):** a chance final de aplicação de status probabilístico deve ser limitada ao intervalo **0% a 100%**, inclusive, após os modificadores. Exemplo: 98% + 5 pp = 103% intermediários ⇒ **100% final**. Efeitos garantidos continuam garantidos (D-134). Este limite não restringe atributos acima de 100 (D-139).
- **D-144 (Q3A):** sorteio individual persistente de −3 a +3 (D-132) segue a distribuição triangular discreta com pesos **1:2:3:4:3:2:1**, equivalentes a **6,25%, 12,5%, 18,75%, 25%, 18,75%, 12,5%, 6,25%**. Não redefinir os pontos-base ou adicionar teto numérico.
- **D-145 (Q4B):** **AGI permanece atributo único** com referências numéricas **independentes para ATB e tempo de trajeto**, de modo a calibrar os subsistemas separadamente. A referência de trajeto permanece **comum a todos os Pokémon** (D-136); nenhuma das referências recebeu valor numérico. Preservar D-140 e D-018/D-133.

### 38.3 Conflito pendente — Q1D × D-142

- **Nova expressão literal:** “não entendi a 1, 50% + 7 luck = 57% - 10luck do oponente = 47% de chance no total”. Ela descreve adição de **7 pontos percentuais por LUK 7** e subtração de **10 pontos percentuais por LUK 10**.
- **D-142, aprovada expressamente na Rodada 57:** chance de aplicação recebe **1 ponto percentual a cada 10 pontos de diferença LUK** entre aplicador e alvo. Com base 50%, LUK 7 contra LUK 10, uma aplicação proporcional contínua desse coeficiente teria **50% + (7 − 10)/10 pp = 49,7%**. O tratamento de diferenças não múltiplas de 10 continua não definido em D-142.
- **Pergunta de esclarecimento obrigatória:** o novo exemplo pretende **substituir a proporção da D-142 por 1 ponto percentual por 1 ponto de LUK de diferença** (resultado 47%), ou a D-142 permanece com 1 ponto percentual por 10 LUK (49,7% caso interpolação proporcional)? Não optar silenciosamente.
- **D-143 não depende da escolha da taxa:** qualquer chance calculada, conforme a regra final que o criador definir, deve ser limitada a **0%–100%**. O conflito da Q1 não invalida as escolhas 2A, 3A e 4B.

### 38.4 Código verificado e escopo

- `scripts/combat/battle.gd` mantém chances atuais de crítico/esquiva e tempo de trajeto sem aplicação da AGI dos seis atributos.
- `scripts/combat/combatant.gd` não implementa variações individuais persistentes de atributos; `scripts/data/skill.gd` não implementa chance de status declarada por efeito.
- **Editados apenas documentos:** três novos D-143..D-145, notas aditivas em D-141, D-136 e D-142, índice e este consolidado. Nenhum código, asset, dado de Pokémon, configuração ou teste alterado.

---

## 39. Rodada 59 — LUK corrigida, variações independentes, duração de trajeto fixa

> **2026-11-03.** Escolhas expressas do criador: **1A, 2A e 3A**. Três novas decisões individuais D-146 a D-148. As regras aprovadas não autorizam alterar código, fichas de Move, VFX, assets ou configurações.

### 39.1 Matriz das decisões

| Documento | Escolha | Regra aprovada |
|---|---|---|
| [D-146](decisoes/D-146-r59-q1-luk-um-ponto-percentual-por-ponto.md) | 1A | Aplicação de status: 1 ponto percentual por ponto da diferença de LUK |
| [D-147](decisoes/D-147-r59-q2-sorteios-independentes-seis-atributos.md) | 2A | Sorteios individuais independentes nos seis atributos |
| [D-148](decisoes/D-148-r59-q3-duracao-trajeto-fixa-ao-iniciar-ataque.md) | 3A | Duração de trajeto calculada no início do ataque e fixa até seu término |

### 39.2 Conciliação expressa com decisões anteriores

1. **D-146 substitui a taxa da D-142:** a D-142 dizia **1 ponto percentual por 10 pontos da diferença LUK**. A escolha expressa 1A desta Rodada 59 substitui essa escala por **1 ponto percentual por ponto de diferença LUK** entre aplicador e alvo. **Exemplo aprovado:** chance-base 50%, LUK 7 e LUK 10 => **50% + 7 pp − 10 pp = 47%**. O conflito apontado na seção 38.3 foi **resolvido nesta rodada**, sem alterar retroativamente o registro do conflito.
2. **D-134/D-137/D-143 preservadas:** só efeitos de status com chance declarada na ficha do Move sofrem o ajuste por LUK. Efeitos garantidos continuam garantidos; a chance final de aplicação probabilística permanece **limitada a 0–100%**. Status não esquiváveis não ganham Evade por esta regra (D-012).
3. **D-147 complementa D-132/D-144:** os seis atributos **STR, MAG, VIT, SPI, AGI e LUK** têm sorteios **independentes entre si**, todos com modificadores individuais −3..+3 e pesos triangulares **1:2:3:4:3:2:1**. Cada atributo é sorteado uma única vez por indivíduo e persistido. A variação de outro atributo não altera a probabilidade de um dado resultado.
4. **D-148 complementa D-119/D-133/D-136/D-140/D-145:** a duração do trajeto é **calculada ao iniciar o ataque e mantida fixa até o fim do trajeto**. AGI e efeitos aplicáveis entram no cálculo, que mantém o ajuste posicional posterior e o mínimo de **0,25 s**. Mudanças posteriores de AGI durante o trajeto não recalculam sua duração. **Pendente:** determinar qual instante técnico do fluxo WINDUP/TRAVEL significa 'iniciar o ataque', quando essa distinção impactar implementação.

### 39.3 Pendências restantes (não aprovadas automaticamente)

- **LUK em crítico e esquiva automática:** D-127 diz que LUK influencia ambas, mas coeficientes e limites próprios não foram aprovados. A escala da D-146 aplica-se especificamente à **chance de status probabilístico**, não é uma tabela automática para todos os eventos.
- **AGI:** valores numéricos de referência para ATB e trajetos (D-145), tratamento de buffs durante WINDUP antes do travamento do trajeto (D-148) e calibração concreta de velocidade.
- **Sorteio/persistência:** quais dados persistentes e algoritmo de seed/ordem são necessários para reproduzir resultados (D-147); independência estatística foi definida, mas a implementação não.
- **Mitigação VIT/SPI:** fórmulas quantitativas continuam por decidir, preservando a aplicação comum dos estágios de Defense (D-138).

### 39.4 Estado verificado do código e escopo

- `scripts/combat/attack_planner.gd`: as durações e cronogramas são planejados em torno da transição de fases após WINDUP; a lógica existente ainda não integra AGI efetiva ao tempo do trajeto nem contém os atributos permanentes do novo modelo.
- `scripts/combat/battle.gd` mantém o ajuste por passos e o piso de 0,25 s, mas não aplica a redução inversa por AGI nem a fórmula LUK aprovada.
- `scripts/data/skill.gd` ainda não declara chances de aplicação por efeito nem o tempo individual de deslocamento como campo próprio.
- **Escopo desta alteração:** três D novos (D-146 a D-148), quatro notas complementares (D-119/D-142/D-143/D-144), índice e consolidado atualizados. **Somente documentação; nenhum código, teste, cena, VFX ou modelo alterado.**


---

## 40. Rodada 60 — recálculo excepcional do trajeto, crítico por LUK e limites

> **2026-11-03.** O criador escolheu **1A, 2B, 3D e 4A**. As decisões **1A, 2B e 4A** estão determinadas sem ambiguidade e foram registradas em **D-149 a D-151**. A questão **3D** contém direção de design, mas não fórmula matemática inequívoca; sua escolha alternativa e observação literal foram preservadas como **pendência**, sem transformá-las em regra numérica.

### 40.1 Matriz de decisões aprovadas

| Documento | Questão | Regra aprovada |
|---|---|---|
| [D-149](decisoes/D-149-r60-q1-recalculo-unico-trajeto-na-troca-de-alvo.md) | 1A | Quando o alvo morre no wind-up, recalcular **uma vez no evento de troca automática** da D-108 e manter a nova duração fixa até o fim do trajeto |
| [D-150](decisoes/D-150-r60-q2-critico-luk-um-ponto-percentual.md) | 2B | Crítico probabilístico com **10% de base + 1 pp por ponto de diferença de LUK (atacante − alvo)** |
| [D-151](decisoes/D-151-r60-q4-limites-critico-esquiva-automatica.md) | 4A | Probabilidades finais de crítico e esquiva automática limitadas ao intervalo **0%–100%** |

### 40.2 Conciliação e exemplos

1. **D-108 × D-148 → D-149:** preservar o cálculo de duração fixo ao iniciar o ataque como regra geral da D-148; se houver morte do alvo e redirecionamento automático **durante wind-up**, fazer **uma exceção com um novo cálculo no momento da troca**. Exemplo: Gible muda o ataque de Pancham para Abra após a morte de Pancham no wind-up; a duração do trajeto é recalculada para essa troca, não continuamente durante TRAVEL. Não definir aqui uma política para múltiplas trocas subsequentes.
2. **D-127 × D-150:** LUK modifica agora o crítico normal em **1 ponto percentual por ponto de diferença**. Com **LUK atacante 70** e **LUK alvo 40**, a chance é **10% + (70 − 40) pp = 40%**. A escala é própria de crítico e não autoriza copiá-la para esquiva automática.
3. **D-151 × D-143 × D-139:** crítico e esquiva automática adotam limites finais **0–100%**, assim como aplicação probabilística de status (D-143); isso não cria teto para atributos LUK, que podem ultrapassar 100 (D-139).
4. **D-005 e D-021:** **10%** continua como valor-base histórico/atual da esquiva automática por golpe; reação ativa da IA durante trajetória tem outra mecânica e não foi alterada.
5. **D-134 e regras de crítico garantido:** não introduzir rolagem em efeitos de status garantidos nem converter críticos expressamente garantidos em eventos probabilísticos.

### 40.3 R60-Q3D — observação preservada, fórmula pendente

- **Escolha literal:** “3D — Como LUK deve modificar a esquiva automática? Outra regra.”
- **Observação literal:** “3 - diferente de critico, a evasiva reduz quanto maior fica, dividindo pela metade”.
- **Ambiguidade material:** “dividindo pela metade” pode se referir a um **ganho fixo pela metade em comparação com crítico**, ou a um **ganho que decai progressivamente conforme a LUK aumenta**, entre outras interpretações. Não aprovar nenhuma delas sem resposta do criador.
- **Pendente:** coeficiente/função para esquiva automática, tratamento de diferenças negativas, instante técnico para congelar a duração em WINDUP/TRAVEL, e eventual política de trocas sucessivas de alvo.

### 40.4 Escopo

Apenas D-149, D-150 e D-151, índice, este consolidado e adendo de rastreabilidade no GDD foram modificados. **Nenhum código, teste de gameplay, cena, ficha de Move, asset ou VFX foi alterado.** A execução do design continua não verificada no jogo.


---

## 41. Rodada 61 — curva de esquiva, captura no WINDUP, retarget sucessivo e LUK dinâmica

> **2026-11-03.** Respostas explícitas **1B, 2A, 3A, 4A e 5A**, sem observações adicionais. Todas são registradas em D-152 a D-156. Os textos históricos das Rodadas 59–60 e os conflitos então pendentes permanecem documentados, mas estas escolhas encerram as pendências específicas indicadas abaixo.

### 41.1 Matriz de escolhas

| Documento | Escolha | Regra |
|---|---|---|
| [D-152](decisoes/D-152-r61-q1-esquiva-luk-retorno-decrescente.md) | 1B | Chance-base de 10% de esquiva automática + contribuição por LUK com ganhos marginais 1, 0,5, 0,25, 0,125... pp por ponto a cada faixa adicional de 10 |
| [D-153](decisoes/D-153-r61-q2-esquiva-luk-curva-simetrica.md) | 2A | Diferença negativa de LUK reduz a chance pela mesma curva aplicada em sentido positivo, limitada pela D-151 |
| [D-154](decisoes/D-154-r61-q3-trajeto-calculo-inicio-windup.md) | 3A | Calcular e fixar a duração do trajeto ao **entrar efetivamente em WINDUP**, ressalvadas trocas de alvo |
| [D-155](decisoes/D-155-r61-q4-trajeto-recalculo-cada-troca-windup.md) | 4A | Recalcular uma vez **em cada** troca automática durante WINDUP |
| [D-156](decisoes/D-156-r61-q5-luk-no-instante-da-rolagem.md) | 5A | Consultar a LUK efetiva no instante da resolução de **cada evento probabilístico** |

### 41.2 Curva de esquiva aprovada — D-005, D-127, D-151, D-152 e D-153

Definir **Δ = LUK_defensor − LUK_atacante** e **F(x)** como a soma de contribuições sobre as faixas sucessivas de até dez pontos de **|Δ|**: taxa **1 pp/ponto** para os primeiros dez, **0,5 pp/ponto** para os próximos dez, **0,25 pp/ponto** para os próximos dez, e assim sucessivamente, reduzindo o ganho marginal à metade em cada faixa. Para Δ positivo somar F(|Δ|); para Δ negativo subtrair F(|Δ|); para Δ zero não aplicar correção.

**P_esquiva = clamp(10% + sinal(Δ) × F(|Δ|), 0%, 100%)**.

| LUK defensor | LUK atacante | Δ | Correção | Chance final |
|---:|---:|---:|---:|---:|
| 40 | 40 | 0 | 0 pp | 10% |
| 45 | 40 | +5 | +5 pp | 15% |
| 70 | 40 | +30 | +17,5 pp | 27,5% |
| 40 | 70 | −30 | −17,5 pp | 0% |
| 40 | 45 | −5 | −5 pp | 5% |

Exemplos baseados nas escolhas da Rodada 61. A fórmula do **crítico** continua **10% + 1 pp/ponto da diferença LUK atacante − alvo** (D-150); a fórmula de **status probabilístico** continua **chance-base + 1 pp/ponto de diferença LUK aplicador − alvo** (D-146). Todas as chances finais respeitam os respectivos limites de **0–100%**. Evade manual/perfeito e reação ativa da IA dentro do trajeto (D-021) **não recebem esta curva**; preservar status não esquiváveis (D-012).

### 41.3 Tempo do trajeto e trocas automáticas — D-108, D-148, D-149, D-154 e D-155

- O instante técnico da expressão “ao iniciar o ataque” é **a entrada efetiva em WINDUP**. Calcular a duração do Move nesse instante com AGI aplicável, passos e mínimo temporal já aprovados.
- Uma morte de alvo durante WINDUP pode disparar redirecionamento para o adversário vivo mais próximo (D-108). **Cada troca efetiva durante essa fase provoca um único recálculo**, substituindo a duração previamente congelada.
- Exemplo: cálculo inicial contra Pancham ao entrar em WINDUP; morte de Pancham → alvo Abra → novo cálculo; morte de Abra ainda no WINDUP → alvo Gible → novo cálculo. Ao entrar em TRAVEL, **a última duração calculada permanece fixa até seu término**.
- As exceções de morte do último inimigo, projéteis em voo e morte após iniciar investida são preservadas; não criar loop de recálculo durante TRAVEL.
- **Pendente distinto:** política para Moves instantâneos que dispensam WINDUP; empate geométrico entre alvos igualmente próximos.

### 41.4 Captura de LUK por evento — D-146, D-150, D-152, D-153 e D-156

- **Crítico normal, esquiva automática e aplicação de status probabilístico:** consultar LUK efetiva de cada participante **no instante da resolução da respectiva rolagem**, não na declaração do ataque nem na captura da AGI do trajeto.
- Exemplo: LUK atacante 40 na declaração, 50 na transição para TRAVEL e 60 no impacto, contra LUK alvo 40 no impacto → **30% de crítico normal**, se a rolagem ocorrer então. Isso não altera efeitos garantidos.
- Não recalcular eventos já resolvidos; não determinar ordem de resolução para eventos simultâneos sem nova decisão.

### 41.5 Escopo e pendências restantes

- As pendências históricas **R60-Q3D, diferenças negativas, instante WINDUP e múltiplas trocas sucessivas** receberam respostas nas D-152 a D-155, preservando os registros originais como histórico.
- Permanecem sem definição: regra para ataque sem WINDUP; empate na escolha do alvo vivo mais próximo; ordem de resolução para eventos simultâneos; referências numéricas de AGI para ATB e trajeto (D-145); calibração de fórmulas quantitativas ainda não aprovadas.
- **Somente documentação**: novos arquivos D-152–D-156, índice, este consolidado e adendo do GDD. Sem mudanças de código, testes, modelos, recursos ou VFX.


---

## 42. Rodada 62 — Moves instantâneos, desempate determinístico, ordenação de LUK e calibração AGI

> **2026-11-03.** O criador escolheu expressamente **1A, 2A, 3A, 4A e 5B**, sem observações adicionais. Decisões individuais [D-157 a D-161](decisoes/README.md). **A escolha 5B registra um adiamento explícito**: a referência de ATB continua não especificada. Os históricos das seções 40 e 41 permanecem intocados.

### 42.1 Registro por questão

| Documento | Escolha | Conteúdo aprovado |
|---|---|---|
| [D-157](decisoes/D-157-r62-q1-trajeto-instantaneo-inicio-execucao.md) | 1A | Move instantâneo **sem WINDUP**: se houver trajeto, calcular sua duração **no início da execução efetiva do Move**, sem criar WINDUP |
| [D-158](decisoes/D-158-r62-q2-desempate-alvo-identificador-estavel.md) | 2A | Empate entre inimigos vivos igualmente próximos no redirecionamento da D-108: desempate pelo **identificador estável de combate**, reproduzível no mesmo estado |
| [D-159](decisoes/D-159-r62-q3-ordem-deterministica-luk.md) | 3A | Resolver eventos numa **ordem determinística única da linha do tempo**; modificações de LUK anteriores à rolagem entram, posteriores não |
| [D-160](decisoes/D-160-r62-q4-referencia-agi-50-trajetos.md) | 4A | Adotar **AGI de referência 50** para duração dos **trajetos**, comum às espécies |
| [D-161](decisoes/D-161-r62-q5-referencia-atb-pendente-avaliacao.md) | 5B | **Adiar** valor numérico de referência para regeneração ATB até avaliar o ritmo de combate; nenhum número escolhido |

### 42.2 Exemplos e limites operacionais

1. **D-157 × D-154:** Move com WINDUP captura o tempo ao entrar efetivamente em WINDUP; Move instantâneo **sem essa fase**, se precisar calcular trajeto, captura no **início de execução efetiva**. Não criar fase oculta nem estender automaticamente regras de retarget do WINDUP a ações sem WINDUP.
2. **D-158 × D-108 × D-155:** se Pancham morre durante WINDUP e Abra/Gible estão igualmente próximos (exemplo: 4 m de distância), o desempate depende **do identificador estável de combate**, não de RNG. O recálculo de duração segue ocorrendo **uma vez por troca**. **Ainda não definidos:** regra de ordenação do ID e sua atribuição/persistência; não escolher entre menor e maior ID por suposição.
3. **D-159 × D-156 × D-019 × D-095:** buff de LUK processado **antes** de uma rolagem no mesmo instante lógico altera a LUK lida por ela; processado **depois**, não. A ordem precisa ser determinística, mas as prioridades concretas entre tipos de evento ainda não foram aprovadas. **Empate por eliminação simultânea no mesmo instante lógico (D-095) permanece obrigatório**; não usar ordem interna de processamento para convertê-lo em vitória.
4. **D-160 × D-136 × D-140 × D-133 × D-018:** a referência comum de AGI para tempo de trajeto agora é **50**. A expressão documental é `T_final = max(0,25 s, T_base_do_Move × 50 / max(1, AGI_efetiva) − 0,10 s × (passo_atacante + passo_alvo))`. Exemplo: Move 1,0 s, AGI efetiva 50 → 1,0 s antes dos passos; AGI efetiva 100 → 0,5 s antes dos passos. Preservar cálculo no WINDUP, exceção de recálculo no retarget e cálculo na execução efetiva sem WINDUP (D-154/D-155/D-157).
5. **D-161 × D-145 × D-126:** referência **ATB permanece sem número** para avaliação futura do ritmo; **50 não é referência ATB**. Preservar ritmo de combate e economia de ATB previamente aprovados. Não declarar avaliação realizada ou fórmula ATB implementada.

### 42.3 Pendências remanescentes e escopo

- Ordenação concreta e identidade estável do desempate (D-158).
- Prioridades para eventos de mesmo instante lógico e preservação de empate simultâneo (D-159/D-095).
- AGI efetiva usada nos recálculos de WINDUP se buffs ocorrerem entre o cálculo original e o retarget (D-155/D-160); os exemplos aprovados não fixaram todos esses detalhes.
- Valor e função quantitativa da referência de ATB, parâmetros de avaliação do ritmo e de calibração (D-161); **não atribuir 50 automaticamente**.
- Precisão/forma de arredondamento do cálculo de duração, e outras lacunas anteriores não respondidas.
- **Somente documentação:** cinco decisões novas, índice, consolidado e adendo do GDD. Nenhum arquivo de código, Move, teste, cena, VFX, asset ou configuração alterado.


---

## 43. Rodada 62 — versão prevalente confirmada e conciliação histórica

> **2026-11-03:** a seção 42 e os arquivos **D-157 a D-161** documentavam uma versão diferente da Rodada 62 (1A, 2A, 3A, 4A, 5B). O criador enviou as escolhas **1C, 2A, 3B, 4A, 5A**, sem observações próprias, e respondeu expressamente **“ok, sim”** à pergunta sobre **suas cinco escolhas prevalecerem sobre a outra versão já publicada**. Assim, **D-162 a D-166 contêm as regras vigentes**, preservando seção 42 e D-157–D-161 como histórico. Não alterar código.

### 43.1 Registro vigente

| Decisão | Escolha | Regra |
|---|---|---|
| [D-162](decisoes/D-162-r62-q1-trajeto-referencia-agi-mediana-jogaveis.md) | **1C** | Referência AGI de **trajeto baseada na mediana da AGI das espécies jogáveis**; **validar o número antes de implementar**. AGI 50 da D-160 **substituída**, não é referência vigente. |
| [D-163](decisoes/D-163-r62-q2-atb-tempo-inverso-agi.md) | **2A** | **Tempo de regeneração natural ATB inversamente proporcional à AGI efetiva**; taxa natural diretamente proporcional à AGI. |
| [D-164](decisoes/D-164-r62-q3-piso-agi-um-na-regeneracao-atb.md) | **3B** | Usar **AGI mínima de 1 exclusivamente no cálculo de regeneração natural ATB**, sem mudar o atributo. Complementa D-140 (piso de trajeto). |
| [D-165](decisoes/D-165-r62-q4-sem-windup-calculo-entrada-travel.md) | **4A** | Quando o Move tem TRAVEL e **não tem WINDUP**, calcular a duração ao **entrar efetivamente em TRAVEL**; esclarecer/substituir o marco genérico da D-157. |
| [D-166](decisoes/D-166-r62-q5-desempate-aleatorio-reproduzivel.md) | **5A** | Em empate de distâncias entre **inimigos vivos mais próximos** durante retarget de WINDUP, **sortear entre empatados com aleatoriedade reproduzível**, substituindo o desempate fixo por ID da D-158. |

### 43.2 Comparação expressa com a versão divergente

- **D-157 → D-165:** o marco genérico “início da execução efetiva” não prevalece sobre **entrada em TRAVEL** para Move com trajeto e sem WINDUP. **D-154/D-155 preservadas** para WINDUP e trocas.
- **D-158 → D-166:** o desempate por **ID estável sem sorteio foi substituído por sorteio reproduzível** entre empatados. D-108 continua escolhendo primeiro o inimigo vivo mais próximo; D-155 continua recalculando uma vez por troca.
- **D-159:** pertence à pergunta 3 de outra versão da Rodada 62; **não foi ratificada** como parte da versão vigente, que trata do piso AGI para ATB em D-164. Preservar regras previamente válidas em D-019, D-095 e D-156, sem inferir uma precedência específica para eventos simultâneos.
- **D-160 → D-162:** o valor numérico **50** do tempo de trajeto deixa de ser regra aprovada; definir a referência com base na **mediana das espécies jogáveis**, que ainda depende de dados e **validação do criador antes de implementar**.
- **D-161:** o adiamento da referência numérica de ATB pertence à outra versão da Rodada 62. O **número para ATB continua sem escolha**, mas **D-163** já aprova a **relação inversa do tempo com AGI**. Não dizer que o coeficiente quantitativo está inteiramente indefinido.

### 43.3 Exemplos e limites

1. **Referência de trajeto:** amostra fictícia de AGI 20, 30, 40, 50, 60 tem mediana **40**, mas isso **não é referência aprovada** no Crawlmon. Precisam ser especificados conjunto de espécies jogáveis, nível e valores comparáveis.
2. **ATB:** para a mesma quantidade de ATB preenchida naturalmente, dobrar AGI efetiva positiva reduz o tempo à metade. Exemplo puramente ilustrativo: 5 segundos tornam-se 2,5 segundos; **não** cria um novo tempo-base oficial. Se AGI efetiva for 0 ou negativa, usar **1 só no cálculo**, conforme D-164, sem eliminar pausas e bloqueios.
3. **Sem WINDUP:** AGI 45 na confirmação do Move e AGI 60 ao entrar efetivamente em TRAVEL → **usar 60** no cálculo inicial do trajeto, cuja referência numérica ainda deve ser validada (D-162).
4. **Empate de alvos:** Abra e Pancham vivos a 4 m do atacante, ambos mais próximos, participam de um **sorteio reproduzível**, não de desempate fixo por ID.

### 43.4 Pendências ainda abertas

- Quais espécies/estágios entram na mediana de AGI do trajeto, tratamento de Nature, atributos individuais, número par de espécies e validação do resultado;
- Valor numérico de referência da AGI para ATB, calibração do ritmo, precisão/arredondamento e amostragem de AGI durante regeneração;
- Tolerância geométrica para empate, seed e consumo reproduzível de RNG; precedências finas de eventos simultâneos;
- D-001 mantida: **o GDD não é fonte normativa de combate**. Escopo documental: cinco novos D, cinco notas históricas, índice, consolidado e GDD. **Nenhum código, Move, asset, cena, VFX ou teste alterado.**


---

## 44. Rodada 63 — amostra da mediana de AGI, calibração ATB e tolerância de proximidade

> **2026-11-03.** Decisões expressas do criador: **1B, 2A, 3A, 4A e 5B**, sem observações adicionais. Arquivos individuais **D-167 a D-171**. O histórico divergente da Rodada 62 (seções 42 e 43) permanece preservado; D-162 a D-166 continuam vigentes, agora complementadas. **Documentação apenas, sem implementação**.

### 44.1 Matriz das decisões aprovadas

| Documento | Escolha | Regra |
|---|---|---|
| [D-167](decisoes/D-167-r63-q1-mediana-todas-especies-controlaveis.md) | **1B** | A amostra da mediana de AGI inclui **todas as espécies diretamente controláveis pelo jogador**, **inclusive evoluções elegíveis** |
| [D-168](decisoes/D-168-r63-q2-agi-base-nivel-comum-sem-modificadores.md) | **2A** | Para cada espécie usar **AGI-base no mesmo nível de referência**, **sem Nature, variação individual ou buffs**; nível ainda indefinido |
| [D-169](decisoes/D-169-r63-q3-referencia-atb-calibrar-ritmo-existente.md) | **3A** | Determinar a referência numérica de AGI para ATB pela **calibração do ritmo existente do jogo** e **apresentar o valor antes de implementar** |
| [D-170](decisoes/D-170-r63-q4-agi-atualizada-a-cada-tick-regeneracao-atb.md) | **4A** | **Reavaliar a AGI efetiva em cada atualização da regeneração natural do ATB**, respeitando pausas, valores já acumulados e piso de cálculo |
| [D-171](decisoes/D-171-r63-q5-tolerancia-empate-distancia-001-arena.md) | **5B** | Considerar **empate** no retarget quando a **diferença de distâncias for até 0,01 unidade da arena, inclusive exatamente 0,01** |

### 44.2 Espécies e atributos comparáveis para a mediana (D-162/D-167/D-168)

- O critério “espécies jogáveis” em D-162 significa **todas as espécies que o jogador pode controlar diretamente**, incluindo **formas evoluídas elegíveis**; não somente iniciais nem espécies exclusivas de controle da IA.
- Cada espécie da amostra contribui com sua **AGI-base em um mesmo nível de referência para todas**, excluindo **Nature, variação individual e buffs** apenas do **cálculo da mediana**. Esses mecanismos continuam existentes no combate/progressão em seus próprios escopos.
- **Pendente expressamente:** escolher o **nível comum**; verificar lista e AGI-base das espécies elegíveis no repositório, lidar com variantes e mediana de conjunto par, e então **apresentar o resultado numérico ao criador para validação antes da implementação** (D-162).
- **Exemplo hipotético:** espécie A e sua evolução ambas controláveis entram na amostra; em determinado nível comum ainda não aprovado, uma AGI-base de 35 poderia ser usada no cálculo mesmo que um indivíduo modificado apresentasse 36. **Nenhuma espécie, número ou nível do exemplo é parâmetro oficial.**

### 44.3 Calibração e atualização do ATB (D-126/D-145/D-163/D-164/D-169/D-170)

- A referência numérica de **AGI para ATB** deve ser derivada de **calibração do ritmo efetivamente existente**, com **valor apresentado para aprovação antes da implementação**. Isso **não** aprova AGI 50, não exige equivalência à mediana de trajeto nem autoriza a alteração do ritmo existente por suposição.
- **D-163 preservada:** para a mesma quantidade de ATB natural, o tempo é inversamente proporcional à AGI efetiva; a taxa de preenchimento é diretamente proporcional. **D-164:** utilizar `max(1, AGI_efetiva)` exclusivamente para cálculo se AGI for zero ou negativa.
- **D-170:** em **cada atualização da regeneração natural de ATB**, consultar AGI efetiva novamente; buffs/debuffs modificam as taxas das próximas atualizações habilitadas, sem recálculo retroativo dos blocos já preenchidos. Preservar pausas/bloqueios e ganhos instantâneos.
- **Exemplo ilustrativo:** ATB tem 2 blocos acumulados com AGI 20; um buff eleva AGI a 40. Mantêm-se os 2 blocos e a regeneração subsequente usa 40 enquanto o buff vigorar. Os valores não são um perfil de espécie aprovado.
- Não foram realizadas **medições**, calibrações ou testes de gameplay para definir a referência de ATB nesta rodada.

### 44.4 Tolerância do empate e sorteio reproduzível (D-108/D-155/D-166/D-171)

- Para a troca automática em **WINDUP**, selecionar inimigos vivos mais próximos. Considerar candidatos **empatados com o mais próximo** quando a **diferença de distâncias for de até 0,01 unidade da arena, inclusive o limite**. Sortear **apenas entre esses candidatos** usando a aleatoriedade reproduzível já aprovada (D-166), não por identificador fixo.
- **Exemplo ilustrativo:** Abra a 4,000 unidades da arena e Pancham a 4,006 unidades, sem alvo mais próximo: diferença **0,006**, ambos entram no sorteio. Um terceiro inimigo a 4,020 fica fora (diferença **0,020**). Se o segundo candidato estiver a **4,010**, a diferença **0,010** ainda conta como empate.
- Não inventar métrica de geometria (distância em plano ou 3D, origem/pivô e pontos de contato), seed, algoritmo de RNG, ordem de sorteios, frequência de reavaliação ou efeitos em ações fora de WINDUP. **D-155** permanece: um recálculo de duração por cada troca automática ainda no WINDUP.

### 44.5 Pendências remanescentes e estado de código

- Definir o **nível de referência** e identificar de forma verificável a amostra real de espécies e valores de AGI-base, para calcular a mediana e **submeter o número à validação do criador**.
- Medir/calibrar o **ritmo existente de ATB** para derivar o número de referência, sujeito a aprovação; definir conversão entre `base_speed` do código e AGI dos atributos permanentes sem supor equivalência.
- Fechar detalhes técnicos do desempate espacial e RNG reproduzível; arredondamento, concorrência de eventos e outras lacunas não escolhidas nesta rodada.
- **Consulta de código pré-publicação:** `scripts/combat/combatant.gd` ainda usa `base_speed` e `speed_buff` para a regeneração; o novo conjunto de atributos AGI e a referência numérica ainda não estão integrados. Registros novos não implicam implementação.
- **Escopo desta rodada:** cinco D novos, notas aditivas em D-162/D-163/D-166, índice, este consolidado e adendo do GDD. **Nenhum código, teste, cena, asset, VFX ou ficha alterado**.


---

## 45. Rodada 64 — nível 50, mediana par, espécies planejadas, calibração ATB e distância horizontal

> **2026-11-03.** Escolhas expressamente aprovadas pelo criador: **1C, 2A, 3B, 4C e 5B**, sem observações adicionais. Documentos individuais **D-172 a D-176**. Esta seção é aditiva: preserva as seções 42–44, a conciliação das duas versões da Rodada 62, e as decisões vigentes D-162 a D-171. **Nenhuma implementação autorizada.**

### 45.1 Quadro das regras aprovadas

| Registro | Escolha | Regra atual |
|---|---|---|
| [D-172](decisoes/D-172-r64-q1-nivel-50-mediana-agi.md) | **1C** | Comparar **AGI-base no nível 50** para todas as espécies elegíveis da amostra dos trajetos |
| [D-173](decisoes/D-173-r64-q2-mediana-par-media-dois-centrais.md) | **2A** | Se houver quantidade **par** de espécies elegíveis, mediana é a **média aritmética dos dois valores centrais** |
| [D-174](decisoes/D-174-r64-q3-especies-controlaveis-planejadas-documentadas.md) | **3B** | Incluir também espécies **oficialmente previstas na documentação vigente para controle direto**, mesmo **não implementadas** |
| [D-175](decisoes/D-175-r64-q4-calibracao-atb-intervalos-3a5-e-0a5.md) | **4C** | Medir e comparar **ambos os intervalos de regeneração natural ATB: 3→5 e 0→5 blocos** |
| [D-176](decisoes/D-176-r64-q5-distancia-horizontal-plano-arena.md) | **5B** | Calcular proximidade do retarget como **distância horizontal no plano da arena**, sem considerar altura |

### 45.2 Referência de AGI para tempo de trajeto — D-162/D-167/D-168/D-172/D-173/D-174

1. **Amostra:** espécies **diretamente controláveis** pelo jogador, **incluindo evoluções elegíveis** e aquelas **oficialmente previstas na documentação vigente** para controle direto, ainda que não implementadas. **Não** incluir espécies exclusivamente inimigas, exclusivamente da IA ou apenas especulativas.
2. **Comparabilidade:** para cada espécie elegível, utilizar a **AGI-base no nível 50**, sem Nature, variação individual ou buffs. Esta exclusão se refere **apenas à amostra estatística da referência**, não à mecânica efetiva de AGI de combatentes.
3. **Mediana:** ordenar os dados. Para amostra com quantidade **par**, usar a **média aritmética dos dois valores centrais**; para quantidade ímpar, o valor central. **Exemplo hipotético:** AGIs `20, 30, 50, 60` → mediana `(30 + 50) / 2 = 40`. **40 não é valor aprovado para o Crawlmon**.
4. **Obrigação pendente:** identificar a lista real de espécies elegíveis e sua evidência documental, obter os valores comparáveis de AGI-base no nível 50, calcular a mediana real e **apresentar o número para validação expressa do criador antes de qualquer implementação**, conforme D-162. Ainda **não se calcularam esses dados**.
5. **Pormenores não definidos:** fontes e fórmulas de AGI-base de espécies sem ficha no nível 50, duplicatas/variantes/formas, política para amostra incompleta e eventual arredondamento de mediana fracionária. Não escolher números por suposição.

### 45.3 Protocolo de calibração do ATB — D-031/D-126/D-163/D-164/D-169/D-170/D-175

- Para calibrar a **referência numérica de AGI para ATB** pelo ritmo já existente, medir **os dois intervalos** de regeneração natural: **3 para 5 blocos** e **0 para 5 blocos**, comparando os tempos observados. Preservar a barra normal de 5 blocos, o ATB inicial de 3 blocos (**D-031**) e os demais custos, ganhos e pausas.
- **Exemplo hipotético, não medição:** a 1 bloco/s constante, 3→5 levaria 2 segundos e 0→5 levaria 5 segundos. **Nenhuma dessas durações foi verificada ou aprovada para o jogo**.
- Preservar **D-163**: tempo natural de preenchimento inversamente proporcional à AGI efetiva; **D-164**: AGI de cálculo mínima 1 no ATB; **D-170**: reler AGI efetiva em **cada atualização de regeneração natural**, sem alterar retroativamente ATB acumulado.
- O valor de referência ATB precisa ser **calculado a partir de dados atuais e apresentado ao criador antes de implementar** (D-169). Nenhuma calibração ou teste de gameplay foi executado nesta rodada; não presumir resultado nem equiparar a referência ATB à de trajetos (D-145).

### 45.4 Retarget — proximidade horizontal e sorteio reproduzível (D-108/D-155/D-166/D-171/D-176)

- Durante a troca automática de alvo no **WINDUP** por morte do alvo original, escolher entre inimigos vivos com **menor distância horizontal no plano da arena**, desconsiderando diferenças de **altura**. Não usar distância euclidiana 3D para selecionar candidato por essa regra.
- Considerar **empatados com o menor valor de distância** os inimigos vivos que distam até **0,01 unidade da arena além da menor distância**, incluindo exatamente o limite. Sortear **reproduzivelmente somente entre os empatados**, não por ID estável (D-166; D-158 é histórico).
- **Exemplo hipotético:** um adversário a 5 unidades horizontais e 3 unidades acima continua a **5 unidades** no critério de proximidade, não ~5,83. Dois candidatos a 4,000 e 4,006 unidades horizontais participam do desempate por sorteio; um a 4,020 não.
- **Pendente:** origem geométrica usada em cada combatente (centro, pivô ou outro), eixos concretos do plano da arena no Godot, seed e consumo de RNG; não alterar alcance, colisão, altura de golpes ou comportamento dos projetéis por interpretação.
- Preservar D-155: **um recálculo de duração por troca efetiva ainda em WINDUP**, não durante TRAVEL.

### 45.5 Estado e limites

- **Somente documentação:** criados D-172–D-176; complementadas aditivamente D-167/D-168/D-169/D-171; atualizados índice, este consolidado e adendo do GDD.
- **Sem alterações de código, teste, cena, arquivo de espécie, Move, asset ou VFX**. Nenhuma mediana real de AGI foi calculada, nenhuma medição real do ATB foi realizada e nenhuma referência numérica foi validada para implementação.


---

## 46. Rodada 65 — formas alternativas, dados completos de AGI, mediana exata, medições controladas e posições lógicas

> **2026-11-03.** O criador aprovou expressamente **1C, 2A, 3A, 4A e 5A**, sem observações adicionais. Registros individuais **D-177 a D-181**. Este complemento é aditivo: **mantém os históricos** das rodadas anteriores, inclusive a versão divergente da Rodada 62 e sua conciliação na seção 43, sem reescrever suas declarações originais. D-061: registrar decisões antes de implementar; **nenhum código está autorizado nesta atividade**.

### 46.1 Regras expressamente aprovadas

| Registro | Escolha | Regra |
|---|---|---|
| [D-177](decisoes/D-177-r65-q1-formas-alternativas-agi-propria-distinta.md) | **1C** | **Contar formas alternativas separadamente somente se controláveis e com AGI-base própria distinta** |
| [D-178](decisoes/D-178-r65-q2-nao-finalizar-mediana-sem-dados-completos.md) | **2A** | **Não finalizar a mediana** enquanto faltar AGI-base **verificável no nível 50** para alguma espécie ou entrada elegível |
| [D-179](decisoes/D-179-r65-q3-mediana-fracionaria-exata-sem-arredondar.md) | **3A** | **Preservar a mediana fracionária exata**, sem arredondamento ou truncamento |
| [D-180](decisoes/D-180-r65-q4-atb-medicao-controlada-sem-interferencias.md) | **4A** | **Medir os dois intervalos de ATB 3→5 e 0→5 em condições controladas**, com regeneração natural ativa e **sem buffs, ações, recompensas instantâneas ou pausas** |
| [D-181](decisoes/D-181-r65-q5-distancia-posicoes-logicas-plano-horizontal.md) | **5A** | **Medir proximidade entre as posições lógicas de referência dos combatentes projetadas no plano horizontal** |

### 46.2 Mediana de AGI dos trajetos — critérios cumulativos

1. **Universo** (D-167/D-174): todas as espécies diretamente controláveis pelo jogador, incluindo as evoluções elegíveis e as espécies **oficialmente previstas na documentação vigente** para controle direto, ainda que não implementadas.
2. **Formas alternativas** (D-177): só acrescentar uma observação separada quando a forma alternativa **puder ser controlada e tiver AGI-base própria distinta**. Não duplicar uma aparência alternativa meramente cosmética com o mesmo valor de AGI-base. Não remover a espécie-base elegível.
3. **Valor comparado** (D-168/D-172): **AGI-base no nível 50**, sem Nature, variação individual ou buffs **somente para a amostra estatística**. Os modificadores existentes do jogo não são removidos.
4. **Completude** (D-178): se **qualquer entrada elegível** não tiver AGI-base **verificável no nível 50**, **não finalizar a mediana** nem declarar uma mediana de subconjunto como se fosse a de todas as espécies elegíveis.
5. **Mediana** (D-173/D-179): ordenar AGIs, tomar o valor central para amostra ímpar ou **a média dos dois centrais para amostra par**; **preservar exatamente o resultado fracionário sem arredondar**. **Exemplo puramente hipotético:** valores centrais `42` e `43` → `42,5`, nunca `42` ou `43`. **42,5 não foi aprovado como parâmetro de jogo**.
6. **Homologação obrigatória** (D-162): após obter dados completos e calcular o valor real, **apresentar a referência numérica ao criador para validação expressa antes de qualquer implementação**. Completar amostra não substitui sua aprovação.

**Pendentes:** identificar a lista real de espécies e formas elegíveis e as AGIs-base do nível 50 a partir dos dados atuais; resolver lacunas documentais sem suposição. Não foi calculada mediana real nesta rodada.

### 46.3 Calibração da regeneração natural ATB — comparação controlada

- **D-169/D-175/D-180:** medir **3→5 e 0→5 blocos** sob **condições controladas**, mantendo regeneração natural habilitada, **sem buffs, ações, ganhos instantâneos ou pausas** que contaminem a medição.
- Os dois intervalos servem à **calibração com o ritmo atual** de ATB, preservando D-031 (início 3/5), D-126 e D-145 (calibração sem mudança silenciosa, referências ATB e trajetória potencialmente distintas). Preparar cenário com ATB 0 não aprova mudar o início da batalha.
- **D-163/D-164/D-170:** o tempo de preenchimento natural é inversamente proporcional à AGI efetiva, com piso numérico 1 **apenas no cálculo**; AGI efetiva é relida em cada atualização de regeneração, sem alterar retroativamente a barra preenchida.
- **Exemplo ilustrativo, não medição:** a 1 bloco/s de regeneração natural hipotética, 3→5 levaria 2 segundos e 0→5 levaria 5 segundos. Nenhum desses tempos foi observado no jogo.
- **D-169:** a **referência ATB numérica só poderá ser proposta** após avaliar dados reais e **deverá ser apresentada ao criador antes de implementar**. Não foi realizada nenhuma medição ou calibração nesta documentação.

### 46.4 Proximidade de retarget durante WINDUP

- **D-108/D-176/D-181:** para escolher o novo inimigo vivo mais próximo em WINDUP, medir a **distância entre as posições lógicas de referência do atacante e dos candidatos, projetadas no plano horizontal da arena**. Diferenças de altura e extensão das colisões não mudam o critério geométrico aprovado.
- **D-171:** são empatados com a **menor distância horizontal** os candidatos dentro da tolerância **inclusiva de até 0,01 unidade da arena**; **D-166:** sortear **reproduzivelmente entre os empatados**, não usar ID fixo.
- **Exemplo hipotético:** posições lógicas projetadas a 4,000 e 4,006 unidades horizontais participam do sorteio; a 4,020 unidade não participa quando a menor é 4,000. Preservar **D-155** (um recálculo da duração por cada troca efetiva ainda em WINDUP) e **D-113** (sem redirecionamento depois de iniciada a investida).
- **Pendente:** verificar no código onde reside a posição lógica e quais eixos são usados no plano horizontal; definir seed e consumo reproduzível do RNG. A decisão **não** altera colisão física, projéteis ou alcance dos Moves.

### 46.5 Validação e limites desta rodada

- Criar somente **D-177–D-181**, notas históricas aditivas em **D-173/D-174/D-175/D-176**, índice de decisões, este consolidado e adendo histórico do GDD.
- **Não** alterar código, testes, arquivos de dados, VFX, cenas ou configurações. **Não** inventar resultado numérico de AGI ou de ATB; ambas referências numéricas continuam sem homologação pelo criador.


---

## 47. Rodada 66 — deduplicação intrasespécie, AGI verificável, amostragem e medição ATB, RNG próprio

> **2026-11-03.** O criador aprovou expressamente as escolhas **1A, 2B, 3B, 4B e 5A**, sem observações adicionais. Novas decisões **D-182 a D-186**. Esta consolidação é **aditiva**, preserva integralmente as seções anteriores, as decisões D-162 a D-181 e os registros históricos da Rodada 62. **Somente documentação, sem alterar código.**

### 47.1 Matriz das cinco decisões

| Documento | Escolha | Regra expressa |
|---|---|---|
| [D-182](decisoes/D-182-r66-q1-formas-um-valor-distinto-agi-por-especie.md) | **1A** | **Uma observação por valor distinto de AGI-base dentro de cada espécie**; formas com valor igual não duplicam observação |
| [D-183](decisoes/D-183-r66-q2-agi-nivel50-por-formula-oficial-verificavel.md) | **2B** | Aceitar AGI-base calculada por **fórmula oficialmente aprovada e verificável, com entradas documentadas**; sem fórmula válida, **manter pendência** |
| [D-184](decisoes/D-184-r66-q3-atb-perfis-velocidade-baixa-media-alta.md) | **3B** | Medir combatentes representativos das **faixas baixa, intermediária e alta de velocidade efetivamente existentes no código**, em condições controladas |
| [D-185](decisoes/D-185-r66-q4-atb-cinco-medicoes-mediana-por-intervalo.md) | **4B** | Realizar **cinco medições por intervalo e combatente**; utilizar a **mediana dos tempos observados** |
| [D-186](decisoes/D-186-r66-q5-fluxo-rng-exclusivo-desempate-retarget.md) | **5A** | Utilizar **um fluxo de números pseudoaleatórios reproduzível exclusivo para desempates de retarget**, separado dos demais sorteios do combate |

### 47.2 Composição de AGI-base no nível 50 (D-162/D-167/D-168/D-172/D-174/D-177/D-178/D-179/D-182/D-183)

- **Universo:** espécies controláveis diretamente pelo jogador, incluindo evoluções elegíveis e espécies oficialmente previstas na documentação vigente para controle direto, ainda não implementadas. Não acrescentar criaturas exclusivas da IA sem previsão oficial de controle pelo jogador.
- **Valores:** AGI-base de cada entrada elegível **no nível 50**, sem Nature, variação individual nem buffs, somente para compor a referência estatística dos trajetos.
- **Formas alternativas (D-182):** para cada espécie, **uma observação por valor distinto de AGI-base**. Uma forma alternativa controlável com AGI-base própria diferente acrescenta observação; **formas com o mesmo valor dentro da mesma espécie não duplicam**. AGIs iguais de **espécies diferentes continuam como observações próprias**. **Exemplo hipotético:** espécie A, forma-base AGI 40, formas Alfa/Beta ambas com AGI própria 60 → `[40, 60]` para essa espécie, não `[40, 60, 60]`; espécie B com AGI 60 contribui seu próprio 60. Nenhum dado do exemplo é oficial.
- **Verificação (D-178/D-183):** AGI-base é verificável se consta diretamente de fonte oficial, ou se é **calculada com fórmula já oficialmente aprovada e verificável, utilizando entradas documentadas**. Caso não haja fórmula válida ou entradas suficientes, **não substituir por estimativa**: entrada e mediana permanecem pendentes. **Não finalizar** a mediana se faltar dado verificável para qualquer espécie/entrada elegível.
- **Cálculo e aprovação (D-173/D-179/D-162):** ordenar todos os valores; se amostra par, usar **média dos dois centrais**, preservando **exatamente frações sem arredondar**. O valor real calculado a partir da amostra completa ainda deve ser **apresentado e validado expressamente pelo criador antes de implementar**. A decisão 2B **não aprova uma fórmula nova por si só**.
- **Não realizado:** nenhuma enumeração completa de espécies e formas elegíveis nem derivação de AGI no nível 50 foi feita nesta atividade; nenhum valor oficial de referência foi obtido ou validado.

### 47.3 Protocolo comparativo de ATB (D-031/D-126/D-163/D-164/D-169/D-170/D-175/D-180/D-184/D-185)

- **Faixas de velocidade (D-184):** identificar, no **código real**, combatentes representativos de **velocidade baixa, intermediária e alta**. Usar as **mesmas condições controladas** para todos; sem inventar faixas ou perfis não existentes.
- **Intervalos (D-175):** medir a regeneração natural de **3 para 5 blocos ATB** e de **0 para 5 blocos ATB**, preservando ATB inicial de 3/5 (D-031) e a capacidade de cinco blocos; a preparação do teste de 0 não modifica a regra permanente.
- **Condições (D-180):** regeneração natural ativa, **sem buffs, ações, ganhos instantâneos ou pausas**.
- **Repetição (D-185):** em **cada perfil/combatente** e **cada intervalo**, executar **cinco medições** e tomar a **mediana dos cinco tempos** daquele par. **Exemplo ilustrativo, não resultado:** cinco medições fictícias `2,00; 2,01; 2,00; 2,18; 2,01 s` → ordenadas `2,00; 2,00; 2,01; 2,01; 2,18` → mediana **2,01 s**.
- **Base de calibração (D-169):** a referência numérica de AGI para ATB será proposta **a partir do ritmo realmente existente**, sem assumir que `base_speed` já corresponda à AGI permanente ou que a referência ATB seja igual à mediana de AGI dos trajetos (D-145). **Apresentar o número para aprovação antes de implementar.**
- **Mantido:** D-163 (tempo inversamente proporcional à AGI efetiva), D-164 (piso 1 só na fórmula) e D-170 (releitura da AGI a cada atualização natural). Os resultados medidos do ritmo antigo **não constituem automaticamente parâmetros aprovados do novo sistema**.
- **Não medido:** perfis reais, tempos, repetibilidade e coeficientes não foram aferidos. Também não foi aprovada metodologia de agregação final entre perfis além da mediana por perfil e intervalo.

### 47.4 Sorteio reproduzível isolado para retarget durante WINDUP (D-108/D-155/D-166/D-171/D-176/D-181/D-186)

- Se o alvo morrer ainda em WINDUP, redirecionar para o **inimigo vivo mais próximo**, medindo a distância **entre as posições lógicas projetadas no plano horizontal da arena**, sem diferença de altura (D-108/D-176/D-181).
- Tratar candidatos com diferença **até 0,01 unidade da arena, inclusive**, em relação ao mais próximo, como empatados (D-171). Sortear **apenas entre os empatados**, e recalcular duração **uma vez por troca efetiva** ainda em WINDUP (D-155).
- **D-186:** os desempates devem consumir um **fluxo de RNG reproduzível exclusivo**, **separado dos demais sorteios**. Rolagens de crítico, esquiva, status e IA não devem consumir nem avançar esse fluxo de desempate.
- **Exemplo hipotético:** uma rolagem de crítico antes do retarget não altera a posição da sequência própria de sorteios de retarget por si; o resultado do desempate ainda depende da sequência, dos candidatos e do estado válidos.
- **Pendentes:** origem e política da seed exclusiva, ordem dos candidatos elegíveis, algoritmo de RNG, consumo em casos sem empate/um só candidato, ordem de múltiplos desempates e critérios de replay. **Não** reintroduzir ID fixo da D-158, regra histórica substituída pela D-166.

### 47.5 Escopo e limites

- Documentação somente: **cinco novos D-182–D-186**, notas aditivas em **D-177/D-178/D-180/D-166**, atualização do índice, deste consolidado e do GDD em adendo.
- **Nenhum** código, teste, VFX, cena, asset, dado de espécie ou configuração alterado; **nenhuma medição de ATB ou cálculo de mediana numérica** executado. Referências de AGI de trajetos e de ATB continuam sem validação numérica; não há seed nem gerador de retarget implementado por esta documentação.


---

## 48. Rodada 67 — seed própria, ordem estável, consumo seletivo de RNG e duas escalas de tempo de ATB

> **2026-11-03.** Escolhas expressamente aprovadas pelo criador: **1B, 2A, 3A, 4A e 5C**, sem observações adicionais. Decisões individuais **D-187 a D-191**. Esta atualização é **aditiva**, preserva as decisões vigentes D-162–D-186 e os históricos divergentes da Rodada 62. **Somente documentação; nenhuma implementação autorizada.**

### 48.1 Regras aprovadas e vínculos

| Documento | Escolha | Regra |
|---|---|---|
| [D-187](decisoes/D-187-r67-q1-seed-propria-retarget-inicio-combate.md) | **1B** | **Gerar seed própria de retarget no início do combate e registrá-la para reprodução** |
| [D-188](decisoes/D-188-r67-q2-ordenacao-candidatos-id-estavel-antes-rng.md) | **2A** | **Ordenar candidatos empatados por ID estável de combatente dentro da batalha antes do sorteio** |
| [D-189](decisoes/D-189-r67-q3-rng-so-consumir-em-empate-real.md) | **3A** | **Consumir RNG exclusivo somente quando houver ao menos dois candidatos elegíveis empatados** |
| [D-190](decisoes/D-190-r67-q4-seis-medianas-atb-antes-conversao-agi.md) | **4A** | **Apresentar seis medianas ATB separadas; não determinar referência numérica de AGI/ATB sem conversão verificável da velocidade atual em AGI** |
| [D-191](decisoes/D-191-r67-q5-tempo-simulado-real-medições-atb-separados.md) | **5C** | **Registrar tempo simulado e tempo real separadamente para diagnosticar discrepâncias** |

### 48.2 Reprodutibilidade de retarget (D-108/D-155/D-166/D-171/D-176/D-181/D-186–D-189)

1. **Seed própria (D-187):** ao **iniciar cada combate**, gerar **uma seed específica do RNG de desempates de retarget** e **registrá-la para reprodução**. O fluxo continua **isolado de crítico, esquiva, status e demais sorteios** (D-186); a seed não é uma referência à AGI nem um valor fixo universal.
2. **Conjunto e geometria:** quando o alvo morrer durante **WINDUP**, considerar somente **inimigos vivos elegíveis**, selecionar o menor valor de distância horizontal **entre as posições lógicas de referência** e admitir empate de distâncias até **0,01 unidade da arena, inclusive**, relativamente à menor distância (D-108/D-171/D-176/D-181).
3. **Ordenação (D-188):** **ordenar candidatos empatados por identificador estável do combatente dentro da batalha antes do sorteio**. Isso **não** escolhe automaticamente o menor ID: **D-158 (escolha por ID) continua registro histórico superado por D-166 (sorteio)**. **Exemplo hipotético:** candidatos empatados de IDs `8, 3, 5` são fornecidos ao RNG na ordem `3, 5, 8`; a seleção permanece aleatória.
4. **Consumo (D-189):** **consumir o RNG exclusivo somente quando há ao menos dois candidatos vivos elegíveis empatados**. Sem candidato ou com um único candidato, **não avançar esse fluxo**. Exemplo: se somente Abra estiver disponível, selecionar Abra pelo retarget permitido, sem rolagem; um empate posterior consome um número do fluxo.
5. **Preservar:** D-155 — um recálculo de duração por cada troca efetiva ainda em WINDUP; D-113 — sem troca após início da investida; D-105/D-107 — encerramento definitivo no último sobrevivente.
6. **Ainda por decidir/verificar:** algoritmo de RNG, formato e persistência da seed, política de ordem temporal para desempates simultâneos, identificação estável dos combatentes no repositório e integração com replay. **Seed numérica do exemplo de D-187 (`84271`) é fictícia**, não padrão nem observação do jogo.

### 48.3 ATB — seis combinações, dois relógios, referência AGI bloqueada (D-126/D-145/D-163/D-164/D-169/D-170/D-175/D-180/D-184/D-185/D-190/D-191)

- **Amostra controlada:** selecionar combatentes representativos das **faixas baixa, intermediária e alta** de velocidades **realmente existentes no código** (D-184). Medir, para cada um, ambos os intervalos de regeneração natural **3→5 e 0→5 blocos** (D-175), **sem buffs, ações, recompensas instantâneas ou pausas** (D-180); preservar início normal em 3/5 (D-031).
- **Repetições e medianas:** realizar **cinco medições por combinação de combatente × intervalo**, usando a **mediana dos cinco tempos** (D-185). Manter **separadas as seis combinações de três perfis × dois intervalos** (D-190), sem fundi-las em uma referência automática.
- **Relógios (D-191):** registrar em **cada medição tanto tempo simulado quanto tempo real transcorrido, separadamente**. Para fins de consolidação, não misturar os relógios: registrar as **seis medianas por tipo de tempo** (até doze resultados distinguíveis, decorrentes das mesmas seis combinações e cinco repetições cada). **A regra não aprova qual relógio servirá de base numérica final para a conversão AGI**, nem uma tolerância de discrepância.
- **Exemplo hipotético, não medido:** um intervalo leva **2,00 s simulados** e **2,08 s reais**; são dois resultados distintos da mesma observação. Se três perfis fictícios tiverem medianas simuladas de 3→5 e 0→5, apresentar os seis números individualmente, e os equivalentes reais também em separado; **não declarar valores de exemplo como dados do jogo**.
- **Bloqueio expresso (D-190):** **não determinar a referência numérica de AGI para ATB sem estabelecer conversão verificável entre a velocidade atual do código e a AGI**. O código consultado ainda utiliza `base_speed` na taxa natural de ATB: não tratar `base_speed` como AGI-base por presunção. Após conversão verificada, calibração e proposta, **apresentar o número de referência ATB ao criador antes de implementar** (D-169).
- **Mantidos:** AGI efetiva única com referências numéricas potencialmente distintas para trajeto e ATB (D-145); tempo natural de preenchimento inversamente proporcional à AGI efetiva (D-163); piso 1 somente no cálculo de ATB (D-164); reavaliação de AGI a cada atualização habilitada da regeneração natural (D-170). Não modificar valores acumulados retroativamente.

### 48.4 Estado, preservação e pendências

- **AGI dos trajetos:** permanece a metodologia D-162/D-167/D-168/D-172–D-174/D-177–D-179/D-182–D-183: amostra verificável completa de espécies elegíveis, formas sem duplicação de AGI dentro da espécie, AGI-base no nível 50, mediana fracionária exata, e **aprovação expressa do número antes de implementar**. Esta rodada não substitui nem calcula essa referência.
- **ATB:** ainda faltam representantes reais, medições controladas, conversão atual→AGI e aprovação do número. Nenhuma medição de gameplay foi realizada nem foi proposta referência numérica nesta documentação.
- **RNG:** ainda faltam definição técnica de gerador, seed, ordem de eventos simultâneos, IDs estáveis e integração real com replay; não afirmar comportamento já implementado.
- **Escopo documental:** cinco novos registros D-187–D-191, notas históricas aditivas em D-166/D-169/D-185/D-186, índice, este consolidado e GDD em adendo. **Nenhum código, teste, recurso, cena, espécie ou VFX alterado**.

---

## 49. Rodada 68 — RNG simultâneo, ordem VIT/SPI→DEF, mínimo de dano e esquiva antes de rolagens condicionadas

> **2026-11-04.** Escolhas expressas **1A, 2A, 3A e 4A**; **nenhuma observação própria**. Novos documentos **D-192 a D-195**, com registros literais. Consolidação estritamente documental, sem alteração de código. Preserva D-001/D-003/D-061 e as decisões anteriores, inclusive os conflitos históricos e a ressalva de R60 transcrita no GDD §12.13.

### 49.1 Matriz das escolhas aprovadas

| Decisão | Escolha | Regra |
|---|---|---|
| [D-192](decisoes/D-192-r68-q1-ordem-retarget-simultaneo-id-atacante.md) | **1A** | Ordenar **eventos simultâneos de retarget que consumirão RNG exclusivo** pelo ID estável do **atacante**, antes de consumir o fluxo; sem substituir sorteio por desempate fixo |
| [D-193](decisoes/D-193-r68-q2-resistencia-natural-antes-def.md) | **2A** | Aplicar **resistência natural VIT (físico) / SPI (mágico)** **antes** do modificador por estágios comuns de **DEF** |
| [D-194](decisoes/D-194-r68-q3-dano-minimo-um-golpe-valido.md) | **3A** | **Dano mínimo 1** para golpes danosos que acertaram validamente, **exceto** imunidades e bloqueios completos |
| [D-195](decisoes/D-195-r68-q4-esquiva-antes-critico-status.md) | **4A** | Resolver **esquiva automática primeiro**; quando funciona, **não rolar crítico** nem **status que dependa do acerto** |

### 49.2 Escopo exato e exemplos

- **RNG concorrente (D-192):** atacantes ID 2 e ID 5 têm **eventos de retarget no mesmo instante lógico**, cada qual com ao menos dois candidatos empatados. Ordenar primeiro o evento do **ID 2** e em seguida o de **ID 5** para os consumos do fluxo exclusivo de RNG. **D-188** continua ordenando os candidatos **dentro** de cada evento, **D-189** impede consumo quando não há empate real, e **D-166** mantém o sorteio reproduzível. Esta ordem **não** altera D-095 (KO simultâneo = empate), nem define desempate entre dois eventos do mesmo atacante.
- **DEF após resistência natural (D-193):** o primeiro fator de mitigação natural é VIT para físico ou SPI para mágico; só **depois** entra o modificador comum dos estágios de DEF (D-130/D-138). Exemplo **hipotético, não fórmula homologada**: 100 de dano, resistência natural subtrativa fictícia 20 e modificador fictício 0,8 → (100−20)×0,8 = **64**. Coeficientes, operações, ordem com crítico/fraqueza e arredondamento **continuam pendentes**.
- **Mínimo de dano (D-194):** se um golpe danoso válido alcança 0,4 após mitigação, o dano efetivo mínimo é **1**, desde que **não haja imunidade/bloqueio completo aplicável**; uma imunidade total continua impedindo dano. A regra não converte esquiva, erro ou Move exclusivamente de status em dano de 1.
- **Ordem das rolagens (D-195):** golpe elegível à esquiva automática, com possibilidade de crítico e status condicionado ao acerto, é esquivado automaticamente → **não rolar crítico nem status condicionado a esse acerto**. Preservar D-012 para debuffs de alvo único não esquiváveis e D-134 para efeitos garantidos. **Não foi escolhida aqui toda a ordem posterior de rolagens em golpes acertados.**

### 49.3 Preservação, conflito histórico e pendências

- **R60 reapresentada:** as diferenças entre o texto reenviado (2A e 3A) e o registro mais recente D-150/D-152/D-153 **continuam explicitamente pendentes de confirmação** conforme o GDD §12.13. D-195 não escolhe ou altera fórmulas de LUK.
- **RNG:** criar/verificar IDs estáveis e definir algoritmo/serialização da seed, granularidade de eventos simultâneos e critério adicional se um mesmo atacante produzir mais de um retarget simultâneo. Não estender ordenação dos sorteios a eliminações simultâneas (D-095).
- **Mitigação:** determinar fórmula numérica de resistência VIT/SPI, limites, ordem com outros fatores, arredondamento, interação com imunidades e efeitos sem dano; nenhum coeficiente aprovado por esta rodada.
- **Código observado na `main` antes desta publicação:** `battle.gd` já verifica `auto_dodged` antes do crítico em `_hit()`; `combatant.gd` já tem `def_buff` e piso de dano, porém ainda não integra resistência natural baseada em VIT/SPI. **A documentação não comprova implementação futura do conjunto de regras.**
- **Escopo:** quatro D individuais, índice, este consolidado e adendo GDD. **Nenhum código, teste, Move, cenário, recurso, asset ou VFX alterado; nenhum teste de gameplay executado.**

---

## 50. Rodada 69 — IDs estáveis no combate, mitigação percentual VIT/SPI, arredondamento único e status pós-dano

> **2026-11-04.** Respostas expressamente aprovadas: **1A, 2A, 3A, 4A**, sem observações adicionais. Registros individuais **D-196 a D-199**. Esta seção é aditiva e preserva integralmente as decisões anteriores, inclusive o conflito textual de R60 no GDD §12.13 e a conciliação histórica de R62. Não representa implementação.

### 50.1 Decisões aprovadas

| Registro | Escolha | Regra |
|---|---|---|
| [D-196](decisoes/D-196-r69-q1-ids-unicos-estaveis-por-combate.md) | **1A** | Atribuir **IDs únicos no início do combate**, numa **ordem estável e documentada**, sem renumerar durante a batalha; complementa D-188/D-192 |
| [D-197](decisoes/D-197-r69-q2-mitigacao-percentual-retornos-decrescentes-vit-spi.md) | **2A** | **Mitigação percentual de retornos decrescentes** com a **mesma estrutura de curva para VIT e SPI**, preservando defesa física/mágica separada |
| [D-198](decisoes/D-198-r69-q3-arredondamento-unico-final-dano.md) | **3A** | Conservar **precisão fracionária** em todos os modificadores; **arredondar uma única vez ao inteiro mais próximo no fim**, depois aplicar mínimo quando cabível |
| [D-199](decisoes/D-199-r69-q4-critico-dano-antes-status-alvo-sobrevive.md) | **4A** | Após acerto válido, resolver **crítico e dano antes**; somente aplicar **status condicionado ao acerto se o alvo sobreviver** |

### 50.2 Esclarecimentos de escopo e exemplos

- **IDs D-196:** a batalha atribui IDs distintos a combatentes ao começar, e não renumera os que permanecem após uma derrota. **A sequência concreta de atribuição ainda não foi aprovada**; a ordem por ID dos atacantes ao consumir RNG simultâneo (D-192) e ordenação dos candidatos empatados (D-188) continuam regras distintas. Nenhuma preferência fixa de alvo por ID é introduzida. **D-095** preserva empate por eliminações no mesmo instante lógico.
- **Defesa D-197:** VIT reduz dano físico e SPI reduz dano mágico, ambas com **redução percentual que apresenta retornos decrescentes** sob uma mesma estrutura matemática, sem aprovar equação numérica, constantes ou limites. D-193 fixa a ordem **resistência natural → estágios de DEF** para ambos. Exemplo apenas conceitual: aumento de SPI 40→50 e depois 90→100 continua favorecendo a proteção, mas com ganho marginal decrescente; **os valores não são percentuais de defesa**.
- **Precisão D-198:** um cálculo **inteiramente fictício** 9,4×0,7×0,8 = 5,264 arredonda **uma única vez** para **5**; os coeficientes não são de Moves ou atributos oficiais. Só depois incide o mínimo de **1 em acerto danoso válido sem imunidade/bloqueio completo** (D-194). O tratamento de empate exato em x,5, a equação natural e a ordem relativa de fatores ofensivos ainda não foram escolhidos.
- **Status D-199:** após a esquiva automática (D-195) falhar, o acerto resolve **crítico e dano**. Se o alvo sobreviver, pode ocorrer aplicação de status **dependente do acerto** de acordo com ficha e LUK efetiva no evento (D-134/D-146/D-156); se o dano causar KO, **não aplicar nem rolar** esse status naquele alvo. Não altera Moves de debuff não esquiváveis da D-012 nem efeitos independentes do acerto. O tratamento de multi-hit e do HP visual/rolante não é decidido aqui.

### 50.3 Relações, conflitos preservados e estado observado

- **R60 ainda divergente:** permanece pendente a conciliação das escolhas 2A e 3A reapresentadas em 2026-11-04 com os documentos anteriores D-150 e D-152/D-153, descrita no GDD §12.13. Nenhuma fórmula de LUK foi silenciosamente substituída.
- **Código da main inspecionado:** `scripts/combat/battle.gd` calcula e arredonda dano usando `roundi` antes de `take_damage`; `scripts/combat/combatant.gd` aplica `def_buff` e outro `roundi`. A nova regra D-198 de arredondamento único global **não está implementada**; as resistências VIT/SPI e sua curva percentual tampouco foram implementadas nesta atividade. **Nenhum teste de gameplay executado.**
- **Pendentes:** ordem exata de atribuição e casos de entrada posterior de combatentes (D-196), família matemática e parâmetros de VIT/SPI (D-197), desempate de arredondamento x,5 e cadeia completa de fatores de dano (D-198), checkpoints de sobrevivência com HP rolante e eventos multi-hit (D-199); PRNG/seed de replay e AGI/ATB permanecem sujeitos às decisões próprias anteriores.
- **Escopo:** quatro registros novos, índice, consolidado e adendo GDD. Nenhum código, cena, asset, ficha de Move, VFX ou teste modificado.

---

## 51. Rodada 70 — ordem de IDs, curva racional VIT/SPI, status multi-hit e descarte do odômetro

> **2026-11-04.** O criador aprovou expressamente **1A, 2A, 3A**. Na **4D**, a única regra nova determinada textualmente foi: **“o odometro era só um teste, não usaremos ele no jogo principal, descarte toda e qualquer ideia que o envolva”**. Registro rastreável em **D-200 a D-203**. **Não** atribuir à resposta 4D qualquer escolha técnica não fornecida. D-061 exige documentação sem alterar código.

### 51.1 Regras aprovadas

| Documento | Escolha | Regra e limitação |
|---|---|---|
| [D-200](decisoes/D-200-r70-q1-ids-por-slots-equipe-depois-inimigos.md) | **1A** | Atribuir IDs estáveis **sequencialmente** pelos slots da **equipe do protagonista** e **depois** pelos slots **inimigos**, considerando a composição inicial de cada combate. Sem renumeração posterior (D-196). O valor inicial e a entrada de novos participantes seguem pendentes. |
| [D-201](decisoes/D-201-r70-q2-curva-racional-vit-spi-k-positivo.md) | **2A** | Mitigação percentual natural de VIT/SPI pela **curva racional R(x) = x/(x+K)**, com **K estritamente positivo**, **a calibrar e validar posteriormente**, sem assumir K=100 nem parâmetros iguais para VIT/SPI. |
| [D-202](decisoes/D-202-r70-q3-status-uma-tentativa-por-alvo-move-apos-ultimo-hit.md) | **3A** | Em Move **multi-hit** com status dependente do acerto, permitir **no máximo uma tentativa do status por alvo por execução**, **após o último impacto**, **somente se o alvo tiver sobrevivido** e ao menos um hit o tiver atingido validamente. |
| [D-203](decisoes/D-203-r70-q4d-odometro-descartado-jogo-principal.md) | **4D + regra expressa** | O **odômetro de HP era só um teste e está excluído do jogo principal**; descartar todas as ideias que o envolvam. Esta resposta **não define outra mecânica de sobrevivência** para a pergunta 4D. |

### 51.2 Exemplos e salvaguardas

- **D-200 / IDs:** slots iniciais aliados Gible e Abra, seguidos por inimigos Pancham e outro: IDs sequenciais exemplificativos `1, 2, 3, 4`, respectivamente. **Os números são didáticos, não uma aprovação do primeiro ID.** D-188 e D-192 seguem organizando os sorteios de retarget, sem substituir o RNG por escolha fixa de alvo. D-095 mantém empate por eliminação simultânea.
- **D-201 / defesa:** com `x=50` e **K fictício 100**, `R=1/3 ≈ 33,33%` de mitigação natural. Esse exemplo **não valida K=100**. Preservar VIT para físico, SPI para mágico (D-130), estágios comuns DEF aplicados **depois** (D-193), mínimo de dano salvo imunidade/bloqueio (D-194) e precisão até arredondamento final (D-198).
- **D-202 / multi-hit:** três impactos do mesmo Move elegíveis a Poison não provocam três sorteios desse status contra o mesmo alvo. Após o **último impacto**, se o alvo **sobreviver** e recebeu acerto válido, é permitida **uma tentativa** segundo a ficha/LUK (D-134/D-146/D-156). Alvo derrotado ou sem acerto válido não recebe essa rolagem. Aplicações de status independentes de acerto e regras próprias de certos Moves permanecem distintas.
- **D-203 / odômetro:** a antiga [D-048](decisoes/D-048-rolling-hp-mother3-odometro.md) descrevia um teste com Rolling HP, toggle, rolamento de dano/cura e SFX. **Essa proposta está superada no escopo do jogo principal**, por ordem expressa mais recente. Preservar o documento histórico, sem implementar, adaptar ou usar o odômetro como base para decisões de gameplay. **A outra D-048 de recompensas ATB de AoE não foi afetada**. A questão 4D não aprova automaticamente uso de `hp`, `target_hp` ou qualquer nova rotina de aferição de sobrevivência.

### 51.3 Divergências técnicas, conflitos históricos e pendências

- **Odômetro no código:** `scripts/combat/combatant.gd` contém `rolling_hp_enabled`, `target_hp` e `tick_rolling_hp`, e há o teste `tests/battle/test_d048_rolling_hp.gd`. **Esses componentes permanecem tecnicamente presentes**, mas **não são requisitos aprovados para o jogo principal**. **Não remover nem alterar código nesta rodada.**
- **Crítico/dano/status:** D-199 exige crítico e dano primeiro e status dependente de acerto só se sobreviver. D-202 fixa a frequência após o último impacto multi-hit. **A resposta R70-Q4D não definiu novo referencial de sobrevivência além de descartar o odômetro**, sem escolher 4A, 4B ou 4C anteriores.
- **Pendências novas:** critério de entrada posterior de combatente e valor inicial do ID; **parâmetro K positivo** e se será igual para VIT/SPI; múltiplos efeitos de status na mesma ficha e hit assíncrono; arredondamento exato `x,5`; desempate de eventos simultâneos do mesmo atacante. Preservar conflito de LUK **R60-Q2/Q3** no GDD §12.13 e demais pendências históricas.
- **Escopo efetivo:** quatro novos registros individuais, adendo de superação histórica na D-048 de HP rolante, índice, este consolidado e GDD. **Nenhum código, teste, asset, Move, cena ou VFX alterado; nenhum teste de gameplay executado.**

---

## 52. Rodada 71 — K compartilhado, desempate 0,5, IDs de novas entradas e status por alvo

> **2026-11-04.** O criador aprovou expressamente **1A, 2A, 3A e 4A**, sem observações próprias. Documentos individuais **D-204 a D-207**. Complementos estritos às decisões anteriores, sem modificar código nem reescrever registros históricos.

### 52.1 Regras aprovadas

| Documento | Escolha | Regra |
|---|---|---|
| [D-204](decisoes/D-204-r71-q1-k-unico-compartilhado-vit-spi.md) | **1A** | Um **único K numérico** compartilhado pelas curvas racionais de mitigação de **VIT e SPI**; **valor de K continua a calibrar e validar** |
| [D-205](decisoes/D-205-r71-q2-arredondamento-metade-para-cima.md) | **2A** | No **arredondamento único final do dano**, valor com parte fracionária **exatamente 0,5** vai ao **inteiro superior** |
| [D-206](decisoes/D-206-r71-q3-proximo-id-sem-reuso-entradas-posteriores.md) | **3A** | Um **novo participante** que ingresse após o início da batalha, se essa situação ocorrer, recebe o **próximo ID não utilizado**, sem renumeração nem reutilização |
| [D-207](decisoes/D-207-r71-q4-status-apos-ultimo-impacto-por-alvo.md) | **4A** | Resolver status de cada alvo depois do **último impacto destinado a ele**, sem esperar os impactos destinados aos outros alvos |

### 52.2 Exemplos e compatibilidade

- **K único (D-204):** VIT 50 e SPI 50 usam o **mesmo** `K > 0` na função `R(x)=x/(x+K)` da D-201. **Exemplo numérico apenas hipotético**, com K fictício igual a 100: ambas as resistências naturais seriam `50/150 = 33,33%` em suas categorias. **Não foi aprovado K=100** nem qualquer outro número. Preservar VIT físico / SPI mágico (D-130), ordem resistência antes de DEF (D-193) e o mínimo 1 salvo imunidade/bloqueio (D-194).
- **Meio exato (D-205):** dano final `4,5 → 5` e `5,5 → 6`, enquanto `4,49 → 4`; arredondamento **uma vez ao fim de todos os modificadores**, preservando D-198. Tolerância/precisão de ponto flutuante seguem não especificadas.
- **IDs de entrada posterior (D-206):** composição inicial hipotética IDs 1, 2, 3; o combatente 2 sai e entra um **novo** combatente, que receberia ID **4**, não 2. Preservar D-200 (atribuição inicial por slots do protagonista, depois inimigos), D-196 (estabilidade) e D-188/D-192 (ordenação de retarget). **Não se aprova por isso o sistema de reforços, substituições ou novos participantes**; o que acontece ao retornar o *mesmo* combatente permanece pendente.
- **Status multi-hit (D-207):** se uma onda completa os impactos de Gible antes dos de Abra e Pancham, tentar o status elegível de Gible **após seu próprio último impacto**, se houve acerto válido e ele sobreviveu. **Uma tentativa máxima por alvo e execução** (D-202), crítico e dano antes (D-199), sem alterar limite de recompensas ATB, KO simultâneo (D-095) ou Moves de status não esquiváveis (D-012).

### 52.3 Pendências e escopo

- **Em aberto:** número e critério de calibração/validação do K único; política de entradas simultâneas e de reentrada do mesmo combatente; efeitos de vários status no mesmo Move; interrupções antes do último hit e como resolver simultaneidade de impactos; tolerância numérica no arredondamento; demais detalhes de replay/RNG e conversão AGI/ATB.
- **Conflito histórico R60:** a divergência textual entre a reapresentação de R60-Q2/Q3 e D-150/D-152/D-153 segue pendente (GDD §12.13). Nenhuma fórmula de LUK foi substituída por esta rodada.
- **D-203 mantida:** odômetro de HP excluído do jogo principal; código legado continua presente, sem alteração.
- **Código consultado na `main`:** `scripts/combat/battle.gd` e `scripts/combat/combatant.gd` ainda apresentam arredondamentos distintos e lógica pré-VIT/SPI; os requisitos novos são documentais, não um atestado de implementação. **Nenhum código, teste, recurso, Move, asset, cena ou VFX modificado e nenhum teste de gameplay executado.**

---

## 53. Rodada 72 — método de calibração de K, ID de retorno, status distintos e interrupções

> **2026-11-04.** O criador aprovou expressamente **1A, 2A, 3A e 4A**, sem observações próprias. Novos registros **D-208 a D-211**, com frases literais. Documentação somente, sem implementar ou alterar regras anteriores não afetadas.

### 53.1 Respostas aprovadas

| Registro | Escolha | Regra |
|---|---|---|
| [D-208](decisoes/D-208-r72-q1-calibrar-k-por-atributo-referencia-e-mitigacao-alvo.md) | **1A** | Calibrar o **K único de VIT/SPI** por um **atributo defensivo de referência** e uma **mitigação percentual-alvo**, **ambos sujeitos a aprovação futura** |
| [D-209](decisoes/D-209-r72-q2-mesmo-combatente-mantem-id-no-retorno.md) | **2A** | **O mesmo combatente conserva o mesmo ID original** se retornar à **mesma batalha** |
| [D-210](decisoes/D-210-r72-q3-uma-tentativa-por-status-distinto-alvo-execucao.md) | **3A** | Permitir **uma tentativa de aplicação para cada status distinto** declarado na ficha, **por alvo e execução**, respeitando condições de acerto e sobrevivência |
| [D-211](decisoes/D-211-r72-q4-status-apos-ultimo-impacto-efetivo-se-interrompido.md) | **4A** | Se Move for **interrompido após acertos válidos**, usar o **último impacto realmente executado** contra cada alvo para resolver status elegível **se o alvo sobreviver** |

### 53.2 Exemplos, delimitações e compatibilidades

- **K (D-208):** o método requer aprovar depois tanto `x_ref` quanto `R_alvo`. Com os valores **estritamente fictícios** `x_ref=50`, `R_alvo=25%`, a equação `R(x)=x/(x+K)` leva a `K=150`. **Nem 50, nem 25%, nem K=150 foram aprovados**. Preservar um **único K positivo compartilhado** por VIT e SPI (D-201/D-204), a separação físico/mágico (D-130) e a defesa natural antes dos estágios DEF (D-193). O parâmetro real necessita proposta e validação **antes de adoção/implementação**.
- **Identidade (D-209):** em uma batalha hipotética, Gible tinha ID 2, sai temporariamente e volta: **permanece ID 2**. Um **novo** combatente que ingresse recebe o próximo ID ainda não usado, conforme D-206. Preservar a ordem inicial pelos slots do protagonista, depois inimigos (D-200). **Esta regra não cria/autoriza mecânica de retirada ou reentrada.**
- **Vários status (D-210):** um Move hipotético declara Poison 30% e Paralysis 20%, ambos condicionados ao acerto. Alvo atingido validamente e sobrevivente pode receber **uma tentativa de cada efeito distinto** por execução; vários hits não multiplicam tentativas do mesmo efeito (D-202), e a resolução por alvo segue o último impacto destinado a ele (D-207). **Probabilidades fictícias, não ficha aprovada.** LUK e efeitos garantidos seguem D-134/D-146/D-156. **Não foi definida ordem de rolagens entre efeitos distintos nem novas interações/incompatibilidades.**
- **Interrupção (D-211):** Move com três impactos previstos é interrompido após dois efetivamente executados contra um alvo. Havendo acerto válido e sobrevivência, o **segundo impacto efetivo** serve de referência para resolver a tentativa elegível, **sem exigir o terceiro que não aconteceu**. Se todos os impactos erraram ou o alvo morreu, **não rolar status dependente do acerto**. Preservar limites individuais da D-210, regra temporal da D-207 para execução normal, regras de interrupção existentes e empate por KO simultâneo (D-095).

### 53.3 Preservação e pendências

- **Nenhum número de K foi aprovado:** faltam valores de atributo de referência e mitigação-alvo, procedimento de verificação e homologação do K calculado. Não tratar exemplos como dados do jogo.
- **Identidade:** não foi definida a disponibilidade de mecânicas de reentrada/reforços, nem o método de verificar identidade de Pokémon ou a ordem de entradas exatamente simultâneas; D-206 e D-209 cobrem somente a atribuição de IDs **condicionalmente**.
- **Status:** ainda faltam regras de ordenação entre status distintos, interação de efeitos incompatíveis, resolução de impactos simultâneos e casos especiais definidos por fichas.
- **D-203 vigente:** odômetro de HP / HP rolante **excluído do jogo principal**, apesar do código antigo do teste permanecer na `main`. A D-199 não deve ser aplicada por contagem visual de odômetro.
- **Divergência histórica R60 mantida:** reapresentação R60-Q2/Q3 vs D-150/D-152/D-153 no GDD §12.13 permanece sem decisão de precedência; as novas decisões não modificam a fórmula de LUK. O arredondamento final único e meio para cima permanecem conforme D-198/D-205.
- **Escopo desta publicação:** quatro registros individuais, índice, este consolidado e adendo no GDD. Nenhum código, teste, Move, cena, asset ou VFX modificado; nenhum teste de gameplay executado.

---

## 54. Rodada 73 — referência verificável VIT/SPI, ordem de status, RNG simultâneo e incompatibilidades

> **2026-11-04.** O criador aprovou expressamente **1A, 2A, 3A e 4A**, sem observações próprias. Registros individuais **D-212 a D-215**. Acréscimo documental, sem implementação nem reescrita do histórico das Rodadas 39–72.

### 54.1 Decisões aprovadas

| Documento | Escolha | Regra |
|---|---|---|
| [D-212](decisoes/D-212-r73-q1-levantar-vit-spi-reais-verificaveis-nivel50.md) | **1A** | **Levantar VIT e SPI reais e verificáveis no nível 50** para fundamentar uma proposta de atributo defensivo de referência, **sujeita à aprovação posterior** |
| [D-213](decisoes/D-213-r73-q2-status-ordem-declarada-ficha-move.md) | **2A** | Resolver as **tentativas de status distintos pela ordem explicitamente declarada na ficha do Move**, mantendo limites individuais |
| [D-214](decisoes/D-214-r73-q3-retarget-mesmo-atacante-ordem-declaracao-indice.md) | **3A** | Desempatar eventos **simultâneos de retarget do mesmo atacante** pela **ordem estável de declaração**, depois **índice estável das ocorrências da mesma declaração** |
| [D-215](decisoes/D-215-r73-q4-prioridade-ficha-para-status-incompativeis.md) | **4A** | **Somente quando dois status forem declarados incompatíveis**, usar **prioridade expressamente indicada na ficha do Move**; não criar incompatibilidades |

### 54.2 Compatibilidades e exemplos estritamente ilustrativos

- **D-212 / VIT-SPI nível 50:** dados precisam ser **reais, verificáveis e rastreáveis para o Crawlmon**, sem confundir valores de outros jogos com atributos oficiais daqui. A D-120 preserva referência biológica ajustada ao balanceamento próprio; a D-139 preserva ausência de teto superior. Esta rodada **não levantou estatísticas, não calculou medianas e não aprovou valores de VIT/SPI**. A D-208 exige aprovação posterior tanto do **atributo defensivo de referência** quanto da **mitigação percentual-alvo**, seguida da validação do K. A D-183 trata de AGI-base e **não aprova fórmula automática de VIT/SPI**.
- **D-213 / ordem de status:** ficha hipotética com `Poison` declarado antes de `Paralysis` → tentativas de Poison antes das de Paralysis, quando elegíveis; **não** determina chances nem torna ambos garantidos. D-210 mantém **até uma tentativa por efeito distinto, alvo e execução**, D-202/D-207/D-211 mantêm condições de impacto/sobrevivência e interrupção. **Ordem de tentativas não é prioridade de incompatibilidade**.
- **D-214 / mesmo atacante:** eventos fictícios `A#1`, `A#2` e `B`, todos simultâneos do atacante ID 2, seriam processados pela **ordem estável de declaração** e por **índice da ocorrência** em empates dessa declaração, antes dos consumos de RNG realmente necessários. **D-192 continua ordenando primeiro pelo ID do atacante**, D-188 ordena candidatos de cada evento, D-189 evita consumir RNG sem empate elegível, e D-095 mantém empate quando equipes morrem no mesmo instante lógico. Esta escolha não introduz preferência determinística por alvo.
- **D-215 / incompatibilidade expressa:** se uma ficha hipotética **declarar** Efeito A e Efeito B incompatíveis e prioridade A sobre B, essa prioridade prevalece na incompatibilidade quando aplicável. **Nenhum par real de status é declarado incompatível por esta escolha**. A sequência de tentativas da ficha (D-213) e as chances previstas dos efeitos (D-134/D-146/D-156) continuam distintas da precedência em caso de conflito.

### 54.3 Pendências, conflitos preservados e estado do projeto

- **Dados de atributos e calibração:** levantar e verificar VIT/SPI no nível 50; definir critério de amostragem/proposta; apresentar para aprovação atributo de referência e mitigação-alvo; somente depois calcular e validar **K único compartilhado** (D-201/D-204/D-208). Não inventar fórmula, valor numérico ou espécie.
- **Status:** não há regra nova para ficha sem ordem expressa, incompatibilidade sem prioridade, status já ativo, efeito de menor prioridade ou status de Moves distintos. **Não presumir quais status são incompatíveis.**
- **RNG:** representação/atribuição técnica de índice estável, persistência para replay e granularidade exata de eventos simultâneos permanecem em aberto, sem alterar algoritmos de sorteio ou política de KO.
- **Histórico:** a divergência textual da reapresentação R60-Q2/Q3 frente a D-150/D-152/D-153 permanece pendente (GDD §12.13); não escolher escala de LUK. D-203 mantém odômetro de HP **excluído do jogo principal**, sem remover código legado. D-198/D-205 mantêm arredondamento único final. A `main` inspecionada continua com código pré-VIT/SPI e sem esses requisitos implementados.
- **Escopo:** quatro D individuais, índice, este consolidado e adendo do GDD. Nenhum código, ficha de Move, teste, cena, asset ou VFX alterado; nenhum teste de gameplay ou levantamento quantitativo de VIT/SPI realizado.

---

## 55. Rodada 74 — lacunas de VIT/SPI, completude de fichas, índices de retarget e RNG de status

> **2026-11-04.** O criador aprovou expressamente **1A, 2A, 3A e 4A**, sem observações próprias. Registros individuais **D-216 a D-219**. Aditivo documental conforme D-061; não altera código nem substitui decisões históricas por suposições.

### 55.1 Respostas aprovadas

| Documento | Escolha | Regra |
|---|---|---|
| [D-216](decisoes/D-216-r74-q1-lacunas-vit-spi-nivel50-sem-referencia-prematura.md) | **1A** | **Registrar lacunas** no levantamento de VIT/SPI **no nível 50** e **não finalizar uma referência quantitativa** até que os **dados necessários** sejam verificáveis |
| [D-217](decisoes/D-217-r74-q2-ficha-incompleta-sem-prioridade-incompatibilidade.md) | **2A** | Considerar **incompleta** a configuração da ficha quando status forem declarados **incompatíveis sem prioridade expressa**, **sem escolher vencedor automaticamente** |
| [D-218](decisoes/D-218-r74-q3-indice-retarget-plano-deterministico-na-declaracao.md) | **3A** | Atribuir índice de cada ocorrência do plano **determinístico de eventos na declaração do ataque**, **preservando o índice até a resolução** |
| [D-219](decisoes/D-219-r74-q4-status-rng-simultaneo-por-id-do-alvo.md) | **4A** | Ordenar o **consumo do RNG nas rolagens simultâneas de status por ID estável do alvo**, **sem alterar simultaneidade lógica** dos efeitos |

### 55.2 Exemplos e salvaguardas

- **VIT/SPI (D-216):** se faltar SPI verificável de uma espécie no nível 50, documentar essa lacuna; não substituir o valor por estimativa nem apresentar referência quantitativa como concluída sem os dados necessários. A D-212 pede valores reais e verificáveis, mas **não aprova uma amostra específica** nem estatística; D-208 exige aprovação posterior do **atributo de referência**, da **mitigação-alvo** e validação de **K único** (D-201/D-204). **Nenhum levantamento quantitativo ou K foi calculado nesta rodada.**
- **Incompatibilidade (D-217):** ficha hipotética declara `Status A` incompatível com `Status B` mas omite prioridade. **A ficha está incompleta** quanto à incompatibilidade, sem autorizar aplicação automática da ordem de tentativas. **D-213** governa ordem de rolagens conforme declaração; **D-215** governa prioridade expressa. **Nenhum status real é declarado incompatível por esta decisão**, e não foi escolhida a reação do editor/runtime a fichas incompletas.
- **Índice de ocorrência (D-218):** um ataque hipotético declara eventos `A#1` e `A#2` por plano determinístico; ambos **mantêm os índices originais até sua resolução**. Complementa a ordenação por ID de **atacante (D-192)**, por declaração/índice no **mesmo atacante (D-214)** e a lista de candidatos (D-188). **D-189** conserva consumo de RNG exclusivo somente com empate real, **D-095** conserva KO simultâneo. Não define formatos, política de cancelamento ou reuso de índices cancelados.
- **Rolagens de status (D-219):** se Abra ID 2 e Pancham ID 5 tiverem rolagens **simultâneas** de um efeito probabilístico, usar ordem ID 2, depois ID 5 **somente para consumir RNG**, sem converter isso em prioridade temporal da aplicação de status. **D-213** segue definindo a ordem de efeitos distintos na ficha, **D-210** mantém limite por efeito/alvo/execução e **D-199** impede status condicionado ao acerto em alvo derrotado. A regra **não muda o fluxo exclusivo de retarget** (D-186–D-189) nem resolve rolagens concorrentes para **o mesmo alvo**.

### 55.3 Pendências, histórico e estado técnico

- **Calibração:** dados rastreáveis de VIT/SPI nível 50, critério de suficiência/amostra e eventual fórmula oficial de progressão continuam pendentes; nenhum atributo de referência, percentual-alvo nem K numérico foi homologado.
- **Fichas:** não estão definidos prioridade ou incompatibilidade para qualquer par real de status nem procedimento de validação/bloqueio para ficha incompleta. Não transformar configuração incompleta em escolha implícita de status.
- **RNG e ordenação:** ainda faltam política de índices para eventos cancelados, serialização/replay, definição de eventos simultâneos, desempate entre **duas rolagens simultâneas de status para o mesmo alvo** e algoritmo/seed do RNG de status. O fluxo exclusivo de retarget permanece separado.
- **Conflitos históricos:** a divergência de LUK da reapresentação R60-Q2/Q3 frente a D-150/D-152/D-153 segue explícita no GDD §12.13; nenhuma fórmula de LUK foi escolhida aqui. A D-203 mantém **odômetro fora do jogo principal** mesmo que código histórico ainda exista. As D-198/D-205 preservam arredondamento único final e meia unidade para cima.
- **Escopo:** quatro registros individuais, índice, esta seção do consolidado e adendo histórico no GDD. Nenhum código, teste, Move, ficha, VFX, asset ou cena alterado; nenhum teste de gameplay executado.

---

## 56. Rodada 75 — amostra defensiva, bloqueio de Move incompleto, índices cancelados e RNG para mesmo alvo

> **2026-11-04.** Aprovações expressas do criador **1A, 2A, 3A e 4A**, sem observações próprias. Decisões individuais **D-220 a D-223**. Esta seção é aditiva conforme D-061 e não implica implementação de código.

### 56.1 Regras aprovadas

| Documento | Escolha | Regra |
|---|---|---|
| [D-220](decisoes/D-220-r75-q1-amostra-defensiva-perfis-aprovacao.md) | **1A** | **Propor** amostra representativa de espécies com perfis defensivos **baixos, médios e altos**, verificar VIT/SPI **no nível 50** e **submeter a composição da amostra à aprovação** |
| [D-221](decisoes/D-221-r75-q2-bloquear-move-prioridade-incompatibilidade-ausente.md) | **2A** | **Bloquear o uso em combate** de Move com prioridade obrigatória **ausente entre status declarados incompatíveis**, **indicando exatamente a omissão** |
| [D-222](decisoes/D-222-r75-q3-indices-cancelados-reservados-sem-reuso.md) | **3A** | **Preservar índices reservados de ocorrências canceladas**, sem reutilizá-los ou renumerar as outras ocorrências **na mesma declaração** |
| [D-223](decisoes/D-223-r75-q4-status-mesmo-alvo-rng-id-atacante-declaracao-indice.md) | **4A** | Para rolagens de status **simultâneas contra o mesmo alvo**, desempatar **somente o consumo de RNG** por **ID estável do atacante**, depois **declaração estável e índice de ocorrência** |

### 56.2 Exemplos, relações e limites

- **Amostra defensiva (D-220):** um levantamento futuro pode **propor** espécies de defesa baixa, média e alta, com VIT/SPI **reais e verificáveis no nível 50**, e apresentar suas fontes e lacunas. **Nenhuma espécie, valor, conjunto de dados, tamanho de amostra, limiar entre perfis ou estatística foi aprovado ou levantado nesta atividade.** D-216 impede finalizar referência quantitativa com dados necessários não verificáveis; D-208 ainda exige aprovação posterior de atributo de referência e mitigação-alvo, seguida de validação de **K único** (D-201/D-204).
- **Bloqueio de ficha (D-221):** uma ficha **hipotética** declara `Status A` e `Status B` incompatíveis, mas omite a prioridade. **O Move fica bloqueado em combate** e a indicação precisa apontar a **prioridade faltante**. Não usar ordem das tentativas como prioridade implícita (D-213/D-215/D-217). **Não há incompatibilidades concretas de status aprovadas aqui**, nem interface ou regra nova de custos/ATB/Burst definida.
- **Índices (D-222):** plano fictício `A#1, A#2, A#3, A#4`; se `A#2` for cancelado, as demais ocorrências mantêm **#1, #3, #4** e **#2 não é reutilizado nessa declaração**. D-218 fixa os índices na declaração do ataque; D-214 conserva desempate por declaração/ocorrência; D-189 continua evitando consumo de RNG de retarget sem empate elegível. Preservar D-095 sobre KO simultâneo.
- **RNG de status (D-223):** alvo fictício Abra ID 3 sofre rolagens de status simultâneas de atacantes IDs 2 e 5; **para consumir RNG**, vem primeiro o atacante ID 2, depois ID 5. A ordenação primária **entre alvos diferentes** continua por **ID do alvo (D-219)**. Para mesmo atacante, usar declaração/ocorrência estáveis (D-214/D-218/D-222), sem substituir a ordem de status distintos **dentro da ficha (D-213)**. O evento continua **logicamente simultâneo**: não altera danos, status, resultados de KO ou prioridade entre equipes.

### 56.3 Histórico e pendências preservados

- **Dados e balanceamento:** amostra concreta, fontes e progressão de VIT/SPI no nível 50, representatividade, referência e mitigação-alvo e valor numérico K continuam em aberto. Não inventar espécies ou números.
- **Bloqueio:** não foi definido como/onde exibir o erro, o instante da validação, se haverá cobrança de ATB/Burst diante de uma tentativa bloqueada ou como o editor impede salvar fichas incompletas. Não estabelecer automaticamente comportamento fora do bloqueio expressamente aprovado.
- **Eventos:** permanecem pendentes o formato do plano declarativo, geração de ocorrências não previstas, serialização/replay, granularidade do instante lógico e possíveis empates residuais.
- **Status:** sem algoritmo ou seed de RNG de status aprovado; D-213/D-215 separam ordem de rolagens e prioridade de incompatibilidade. Não antecipar solução para status incompatíveis de Moves diferentes ou eventos com mesmas chaves de desempate.
- **Conflitos históricos:** a divergência da reapresentação R60-Q2/Q3 sobre LUK frente a D-150/D-152/D-153 permanece explicitamente **não resolvida** (GDD §12.13). D-203 mantém **odômetro fora do jogo principal**, embora permaneça código legado. D-095 mantém empate de eliminações simultâneas.
- **Escopo:** quatro arquivos D novos, índice, este consolidado e adendo histórico GDD. **Nenhum código, teste, Move, ficha, cena, asset ou VFX alterado; nenhum teste de gameplay ou levantamento quantitativo de atributos executado.**

---

## 57. Rodada 76 — perfis defensivos separados, validação sem custos, eventos condicionais e RNG de status

> **2026-11-04.** O criador aprovou **1A, 2A, 3A e 4A**, sem observações próprias. Decisões individuais **D-224 a D-227**. Atualização documental aditiva conforme D-061, sem implementação nem modificação do histórico.

### 57.1 Regras aprovadas

| Documento | Escolha | Regra |
|---|---|---|
| [D-224](decisoes/D-224-r76-q1-perfis-defensivos-separados-vit-spi-amostra.md) | **1A** | Classificar **separadamente os perfis defensivos de VIT e SPI**, contemplando representatividade **física, mágica e mista** na **proposta** de amostra |
| [D-225](decisoes/D-225-r76-q2-validar-bloqueio-antes-confirmacao-sem-custos.md) | **2A** | **Validar antes de confirmar a ação e antes de consumir ATB/Burst**; Move bloqueado por ficha incompleta **não consome recurso nem ação** |
| [D-226](decisoes/D-226-r76-q3-reservar-indices-ocorrencias-condicionais-na-declaracao.md) | **3A** | O plano determinístico inicial deve **prever ocorrências condicionais possíveis e reservar seus índices na declaração do ataque** |
| [D-227](decisoes/D-227-r76-q4-rng-exclusivo-status-seed-inicio-combate-registrada.md) | **4A** | Usar **RNG próprio para status**, com **seed gerada no início do combate e registrada para reprodução**, separado do fluxo exclusivo de retarget |

### 57.2 Exemplos e salvaguardas

- **Amostra (D-224):** uma espécie pode ser candidata ao mesmo tempo ao grupo de VIT alta e SPI baixa; a classificação é **separada**, de modo que a amostra proposta cubra especialistas físicos, mágicos e perfis mistos. **Nenhuma espécie, limiar, amostra, fórmula nem valor foi aprovado nesta rodada**. D-220 determina aprovação da composição; D-212/D-216 exigem dados de VIT/SPI reais e verificáveis **no nível 50** e registro das lacunas; D-208 exige aprovação posterior de atributo de referência e mitigação-alvo antes de validar K único (D-201/D-204).
- **Bloqueio (D-225):** ficha hipotética declara efeitos A e B incompatíveis, sem prioridade expressa. Antes de confirmar a ação, a validação bloqueia o Move, informa a prioridade ausente (**D-221**) e **não debita ATB, Burst nem oportunidade de ação**. A existência de status incompatíveis concretos não foi decidida. A interface do aviso e outras falhas de ficha seguem não especificadas.
- **Plano (D-226):** o ataque hipotético prevê `A#1` e uma possível ocorrência condicional `A#2`, e **reserva ambos os índices já na declaração**; se a condição de `A#2` não ocorrer, o índice segue reservado e não há execução ou sorteio fictício. Preservar D-218 (plano no instante de declaração), D-222 (índices cancelados não reutilizados), D-214 (ordenação dos eventos de um mesmo atacante), D-189 (RNG de retarget somente em empate elegível) e D-095 (KO simultâneo).
- **RNG de status (D-227):** gerar e **registrar uma seed própria para status no início de cada combate**, separada da seed exclusiva de retarget (D-186/D-187). Na reprodução, consumos de status seguem a **ordem primária pelo ID do alvo (D-219)**, seguida por ID do atacante, declaração e índice quando o alvo é o mesmo (D-223); as tentativas distintas dentro do Move seguem a ordem de sua ficha (D-213). A ordenação do **RNG** não cria prioridade temporal de efeitos nem modifica simultaneidade lógica.

### 57.3 Pendências e histórico preservados

- **VIT/SPI:** ainda faltam dados verificáveis no nível 50, limiares de baixo/médio/alto, espécies concretas e proposta de composição. **Não finalizar uma referência quantitativa nem homologar valor numérico de K** sem os dados e aprovações exigidos pelas D-208/D-216.
- **Bloqueio:** a interface e o texto exato do aviso, a camada técnica de validação e o tratamento de outras configurações incompletas não foram aprovados. Esta decisão **não cria uma política geral de reembolso**; bloqueio ocorre **antes de debitar** recursos.
- **Eventos:** continuam sem definição o formato do plano declarativo, eventos impossíveis de enumerar antecipadamente, limites/representação de índices e persistência do replay. A reserva de índice não gera evento real nem consome RNG.
- **RNG:** não há algoritmo, formato de seed ou log, política de consumo para chances finais exatas de 0%/100% nem protocolo completo de replay aprovados. O fluxo exclusivo de retarget continua separado, e os efeitos simultâneos preservam simultaneidade lógica.
- **Conflitos anteriores:** a divergência textual da Rodada 60 sobre escalas de LUK frente às D-150/D-152/D-153 permanece registrada no GDD §12.13 **sem nova resolução**. D-203 continua excluindo odômetro do jogo principal; D-095 mantém empate por KO simultâneo.
- **Escopo:** quatro decisões novas, índice, este consolidado e adendo GDD. **Nenhum código, teste, Move, ficha, cena, asset ou VFX modificado. Nenhum teste de gameplay ou levantamento quantitativo de atributos executado.**

---

## 58. Fichas de Moves — Rodada M1: custo de MP aprovado, estruturas aguardam quatro exemplos

> **2026-11-04.** O criador iniciou uma **série própria de decisões de fichas de Moves**, distinta das rodadas gerais de combate. Respostas recebidas: **1D, 2D, 3D e 4A**, com observação: **“Quero exemplos de 4 moves antes de definir suas ideias”**. **Apenas M1-Q4A contém regra suficientemente expressa para registro**, documentada em **D-228**. A escolha D sem redação de regra não autoriza adotar alternativas anteriores nem nova arquitetura.

### 58.1 Decisão aprovada

| Documento | Escolha | Regra |
|---|---|---|
| [D-228](decisoes/D-228-m1-q4a-mp-adicional-moves-magicos-especiais.md) | **M1-Q4A** | **Adotar custo adicional de MP no gameplay dos Moves mágicos/especiais**, **além** dos custos de ATB/Burst aplicáveis pelas decisões anteriores, com **valores individuais a definir**. **Substituir expressamente somente a regra de ausência de MP de D-032**, preservando todo o resto daquela decisão e a seção histórica §14.6 deste consolidado. |

### 58.2 Respostas pendentes, conflito histórico e delimitação

- **M1-Q1 = 1D:** não foi escolhida a organização das descrições; **em aberto**, aguardando os quatro exemplos solicitados pelo criador.
- **M1-Q2 = 2D:** não foi escolhida uma notação/estrutura de modificadores; **em aberto**, aguardando os quatro exemplos.
- **M1-Q3 = 3D:** não foi escolhida modelagem de seleção/abrangência/facção de alvos; **em aberto**, aguardando os quatro exemplos.
- **Conflito MP resolvido por precedência expressa apenas neste ponto:** D-032 registra retirada histórica de custos MP dos Moves; a **nova D-228 revoga essa retirada** para Moves mágicos/especiais. **Não editar nem apagar D-032** e **não presumir revogação** de outras regras históricas. Este consolidado já descreve MP adicional em §14.6; isso agora está alinhado quanto à existência de MP adicional, **sem homologar custos por Move, momento exato de débito ou todas as regras econômicas históricas daquela seção**.
- **Divergência com a implementação:** `scripts/data/skill.gd` ainda não possui `mp_cost` nem custo MP próprio; a cobrança adicional em gameplay **não foi implementada**. D-122 mantém categoria física/mágica distinta de movimento `MELEE / PROJECTILE / CAST / STATUS`. Nenhum valor individual ou classificação nova foi atribuído.
- **Exemplos de quatro Moves** apresentados ao criador na conversa são **propostas de visualização**, não fichas definitivas; podem reutilizar parâmetros efetivamente descritos em D-032 e `scripts/data/skill.gd`, deixando **desconhecido/pendente** onde não houver definição verificável.
- **Histórico não afetado:** permanecem a divergência de LUK da Rodada 60 (GDD §12.13), o descarte do odômetro do jogo principal (D-203), a política de status distintos/RNG (D-199/D-210/D-213/D-215/D-227), as regras de tempo próprio do Move (D-119/D-133) e o bloqueio pré-confirmação de Move incompleto (D-225).
- **Escopo da atualização:** apenas D-228, índice, este consolidado e adendo do GDD. **Nenhum código, teste, ficha de Move, cena, asset ou VFX alterado; nenhum teste de gameplay executado.**

---

## 59. Fichas de Moves — Correção do formato de tooltip e separação da descrição visual

> **2026-11-04.** Após analisar quatro exemplos da Rodada M1, o criador determinou expressamente: **“Não, está péssimo, seja mais similar a como lol descreve suas habilidades, com toda descrição, dano e efeitos em blocos de texto junto com seus modificadores e o restante como custos e wind up acima, deixa a parte do efeito visual pra descrição na ficha fora de combate”**. Regra registrada em **[D-229](decisoes/D-229-moves-tooltip-texto-integrado-visual-fora-combate.md)**. Atualização documental conforme D-061, sem implementação.

### 59.1 Regra de apresentação aprovada

- **Tooltip/descrição em combate:** manter **custos e windup acima**, como informações rápidas; apresentar abaixo **texto corrido completo** descrevendo **dano, cura, status, duração, condições de acerto, probabilidades, exceções e modificadores junto ao efeito a que pertencem**. Seguir o modo de redação de tooltips de **League of Legends** como **referência de apresentação**, não importar suas regras de gameplay.
- **Não separar** dano-base, escalas e efeitos negativos em painéis gráficos independentes, caixas numéricas ou descrições soltas que desassociem a operação do efeito.
- **Descrição visual:** somente na **ficha fora de combate**, em seção própria. Não colocar descrição estética de partículas, preparação, impacto ou dissipação visual na tooltip de combate; permitir linguagem mecânica como “projétil esquivável” ou “detona ao acertar”, porque determina o comportamento do Move.
- **Dados pendentes são pendentes:** não inventar fórmulas, escalas de STR/MAG, custo MP, velocidade, classificação de dano ou status. D-228 ainda exige custos MP individuais apenas para Moves classificados mágicos/especiais; seu valor permanece não aprovado.

### 59.2 Quatro exemplos demonstrativos (não fichas oficiais)

- **Bite — 2 ATB; windup 1,2 s:** “Morde um inimigo, causando **1,3× o dano-base** e tendo **30% de chance de aplicar Stun por 2 segundos** ao acertar. O atordoamento suspende a regeneração de ATB [...]”. Dados existentes na D-032.
- **Sand Attack — 1 ATB; windup 0,75 s:** “Dispara um projétil esquivável que **não causa dano** e, ao acertar, aplica **Blind durante 4 segundos**, fazendo cada ação ofensiva do alvo ter **35% de chance de errar**”. Os 35% são **chance de erro enquanto cego**, não chance de aplicação do efeito (D-032).
- **Dragon Rage — 3 ATB; windup 2 s:** “Dispara um projétil contra um inimigo, causando **1,6× o dano-base** e, ao acertá-lo, explode, causando o mesmo dano aos aliados desse alvo. Se errar, **não explode**”. D-032 preservada.
- **Media — 2 ATB; windup 0,5 s:** “Restaura **40% do HP máximo** de todos os aliados vivos, incluindo o usuário, com **mínimo de 12 HP por alvo**”. Regra encontrada no código atual `scripts/combat/battle.gd`, com arredondamento individual, sem assumir escala de MAG adicional.

### 59.3 Distinção entre requisitos decididos e pendências

- **M1-Q1/Q2:** a orientação textual direta posterior substitui a indefinição **apenas quanto ao formato das descrições em combate e à integração textual dos modificadores**. Não pressupõe duas descrições separadas, campos obrigatórios de cálculo ou nova linguagem técnica para os modificadores.
- **M1-Q3 permanece em aberto:** a escolha de estrutura interna para seleção, facção e abrangência de alvos **não** foi resolvida por esta correção visual. Os exemplos de alvos no texto não criam arquitetura de dados.
- **Relações preservadas:** D-032 (exceto MP superado por D-228), D-119, D-122/D-123, D-199/D-210/D-213, D-215/D-225, D-203 e demais decisões históricas. O conflito textual de LUK na R60 (§12.13 do GDD) permanece sem resolução. O uso da referência League of Legends **não aprova novas mecânicas ou valores de balanceamento**.
- **Escopo:** novo documento D-229, índice, este consolidado e adendo do GDD. Nenhum código, ficha de Move, HUD, teste, asset, cena ou VFX alterado; nenhuma validação de gameplay executada.

---

## 60. Fichas de Moves — Dano e cura numéricos nas tooltips (correção posterior à D-229)

> **2026-11-04.** O criador corrigiu os exemplos anteriores com a declaração literal: **“TÁ PÉSSIMO VOU SABER OQ É 1X3 O DANO BASE?? É PRA TER NÚMEROS NÚMEROS NÃO FORMULAS”**. Regra registrada em **[D-230](decisoes/D-230-moves-tooltip-dano-cura-numericos-sem-formulas.md)**, sem alterar código nem reescrever registros históricos.

### 60.1 Regra de apresentação aprovada

- **Mostrar valores concretos de dano e cura em pontos** na descrição em combate, legíveis imediatamente. **Não usar “1,3× dano-base”, “1,6× dano-base”, cálculos com STR/MAG ou fórmulas como substitutos do número de dano** na tooltip.
- Integrar o **número de dano/cura** na frase que explica seu efeito, junto com os **valores de status, chance, duração, modificadores e condições**, sem cards técnicos separados; manter **custos e windup acima** (D-229) e **descrição visual estética somente na ficha fora de combate**.
- **Os números exibidos precisam ser fundamentados nos parâmetros verificados que se apliquem ao contexto.** A exigência de números **não aprova dano-base absoluto, coeficientes de STR/MAG, valores de MP, regras de arredondamento novas ou um mecanismo de atualização dinâmica da tooltip**. Se um número ainda não puder ser obtido com fidelidade, registrar a pendência em vez de inventá-lo.
- **Exemplos de cálculo no código atual** com o Gible existente (`attack=9`), sem crítico, fraqueza ou modificadores de ATK/DEF/posição: **Bite causa 12 pontos** e **Dragon Rage causa 14 pontos** por inimigo com defesas neutras; **Sand Attack causa 0**; **Media pode restaurar 13 pontos de HP para um aliado com HP máximo de 32**, sendo uma cura dependente do HP máximo e do HP faltante. **Todos são resultados de cenários delimitados, não danos-base nem curas universais homologados**.
- **D-229 fica esclarecida, não apagada**: seus exemplos antigos que trazem somente `1,3×` ou `1,6×` **não são texto de tooltip suficiente**. As razões de potência continuam nos parâmetros de motor e na documentação histórica da D-032 até que os valores-base finais sejam definidos.

### 60.2 Pendências e compatibilidades

- **M1-Q3** (estrutura técnica da seleção/facção/abrangência dos alvos) continua em aberto. **D-228** aprovou MP adicional para Moves mágicos/especiais, mas os custos individuais estão pendentes.
- **Faltam decisões** para valores-base de design e fórmulas de STR/MAG por Move e sobre como apresentar valor numérico quando o contexto do atacante/alvo ainda não existe ou muda. Não fixar números exemplificados como atributos permanentes dos Moves. D-198/D-205 mantêm suas regras de arredondamento; código atual ainda não implementa integralmente o combate consolidado.
- **Escopo executado:** criar D-230 e atualizar índice, este consolidado e adendo GDD. **Não alterar nenhuma linha de código, teste, cena, HUD, ficha oficial, asset ou VFX; não executar testes de gameplay.**

---

## 61. Rodada 77 — limites VIT/SPI a aprovar, filtragem IA, máximo de eventos e chances extremas sem RNG

> **2026-11-04.** O criador aprovou **1A, 2A, 3A e 4A**, sem observações adicionais. Registros individuais **D-231–D-234**. Aditivo à documentação conforme D-061. **Preservar integralmente §58–§60 e D-228–D-230** sobre fichas e tooltips, incluídos na main antes desta rodada. Não altera código.

### 61.1 Regras aprovadas

| Documento | Escolha | Regra |
|---|---|---|
| [D-231](decisoes/D-231-r77-q1-propor-faixas-vit-spi-por-distribuicao-verificavel.md) | **1A** | Propor **faixas defensivas baixas, médias e altas** com base na **distribuição verificável de VIT e SPI no nível 50**, com **aprovação dos limites antes de classificar a amostra** |
| [D-232](decisoes/D-232-r77-q2-ia-excluir-moves-incompletos-antes-selecao.md) | **2A** | **Excluir Moves com configuração de incompatibilidade incompleta** da lista de candidatos da **IA antes da seleção tática**, **sem gastar ação ou recursos** |
| [D-233](decisoes/D-233-r77-q3-limite-maximo-explicito-ocorrencias-condicionais.md) | **3A** | Move com **quantidade variável de ocorrências condicionais** precisa de **máximo explícito**, reservando índices possíveis na declaração; **sem máximo, o plano está incompleto** |
| [D-234](decisoes/D-234-r77-q4-chance-status-extrema-sem-consumir-rng.md) | **4A** | Para chance final de status **exatamente 0% ou 100%**, determinar **falha ou sucesso sem consumir RNG**, mantendo acerto, sobrevivência e outras condições |

### 61.2 Exemplos e compatibilidade

- **VIT/SPI (D-231):** propor cortes entre baixo/médio/alto fundamentados **separadamente** nas distribuições de valores de VIT e SPI **reais e verificáveis no nível 50** (D-224). **Pedir aprovação dos limiares antes de utilizá-los** na classificação e posteriormente submeter a composição concreta da amostra à aprovação (D-220). **Nenhum corte, percentil, dado de espécie, amostra, parâmetro de referência, mitigação-alvo ou K foi escolhido nesta rodada**. D-216 impede fechar referência quantitativa na falta dos dados necessários.
- **IA (D-232):** se uma ficha hipotética declarar `Status A` e `Status B` incompatíveis **sem prioridade explícita**, excluir esse Move **antes da escolha tática** (D-215/D-217/D-221); não consumir ação nem ATB/Burst/MP só por tentar considerá-lo (D-225). **Não determinar automaticamente Tackle ou outra saída caso não reste candidato válido**. Preservar a regra independente de MP adicional para Moves mágicos/especiais **D-228**, com valores ainda pendentes.
- **Ocorrências (D-233):** se um Move hipotético pode criar de zero até **três** ocorrências condicionais e tiver **máximo explicitamente definido como três**, reservar todos os índices na declaração; eventos não realizados **não consomem RNG** nem liberam índices. **Três é apenas um valor ilustrativo**, não um limite de Move real. Preservar D-218/D-222/D-226 e as ordenações de retarget. **O plano sem máximo está incompleto**; esta decisão **não autoriza por si só bloqueio em combate por esse motivo** (o bloqueio D-221/D-225 é específico da incompatibilidade de status).
- **Status/RNG (D-234):** chance final probabilística de status 0% **falha** e 100% **tem sucesso**, **sem consumo da seed/fluxo exclusivo de RNG de status (D-227)**. Exemplo: 103% intermediários limitados a 100% conforme D-143 geram sucesso **apenas se a tentativa for elegível**; se alvo foi esquivado ou derrotado, não há tentativa (D-195/D-199). Para 0% < chance < 100%, seguir a ordenação determinística de D-219/D-223 e a ordem da ficha D-213. Efeitos declarados garantidos continuam garantidos (D-134).

### 61.3 Pendências e histórico preservados

- **Amostragem:** valores verificáveis de VIT/SPI no nível 50, tamanho da amostra, estratégia de distribuição e cortes concretos permanecem pendentes; não escolher K ou fórmula nova.
- **IA e fichas:** reação caso **nenhum Move válido** permaneça na lista e tratamento de outras causas de incompletude não foram definidos. D-228–D-230 continuam aprovando MP e apresentação numérica da tooltip, sem alterar custos ou descrever VFX em combate.
- **Plano de eventos:** máximos individuais de ocorrências condicionais, representação do plano, como tratar evento além do máximo e decisão específica para plano incompleto permanecem abertos. Não escolher política de bloqueio para essa causa por analogia.
- **RNG de status:** algoritmo, sementes concretas, formato de registros/replay e tolerância para valores *próximos*, mas não iguais, a 0%/100% permanecem abertos; preservar simultaneidade lógica e KO simultâneo D-095.
- **Conflitos históricos:** a diferença de escala de LUK na reapresentação R60-Q2/Q3 frente às D-150/D-152/D-153 continua registrada em GDD §12.13, **sem nova decisão**. D-203 mantém o odômetro fora do jogo principal, sem remover código.
- **Escopo:** quatro novos D individuais, índice, seção consolidada e adendo histórico GDD. **Nenhum código, teste, Move, ficha, cena, asset ou VFX modificado; nenhum teste de gameplay realizado.**

---

## 62. Rodada 78 — tercis VIT/SPI, alternativa Tackle da IA, plano sem máximo e status entre Moves

> **2026-11-04.** O criador aprovou expressamente **1A, 2A, 3A e 4A**, sem observações próprias. Novos registros **D-236 a D-239**. Adendo documental, sem alterar o histórico ou código. Preservar **D-235** (Moves/VFX independentes de personagem e lado) e D-228–D-230 (MP e tooltips).

### 62.1 Regras aprovadas

| Documento | Escolha | Regra |
|---|---|---|
| [D-236](decisoes/D-236-r78-q1-tercis-separados-vit-spi-faixas-para-aprovacao.md) | **1A** | **Propor limites baixo/médio/alto por tercis** de distribuições **verificáveis de VIT e SPI no nível 50**, **separadamente**, submetendo os **números concretos à aprovação** antes de classificar a amostra |
| [D-237](decisoes/D-237-r78-q2-ia-considerar-tackle-se-sem-moves-validos.md) | **2A** | Se não houver Move válido na lista da IA, **permitir considerar Tackle separadamente somente se estiver elegível**; caso contrário, **reação permanece pendente** |
| [D-238](decisoes/D-238-r78-q3-bloquear-move-plano-sem-maximo-antes-custos.md) | **3A** | **Bloquear a confirmação** do Move com plano de ocorrências condicionais **sem máximo explícito**, **antes de consumir ação ou recursos**, identificando a **omissão exata** |
| [D-239](decisoes/D-239-r78-q4-politica-explicita-status-incompativeis-moves-distintos.md) | **4A** | Exigir **política explícita de prioridade, aprovada pelo criador**, para resolver **status declarados incompatíveis oriundos de Moves distintos**, **sem inferir prioridade das fichas isoladas** |

### 62.2 Exemplos, limites e compatibilidades

- **Tercis de VIT/SPI (D-236):** após obter **dados reais e verificáveis no nível 50** (D-212/D-216), propor **separadamente** tercis e cortes de VIT e SPI, apresentando **limites numéricos para aprovação antes de classificar espécies** (D-231). **Não existe ainda proposta de valores, universo amostral, cortes aprovados ou classificação concluída.** A composição da amostra precisa de aprovação posterior (D-220), e K único/mitigação-alvo seguem pendentes (D-201/D-204/D-208).
- **IA/Tackle (D-237):** quatro Moves abstratos da IA são excluídos por prioridade de status incompatíveis ausente (D-232); quando **nenhum candidato válido** restar, a IA **pode considerar Tackle como ação separada**, **somente se Tackle estiver elegível**. Se não estiver, a reação **não foi decidida** — não presumir espera ou perda da ação. A simples exclusão não gasta ação/ATB/Burst/MP, conforme D-225.
- **Plano condicional (D-238):** Move hipotético prevê número variável de ocorrências mas **não define máximo** (D-233). A **confirmação é bloqueada antes do débito de ação, ATB, Burst ou MP**, com indicação precisa de **qual máximo obrigatório está faltando**. D-218/D-222/D-226 mantêm o plano determinístico e índices reservados na declaração. A decisão **não** define o filtro da IA para essa segunda causa de incompletude nem a mensagem/UI do aviso.
- **Incompatibilidade entre Moves (D-239):** um Move hipotético aplica X, outro aplica Y, e **uma regra futura** declara X/Y incompatíveis. **Não escolher vencedor** sem política de precedência entre Moves **expressa e aprovada**. Não usar como política implícita ID do atacante, ordem de declaração da ficha ou consumo de RNG. Preservar D-213/D-215/D-217 para os casos já definidos, D-219/D-223/D-227/D-234 para RNG de status e D-095 para KO simultâneo.

### 62.3 Pendências, conflitos e escopo

- **Atributos:** faltam dados VIT/SPI nível 50, seleção/verificação das distribuições, convenção de empates nos tercis, números dos limites e aprovação da amostra. Não homologar valores defensivos ou K nesta etapa.
- **IA:** quando **nenhum Move válido nem Tackle elegível** existir, **não há reação aprovada**. O filtro de IA para Move com plano condicional sem máximo continua pendente.
- **Eventos:** valores de máximos por Move, comportamento ao ultrapassá-los e formato do plano permanecem abertos; o bloqueio sem máximo é novo requisito documental, não implementação técnica.
- **Status:** política concreta para incompatibilidades **entre Moves diferentes**, sua configuração e reação diante de ausência da política **não foram aprovadas**. Não assumir incompatibilidades específicas. Probabilidades finais exatas de 0%/100% seguem D-234.
- **Conflitos históricos:** preservar a divergência textual da reapresentação R60-Q2/Q3 frente a D-150/D-152/D-153 no GDD §12.13; não mudar LUK. D-203 mantém odômetro fora do jogo principal, sem remover protótipo. **D-235 permanece em vigor** como regra de independência de Moves/VFX, inclusive protótipos, sem qualquer alteração nesta rodada.
- **Somente documentação:** quatro documentos D novos, índice, consolidado e adendo histórico GDD. **Nenhum código, teste, ficha de Move, IA, cena, asset ou VFX modificado; nenhum teste de gameplay executado.**

---

## 63. Rodada 79 — valores empatados em tercis, espera da IA, excedentes do plano e matriz entre status

> **2026-11-04.** O criador aprovou expressamente **1A, 2A, 3A e 4A**, sem observações adicionais. Registros individuais **D-240 a D-243**. Atualização documental aditiva conforme D-061, sem implementação. Preservar D-235 sobre independência de Moves/VFX e D-228–D-230 sobre MP e tooltips.

### 63.1 Regras aprovadas

| Documento | Escolha | Regra |
|---|---|---|
| [D-240](decisoes/D-240-r79-q1-igualdade-atributo-mesma-faixa-tercis.md) | **1A** | Espécies com **igual valor de VIT ou SPI** ficam na **mesma faixa do atributo** mesmo que os três grupos resultem em **quantidades diferentes** |
| [D-241](decisoes/D-241-r79-q2-ia-sem-opcoes-reavaliar-proxima-oportunidade.md) | **2A** | Se **nenhum Move válido nem Tackle elegível** existir, a IA **não inicia ação nem consome recursos**, **reavaliando na próxima oportunidade normal de decisão** |
| [D-242](decisoes/D-242-r79-q3-ocorrencia-excedente-rejeitar-e-registrar-violacao.md) | **3A** | **Impedir a execução** de ocorrência condicional **acima do máximo** e **registrar violação do plano**, **preservando eventos válidos já resolvidos** |
| [D-243](decisoes/D-243-r79-q4-matriz-pares-status-incompativeis-aprovacao.md) | **4A** | Elaborar **matriz explícita de prioridades por pares de status declarados incompatíveis entre Moves distintos**, **sujeita à aprovação**; **nenhuma entrada concreta aprovada** |

### 63.2 Exemplos e compatibilidades

- **Tercis VIT/SPI (D-240):** se valores **hipotéticos** de VIT iguais a `50` estiverem em uma fronteira proposta, **todas as espécies com VIT 50 ficam no mesmo grupo de VIT**, ainda que a contagem do grupo fique desigual. A faixa exata do valor fronteiriço ainda depende de limites aprovados (D-236). VIT e SPI são classificados separadamente (D-224), utilizando **dados verificáveis no nível 50** (D-212/D-216), com cortes e amostra sujeitos à aprovação (D-220/D-231). **Nenhum número, espécie, limiar ou K foi homologado.**
- **IA (D-241):** quando a lista de Moves válidos ficar vazia (D-232) e Tackle **não estiver elegível** (D-237), a IA **não começa ação, não consome ATB/Burst/MP e reavalia na próxima oportunidade normal**, sem novo temporizador nem escolha de fallback forçada. A regra não inventa o instante/frequência exata de decisão ou perda da oportunidade.
- **Plano (D-242):** Move com máximo **hipotético** de três ocorrências tenta executar uma quarta; a **quarta é rejeitada**, a **violação é registrada**, e eventos anteriores já validamente resolvidos são **preservados**, sem criar novos índices ou consumir RNG para evento inválido. D-218/D-222/D-226/D-233/D-238 permanecem: plano e índices reservados na declaração, máximo obrigatório, bloqueio pré-ação quando máximo não foi definido. Não há política aprovada para prosseguimento/cancelamento de eventos **posteriores** à violação, nem formato do registro.
- **Matriz de incompatibilidades (D-243):** a política exigida por D-239 para conflitos **entre Moves distintos** deverá usar **matriz explícita por pares de status** e ser aprovada pelo criador antes de definir vencedores. **Nenhum par real nem precedência foi declarado**. Prioridades existentes **dentro da mesma ficha** (D-215/D-217) não são automaticamente transferidas. A ordem do RNG de status (D-219/D-223/D-227/D-234) não define prioridade entre efeitos. Preservar a simultaneidade de KO (D-095).

### 63.3 Pendências e história

- **Atributos:** permanecem faltando valores de nível 50 verificáveis, cortes por tercis e a convenção específica para faixa fronteiriça empatada, aprovação da amostra e parâmetros de mitigação/K.
- **IA:** a frequência exata da oportunidade normal, a semântica operacional enquanto não há opções e os filtros de IA para outras causas de Move incompleto não estão especificados nesta rodada.
- **Eventos:** o **formato do registro de violação**, reação a novas ocorrências válidas após o excedente e limites concretos por Move continuam abertos; nenhuma implementação de logging ou rollback foi autorizada.
- **Status:** a **estrutura geral em matriz está aprovada**, mas pares incompatíveis e prioridades **não**; falta aprovar entradas concretas e procedimento para políticas ausentes. Não inferir incompatibilidades de status nem árbitro por atacante, Move ou RNG.
- **Conflitos preservados:** não conciliar unilateralmente a divergência R60-Q2/Q3 de LUK frente a D-150/D-152/D-153 (GDD §12.13); D-203 mantém odômetro fora do jogo principal, sem remover protótipo. A D-235 segue obrigatória para Moves/VFX de qualquer personagem, lado ou protótipo.
- **Escopo:** quatro arquivos D novos, índice, consolidação e adendo GDD. **Nenhum código, IA, teste, Move, ficha, cena, asset ou VFX alterado; nenhum teste de gameplay ou coleta de atributos realizado.**

---

## 64. Fichas de Moves — Rodada M2: parâmetros técnicos separados, efeitos individuais e visual fora de combate

> **2026-11-04.** O criador aprovou expressamente **1A, 2A, 3A, 4A, 5A e 6A**; **observações: nenhuma**. Decisões individuais **D-244 a D-249**. Série específica de fichas de Moves, independente da numeração das rodadas gerais. Registro aditivo pela D-061, sem implementação.

### 64.1 Escolhas registradas

| Decisão | Escolha | Regra aprovada |
|---|---|---|
| [D-244](decisoes/D-244-m2-q1-dano-base-categoria-escalas-separadas.md) | **1A** | Q1A: separar dano-base, categoria físico/mágico e escalas STR/MAG na ficha técnica; tooltip com dano numérico calculado |
| [D-245](decisoes/D-245-m2-q2-windup-trajeto-velocidade-projetil-independentes.md) | **2A** | Q2A: windup, tempo-base de deslocamento e velocidade de projétil separados; usar só modificadores aprovados |
| [D-246](decisoes/D-246-m2-q3-selecao-faccao-abrangencia-alvos-separadas.md) | **3A** | Q3A: seleção Self/One/Two/All, facção ally/enemy/both e abrangência condicional dos efeitos como dimensões distintas |
| [D-247](decisoes/D-247-m2-q4-cura-buffs-status-dispel-efeitos-individuais.md) | **4A** | Q4A: cura, buffs/debuffs, status e Dispel como efeitos individuais com magnitude, condição, chance, duração e ordem aplicáveis |
| [D-248](decisoes/D-248-m2-q5-visual-preparo-emissao-impacto-dissipacao-ficha-fora-combate.md) | **5A** | Q5A: descrição visual somente fora do combate, separada por preparação, movimento/emissão, impacto e dissipação quando aplicável |
| [D-249](decisoes/D-249-m2-q6-dispel-lista-explicita-removiveis-excecoes.md) | **6A** | Q6A: Move com Dispel deve listar expressamente efeitos removíveis e exceções aplicáveis |

### 64.2 Aplicação às fichas e relação com as regras anteriores

- **Dano e escala (D-244):** registrar separadamente **dano-base, categoria física/mágica e escalas STR/MAG** na ficha técnica; no texto integrado da **tooltip em combate**, exibir **dano numérico calculado em pontos**, não multiplicadores ou fórmulas isolados (D-229/D-230). STR serve de referência a dano físico e MAG a dano mágico/especial (D-122). Somente efeitos explicitamente declarados escaláveis pela ficha recebem escala MAG (D-123). **Nenhuma fórmula, coeficiente, valor-base ou categoria individual de Move foi escolhida**.
- **Tempos (D-245):** **windup**, **tempo-base de deslocamento próprio de cada Move** e **velocidade individual de projétil** são parâmetros separados quando aplicáveis. Preservar D-119/D-133/D-136 para AGI e passos nos trajetos e D-057/D-067/D-077/D-078 para ondas AoE com geometria e velocidade constante por Move. **Não deduzir que a AGI altera o projétil** ou que há duração para um deslocamento inexistente.
- **Alvos (D-246):** separar **seleção** (`Self/One/Two/All`), **facção elegível** (`ally/enemy/both`) e **abrangência de cada efeito**, inclusive condições especiais. Exemplo existente: **Dragon Rage** é alvo único com impacto em área condicional (D-032); não transformar todo AoE em alvo principal, preservando D-007/D-037. **Não inventar regras de alvos ou combinações** não definidas nas fichas.
- **Efeitos (D-247):** registrar individualmente **cura, buff/debuff, status e Dispel**, com **magnitude, condições, chance, duração e ordem quando aplicáveis**; não impor chance ou duração inexistentes. Preservar D-210/D-213/D-215 para tentativas, ordem e incompatibilidades, D-199/D-202/D-207/D-211 para condições e D-227/D-234 para RNG. Matriz entre Moves (D-243) ainda não aprovada concretamente. **Não importar efeitos adicionais** para Moves existentes.
- **Visual (D-248):** dividir a **descrição visual da ficha fora do combate** em **preparação, movimento/emissão, impacto e dissipação** quando aplicáveis; no combate manter o **texto mecânico integrado** sem descrição artística (D-229). Não introduzir VFX, câmera, movimentos ou fases que não estejam aprovados; D-235 exige o mesmo Move independente de personagem, lado e posição.
- **Dispel (D-249):** Move que possuir Dispel lista **expressamente os efeitos removíveis e as exceções aplicáveis**; não declarar qualquer par/status como removível ou imune sem decisão. Não atribuir Dispel a Media nem a qualquer outra habilidade sem sua ficha declarar o efeito.

### 64.3 Limites e histórico preservados

- O formato de **tooltip estilo LoL** (custos/windup acima, texto integrado em combate, valores numéricos de dano/cura) é vigente por **D-229/D-230**. **A ficha técnica** é distinta da tooltip; a M2 não a converte em painéis de gameplay, nem aprova cálculos STR/MAG, efeitos concretos, números de MP ou um novo modelo de runtime.
- **D-228:** Moves mágicos/especiais têm MP adicional aos recursos aplicáveis, com custos **individuais pendentes**; prevalece somente no conflito de MP com a D-032. Não decidir automaticamente quais Moves individuais são mágicos/especiais a partir do tipo de execução.
- **D-235:** todo Move/VFX funciona independentemente de personagem, equipe, lado, posições fixas e câmera. **Sem teste** de lados/atacantes/alvos; esta é documentação.
- **Pendências:** fórmulas-base e coeficientes, valores individuais, tempos/velocidades, regras de mistura de alvos, herança de campos entre efeitos, critérios de Dispel e efeitos removíveis, detalhes estéticos, validação de runtime e números numéricos de preview sem alvo identificado.
- **Conflitos históricos preservados:** divergência de LUK da Rodada 60 frente a D-150/D-152/D-153 (GDD §12.13) não resolvida; D-203 mantém odômetro fora do jogo principal. D-215/D-217/D-221/D-225/D-238 mantêm validações de fichas incompletas em situações aprovadas.
- **Escopo:** seis novos documentos de decisão (D-244 a D-249), índice, este consolidado e adendo do GDD. **Nenhum código, ficha operacional, teste, HUD, cena, asset, animação, câmera ou VFX modificado. Nenhum teste de gameplay executado.**

---

## 65. Rodada 80 — fronteiras de tercis, filtro da IA, continuidade do plano e status já ativos

> **2026-11-04.** O criador aprovou **1A, 2A, 3A e 4A**, sem observações adicionais. Decisões individuais **D-250 a D-253**, adicionadas conforme D-061. **Preservadas integralmente a série M2 (D-244 a D-249, §64), D-235 e demais regras históricas.** Nenhum código modificado.

### 65.1 Decisões aprovadas

| Documento | Escolha | Regra |
|---|---|---|
| [D-250](decisoes/D-250-r80-q1-valor-igual-limite-tercil-faixa-superior.md) | **1A** | Valor de **VIT ou SPI exatamente igual a limite aprovado** entra na **faixa superior**; todos os valores iguais recebem a mesma categoria |
| [D-251](decisoes/D-251-r80-q2-ia-filtrar-moves-sem-maximo-condicional.md) | **2A** | **Excluir antes da escolha tática da IA** Moves com **máximo condicional obrigatório ausente**, sem consumir recurso ou ação |
| [D-252](decisoes/D-252-r80-q3-continuar-eventos-validos-apos-excedente.md) | **3A** | **Rejeitar e registrar apenas a ocorrência excedente**, **continuar eventos posteriores válidos previstos** no plano e preservar os anteriores |
| [D-253](decisoes/D-253-r80-q4-matriz-incompatibilidade-simultaneos-e-ativos.md) | **4A** | **Aplicar matriz aprovada** de prioridades por pares de status incompatíveis **entre Moves diferentes**, tanto quando simultâneos quanto quando um status já ativo conflita com novo status de outro Move |

### 65.2 Exemplos e compatibilidades

- **Tercis (D-250):** com **limite hipotético, não aprovado, de VIT=50** entre defesa baixa e média, **todas** as espécies com VIT 50 ficam na **faixa média**. No limite aprovado entre média e alta, os valores iguais ficam na alta. Preservar D-240 (valores iguais nunca separados), D-224/D-236 (tercis e classificação separados para VIT/SPI) e D-212/D-216/D-220/D-231 (valores reais nível 50, cortes e composição sujeitos a aprovação). **Não existem cortes, amostra ou K numérico aprovados** (D-208).
- **IA (D-251):** antes da seleção tática, **filtrar tanto Moves sem prioridade obrigatória entre status incompatíveis (D-232)** quanto **Moves sem máximo obrigatório de eventos condicionais (D-233/D-238)**. Essa exclusão não debita **ATB/Burst/MP nem ação**. Se não restar Move válido, preservar **D-237** (Tackle separadamente se elegível), e **D-241** (se tampouco Tackle for elegível, não agir/gastar e reavaliar na próxima oportunidade normal). Não introduzir novas causas de filtro.
- **Ocorrências (D-252):** com máximo **fictício** de três, a tentativa de ocorrência `#4` é **rejeitada e registrada**, sem desfazer os eventos válidos `#1`/`#2`. Uma ocorrência `#3` que esteja **validamente planejada e ainda elegível** pode continuar **depois**, sem permitir índices novos ou excedentes. Preservar D-218/D-222/D-226/D-233/D-238/D-242, demais cancelamentos válidos e D-095 para resultados simultâneos.
- **Status incompatíveis (D-253):** a futura **matriz aprovada por pares (D-239/D-243)** aplica a mesma precedência a dois efeitos de **Moves distintos** que sejam simultâneos ou a **status já ativo e novo status proveniente de outro Move**. **Não há nenhum par real aprovado, nenhuma linha de matriz preenchida, nem vencedor definido.** Preservar D-215/D-217 para a mesma ficha; D-210/D-213/D-219/D-223/D-227/D-234 para tentativas e RNG. Não inferir remoções, durações, supressões ou prioridade via ordem de RNG.

### 65.3 Pendências e histórico preservados

- **Atributos:** não foram levantados VIT/SPI nível 50 nem calculados tercis; continuam pendentes cortes, fonte/distribuição, amostra, referência, mitigação e K único. A escolha de faixa superior só se aplica quando um limite tiver sido aprovado.
- **IA:** não foram aprovadas novas regras de frequência da decisão, elegibilidade de Tackle, modo de informar erro ou filtros além das duas causas específicas já declaradas; nenhuma implementação foi autorizada.
- **Eventos:** o formato do registro de violação, limites concretos de cada Move e demais falhas do plano continuam em aberto. D-252 mantém apenas eventos futuros **válidos/elegíveis**.
- **Status:** a matriz ainda depende de **pares concretos e precedências aprovadas**; não há política de remoção/reaplicação/duração nem procedimento para entrada inexistente. A nova abrangência **não** cria incompatibilidades.
- **Preservações:** D-228–D-230 e D-244–D-249 preservam MP, fichas técnicas e tooltips; D-235 preserva a independência dos Moves/VFX para qualquer personagem/lado; D-095 mantém KO simultâneo; D-203 exclui odômetro no jogo principal. Divergência histórica de LUK da R60 (GDD §12.13) permanece sem conciliação.
- **Escopo:** quatro D individuais, índice, este consolidado e adendo GDD. **Nenhum código, IA, teste, Move, ficha operacional, cena, asset ou VFX modificado; nenhum teste de gameplay realizado.**

