# D-1205 — Knock-up: o impulso para cima do Dig vira um status (stun com outro nome) e o contato aplica knockback visual para trás

> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** Teste sempre no debug (`vfx_room`), com dados, em menos de 1 minuto.

- **Data:** 2026-11-13.
- **Área:** Combate / status / Dig.
- **Relacionadas:** D-1196 (Dig A), D-977/D-980 (STUN), D-134 (chance de status), D-1049 (knockback visual).
- **Status:** implementado, aguardando verificação do criador.

## O que o criador disse (literal)

> "faz o impulso pra cima do uppercut também aplicar um impulso pra trás pro boneco não ficar preso um dentro do outro"

> "alem disso vamos tratar esse impulso pra cima como um efeito de status chamado de Knock-up que é basicamente um stun"

Respostas às perguntas:
- Impulso para trás: **"o contato entre ambos, quando causar dano, ele aplica o knockback visual pra trás junto com o knock-up"**.
- Duração do Knock-up: **"Tempo do voo do alvo (recomendação)"** (~0,8 s = 2 × 8,8 m/s ÷ gravidade 22 do HTML).
- Regras: **"STUN com outro nome (recomendação)"** (não age, ATB pausado, interrompe wind-up, sem Evade).
- Aplicação: **"Sempre que acerta (recomendação)"** (sem chance nem resistência; ARMOR bloqueia como no STUN do Electric Beam).

## Decisão

1. `Combatant.stun_kind` (`""` = STUN, `"knockup"`): mesmo `stun_timer` e as mesmas regras do STUN; só o nome exibido (KNOCK-UP) e o visual mudam (sem estrelinhas, o corpo está no ar).
2. O Dig aplica Knock-up de 0,8 s a cada acerto (regra própria `MoveBehaviors.Dig`).
3. O knockback visual padrão volta ao Dig (`visual_push` removido) e soma com o knock-up.

## Pendente / observação

- O knockback visual padrão devolve o alvo ao ponto de origem ~0,95 s depois do acerto, enquanto o Dig fica parado 1,38 s em cima desse ponto: pode haver um breve cruzamento no fim. Não foi pedido tratar.

## Correções (2026-11-13)

> "não, o knock-up pra trás tem que ser suave, não simplesmente trocar a posição do personagem" / "a camera fica super bugada, só não faça ela se mover quando isso acontece"

- Recuo suave: o alvo anda 2,6 m (`STAND_GAP`) ao longo do eixo atacante→alvo durante o voo (0,8 s, ease-out), fica lá enquanto o Dig está parado e volta (smoothstep) junto com o pulo de volta dele. O empurrão padrão do jogo (0,11 s) fica desligado no Dig (`visual_push = 0`). A distância de 2,6 m é escolha da IA (a distância de contato normal do Move).
- Câmera: sem tremor de acerto nem linhas de velocidade no Dig; o enquadramento de área segura usa o ponto de repouso do Dig e do alvo, não o corpo no ar (`FxDig.anchor`). O movimento normal da câmera de ataque (vista de ação no início, volta ao cinema depois) não foi alterado.

## Ajustes finos (2026-11-13)

> "reduz pra 1 metro de deslocamento" / "aumente a gravidade de descida, o personagem está voando ao invés de cair suavemente rapidamente, com maior aceleração vertical" / "faça com que o POV seja aumentado durante pra poder ver o personagem"

- Recuo fixo de 1 m, linear no tempo durante o voo (arco suave).
- Gravidade de descida 48 (subida continua 22; o 48 é escolha da IA, ~2,2x): o voo cai de 0,8 s para 0,67 s, e o Knock-up passa a durar 0,67 s (tempo do voo).
- FOV +15° durante o knock-up e a parada do Dig (`BattleCamera.fov_boost_target`, entra e sai suave; o 15° é escolha da IA).

## Recuos (2026-11-13, 2ª rodada)

> "o deslocamento horizontal agora está mt pequeno, aumente pra 2.5 metros, faça com que o impacto também empurre o atacante pro oposto da direção do oponente, no caso pra tras no pov dele em 1.5 metros"

- Recuo do alvo: 2,5 m (substitui o 1 m). Recuo do atacante: 1,5 m para trás (oposto ao oponente), em arco suave durante o uppercut; ele fica parado aí por 1 s e pula de volta a partir desse ponto.

## Genérico para qualquer Move + Knock-up de 1,3 s (2026-11-13)

