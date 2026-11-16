# Composição de cenas e cutscenes das campanhas

> **Estado:** documento vivo, **começado em 2026-11-14**. Faz parte do escopo de criação de campanhas (ordem do criador). Tudo aqui é **proposta, a aprovar**, exceto o que cita decisão. Nada implementado. Quando o criador aprovar um item, vira `D-xxx` antes de qualquer código (AGENTS.md §4).

## 1. Para que serve

Definir **como uma campanha conta a sua história dentro do jogo**: quais cenas existem, de que tipo são, quem aparece, o que a câmera e a UI fazem, e como cada cena se liga ao andar da torre, ao badge e às escolhas do jogador. Cada campanha (Phantastes é a primeira) preenche uma ficha por cena segundo o §5.

## 2. O que já existe (não reinventar)

| Peça | Decisão | Resumo |
|---|---|---|
| Diálogo de NPC | D-1085, D-1087, D-1090 | Prompt `[Z] TALK`; card Paper/RPG com abertura animada, retrato em medalhão, typewriter, `[Z] NEXT`/`CLOSE`; reticências sobre o NPC que fala |
| Câmera de diálogo | D-1088, D-1092 | Dois-shot em três-quartos pela esquerda (~50°, 3,9 m, FOV 45°); movimento e câmera travados; volta suave em ~0,4 s |
| Reações dos aliados | D-1089, D-1092 | Faixas laterais com nome e retrato, só sabor, por Nature |
| Eventos com escolha | GDD §7.14–7.29 (R29-Q2, R30-Q2) | Consequências locais à expedição |
| Protagonista do livro | D-1210 | Só em momentos-chave; é neles que a equipe do jogador cruza com a rival |
| Badge ao lado do mapa | D-1210 | Andar, objetivo e onde está a próxima parte da história |
| Conteúdo de campanha | D-1210 | Pré-pronto, não procedural |
| Rivais | D-1210, D-1211 | Sem relação com a história; contato só nos momentos-chave |
| Pontos de descanso | D-311 | Já existem como conceito |

## 3. Lacunas e conflitos que o documento precisa resolver

1. **Idioma das falas.** D-1085 diz que falas de NPC ficam em **português** (exceção a D-413), e D-1210 anota "texto em inglês (D-413)". Nas notas de tradução eu tratei como inglês. **Qual vale para a campanha?**
2. **Tudo que existe é diálogo com NPC parado.** Não há decisão para cena sem NPC (narração, cena do portal, cenas com a Sombra, chegada ao palácio) nem para cena com o protagonista do livro.
3. **Câmera dos momentos-chave.** O dois-shot de D-1088 é jogador + NPC; um encontro com a equipe rival ou uma cena com vários personagens precisa de outro enquadramento.
4. **Como a escolha aparece.** O card atual não tem escolhas (D-1087, "sem escolhas nesta rodada").
5. **Cena e andar.** Cada andar é um nível da torre (D-1210); falta dizer onde, dentro do andar, cada cena dispara.
6. **Modelos disponíveis.** Só modelos Z-A (D-1211). Personagens sem modelo (Beech, Alder, família da fazenda, ogra) não têm cena possível até haver escolha.

## 4. Tipos de cena (proposta)

| Tipo | Quando | Exemplo em Phantastes |
|---|---|---|
| **Abertura/entrada** | Início da campanha ou de um andar | O quarto virando floresta |
| **Conversa** | Com um NPC, no sistema de diálogo existente | A mulher da cabana; a mulher da fazenda |
| **Momento-chave** | A história avança; protagonista do livro presente; contato com a equipe rival (D-1210) | O Ash tentando enterrar Anodos |
| **Evento com escolha** | O jogador decide; consequência local (R29-Q2) | Abrir ou não o armário da ogra |
| **Encontro narrativo** | Combate que a cena inicia ou conclui | Ash; goblins |
| **Descanso** | Ponto seguro (D-311) | A fazenda |
| **Fecho de andar** | Passagem ao próximo andar; atualiza o badge | Chegada ao palácio |

## 4b. Câmera e faixas pretas de cutscene (ideia do criador, a detalhar)

