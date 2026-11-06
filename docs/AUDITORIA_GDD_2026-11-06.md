# Auditoria do GDD — inventário, pós-combate, transição, Moves, HP/MP, modelos 3D, NPCs e atributos

> **Data:** 2026-11-06
> **Natureza:** relatório de leitura. **Nenhum código, cena, asset, GDD ou decisão foi alterado.**
> **Fontes:** `docs/GDD.md` (revisão 1.59), `docs/REGRAS_DO_JOGO.md`, `docs/decisoes/README.md` e os arquivos `D-*.md` aplicáveis, o código da árvore de trabalho (`scripts/`, `scenes/`) e `docs/pokedex_manifest.json`.
> **Limite:** o Godot e os testes **não foram executados**. Tudo abaixo é leitura de código/documentos; nada foi verificado em tela, em jogo real ou em desempenho.

## Decisões aplicáveis

- **Processo / escopo:** D-001 (o GDD é ignorado no combate; vale para exploração, campanha, progressão e economia), D-002, D-003, D-022, D-061, D-235, D-320.
- **Exploração / overworld:** D-033, D-275, D-276, D-278, D-309, D-310, D-311, D-312, D-313, D-314, D-315, D-316, D-317, D-318, D-319, D-321, D-323, D-324, D-325, D-326, D-329, D-330, D-344, D-345.
- **Atributos / progressão:** D-117 a D-156 (cluster de AGI, LUK, VIT/SPI, crítico, esquiva e status), D-269, D-270, D-271, D-130, D-131.
- **Moves / elementos / fichas:** D-118, D-228 a D-230 (citadas pelo GDD; os arquivos locais não existem nesta árvore), D-235, D-244 a D-249.
- **HUD / combate:** D-048, D-236, D-238, D-239, D-240, D-272, D-273, D-343.
- **Modelos / DQT:** D-336 a D-342.
- **Inventário:** regras do GDD R34-Q5, R35-Q3 e R38-Q4; D-033 para as Poções no mapa.

> Onde este relatório diz “GDD”, está falando do documento de design. Onde diz “decisão D-xxx”, está falando dos arquivos de `docs/decisoes/`. Os IDs internos do GDD (a tabela §9) **não** são os mesmos IDs das decisões.

---

## 1. HUD de inventário

### 1.1 O que o GDD define

- **ITENS em combate:** acessa e usa consumíveis; **cada uso custa 1 bloco ATB**; navegar pelo menu não pausa o combate; catálogo, alvos, efeitos e momento exato da cobrança ficam pendentes (GDD §2).
- **Capacidade:** **10 itens não segurados por Pokémon ativo**, até **30 com três ativos**; itens segurados ficam fora da contagem; com o inventário cheio, o jogador escolhe um item carregado para deixar/trocar antes de recolher o novo; os itens acompanham o Pokémon que vai para a reserva (R34-Q5, R35-Q3, R38-Q4).
- **Itens segurados:** alguns dão efeito passivo; outros são ativados automaticamente e consumidos, como berries; gatilhos e efeitos pendentes (R28-Q2).
- **Interface:** o GDD declara explicitamente “interface” como pendente em R34-Q5, R35-Q3 e R38-Q4. **Não existe uma especificação de HUD de inventário** (barra rápida, contador sempre visível, grade, ícones, ordenação, descarte etc.).

### 1.2 O que o jogo tem hoje

- `scripts/ui/menus.gd`: fora de combate, **X** abre um overlay com três abas — **Itens / Status / Segurar** — e pausa a árvore.
  - **Itens:** lista os consumíveis com `xN`; escolher um abre a lista de personagens com `HP atual/máximo` e item segurado; usa só se `HP < max_hp` e consome 1.
  - **Status:** abre `StatusScreen` (retrato, arte, HP, ATK, VEL, fraquezas, cartões de golpes).
  - **Segurar:** equipa/remove item segurado; o item antigo volta ao inventário.
- `scripts/autoload/game_state.gd`: um **único dicionário compartilhado** `inventory` (`potion: 3`, `amulet: 1`, `charm: 1`), sem limite, sem bolsa por Pokémon. O líder do grupo aponta para esse mesmo dicionário (`abra.inventory = inventory`).
- `scripts/data/item.gd`: só **três** itens definidos — **Poção** (cura 30 HP), **Amuleto** e **Talismã** (segurados, “sem efeito ainda”). Existem centenas de ícones em `assets/items/`, mas não há definição de item para eles.
- `scripts/dungeon/exploration.gd` + `pickup.gd`: 2 a 4 Poções por andar, coleta automática ao encostar, registro em `dungeon_items_collected` para não reaparecer ao voltar de uma batalha; um novo andar limpa a lista (D-033).
- Combate: `scripts/combat/battle_scene.gd` (`_show_items`) lista os consumíveis de `GameState`, com custo de **1 ATB**, alvo na equipe; sem ícones e sem tooltip.
- **Não existe HUD de inventário sempre visível**, barra rápida, contador de itens ou atalho de poção fora do menu X.

### 1.3 Lacunas e divergências

| Ponto | GDD | Jogo | Situação |
|---|---|---|---|
| Limite de 10 por Pokémon / 30 no total | Aprovado (R35-Q3) | Sem limite; dicionário compartilhado | **Não implementado** |
| Inventário cheio: escolher item para trocar | Aprovado (R35-Q3) | Não existe | **Não implementado** |
| Itens acompanham o Pokémon para a reserva | Aprovado (R38-Q4) | Não existe reserva | **Não implementado** |
| Itens segurados com efeito passivo/automático | Aprovado (R28-Q2) | Amuleto e Talismã sem efeito | **Não implementado** |
| Uso de consumível em combate por 1 ATB | Aprovado (GDD §2) | Implementado só para Poção | **Parcial** |
| Interface / HUD | Pendente no GDD | Menu X com três abas | **GDD omisso; jogo tem uma solução** |
| Catálogo de itens | Pendente no GDD | 3 itens; muitos ícones sem definição | **GDD omisso; jogo incompleto** |

### 1.4 O que já está no jogo e não está no GDD (candidatos a documentar)

- O menu X com abas **Itens / Status / Segurar**, a navegação por teclado e a pausa da árvore.
- O fluxo **item → personagem → usar** e o fluxo **item → personagem → segurar/remover**.
- O inventário **compartilhado** e os itens iniciais (3 Poções, 1 Amuleto, 1 Talismã).
- A **coleta automática** de Poção no mapa e a persistência por andar (D-033 já cobre a regra; o GDD não descreve a UX).
- A **Poção cura 30 HP**; Amuleto/Talismã não têm efeito.
- O `StatusScreen` no formato “vitrine” (roster, arte, painel de combate, cartões de golpes, `N/D` para o que não existe).

> **Observação:** vários desses pontos são escolhas de implementação, não regras de design. Se o GDD for atualizado, o mais útil é registrar **o que é regra** (limite, uso, item segurado, inventário cheio) e deixar o layout detalhado para um documento de UI.

### 1.5 Decisões necessárias

1. “HUD de inventário” significa **HUD sempre visível** (contador/atalho) ou o **menu de pausa** que já existe?
2. O inventário continua **compartilhado** ou passa a ser **por Pokémon** (R35-Q3)?
3. O limite de **10/30** entra agora ou fica para quando houver mais itens?
4. Quais itens segurados têm efeito e como o jogador vê isso?
5. O uso de item fora de combate é livre ou limitado (ex.: só em descanso/hub)?

---

## 2. Fim do combate com XP, level up e alocação de atributos

### 2.1 O que o GDD define

