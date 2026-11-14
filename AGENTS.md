<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# Regras obrigatórias para qualquer agente neste projeto

**Leia isto e `docs/decisoes/` ANTES de qualquer tarefa. Sempre. Sem exceção. Mesmo que a tarefa pareça pequena ou não relacionada.**

## 1. Ler as decisões do criador (sempre)

1. Abra `docs/decisoes/README.md` e **todos** os arquivos `docs/decisoes/D-*.md`. Cada arquivo é uma decisão do criador, com a frase literal dele.
2. Comece a resposta citando os IDs que se aplicam (ex.: "Decisões aplicáveis: D-006, D-007") ou escreva "nenhuma decisão se aplica". Isso prova que você leu. Se a tarefa for de combate/debug/VFX, cite também **D-1154** e diga explicitamente que leu **`docs/TELEMETRIA.md`**.
3. Também leia `docs/REGRAS_DO_JOGO.md` e **`docs/TELEMETRIA.md`** antes de mexer em combate, fila, pausa de status ou debug. **O GDD (`docs/GDD.md`) é ignorado no combate** (D-001).
4. Se o código contradiz uma decisão, a decisão vale. Diga a divergência; não "conserte" por conta própria sem pedir.

## 2. Ambiguidade = perguntar

- Se qualquer parte do pedido puder ser entendida de mais de um jeito (o que muda, onde, quando, em que caso), **pergunte antes de mexer em qualquer coisa**.
- Não apresente palpite como se fosse fato nem exemplo inventado como se fosse dele. **Mas a IA pode e deve recomendar:** dê a sua recomendação de forma clara (rotulada "recomendação"), com o porquê e as alternativas, e o criador decide.
- Não repita pergunta que o criador já respondeu: releia a conversa e `docs/decisoes/`.
- **O criador decide** regras do jogo, valores de balanceamento, visual (cor, forma, movimento, tempo), nomes de Moves/personagens e escopo. Nesses pontos a IA **recomenda, mas não implementa** até ele dizer "sim" àquela escolha. Recomendar é bem-vindo; decidir sozinha, não.
- **Detalhes técnicos podem ser decididos pela IA**, desde que não mudem regra nem o que o jogador vê: nome de variável, organização do código, ordem de funções, como testar, ferramentas de apoio. Nesses casos, escolha o mais simples e **diga o que escolheu**, para ele poder mudar.
- **Perguntas em bloco são permitidas** se cada item for numerado e separado, com a recomendação da IA ao lado. O "sim" só vale para o item a que ele respondeu: o que ele não respondeu **continua em aberto** e não entra em código, briefing, protótipo nem documento como decidido.
- Valor ou escolha de regra/visual que não veio das palavras dele fica "pendente" até ele aprovar. Na frase literal de uma decisão vão só as palavras dele, nunca um resumo meu.

## 3. Fazer só o que foi pedido

- Nada de mudar regra, tempo, visual, ordem de eventos ou comportamento que ele não pediu.
- **Refatorar = comportamento idêntico.** "Auditoria", "proponha", "corrija" **não** autorizam mudar regra de jogo.
- Sim a um plano grande **não** autoriza as escolhas de detalhe dentro dele: pergunte cada detalhe ambíguo.
- Se um teste ou detector sinaliza algo, **pergunte** se o jogo ou o teste está errado; não altere o jogo para o teste passar.
- **NUNCA mande outra IA (deepseek-code, subagente, outra sessão) fazer algo que o criador não pediu.** Delegar é só para o que ele pediu, e o briefing **não pode conter escolhas que ele não fez** (visual, cores, forma, movimento, valores, alvo, custo, escopo). Se faltar definição, **pergunte ao criador antes de delegar**. Ordem do criador "não mexe em nada" vale também para quem você delegou.

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

**Antes de qualquer VFX de Move/elemento em combate, por menor que seja, leia e siga `docs/vfx/PROTOCOLO_VFX_OBRIGATORIO.md`.** Em resumo: (1) cite as decisões aplicáveis e leia os protótipos HTML e a especificação do Motion Composer; (2) carregue com a ferramenta Skill `scenario-godot-vfx` e `scenario-godot-shaders`; (3) o Motion Composer é **auxiliar e opcional** (D-1030): use-o quando ajudar no movimento secundário/timing, mas **não é obrigatório nem gate**; o efeito principal pode ser feito à mão com animação, malhas, flipbooks, shaders, partículas e câmera; (4) quatro fases (Wind-up, Release, Trajeto, Impacto) com transição contínua; (5) checklist literal das frases do criador, verificado em **quadros em tamanho real, nas duas vistas (normal e espelhada)**, procurando também o que não deveria existir; (6) entregue **um vídeo com as duas vistas** e diga o que não foi verificado; (7) um ajuste por vez, esperando aprovação. Quando o criador disser que está ruim: não remende, ache a causa com dados.

**Clima/exploração não é Move:** névoa, calor ondulado, chuva/neve e distorção temporal são camadas 2D de ambiente e ficam **fora** deste protocolo e do Motion Composer (D-383).

## 9. Suíte de debug de combate, testes e análise de VFX para agentes de IA (D-1042, D-1044)

Sempre que trabalhar com combate, Moves, dano, animações, regras ou efeitos visuais, use a suíte de testes, telemetria e análise visual da sala de combate e debug (`scenes/debug/vfx_room.tscn`, `scripts/debug/vfx_room.gd`, `scripts/combat/battle_debug.gd`, `scripts/combat/battle_trace.gd` e `tests/battle/run_agent_combat_tests.py`):

