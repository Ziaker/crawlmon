<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1227 — Move Sketch: alinhamento, animações de bloco e telemetria completa

- **Data:** 2026-11-15. **Relacionadas:** D-1221, D-1226 (Move Sketch), D-1218 (dados antes de imagens), D-235.

## Frase literal do criador

> "incrivel, adicione mais opções de alinhamento, para com o jogador, para com o oponente, animações de giro, rotação e outros tipos de animação pros blocos"

> "e faça questão de criar um sistema de telemetria completo para que você também consiga editar as coisas"

## Decisão

- Cada bloco ganha "Olhar para": nada, direção da linha, o jogador, o oponente, a câmera (eixo X ou Z).
- Cada bloco aceita várias animações: giro, balanço, pulsar, quicar, flutuar, tremer, orbitar, surgir, sumir.
- Telemetria completa no app (`TEL`): estado, eventos, amostragem por tempo e comandos de edição, mais um gadget "Telemetria".

## Escolhas da IA (sem "sim" do criador)

Lista de animações, intensidades e repetições padrão, nomes dos comandos e o formato do estado. Sem piscada de tela: nenhuma animação alterna opacidade rápido (D-418).

## Estado

Implementada no protótipo; nada no Godot. Doc da telemetria: `prototypes/move_sketch/TELEMETRIA.md`.

## Adendo: gadget Camadas (pedido do criador: "sistema de camadas pra que fique mais facil selecionar algo")
- Gadget "Camadas" lista Formas e Traços: selecionar, ocultar (◉/○), travar (■/□), renomear (duplo clique), reordenar (▲▼), apagar, buscar e "Isolar" (mostra só o selecionado). Alt+clique na cena seleciona um traço.
- Escolhas da IA, pendentes de aprovação: ocultar/isolar afeta só a visão (não muda export nem movimento); travada = não seleciona na cena, não apaga, não renomeia; ▲▼ de traços troca ordem dentro da mesma célula (muda a concatenação do caminho).
- Telemetria: `layer.list`, `layer.set`, `layer.select`, `layer.move`, `layer.iso`, `stroke.del`. Traços agora têm `id`, `name`, `hid`, `lock` (salvos e no histórico).

## Adendo: alinhamento de posição (pedido: "ao redor do oponente/jogador/outra forma, acima, abaixo, no meio e outros")
- Campo `pl` por forma: `to` = player | opponent | between (meio entre os dois) | shape:ID; `at` = center, above, below, feet, front (lado voltado ao outro lutador), behind, side+, side-, around (órbita: raio, voltas, ângulo inicial, plano y/z/x); `gap` = distância extra. A posição do gizmo vira deslocamento a partir desse ponto (soma com "Seguir trilha").
- Exportado em `align_to` (+ `pos_is_offset:true`) e no briefing; telemetria: `shape.add/shape.set {pl:{...}}`, `state.shapes[].align_to`.
- Escolhas da IA pendentes de aprovação: tamanho do alvo (jogador/oponente = altura 1,6, raio 0,35; formas usam a escala), margem = metade do tamanho da própria forma, órbita com velocidade constante, laços entre formas (A segue B, B segue A) não dão erro e são cortados em 3 níveis.

## Adendo: copiar posição X/Y/Z de outra pose
- Em Ajustes da forma, "Copiar posição X Y Z de outra pose": origem = a outra pose da própria forma, ou início/fim de outra forma; escolhe-se quais eixos (X, Y, Z) copiar e o destino é a pose ativa (início ou fim). Copia a posição no mundo e desconta a âncora da própria forma (trilha/alinhamento), então o resultado continua correto em formas relativas.
- Telemetria: `shape.copypos{id,to,from:{id?,key},axes}`. Interpretação da IA de "outra pose" (a confirmar): início↔fim da mesma forma e pose de outra forma.

