<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1109 - Coruja: caminhada com arco contínuo dos pés

## Frase literal do criador
> "queria que fizessem um ciclo completo na caminhada, o movimento ser um arco completo entre cada passo, nao sei como explicar"

Ao escolher entre (1) arco do corpo, (2) arco contínuo dos pés e (3) no lugar/avançando, respondeu: **"2"**.

## Decisão
Na caminhada da Coruja, assim que um pé crava no chão o outro já descola e faz o arco completo no ar até a próxima pisada, com passada mais ampla, sem a pausa longa com os dois pés no chão do `Walk 1 Heavy` (hoje 20 de 32 quadros no chão, 4 quadros de apoio duplo, 18 cm de avanço, 6,5 cm de altura).

Nova Action e novo `.blend`; `Idle 1` e `Walk 1 Heavy` ficam intactos (D-1104).

## Ambiguidades em aberto
- No lugar ou avançando (item 3 não respondido).
- Tamanho da passada, altura do arco do pé e duração do ciclo.
- Se o corpo (quadril/coluna) deve continuar como está ou acompanhar.

## Estado
Aprovado o conceito; aguardando respostas das ambiguidades. Nada implementado.

## Rodada 2 (2026-11-10)
> "avanca pra frente mas obviamente no jogo ele e preso, so para ter referencia visual boa / 2 - 35% mais / 3 - pode mudar, aumente se for necessario / 4 sim, inclusive faca ele realizar uma pose com as maos abertas e bracos como um monstro de scooby doo, nao sei como explicar enquanto caminha, ao inves de um movimento basica humano"

- Avança para frente no `.blend` só como referência visual; no jogo continua presa no lugar.
- Passada (avanço e altura do pé) 35% maior: 18 cm → ~24,3 cm; 6,5 cm → ~8,8 cm.
- Duração do ciclo pode mudar; aumentar se necessário.
- Corpo (quadril/coluna) acompanha o passo.
- Braços em pose de "monstro de Scooby-Doo" durante a caminhada: braços erguidos à frente, mãos abertas com garras, em vez do balanço humano.

Estado: em implementação; proposta visual aguardando aprovação.

## Rodada 3 (2026-11-10)
> "a cabeca ta virada pra cima ao inves de continuar pra frente, corrija ... deixa as maos mais abertas e levantadas, nao pra cima, pra diagonal frente um pouco"
> "ambos bracos rigidos no mesmo angulo" — esclarecido: "pedido, nao e pros bracos se movimentarem tanto, e pra estarem rigidos pra frente algo como uma pose de assustar meio fantasma"

- Cabeça sempre olhando para frente.
- Mãos mais abertas, levantadas na diagonal para frente (não para cima).
- Braços rígidos, esticados para frente, os dois no mesmo ângulo e sem oscilar com o passo (pose de assustar de fantasma).

## Rodada 4 (2026-11-10)
> "o corpo ta inclinado pra tras ao inves de ser pra frente, cace referencias sobre pose monstruosa de assustar"

- Corpo inclinado para frente (corcunda de monstro): Hips ~5°, Spine ~16°, Chest ~30° para frente; cabeça continua olhando para frente.
- Braços travados no mundo, sempre retos para frente e no mesmo ângulo (a torção do tronco não os move). Arquivo: `owl_walk_monster_arc_v4.blend`.

## Rodada 5 (2026-11-10)
> "fiz uma mudanca no frame 2 pra vc usar de ref pra correcao"

- Criador ajustou manualmente os ossos dos braços, ombros, antebraços, mãos e garras no frame 2 como pose de referência da postura monstruosa.
- Ambiguidades a confirmar antes da propagação: se propaga a pose para todo o ciclo fixada ao tórax, se mantém a sutil assimetria manual ou espelha um dos lados, e se mantém rígida ou com micro-balanço.

## Rodada 6 (2026-11-10)
> "pernas dao snap em vertos frames deixe o movimento mais rapido mais passos"

