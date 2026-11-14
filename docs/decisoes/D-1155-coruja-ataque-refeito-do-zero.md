<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1155 — Ataque da coruja completamente refeito, com golpe diferente e escala de osso

- **Data:** 2026-11-11.
- **Área:** Animação / coruja / Blender.
- **Relacionadas:** D-1149 (ataque básico v1, "com uma garra, de cima para baixo"), D-1141 (clipe a 1,0× com endlag), D-997 (pular pose parada do início), D-322 (refazer do zero = ignorar o antigo).

## O que o criador disse (literal)

> veja o personagem aberto no blender e faça uma pesquisa por referências para criar uma animação de ataque de alto nível que contenha a maioria dos principios de animação

Ao aceitar aplicar a pesquisa: **"Sim, v2 da garra"**.

Sobre o timing da v1 (garra no alto no 15, batida no 19, fim no 53):

> mude TUDO do atual, quero um ataque completamente refeito

Sobre usar escala de osso para squash/stretch e smear de um quadro: **"Sim, com escala"**.

Sobre "mude tudo" incluir o golpe em si (a D-1149 definia uma garra, de cima para baixo): **"Golpe diferente"**.

Ao descrever o novo golpe:

> com uma garra, um ataque bem amplo, pense em pantera negra em marvel rivals, warwick em 2xko

Ao reprovar a primeira passada (2026-11-11):

> não tem nenhum movimento do personagem, nenhuma preparação, não é só o braço que devem ser mover, é pra ter preparo, trajeto e impacto, além de uma recuperação semi-lenta
>
> cace referências nos modelos de animação que usamos em C/games/tact e nos pokemons em E/arenamon

A primeira passada foi **reprovada**. O ataque precisa de movimento do personagem inteiro, com preparo, trajeto, impacto e recuperação semi-lenta, com referência nos clipes de ataque de `C:\games\tact` e nos Pokémon de `E:\Arenamon`.

Depois de editar a segunda tentativa à mão no Blender (2026-11-11):

> veja as melhorias que fiz e adapte elas pra ficar mais correto, use o motion lens, obrigatoriamente

As edições manuais do criador são a base: preservar as poses dele e só adaptar o movimento em volta para ficar mais correto. O uso do Motion Lens é obrigatório. Estado manual guardado em `owl_attack_user_edit_backup.blend`.

Sobre levantar a garra no quadro 19 para ela só tocar o chão, sem atravessar: **"Sim, só tocar"**. Só o braço esquerdo muda nessa pose; o resto da pose do criador fica igual.

Depois de editar de novo o quadro 19 à mão (2026-11-11):

> veja as mudanças que fiz no frame 19 e melhore a recuperação pra ser mais suave

A nova pose do quadro 19 do criador é preservada; a recuperação é refeita a partir dela para ficar mais suave. Estado manual guardado em `owl_attack_user_edit_backup_2.blend`.

Sobre refazer os quadros 17 e 18 do trajeto para o pé esquerdo parar de deslizar: **"Sim, refazer 17-18"**.

Pedido de polimento geral (2026-11-11):

> melhore o feeling e o trajeto do ataque em geral, sem tirar sua força, e poses dinamicas, quero que me impressione

Melhorar a sensação e o trajeto do ataque inteiro, sem perder a força nem as poses dinâmicas. As poses do criador nos quadros 11, 15 e 19 continuam sendo as âncoras. O trabalho é feito numa Action nova, derivada, para a anterior ficar disponível para comparação.

Crítica à `Attack 4` (2026-11-11):

> giro maior do tronco durante o ataque, se desfazendo após finalizar, o movimento do braço e do corpo em sí após finalizar o ataque não é mt bom, a finalização deveria concluir o arco com um "espiral" de movimento, lentamente, ao invés de ser como é

O tronco deve girar mais durante o ataque e desfazer o giro depois. A finalização deixa de ser "garra parada e volta direta": o braço e o corpo concluem o arco em espiral, devagar. Interpretação do assistente (não confirmada): a pose do quadro 19 do criador continua como âncora e o giro extra acontece passando dela.

Pedido posterior sobre a recuperação (2026-11-11):

> veja todas mudanças recentes que eu fiz e corrija o movimento de recuperação pra não entrar no corpo do personagem alem de deixar ele nno mínimo 50% mais suave

