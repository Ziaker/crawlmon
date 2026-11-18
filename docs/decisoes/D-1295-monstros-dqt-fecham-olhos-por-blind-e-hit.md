> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** Teste em <10 s: `--scenario=olhos_debug_dqt --stdout-trace --quit` (eventos `eyes`, `eyes_blink`).

# D-1295 — Monstros DQT fecham os olhos por BLIND e por hit (primeira tentativa)

## Frase literal do criador
> "tenta com eles"

(resposta à oferta de aplicar a recomendação da auditoria `docs/plans/AUDITORIA_OLHOS_DQT_TACT.md` aos monstros DQT, depois do "aprovo tudo" de D-1268/D-1271/D-1272.)

## Decisão (escopo desta tentativa)
- O `DqtEyes` (D-340) ganha a mesma interface do `EyeBlink` (`hold_closed`, `squeeze(s)`, `blink_now()`, `lid_k`, `blinks`) e `BattleFx` passa a achá-lo, de modo que BLIND (D-1271) e hit de 0,5 s (D-1272) valem também para os DQT que têm malha de olho fechado ligada por `<X>_scale`: **Slime, Dracky, Healslime** (dado do jogo, auditoria Tact). A pálpebra é a malha `Eye_Model_a` (adesivo de olho fechado), sem fração: aberto/fechado.
- Segunda tentativa ("sim" do criador à oferta): Orc, Cyclops e Sabrecub, que não têm malha de olho fechado mas têm ossos `*mabuta*`, seguram durante BLIND/hit a pose que o próprio clipe Sleep (`<prefixo>04`) dá a esses ossos em t=0 (translação/rotação/escala, só as trilhas que existem). Sem piscar aleatório próprio nesses (o Sabrecub já pisca no clipe). Visual: Sabrecub e Cyclops mudam nitidamente na captura; no Orc não deu para julgar.
- Fora desta tentativa: Platypunk (nós `OpenEye`/`CloseEye`) e Fungi (sem dado).
- Não muda regra de jogo, dano, tempo ou o piscar aleatório do D-340.
- Interpretação minha (pendente): "eles" = os monstros DQT que a auditoria mostrou com olho fechado por malha.

## Orc (correção, 2026-11-17)

Frase literal do criador: "o ponto do olho do orc não tá sumindo quando ele fecha os olhos".

O ponto é a malha `Eye_Model_a` (pupila). Perfil do Orc (`content/characters/dqt_orc/model_profile.tres`, chave `paint_closed_eye`, antes `hide_eye_mesh_on_close`) esconde essa malha enquanto BLIND/hit; o Sabrecub e o Cyclops não (lá a pálpebra já cobre; esconder deixou o olho branco). **Limite do dado:** o clipe Sleep do Orc quase não mexe nos ossos de pálpebra (só variações pequenas); sem a pupila, o olho fica como um branco liso, que não é um olho fechado. Fechar de verdade pediria um adesivo/pálpebra que o modelo não tem (decisão do criador).

### Orc: pálpebra desenhada (2026-11-17)

Frase literal do criador: "pode ser desenhar então, é só uma mudança de cor no geral não?"

Implementado como cor: enquanto BLIND/hit, a malha `Eye_Model_a` do Orc recebe um material liso (cor de pele iluminada, `eye_cover_color` no perfil, sem sombreamento) e o osso do olho é ampliado 2,7x para cobrir o olho branco. Valores 2,7x e cor [0,70, 0,55, 0,40] são meus e pendentes de aprovação do criador; o resultado é um disco liso sem contorno de sobrancelha/pálpebra.

### Orc: pálpebra como shader (2026-11-17)

Frases literais do criador: "volta atrás e desenha a palpebra como shader"; depois "tá grande demais".

Substitui o disco liso: enquanto BLIND/hit o Orc troca a malha do adesivo de olho por uma cópia com cada olho ampliado 1,2x em torno do próprio centro, desenhada por shader (`DqtEyes.LID_SHADER`: amêndoa de cor de pele, linha de cílios curva e leve sombra acima; fora da amêndoa é descartado). Valores técnicos meus e pendentes: 1,2x (1,5x e 2,4x ficaram grandes demais), cor `eye_cover_color`, forma da amêndoa e da linha. Aberto, a malha e o material originais voltam intactos.

### Acabamento e modelos novos (2026-11-17, técnico, sem regra nova)

Pedido do criador: "quero que faça o prompt pra um melhor acabamento pra mecanica e feature e adaptação pra novos modelos" (`docs/plans/PROMPT_OLHOS_ACABAMENTO_E_NOVOS_MODELOS.md`). Feito: `EyeStrategy.detect` (`scripts/common/eye_strategy.gd`) escolhe a estratégia só por dado (`shader_lid`, `decal`, `open_close_bones`, `bone_lids`, `none`; `paint_candidate` reportado à parte); Platypunk fecha pela pose Sleep dos ossos `OpenEye`/`CloseEye` (eram ossos, não nós; o clipe troca a posição z deles); flag do Orc renomeada `paint_closed_eye`. **Limite honesto:** não há critério de dado confiável para dizer se a pálpebra já cobre o branco do olho, então a escolha entre `bone_lids` e pintura na textura continua sendo flag no perfil; a ferramenta `diag_eye_strategy.gd` só aponta candidatos. Fungi segue sem dado (decisão do criador pendente). Valores do Orc (arco 0,2, espessura 3 px, limiar de branco) e do resto (0,5 s, ritmo do piscar) seguem pendentes de aprovação.

### Orc: pálpebra pintada na textura da cabeça (2026-11-17)

Frase literal do criador: "tá péssimo ainda, acha um outro jeito"

Substitui o shader sobre o adesivo (que aparecia como remendo): o olho branco do Orc está na textura da cabeça, então `DqtEyes` acha, por olho, o branco ao redor da pupila (vértices da cabeça mais próximos, UV, preenchimento do branco), repinta com a cor de pele medida num anel ao redor e traça uma linha de cílios curva. Uma cópia do material da cabeça com essa textura entra só enquanto BLIND/hit; a pupila fica escondida. Aberto, tudo volta ao original. Valores técnicos meus e pendentes: arco da linha (0,2 da altura), espessura (3 px), limiar de "branco".

### Aprovação dos valores (2026-11-17)

Frase literal do criador: "eu aprovo todos, pode fechar a sessão"

Aprovados os valores técnicos pendentes desta frente: arco 0,2, espessura 3 px e limiar de branco da linha do Orc, hit de 0,5 s, ritmo do piscar e a escolha por flag `paint_closed_eye`. Fungi (sem dado) e o caso de golpe absorvido por escudo (D-1272) não foram decididos por essa frase e seguem em aberto.