- Corrigir o snap/pop das pernas: suavizar a trajetória do pé (remover descontinuidade angular de pitch no meio do voo e choque na decolagem/pouso).
- Movimento mais rápido com mais passos: acelerar a cadência (reduzir duração do ciclo de 40 para ~24 quadros, aumentando o número de passos).
- Aplicar a pose de referência dos braços que o criador fez no frame 2 fixada ao tórax ao longo de todo o ciclo.
- Salvar em nova versão (`owl_walk_monster_arc_v5.blend`) e testar com Motion Lens.

## Rodada 7 (2026-11-10)
> "deixa ozs ombros rigidos tambem zem rotacao"

- O criador pede ombros rígidos e sem rotação.
- Esclarecer se refere a:
  1. Ombros/braços travados no espaço global (não giram/torcem com o balanço lateral do tórax durante a passada).
  2. Rotação local dos ossos LeftShoulder/RightShoulder zerada (neutra em relação ao tórax).
  3. Ambas as coisas (ombros neutros e sem oscilação no espaço).

## Rodada 8 (2026-11-10)
> "Eles balançam com o sobe e desce mas não de forma horizontal"

- Ombros e braços acompanham apenas o sobe e desce vertical (bob) da caminhada.
- Eliminada toda a rotação e balanço horizontal (sem yaw / torção lateral esquerda-direita e sem roll lateral nos braços/ombros).
- Ficam apontando retos para frente o tempo todo, apenas subindo e descendo com o passo.
- Salvar nova versão (`owl_walk_monster_arc_v6.blend`) e validar com Motion Lens.

## Rodada 9 (2026-11-10)
> "aumente mais o numero de passoa quero mais pressao nos movimentos , que o passo levante mais"

- Mais passos / cadência mais rápida: reduzir ainda mais a duração do ciclo (de 24 quadros para ~16-18 quadros, aumentando a frequência de passos por segundo).
- Passo levantar mais: aumentar a altura do arco do pé no ar (de 8 cm para ~13-14 cm).
- Mais pressão nos movimentos: acentuar o impacto e peso na pisada (compressão maior do quadril/joelho no contato, descida mais pesada e rápida ao bater no chão).
- Salvar como `owl_walk_monster_arc_v7.blend` e validar com Motion Lens.

## Rodada 10 (2026-11-10)
> "ok, vamos diminuir o numero de keyframes e dar menos passos, mas eles serem longos, um pendulo inteiro, quase 180 graus"

- Criador pede menos passos e passos longos, com redução do número de keyframes.
- Menciona "um pêndulo inteiro, quase 180 graus".
- Ambiguidades a esclarecer antes de alterar:
  1. Se o "pêndulo de quase 180 graus" se refere ao arco de balanço da perna (de trás para frente) ou ao balanço lateral do corpo/tronco (de um lado para o outro) ou ambos.
  2. Quantos passos fazer no total (ex.: apenas 1 ciclo com 2 passos - esquerdo e direito - ou 4 passos).
  3. Se "diminuir o número de keyframes" significa usar apenas poses-chave (keying esparso em Bezier nos contatos e passagens) para o criador editar facilmente na timeline, em vez de assar todos os frames.

## Rodada 11 (2026-11-10)
> "vamos testar o B / 2 - 4 passos / 3 sim"

- Pêndulo do corpo (B): o corpo inteiro oscila lateralmente como um grande pêndulo, tombando o peso de um lado para o outro sobre a perna de apoio (arco amplo em pêndulo).
- 4 passos no total (2 ciclos completos).
- Keyframes limpos/esparsos (sim): apenas poses-chave (Contato e Passagem) com interpolação Bézier, sem assar todos os frames, facilitando edição no Dope Sheet.
- Salvar como nova versão (`owl_walk_pendulum_v1.blend` ou `owl_walk_monster_arc_v8.blend`) e validar com Motion Lens.

## Rodada 12 (2026-11-10)
> "movimento em ondas para o corpo, eu quero que ele pareça menos estático, isso inclui os braços e ombros. Deire o rosto mais levantado / me diz se entendeu"