## Adendo: afinação de modelos (pedido: "transformar uma coroa em uma ponta de lança")
- Por pose (início/fim) cada forma tem `m` = {tip, pw, base, bulge, flat, twist, bend} e por forma o eixo `dax` (x|y|z): afinar a ponta (1 = vira um ponto), curvatura da ponta, afinar a base, barriga, achatar (lâmina; achata o eixo seguinte ao seguinte do principal: com Y, o X), torcer, curvar. Início e fim diferentes = a forma se transforma durante a duração dela (morph). Os vértices são deformados em tempo real; cópias de rastro e partes compartilham a geometria.
- Botões: Zerar afinação, Igualar à outra pose, "Proposta: ponta de lança" (tip 1, pw 1,6, flat 0,65: valor de trabalho da IA, não decidido pelo criador).
- Export em `deform:{axis,start,end}` e briefing; telemetria: `shape.set{k0:{m},k1:{m},dax}` e `state.shapes[].deform`.
- Verificado por dados: crown3d com fim tip=1/flat=.65: extensão do topo 0,462 → 0,156 (meio) → 0 (fim). Não verificado: aparência/qualidade visual, normais e arestas em formas muito deformadas, interação com Partes.

## Adendo: subtabs, regras de intervalo, mais animações e configurações
- **Subtabs:** gadget Formas = Criar | Lista. Ajustes da forma = Forma | Tempo | Posição | Olhar | Modelo | Animações | Partes (a aba escolhida é lembrada na sessão).
- **Regras de intervalo por animação:** onde começa e termina (em % da duração da forma OU por fases do Move: início da fase X até o fim da fase Y), curva (linear, suave, acelera, desacelera, acelera/desacelera, recuo e pulo, quica) e "suavizar entrada e saída" (rampa). Animações acumulativas (giro, crescer, deslizar, surgir, sumir) mantêm o valor final depois do fim do intervalo. O app mostra "ativa de X ms a Y ms"; o export traz `active_ms`.
- **Intervalo do movimento** (pose início→fim) e **intervalo próprio da afinação** (`iv`, `mi`): % inicial/final e curva.
- **Novas animações (17 no total):** alongar, esmagar e esticar, crescer, deslizar, balançar para o lado, espiral, inclinar e voltar, vibrar a rotação (+ as 9 anteriores). Alongar/esmagar preservam volume (opcional).
- **Afinação extra:** alongar o modelo, inclinar/cisalhar, ondular (amplitude e quantidade).
- **Cor e brilho:** cor do fim (a cor muda do início ao fim) e brilho emissivo início/fim.
- Telemetria: `shape.anim{...,t0,t1,ease,ramp,by,p0,p1,vol}`, `shape.set{iv,mi,color1,g0,g1}`, `state.shapes[].anims_cfg`. Tudo isto é proposta da IA (nomes, faixas e padrões) pendente de aprovação.

## Adendo: Shift trava o arraste da alça de mover
- Segurando Shift ao arrastar a alça de mover (translate), o deslocamento na tela é travado em passos de 45° (horizontal, vertical ou diagonal exata) a partir do ponto onde o arraste começou. Alças de um eixo só (setas) já são travadas e não mudam. Passo de 45° é escolha da IA (pendente).

## Adendo: exportar uma forma específica
- Gadget Exportar ganhou o seletor de escopo (Move inteiro | Só a forma X) e o botão "Exportar esta forma (todos os parâmetros)" em Ajustes da forma (aba Forma). Em Briefing, JSON e GDScript saem `SHAPE`/`shape` (valores normalizados: x 0 atacante→1 alvo, y em alturas do personagem) e `RAW`/`raw` (tudo como guardado: tipo, lados, parâmetros, cor, poses início/fim com posição/rotação/escala/divisão/afinação, alinhamento, olhar, animações com intervalos, curvas, cor do fim, brilho, rastro, partes, intervalos), com os padrões preenchidos, mais as fases do Move para interpretar `from/to`. Download: `<move>_forma<id>.<ext>`.
- Telemetria: `export{id,format:json|gd|brief}`.

## Adendo: eixos rotulados (pedido: "não sei o que leva pra frente, pra cima e pros lados")
- Com uma forma selecionada, eixos guia coloridos atravessam a forma, sempre por cima de tudo, com rótulos: +X FRENTE (→ alvo) / −X ATRÁS (vermelho), +Y CIMA / −Y BAIXO (verde), +Z LADO / −Z LADO (azul). As alças de mover/girar/escalar também passam a desenhar por cima das formas.
- Tríade no canto direito: para a câmera atual, mostra para onde apontam FRENTE, CIMA e LADO (indica "p/ câmera" ou "afasta" quando o eixo aponta para dentro da tela). H esconde.

## Adendo: tempo da separação de partes (início e fim)
- Aba Partes, "Tempo da separação": começa/termina de separar (% da duração da forma), curva, **atraso entre partes para iniciar** (a última parte começa X% do intervalo depois da 1ª) e **atraso entre partes para finalizar** (a 1ª termina X% do intervalo antes da última). Sem tempo próprio, o comportamento anterior continua igual (separa junto com o movimento da forma). Export em `parts.timing`. Valores e nomes são propostas da IA.