**Frase do criador (2026-11-14):** "pensou também nos angulos de câmera, as faixas pretas nas regiões superiores e inferiores pra indicar cutscenes? as falas ?"

**Faixas pretas (letterbox):** barras no topo e na base da tela que entram quando uma cena começa e saem quando termina, para o jogador reconhecer "agora é cena". Nada definido: espessura, animação de entrada e saída, se cobrem só a tela de jogo ou também o HUD, se valem para todo tipo de cena (§4) ou só para os momentos-chave e aberturas. O diálogo comum de NPC (D-1088) já tem câmera própria sem faixas; falta decidir se continua assim.

**Ângulos de câmera (catálogo proposto, sem valores):**
- **Dois-shot** (existe, D-1088/D-1092): jogador + NPC, três-quartos pela esquerda.
- **Plano aberto do ambiente:** mostra o castelo/andar inteiro (D-1210: visualmente não é uma dungeon); serve às cenas de abertura e de chegada.
- **Plano de grupo:** equipe do jogador contra a equipe rival, nos momentos-chave.
- **Plano de personagem** (close): quem fala ou reage, para o Ash se anunciando, a Sombra, a Dama de Mármore.
- **Câmera de ameaça:** a sombra da mão antes do Ash aparecer; câmera baixa ou parcial, sem mostrar o personagem.
- **Câmera fixa ou em trilho** para cenas sem controle do jogador.

**Regras que já valem:** câmera não atravessa paredes (D-1023); movimento e giro travados durante a cena (D-1088); D-235 (nada por personagem ou por lado: o enquadramento sai das posições reais).

**Em aberto:** quais ângulos entram, valores (distância, altura, FOV, duração), se o jogador pode pular, e como a câmera volta ao controle.

## 4c. Falas (roteiro)

**O que já existe:** o card de diálogo (D-1090) mostra nome, retrato, texto com typewriter e `[Z] NEXT`; sem escolhas e sem som (D-1087); faixas laterais de reação dos aliados (D-1089/D-1092).

**O que falta definir (nada escrito ainda):**
- **Formato do roteiro por cena:** quem fala, texto, retrato/expressão, pausas.
- **Narração:** Phantastes é narrado em primeira pessoa por Anodos; como o livro vira fala (narrador, card sem retrato, ou só cena sem texto).
- **Tamanho:** limite de linhas por card para caber (D-1090) e por cena.
- **Tom por personagem:** Ash, Sombra e Alder precisam de vozes distintas; quem não tem modelo só existe como texto.
- **Escolhas:** como aparecem no card (ver §7.5).
- **Idioma:** conflito D-1085 × D-1210 (§3.1).
- **Quem escreve:** os textos do livro são domínio público, mas a adaptação é nova; cada fala nova é aprovada por você antes de entrar.

**Proposta de ordem:** primeiro a cena piloto 1 (Abertura) e a 3 (Ash), com roteiro curto, para você ler e corrigir o tom antes de escrever as demais.

## 5. Ficha de cena (modelo)

- **ID e título**; **campanha**; **andar** da torre e **ponto** do andar onde dispara.
- **Origem no livro** (capítulo) e o que muda para o jogo.
- **Tipo** (§4) e **gatilho** (entrar na sala, interagir, vencer um encontro, escolha anterior).
- **Personagens** em cena (modelos aprovados) e **quem fala**; protagonista presente: sim/não (D-1210).
- **Equipe rival presente:** sim/não.
- **Câmera:** ângulo (§4b), faixas pretas sim/não, travas de controle, duração.
- **Roteiro:** lista de falas (§4c): quem fala, texto, retrato, pausa.
- **Texto:** falas (idioma conforme §3.1), retratos, tom.
- **Escolhas** e **consequências** (só locais à expedição).
- **Efeito no badge** (objetivo e próxima parte da história) e no **Respeito**, se houver.
- **Combate** ligado à cena, se houver (inimigos, ameaça D-310).
- **Pulável / repetível**, e o que acontece ao repetir a campanha.
- **Debug:** cenário em `vfx_room` ou equivalente para testar a cena em menos de 10 s (D-1204).

## 6. Inventário de cenas candidatas de Phantastes (capítulos 1 a 10)