- **XP:** todos os Pokémon ativos que participaram de uma batalha vencida recebem experiência, independentemente do golpe final; quantidades, divisão, reserva e incapacitados ficam pendentes (R26-Q3).
- **Reserva:** não recebe XP das vitórias; pode progredir por treinamento/serviços fora das expedições (R31-Q3, R33-Q2).
- **Preservação:** XP e níveis são preservados após derrota definitiva ou retirada voluntária (R32-Q3).
- **Nível e pontos:** cada nível concede **1 ponto distribuível ao protagonista**; a distribuição é **obrigatória antes de concluir a progressão** e não pode ser acumulada voluntariamente (R13-Q4, R14-Q4).
- **Aliados:** crescem automaticamente por curvas de espécie, influenciadas por Tactic e ações executadas (R12-Q5, R13-Q5, R15-Q3, R17-Q3); fórmulas pendentes.
- **Evolução:** quando os requisitos são atingidos, o jogador escolhe **quando** evoluir (R25-Q3).
- **Recompensas:** moedas, recursos e itens são tipos previstos para batalhas comuns; moedas compram itens/recursos de NPCs e lojas (R27-Q5, R28-Q1, R29-Q1).
- **Fim de expedição:** vencer o chefe encerra a expedição e retorna à campanha; a recompensa principal é o avanço/desbloqueio, e recompensas materiais são opcionais (R26-Q4, R28-Q5).
- **Derrota:** se todos os ativos caem, ocorre derrota definitiva e a expedição é encerrada, com as perdas/preservações já aprovadas (R23-Q3, R33-Q1).
- **Ordem/UI:** o GDD **não define** a ordem das telas pós-combate, o layout do “level up”, nem como a alocação obrigatória aparece. “Interface” e “limites” estão pendentes.

### 2.2 O que o jogo tem hoje

- `scripts/combat/battle_scene.gd` (`_on_battle_ended`): desliga a pausa, encerra slow-motion, chama `fx.finish(player_won)` (pose de vitória), esconde o menu, limpa o alvo, **espera 3 s** e chama `GameState.end_battle(player_won)`.
- `scripts/autoload/game_state.gd` (`end_battle`): se venceu, adiciona o `encounter_id` a `defeated`; limpa `encounter_id`; marca `in_battle = false`; troca a cena para `scenes/exploration.tscn`. **Não há XP, nível, pontos, alocação, evolução, recompensa, tela de resultados nem salvamento.**
- `Combatant` não tem `level`, `xp`, `attribute_points`, `attributes`, `max_mp` ou `mp`. O `StatusScreen` mostra **NV. —**, **EXP N/D**, **MP N/D**, **DEF N/D** e **PASSIVA: SEM HABILIDADE**.
- O HP atual persiste entre batalhas porque os mesmos objetos `Combatant` ficam em `GameState.party`; não há MP.
- A equipe começa com **Abra + Pancham** (`GameState._build_party`), não só com o protagonista; não há reserva.
- Derrota: `end_battle(false)` faz exatamente o mesmo retorno ao mapa; **não encerra a expedição**, não perde itens e não preserva XP (porque não há XP).
- `BattleReward` (`scripts/combat/battle_reward.gd`) é apenas um **token visual de ATB/Burst** para o HUD; não é recompensa de batalha/loot/XP.
- Não há save/load de progresso; o estado vive em memória e reinicia com o jogo.

### 2.3 Lacunas e divergências

| Ponto | GDD | Jogo | Situação |
|---|---|---|---|
| XP para todos os ativos | Aprovado (R26-Q3) | Não existe | **Não implementado** |
| Nível e 1 ponto por nível | Aprovado (R13-Q4) | Não existe | **Não implementado** |
| Alocação obrigatória antes de concluir | Aprovado (R14-Q4) | Não existe | **Não implementado** |
| Crescimento automático dos aliados | Aprovado (R12-Q5/R13-Q5) | Não existe | **Não implementado** |
| Evolução escolhida pelo jogador | Aprovado (R25-Q3) | Não existe | **Não implementado** |
| Reserva e treino | Aprovado (R31-Q3/R33-Q2) | Não existe reserva | **Não implementado** |
| Recompensas moedas/itens | Aprovado (R27-Q5) | Não existe | **Não implementado** |
| Derrota encerra a expedição | Aprovado (R23-Q3/R33-Q1) | Volta ao mapa como vitória | **Divergência** |
| Começar só com o protagonista | Aprovado (R27-Q2) | Começa com Abra + Pancham | **Divergência** |
| Ordem/UI do pós-combate | Pendente | 3 s + pose + troca direta de cena | **GDD omisso** |

### 2.4 O que já está no jogo e não está no GDD (candidatos a documentar)

- A **pose de vitória** e os **3 s** antes de voltar ao mapa.
- O **retorno direto** ao mapa, sem tela de resultados.
- A **persistência de HP** entre batalhas (GDD já diz que HP persiste, mas não descreve a implementação).
- A **ausência de tela de derrota** e o retorno ao mapa mesmo com derrota (isto é divergência, não sugestão de GDD).
- O `StatusScreen` com `N/D` para nível/EXP/MP/DEF/passiva (protótipo de UI).

### 2.5 Decisões necessárias

1. Qual é a **ordem** do pós-combate: resultados → XP → level up → alocação → mapa? Tudo numa tela ou telas separadas?
2. Qual a **fórmula de XP** e a **curva de nível**? (O GDD deixa pendente; a proposta em `docs/PROPOSTA_ATRIBUTOS_NIVEL_XP.md` está marcada como inválida.)
3. Quantos pontos por nível, quais atributos podem receber, o que acontece com pontos não distribuídos e como a alocação obrigatória bloqueia a saída?
4. Aliados crescem por curva fixa, por Tactic/ações ou ambos? Qual a fórmula?
5. Evolução: requisitos, UI e momento; o que acontece com os Moves conhecidos?
6. Recompensas: moedas, itens e recursos entram agora? Quais?
7. Derrota: encerra a expedição e volta para onde? Perde quais itens? O que é preservado?
8. O jogo terá **save**? Sem isso, XP/nível/recompensas não persistem entre sessões.

> **Atenção:** implementar XP/nível/alocação é uma mudança grande e depende de decisões de fórmula, curva, atributos e save. O GDD atual não dá números; não inventar.

---

## 3. Transição para o mapa pós-combate

### 3.1 O que o GDD define

- O jogo alterna **exploração 2D** e **combate 3D em cena separada** (GDD §1).
- Ao voltar, o jogador retorna à exploração “quando permitido”; o layout do andar, itens coletados e inimigos derrotados permanecem (R9-Q2, R9-Q4, R36-Q3).
- Vencer o chefe encerra a expedição e retorna à campanha (R26-Q4); derrota encerra a expedição (R23-Q3/R33-Q1).
- A arena 3D deve refletir o bioma do encontro (R38-Q2, pendente).
- **Não há especificação** da transição visual de entrada/saída, do tempo, do fade, de uma tela de resultados ou do ponto exato de retorno. “Transições” aparece como pendente.

### 3.2 O que o jogo tem hoje

- **Entrada:** `scripts/ui/transition.gd` — “Fenda tática”: 5 painéis inclinados fecham, o selo **ENCONTRO / MON SELVAGEM** estampa, os painéis abrem; duração **1,5 s**; a cena troca em **46%**; a revelação acontece em **60%**; a árvore é pausada enquanto os painéis cobrem a tela.
- `GameState.start_battle(id, pos)` guarda `encounter_id` e `player_pos`, marca `in_battle = true` e chama a transição. `battle_scene` espera `transition.revealed` antes da intro.
- **Saída:** `battle_scene._on_battle_ended` → `fx.finish` (pose de vitória) → **3 s** → `GameState.end_battle` → `change_scene_to_file(EXPLORATION)` **sem transição/fade**.
- Ao voltar, `exploration.gd` reutiliza `dungeon_layout`, `dungeon_explored`, `dungeon_items_collected` e `defeated`; o jogador reaparece em `player_pos` (se não for parede); há **1,25 s** de `POST_BATTLE_GRACE` em que o contato com inimigo não inicia batalha.
- Não há tela de resultados, recompensas, XP, level up ou “vitória/derrota” explícita; a única saída é a troca direta de cena.