## Adendo: animações "UMA vez e fica" (correção pedida pelo criador)
- Problema: pulsar, alongar, esmagar, balançar, flutuar, quicar, deslizar para o lado e inclinar usavam seno, então 1 repetição ia e VOLTAVA. Agora essas animações têm "Comportamento": **vai UMA vez e fica no valor final (sem voltar)** ou **vai e volta (repete N vezes)**. Sem modo salvo: 1 repetição = vai e fica; mais de 1 = oscila (formas antigas com 1 repetição mudam de comportamento, por pedido do criador). Novas animações desses tipos nascem em "vai e fica"; a intensidade negativa encolhe. Após o fim do intervalo mantém o valor final. Telemetria: `shape.anim{mode:hold|osc}`.

## Adendo: esticar em uma direção (frente, cima, lado)
- Animação "Esticar" agora tem **Direção**: pelos dois lados (centro fixo) ou para uma direção (+ ou −) com uma ponta parada e a outra avançando; eixos rotulados (X frente/trás, Y cima/baixo, Z lados). Atalhos em "Adicionar animação": Esticar para frente/trás/cima/baixo/lado/outro lado e pelos dois lados (padrão dos atalhos: vai UMA vez e fica, sem preservar volume). O eixo é o eixo local da forma (gira junto com a forma). Esmagar usa a mesma direção. Telemetria: `shape.anim{type:'stretch',axis,dir:both|pos|neg}`.

## Adendo: presets de forma
- Gadget Formas, subtab "Presets": salva a forma selecionada inteira (modelo, poses, afinação, alinhamento, olhar, animações com intervalos, partes e tempos, cor/brilho, rastro, intervalos) com nome no `localStorage` (`move_sketch_presets_v1`). Ações: Criar na cena, Aplicar à selecionada (mantém id e fases), Renomear, Copiar JSON, Apagar, Importar JSON e Copiar todos. Alinhamento a outra forma (`shape:ID`) não é guardado (vira "nada"). Telemetria: `preset.save/list/apply/del`.

## Adendo: exportar imagem (spritesheet PNG / GIF) com código opcional
- Gadget Exportar, seção "Exportar imagem / animação": origem = só a forma selecionada (toda a animação dela, do início ao fim) ou a cena inteira (corpo, oponente, formas); formato Spritesheet PNG (colunas, linhas) ou GIF animado (paleta median cut, transparência de 1 bit); tamanho 128–512 px, fps 8–30, fundo transparente/azul do app/branco/preto. Quadros renderizados em tempo fixo por quadro (determinístico), câmera ortográfica na direção da câmera atual, enquadrando a união de todos os quadros (máx. 240 quadros).
- "Incluir metadados e código (.zip)": gera um .zip com a imagem, o `.json` do sheet (frame_w/h, colunas, linhas, fps, duração, `time_range_ms`, `godot:{hframes,vframes}`, lista de quadros) e o código escolhido (GDScript, JSON, Briefing ou os três; da forma ou do Move conforme a origem). Sem o zip, baixa só a imagem. Telemetria: `TEL.capture({scope,fmt,size,fps,cols,bg,zip,code})`.
- Escolhas da IA pendentes: limite de 240 quadros, GIF com transparência 1 bit (bordas serrilhadas), câmera ortográfica na vista atual.

## Adendo: exportação de imagem em vários ângulos (referência visual para a IA)
- Ângulos selecionáveis: câmera atual, lateral (±Z), de frente (+X), de trás (−X), de cima, de baixo, quatro 3/4 e isométrica ("Todos os ângulos"), mais "Volta 360°" (8, 12 ou 16 ângulos a cada 45°/30°/22,5°). Mesma escala ortográfica em todos (esfera que contém a forma em todos os quadros).
- Spritesheet com vários ângulos: cada LINHA é um ângulo, cada COLUNA um instante (início→fim). GIF com vários ângulos: grade com todos os ângulos no mesmo quadro. "Quadros por ângulo" (4–16 pontos-chave ou automático pelos fps) e rótulos opcionais (nome do ângulo e tempo em ms). O JSON de metadados lista cada ângulo (`camera_dir`, `up`, linha) e cada quadro. Limite 16384 px por lado / 90 Mpx (erro claro se passar). Telemetria: `TEL.capture({angles:'all'|[ids],turn,nf,labels,...})`.