Inspecionar a Action aberta e preservar as edições recentes do criador. Corrigir a recuperação para que braço e garra não atravessem o corpo. Medir a suavidade antes e depois com o Motion Lens e dados de trajetória; obter pelo menos 50% de redução em uma medida objetiva de aspereza na recuperação, sem alterar o ataque até o quadro de impacto. Métrica e resultados serão registrados após a verificação.

## Decisão

0. O novo golpe é feito **com uma garra** e é **bem amplo**. Referências de movimento: Pantera Negra em Marvel Rivals e Warwick em 2XKO (referência visual para adaptação autoral, sem transferência de animação).

1. O ataque da coruja é refeito do zero: timing, poses, curvas e duração novos, sem reaproveitar a v1 nem a referência do Cyclops.
2. O golpe em si também muda. A D-1149 ("uma garra, de cima para baixo") deixa de valer para a nova versão; a v1 fica preservada no arquivo dela.
3. Escala de osso está autorizada para squash/stretch e smear de um quadro.
4. A animação deve conter a maioria dos princípios de animação, com base na pesquisa de referências feita em 2026-11-11.
5. É trabalho de animação no Blender. Nenhuma regra de combate é definida aqui.

## Ambiguidades em aberto

- Direção exata do golpe amplo (lateral, diagonal, etc.): o criador não disse; a blocagem em stepped é mostrada para aprovação antes de qualquer polimento.
- Duração total do clipe (pela D-1141, o clipe inteiro é o tempo de trava do jogador).
- Se a escala de osso sobrevive à exportação para o Godot: não verificado.

## Referências medidas (2026-11-11)

Clipes amostrados em Blender em segundo plano; medidas em `assets/modelos/owl/blender/evidence/attack_v2_swipe/refs/medidas_referencias.json`.

- Tact, ataque básico `_11` de killerpanther (0015), kakutoupanther (0149), troll (0061), hellbeast (0056) e gigantes (0065): o golpe acontece em **0,71 s** em todos; duração total de 1,8 a 2,2 s; o corpo inteiro sobe ou salta (topo do corpo sobe de 0,14 a 1,05 alturas) e a recuperação ocupa de 1,0 a 1,4 s.
- Arenamon, `Mutant Swiping` (mosh): corpo avança 0,23 altura até o golpe em 0,96 s e volta à origem; 1,92 s no total.
- Arenamon, Pokémon: só o Croagunk tem clipe de ataque (`tackle`, 2,42 s); gumshoos, drowzee e eggo não têm clipe de ataque.

## Estado

**Correção do salto de recuperação (2026-11-11):**

> esse salto tá um lixo, o perosnagem nem se movimenta, o corpo nem se movimenta, não é só um deslocamento do modelo pra cima, corrige

A tentativa `Attack 6 Small Recovery Hop` foi rejeitada: transladar Root e Hips não produz a articulação pedida. Refazer o pequeno salto com flexão/extensão das pernas, impulso do quadril, movimento do tronco e absorção da aterrissagem; manter duração 1–52 e ataque até o impacto. Não retomar o salto grande rejeitado.

**Revisão implementada, aprovação visual pendente:** `Attack 6 Recovery Body Hop`, derivada da Action 6 restaurada. Root mantido. Carga sobre a perna de apoio em 31–33, extensão em 34, pernas recolhidas durante o recuo aéreo em 35–39; pés chegam em 40/41, quadril e tronco absorvem o pouso e acomodam até 46. Animados separadamente quadril, coluna, peito, cabeça e controles dos pés; inclinação do peito defasada um quadro. Alteração da translação rígida rejeitada substituída pela articulação do corpo. Ataque 1–19 com desvio matricial zero; pose 52 com erro numérico abaixo de 0,000001. Intervalo 1–52 preservado. Motion Lens executado, folhas frontal/lateral/superior e curvas abertas e conferidas em `evidence/recovery_body_hop/`. Verificação BVH de braço esquerdo versus torso/cabeça sem interseções nas 45 amostras de recuperação; exclui triângulos de grupos dominantes mistos. Mantida a limitação preexistente dos pés abaixo do plano do chão no início da recuperação (até 8,34 cm nas amostras finais); corrigido o afundamento adicional causado pela nova flexão. Evidências em `verification.json` e `report.txt`. Salvo no arquivo principal e deixado em reprodução. Exportação, jogo, espelhamento e outros atacantes/alvos não testados. Nenhuma regra de combate alterada.