### 3.3 Lacunas e divergências

| Ponto | GDD | Jogo | Situação |
|---|---|---|---|
| Entrada 2D → 3D | Cena separada | “Fenda tática” 1,5 s | **GDD omisso; jogo tem solução** |
| Saída 3D → 2D | “Retornar à exploração” | 3 s + troca direta, sem transição | **GDD omisso** |
| Ponto de retorno | Não definido | Posição salva do encontro | **GDD omisso** |
| Graça pós-batalha | Não definida | 1,25 s | **GDD omisso** |
| Derrota | Encerra expedição | Volta ao mapa | **Divergência** |
| Chefe | Volta à campanha | Não existe chefe/campanha | **Não implementado** |
| Resultados/recompensas | Previstos (XP/itens) | Não existem | **Não implementado** |

### 3.4 O que já está no jogo e não está no GDD (candidatos a documentar)

- O nome, o desenho e o tempo da transição **“Fenda tática”**.
- O selo **“ENCONTRO / MON SELVAGEM”**.
- Os **3 s** de pose de vitória antes do retorno.
- A **graça de 1,25 s** e o retorno à posição exata.
- A ausência de transição na volta (se isso é intencional, o GDD deveria dizer; se não, é dívida).

### 3.5 Decisões necessárias

1. A volta ao mapa deve ter **transição visual** (fade, painel, “retorno”) ou fica direta?
2. Deve existir **tela de resultados** antes do mapa? Se sim, o que mostra (XP, nível, itens, moedas, cura)?
3. O jogador volta ao **ponto exato** do encontro ou à entrada do andar?
4. Derrota e vitória usam a **mesma** transição? O que muda?
5. A transição de entrada deve entrar no GDD como regra de UX ou permanecer como detalhe de implementação?

---

## 4. Sistema de troca de Moves

### 4.1 O que o GDD define

- **Até 8 Moves utilizáveis em combate**, dos quais **4 principais** servem de hotkeys rápidas; **Tackle genérico fica separado** dos 8 (R38-Q5).
- **Gerenciamento pendente:** escolha/armazenamento dos Moves conhecidos, critérios para os 8 disponíveis, organização dos 4 principais, forma de acessar os demais e relação das posições extras com custos (R38-Q5).
- **Aprendizado:** nível/progressão é a fonte principal de novos Moves comuns; mestres, HMs/TMs (só combate por enquanto) e outras fontes também valem; listas por espécie, requisitos, ritmo, aprendizado e gerenciamento pendentes (R27-Q4, R23-Q5, R24-Q4).
- **Evolução:** preservar os Moves conhecidos ao evoluir e permitir aprender os da espécie evoluída é uma opção em aberto (GDD R39, linhas 1630–1633).
- **Custos:** os custos ATB/Burst/MP anteriores continuam; nenhum Move usa PP; não criar custos para os 4 adicionais sem decisão.
- **Não há decisão** sobre: onde trocar (menu, hub, mestre), quando, custo, se a troca é livre, se o Move substituído é esquecido, se os 4 principais são fixos ou escolhidos, se Tackle ocupa slot, nem como o jogador vê os 8.

### 4.2 O que o jogo tem hoje

- **Não existe sistema de troca.** Os Moves são listas fixas criadas no código:
  - `GameState._build_party`: Abra com **7** Skills; Pancham com **6**.
  - `battle_scene._new_gible`: Gible com **4**.
  - `DqtTestParty.build`: Slime/Orc/Cyclops com **3** cada.
- `StatusScreen` mostra `Tackle + todos os skills`, navega com ←/→ e abre detalhes; **não equipa, desequipa, troca nem reordena**.
- O menu FIGHT monta `Tackle + leader.skills`; **todos** os Moves do líder ficam disponíveis. As teclas **1–9** usam o Move da posição e **R** repete o último; não há distinção de “4 principais”.
- Não existe banco de Moves, lista de “conhecidos”, “aprendidos”, “esquecidos”, slots de 8, nem hotkeys configuráveis.
- `Skill` é instanciado em código; `move_id` é derivado do nome de exibição por `BattleSpace.move_id()`, com aliases. Não há um `move_id` explícito no dado.

### 4.3 Lacunas e divergências

| Ponto | GDD | Jogo | Situação |
|---|---|---|---|
| Até 8 Moves + 4 hotkeys | Aprovado (R38-Q5) | Abra 7 + Tackle; Pancham 6 + Tackle; Gible 4 | **Não implementado** (e o total não é 8 + Tackle) |
| Gerenciamento/ troca | Pendente | Não existe | **GDD e jogo omissos** |
| Aprender por nível | Aprovado (R27-Q4) | Não existe nível | **Não implementado** |
| Mestres/HMs/TMs | Aprovado (R23-Q5/R24-Q4) | Não existe | **Não implementado** |
| Tackle separado | Aprovado | Tackle é `Skill.basic()` e entra na listaFIGHT | **Parcial/ divergente na UI** |
| Custo dos 4 adicionais | Pendente | Não se aplica | **GDD omisso** |

### 4.4 O que já está no jogo e não está no GDD (candidatos a documentar)

- Teclas **1–9** para escolher Move e **R** para repetir.
- `StatusScreen` com cartões de Move (custo ATB, elemento, poder) e navegação ←/→.
- Listas **hardcoded** por personagem.
- `move_id` derivado do nome, com aliases em `BattleSpace.move_id()`.

> Esses pontos são UX/implementação. O GDD precisa, antes, da **regra de troca**; a UI pode ficar em um documento separado.

### 4.5 Decisões necessárias

1. A troca acontece **fora de combate** (menu X), no **hub**, com um **mestre NPC**, ou em mais de um lugar?
2. É **livre** ou tem custo (item, moeda, descanso)?
3. O jogador escolhe os **4 principais** entre os 8? Os 4 são os primeiros? Podem ser reordenados?
4. **Tackle** ocupa um dos 8 ou continua separado (e aparece sempre)?
5. O Move substituído é **esquecido** ou volta para uma lista de conhecidos? Pode reaprender?
6. Como o jogador obtém Moves: nível, mestre, HM/TM, evento? Quais listas por espécie?
7. Os 8 Moves têm custos iguais? O GDD diz que os custos anteriores valem, mas não define os adicionais.
8. A troca pode acontecer no meio da expedição? Se sim, em que ponto?

> **Não implementar** troca de Moves antes de responder a 1–5. O GDD atual só autoriza “até 8/4” e deixa o resto pendente.

---

## 5. HP e MP visíveis no overworld, não em combate

### 5.1 O que o GDD define

- **HP:** medidor de vida; máximo derivado de Vitality + nível; HP atual persiste entre batalhas da mesma dungeon até ser recuperado (R11-Q2, R14-Q3); pontos de descanso recuperam HP (R32-Q2, quantidade pendente).
- **MP:** recurso separado; máximo derivado de Magic + nível; Moves mágicos/especiais gastam MP além de ATB/Burst; MP persiste entre batalhas da mesma dungeon; recupera 25% do máximo a cada 3 s com ATB 5/5 (arredondado para baixo); restaura no descanso e no início de nova exploração (R11-Q3, R12-Q1/Q2/Q3, R13-Q1/Q2/Q3, R14-Q2, R15, R16, R17).
- **Interface:** “interface” do MP aparece como pendente (R11-Q3); a interface gráfica final do combate 3D é listada como pendente (GDD §7); **o GDD não define onde HP/MP aparecem** — se no overworld, no combate, nos dois, em barras, números ou menu.
- **Nenhuma regra** diz “HP/MP só no overworld” ou “não mostrar em combate”.

