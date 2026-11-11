# D-1138 — Animação de defesa da coruja

> vamos fazer a defesa, ela deve durar 3 segundos, 2 ativo, .5 de inicio e 1 de finalização

Ao confirmar a soma das fases, o criador escolheu: **“3 s, com finalização de 0,5 s”**.

> isso não tá um bloqueio de verdade, cace por referencias de street fighter 5 e 6

A v1 foi rejeitada. A revisão usa poses de bloqueio de Street Fighter V e VI como referência visual, mantendo as três fases e a duração aprovada.

> vc ao menos tá usando o motion lens? refaz isso direito

A v2 também precisa de revisão. O criador pede uso efetivo do Motion Lens na análise visual da nova versão. Produzir e abrir folhas de poses e silhuetas e curvas, além de analisar contatos e entrada/saída.

> mostra o rig dele pra eu editar a pose, ela está péssima e o personagem que usou não era o que devia, marisa faz uma pose melhor

A v3 foi rejeitada. O criador quer editar a pose manualmente com o rig visível, e indica Marisa como referência de defesa. As referências anteriores de Ryu, Ken e Vega não representam sua escolha de personagem para a pose.

> veja as mudanças que fiz e melhore a animação, não arruine o que eu fiz, só melhore o movimento até as mudanças e também faça ele ser mais inclinado, mais respirante, mais direto pra bloquear, tipo um snap rapido

Ao esclarecer a direção da inclinação, respondeu **“Para trás, absorvendo o golpe”**. Preservar a pose manual como alvo, melhorar a aproximação com snap rápido, adicionar respiração e inclinação para trás. Estado manual preservado em `owl_guard_user_pose_backup.blend` e pose do quadro 39 registrada antes de trocar o quadro.

> queria que ele se inclinasse também, o tronco na guard ativa pra melhorar o snap

Reforçar a inclinação posterior do tronco na chegada e durante a guarda ativa.

**Aprovação da v5 (2026-11-11):** o criador respondeu “perfeito”. Defesa aprovada no Blender. Integração ao jogo pendente.

V5 salva em `owl_guard_v5_torso_snap.blend`, Action `Guard 5 Torso Recoil`. Adicionados 10° de recuo na coluna/tórax durante a guarda, com pico de 12° ao fechar o bloqueio no quadro 5. Compensação de 4° na cabeça. Folha do Lens gerada e aberta em `evidence/guard_v5_lens/poses.png`; retorno ao primeiro quadro conferido. Aprovação visual pendente.

V4 salva em `owl_guard_v4_user_snap.blend`, Action `Guard 4 User Pose Snap Breathing`. As rotações locais de ombros, braços, antebraços, mãos e garras do criador foram preservadas durante a guarda. Entrada em snap entre 2 e 5, pequeno recuo em 8 e acomodação até 13. Inclinação posterior de 6,5° distribuída no quadril e coluna, com compensação de olhar; respiração de um ciclo em 2 s, até 4 mm de elevação e pequena expansão angular do tronco. Retorno ao idle no intervalo 61–73. Duração entre chaves mantida em 3 s. Folhas e gráficos do Motion Lens gerados, abertos e conferidos em `evidence/guard_v4_lens/`; pés sem deslize, alerta de velocidade alta em 4 correspondente ao snap solicitado. Mantém-se a pequena penetração de pele de -0,0062 m já observada. Aprovação da v4 pendente.

### V3 — revisão com Motion Lens

Salva em `owl_guard_v3.blend`, Action `Guard 3 Forearm Shield`. A guarda usa protração dos ombros, cotovelos sustentando os antebraços à frente e mãos afastadas da superfície do rosto. O movimento foi redistribuído nos 12 intervalos da entrada e da saída, com guarda mantida entre os quadros 13 e 61. Duração temporal entre os quadros 1 e 73 a 24 fps = 3 s.

Foram geradas e abertas as folhas do Motion Lens em `evidence/guard_v3_lens/`: `before_v2.png`, `after_v3.png` (frente, lado, topo), `after_v3_silhouette.png` e `after_v3_graphs.png`. Os relatórios anterior e posterior também estão nessa pasta. A inspeção encontrou atravessamentos do braço direito na cabeça e motivou a correção da posição do ombro e do cotovelo. A verificação final de interseções entre superfícies da cabeça e os antebraços/mãos/garras resultou em zero para ambos os braços na pose mantida. Retorno ao primeiro quadro com erro matricial zero e pés sem deslizamento no Lens. Persistem alertas baixos de pausa intencional e troca de sinal na representação de rotações, sem salto angular observado nas amostras. A menor altura de pele medida foi -0,0062 m em relação ao plano Z=0. Não integrado ao jogo.

As imagens de SF5 e SF6 foram efetivamente abertas no navegador nesta revisão: SF5 `https://assets.st-note.com/img/1670318717103-sBLEOMjteh.png?fit=bounds&height=2000&quality=85&width=2000` e SF6 `https://img.redbull.com/images/q_auto%2Cf_auto/redbullcom/2024/10/1/wt4pe4iuypjawi3zufeo/sf6-blocked-jump`. A primeira mostra defesa agachada com antebraço alto e braço transversal, e a segunda mostra Ken com cabeça recolhida atrás da guarda ao receber um golpe aéreo. São referências visuais para adaptação autoral. Aprovação da v3 pendente.

Referências pesquisadas: manual oficial de SFV, seção de guarda (`https://game.capcom.com/manual/sfv/en-uk/page-mb.html?cat=2&subcat=2`), imagens de bloqueio SFV e Ryu contra Marisa em SF6 (`https://kamigame.jp/streetfighter6/page/408419921547004957.html`). As páginas oficiais retornaram 403 ao abrir, embora a busca tenha localizado o conteúdo. A pose da coruja é uma adaptação autoral, sem transferência de animação desses jogos.

V2 salva em `owl_guard_v2.blend`, Action `Guard 2 High Block`: tronco em diagonal, um antebraço alto diante da cabeça, outro protegendo o tronco e peso recuado. Conferidas as vistas frontal, perfil e três quartos e o apoio dos pés com Motion Lens. Aprovação visual pendente.

O clipe da coruja tem 0,5 s para entrar na guarda, 2 s em guarda e 0,5 s para retornar à pose inicial. A decisão é sobre a animação no Blender. As regras de Guard no jogo seguem D-272 e D-1004.

Salvo em `assets/modelos/owl/blender/owl_guard_v1.blend`, Action `Guard 1 Braced Claws`. A 24 fps, os quadros 1, 13, 61 e 73 marcam o início, o começo da guarda ativa, o começo da finalização e o retorno à pose inicial. A pose foi conferida de frente, em três quartos e de perfil. O Motion Lens mediu zero deslizamento dos pés. Aprovação visual e integração no jogo pendentes.