## Adendo: melhorias da exportação de imagem e dinâmica no mundo
- Rótulos: ângulo só na 1ª coluna de cada linha e tempo só na 1ª linha (GIF em grade: ângulo em cada célula, tempo na 1ª); nomes curtos. Enquadramento justo (maior extensão projetada em todos os quadros e ângulos, mesma escala). "Cortar quadros em que a forma já sumiu" (opacidade < 3%; só forma) e "Pular ângulos quase idênticos" (compara silhuetas, inclusive espelhadas; o JSON lista `skipped_angles`).
- Exportação da forma ganhou `dynamics`: posição no mundo (x 0 atacante→1 alvo, y em alturas), eixos locais da forma convertidos para o mundo, para onde aponta o lado + do eixo da afinação (a ponta) e o giro/esticar/deslizar em direções do jogo (frente/trás, cima/baixo, lado ±Z), com `notes` em texto. Vai no JSON, no briefing e no GDScript (`DYNAMICS`).
- Verificado com os parâmetros da Coroa #4 do criador: eixo local Z aponta para +X (frente, rumo ao alvo); a ponta aponta para o alvo; medida pelos pixels da vista lateral (silhueta larga atrás, estreita à frente).

## Adendo: edição dos pontos da trilha
- Gadget Camadas, ao selecionar um traço (lista ou Alt+clique): "Pontos da trilha selecionada". "Editar pontos: sim" mostra bolinhas nos pontos (verde = início, vermelho = fim, amarelo = selecionado), seleciona-se clicando na bolinha ou na linha da tabela e arrasta-se com a alça de mover (Shift trava em 45°). Tabela com X (0 atacante → 1 alvo), Y (altura, 1 = personagem), Z (lado) editáveis por número. Botões: Suavizar, Tempo uniforme (velocidade constante), Inverter, Inserir ponto (no meio do trecho após o selecionado), Apagar ponto, Simplificar para N pontos (reamostra por comprimento mantendo o ritmo; obrigatório acima de 80 pontos). Em modo de edição o clique vazio não desenha. Trilha travada não edita. Tudo entra no histórico (desfazer).
- Telemetria: `stroke.pts{id}`, `stroke.op{id,op:simplify|smooth|uniform|reverse|insert|del|point,...}`, `stroke.edit{id,on,point}`.

## Adendo: rotação numérica e por botões
- Antes só havia a alça de girar (botão "Girar (E)" no gadget Formas), sem valores. Agora, em Ajustes da forma (aba Forma): "Rotação (pose do início/fim)" com sliders X/Y/Z em graus (-180 a 180, com botão 0), botões de 90°/−90°/180° em torno dos eixos do JOGO (frente X, vertical Y, lado Z, compondo com a rotação atual), "Zerar rotação" e "Igualar à outra pose". Shift trava a alça de girar em passos de 15°. Ordem dos ângulos: Euler XYZ do three.js (a mesma que o export usa em `rot_deg`).

## Adendo: modo "Pontos" (edição direta das trilhas, pedido de simplificação do criador)
- Botão **Pontos** (ao lado de Traço e Forma, atalho **P**): bolinhas aparecem em TODAS as trilhas visíveis (cor da trilha; a selecionada em branco, início verde, fim vermelho, ponto selecionado amarelo). **Arrastar a bolinha** move o ponto direto com o mouse (no plano da câmera); **Shift** trava em 45°; **duplo clique na linha** cria um ponto ali; **Delete** apaga o ponto selecionado; clicar numa linha seleciona a trilha (trilha com mais de 80 pontos é simplificada automaticamente para 16, desfazível); clique vazio deseleciona; não desenha nesse modo. O painel por números no gadget Camadas continua para ajuste fino.