### 5.2 O que o jogo tem hoje

- **Overworld:** não há HUD. HP só aparece no menu X (lista de personagens e `StatusScreen`); MP aparece como **N/D**; DEF, nível, EXP e passiva também são **N/D**.
- **Combate:** `BattleHud` mostra HP do jogador, aliados e inimigos (cartões e etiquetas flutuantes), ATB, Burst, Burn e números de dano/cura; **não mostra MP**.
- `Combatant` não tem `max_mp`/`mp`; `Skill` não tem custo de MP; não há recuperação de MP, descanso ou início de exploração com MP cheio.
- O HP atual persiste porque os `Combatant` são os mesmos entre cenas; não há cura automática ao voltar.

### 5.3 Lacunas e divergências

| Ponto | GDD | Jogo | Situação |
|---|---|---|---|
| HP visível no overworld | Não definido | Só no menu X | **GDD omisso; decisão nova necessária** |
| MP visível no overworld | Não definido | Não existe MP | **GDD omisso; MP inteiro não implementado** |
| HP visível em combate | Não proibido | Sim | **Proposta do criador contradiz o estado atual** |
| MP em combate | Não definido | Não existe | **Não implementado** |
| MP máximo/custos/recuperação | Aprovado em regra, números pendentes | Não existe | **Não implementado** |
| HP/MP persistência | HP e MP persistem na dungeon | HP sim; MP não existe | **Parcial** |

> **Importante:** “HP/MP visíveis no overworld, não em combate” é uma **nova regra de UI**, não uma correção do GDD. Ela precisa ser registrada como decisão. Também é ambígua: “não em combate” significa remover **todo** HP/MP do combate, inclusive a vida dos inimigos e os números de dano? Ou só os medidores do jogador/aliados?

### 5.4 O que já está no jogo e não está no GDD (candidatos a documentar)

- HUD de batalha com HP do jogador, aliados e inimigos; etiquetas flutuantes; barras de ATB/Burst; Burn; números de dano/cura.
- `StatusScreen` com HP, ATK, VEL, fraquezas e cartões de golpes; `N/D` para MP/DEF/nível/EXP/passiva.
- **Nada** de HP/MP no overworld.

> O HUD de combate é assunto de decisões/REGRAS (D-001), não do GDD. O GDD pode, no máximo, descrever a **filosofia** (o que o jogador vê no overworld vs. no combate) e apontar para a decisão.

### 5.5 Decisões necessárias

1. O HP/MP do **líder**, dos **três ativos** ou de **todos** aparecem no overworld?
2. Formato: barra + número, só número, ícone com porcentagem, canto fixo ou acima do personagem?
3. **Remover** HP/MP do combate ou apenas **não mostrar os do jogador**? A vida dos inimigos continua? Os números de dano continuam?
4. O MP precisa ser implementado antes (máximo, custo, recuperação, descanso, início de exploração)? Quais números?
5. O HUD do overworld é sempre visível ou alterna com X? Ele pausa o jogo?
6. O que acontece quando um personagem cai no overworld? A barra some, fica vazia, mostra “KO”?

---

## 6. Modelos 3D dos personagens de Dragon Quest Tact no overworld

### 6.1 O que o GDD define

- **Exploração 2D** com o protagonista controlado diretamente; **combate 3D** em cena separada, com modelos tridimensionais dos mesmos Pokémon (GDD §1).
- A arena 3D deve refletir o bioma do encontro (R38-Q2, pendente).
- O GDD trata “sprites 2D” como pendência de implementação, mas **não prevê um overworld 3D**.
- **Não há nenhuma menção a Dragon Quest Tact, modelos DQT ou substituição dos sprites por modelos 3D no overworld.**

### 6.2 O que as decisões dizem (e por que isso importa)

- **D-275:** “O overworld permanece 2D. O combate 3D é referência visual.” O criador foi explícito: **“NÃO É PRA DEIXAR O OVERWORLD 3D”**.
- **D-278:** restaurar o overworld anterior e alterar somente a paleta.
- **D-313:** o overworld continua **2D**; **não importar novos modelos por ora**; usar os sprites overworld existentes; a sombra elíptica sob entidades **não** foi autorizada.
- **D-317:** **não serão importados novos modelos** nesta fase; usar os sprites existentes.
- **D-324:** o hub é **2D**, com **sprites existentes**, **sem modelos novos**.
- **D-325:** autoriza assets 2D não-Pokémon do Mystery Dungeon; **Pokémon do site ficam de fora**; os sprites/retratos existentes continuam.
- **D-319:** a F3 mexe só no overworld; a batalha 3D continua com o **Gible fixo**.
- **D-336 a D-342:** os modelos DQT (Slime, Orc, Cyclops) são um **teste de crossover na batalha** (`--dqt`, `--dqt-mirror`, F11), com escala, posição, olhos, passo e arma próprios. **Não são conteúdo do overworld nem substituem os Pokémon.**

### 6.3 O que o jogo tem hoje

- **Overworld 2D:**
  - `player.gd`, `follower.gd` e `npc.gd` usam `Sprite2D` com `res://personagens/overworld/<direção>/<species>.png` (e `frame2/`), escala 1,2, filtro nearest.
  - `exploration.tscn` é `Node2D`; tile de **48 px**; câmera **2,3×** (D-344); Y-sort; `AStarGrid2D`; névoa; atlas do **Temporal Tower** (D-330).
  - `personagens/overworld/down` tem **1.212 arquivos** (base + frame2), `personagens/portraits` **612**, `personagens/icons` **606**.
- **Combate 3D:**
  - `assets/modelos` tem **6 pastas**: `abra`, `gible`, `pancham` (Pokémon) e `dqt_slime`, `dqt_orc`, `dqt_cyclops` (DQT).
  - `battle_scene._make_model` carrega o GLB; se não existir, cai num **capsule** procedural.
  - DQT: perfis Y-up, altura-alvo, clipes, arma na mão, olhos/piscar, passo casado; tudo **no combate**.
- **Manifesto:** **297 espécies usáveis**, todas com `has_3d_model = true` e `has_overworld = true`; **294** vêm do Legends Z-A e **3** do Arenamon chars. Mas **apenas 3 GLBs de Pokémon estão importados** no projeto.
- **Teste DQT:** `--dqt` coloca o trio no lado do jogador; `--dqt-mirror` no lado inimigo; **F11** alterna. `DqtTestParty` não substitui `GameState.party`; a exploração continua com sprites Pokémon.

### 6.4 Análise: dá para aplicar os modelos DQT no overworld?

**Resposta curta:** tecnicamente dá para colocar um `Node3D` numa cena 2D, mas **não é uma troca de asset**. As decisões atuais **proíbem** o overworld 3D e a importação de novos modelos. Portanto, isso é uma **nova direção**, não uma atualização de GDD.

**O que seria necessário:**