Todas são **candidatas**, tiradas do texto; o tipo é proposta. Não há ficha preenchida ainda.

| # | Cap. | Cena | Tipo proposto | Personagens (aprovados) |
|---|---|---|---|---|
| 1 | 1–2 | Fada da escrivaninha promete o caminho; o quarto vira floresta | Abertura | Froslass (D-1213) |
| 2 | 3 | A moça da cabana avisa quem evitar (Ash, Alder); quatro carvalhos | Conversa + Descanso | sem modelo |
| 3 | 4 | O Ash se anuncia (medo, sombra da mão), persegue; a Beech salva | Momento-chave | Zinmenju (Ash) |
| 4 | 5 | Anodos acorda a Dama de Mármore cantando; ela foge | Evento + perseguição | Golurk |
| 5 | 6 | O Cavaleiro Enferrujado avisa sobre a Alder | Conversa | Restless Armour |
| 6 | 6 | A gruta da Alder; o Ash vem; golpes de machado o afastam | Momento-chave (Exemplo B) | Zinmenju; Restless Armour; Alder sem modelo |
| 7 | 7 | A fazenda: explicação das regras de Fairy Land | Descanso + Conversa | sem modelo |
| 8 | 8 | O armário proibido; a Sombra encontra Anodos | Evento com escolha | Gastly |
| 9 | 9 | Efeitos da Sombra (flores, criança, desconfiança do cavaleiro) | Eventos | Gastly; Restless Armour |
| 10 | 9 | A moça do globo | Evento com escolha | sem modelo |
| 11 | 9 | A aldeia onde os rostos mudam com a distância | Evento | sem modelo |
| 12 | 10 | Goblins no deserto: hostis até verem a Sombra | Encontro narrativo (evitável) | Gremlin, Lilliput |
| 13 | 10 | O barco no rio e a chegada ao palácio | Fecho de andar | nenhum |

## 7. Perguntas em aberto (uma decisão por item; recomendação minha ao lado)

1. **Idioma das falas da campanha:** português (como D-1085) ou inglês (como D-1210)? *Recomendação:* português nas falas, UI em inglês, como D-1085, para ficar coerente com o que já existe.
2. **O jogador controla algo durante as cenas?** *Recomendação:* travado, como em D-1088, com opção de pular.
3. **Cenas sem NPC** (narração, portal, Sombra): usar o mesmo card Paper sem retrato, ou outro formato? *Recomendação:* reutilizar o card, com retrato neutro (como já faz D-1090 para NPC sem retrato), até haver outra direção.
4. **Momento-chave com a equipe rival:** enquadramento e quem fala. *Recomendação:* só depois de fechar o §3.3; não decidir ainda.
5. **Escolhas no card:** formato e botões. *Recomendação:* levar ao lab de diálogo (como foi com D-1087), três opções para você escolher.
6. **Disparo da cena dentro do andar:** por sala, por item, ou ao vencer encontro? *Recomendação:* ligar ao objetivo do badge, para o jogador sempre saber onde está o próximo ponto.
7. **Cenas repetíveis e puláveis** em replay. *Recomendação:* puláveis a partir da segunda vez.
8. **[APROVADO, D-1214] Faixas pretas:** em todas as cenas ou só nos momentos-chave e aberturas? *Recomendação:* só momentos-chave, aberturas e fechos de andar; o diálogo comum de NPC fica sem faixas, como já é.
9. **[APROVADO, D-1214] Catálogo de ângulos (§4b):** quais entram. *Recomendação:* começar com dois-shot (existe), plano aberto e plano de grupo; os outros só se uma cena pedir.
10. **[APROVADO, D-1214] Narração de Anodos:** como vira fala. *Recomendação:* card sem retrato, em itálico, só nas aberturas e fechos.
11. **Personagens sem modelo:** quais entram só como voz/texto e quais ganham modelo Z-A.

## 8. Próximos passos propostos

- O criador responde o §7 (um item por vez).
- Preencher a ficha do §5 para as cenas 1, 3 e 6 (Abertura, Ash, Exemplo B) como piloto.
- Só depois levar ao lab de diálogo o que for visual (UI de escolha, enquadramento).
