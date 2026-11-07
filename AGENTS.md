# Regras obrigatórias para qualquer agente neste projeto

**Leia isto e `docs/decisoes/` ANTES de qualquer tarefa. Sempre. Sem exceção. Mesmo que a tarefa pareça pequena ou não relacionada.**

## 1. Ler as decisões do criador (sempre)

1. Abra `docs/decisoes/README.md` e **todos** os arquivos `docs/decisoes/D-*.md`. Cada arquivo é uma decisão do criador, com a frase literal dele.
2. Comece a resposta citando os IDs que se aplicam (ex.: "Decisões aplicáveis: D-006, D-007") ou escreva "nenhuma decisão se aplica". Isso prova que você leu.
3. Também leia `docs/REGRAS_DO_JOGO.md` antes de mexer em combate. **O GDD (`docs/GDD.md`) é ignorado no combate** (D-001).
4. Se o código contradiz uma decisão, a decisão vale. Diga a divergência; não "conserte" por conta própria sem pedir.

## 2. Ambiguidade = perguntar

- Se qualquer parte do pedido puder ser entendida de mais de um jeito (o que muda, onde, quando, em que caso), **pergunte antes de mexer em qualquer coisa**.
- Não preencha lacunas com palpite, "padrão sensato" ou exemplo inventado. Não ofereça "meu padrão" para decidir por ele.
- Não repita pergunta que o criador já respondeu: releia a conversa e `docs/decisoes/`.

## 3. Fazer só o que foi pedido

- Nada de mudar regra, tempo, visual, ordem de eventos ou comportamento que ele não pediu.
- **Refatorar = comportamento idêntico.** "Auditoria", "proponha", "corrija" **não** autorizam mudar regra de jogo.
- Sim a um plano grande **não** autoriza as escolhas de detalhe dentro dele: pergunte cada detalhe ambíguo.
- Se um teste ou detector sinaliza algo, **pergunte** se o jogo ou o teste está errado; não altere o jogo para o teste passar.

## 4. Novas decisões

- Quando o criador definir uma regra, **crie `docs/decisoes/D-xxx-*.md` antes de escrever código** (frase literal, decisão, ambiguidades, estado). Atualize o índice.
- **Após cada rodada de respostas, registre imediatamente as decisões aprovadas em documentos individuais, atualize o índice e `docs/REGRAS_DO_JOGO.md` no GitHub ANTES de abrir outra rodada**, conforme D-061. Isso é atualização documental, não autorização para alterar o código. Se o criador proibir expressamente atualizar a documentação, respeite e informe o que não foi publicado.
- Se duas decisões se contradizem, preserve as duas e pergunte qual vale.

## 5. Git

- **Nada de `push` sem autorização expressa.** Não commite o que não é seu: outras sessões editam os mesmos arquivos. Confira `git branch --show-current` e `git status` antes de commitar/enviar e diga o que será enviado.
- Commits terminam com a linha de coautoria. `assets/modelos/` nunca vai ao Git.

## 6. Antes de dizer "pronto"

Releia as decisões aplicáveis e confirme, uma a uma, que nenhuma foi violada. Diga o que **não** foi verificado.

## 7. Moves e efeitos são independentes de personagem, de lado e de posição (OBRIGATÓRIO, inclusive em protótipos)

Fonte: D-235. Esta regra vale para **qualquer** trabalho com Moves, VFX, animação, câmera, UI e testes, e também para protótipos, laboratórios e salas de debug.

1. **Todo Move pode ser usado por qualquer personagem**, de qualquer time (aliado ou inimigo), em qualquer lado do campo (perto ou longe da câmera) e contra qualquer alvo. O mesmo Move equipado em dois personagens tem de funcionar igual. Não existe "move de um personagem só".
2. **Nada pode depender de um personagem, de um time ou de um lado**: nome, espécie, modelo, `is_player`, "o jogador fica aqui e o inimigo ali", direção fixa da câmera, posições ou coordenadas fixas (inclusive as de protótipos HTML) são proibidos. Derive tudo do atacante e do alvo reais: eixo atacante→alvo, altura, raio e centro medidos do modelo, distância e escala da câmera.
3. **O comportamento é por `move_id`**, nunca por personagem. Nomes e arquivos com o nome de um personagem (por exemplo "Abra") são só rótulos históricos.
4. **O inimigo distante também usa o mesmo Move** e o efeito tem de aparecer certo do lado dele, com o alvo perto da câmera ou longe dela.
5. **Antes de dizer "pronto"**, teste o Move com: (a) outro atacante que o tenha ou possa tê-lo, (b) o lado espelhado (atacante inimigo e distante, alvo aliado e próximo), (c) alvos de tamanhos diferentes. Diga o que **não** foi testado.

## 8. VFX de Move/elemento em combate: protocolo obrigatório (D-308)

**Antes de qualquer VFX de Move/elemento em combate, por menor que seja, leia e siga `docs/vfx/PROTOCOLO_VFX_OBRIGATORIO.md`.** Em resumo: (1) cite as decisões aplicáveis e leia os protótipos HTML e a especificação do Motion Composer; (2) carregue com a ferramenta Skill `scenario-godot-vfx` e `scenario-godot-shaders`; (3) todo VFX de Move é construído **sobre o Motion Composer** (`MotionEffect` + `MotionPresets` + representações), e se ele não der conta, **atualize o Motion Composer primeiro** (V1.1, V1.2, sem limite de versões), nunca contorne com código à mão; (4) quatro fases (Wind-up, Release, Trajeto, Impacto) com transição contínua; (5) checklist literal das frases do criador, verificado em **quadros em tamanho real, nas duas vistas (normal e espelhada)**, procurando também o que não deveria existir; (6) entregue **um vídeo com as duas vistas** e diga o que não foi verificado; (7) um ajuste por vez, esperando aprovação. Quando o criador disser que está ruim: não remende, ache a causa com dados.

**Clima/exploração não é Move:** névoa, calor ondulado, chuva/neve e distorção temporal são camadas 2D de ambiente e ficam **fora** deste protocolo e do Motion Composer (D-383).