> "coisas globais assim não são variáveis fáceis de mudar como valores? não era pra teoricamente ser só trocar 1 número e pronto?" / "tem que sempre pensar amplamente para outros moves também usarem a variável" / "a duração do stun do knock-up tem que ser exatamente o mesmo tempo que ele fica airborne ... subir um pouco mais por 1.3 segundos ... isso também inclui a caída"

- **Tudo virou campo do `MoveData`** (0 = desligado), valendo para qualquer Move, sem código novo: `knockup_height`, `knockup_air_time`, `knockup_gravity_down`, `knockup_shudder`, `target_push`, `attacker_push`, `push_return_at`, `push_return_time`, `impact_fov_boost`, `camera_still_on_hit`. O Dig usa: altura 3,0 m, 1,3 s no ar, queda 48, tremor 0,68 s, recuo do alvo 2,5 m, do atacante 1,5 m, volta em 1,38 s durante 0,57 s, FOV +15°, câmera parada.
- **O tempo no ar é o do status**: `knockup_air_time` (subida + queda, 1,3 s) é a duração do Knock-up. O voo é desenhado a partir do próprio `stun_timer`, então o alvo pousa exatamente quando o status acaba (medido: pico 3,0 m, y = 0 quando stun = 0). A subida sai do tempo e da altura (v = 2h/subida, g = v/subida); a queda usa `knockup_gravity_down`. A altura de 3,0 m é escolha da IA (antes 1,76 m).
- Código: `FxKnock` (genérico, chamado pelo `BattleFx.play_hit` com o MoveData do Move que acertou), `MoveBehavior._apply_knockup` (status, na base: qualquer Move), `BattleFx.camera_anchor`. `FxDig` ficou só com a coreografia do HTML (corpo, tremores, erupção).

## Giro, vento, pouso e parábola contínua (2026-11-13)

> "faça o personagem que leva o air borne fique rodando no próprio eixo em alta velocidade, inclusive eu queria que tivesse um efeito visual pra isso, ventos em forma de círculo rapidamente animados. inclusive ao chegar no chão causar um impactozinho com shake e um anel de poeira" / "não é pra ele ficar VOANDO no ar, é pra ele estar indo pra cima pelo início da duração e caindo até o final da duração" / "corrige também do atacante após finalizar o ataque ficar realizando a animação de corrida ao invés de ficar no idle depois de aterrisar"

- Novos campos do `MoveData` (valem para qualquer Move): `knockup_spin_turns` (voltas inteiras no voo; Dig 5, termina alinhado), `knockup_wind` (3 anéis de vento com o shader `wind_swirl`), `knockup_landing_dust` (raio do anel de poeira ao pousar; Dig 1,0 m) e `knockup_landing_shake` (tremor de câmera do pouso; Dig 0,6). Os valores do Dig e as cores/tamanhos do vento são escolhas da IA.
- Parábola contínua: o Dig usa `knockup_gravity_down = 14.2` (= 8h/T²), então o ápice fica na metade do tempo (3,0 m em 0,65 s) e o alvo sobe no começo e cai até o fim, sem pairar. Antes: gravidade de queda 48 e subida lenta, que parecia voar.
- Depois de aterrissar do uppercut, o atacante volta ao idle (`battle_idle`) em vez de continuar a animação de corrida.

## Roda, não pião (2026-11-13)

> "ele tá girando, é pra na verdade ele rodar, como uma roda, o efeito também ser arcos de vento rodando junto"

- O Knock-up agora gira como uma roda (cambalhota): em volta do eixo lateral ao recuo (`UP × direção do recuo`), pelo centro do corpo, em voltas inteiras (`knockup_spin_turns`), terminando alinhado ao pousar. Antes girava como pião no eixo vertical.
- O vento são arcos de vento no plano da cambalhota (3 faixas com riscos longos, eixo = eixo lateral) que giram junto com o corpo, um pouco mais rápido que ele.

## Escala do vento, rotação por duração e animação de dano (2026-11-13)

> "o efeito visual está mt maior e muito mais rápido que o personagem, faça ele escalar com o tamanho do modelo do personagem e a velocidade de rotação ser baseada na duração, ficando menos rápida quanto mais chega perto do chão, pra aterrisar 'de pé'" / "ao aterrisar, faça o personagem continuar sua animação de caída/dano, travando ela no contato e a finalizando depois de aterrisar"

