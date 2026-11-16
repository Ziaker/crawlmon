# D-1209 — Karate Chop e Brick Break: opção A do HTML "toon construct", mão holograma branca, sem prisma

- **Data:** 2026-11-14.
- **Área:** VFX de Move / combate.
- **Relacionadas:** D-235, D-280, D-308, D-1030, D-1208, D-1196, D-1154, D-1204.
- **Status:** registrado; implementação a seguir (DeepSeek no código, Claude no visual e nas fichas).

## O que o criador disse (literal)

Arquivo: `brawlmon_crawlmon_3d_atb_babylon_js_vfx_atelier_karate_chop_brick_break_toon_construct (1).html`.

> "Vamos usar ambas opções A para trazer para o jogo, mas obviamente tendo a mais perfeita noção de que usaremos algum modelo de mão toon (ou que já temos do fire bullet se necessário) em forma de holograma físico com minuscula opacidade e shader marrom para seus efeitos especiais" / "eu quero que me surpreenda, use as sua skill de co-criador, lhe dou liberdade criativa para cada fase do move, desde que siga o conceito presente neste HTML." / "deixe 90% do código pro deepseek realizar, vc deve criar a parte visual e corrigir as descrições e efeitos escritos e descritos dos moves em suas fichas dentro do jogo"

Respostas:
- Tempos (HTML x jogo): **"pense no balanceamento destes dois moves, siga sua recomendação mais balanceada"**.
- Prisma espiritual do Brick Break: **"ele nem devia existir no geral"**.
- Cor: **"acho que ambos serem brancos é melhor"** (substitui o shader marrom do pedido inicial).

## Decisão

1. Karate Chop = opção A do HTML (`shuto`, corte diagonal -38°). Brick Break = opção A (`palmcrush`, palma para baixo), **sem o prisma** (nada de prisma, placa ou barreira no alvo).
2. Mão toon em forma de holograma, de opacidade mínima, **branca** nos dois Moves (a mão do Fire Bullet pode ser reaproveitada). Efeitos do Move também brancos, sem ciano, âmbar, vermelho nem marrom.
3. Balanceamento: a recomendação adotada é **não mexer na mecânica**: wind-up (1,0 s e 1,5 s), espera no alvo de 0,53 s, custo, dano e `run_offset` (D-1208) ficam como estão; as fases do HTML são esticadas para caber nesses tempos (D-280).
4. Liberdade criativa de cada fase (wind-up, release, trajeto, impacto) dentro do conceito do HTML; as fichas escritas (efeito, visual, movimento, fases) são corrigidas para o que o jogo realmente faz.

## Escolhas da IA (o criador pode mudar)

Opacidade base da mão, tom exato do branco, escalas e tempos internos das fases.

## Rodada de 2026-11-14 (depois de ver o Karate Chop no jogo)

> "tira esse zoom, ele mais atraplha que ajuda, já não da pra ver nada com ele imagina sem, simplesmente NÃO DA PRA VER NADA" / "vamos voltar com a mão e o efeito visual do ataque sendo marrom" / "o pulo que o personagem dá pra realizar o golpe ocorre antes mesmo dele chegar, corrija isso" / "força o deepseek a auditoriar por completo, perfeitamente o HTML novamente, e o faça recriar o efeito novamente com a mão no mínimo 70% maior"

- **Cor: volta a ser MARROM** (a mão e o efeito do ataque), substituindo o "ambos brancos" desta decisão. O tom exato é escolha da IA (mão `#b57a45`, brilho `#e0a86b`).
- **Zoom removido** nos dois Moves (Karate Chop e Brick Break, escolha da IA para o escopo): sem borrão radial/aberração de tela no acerto (`no_screen_post`), sem tremor de câmera e sem linhas de velocidade (`camera_still_on_hit`).
- **Pulo do Karate Chop** acontece no alvo (no STRIKE, pousando no contato), não durante a corrida.
- **Mão no mínimo 70% maior** que a versão anterior (escala da mão x1,7 ou mais); o DeepSeek reaudita o HTML por completo e recria o efeito.

## Rodada 3 (2026-11-14)