- Movimento em ondas (overlapping action / onda espinhal): a ondulação da passada começa no quadril e viaja em sequência pela coluna, tórax, ombros e braços (com defasagem/lag de alguns quadros), tirando a sensação de bloco rígido.
- Braços e ombros menos estáticos: participam da onda, com cotovelos e garras sofrendo arrasto (drag/follow-through) em vez de ficarem congelados.
- Rosto mais levantado: cabeça/queixo mais erguidos para frente/cima, exibindo a face e o olhar da criatura.
- Estado: alinhando entendimento com o criador antes de alterar a animação.

- Status: Aprovado pelo criador ("prossiga"). Implementando versão `owl_walk_monster_arc_v9.blend`.

## Rodada 13 (2026-11-10)
> "veja o keyframe que editei, o frame 33, note como eu quero que as pernas se alarguem, um 180 completo a cada passo"

- Criador editou manualmente o frame 33 para definir a amplitude real da passada:
  - Passada ultra-larga e estendida: separação frente-trás de ~55 cm (Y) e largura lateral de ~55 cm (X).
  - Joelhos e pernas abertos para fora em lunge/agachamento monstruoso profundo (coxas abertas em ângulo amplo de quase 180° entre o pé de trás e o da frente).
  - Quadril afundado em centro de gravidade baixo (~32 cm de altura do chão).

- Status: Aprovado pelo criador ("sim"). Implementando lunge e abertura de pernas de 180° em todos os 4 passos na versão `owl_walk_monster_arc_v10.blend`.

## Rodada 14 (2026-11-10)
> "os arcos dos braços deviam ser mais suaves e mais duradouros"

- Arcos dos braços mais suaves e duradouros:
  - Frequência dos braços sincronizada com o ciclo completo do pêndulo corporal (período mais longo de oscilação em vez de vibração curta por passada).
  - Maior amortecimento e suavização nas curvas Bézier (ease-in/ease-out ampliado nas garras e cotovelos), permitindo que o arco flutue e paire mais tempo no ar antes de descer.
- Salvar como `owl_walk_monster_arc_v11.blend` e validar com Motion Lens.

## Rodada 15 (2026-11-10)
> "são ondas pra cima e pra baixo não pra direita e pra esquerda."

- Esclarecimento fundamental da onda:
  - Movimento ondulatório é estritamente vertical (para cima e para baixo / no plano sagital Z e pitch).
  - Eliminado o balanço lateral (esquerda e direita / roll e sway X) no corpo e nos braços.
  - Ombros, braços, antebraços e garras ondulam subindo e descendo em arcos verticais suaves e duradouros, acompanhando a onda de compressão e elevação do passo.
- Salvar como `owl_walk_monster_arc_v12.blend` e validar com Motion Lens.

## Rodada 16 (2026-11-10)
> "pelo amor de deus, volta atrás duas vezes"

- Criador solicitou reverter as duas últimas rodadas (descartando as alterações de v11 e v12).
- Reaberto o arquivo `owl_walk_monster_arc_v10.blend` com a Action `Walk 5 Monster Lunge 180` (a versão da aprovação da passada de 180° e abertura inspirada no frame 33).
- Estado atual restaurado: v10.

## Rodada 17 (2026-11-10)
> "o movimento do boneco tá todo estranho do frame 10 ao 20 e do 44 ao 53, tudo na mesma perna, o movimento parece mais forçado do que algo suave que o personagem faz, os pés nem mesmo rotacionam em ambas pernas quando o personagem dá um passo e a perna levanta"

- Causa física e cinemática diagnosticada nos frames 10..20 e 44..53:
  1. **Hiperextensão física (joelho travado a 100% de estiramento)**: O rig possui comprimento total da perna de 0,2972 m (coxa 0,1648 m + tíbia 0,1325 m). Na passada estendida da v10, a distância pedida entre a articulação do quadril e o tornozelo chegava a 0,35 m a 0,37 m nos frames 12..19 e 44..52 (excedendo o comprimento anatômico do membro em mais de 20%). Isso forçava o solucionador de IK a esticar a perna até o limite absoluto, travando a junta do joelho em linha reta ("estalo/puxão forçado") e fazendo o pé flutuar/arrastar de forma não natural.
  2. **Pés retos sem articulação de tornozelo**: As rotações de pitch nos controles `LeftFootIK` e `RightFootIK` estavam zeradas durante as fases do passo, mantendo os pés como blocos de madeira planos sem rotação ao descolar ou aterrissar.