- O vento escala com o personagem: raio = meia diagonal do corpo medida dos meshes reais (altura x largura), faixa fina, e gira exatamente junto com o corpo (antes era maior e 12-24% mais rápido; os riscos quase não correm sozinhos).
- Rotação pela duração: o ângulo segue ease-out (`1 - (1-k)²`): rápida no início, a velocidade chega a zero ao tocar o chão, com número inteiro de voltas, então ele aterrissa de pé.
- Animação de dano: trava no pose de contato (0,08 s depois do acerto) durante o voo e é solta no pouso, terminando o clipe e só então voltando ao idle. Se outro sistema trocar o clipe durante o voo, o dano é devolvido no mesmo ponto. Medido: `anim=damage speed=0.00 pos=0.07` durante todo o voo; `speed=1.04` e pos 0,07→0,67 depois do pouso.

## Recuo ao contato (2026-11-13)

> "vamos aumentar pra 2M o deslocamento horizontal ao contato"

- Lido como o recuo do atacante (`attacker_push`): 1,5 m -> 2,0 m. O recuo do alvo (`target_push`) já era 2,5 m e ficou como está. Se o pedido era outro deslocamento, é só trocar o número no `move.tres`.

> "então 3.5 no caso do alvo"

- Recuo do alvo (`target_push`): 2,5 m -> 3,5 m. Atacante fica em 2,0 m.

## Move finalizado e próximo passo (2026-11-13)

> "perfeito, considero o move finalizado" / "agora eu quero que mande o deepseek fazer um protótipo do efeito visual no cartão e eco textual para o knock-up, estou pensando no próprio cartão pular pra cima também com um efeito de setas pra cima, e o eco textual ser as letras saindo do personagem todas separadas e depois se juntando com um efeito de hit de quadrinho. mande ele dar 3 opções pra ambos no protótipo"

- O Dig (A) está finalizado pelo criador.
- Em andamento: protótipo HTML `prototypes/knockup_card_eco/index.html` com 3 opções para o cartão (pula com a parábola do voo + setas para cima) e 3 para o eco textual (letras separadas que se juntam com hit de quadrinho). Pendente: ele escolher; o código do jogo só muda depois. Conflito exposto: D-1061 (eco sem bordas, chapado) x a imagem de referência com contorno preto; o protótipo traz opções dos dois lados.

## Escolha do eco textual (2026-11-13)

> "opção 1 pro eco textual, já o cartão está péssimo e sem criatividade"

- Eco textual do Knock-up: **opção 1** do protótipo (letras amarelas chapadas, sem borda, que saem separadas do personagem e se juntam com uma estrela coral chapada). Não implementado ainda no jogo.
- Cartão: as 3 opções foram recusadas ("péssimo e sem criatividade"); novas opções em protótipo, pendentes.

## Rodada: cartões escolhidos e plano de implementação

> "THrown slab do conceito anterior e trapdoor slam do conceito novo, quero os 2 no jogo junto com o conceito aprovado do eco textual"

- Cartão que recebe o efeito: **cartão do alvo na HUD** (`UnitCard` do aliado e `EnemyTag` do inimigo), com o selo KNOCK-UP; escolhido por ele (opção "Cartão do alvo na HUD").
- Os dois efeitos (Thrown Slab de `cartao_v2.html`, Trapdoor Slam de `cartao_v3.html`) entram no jogo; sobre combiná-los, o criador disse: "no caso de querer os 2 junto eu digo pra ver in-game qual fica melhor". Logo: os dois ficam selecionáveis no jogo (campo `card_style` no MoveData + troca de teste no debug) e ele decide qual fica em cada Move depois de ver.
- Eco textual: opção 1 (letras separadas que se juntam, amarelo chapado, sem borda).
- Plano: (1) DeepSeek: encanamento (campo no MoveData, estado do cartão no HUD, controle de debug para alternar o estilo); (2) Claude: a camada visual (pose do cartão por estilo, eco textual); (3) conferir na sala de debug nas duas vistas.

## Rodada: Trapdoor Slam no Dig; eco mais rápido e mais alto

> "vamos com o trapdoor slam então, além disso o eco textual tem que ser mais rápido ainda e surgir um pouco mais pra cima"

- Dig (`investida_escavadora`): `card_style = trapdoor_slam`. Thrown Slab continua disponível para outro Move (`card_style = thrown_slab`).
- Eco textual: `KnockEcho.SPEED` (2.0 = toca 2x mais rápido que o voo, ~0,65 s) e `KnockEcho.RAISE` (1,1 tamanhos de letra acima da cabeça). Os dois números são palpite meu; ele ainda não os aprovou.