> "deixe tudo em branco, o posicionamento do impacto está muito abaixo do que deveria, é pra estar perfeitamente no centro do alvo, a mão some no segundo que acerta ao invés de ficar presente durante o pós impacto, sumindo lentamente após o ataque por .85 segundos" / "além de também deixar a mão 40% maior" / "o ataque tem que ocorrer durante o pulo e o pulo tem que ter uma duração maior, o personagem só aterrisa durante o pós impacto" / "pq a mão some durante o trajeto? não é pra NADA SUMIR DURANTE O TRAJETO, NENHUM MOVE DEVE SUMIR DURANTE O TRAJETO"

- **Cor: tudo BRANCO** de novo (mão e efeito do ataque), substituindo o marrom da rodada anterior.
- **Impacto e corte no centro exato do alvo** (centro da caixa real do corpo), não abaixo.
- **A mão fica depois do acerto** e some devagar por **0,85 s** (dissolve), mesmo depois de o Move terminar.
- **Mão 40% maior** (x1,4 sobre a versão de 0,9 x altura do atacante): passa dos 2,5 m da D-1033 por ordem do criador.
- **Pulo do Karate Chop:** um arco só, mais longo: o corte acontece com o corpo no ar e ele só aterrissa no pós-impacto (fim do hold).
- **Nada some durante o trajeto:** a mão estava desenhada invisível no TRAVEL (bug meu); corrigido. A regra do criador vale para todo Move; Moves que escondem o corpo no trajeto por desenho (Investida Subterrânea/Dig) ficam pendentes de confirmação dele.

## Rodada 4 (2026-11-14): movimento da mão e legibilidade

> "a opacidade da mão é parte do problema, está mt pequena e suas dobras e partes não tem um outline" / "o prelude é inexistente, a mão deve ir até o ponto diagonal superior direito do alvo e então, no impacto realizar um corte completo em diagonal, durante esse prelude a mão devia expandir de tamanho proceduralmente até atingir +.35x seu tamanho" / "a mão está SUMINDO no impacto ... ela deve, depois do ataque, desacelerar lentamente e sumir lentamente" / "durante o trajeto a palma deve estar 'correndo' junto com o personagem dando 'passos' pulando no caminho e então, ao pular, ela se apronta, levantando alto e realiza o ataque em diagonal completo, terminando recebendo um atrito e desaceleração após o impacto e sumindo lentamente após o personagem aterrisar."

- Legibilidade: preenchimento mais opaco (0,55) e contorno branco por casco invertido (`holo_hand_outline.gdshader`), cada dedo/palma/polegar com linha própria (valores da IA).
- Coreografia: WINDUP forma no ombro; TRAVEL a mão corre junto ao corpo saltando a cada passo (período = clipe `run` / 2, altura 0,10 x altura do atacante); no salto ela se apronta e sobe alto até o canto superior direito do alvo crescendo x1,35, armada 0,25 s antes do corte; corte diagonal completo de 0,16 s; atrito e desaceleração depois do impacto; visível até o pouso e só então some em 0,85 s.
- Base de dados (Motion Lens do Arenamon, clipe `attack`, 24 fps): Abra e Pancham sobem o braço, ficam armados ~0,17-0,25 s, dão um chicote de ~0,17 s (Abra pico 10,9 m/s, Pancham 5,9 m/s), param em 1 quadro e derivam devagar. Valores 0,25 s e 0,16 s vêm daí; escolha da IA.
- A mão some no impacto por `inc.interrupted` (melee que já bateu e leva golpe) e pelo DONE no contato; corrigido: o acerto nunca cancela a mão.

## Rodada 5 (2026-11-15): criador desiste do Move

> "DESISTO DESSE MOVE"

Trabalho no Karate Chop e no Brick Break (D-1209) **parado por ordem do criador**. Estado deixado: mão holograma do Karate Chop ainda ligada no código (`fx_martial.gd`), Brick Break sem o efeito novo, nada commitado. Ferramentas criadas e mantidas (D-1218): evento `martial_hand`, `tools/vfx/check_martial_hand.py`, `--shot-at-stage`. O que fazer com a mão ligada (manter, desligar ou remover) fica pendente da decisão dele.
