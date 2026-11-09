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
11. **[CONVERSA 2026-11-08]** A biblioteca de VFX de referência passa a ser uma **cena Godot separada do jogo principal**, sem HTML, com flipbooks/addons e as skills de VFX do Godot; o **Slash Arc está descartado**. Por ora, **somente pesquisa** de **4 dos 19** efeitos (Vortex Mesh, Motion Trail, Shockwave Ring, Anime Impact Flipbook), escolhidos pelo assistente; a construção será do zero. Nada do jogo principal muda (D-1017).
12. **[CONVERSA 2026-11-08/09]** A biblioteca de **ferramentas** de pesquisa/criação de VFX é independente de personagem, time e lado (D-235), só observa e mede (não muda dano, alcance, tempo, acerto, ATB nem câmera do jogo), reaproveita o que já existe sem duplicar e é entregue **uma ferramenta por vez**, mostrando funcionando. Ordem aprovada em D-1020; **ferramentas 1 (gravador), 4 (corpo/clipes) e 6 (captura de referência) implementadas e testadas**; as ferramentas 2, 3 e 5 seguem pendentes. Nada de commit/push sem pedido (D-022).

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

- **[README/CÓDIGO / D-396 / D-397 / D-398]** 12 elementos oficiais (nomes exclusivamente em inglês): Neutral, Fire, Water (substitui Ice/Gelo), Electric, Wind, Psychic, Light, Dark, Nature (engloba toxinas e flora), Sound, Earth, Mystic (equivalente ao Almighty de Megaten, dano transcendente puro que ignora afinidades elementais convencionais).
- **Fraqueza:** dano ×**1,5** (`WEAKNESS_MULT`). **Crítico:** **10%** de chance (`CRIT_CHANCE`), dano ×**2** (`CRIT_MULT`); `whiff` (Evade cedo) torna o golpe seguinte crítico. **[CÓDIGO]**
- **Dano base [CÓDIGO]:** `round(ataque × potência × fraqueza × crítico × passos)`, mínimo 1, depois o alvo aplica defesa (buff de defesa ±25% por estágio, mínimo ×0,4).
- **Sorte [GDD R11-Q5]:** influencia probabilidades de combate (crítico etc.). **[PENDENTE]** o que exatamente e fórmulas. **[CÓDIGO]** hoje o crítico é fixo em 10%.
- **Buffs/debuffs [GDD R10-Q4]:** por **estágios discretos**, não percentuais arbitrários. **[CÓDIGO]** estágios −2..+2 para ataque, defesa e velocidade, **25% por estágio** (ataque ×0,4 mín., velocidade ×0,3 mín.), zerados no fim da batalha. **[PENDENTE]** duração, acumulação e demais atributos.
- **Atributos [GDD R10–R11 / D-269 / D-390 / D-391]:** Seis atributos oficiais (**STR, MAG, VIT, WIS, AGI, LUK**). O atributo Spirit foi oficialmente renomeado para **WIS** (*Wisdom*) (D-391). Sem escala 1–100 (D-269). No nível 1, cada espécie possui um orçamento exato de **15 pontos base** distribuídos entre os seis atributos proporcionalmente aos jogos de origem (D-390).
- **Escala de HP e MP [D-391 / D-392]:** O HP aumenta com a Vitality (VIT) e o MP aumenta com a Wisdom (WIS) (D-391). Fórmula fechada de HP anti-hitkill: $\text{HP} = 25 + 10 \times \text{Nível} + 25 \times \lfloor\frac{\text{Nível}}{10}\rfloor + 2 \times \text{VIT}$ (+10 HP/nível, +25 de bônus adicional nos marcos 1, 10, 20, 30... e +2 HP por ponto de VIT) (D-392).
- **Regeneração de MP e Custos [D-413]:** Recuperação de **+4 MP a cada 8,0 segundos** em combate ativo (até o teto de MP máximo). O temporizador de regeneração é individual para cada personagem (aliados e inimigos) e é zerado imediatamente toda vez que o combatente gasta MP executando um move. O Abra possui piso mínimo obrigatório de **20 MP** ($\\text{MP} \\ge 20$). Todos os moves possuem custos calibrados de MP (0 MP para básico Tackle, 2–3 MP leves, 4–6 MP médios, 7–9 MP fortes/AoE). Uma HUD visual indica o progresso do temporizador individual de recarga.
- **Progressão e Alocação de Nível [D-394]:** O líder (jogador) ganha **1 ponto livre** para alocar por nível comum e **3 pontos livres** nos marcos a cada 10 níveis (10, 20, 30...). Aliados (IA) não possuem distribuição manual: evoluem por **proficiência baseada em suas ações reais em combate** modulada por Tactics e Nature (D-394).
- **Natures Iniciais e IA [D-271 / D-393]:** Catálogo inicial de **8 Natures** (Hardy, Docile, Brave, Timid, Modest, Calm, Jolly, Adamant) com modificadores *flat* de −3 a +3 somando sempre exatamente zero. Natures não alteram taxas de crescimento por nível (D-271). Influenciam o comportamento da IA (reserva de ATB e agressividade), com precedência integral da postura do menu Tactics (D-001 / D-393).
- **Identificação dos Moves — Três Ícones e Conteúdo Técnico [D-395 / D-396 / D-397 / D-398 / D-403 / D-404 / D-406 / D-407 / D-408 / D-409 / D-410 / D-411 / D-412 / D-414 / D-415 / D-416 / D-417 / D-419 / D-420]:** Cada Move exibe até 3 ícones: (1) **Tipo de Move** (Physical [Starburst vermelho], Magical [Sparkle 4 pontas azul], Guard [Escudo sólido preenchido cor Neutral], Dodge [Sidestep Swerve << em âmbar #fcb900, distinto de Electric], ou nenhum para puro status); (2) **Alcance / Entrega** (Seta ↑ para Melee, Traço — para Mid Range, Seta ↓ para Long Range, Círculo aberto grande ○ sem preenchimento para Efeito em Área sem trajeto [como Media], ou nenhum para status — todas obrigatoriamente com **fundo branco** [D-396/D-403/D-404]); (3) **Elemento** (glifo vetorial com apoio visual nítido e nome em inglês [D-397/D-398/D-403/D-404/D-406/D-407/D-408/D-409/D-410/D-411/D-412/D-414], com Neutral sendo círculo preenchido, Water substituindo Ice, Electric com amarelo elétrico luminoso [#fde047], Wind [fundo #4ff7ba, vórtice em espiral monolítico em preto sólido com canal esculpido em negativo ratificado em D-414], Mystic [Bannō Sigil de 8 pontas em fundo #65B5B3, 12º elemento Almighty], Sound sem arcos, Psychic com espiral hipnótica P5). Todos os 12 elementos do sistema estão 100% oficializados e congelados. Conforme D-415/D-416/D-419, os fundos dos ícones utilizam cores vibrantes e limpas em blocos flat (sem bordas/outlines). Na hotbar inferior e nos elementos à frente do nome no painel direito, os blocos adotam formato de paralelogramo inclinado para a direita (`/ /`). Na ficha de inspeção do move, o nome é movido para o topo e os ícones de tipo e alcance ficam posicionados em linha ao seu lado direito na mesma altura da fonte (inclusive os blocos de ATB, MP e POWER), liberando a área inferior para ficha técnica detalhada. Conforme **D-417**, todas as fichas e cards de moves em todas as HUDs do jogo (`hud_post_combat.html`, `status_screen.gd`, `battle_hud.gd`, `skill_info_panel.gd`) passam a adotar o padrão oficial consagrado: fundo flat na cor sólida do elemento, glifo do elemento estampado em marca d'água translúcida em segundo plano atrás do nome, tipografia Teko bold ampliada, trio de badges e indicação explícita dos custos de ATB e MP. Conforme **D-420**, é estritamente proibido repetir em textos informativos dados que já estão evidentes na interface (custos de ATB/MP, Power e Elemento); o espaço deve detalhar: (1) O que o move faz (efeito/mecânica real), (2) Seu visual (VFX, iluminação e estética 3D), (3) Seu deslocamento (cinemática de avanço, recuo, feixe ou projétil) e (4) Wind-up (tempo em segundos e risco de interrupção). A visão expandida (Modal Z) organiza essas informações em um dossiê técnico estruturado em seções dedicadas (Mechanics, Visuals, Motion, Wind-up e Tactical Synergy), sem vincular o move a espécies específicas (D-235).
- **[CONVERSA 2026-11-06] [D-347]** O HP e a barra atualizam **imediatamente** ao receber dano ou cura. O odômetro rolante (D-048) saiu do fluxo ativo e foi guardado em `scripts/legacy/rolling_hp_odometer.gd`, com teste em `tests/legacy/`; o toggle saiu do menu.

- **Painel de Combat Gauges, Atributos e Nature Integrada [D-421]:**
  - **Eliminação do bloco separado de Nature:** A Nature deixa de ocupar uma caixa externa dedicada de 82px na base da HUD, sendo integrada ao rodapé do cartão de `ATTRIBUTES` (altura unificada de 142px com `COMBAT GAUGES`).
  - **Rótulo Limpo:** O cabeçalho passa a ser estritamente `ATTRIBUTES`, eliminando os complementos `// 6`, `CANONICAL` e subtítulos redundantes.
  - **Geometria Angular Contínua:** Blocos de Gauges (Paper Cream) e Attributes (Deep Navy) compartilham a mesma inclinação de paralelogramo à direita (`/ /`). Barras de HP/MP, trilhos e blocos de ATB são paralelogramos planos inclinados.
  - **Modificadores Integrados:** Bônus/penalidades de Nature (`+2`, `-1`) estampados diretamente ao lado do valor do atributo em verde limão ou coral.
  - **Rodapé Compacto Dividido (Opção 1C):** Na base interna de Attributes, a esquerda exibe a faixa de Nature com aba vertical dourada (`NAT BRAVE`), enquanto a direita abriga a doca de fraquezas (`WEAK`) com glifos SVG em paralelogramos planos, com zero bordas de 1px.

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
- **Status Screen — Tag ALLY, Tipografia da Nature e Tooltip/Doutrina Tática [D-422]:**
  - **Elevação da Tag ALLY/PROTAGONIST:** Tag reposicionada para `tag_y = 62.0` eliminando qualquer colisão com a fonte do nome do monstro (`PANCHAM` / `ABRA`), garantindo margem limpa de respiro negativo.
  - **Tipografia da Nature:** Remoção do prefixo `NAT`; nome da Nature exibido isolado em tipografia Teko 20px com a aba dourada.
  - **Tooltip e Parágrafo de Combate na Região Aberta:** Ao passar o mouse por cima ou clicar na Nature, abre-se um tooltip identificador e, na área aberta entre os atributos e a hotbar de skills (acima da linha em `y = 520.0`), projeta-se um painel textual detalhado com a doutrina de combate e perfil tático da IA para aquela Nature.

- **[CÓDIGO]** Hoje: AoE corre até o "alvo principal"; só ele pode desviar; um desvio manual dele cancela o AoE inteiro; os demais levam 85%. O bug de fogo amigo (equipe errada) foi corrigido; AoE com alvo morto mira o próximo. **Essas regras de código divergem de 1–5.**
- **Movimentos AoE/status existentes [CÓDIGO]:** Media (cura 40% do HP máx, mín. 12, equipe), Tarukaja (+1 estágio de ataque na equipe), Rakunda (−1 defesa), Sukunda (−1 velocidade), Mabufula, Megido (projéteis em área), Hassou Tobi, Titanomachia (físicos em área).

---

## 10. Itens, IA e Tactics

- **[CÓDIGO]** Itens: **Poção** (consumível, +30 HP), **Amuleto** e **Talismã** (segurar; sem efeito ainda). Inventário inicial do grupo: 3 Poções, 1 Amuleto, 1 Talismã. O líder usa o inventário compartilhado; o inimigo tem 1 Poção. IA bebe Poção quando HP ≤ **50%** e tem 1 ATB.
- **[GDD R28-Q2]** Alguns itens segurados têm efeito passivo, outros são consumidos automaticamente (como berries). **[PENDENTE]** efeitos.
- **[GDD R34-Q5, R35-Q3]** Cada integrante da equipe ativa carrega **até 10 itens não segurados** (até 30 com três); ninguém concentra 30. Inventário cheio: escolher um item para deixar/trocar antes de recolher outro. Itens segurados fora da contagem.
- **[D-424, D-425, D-426, D-427, D-428, D-429, D-430, D-431, D-432, D-434, D-435, D-436, D-437, D-438, D-439, D-440]** UI do Inventário, Status Screen e Combate: design de "Mochila de Expedição" rústica em paralelogramo `/ /` (D-416) com paleta de couro marrom (`#3c2415`), sombras profundas (`#24140a`) e amarelo ocre queimado (`#dfc980`) de alto contraste (7.8:1). Exibe a matriz de 10 slots (2×5) por integrante. Ao selecionar um item, os detalhes abrem em gaveta retrátil inferior (Opção A) e todos os outros 9 slots sofrem obscurecência (dimming de 28% de opacidade, Opção C) para foco total no item selecionado. Badges de consumível adotam a cor oficial Verde Herbal / Botânico (`#2e7d4e`) em escala ampliada de 11px, com alinhamento óptico vertical estrito do ícone ao centro da tipografia. Ícones reais de pixel art de cada item exibidos com fidelidade de cores original via TextureRect (D-430). O texto de descrição aplica cisalhamento itálico a 9° (D-429, D-430: Opção A). O botão `USE (1 ATB) [Z]` é renderizado como retângulo ortogonal (90°, skew = 0) perfeitamente alinhado e confinado (D-430). Tag amarela `EXPEDITION SATCHEL` contida com margem de segurança contra a borda inclinada e textos do rodapé descolados sem colisão tipográfica (D-431). No painel de atributos, hover da Nature alinhado pixel-perfect sobre MODEST com rebaixamento vertical para y=sy+132px, bloco de hover compacto dinâmico, rótulo "WEAK:" restaurado antes dos badges de fraqueza, texto inferior redundante de Nature removido (D-431, D-432). O painel tático de Nature separa "AI DOCTRINE:" e os valores dinamicamente sem sobreposição, e adota descrições objetivas focadas em comportamento de IA sem menção a atributos numéricos (D-432). A hotbar de habilidades adota o padrão Battle Strips em grade de 2x4 fitas horizontais com números de atalho embutidos no canto superior esquerdo sobre os ícones elementais, pips de ATB em paralelogramas reais / /, custo de MP compacto ("8MP"), omissão de custo zero (sem "0MP" / sem "FREE") e nomes 100% desimpedidos (D-434, D-435). No combate, o bloco central do SkillInfoPanel (480×374px) é eliminado para total desobstrução da arena 3D e do inimigo, migrando para card esguio lateral junto à seleção de golpes, com descrições reformuladas em 3 eixos objetivos (ação mecânica, propriedades táticas reais e escalamento MAG/STR com wind-up) sem redundâncias (D-436). No SkillInfoPanel, remoção do rótulo redundante "TACTICAL ANALYSIS" e da caixa de alerta "incoming move from X", exibição do elemento exclusivamente como marca d'água SVG translúcida atrás do título, inclusão de ícones de Tipo e Alcance ao lado do nome do move, e descrições ricas em combate (D-437). Harmonização do cinza neutro (#cbd5e1); custos de MP obrigatórios no Fight Drawer e SkillInfoPanel; opções sem MP apagam e são bloqueadas; redução de 30% em todos os custos de MP; cores por elemento e 3 ícones no Fight Drawer; SkillInfoPanel com 75% de opacidade; remoção de textos redundantes nos moves; Wind-up e 3 ícones no topo (D-438). Wind-up posicionado na linha de custos ao lado de MP; chips de MP e Wind-up em cor sólida flat sem borda; altura do painel reduzida de 246px para 196px mantendo todos os dados e ampliando a visão da arena (D-439). Glifo oficial do elemento Neutral atualizado para Diamond Core (losango chanfrado com núcleo central); AttackTag mantém apenas 2 ícones (tipo e alcance) e aplica regra de descoberta (fundo neutro escuro + bloco [?] quando o inimigo for desconhecido, sem spoiler visual de cor) (D-440). Integrado em `scripts/ui/status_screen.gd`, `scripts/ui/battle_hud.gd`, `scripts/ui/fan_menu.gd`, `scripts/ui/skill_info_panel.gd` e `scripts/data/skill.gd`.
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

- **[D-278, D-313]** O overworld mantém a estrutura e a colisão originais e continua 2D; a paleta usa a arena 3D como referência. A D-313 relaja a restrição “somente paleta”: os tiles podem ser refeitos/melhorados para encaixar melhor entre si, e ficam autorizados poeira/partículas, tochas cintilando, NPC olhando para o jogador e sprites de Pokémon. Sombra sob as entidades **não** foi autorizada. **Substituída no overworld pela D-1022 (direção 3D; escopo pendente).**
- **[GDD R7-Q5, R8-Q3/Q4]** Mapas **gerados proceduralmente por exploração/andar**, com salas e corredores; **seed reutilizável** reproduz o mesmo layout (mesma seed + regras + versão do gerador); formas, posições e conexões algorítmicas.
- **[GDD R9-Q2, R36-Q3]** Ao **revisitar um andar** na mesma exploração, o layout **não muda**; itens já coletados e eventos concluídos **mantêm o estado**; inimigos derrotados **continuam removidos** (R9-Q4). Sem respawn ao subir/descer escadas.
- **[GDD R9-Q5, R23-Q1]** Movimento **contínuo e livre nas 4 direções cardeais**, sem diagonal direta.
- **[GDD R32-Q4]** O mapa do andar é **revelado progressivamente**. **[CÓDIGO]** névoa de guerra com raio de visão 7,5 tiles; o explorado fica na memória e sobrevive às batalhas.
- **[CÓDIGO]** Geração: 7–11 salas (4×4 a 9×7), 4–6 inimigos, 2–3 NPCs; tile de 48 px; o layout fica em cache no `GameState`.
- **[D-314]** Aliados ativos seguem em **fila**, no **rastro exato** do protagonista, sem atravessar paredes/obstáculos; se travar, espera ou vai ao ponto livre mais próximo.
- **[D-361] Seguidor mais perto:** o gap do rastro passa de **48 px** para **32 px** (2/3 de tile); rastro exato, velocidade, espera e reposicionamento de D-314 não mudam; se ainda parecer longe, o próximo valor é 24 px.
- **[D-381] Clima de exploração (só visual):** os eventos temporais não alteram movimento, combate, colisão, câmera, geração, raio de visão 7,5, LOS nem o explorado; entram neblina maior (véu mais denso, sem aumentar o raio), calor ondulado, chuva/neve com respingo e distorção temporal em Temporal/Spire; frequência **rara** (cadência exata pendente). Clima fora do Motion Composer (D-383); nada implementado.
- **[D-382] Cadência do clima:** 20% de chance por andar (1 em 5), no máximo um evento por andar, 20–40 s com fade; o mapeamento de biomas de D-362 fica mantido; clima fora do Motion Composer (D-383); continua só visual.
- **[D-383] Clima fora do Motion Composer:** névoa, calor, chuva/neve e distorção temporal são camadas 2D de ambiente e não usam o Composer nem o protocolo de 4 fases; D-308 fica restrito a VFX de Move/elemento em combate; o Composer não é gate para clima.
- **[D-1021] Water / Tidal Surge (biblioteca de projéteis):** próximo elemento da biblioteca; **jato de água contínuo** ligado ao lançador, baseado na W da Nami; **explosão radial** no impacto; paleta **azul/ciano/branco**, sem dourado; seis fases (Start, Wind-up, Release, Trajectory, Impact, Post-impact) aprovadas. Só visual: não altera tempo, dano, acerto, ATB nem qualquer regra de combate (D-019). **Fase Start implementada; demais fases pendentes.**
- **[D-1025] Tidal Surge é do Slime; mecânicas primeiro:** o Slime é o dono do Move; a fase Start fica **em espera, não aprovada**; a ficha foi aprovada (2 ATB + 5 MP, 0,8 s, 100/75/50, saltos de 0,3/0,6 s, até 2, evasível, sem ATB/Burst extra) e a **mecânica foi implementada e testada**. D-235 continua: o Move é por `move_id` e genérico, salvo decisão expressa de exclusividade. Os saltos ainda não são desenhados no VFX.
- **[D-384] Neblina implementada:** camada 2D de tela cheia, rolagem de 20% por andar (1 em 5), 20–40 s, fade de 2 s; não altera raio/LOS/explorado/regras; calor/chuva/neve/distorção pendentes; captura antes/depois e vídeo do ciclo em `docs/referencias/exploracao/weather_mist_before_after.png`.
- **[D-385] Neblina mais densa:** `max_alpha` 0,40, `density` 0,85, `noise_scale` 1,7 e `edge_mist` 0,75; bancos maiores, cantos expandidos e bordas fechadas para piorar a leitura visual; raio 7,5/LOS/explorado intactos; vídeos regravados.
- **[D-386] Chuva implementada:** gotas 2D em espaço de mundo e respingos nas células de chão perto do jogador; 20% por andar, 20–40 s, fade 2 s; só visual; CPUParticles2D (GL Compatibility); calor/neve/cinza/distorção ainda pendentes.
- **[D-387] Calor ondulado implementado:** overlay 2D de tela cheia com senoides, RGB shift leve e tom âmbar, mais forte perto do chão; poeira de calor esparsa; 20% por andar, 20–40 s; só visual; fora do Motion Composer (D-383).
- **[D-388] Seguidor na mesma velocidade:** `SPEED` do seguidor 200 → **180 px/s**, igual ao jogador; o spawn usa o gap de 32 px (D-361); rastro exato, espera e reposição de D-314 não mudam; o ganho de velocidade para alcançar o alvo deixa de existir.
- **[D-389] DQT Orc 3D no overworld:** o Orc é um terceiro seguidor **visual** atrás do Pancham, com rastro/gap 32/velocidade 180; renderizado em SubViewport 3D ortográfico e exibido num Sprite2D; idle/walk do DQT; só no overworld, sem batalha/party/colisão e fora de `followers`; sem o GLB local ele não aparece.
- **[D-991] Modelos 3D dos Pokémon no overworld (lab):** laboratório separado troca os sprites de Abra e Pancham (e o Orc) pelos GLBs, normalizados em altura (Abra 25, Pancham 24, Orc 30 px de mundo) para igualar os sprites; render 3D→2D igual a D-389; três opções de shader (pixel, toon, pixel+toon) e uma referência sem shader; o jogo normal continua com sprites 2D e **sem** shader até o criador escolher.
- **[D-1016] Abra, Pancham e Orc em 3D no jogo normal (estilo pixel):** os sprites dos três são substituídos pelos GLBs; shader pixel (64×64 nearest, 6 níveis, saturação 1,15, contraste 1,08, silhueta escura); tamanhos 25/24/30 px mantidos (overhaul dos tiles adiado); a elipse escura já desenhada some sob quem tem modelo (a divergência D-313/D-324 continua nos demais); sem o GLB local o sprite 2D volta; o Orc continua visual (D-389); batalha/party/colisão/IA e clima intactos.
- **[D-1018] Lab de escala dos modelos 3D:** variantes A (1,0×), B (1,5×), C (2,0× gap 48), D (2,0× gap 48 zoom 2,8×) e C32 (2,0× gap 32) gravadas; o jogo normal continua 25/24/30, gap 32 e zoom 2,3× (D-1016/D-361/D-344); escolha pendente.
- **[D-1022] Fim do overworld 2D:** o overworld deixa de ser 2D e passa a ser 3D; substitui D-275/D-278/D-313 no overworld; câmera, geração de mapa, assets, seguidores, névoa e encontros ainda não definidos; o jogo 2D atual continua como referência até a fatia 3D; nada implementado.
- **[D-1023] Lab 3D em terceira pessoa (SMT III):** só laboratório; corredor em L com câmera atrás, colisão, Slime e porta; vídeos solo e do grupo (11,0 s, 330 quadros); formação em triângulo, Pancham 0,7 m; Onda 1 com navmesh/NavigationAgent3D, IA do Slime (patrulha/persegue/volta), poeira de passo, porta interativa e vinheta; auditoria solo/party sem corpo ou câmera em parede; sem lock de mouse e janela de teste sem foco; o jogo normal 2D continua como referência; câmera, escala e geração de mapa finais ainda não definidas.
- **[D-1027] Mini-mapa 2D:** o 2D não é mais o overworld jogável; **teste implementado** no lab Murky Forest com mini-mapa top-down 256×256, marcadores verdes (jogador/aliados menores), vermelho (inimigos) e branco (NPCs via grupo `minimap_npc`); ícone provisório; névoa/rotação/tamanho finais pendentes.
- **[D-1028] Visual 3D toon inspirado nas tiles do PMD:** **teste implementado** no lab Murky Forest: cenário low-poly reconstruído do visual das tiles, toon em todo o overworld 3D (personagens + cenário), batalha fora; escala 1 m/célula 3 m/corredor 6 m/parede 4,2 m; auditoria solo/party sem corpo ou câmera em parede e com toon ativo; fidelidade fina, performance e licença pendentes.
- **[D-1037] HUD de exploração:** **teste implementado**: mini-mapa 112×112 sem texto e badges de vida no extremo canto esquerdo (ABRA 86/100, PANCHAM 100/100, ORC 46/100; HP demo), 3 badges no party e 1 no solo; fonte real do HP, personagens e estilo finais pendentes; ideias de HUD listadas; combate/2D intactos.

### 14.2 Inimigos no mapa
- **[GDD R8-Q5, R9-Q3]** Inimigos **visíveis** no mapa; **patrulham** e **perseguem** após detectar; **o contato inicia o combate 3D** (não a mera detecção).
- **[CÓDIGO]** Patrulha 42 px/s, perseguição 105 px/s; detecção por visão a 6,5 tiles (precisa de linha de visão), audição a 3 tiles, perde o rastro a 9 tiles; contato a 26 px; desiste após 4 s; raio de patrulha 4 tiles; **graça pós-batalha de 1,25 s**. Jogador 180 px/s.
- **[GDD R9-Q4]** Inimigo derrotado é removido do andar nesta exploração.
- **[D-310, D-315, D-321]** Substitui a detecção por visão atual: quatro níveis de ameaça (0 Medroso, 1 Fraco, 2 Valente, 3 Perigoso). A **soma dos níveis do grupo inimigo** (máx. 3 membros) é comparada com a **soma dos níveis dos membros vivos da equipe**; cada membro usa o próprio nível para ícone e tamanho. Inimigos podem andar **em grupo solto** (cada um calcula o próprio caminho, mas ficam próximos) ou sozinhos; a composição é aleatória; se o líder cai, o próximo vira líder. O nível de cada inimigo é **média da equipe + 1 a +4**. Distâncias: Fraco 3, Valente 6, Perigoso 9 tiles. Velocidades: Medroso 40, Fraco 70, Valente 110, Perigoso 150 px/s. Medroso foge a **3 tiles** e patrulha a **42 px/s**; tocado, inicia batalha normal. Faixas confirmadas: diferença percentual `(soma_inimiga - soma_equipe) / soma_equipe` com cortes **−0,40 / −0,10 / +0,30**. Tamanhos/ícones serão escolhidos após desenhos.

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
- **[D-316]** A expedição tem **5 andares**; a escada do último andar inicia uma **nova expedição completa** (andar 1, nova seed, MP cheio, Natures novas; mantém equipe, itens e HP). O ponto de descanso ativa **ao pisar**, cura a **equipe ativa**, é de uso único e cada andar tem **2 pontos**, com **10% de chance** de um terceiro.
- **[D-317]** O bioma é **sorteado por dungeon**; os 4 primeiros andares usam um bioma e o **5º andar usa outro bioma sorteado**, com o qual a nova dungeon continua. Não é necessário definir espécies por bioma agora e **não serão importados novos modelos**; usar os sprites overworld existentes.
- **[D-318]** A F6 começa por **eventos**; a ordem dos demais conteúdos está pendente.
- **[D-319]** A F3 mexe **só no overworld**; a batalha 3D continua com o Gible fixo.

### 14.4 Recrutamento
- **[GDD R23-Q4, R24-Q2, R35-Q2]** Exige **interação voluntária explícita** (nunca automático por aproximação). Pokémon **especiais** exigem uma tarefa/evento antes (R32-Q5). Hostis normais seguem iniciando combate. Candidatos especiais são identificados no mapa (R26-Q2).

### 14.5 Progressão, XP e economia
- **[GDD R26-Q3, R31-Q3]** Todos os **ativos que participaram** de uma batalha vencida recebem XP, mesmo sem dar o golpe final; reservas **não** recebem XP das vitórias, mas podem progredir por treinamento/serviços fora das expedições (R33-Q2).
- **[GDD R11-Q4, R12-Q5, R13-Q4/Q5, R14-Q4]** Subir de nível: o **protagonista** recebe **1 ponto por nível** e **é obrigado a distribuí-lo** na hora; **aliados** crescem automaticamente por curvas da espécie, influenciadas por **Tactic e ações executadas**, e por Natures. Evolução de espécie: o jogador escolhe **quando** (R25-Q3).
- **[GDD R27-Q4]** O nível/progressão é a fonte principal de novos Moves; mestres, HMs/TMs (**só para combate por enquanto**, R24-Q4) e outras fontes também (R23-Q5).
- **[GDD R27-Q5, R28-Q1, R29-Q1]** Recompensas de batalha: **moedas, recursos, itens**; moedas compram itens/recursos de NPCs e lojas, que existem dentro das dungeons e fora delas. **[R33-Q5 REJEITADA]** recursos materiais genéricos/crafting **não estão definidos**.
- **[D-323]** **simisear, simipour, throh, amoonguss, stunfisk e aromatisse** saem da lista usável do manifesto por não terem sprite overworld; continuam no histórico e nenhum asset é apagado. Contagem usável: **297**.

### 14.6 MP, HP e descanso
- **[GDD R11-Q3, R12-Q1/Q2/Q3, R13-Q1/Q2/Q3, R14-Q1/Q2/Q3, R15–R17]** Existe **MP** separado: Moves mágicos/especiais gastam MP **além** de ATB/Burst; custo-base comum com exceções; MP máx = Magia + nível; MP e HP **persistem entre combates da mesma dungeon**; MP é restaurado ao máximo no **início de cada exploração** e nos **pontos de descanso** (que também recuperam HP, quantidade pendente — R32-Q2); MP descontado na ativação (R14-Q1).
- **Recuperação por ATB cheio [GDD R14-Q2, R15, R16, R17-Q5]:** com ATB normal 5/5, **25% do MP máximo a cada 3 s consecutivos**, arredondado para baixo; o contador zera ao sair de 5/5 e fica zerado com MP cheio; **pausa durante o menu Tactic**.
- **[CÓDIGO]** Hoje o jogo mostra `MP N/D`: MP **não** existe ainda.

### 14.7 Natures
- **[GDD R14-Q5, R15-Q4/Q5, R16-Q4, R17-Q4, R18-Q4/Q5, R19-Q4/Q5, R20-Q4/Q5, R21-Q4/Q5, R22-Q4/Q5]** Natures modificam atributos-base (bônus e penalidades flexíveis; podem ser neutras), influenciam crescimento e tendências táticas. Sorteadas na geração de recrutáveis aleatórios, do protagonista (**de novo no início de cada exploração**, preservando os pontos distribuídos e a proporção de HP/MP, arredondando para baixo, mínimo de HP positivo) e de Pokémon de evento. Atributos finais ficam em **1–100**. A Tactic escolhida **prevalece** sobre Natures no comportamento da IA.

### 14.8 Hub (D-324)
- **[D-324] Direção aceita:** o hub é um lugar 2D jogável (não um menu), numa tela fixa sem interiores, com fachadas, praça e serviços em bancas/NPCs; começa como base compacta e cresce para vila por plots/NPCs. O modelo é o de **extração**: o hub é a base da campanha; a escada continua a expedição; extrair volta ao hub; o chefe abre a próxima dungeon. O visual usa a linguagem 2D do overworld, sprites existentes, sem modelos novos e sem sombra elíptica (D-313); o portão enquadra o bioma atual. **Pendente:** se o hub substitui a seleção de campanha ou é opcional; o conjunto de serviços da V1; economia/preços; armazém; estalagem/cura; save; protagonista; fila de aliados no hub; recrutas físicos; iluminação; planta/câmera; nome. Nada implementado.

### 14.9 Assets 2D externos (D-325)
- **[D-325] Autorizado:** usar assets 2D não-Pokémon das páginas de **Explorers of Time/Darkness** e **Explorers of Sky** do The Spriters Resource: **dungeons**, **backgrounds**, **sprites de itens** e **outros** (UI, murais, fundos de menu, céus, estátuas, props, fontes, mapa). **Pokémon do site ficam de fora por ora**; os sprites/retratos existentes no projeto continuam. A D-313 é relaxada só para esses assets não-Pokémon; a proibição de sombra elíptica continua. A batalha 3D e a D-319 não mudam; VFX novo segue D-308. **Pendente:** importação direta vs. referência; lista exata de "outras coisas"; créditos/proveniência; pastas. Nada importado.
- **[D-326] Ordem e escala:** usar **Time/Darkness primeiro**, **Sky depois**; dungeons com **tilesets modulares** sobre a geração procedural, sem trocar por mapas completos; adotar **24 px por tile por ora**. Conversão proposta para preservar o comportamento em tiles: TILE 48→24, velocidade do jogador 180→90 px/s, zoom 1.5→3.0, colisões pela metade, névoa e dimensões do andar em tiles inalteradas. **Pendente:** escala visual dos sprites; primeira leva de assets; tilesets por bioma. Nada implementado.
- **[D-328] 24 px no jogo inteiro + cena de teste:** o 24 px valia para a exploração 2D, a dungeon, o hub e os sistemas de mapa; o combate 3D não mudava. A cena isolada `scenes/hub_test.tscn` abre por **F10** e volta por **ESC**; usa a Treasure Town limpa, colisão básica e NPCs de teste, sem serviços. **Revertida por D-329:** o jogo voltou a 48 px; a cena do hub permanece, em 48 px.
- **[D-329] Voltar para 48 px:** a conversão para 24 px foi cancelada porque a perda de qualidade foi imensa. `TILE` 24→48; jogador 90→180 px/s, colisão 7→14, câmera 3.0→1.5; NPC 14×14→28×28 e interação 18→36; inimigos 21/52,5→42/105 e contato 13→26; pickup 12→24; seguidores 100→200 e gap 24→48; `map_visuals` sem downscale; tochas/brasas/poeira/sombras de volta a 48 px. Os tilesets do PMD (~24 px) precisarão de escala 2× ou tratamento próprio.
- **[D-330] Dungeon Tiles:** os 16 tilesets do Sky foram importados para `assets/pmd/dungeons/sky/raw/` e os atlas para `assets/pmd/dungeons/sky/atlas/`; o sheet do Time/Darkness está em `assets/pmd/dungeons/time_darkness/raw/` e `docs/referencias/` como referência. **Estado atual:** o atlas ativo é o **Sky Temporal Tower de 30 tiles** (18 do núcleo + 2 Ground Alt + 8 peças reais de parede), alinhado à grade real da folha: **pitch de 25 px** (1 px de linha ciano + 24×24 de arte), origem `(9, 163)`, recorte 24×24 e escala nearest para 48. A geração procedural (GDD R7-Q5) continua; troca somente visual; nenhum VFX novo.
- **[D-344] Câmera do dungeon em 2,3×:** a câmera da exploração 2D passa de **1,5×** para **2,0×** e depois para **2,3×** (`scripts/dungeon/player.gd`), para ficar mais perto dos personagens. Velocidade, suavização, limites e colisão não mudam; o teste do hub já estava em 2,0×; a câmera 3D de batalha não é afetada.
- **[D-345] Pipeline de tilesets:** medir a grade real de cada folha (linhas ciano, pitch, origem, célula), gerar manifesto e perfil papel → índice, recortar a célula inteira, validar o atlas (dimensões, vazio, ciano/teal, costura, hash), gerar folha de contato e testar no laboratório do Godot antes de usar. O visual aprovado (Walls + Ground, 1 linha, 2,3×) não muda.
- **[D-346] Terrain nativo e bioma por andar (Bloco 1):** o seletor usa os 16 perfis, mantém Temporal Tower nos andares 1–4, troca no 5º andar (`floor / 5`), não repete o passo anterior e tem fallback `temporal_tower`; o contador visual avança em `new_dungeon`; na derrota a expedição é encerrada e recomeça no andar 1 com nova seed/bioma (R23-Q3/R33-Q1, D-316/D-317). O terrain nativo de 8 bits foi implementado no laboratório, mas **não entrou no jogo**: a folha tem 9 peças reais de borda, não um blob 47; as extras são formas prontas. A auditoria do lab dá 27 side / 49 corner (Temporal) e 26 / 53 (demais), e o resultado ficou pior que o renderer aprovado. O `map_visuals.gd` do jogo mantém a máscara manual de 4 vizinhos (D-330). Para 0/0 é preciso decodificar as extras (Bloco 2). Câmera 2,3×, 48 px, combate e colisão não mudam.
- **[D-347] Piso orgânico (Bloco 2):** `Ground Alt. 1` (C16 R1) e `Ground Alt. 2` (C19 R1) entram no atlas/perfil onde existirem. Só células de chão **interiores** (sem parede nos 4 lados) recebem variantes; bordas/cantos mantêm a máscara de 4 vizinhos. Distribuição determinística pelo `dungeon_seed`: 92% `ground_c`, 4% alt 1, 4% alt 2; as alts são decals de chão (flores/árvores/pedras), não piso seamless.
- **[D-348 / D-354 / D-355 / D-356] Parede de 1 tile:** fora do mapa conta como **aberto** (`_is_solid`); **30 tiles reais** no atlas: 18 núcleo + 2 Ground Alt + `wall_strip_v` C3R4, `wall_strip_h` C4R3, `wall_island` C4R4, `wall_tip_n/s/w/e`, `wall_cross` e os centros `wall_alt_1/2` (C7R1/C10R1). A escolha é pela **assinatura de lados abertos medida** no tile (`role_sides`); nos 12 perfis sem contrato, o fallback usa as **peças reais por papel** (strip, island, tips, cross, alt), nunca uma strip em todo lado. 1 lado → peça do núcleo; 2 opostos → strip; 2 adjacentes → canto; 3 → tip; 4 → island; interseção → cross. Os centros Wall Alt. só variam 10% das células **totalmente interiores** (D-355). O bloco 3×3 é uma **massa de parede** (linha 1 topo, linha 2 face); o preview da folha confirma `topo → face → chão`. O laboratório tem sala embutida, **porta de corredor**, máscaras 8-vizinhos e overlay; os decals de piso são 4%+4% exatos, sem adjacentes (D-356). Câmera 2,3×, 48 px, combate, movimento e colisão não mudam. O laboratório mostra o renderer manual com esse piso e alterna os 16 perfis; o terrain nativo do Bloco 1 sai do atlas ativo. Câmera 2,3×, 48 px, combate e colisão não mudam.
- **[D-358] Névoa e overlay por bioma:** as 16 folhas têm cor de ambiente (CanvasModulate) e preset de névoa (cor/densidade/warp/drift) em `scripts/dungeon/biome_visuals.gd`; o `fog_of_war` lê `GameState.visual_biome` e o `apply_biome` troca o shader; as tochas/luzes amarelas e a luz do jogador foram removidas; só a luz vermelha dos inimigos permanece. Raio de 7,5, LOS, explorado permanente e ordem de desenho não mudam.
- **[D-359] Paletas fortes por bioma:** 16 `AMBIENT`/`FOG` saturados e distintos em `biome_visuals.gd` (verde, ciano, areia, azul, índigo, rosa, laranja, amarelo, violeta, cinza…); a luz do jogador foi removida e Temporal/Spire tiveram o ambiente compensado; as 16 capturas in-game foram regeradas.
- **[D-360] Névoa de duas cores laterais e ruído por bioma:** `BiomeVisuals.FOG` tem `color`/`color_b` + `side_mix` e `noise_type`/frequência/octaves/seed/escalas; o shader mistura as cores laterais e o `fog_of_war` recria o `NoiseTexture2D` por bioma; a máscara/LOS/raio 7,5 e o explorado permanente não mudam. O laboratório só tem ambiente; a névoa é da cena do jogo.

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
- **D-320:** o criador autorizou commit + push **somente de documentação** nesta rodada; a `main` local está divergente de `origin/main` (ahead 11 / behind 56), então o push exige decisão sobre merge/rebase antes de acontecer.

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

## 42. Decisão D-157 — Retorno do Hit Shake e Correção do Lançamento de K.O.

- **Hit Shake nos Ataques (D-157):** Ataques que atingem o alvo disparam tremor direcional de câmera calibrado em escala menor que o K.O. final:
  - Golpes comuns: trauma ~0.35, decaimento rápido (~0.12s), micro tremor seco e responsivo.
  - Golpes pesados (Fraqueza, Crítico ou Poder >= 1.4): trauma ~0.55, micro FOV-kick de ~1.5°, decaimento ágil (~0.18s).
  - K.O. final: preserva trauma 1.0, FOV-kick 4.5° e tremor épico estendido.
- **Lançamento de K.O. Longe (D-157):**
  - Distância ampliada para 28–36 metros (substituindo o antigo curso curto de 9m).
  - Arco balístico com altura máxima de 7.0–9.5 metros com impulso explosivo inicial (curva ease-out).
  - Rotação do modelo vinculada estritamente ao progresso de voo (`prog`), executando capotamento limpo de ~1.25 a 1.5 voltas ao longo do trajeto (eliminando o giro contínuo no mesmo ponto).
  - Deslocamento direcionado para longe do atacante com leve abertura lateral.

---

## 43. Decisão D-158 — Efeitos Visuais Físicos de Buffs e Debuffs: Tamanho, Velocidade de Animação e Armadura

- **Tamanho por ATK (+atk / -atk):** O modelo do personagem escala em $\pm 0.15$ por stack (+15% em +1, +30% em +2; -15% em -1, -30% em -2; 1.0 em 0). A transição utiliza tween suave (~0.35s) com leve amortecimento elástico. `_base_scale` do motor acompanha a nova escala para manter compatibilidade com hit-stops e ataques.
- **Velocidade de Animação por SPD (+spd / -spd):** A velocidade de reprodução (`speed_scale`) das animações (idle e corrida de investida) varia em $\pm 0.15x$ por stack (1.15x em +1, 1.30x em +2; 0.85x em -1, 0.70x em -2; 1.0x em 0). Transição suave via tween.
- **Armadura e Contorno por DEF (+def / -def):**
  - `+def`: contorno anime engrossado em +35% por stack com brilho metálico/cristalino adicionado ao shader.
  - `-def`: contorno anime adelgaçado em -35% por stack com aspecto fragilizado.
- **Limpeza:** Ao expirar ou limpar buffs (`clear_buffs`), escala, velocidade e shader retornam suavemente aos valores nominais padrão.

---

## 44. Decisão D-159 — Limite de Buffs/Debuffs Ampliado para ±5, Acumulação Aditiva Unificada, Cálculo Fracionário e Teto Visual em 3 Stacks

- **Limite de Stacks (±5):** O intervalo de estágios acumuláveis de buffs e debuffs de combate é expandido para o patamar de `-5` até `+5` (substituindo o antigo `-2` a `+2`), aplicado a Ataque (`atk_buff`), Defesa (`def_buff`) e Agilidade/Velocidade (`speed_buff`).
- **Acumulação Aditiva Unificada:** Buffs e debuffs compartilham o mesmo registrador numérico e se anulam diretamente. Um combatente com `ATK -3` que recebe um buff de `ATK +1` passa para `ATK -2`. Tentativas de ultrapassar `+5` ou `-5` mantêm o valor travado no limite e geram mensagem informativa no log.
- **Cálculo de Combate (Fórmula Relativa Fracionária):**
  - Passo percentual padrão de 25% ($0.25$).
  - **Ataque:** Para $s \ge 0$, $\text{mult} = 1.0 + s \times 0.25$; para $s < 0$, $\text{mult} = 1.0 / (1.0 + |s| \times 0.25)$.
  - **Velocidade (ATB):** Para $s \ge 0$, $\text{mult} = 1.0 + s \times 0.25$; para $s < 0$, $\text{mult} = 1.0 / (1.0 + |s| \times 0.25)$.
  - **Defesa:** Para $s \ge 0$, dano recebido é mitigado dividindo por $(1.0 + s \times 0.25)$ (em $+5$, recebe $\sim 44.4\%$ do dano, mitigando $55.6\%$); para $s < 0$, dano recebido é amplificado multiplicando por $(1.0 + |s| \times 0.25)$ (em $-5$, recebe $225\%$ do dano).
- **Teto Visual em 3 Stacks (D-158):** A deformação física do modelo (escala de tamanho, aceleração de animação idle/corrida, largura de contorno anime e reflexos metálicos) é limitada estritamente ao patamar de $\pm 3$ stacks (clamped em `[-3, 3]`), de modo que stacks adicionais (+4 e +5, ou -4 e -5) atuam na matemática de combate sem distorcer o modelo além do limite estético.
- **Feedback Visual (Popups e HUD):** O popup 2D flutuante (`SmtStageVfx`) indica o delta pontual aplicado (ex: `↗ ATK +1`), enquanto as tags e badges no HUD exibem o saldo consolidado acumulado (ex: `ATK -2`).

---

## 45. Decisões D-160 a D-164 — Correções de combate

- **D-160:** o inimigo derrotado é lançado sempre para longe de onde os jogadores estão, qualquer que seja o golpe. Substitui D-079 para inimigos.
- **D-161:** o líder pode escolher um Move durante a pausa de status e durante a própria ação. Há uma vaga; escolher outro substitui. O custo é pago na execução; sem ATB nessa hora, o Move é descartado. O Move começa quando o golpe atual termina tudo, incluindo o pulo de volta; na pausa de status, espera a pausa acabar.
- **D-162:** a câmera lenta de decisão dura 2 s no Fight e 3 s em Itens.
- **D-163:** o clipe de wind-up repete até o fim do preparo; se o preparo for cancelado, o personagem volta ao idle.
- **D-164:** todo Evade manual nos últimos 0,22 s é perfeito e dá contra-ataque sem preparo, inclusive parado. O teleporte continua só no próprio trajeto.
- **D-165:** a velocidade de animação por SPD vale para todos os clipes, não só idle e corrida.
- **D-166:** no K.O., o inimigo encolhe durante o voo e some com faíscas, sem queda ao chão nem explosão de fumaça.
- **D-167:** no limite de ±5, nenhum efeito ou popup de alteração aparece e o log avisa; o bônus do Taunt não passa de +5; o `-def` mostra rachaduras até -3; os sobreviventes voltam ao visual normal ao fim da batalha.
- **D-168:** a IA escolhe primeiro o alvo (aleatório, respeitando engajamento) e depois o Move por nota situacional, com sorteio entre os melhores e penalidade por repetição. Quem reage com Esquivar guarda ATB para o Evade. No próprio trajeto, a IA só desvia na janela perfeita. Pancham começa com Habilidades e Esquivar.
- **D-169:** o tempo-base de corrida de Karate Chop e Dragon Claw é 0,45 s.

---

## 69. Decisões D-269 a D-273 — atributos sem escala 1–100 e conversão dos valores originais

> Renumerado em 2026-11-05 (antes D-192 a D-196, seção 49), por escolha do criador, para não colidir com as Rodadas 68–82 do GitHub (D-192 a D-268, seções 49–68). O Guard (D-272) tem regras completas em `docs/decisoes/D-272-guard-escudo-de-1-atb.md`.

- **D-269:** a escala 1–100 deixa de valer; personagens em níveis baixos não têm valores exorbitantes. O "limite de 10" **não é regra** (correção expressa do criador). Em aberto: o que define um valor baixo para o nível 1 e se vale para HP, MP e inimigos.
- **D-270:** os atributos de cada espécie saem da conversão dos valores originais, criada pelo assistente (não pelo criador). A proposta atual está em `docs/PROPOSTA_ATRIBUTOS_NIVEL_XP.md`.
- **D-271:** os modificadores de Nature são valores flat de −3 a +3 somados aos atributos (formatos variados, ex.: +1/+1/+1/−3), não porcentagens; a Nature afeta só atributos e formas de agir em combate, não o crescimento. Os modificadores somam 0 e uma Nature altera de 2 a 6 atributos. Em aberto: Natures neutras, catálogo e vínculo com a tática.
- **Natures adiadas (2026-11-04):** o criador mandou deixar as Natures para implementar outra hora, por precisarem de mais planejamento (D-271).
- **D-272 (Guard):** ação de 1 ATB (Burst não paga), dura 2 s, sem cancelar; impede outras ações e pausa o ATB de quem a faz; reduz o dano do contato (arredondando para cima) e termina; o recuo do alvo ganha +0,30 s globalmente, menos quem está em Guard; Brick Break quebra o Guard, causa dano normal e dá 1 ATB; Mold Break é habilidade futura.
- **D-273:** a barreira em cúpula hexagonal não foi descartada: fica guardada (`fx_barrier.gd`) para um eventual Move Protect; o Guard usa o escudo (D-272).

## Protótipo HTML de VFX — D-331
Correções e acabamento autorizados no HTML de oito Moves: Quarks.js real, shaders, detalhe moderado, independência dos participantes (D-235) e relógio único (D-019). Os valores demonstrativos não alteram as regras do combate Godot.

## Decisões D-279 a D-281 — choque de corridas, perseguição do visual e espera antes do retorno (2026-11-05)
- **D-279 (choque):** quando duas corridas se cruzam (inclusive alvos diferentes), os dois se chocam e dão um pulinho para trás (mesmo salto do retorno de cada ataque). Se correm um no outro, os golpes saem ao mesmo tempo do ponto do pulinho, aproximando-se lentamente até 2,6 un se ficarem distantes; cada Move usa sua antecipação e seu tempo de acerto e o mais rápido interrompe o outro (regra de interrupção existente). Alvos diferentes: os dois cancelam a corrida e voltam à origem. Em aberto: distância e eixo do choque, velocidade da aproximação, custo do ataque cancelado, 3+ corredores, golpes no mesmo quadro.
- **D-280 (perseguição):** o atacante persegue o ponto onde o modelo do alvo está desenhado (desvio, recuo, pulo de volta); a posição lógica do alvo não muda (D-045, D-019). No STRIKE a trajetória fica fixa e o contato é corrigido só no impacto (restaura D-044/D-054; o código atual contradiz). Causa do arrasto "colado": `AttackMotion._track` no STRIKE.
- **D-281 (retorno):** depois do golpe o atacante espera 0,7 s no alvo (total, no lugar dos 0,2 s) antes do pulo de volta, apenas em Tackle, Brick Break, Dragon Claw, Hassou Tobi e Titanomachia (melee com wind-up de 1,5 s), por `move_id`.
- **D-282 (estado de prisão):** quem está no idle pós-golpe de um Move corpo a corpo não pula de volta enquanto outro ataque corpo a corpo já estiver na fase de golpe contra ele; o pulo fica suspenso (não é um idle maior). Solta no impacto, em desvio, Guard, interrupção ou cancelamento. Evade e Guard manuais são permitidos durante a prisão. Projéteis não entram.
- **D-283 (Evade):** o Evade manual só funciona nos últimos 0,25 s do golpe e é sempre perfeito; antes da janela o botão não tem efeito; não existe Evade "cedo". A IA desvia dentro da janela. Substitui os 0,22 s de D-164/D-075 e deixa sem uso os ramos de desvio não perfeito (D-029, D-066).
- **D-284 (contra-ataque):** o golpe depois de um desvio perfeito tem wind-up de 0,3 s, independente do Move; Moves de status continuam instantâneos.
- **D-285 (IA e Guard):** a IA sorteia o Guard na declaração do ataque, mas só o levanta quando faltam 0,8–1,3 s para o impacto.
- **D-286 (contato):** se o alvo sai do lugar durante o golpe do atacante, ele o alcança deslizando a no máximo 45 u/s (só se o contato se afastou mais de 1 un); suaviza D-054.

### Atelier HTML — D-333 e D-334
Para o HTML dos oito Moves, o criador confirmou a entrega com Quarks.js como exceção aos requisitos de Motion Composer e batalha Godot. Cada efeito tem tamanho fixo em unidades do mundo; origem e contato seguem os modelos reais. Não modifica VFX nem regras do jogo Godot.

## Decisão D-343 — Heal Gain: opção 2, cruzes verdes e lado direito limpo (2026-11-06)
- O número de cura flutuante usa a **opção 2 (Persona Kinetic Cross)** do protótipo HTML: Kanit Black Italic, dígitos `#B7FFC9`, cruz assimétrica `#A8FFC4`, sombra sólida `#08150E` e barra inferior tática.
- O texto exibido **não muda**: a cruz é o sinal de mais e os dígitos são o valor real da cura; sem `+` extra.
- Junto do número sobem **cruzes verdes brilhantes** por **flipbook** (4×4) sobre o **Motion Composer**.
- O **lado direito do HUD fica limpo**: a notificação/log à direita não é exibida.
- O número é HUD ancorado no alvo real; as cruzes são VFX de tamanho fixo e independentes de personagem/time/lado (D-235). O efeito é visual e segue o sinal `healed` (D-019).

## Decisões D-390 a D-394 — Natures, Atributos de 15 Pontos, HP Anti-Hitkill e Progressão (2026-11-07)
- **D-390 (Orçamento de 15 pontos no nível 1):** conversão determinística proporcional aos status originais das espécies (Pokémon e DQT) via Hare-Niemeyer. A soma dos 6 atributos base no nível 1 é rigorosamente 15.
- **D-391 (Renomeação de SPI para WIS e scaling de MP):** o atributo defensivo mágico é oficialmente WIS (*Wisdom*); MP máximo na ficha é calculado como $10 + 2 \times \text{WIS} + \text{Nível}$.
- **D-392 (Curva de HP anti-hitkill e marcos):** $+10$ HP por nível regular, bônus de $+25$ HP nos níveis de marco (1, 10, 20, 30...) e $+2$ HP por ponto de VIT. Calibrado em 39–43 HP no nível 1 para prevenir mortes em 1 golpe.
- **D-393 (Catálogo de 8 Natures iniciais e tática de IA):** Hardy, Docile, Brave, Timid, Modest, Calm, Jolly, Adamant com modificadores *flat* (−3 a +3 somando sempre 0). Não afetam taxas de crescimento por nível. Modulam reserva de ATB e agressividade da IA, sob estrita precedência do menu Tactics.
- **D-394 (Progressão e proficiência):** protagonista líder (`party[0]`) ganha 1 ponto/nível (3 nos marcos de 10) para alocação manual; companheiros aliados acumulam contadores de ações executadas em batalha para orientar a progressão orgânica automática.


## Decisões D-399 a D-402 — Sistema de Experiência (XP), Vitória e Level Up (2026-11-07)
- **D-399 (Curva de XP e recompensa por inimigo):** XP necessário para o nível $ dado por  \times L^2$. Drop de XP do inimigo derrotado calculado como $\text{base\_exp} \times \text{level}$ (com $\text{base\_exp} = 30$ para inimigos iniciais). O total é concedido integralmente a todos os combatentes sobreviventes ativos na equipe (sem penalização por tamanho do grupo).
- **D-400 (Tela de vitória e pausa pós-combate):** ao abater o último oponente, a cena desacelera e pausa a cena 3D; exibe painel de vitória com resumo de XP, barras de progresso animadas, alerta visual de LEVEL UP! e espólios (loot); avanço apenas mediante confirmação explícita do jogador (tecla Confirmar).
- **D-418 (VFX de Celebração de Nível sem Flash):** Proibição total de flashes estroboscópicos de tela inteira (prevenção de fotossensibilidade/epilepsia). A comemoração de level up é sinalizada por um pilar vertical de energia estilo aura boost Dragon Ball com duração de 0,55 s, opacidade intencionalmente baixa (sem obstruir o visual do personagem) e anéis de choque concêntricos que se expandem rapidamente no plano do chão alinhados ao ângulo da câmera.
- **D-401 (Modal obrigatório de alocação de pontos do líder):** se o líder (party[0]) subir de nível, ao avançar a tela de vitória abre-se imediatamente um modal de distribuição de atributos (1 ponto em nível comum, 3 pontos nos marcos a cada 10 níveis, conforme D-394). A saída para a exploração 2D fica bloqueada até que todos os pontos concedidos sejam alocados (D-135).
- **D-402 (Concessão de XP para sobreviventes):** apenas combatentes vivos ao final da luta (hp > 0) recebem experiência; combatentes nocauteados (K.O.) não ganham XP nem avançam de nível naquela batalha, incentivando suporte e cura tática.
- **D-433 (Level Up HUD e Transição de Vitória):** a tela unificada pós-combate SMT III passa a se chamar oficialmente Level Up HUD (LevelUpHUD); ela é ativada após a vitória exclusivamente quando há subida de nível de combatente, substituindo a interface anterior (VictoryPanel e LevelUpModal). A tela de pós-combate comum para vitórias sem subida de nível será recriada em outra rodada.


## Decisão D-405 — Inimigos Aleatórios e Tamanho do Grupo (2026-11-07)
- **D-405 (Encontros Aleatórios e Tamanho de Grupo):** Inimigos aleatórios sorteados entre Slime, Abra, Pancham, Cyclops, Orc e Gible. Composição do grupo inimigo: Solo 55%, Dupla 30% e Trio 15%. Duplicatas de espécies permitidas em duplas e trios. Todos os inimigos gerados com 15 pontos base (Hare-Niemeyer, D-390), Natures (D-393) e HP anti-hitkill (D-392).
## Decisões D-955 a D-957 — Biblioteca de VFX de projéteis (2026-11-07)

- **D-955:** biblioteca de VFX de projéteis genéricos por elemento, no Godot, para referência e reúso. Fontes de referência: skin spotlights de LoL, Persona 5 e SMT V: Vengeance.
- **D-956:** os VFX de projétil têm seis fases: Start (efeito que dispara o wind-up) → Wind-up → Release → Trajectory → Impact → Post-impact (a dissipação do impacto). Contra vários alvos, vários projéteis saem de uma vez. Os efeitos de área sem projétil ainda não entram na biblioteca. A pausa de VFX da D-953 está encerrada. O efeito principal é feito à mão, e o Motion Composer cuida só do secundário (D-954). **Só visual: nenhuma regra de combate muda.**
- **D-957:** o primeiro elemento é Electric, um feixe dourado contínuo como o da Zeri, que se apaga dourado, sem Glow. Vários feixes no combate dependem de uma decisão de combate à parte (conflito com D-007 e D-009).
- **D-969:** o feixe Electric ganha, no impacto, um anel elétrico (`flipbook_lightning`) e uma estrela (`flipbook_impact`), e fagulhas animadas em flipbook no impacto e no wind-up. Só visual.
- **D-970:** o impacto do Electric ganha um pilar de choque em volta do alvo, com descargas laterais sutis, e o trajeto deixa fagulhas e pequenas descargas no ar. O leque horizontal foi cancelado. Só visual.
- **D-971:** o raio Electric ganha uma cabeça clara na ponta durante o trajeto, e o impacto acontece em ordem (clarão, estrela, pilar, anel e fagulhas). Só visual.
- **D-972:** o impacto do Electric é um pilar de estouro animado (coluna sólida que bate, pulsa, se parte em riscos com faíscas laterais e apaga), maior e mais longo (~1,2 s). Só visual.
- **D-973 (corrige D-972):** o pilar do Electric é feito de coroas de raios em zigue-zague, acionadas no contato, que se abrem para fora e para cima em 360°; não há cilindro sólido nem pós-impacto próprio. Só visual.
- **D-974:** o pilar do Electric é proporcional ao tamanho do alvo; o impacto ganha um anel no chão de 0,35 s; na release a esfera incha até o dobro (máx. 1,4 m de raio) e volta em 0,25 s, depois some até 0,6 s. Só visual.
- **D-975:** removido o anel na cor do elemento que surgia no corpo do atacante no fim do wind-up dos moves à distância; o pilar do Electric sai de dentro do inimigo em 0,25 s antes da vida normal. Só visual.
- **D-976:** visual do Electric Beam aprovado (v20). Próximo passo: a mecânica.
- **D-977:** Electric Beam custa 8 MP; num contato com sucesso tem 20% + (LUK do atacante − LUK do alvo) pontos percentuais de causar STUN de 4 s no alvo.
- **D-978:** no contato sem STUN, o pilar do Electric fica 25% menor e 35% mais curto, sumindo em opacidade gradual; quando o STUN acontece, o impacto é o pilar atual completo. O Slime tem o Electric Beam.
- **D-979:** todo STUN mostra um anel de estrelas girando acima da cabeça e o personagem balança tonto (inclinado, joelhos cedendo, quase caindo) até o STUN acabar. Só visual.
- **D-980:** as estrelas do STUN têm tamanhos e giros diferentes e ficaram um pouco maiores (0,65 m). Texto "STUN!", HUD e cenários de debug em definição.
- **D-981:** etiquetas dos inimigos mostram só HP e ATB, são compactas e translúcidas, com retrato e ícones de elemento; os elementos aparecem como "?" (preto no branco) até haver a mesma espécie na equipe ou uma fraqueza descoberta. No STUN também ficam zonzas; o balanço das HUDs ficou mais lento.
- **D-982:** HUD sem o título "CHOOSE YOUR ACTION" e sem "PLAYER"; badges do jogador 15% maiores; regen de MP dos aliados num painel ao lado de CAMERA DIRECTION; etiquetas dos inimigos mais altas e translúcidas; balanço do STUN mais lento.
- **D-983:** sem o losango vermelho embaixo das etiquetas dos inimigos; o alvo selecionado é indicado pelo fundo claro da etiqueta.
- **D-984:** nas etiquetas dos inimigos, debuffs e status negativos ficam na extrema esquerda; buffs e status positivos na extrema direita.
- **D-985:** a etiqueta de wind-up será refeita com fundo na cor do elemento do move, acima dos badges do inimigo, e a janela de Evade será marcada por um efeito visual (a definir). Adiado.
- **D-986:** na janela de Evade, o inimigo que vai golpear mostra um estouro em estrela branco-amarelado dentro de um anel dourado (estilo Metroid Dread). Só visual.
- **D-987 (altera D-283):** a janela de Evade são os **primeiros** 0,25 s da fase de golpe (o prelúdio), não os últimos; a IA segue a mesma janela; o efeito estilo Dread gira por dentro e o anel se separa e expande.
- **D-988 (corrige D-987):** a janela de Evade são os 0,25 s que terminam 0,25 s antes do contato, quando o atacante se ergue; golpes curtos recuam a janela para o início.
- **D-990:** "Swing" e "Hit-windup" (prelúdio do ataque) são a mesma fase; o rastro do golpe corpo a corpo é uma fita 3D que segue a mão/arma real até o contato.
- **D-996:** o Spear Thrust para 1,4 unidade mais longe do alvo que as outras investidas (7,0 em vez de 2,6; D-997), para acertar com a ponta.
- **D-998:** Tackle é o golpe básico genérico; uma variante de Tackle com outro nome tem uma trait própria (ex.: Spear Thrust do Orc, para a 7 unidades). A trait é do move, não do personagem.
- **D-1005:** Boulder Smash (Tackle do Cyclops) tem poder 1,2 Físico e, no contato, 20% + diferença de LUK de -1 DEF no alvo, mostrando o visual do Rakunda.
- **D-1006 (altera D-028/D-283/D-988):** o Evade manual funciona do início do wind-up do inimigo até o contato e sempre é perfeito; o efeito Dread fica só como aviso.
- **D-1008 (altera D-020):** a câmera pode aproximar/dar zoom desde que nada fique fora de quadro; o trabalho começa pelo enquadramento na área livre da HUD.
- **D-1010 (câmera, etapa 1):** só no modo CINEMA a câmera enquadra o retângulo livre da HUD (cartões, menu, painéis e etiquetas de inimigos); inimigos e aliados vivos ficam dentro; pode aproximar a posição e abre o FOV se obstruir.
- **D-1011:** o líder sempre visível; menu e cartão do líder acompanham o líder na horizontal, sempre à esquerda dele; a câmera recua/abre o FOV rápido se ele chega perto.
- **D-1012 (teste):** câmera de ação (IMPACTO) sobe a y=4,5, mira o ponto médio atacante/alvo e usa a área segura com os dois obrigatórios.
- **D-1013 (remove D-339 e D-342):** todos os personagens de batalha têm 1,2 m de altura, iguais como aliado ou inimigo.
- **D-1013:** o trajeto no chão (faixa + bordas) volta do atacante ao alvo e se preenche durante o wind-up; sem bloco quadrado; todos os ataques.
- **D-1014 (corrige D-1006/D-1007):** o jogador pode apertar o dodge a qualquer momento, mas só desvia na janela (físico: prelúdio 0,25 s; projétil/área: últimos 0,25 s); fora da janela gasta e erra; a IA só desvia dentro da janela.
- **D-1015:** o dodge apertado fora da janela toca o clipe "down" no personagem e ele volta ao idle sozinho.
- **D-1019:** o trajeto no chão acompanha atacante e alvo ao vivo, enche pelo relógio do Battle e separa faixas sobrepostas; 3 estilos novos por --lane=N para o criador escolher.
- **D-1024:** o trajeto fica a 70% de opacidade; onde duas corridas opostas em wind-up vão colidir aparece um marcador de choque (anel de pressão + X, não elétrico).

## Decisão D-441 — Drain Spear no jogo (2026-11-08)

- **D-441 (só visual, nenhuma regra de combate muda):** o leque do impacto do Badge Steal continua e aponta do contato para o atacante; 8 luzes azuis saem do ponto de contato em arcos diferentes, voam até o jogador e formam o anel onde ficava a coroa, sem coroa/órbita, e somem por opacidade; o cabo da lança fica 20% mais fino, sem mudar a lâmina nem a ponta. O Move fica no Orc do DQT, no combate real; o laboratório é só depuração.