## Adendo: caneta (Bézier), duração própria de cada forma e posição da tríade
- **Caneta** (botão Caneta, atalho B): clique cria um ponto; clique e arraste puxa as alças simétricas da curva (Alt = ponto de quina, Shift trava 45°); Enter ou duplo clique termina; Backspace apaga o último; Esc cancela. A trilha guarda `bz` (âncoras com alças) e a polilinha amostrada (`pts`). No modo Pontos as âncoras (quadrados) e as alças (azuis) são arrastáveis, duplo clique na curva cria âncora, Delete apaga. Camadas tem tabela de âncoras, "Virar curva (caneta) com N âncoras" e "Virar pontos". Export traz `curves` (âncoras e alças normalizadas). Telemetria: `stroke.pen`, `stroke.op bezier|polyline`.
- **Duração própria da forma:** em Ajustes da forma, aba Tempo, "Tempo próprio em ms" (começa, termina, duração) que substitui o intervalo por fases (`tm`), e as pontas e o corpo da barra da forma na linha do tempo podem ser arrastados (passos de 10 ms). Export com `time_ms` e `own_time`. A duração das trilhas (mãos, arma, efeito) continua sendo a das fases.
- Tríade posicionada abaixo dos botões de vista (ou ao lado, se faltar espaço).

## Adendo: alcance ao arrastar pontos + 11 melhorias de uso (QoL)
- **Alcance ao arrastar um ponto (modo Pontos):** só o ponto | vizinhos (queda suave em cosseno, alcance N pontos) | dali até o fim | do início até ali | a trilha toda; Ctrl enquanto arrasta = vizinhos suaves. Vale para pontos e âncoras de curva. Telemetria `pinf{mode,n}`.
- QoL (todas propostas da IA, a confirmar): (1) ← → passo de quadro (Shift = 10), , . e Home/End; (2) F enquadra a seleção, Shift+F tudo; (3) Ctrl+D duplica forma/trilha; (4) Tab/Shift+Tab seleciona a próxima/anterior camada; (5) Grade (off, 0,05, 0,1, 0,25) para formas, pontos e caneta (`snap{step}`); (6) coordenadas x y z ao vivo na barra de mensagem durante o arraste; (7) transformar a trilha: deslocar, espelhar X/Y/Z, escalar % (`stroke.xform`); (8) mover a trilha para outra trilha/fase; (9) baixar/abrir projeto completo (.json, com presets); (10) 10 cores rápidas na aba Forma; (11) "?" abre a lista de atalhos.

## Adendo: gadget Tutorial (3 lições) + enquadramento "seguir os efeitos"
- Gadget **Tutorial** (dock): 3 lições guiadas — (1) projétil completo (Long range, 18 passos), (2) golpe melee completo (16), (3) mid-range completo (16). Cada passo tem explicação, "Ir até lá" (abre gadget, aba e modo certos), "Fazer este passo por mim" (o app executa; refaz os anteriores que faltarem) e verificação automática (✔). Também "Começar do zero e ir fazendo" e "Montar o exemplo inteiro" (ambos pedem confirmação e entram no desfazer). "Cobertura de componentes" lista 30 itens do app que o projeto já usa. Todo o conteúdo é exemplo didático com valores de demonstração (nomes, cores, tempos, formas), **não são regras do jogo**; só viram Move do jogo se o criador aprovar.
- Prova de funcionamento: `TEL.tutorial.selfTest()` executa cada lição inteira num projeto limpo, confere todos os passos, a cobertura 30/30, se cada forma aparece em algum instante, a exportação (JSON/briefing/GDScript de cada forma), a captura multi-ângulo e o GIF, e restaura o projeto do usuário. Resultado atual: 3 lições, 0 passos com falha, 0 problemas, 30/30. Outros: `TEL.tutorial.run(id,n)`, `.coverage()`, `.lessons()`.
- Exportar imagem: novo "Enquadramento (cena)": seguir os efeitos (padrão; a câmera acompanha o centro dos efeitos visíveis em cada quadro, mesma escala), só os efeitos (união) ou efeitos + personagens. Formas com opacidade ≈ 0 não entram no enquadramento.

## Adendo: gadget próprio "Pontos e trilha"
- Os pontos da trilha (tabela X Y Z, simplificar, suavizar, inverter, inserir/apagar, curva da caneta) e "Transformar a trilha" (deslocar, espelhar, escalar, mover para outra trilha/fase) saíram do gadget Camadas e ganharam o gadget **Pontos** (dock "•"). Ele abre sozinho ao entrar no modo Pontos (tecla P), mostra a trilha selecionada e uma dica quando não há seleção. Camadas fica só com a lista de formas e traços.