1. **Escopo de personagens.** Os DQT são só **3** (Slime, Orc, Cyclops). Eles não representam os **297 Pokémon** usáveis. Se o objetivo é “os personagens DQT no overworld”, quais? Se é “substituir os sprites dos Pokémon por 3D”, os DQT não servem.
2. **Modelos.** Para os Pokémon, o manifesto diz que **297 têm modelo 3D de origem** (294 Z-A + 3 Arenamon), mas **só 3 estão importados**. Seria preciso importar, riggar, animar e validar **294** modelos; os DQT têm pipeline próprio (Y-up, clipes, arma, olhos, passo) que não é o pipeline dos Pokémon (Z-up, `MODEL_SCALE`, `_strip_root_motion`).
3. **Cena 3D ou 2.5D.** O overworld hoje é `Node2D` com tilemap 2D, câmera ortográfica 2D, colisão 2D, `AStarGrid2D`, névoa 2D e Y-sort. Um overworld 3D exigiria:
   - chão/tiles 3D ou 2.5D, câmera 3D, iluminação, sombras (a sombra elíptica não foi autorizada), oclusão, ordenação;
   - colisão/navegação 3D ou híbrida;
   - animação de caminhada em 8 direções ou personagem sempre virado para a câmera;
   - ancoragem de UI, diálogo, retratos e prompts;
   - desempenho e LOD.
4. **Retratos e diálogo.** O `DialogueBox` usa retratos PMD 2D. DQT não tem retrato PMD; seria preciso renderizar o modelo 3D em um retrato ou usar fallback.
5. **Escala e estilo.** DQT é um estilo realista/estilizado de Tact; Pokémon é outro. Misturar no mesmo overworld pode quebrar a coerência visual que D-275/D-278 buscam.
6. **Decisões.** D-275, D-313, D-317 e D-324 teriam de ser **explicitamente substituídas** por uma nova decisão. Não se pode “atualizar o GDD” para 3D sem o criador revogar essas decisões.

**Opções (não são decisões):**

| Opção | O que é | Custo | Conflito |
|---|---|---|---|
| A. Manter 2D | Sprites atuais; DQT só no combate/teste | Zero | Nenhum (segue D-275/D-313/D-317/D-324) |
| B. 2.5D | Personagens 3D sobre o tilemap 2D | Alto (modelos + câmera + ordenação + sombra) | Parcial com D-275 (“não deixar o overworld 3D”) |
| C. Overworld 3D completo | Tiles/câmera/colisão/navegação 3D | Muito alto | Revoga D-275/D-313/D-317/D-324 |
| D. DQT só no combate | Como hoje; talvez expandir o teste | Baixo | Nenhum |
| E. DQT como NPCs especiais | Poucos modelos 3D ou sprites pré-renderizados | Médio | Precisa de decisão e portraits |

### 6.5 O que já está no jogo e não está no GDD (candidatos a documentar)

- O pipeline DQT de batalha (escala, Y-up, clipes, arma, olhos, passo) e os atalhos de teste (`--dqt`, `--dqt-mirror`, F11).
- A cena de teste do hub (`F10`) com Treasure Town e dois NPCs de teste.
- O atlas do Temporal Tower e a câmera 2,3× (D-330/D-344).
- O manifesto de **297 usáveis** e a regra de que todos têm modelo 3D de origem, mas só 3 estão importados.
- O fallback de cápsula quando falta GLB.

> **Não** propor isso como “atualização do GDD” sem antes decidir a direção. O GDD atual está coerente com 2D; o pedido de 3D é uma **mudança de produto**.

### 6.6 Decisões necessárias

1. O que exatamente se quer: **DQT no overworld** (quais personagens?), **Pokémon em 3D no overworld** (todos os 297 ou só o grupo ativo?) ou **overworld 3D completo**?
2. A direção 2D de D-275/D-313/D-317/D-324 continua valendo? Se não, qual nova decisão substitui?
3. Se for 3D: **tiles 3D** ou **personagens 3D sobre tiles 2D**? Câmera fixa, orbital ou top-down?
4. Quais modelos entram primeiro? Só o grupo ativo + NPCs + inimigos? Todos os 297?
5. Como ficam os **retratos/diálogo**, a **sombra** (proibida) e a **performance**?
6. O combate 3D continua como está (D-319) ou também muda?

---

## 7. NPCs, mercadores, inimigos e NPCs especiais (quests/recrutamento)

### 7.1 O que o GDD define

- **NPCs e campanha:** objetivos e missões que desbloqueiam dungeons são apresentados principalmente por personagens, NPCs e acontecimentos narrativos (R31-Q4).
- **Mercadores/lojas:** moedas compram itens/recursos de NPCs ou lojas; comerciantes e lojas podem existir **dentro das dungeons** e **fora das expedições**, na seleção/progressão da campanha (R28-Q1, R29-Q1). Catálogo, preços, localização e interface pendentes.
- **Salas secretas e NPCs especiais:** salas secretas são opcionais, com recompensas, eventos e **NPCs especiais**; descobertas por pistas, mapas, NPCs ou eventos (R26-Q5, R33-Q4).
- **Recrutamento comum:** Pokémon elegíveis oferecem recrutamento por **interação voluntária explícita** no mapa 2D; contato hostil normal continua iniciando combate 3D (R23-Q4, R24-Q2, R35-Q2).
- **Recrutamento especial:** Pokémon especiais aparecem como candidatos identificados no mapa e exigem uma **tarefa/evento** antes de efetivar o recrutamento (R26-Q2, R32-Q5).
- **Prioridade de conteúdo:** eventos, salas secretas, recompensas especiais e NPCs nas dungeons procedurais (R25-Q5).
- **Inimigos:** visíveis no mapa, patrulham, perseguem após detecção e iniciam combate por contato (R8-Q5, R9-Q3, R37-Q1); derrotados são removidos da expedição (R9-Q4).
- **Ameaça/grupos (decisões):** quatro níveis (Medroso/Fraco/Valente/Perigoso), soma dos níveis, tamanho/ícone, distâncias/velocidades, grupos de até 3, líder substituído (D-310, D-315, D-321).
- **O GDD não tem catálogo** de NPCs, estoque/preços de mercador, lista de quests, condições de recrutamento nem identidade dos NPCs especiais.

### 7.2 O que o jogo tem hoje

- **NPCs:** 2 a 3 por andar (`DungeonGenerator.NPC_COUNT`), sorteados de uma lista de **177 candidatos** (`npc_data.gd`), com **18 falas** aleatórias.
  - `DungeonNPC` é `StaticBody2D` com colisão 28×28; sprite 1,2×, retrato PMD; prompt **“[Z] FALAR”**; vira para o jogador quando ele se aproxima (D-313); bloqueia movimento e é sólido no `AStarGrid2D`.
  - **Não há** mercador, loja, quest, recrutamento, NPC especial, serviço, preço, moeda ou persistência: os NPCs são sorteados de novo a cada carregamento da cena (o layout é fixo, mas a espécie/fala não é persistida).
- **Inimigos:** 4 a 6 por andar; visual de **blob vermelho** (não é sprite de Pokémon); patrulha 42 px/s, persegue 105 px/s, vê a 6,5 tiles com linha de visão, ouve a 3 tiles, perde o rastro a 9 tiles/4 s, contato a 26 px, raio de patrulha 4 tiles.
  - Não têm **espécie, nível, ícone/tamanho de ameaça, grupo** nem composição. O combate é sempre o **Gible fixo** (D-319).
  - O contato de um **aliado seguidor** também inicia batalha (R37-Q1); há **1,25 s** de graça após voltar.
  - O derrotado é removido via `GameState.defeated` (R9-Q4).
- **Hub test:** `hub_test.tscn` (F10) tem 2 NPCs fixos (Bulbasaur, Charmander) com falas de placeholder e **nenhum serviço**.
- **Não há** moedas, loja, estoque, preço, quest, diário, facção, NPC especial ou recrutamento.

### 7.3 Lacunas e divergências

