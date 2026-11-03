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