- Correção implementada na Action `Walk 9 Fluid Organic Stride` (v13):
  1. **Eliminação completa do estiramento excessivo**: Com a calibração da passada e a antecipação suave do calcanhar a partir de 50% da fase de apoio, o alcance máximo da perna nunca passa de 84,2% (0,250 m de 0,2972 m no pico da perna esquerda e 76,0% na direita). Os joelhos mantêm curvatura constante e natural em todos os 65 frames (0 avisos de hiperextensão).
  2. **Articulação completa dos pés**:
     - *Heel-off / Roll*: Calcanhar sobe gradualmente a partir do meio do apoio até atingir inclinação alta (+24,8° no controle IK) antes de descolar a ponta dos dedos.
     - *Swing / Dorsiflexão*: No voo de passagem, o pé articula fluidamente apontando e flexionando suavemente (-15,8° a -37,3° de inclinação anatômica).
     - *Heel-strike & Roll-flat*: O pé aterrissa apoiando o calcanhar e rola de volta para o plano perfeitamente assentado (0,0°).
  3. **Apoio travado sem deslize**: `slide max = 0.000 m/frame` para ambos os pés na telemetria do Motion Lens.
- Salvo como `owl_walk_monster_arc_v13.blend` e validado com Motion Lens (contact sheet gerado em `scratch/lens_walk9/motion_lens_contact_sheet.png`).

## Rodada 18 (2026-11-10)
> "OLHA A MERDA QUE TU FEZ EU PEDI UMA MUDANÇA SIMPLES E VC SIMPLESMENTE ARRUINOU TODO O MOVIMENTO NÃO ERA PRA TIRAR O MOVIMENTO COMPLETO ERA SÓ PRA AJEITAR A MERDA DAS PERNAS SÓ AJEITA ESSE LIXO E RÁPIDO"

- Revertido imediatamente o encurtamento indevido da passada: toda a base monstruosa da v10 (postura encurvada, onda na coluna, queixo erguido, braços abertos de monstro e a passada ultra-larga de 180° inspirada no frame 33) foi mantida 100% intacta.
- Causa real do problema "tudo na mesma perna" nos frames 10..20 e 44..53:
  - O osso `LeftUpLeg` estava com um deslocamento estático não-keyframed no pose mode (`location = (0.0321, 0.0113, -0.1538)`), projetando o quadril esquerdo 15 cm à frente do osso simétrico da perna direita.
  - Ao zerar e resetar o `LeftUpLeg` para `(0, 0, 0)`, a perna esquerda voltou à simetria anatômica perfeita com a direita. O pé esquerdo não descola mais prematuramente nem sofre puxão forçado nesses quadros.
- Articulação completa dos pés em ambas as pernas ao dar o passo e levantar:
  - Rotações de pitch naturais aplicadas em `LeftFootIK` e `RightFootIK`:
    - Saída / Heel-off: calcanhar sobe (-18° a -22°) mantendo os dedos no chão.
    - Elevação / Passagem: pé acompanha o trajeto suavemente em vez de ficar como bloco de madeira reto.
    - Aterrissagem / Heel-strike: calcanhar toca primeiro (+10° a +14°) e rola plano (0°) no chão.
- Salvo como `owl_walk_monster_arc_v14.blend` (contact sheet gerado em `scratch/lens_walk14/motion_lens_contact_sheet.png`).

## Rodada 19 (2026-11-10)
> "1" (em resposta à escolha do estilo de rotação: ponta apontando para baixo / calcanhar alto ao sair do chão e subir no ar, acompanhando o arco da perna, e só empinando para cima na hora de aterrissar)