| Ponto | GDD | Jogo | Situação |
|---|---|---|---|
| NPCs de ambientação | Aprovado genericamente | 2–3/andar, 177 espécies, 18 falas | **Parcial** |
| Mercadores/lojas | Aprovado (R28-Q1/R29-Q1) | Não existe | **Não implementado** |
| Moedas/preços | Aprovado como tipo de recompensa/uso | Não existe | **Não implementado** |
| Quests/missões | Aprovado (R31-Q4/R34-Q1) | Não existe | **Não implementado** |
| NPCs especiais/salas secretas | Aprovado (R26-Q5/R33-Q4) | Não existe | **Não implementado** |
| Recrutamento comum | Aprovado (R23-Q4/R24-Q2/R35-Q2) | Não existe | **Não implementado** |
| Recrutamento especial | Aprovado (R26-Q2/R32-Q5) | Não existe | **Não implementado** |
| Inimigos com espécie/nível/ameaça | Aprovado (D-310/D-315/D-321) | Blob sem espécie/nível; Gible fixo | **Não implementado** |
| Detecção por proximidade (R38-Q1) | Aprovado | Código usa visão + audição | **Divergência** |
| Grupos de inimigos (D-321) | Aprovado | Não existe | **Não implementado** |

### 7.4 O que já está no jogo e não está no GDD (candidatos a documentar)

- O **pool de 177 NPCs** e as **18 falas** genéricas.
- O prompt **[Z] FALAR**, o retrato PMD, o NPC virando para o jogador e a colisão que bloqueia o caminho.
- O **blob vermelho** dos inimigos (visual provisório).
- Os números atuais de detecção/patrulha/perseguição e a **graça de 1,25 s**.
- A cena de teste do hub (F10) e seus dois NPCs.
- A ausência de persistência dos NPCs entre carregamentos (não é uma regra; é um estado).

> Os números de detecção atuais **contradizem** D-310/D-315; não são candidatos a “entrar no GDD” como regra. O GDD deve apontar para as decisões novas, não fossilizar o provisório.

### 7.5 Decisões necessárias

1. **Quais tipos de NPC** existem: ambientação, mercador, quest, treinador/mestre, recrutamento, especial? Quais entram primeiro?
2. **Mercadores:** onde (dungeon/hub/campanha), estoque, preços, moeda, restock, interface. O GDD deixa pendente; não inventar.
3. **Quests:** quem dá, como aparece, o que conta, o que persiste entre expedições, recompensa. R37-Q2 diz que o progresso fica principalmente na expedição atual; confirmar.
4. **NPCs especiais:** quem são, como aparecem, que tarefa pedem, como o jogador os identifica.
5. **Recrutamento:** comum vs especial, elegibilidade, interação, chance, equipe/reserva, o que acontece se a equipe estiver cheia.
6. **Inimigos:** espécie/nível/ameaça/grupo, ícone/tamanho, quais espécies por bioma, como o nível é recalculado (D-310/D-315).
7. **Persistência:** NPCs e inimigos devem manter espécie/estado ao revisitar o andar? Hoje os inimigos derrotados persistem, mas os NPCs são sorteados de novo.

---

## 8. Atributos de personagens, atributos de Moves, elementos, tipos e informações

### 8.1 O que o GDD define

- **Atributos:** cinco atributos inspirados em SMT3 — **Strength, Magic, Vitality, Agility, Luck** — em **escala 1–100**; HP derivado de Vitality + nível; MP derivado de Magic + nível (R10-Q1/Q2, R11-Q1/Q2/Q3).
- **Nível/XP:** cada Pokémon tem nível; atributos evoluem com o nível; o protagonista recebe 1 ponto por nível e distribui manualmente; aliados crescem por curvas de espécie (R10-Q3, R11-Q4, R12-Q4/Q5, R13-Q4/Q5).
- **Natures:** influenciam atributos, crescimento e tendências comportamentais (R14-Q5, R15-Q4, R16-Q4/Q5, R17-Q4, R18-Q4/Q5, R19-Q5, R20-Q5, R21-Q5, R22-Q5).
- **Dano:** Strength origina dano físico; Magic origina dano mágico/especial; Vitality mitiga dano físico; Spirit mitiga dano mágico; Luck influencia crítico, esquiva automática e status; Agility acelera ATB e reduz trajeto (D-122, D-130, D-127, D-117/D-119).
- **Moves:** até 8 utilizáveis, 4 principais; Tackle separado; sem PP; Moves mágicos/especiais gastam MP; custos ATB/Burst anteriores valem; fichas com dano, categoria, escalas, windup, trajeto, velocidade de projétil, alvos e efeitos (D-244 a D-249).
- **Tooltips:** custos/windup no cabeçalho; descrição em prosa com dano/cura **numéricos**, efeitos, chances, duração e condições; descrição visual só na ficha fora de combate (GDD §12.24–12.25, que cita D-229/D-230).
- **Elementos:** o sistema é inspirado principalmente em **Shin Megami Tensei**, não em Pokémon; preservar as 11 categorias atuais (`FISICO`, `FOGO`, `AGUA_GELO`, `RAIO`, `PSIQUICO`, `VENENO`, `SOM`, `TERRA`, `VENTO`, `LUZ`, `TREVAS`); afinidades por espécie com SMT como referência; tabela global ainda em aberto (D-118, D-128).
- **Tipos:** o GDD fala de “tipos” de forma genérica; **não há uma tabela de tipos Pokémon** (Fogo/Água/Planta etc.) nem uma lista de resistências/imunidades. O que existe são **elementos** e **fraquezas** por personagem.

### 8.2 O que o jogo tem hoje

- **`Combatant`:** `max_hp`, `hp`, `base_attack`, `mag` (provisório, espelha `base_attack`), `base_speed` (blocos/s), `weaknesses`, `held_item_id`, `skills`, buffs `atk_buff`/`def_buff`/`speed_buff` (−5..+5), status (`is_invulnerable`, `stun_timer`, `blind_timer`, `taunted_by`, `guard_timer`, `burn_ticks_left`), ATB/Burst, passos de posição.
  - **Não há** `STR`, `MAG` (como atributo separado), `VIT`, `SPI`, `AGI`, `LUK`, `level`, `xp`, `max_mp`, `mp`, `nature`, `defense`, `passive`, `resistances` ou `immunities` como dados de personagem.
- **Dano:** `attack * power * 1.5 (fraqueza) * 2.0 (crítico) * passo (±10%)`, mínimo 1; `def_buff` reduz; Guard reduz 50% provisório (ceil); Burn tira 2 HP fixos por tick. Não usa STR/MAG nem VIT/SPI.
- **Crítico/esquiva:** 10% fixos; sem LUK. **Fraqueza:** 1.5×. **Passos:** +10% por passo à frente, −10% por passo atrás.
- **Elementos:** 11 em `scripts/data/element.gd`; cada personagem tem uma lista de **fraquezas** (Abra: Trevas/Som; Pancham: Psíquico/Vento; Gible: Água/Gelo; DQT: Fogo/Raio/Psíquico). **Não há resistências, imunidades, absorção, reflexão ou tabela por espécie.**
- **Moves:** `Skill` tem `display_name`, `power` (multiplicador), `cost` (ATB), `element`, `kind` (MELEE/PROJECTILE/CAST/STATUS), `ground`, `is_aoe`, `is_friendly`, `windup`, `aoe_on_contact`.
  - **Não tem** custo de MP, categoria físico/mágico, precisão, modo de alvo (Self/One/Two/All), lista de efeitos, chance/duração de status, número de hits, descrição, tooltip ou `move_id` explícito.
  - Moves são listas fixas: Abra 7, Pancham 6, Gible 4, DQT 3. Não há banco de dados nem “lista de conhecidos”.
  - `move_id` é derivado do nome (`BattleSpace.move_id`) com aliases.