**Pedido após a reversão (2026-11-11):**

> só faça ele dar um pequeno salto com peso na recuperação

Adicionar somente um pequeno salto de acomodação na recuperação da versão restaurada, com compressão na aterrissagem. Preservar o ataque e a duração 1–52; não retomar o salto ampliado rejeitado. Implementação e conferência no Blender pendentes.

**Reversão solicitada (2026-11-11):**

> vc piorou tudo, tá uma bosta esse pulo, o movimento tá completamente lento, volte atrás

`Attack 7 Feral Leap` reprovada pelo criador. Restaurado integralmente o backup `owl_attack_wide_swipe_v2_before_attack7.blend` no arquivo principal, com `Attack 6 Clear Spiral Recovery`, intervalo 1–52 a 24 fps e as edições manuais anteriores à rodada. Desfeitos o salto ampliado, o prolongamento do timing e as mudanças da recuperação desta rodada. Estado rejeitado guardado separadamente em `owl_attack7_rejected_backup.blend`. Os resultados numéricos abaixo são históricos e não representam aprovação artística. Nenhuma mudança no jogo.

Pedido de revisão de 2026-11-11:

> o braço fica completamente estranho do frame 30 ao 41, me surpreenda na correção, eu também gostaria que após o wind-up o pulinho seja mais epico do ataque

Corrigir a anatomia e continuidade da recuperação (30–41) e tornar o salto após o preparo mais expressivo, com maior impulso e leitura aérea. Trabalhar em versão derivada; medir com Motion Lens e verificar visualmente.

**Revisão atual — Attack 7 Feral Leap (2026-11-11, aprovação visual pendente):** estado aberto preservado em `owl_attack_wide_swipe_v2_before_attack7.blend`; a Action 6 permanece disponível. Recuperação refeita com cotovelo abaixo do ombro, mão por fora do tronco e retorno gradual. Salto com ápice do corpo 0,30 m mais alto, pernas recolhidas e garra armada. Acrescentados 6 quadros ao trajeto aéreo e 3 à recuperação: impacto em 25, fim em 61, duração entre chaves de 2,50 s a 24 fps. Poses-âncora do preparo 15, antigo impacto 19 (agora 25) e encerramento 52 (agora 61) preservadas com erro matricial zero. Motion Lens executado; folhas frontal/lateral/superior e gráficos abertos e conferidos em `evidence/attack7/`. BVH braço esquerdo versus torso/cabeça: zero interseções nas 73 amostras de meio quadro entre 25–61; o detector exclui triângulos de transição com grupos dominantes mistos. RMS da terceira diferença da trajetória em relação à Action 5: mão −53,9%, garras −58,5%, antebraço −70,3% (inclui o efeito do retorno mais lento; não é uma medida de qualidade artística). Evidências: `geometry.json`, `smoothness.json`, `report.txt` e folhas do Motion Lens. Persistem os alertas preexistentes de afundamento dos pés até 8,5 cm e deslizamento esquerdo. Não exportado nem testado no jogo, com outros atacantes, lado espelhado ou alvos diferentes. Nenhuma regra de combate alterada.

**Recuperação sem atravessar o corpo (2026-11-11):** após o pedido literal acima, o estado aberto da `Attack 5 Spiral Finish`, inclusive edições não salvas, foi copiado para `owl_attack_wide_swipe_v2_before_recovery6.blend`. Uma Action derivada, `Attack 6 Clear Spiral Recovery`, redesenha o braço esquerdo após o quadro 19; os quadros até o impacto e a pose do 19 permanecem iguais (desvio máximo 0). A mão completa a espiral pela frente e por fora do torso, com transição suave para o idle. Verificação de malha por interseção BVH entre triângulos dominados por `LeftArm`/`LeftForeArm`/`LeftHand`/`LeftHandClaws` e `Head`/`Spine`/`Hips`: 7 quadros com interseção na Attack 5 (26–32), **0** na Attack 6 (19–52), inclusive 67 amostras a cada meio quadro. Medida de suavidade: RMS da terceira diferença da posição mundial das juntas, quadros 19–52; mão 0,06282 → 0,01894 (−69,9%), garras 0,08412 → 0,04143 (−50,7%), antebraço 0,05972 → 0,02955 (−50,5%). A meta de 50% foi alcançada nos três pontos medidos. Motion Lens antes/depois, folhas de poses e medidas em `evidence/attack_v2_swipe/lens_spiral_before_recovery6/` e `lens_spiral_after_recovery6/`. O Motion Lens ainda relata o afundamento preexistente de até 8,5 cm da malha/pés no chão e 0,063 m/quadro de deslizamento do pé esquerdo. Exportação e teste no jogo pendentes.