- Implementada a Opção 1 escolhida pelo criador em ambas as pernas (`LeftFootIK` e `RightFootIK`):
  - **Saída / Push-off**: calcanhar sobe para $-25^\circ$ enquanto os dedos empurram o chão.
  - **Elevação e Ápice no ar**: a ponta dos dedos cai e aponta claramente para trás/baixo (inclinação anatômica de $-56^\circ$ no ápice, `pitch` local de $-30^\circ$ a $-35^\circ$), com o calcanhar alto acompanhando o arco do passo no ar sem ficar reto ou travado.
  - **Avanço / Heel-strike**: no final do balanço, o pé empina para cima ($+25^\circ$ no avanço e $+20^\circ$ no contato) para tocar o calcanhar primeiro no chão.
  - **Apoio / Stance**: rola de volta para plano ($0^\circ$) e permanece cravado no chão durante a fase de sustentação.
- Todo o restante da criatura (passada larga de 180° baseada no frame 33, corcunda, onda na coluna, queixo erguido e braços monstruosos) mantido 100% intacto.
- Salvo e carregado ativamente no Blender como `owl_walk_monster_arc_v15.blend` (contact sheet gerado em `scratch/lens_walk15/motion_lens_contact_sheet.png`).

## Rodada 20 (2026-11-10)
> "2 e 3" (em resposta à rotação dos pés ao mover para pisar: Opção 3 - pivotar no chão antes de sair; Opção 2 - girar no ar acompanhando a perna e a direção da pisada)

- Implementada a combinação exata de 2 e 3 nos controles `LeftFootIK` e `RightFootIK`:
  - **Pivô no chão antes de sair (Opção 3)**:
    - Quando o pé está atrás no chão e vai iniciar a passada, o calcanhar sobe e o pé pivota/gira no chão para fora (yaw de $\pm 25^\circ$, pitch de $-25^\circ$, roll de $\pm 8^\circ$), lançando o impulso com rotação antes de decolar.
  - **Giro dinâmico 3D no ar acompanhando a perna (Opção 2)**:
    - Ao sair do chão e viajar no ar descrevendo a passada larga de 180°, o tornozelo gira nos 3 eixos acompanhando o arco aberto do joelho:
      - Yaw abre até $\pm 61^\circ$ apontando na direção do arco da perna aberta (em vez de ficar paralelo como esqui).
      - Roll inclina suavemente a sola ($\pm 12^\circ$) acompanhando a curva da perna.
      - Pitch direciona a ponta para trás/baixo no ápice ($-50^\circ$) e empina para cima ($+25^\circ$) ao avançar para o contato.
    - Na aterrissagem, o pé orienta o calcanhar na direção exata da pisada e assenta plano no chão.
- Todo o corpo superior (postura curvada, onda na coluna, queixo erguido e braços monstruosos) mantido 100% intacto.
- Salvo e carregado ativamente no Blender como `owl_walk_monster_arc_v16.blend` (contact sheet gerado em `scratch/lens_walk16/motion_lens_contact_sheet.png`).

## Rodada 21 (2026-11-10)
> "reduz a quantidade de frames pra 45 e adapte"

- Duração total da animação adaptada proporcionalmente de 65 para 45 frames (escala temporal de $44/64 = 0{,}6875$ em todas as 82 fcurves da Action):
  - Linha do tempo ajustada: `frame_start = 1`, `frame_end = 45` (45 frames totais).
  - 4 passos mantidos com 11 frames por passada:
    - Passo 1: frames 1 a 12 (contato em F12).
    - Passo 2: frames 12 a 23 (contato e pose do frame 33 agora no frame 23).
    - Passo 3: frames 23 a 34 (contato em F34).
    - Passo 4: frames 34 a 45 (contato em F45).
  - Todos os giros e articulações dos pés (pivô no chão antes de sair e giro 3D no ar) adaptados e sincronizados com a velocidade maior da passada.
  - Onda na coluna, postura curvada, queixo erguido e braços de monstro reescalados harmonicamente com o novo ritmo.
- Salvo e carregado ativamente no Blender como `owl_walk_monster_arc_v17.blend` (contact sheet gerado em `scratch/lens_walk17/motion_lens_contact_sheet.png`).