- **Status:** aplicados por `match` no nome do Move em `battle.gd`: Media cura 10 + MAG; Tarukaja +1 ATK; Rakunda −1 DEF; Sukunda −1 SPD; Taunt; Sand Attack cega 4 s; Karate Chop 30% −1 SPD; Bite 30% stun 2 s; Brick Break quebra Guard; Fire Bullet aplica Burn quando interrompe.
- **UI de informação:** `StatusScreen` mostra HP, ATK, VEL, fraquezas e cartões de Move com **custo ATB, elemento e “Poder ×1,3”**; **Descrição: N/D**, **DEF N/D**, **MP N/D**, **NV. —**, **EXP N/D**, **PASSIVA: SEM HABILIDADE**. No combate, a lista FIGHT mostra nome, custo/elemento e tempo de trajeto, mas **não o dano numérico**.
- **`CrawlmonAttributeMath`:** implementa fórmulas aprovadas (offsets individuais, crítico por LUK, status por LUK, esquiva automática por LUK, incremento de ATB por AGI), mas o próprio arquivo diz **“Not wired into Combatant, Battle or Skill”**.
- **`Guard`:** 50% provisório (D-272), sem VIT/SPI. **`travel_extra`:** provisório para Orc/Cyclops (D-341), até a AGI existir.

### 8.3 Divergências entre GDD e decisões (o GDD está desatualizado)

| Ponto | GDD | Decisão vigente | Consequência |
|---|---|---|---|
| Quantidade de atributos | **5** (STR/MAG/VIT/AGI/LUK) | **6**, com **Spirit (SPI)** (D-130/D-131) | GDD §7.1 e linha 386 precisam de correção |
| Escala | **1–100** | **Sem escala 1–100**; valores crescem com o nível e não há teto 100 (D-269/D-139) | GDD §7.1, R10-Q2 e REGRAS §14.7 estão obsoletos |
| Nature e crescimento | Nature influencia **crescimento** | Nature afeta **só atributos e formas de agir**; **não** inclina crescimento (D-271) | GDD R14-Q5/R15-Q4/R16 etc. precisam de ressalva |
| HP/MP | HP = VIT+nível; MP = MAG+nível | Regras gerais mantidas; fórmulas e números pendentes (D-124 etc.) | GDD não deve fingir fórmula pronta |
| Dano | STR físico / MAG mágico; VIT/SPI mitigam | Aprovado (D-122/D-130) | Código não implementa |
| LUK | Crítico/esquiva/status | Aprovado (D-127/D-146/D-150–D-153) | Código usa 10% fixo |
| Moves | Até 8 + 4 hotkeys | Aprovado (R38-Q5) | Código tem 7+1/6+1/4; sem 4 principais |
| Tooltip | Texto com dano/cura numéricos | Aprovado (GDD §12.24–12.25; D-229/D-230 citadas) | Código mostra “Poder ×1,3” e “Descrição N/D” |
| Elementos | SMT, 11 categorias, afinidades por espécie | D-118/D-128 | Código tem 11 elementos, mas só fraquezas, sem resistências/imunidades |

### 8.4 Divergências entre código e documentação (fora do GDD)

- `docs/REGRAS_DO_JOGO.md` §15 lista o Gible com **7** Skills (Bite, Sand Attack, Dragon Rage, Dig, Rakunda, Mabufula, Titanomachia). O código `_new_gible` tem **4** (Bite, Sand Attack, Dragon Rage, Dig). **Documento e código divergem.**
- O GDD §12.23–12.25 cita **D-228, D-229 e D-230**; nesta árvore **não existem** esses arquivos, e **D-230** está ocupado por “Motion Composer Etapa 1”. É um problema de integridade de IDs, não uma regra.
- O GDD §8 (“estado real do repositório”) descreve um commit antigo, ATB de 0–100, cápsulas e uma batalha que não existe mais. **Está obsoleto.**
- O GDD §9 usa IDs internos (D-001, D-002...) que **não** são os IDs das decisões; isso já causou confusão em auditorias anteriores.

### 8.5 O que já está no jogo e não está no GDD (candidatos a documentar)

**No domínio do GDD (exploração/progressão/UI):**

- O **manifesto de 297 espécies usáveis** (294 Z-A + 3 Arenamon) e a regra de que todas têm sprite overworld e modelo 3D de origem. O GDD ainda diz “espécies elegíveis: pendente”.
- A **equipe inicial Abra + Pancham** (o GDD diz que a aventura começa só com o protagonista).
- O **StatusScreen** com HP/ATK/VEL/fraquezas/golpes e `N/D` para o que não existe.
- A **Poção cura 30**, os itens segurados sem efeito, o inventário compartilhado.
- O **HP persistente** entre batalhas.

**No domínio do combate (D-001: não levar para o GDD; levar para REGRAS/decisões):**

- 11 elementos, 4 formas de trajeto, 7/6/4 Moves, ATB/Burst, fraqueza 1.5×, crítico 2×/10%, esquiva automática 10%, buffs ±5, status (stun/blind/taunt/guard/burn), Guard 50% provisório, Burn 2 HP/tick, dano por passo ±10%, fórmula de dano, Media 10+MAG, `move_id` por nome, números de dano/cura.
- O **`CrawlmonAttributeMath`** (fórmulas aprovadas, não ligadas).
- O **`DqtTestParty`**, o **hub test**, a **VFX room** e os atalhos de debug (F9/F10/F11 etc.) — **não são conteúdo de jogo** e não devem entrar no GDD como regra.

### 8.6 Decisões necessárias

1. **“Tipos”** significa os **11 elementos SMT** ou **tipos Pokémon** (Fogo/Água/Planta...)? Se forem tipos Pokémon, é um sistema novo, com tabela própria; se forem elementos, confirmar os 11 e definir resistências/imunidades/afinidades.
2. **Atributos:** confirmar os **seis** (STR/MAG/VIT/SPI/AGI/LUK), sem 1–100; definir valores-base/conversão (D-270), HP/MP, nível máximo, XP, pontos por nível, curvas dos aliados e Natures.
3. **Moves:** definir custo de MP, categoria físico/mágico, precisão, alvos, efeitos, chances, duração, número de hits, descrição/tooltip e `move_id` explícito; definir os 8/4 e a troca.
4. **Informação:** onde o jogador vê os atributos, os Moves e os elementos (status screen, tooltip de combate, ficha fora de combate); o GDD deve apontar para a decisão, não duplicar números de combate.
5. **GDD vs REGRAS:** manter D-001 (GDD não normativo no combate) e corrigir o GDD só no que é exploração/progressão/UI? Ou o criador quer um GDD único, com combate incluído? Essa escolha muda o escopo da atualização.

---

## 9. Consolidado: o que está no jogo e não está no GDD

> Classificação: **GDD** = deve ser considerado para o GDD; **REGRAS** = já é/pertence a decisões e REGRAS (D-001); **DEBUG** = cena/atalho de teste, não é conteúdo de jogo.