1. **Cenários de Dano e Reação:** para testar reação de hit, animação `damage`, flash, ARMOR, STUN, Guard, textos flutuantes e lançamento balístico de K.O., use os cenários do grupo "Dano e Reação" (`--scenario=dano_direto`, `dano_critico`, `dano_weak`, `dano_armor`, `dano_stun`, `dano_guard`, `dano_ko`) ou os atalhos `F9` (dano com reação) e `F10` (K.O. com lançamento) no `BattleDebug`.
2. **Fases de Move e Ficha Visual (`Skill.visual_phases()`):** para inspecionar e congelar cada fase de qualquer Move conforme sua ficha de descrição visual e D-308, use `--phase=windup|release|travel|strike|impact|return`, `--isolate-phase=<fase>` (que imprime e exibe a `FICHA_FASE` do Move) ou os cenários `fase_windup`, `fase_release`, `fase_trajeto`, `fase_golpe`, `fase_impacto`, `fase_retorno` combinados com `--move="<Nome>"`.
3. **Telemetria Estruturada, Determinismo e Invariantes:** leia **`docs/TELEMETRIA.md`** antes de usar; use `--summary-json` e `--stdout-trace` para obter saída JSONL/JSON limpa no `stdout` (sem adivinhar pelo log), `--strict-asserts` para falhar imediatamente (exit code 1) em qualquer anomalia de `BattleTrace`, `--acts-ticks=` / `--step-ticks=N` para agendamento determinístico por quadro físico, e `Battle.save_state()` / `restore_state()` para testes de ramificação.
4. **Análise Visual de VFX (10 Ferramentas D-1044):** ao criar, auditar ou depurar VFX, utilize:
   - `--audit-leaks` (detector automático de restos, nós órfãos e luzes esquecidas pós-retorno: exige `leaks=0`);
   - `--scale-overlay` (reticulado 2D em pixels 50/100/200px e régua métrica 3D 1,2 m D-1013 / 2,5 m D-1033);
   - `--proof-sheet=caminho.png` (folha de prova automática 2×4 Normal + Espelhada nas 4 fases D-308);
   - `--bone-probe` (vetor velocidade 3D de mão/arma e sincronia de pico no golpe);
   - `--solo-node=<padrão>` / `--mute-node=<padrão>` (isolamento individual de nós de `BattleFx`);
   - `--cam=macro` / `--cam=5` (câmera teleobjetiva FOV 15° a 5% de velocidade no ponto de impacto);
   - `--overdraw` (mapa de calor de densidade de transparência/aditivo);
   - `--bg=arena|gray|black|white` (teste de silhueta e contraste em fundos neutros);
   - `--envelope-graph` (curva de opacidade em tempo real e detector de cortes secos `[POP_DETECTED]`);
   - `--diff-with=referencia.png` (comparador visual A/B com imagem de diff magenta e RMSE).
5. **Simetria D-235 e Execução Headless:** teste sempre nas duas vistas (normal e `--mirror`), com diferentes atacantes e tamanhos de alvo, usando `python tests/battle/run_agent_combat_tests.py` (incluindo `--test-d235` e `--test-all-moves-matrix`).
6. **Controles de ATB no debug (D-1070):** para montar situações de ATB sem esperar o relógio (ATB cheio acelera a recuperação de MP em 1,75x; ATB cheio, zerado, +1 e -1 bloco), use no painel F1 do `BattleDebug`: `]` soma 1 bloco, `[` tira 1, `Shift+]` deixa cheio, `Shift+[` zera (no lutador escolhido com `Tab`; `F2` continua enchendo o ATB de todos). Na sala de VFX, a grade de status tem os botões "ATB +1", "ATB -1", "ATB cheio" e "ATB zerado". Antes de testar recuperação de MP, regenere o ATB para os 5 blocos ou o 1,75x não se aplica.
7. **Catálogo completo e aba "Análise VFX" da sala (D-1042, D-1044):** a sala de VFX carrega **todos** os Moves do jogo (`Skill.all_catalog_skills()`, ligado por `_seed_full_catalog()`), então qualquer Move pode ser testado com qualquer atacante e em qualquer lado (D-235): não dependa de quem foi sorteado na sessão. As ferramentas do item 4 também ficam na aba **"Análise VFX"** da sala (solo/mute de nós, sobreposições, folha de prova, comparador A/B). O estado de uma batalha pode ser salvo e restaurado com `Battle.save_state()` / `restore_state()` para repetir um mesmo instante.

## 10. Telemetria do jogo (OBRIGATÓRIO — D-1154)

**Antes de qualquer tarefa de combate, Moves, dano, animação, regra, fila, pausa de status, VFX ou debug, leia `docs/TELEMETRIA.md`.** Não é opcional e não vale “já sei como funciona”.

1. **Diga que leu:** comece a resposta citando **D-1154** junto com as demais decisões aplicáveis.
2. **Use o dado, não o olho:** `--stdout-trace` para eventos, `--summary-json` para a sala, `--strict-asserts` para invariantes. Se o dado existir, não substitua por “parece que”.
3. **Fila D-161:** em eventos `queue`, `started: true` significa que o Move **começou**; `lost` significa que foi **descartado**. Nunca confunda os dois. A pausa D-031/D-1150 não limpa a vaga; hit/War Cry real pode limpar (D-064/D-161).
4. **Evento novo:** se precisar de telemetria que não existe, registre a decisão e documente o campo em `docs/TELEMETRIA.md` antes de usar.
5. **Evidência:** entregue comando, JSON/arquivo:linha, o que foi verificado e o que não foi. Se um detector acusar anomalia, diga se o jogo ou o teste está errado; não mude a regra para o teste passar.
6. **Escopo atual:** combate. Overworld/exploração/áudio/UI fora do combate ainda não têm `GameTrace`; se a tarefa for lá, diga que a telemetria é limitada e proponha a camada separada.