**Finalização em espiral (2026-11-11, aguardando aprovação):** Action nova `Attack 5 Spiral Finish` (`Attack 4` e `Attack 3` guardadas). Poses do criador em 11, 15 e 19 com desvio 0; quadros 1–19 iguais à `Attack 4`. Depois do impacto o tronco continua girando: peito de −75° (quadro 19) até −116° (quadros 25–26), quadril de −12° até −25°, e desfaz o giro até 0° no quadro 46. A garra não para mais no impacto: segue o arco para a direita, sobe e enrola para dentro até a frente do peito (quadros 19–29), depois desce até o idle por uma curva contínua (30–47, um ponto por quadro). Velocidade da mão esquerda depois do contato: 0,26 → 0,11 → 0,19 → 0,21 → 0,16 → 0,12 … caindo até 0 no 52, sem inversão de direção. Passos de volta: pé esquerdo 30–38, pé direito 37–46. Motion Lens em `evidence/attack_v2_swipe/lens_espiral/`: "sem pausa" depois do contato (consequência direta do pedido), deslizamento do pé esquerdo 0,063 m/quadro, malha até −0,085 m (pés). Duração mantida em 52 quadros. Vista espelhada, exportação e jogo não verificados.


**Polimento geral (2026-11-11, aguardando aprovação):** Action nova `Attack 4 Lunging Claw Sweep Polish` (a `Attack 3` fica intacta para comparação). Poses do criador em 11, 15 e 19 com desvio 0. Preparo: quebras em 5 e 8, quadril lidera e abaixa, braço esquerdo atrasa e sobe por último. Trajeto 16–18: quadril comprime no 16 e salta em arco, cabeça adianta o olhar, garra segue um arco amplo por pontos no mundo, com esticamento do antebraço limitado a 1,5. Impacto: a garra para cravada no mesmo ponto (erro ≤ 1 mm, 19–25) enquanto o corpo chega depois (quadril −4,5 cm e cabeça −8,6 cm em 20–21) e volta até o 25; braço direito passa do ponto e retorna. Velocidade da mão esquerda: 0,49 → 0,80 → 1,04 → 1,19 m/quadro, com o pico no quadro do contato (antes o pico era um quadro antes: 1,70 e depois 0,70). Motion Lens em `evidence/attack_v2_swipe/lens_polish/`: pausa de 5 quadros OK; deslizamento do pé esquerdo 0,046 m/quadro; bote contado em 5 quadros (o Lens agora inicia no 15); pés até 7,5 cm abaixo do chão em 19–31 (vem da pose do criador; o esquerdo afunda mais com a compressão do 20–21). Vista espelhada, exportação e jogo não verificados.


**Quadros 17 e 18 refeitos (2026-11-11, aguardando aprovação):** recriados entre as poses do criador dos quadros 15 e 19 (ambas com desvio 0): corpo a 48% e 84% do caminho, pés em arco, braço esquerdo em arrasto e depois smear. Motion Lens em `evidence/attack_v2_swipe/lens_trajeto_17_18/`: deslizamento do pé esquerdo 0,258 → 0,049 m/quadro; bote em 4 quadros OK; pausa de 5 quadros OK; mão esquerda 0,2 → 0,9 → 1,7 → 0,7 m/quadro e para. Pendente: pé direito até 7,5 cm abaixo do chão nos quadros 19–31 (pose do quadro 19 do criador, não alterada) e pé esquerdo 3,6 cm nos quadros 7–10.