| Item no jogo | Onde | Classe | Observação |
|---|---|---|---|
| Menu X com abas Itens/Status/Segurar | `menus.gd` | GDD (UI) | O GDD não descreve a tela |
| Inventário compartilhado, sem limite | `game_state.gd` | GDD (regra) | Contradiz R35-Q3 (10/30) |
| Poção cura 30; Amuleto/Talismã sem efeito | `item.gd` | GDD (item) | Catálogo mínimo |
| Coleta automática de Poção (2–4/andar) | `exploration.gd` | GDD (UX) | Regra já em D-033 |
| StatusScreen “vitrine” com N/D | `status_screen.gd` | GDD (UI) | Protótipo |
| Pose de vitória + 3 s + retorno direto | `battle_scene.gd` | GDD (pós-combate) | Sem tela de resultados |
| HP persiste entre batalhas | `Combatant` | GDD (regra) | Já previsto no GDD; falta MP |
| Transição “Fenda tática” 1,5 s | `transition.gd` | GDD (UX) | Só entrada; saída direta |
| Graça de 1,25 s pós-batalha | `exploration.gd` | GDD (UX) | Não documentada |
| Equipe inicial Abra + Pancham | `game_state.gd` | GDD (regra) | Contradiz R27-Q2 |
| Hotkeys 1–9 e R no combate | `battle_scene.gd` | GDD/REGRAS (UI) | Sem 4 principais/8 slots |
| Listas de Moves hardcoded | `game_state.gd` | GDD (regra) | Sem banco/aprendizado |
| NPCs 2–3/andar, 177 espécies, 18 falas | `npc_data.gd` | GDD (conteúdo) | Sem mercador/quest/recrutamento |
| NPC vira para o jogador, prompt [Z], colisão | `npc.gd` | GDD (UX) | D-313 autoriza o olhar |
| Inimigos blob, detecção 6,5/3/9 tiles | `enemy.gd` | REGRAS (IA) | Contradiz R38-Q1 e D-310/D-315 |
| Inimigo derrotado removido | `GameState.defeated` | GDD (regra) | Já previsto R9-Q4 |
| Batalha sempre Gible | `battle_scene.gd` | REGRAS (escopo) | D-319 mantém |
| DQT trio só na batalha/teste | `dqt_test_party.gd` | DEBUG | `--dqt`, `--dqt-mirror`, F11 |
| Hub test com Treasure Town | `hub_test.gd` | DEBUG | F10; não é o hub |
| 297 usáveis, 294 Z-A + 3 Arenamon | `pokedex_manifest.json` | GDD (catálogo) | GDD diz “pendente” |
| 3 GLBs de Pokémon; 3 DQT | `assets/modelos` | GDD/DEBUG | 297 têm modelo de origem, 3 importados |
| 11 elementos, 4 kinds, statuses | `element.gd`, `skill.gd`, `battle.gd` | REGRAS | D-001: não levar ao GDD |
| Fórmulas de LUK/AGI/status | `crawlmon_attribute_math.gd` | REGRAS | Não ligadas |
| Guard 50%, Burn 2/tick | `battle.gd` | REGRAS | D-272/D-238 |
| Sem save/load | todo o projeto | GDD (campanha) | Não há persistência entre sessões |

---

## 10. Proposta de atualização do GDD (para aprovação; nada foi editado)

### P0 — corrigir contradições com decisões vigentes

1. **Atributos:** trocar “cinco atributos” por **seis** (STR, MAG, VIT, SPI, AGI, LUK), citando D-130/D-131.
2. **Escala:** remover “1–100” e o “limite 1–100”; registrar que a escala foi revogada por D-269 (e D-139) e que os valores crescem com o nível, sem teto 100. Ajustar também `docs/REGRAS_DO_JOGO.md` §14.7.
3. **Nature:** retirar “Nature influencia crescimento”; D-271 limita a Nature a **atributos e formas de agir**.
4. **GDD §8:** atualizar ou remover a seção “estado real do repositório” (commit antigo, ATB 0–100, cápsulas).
5. **IDs:** reconciliar as citações **D-228/D-229/D-230** do GDD §12.23–12.25 com os arquivos reais (hoje ausentes/colidindo com Motion Composer).
6. **Gible:** corrigir a tabela de `REGRAS` §15 para os 4 Moves do código, ou decidir que o código deve ter os 7.

### P1 — adicionar o que o GDD não cobre e é regra/UX de campanha

1. **Pós-combate:** ordem resultados → XP → level up → alocação → retorno; o que aparece em cada tela; o que acontece na derrota.
2. **XP/nível:** fórmula, curva, nível máximo, divisão entre ativos, reserva/incapacitados, preservação após derrota/retirada.
3. **Alocação:** 1 ponto/nível, atributos elegíveis, obrigatoriedade, UI, pontos não distribuídos.
4. **Recompensas:** moedas/itens/recursos; lojas/mercadores; preços; inventário.
5. **Inventário:** HUD vs menu; 10/30; por Pokémon; inventário cheio; itens segurados; uso fora de combate.
6. **Moves:** 8/4; onde/como trocar; custo; conhecidos/esquecidos; Tackle; mestres/HMs/TMs; tooltip.
7. **HP/MP no overworld:** o que aparece, para quem, em que formato; o que sai do combate.
8. **NPCs/quests/recrutamento:** tipos, catálogo, persistência, condições, recompensas.
9. **Modelos 3D:** só depois de decidir a direção (2D/2.5D/3D) e revogar/substituir D-275/D-313/D-317/D-324 se for o caso.

### P2 — detalhes que podem ficar fora do GDD

- Layout do menu X, abas, fontes, ícones, `StatusScreen`.
- Nome/tempo/desenho da transição “Fenda tática”.
- 3 s de pose, 1,25 s de graça, posição exata de retorno.
- Pool de 177 NPCs, 18 falas, prompt [Z].
- Números atuais de detecção/patrulha (provisórios; D-310/D-315 os substituem).
- Hub test, DQT test, VFX room, atalhos de debug.
- Fórmulas e números de combate (D-001: vão para REGRAS/decisões, não para o GDD).

---

## 11. O que não foi verificado

- **Não executei o Godot**, não abri as cenas, não rodei testes e não capturei tela. A auditoria é de leitura.
- Não verifiquei o comportamento real do menu X, da transição, do retorno, do HUD de combate, da IA, do pathfinding, da performance ou do save.
- Não verifiquei a **viabilidade técnica/visual** de um overworld 3D; a análise de modelos é baseada em arquivos e código, não em teste.
- Não verifiquei os **297 modelos 3D** do Z-A; o manifesto diz que existem, mas só 3 GLBs de Pokémon estão no projeto.
- Não verifiquei as decisões **D-228–D-230** citadas pelo GDD: os arquivos não existem nesta árvore e D-230 colide com Motion Composer.
- Não verifiquei a `origin/main` nem o GitHub; a árvore de trabalho tem muitos arquivos modificados (ver `git status`), então o código pode estar à frente/atrás do commit.
- Não verifiquei se o GDD e a REGRAS são a versão publicada; o relatório usa a árvore local.

---

## 12. Perguntas bloqueantes (responder antes de atualizar o GDD ou implementar)

1. **Escopo do GDD:** o senhor quer que eu **só entregue esta auditoria** ou que eu **edite o GDD** com as correções P0/P1? Se sim, quais itens autoriza?
2. **Modelos 3D:** manter o overworld **2D** (D-275/D-313/D-317/D-324), fazer **2.5D** (personagens 3D sobre tiles 2D) ou **3D completo**? Os DQT entram como **personagens**, **NPCs** ou **inimigos**? Substituir **todos os 297 Pokémon** ou só o grupo ativo/NPCs?
3. **HUD de inventário:** é uma **HUD sempre visível** ou o **menu X** atual? O inventário é **compartilhado** ou **por Pokémon**? O limite **10/30** entra agora?
4. **HP/MP:** mostrar **só o líder**, **os três ativos** ou **todos**? **Remover** HP/MP do combate ou só os do jogador? A vida dos inimigos e os números de dano continuam?
5. **Pós-combate:** qual a ordem das telas e o que cada uma mostra? A derrota usa a mesma tela? O jogo terá **save**?
6. **Moves:** a troca é no **menu**, no **hub** ou com **mestre**? É livre ou tem custo? Os **4 principais** são escolhidos? Tackle ocupa slot? O Move trocado é esquecido?
7. **“Tipos”:** são os **11 elementos SMT** ou **tipos Pokémon**? Se forem tipos Pokémon, qual tabela? Se forem elementos, quais resistências/imunidades?
8. **NPCs/quests:** quais tipos entram primeiro (mercador, quest, recruta, especial)? Onde (dungeon/hub/campanha)? O que persiste entre expedições?