## Adendo: Move de exemplo "Tail Whip" (proposta) e briefing com nomes e detalhes
- Pedido do criador: "crie um move chamado tail whip, use referências através do move sketch, me surpreenda". Feito como **proposta de referência no Move Sketch** (gadget Tutorial → Moves de exemplo → Carregar Tail Whip; `TEL.moves.build('tail_whip')`), documentada em `docs/moves/tail_whip_referencia.md`. Nada foi para o jogo; tipo, tempos, distâncias, formas e cores são propostas pendentes de aprovação do criador (AGENTS.md §2); a decisão de tipo/efeito de jogo é dele.
- Briefing (e export) agora mostram o nome da camada de cada forma e uma linha "Detalhes" (tempo em ms, olhar, animações com intervalos, partes, rastro, intervalos, cor do fim e brilho).

## Adendo: correção — tempo da separação de partes estava na aba errada
- O bloco "quando começa e termina (tempo)" da separação de partes (começa em %, termina em %, curva, atraso entre partes para iniciar e para finalizar) aparecia na aba **Tempo** porque o título começava com "Tempo". Agora o título é "Separar em partes · quando começa e termina (tempo)" e fica na aba **Partes**, logo abaixo de Afastamento e dos deslocamentos.

## Adendo: início recolhido + gadget Biblioteca (efeitos e Moves salvos)
- **Início recolhido:** ao abrir o app, todo gadget aberto começa recolhido (só a barra de título, como na captura do criador) e nenhum gadget abre sozinho na primeira carga; o botão "Iniciar recolhido/aberto" no dock alterna (`move_sketch_startmin` no navegador).
- **Biblioteca** (dock ▦, Ctrl+S salva): (1) **Moves salvos** no navegador, com miniatura, tipo, nº de formas/trilhas e data: salvar, abrir, renomear, baixar (.json) e importar arquivo; (2) **Efeitos salvos** (presets) com miniatura (quadro do meio da animação) e as ações criar na cena, aplicar à selecionada, renomear e apagar; efeitos antigos ficam sem miniatura até serem salvos de novo; (3) **Exemplos** (Tail Whip). Dados em `move_sketch_library_v1` e `move_sketch_presets_v1` (somente neste navegador: use "Baixar" para backup).

## Adendo: exemplos incluídos visíveis na Biblioteca (Tail Whip)
- O Tail Whip só aparecia na aba "Exemplos"; agora a aba **Moves salvos** começa com **Exemplos incluídos** (miniatura gerada uma vez e guardada), com **Abrir**, **Copiar p/ Moves salvos** (cópia editável) e **Efeitos p/ Efeitos salvos** (cada forma do exemplo vira um efeito salvo, ex.: "Tail Whip · Crack", com miniatura). Os exemplos são montados num estado temporário (fila serializada, sem mexer no projeto aberto nem no histórico de desfazer). O exemplo continua sendo proposta da IA, não dado do jogo.

## Adendo: duração de cada componente na linha do tempo (arrastar bordas e duplo clique)
- **Fases:** arrastar a fronteira entre fases (no cabeçalho ou nas linhas das trilhas; cursor de redimensionar, marcas brancas) muda a duração da fase (passos de 10 ms, mínimo 20; o total acompanha). Duplo clique numa fase (cabeçalho ou célula da trilha) abre a digitação da duração em ms.
- **Formas:** arrastar as pontas ou o corpo da barra (pegas visíveis) muda início e fim; duplo clique abre "início e duração em ms" (um número só = duração). A linha do tempo mostra até 16 formas (antes 6). Tudo entra no desfazer.

## Adendo: Tail Whip v2 (Status), giro do corpo, reação do alvo, marcadores de som e auditoria
- A pedido do criador, o Tail Whip foi refeito a partir da descrição dele (golpe de Status, sem dano direto, giro de costas, cauda com rastro, poeira, rajada, estalo, alvo recua o olhar e baixa a guarda, brilho ou ícone). A v1 (Melee) foi descartada e auditada em `docs/moves/tail_whip_auditoria.md`.
- Novos recursos do Move Sketch (propostas técnicas da IA): **giro do corpo** do atacante por chaves (graus acumulados, curva), marcador de "frente" nos bonecos, **reação do alvo** (recuo, pulo, inclinar, olhar, abaixar a guarda) e **marcadores de som (cues)** na linha do tempo; tudo no export (`body_yaw`, `target_reaction`, `cues`) e na telemetria (`yaw.set`, `react.set`, `cue.add/clear`). `TEL.moves.audit()` roda 19 verificações por dados (incluindo D-418, D-1222 e D-235). "Piscar" do ícone foi trocado por um pulso lento por D-418. O efeito de jogo (queda de defesa) NÃO foi decidido.