**Recuperação mais suave (2026-11-11, aguardando aprovação):** o criador girou a coluna 21,8° e deslocou a coxa direita no quadro 19, e apagou as chaves dos quadros 17 e 18 (não restauradas). A pose do 19 ficou idêntica (desvio 0). Recuperação 19–52 refeita a partir dela: curva única de aceleração e desaceleração, partes defasadas (quadril primeiro, garra esquerda por último), chaves em 22, 26, 30, 34, 38, 42, 46, 49; pé esquerdo volta em 27–35 e o direito em 35–44, com arco. Variação máxima de velocidade por quadro em 19–52: cabeça 0,019 → 0,006 m, mão esquerda 0,080 → 0,013 m, mão direita 0,055 → 0,006 m; pé direito 0,054 → 0,051 m (sem ganho). Motion Lens em `evidence/attack_v2_swipe/lens_recuperacao_antes/` e `lens_recuperacao_depois/`: pausa pós-contato 0 → 5 quadros. Pendências que o Lens acusa e não foram mexidas: pé esquerdo desliza 0,258 m/quadro em 17–18 (sem as chaves apagadas), bote em 5 quadros, malha −0,075 m.


**Garra só toca o chão (2026-11-11):** no quadro 19 o braço esquerdo foi levantado até as garras ficarem a cerca de 1 cm do plano do chão (antes, 9 cm abaixo); só os ossos do braço esquerdo mudaram nessa pose, e a pausa e a recuperação (22–42) foram refeitas para o braço a partir dela. Motion Lens em `evidence/attack_v2_swipe/lens_garra_toca/`: malha −0,091 → −0,054 m. O que resta abaixo do chão são os **pés** na pose do quadro 19 do criador (até 5 cm, quadros 19–27); não alterado, aguardando decisão.


**Adaptação das edições do criador (aguardando aprovação):** as poses dele nos quadros 11, 15 e 19 ficaram idênticas (desvio 0 medido). Refeitos só os quadros em volta: pé esquerdo levanta no passo para trás (7), trajeto 16–18 com pés em arco e braço acelerando em degraus, pausa de impacto 19–26 recriada a partir da pose dele, recuperação 31–42 rebaseada nos pés dele, chave do quadro 4 removida. Motion Lens antes/depois em `evidence/attack_v2_swipe/lens_usuario/` e `lens_adaptado/`: deslizamento do pé esquerdo 0,364 → 0,036 m/quadro; golpe (efetor LeftHand) bote em 4 quadros OK, pausa de 5 quadros OK, antecipação dupla eliminada; malha −0,131 → −0,091 m (garras da pose do quadro 19 do criador entram 9 cm no chão, não alterado). Alertas de escala são do squash/smear autorizado.


**Segunda tentativa (aguardando aprovação):** Action `Attack 3 Lunging Claw Sweep` no mesmo `owl_attack_wide_swipe_v2.blend`, quadros 1–52 a 24 fps (2,17 s). Preparo 1–15 (corpo recolhe 0,19 m para trás e abaixa 0,17 m, tronco gira, garra armada), trajeto 16–18 (salto à frente, quadril avança 0,68 m do recolhido ao impacto, pé direito lidera), impacto no 19 (0,75 s) com squash do tronco e pose segurada até o 28, recuperação 28–52 (1,0 s) com dois passos de volta à origem. A primeira passada ficou guardada como `Attack 2 Wide Claw Swipe (reprovada)`. Folha: `evidence/attack_v2_swipe/poses_v3_corpo_inteiro.png`. Malha até 54 mm abaixo do chão no quadro 20. Motion Lens, vista espelhada e exportação não verificados.


Primeira passada criada em `assets/modelos/owl/blender/owl_attack_wide_swipe_v2.blend`, Action `Attack 2 Wide Claw Swipe`, quadros 1–38 a 24 fps (1,58 s). Garra esquerda em varredura ampla diagonal, de trás/alto à esquerda até baixo à direita: preparo 1–8, sustentação 8–11, arrasto 12, smear com escala no 13, overshoot no 14, assentamento 17–24, retorno 24–38. Pés sem deslizamento medido; malha até 35 mm abaixo do chão no quadro 14. Folha em `evidence/attack_v2_swipe/poses_primeira_passada.png`. Escolhas do assistente ainda não aprovadas: garra esquerda, direção diagonal, duração de 1,58 s. Falta sobreposição fina (garras, cabeça), Motion Lens e aprovação visual. `owl_attack_basic_v1.blend` em disco não foi alterado.
