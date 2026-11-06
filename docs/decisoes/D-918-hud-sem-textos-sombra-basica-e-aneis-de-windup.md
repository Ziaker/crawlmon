# D-918 — HUD sem logo nem linha de título, sombra básica no lugar do anel ciano e anéis de wind-up mais baixos e centrados

> **Renumerada em 2026-11-06:** D-240 → D-918. O ID D-240 já pertence a outra decisão no `origin/main`; o conteúdo local foi preservado com o novo ID.


- **Data:** 2026-11-05
- **Área:** HUD / Visual / combate
- **Origem:** Conversa. O criador anexou recortes do HUD (a linha "ABRA / RECURSOS … ATB 04", o logo "CRAWL/MON", a linha "ALIADO / RECURSOS … ATB 05", um personagem com o anel ciano e dois anéis de wind-up) e escreveu:

> tem como remover esses textos e esse circulo ciano dos peronsagens e trocar por uma sombra básica de baixa qualidade, um circulo preto com pouca opacidade? inclusive diminuir a altura desses aneis e reposicionar eles corretamente pra ficarem bem no meio dos personagens quando realizam um wind up?

Antes disso, sobre os status: "as badges deviam ficar na região acima da barra de vida, fora da hud onde fica o icone barra e ettc".

## Decisão (interpretação aplicada; não confirmada ponto a ponto)

1. **Textos removidos:** o logo "CRAWL/MON" do canto da tela e, nos cartões do jogador e do aliado, a linha de título ("<NOME> / RECURSOS" e "ATB nn"). O contador "ATB nn" e o nome do recurso deixam de existir no HUD de batalha (a informação continua nas células de ATB do cartão).
2. **Badges (STUN, CEGO, GUARD, BURN…):** os dos cartões ficam **acima do corpo do cartão**, na faixa onde ficava a linha de título (fora do corpo do HUD), como já era na etiqueta do inimigo. BURN passa a ser uma badge igual às outras (revoga a posição "ao lado do nome" da D-917).
3. **Anel ciano → sombra básica:** o anel ciano que aparecia sob o personagem enquanto ele podia agir (`ReadyRing`) vira um **disco preto de baixa qualidade** (cilindro de 20 lados, preto, 32% de opacidade) **sempre presente** sob o personagem. O anel dourado do Burst (`BurstRing`) não foi mexido.
4. **Anéis de wind-up** (o anel de carga aos pés do atacante e os dois anéis da mira no alvo): **achatados** (escala de altura 0,22 em vez de 1) e **centrados onde o personagem realmente está** (a posição do modelo, que inclui o passo de "pronto"), e não no ponto de origem.

## Anel ainda mais fino (2026-11-05, frase do criador)

> o anel podia ficar ainda mais fino, sem perder sua largura e sua animação de fechamento

Aplicado só aos anéis de wind-up: a faixa do anel ficou com **metade da espessura** (raio interno 0,93 em vez de 0,85, o externo continua 1,0) e a altura caiu para 0,12 da original. O diâmetro e a animação de fechamento (a escala que encolhe durante o wind-up) são os mesmos.

## Investigação (sem mudança de código): por que o acerto do Pancham parece demorar

Pedido do criador: "investigue o por que as animações de ataque do pancham parecem demorar mais pra causar o dano do que o normal". Medido na sala de VFX (tempos em segundos depois do início do wind-up):

| Move | wind-up | corrida (TRAVEL) | espera no alvo (STRIKE) | acerto |
|---|---|---|---|---|
| Pancham Mach Punch | 0,2 | 0,37 | **0,87** | 1,45 |
| Pancham Karate Chop | 1,0 | 0,57 | **0,87** | 2,43 |
| Pancham Brick Break | 1,5 | 0,37 | **0,87** | 2,75 |
| Gible Bite | 1,2 | 0,93 | **0,87** | 3,00 |

- A fase STRIKE de **todo** golpe corpo a corpo dura `0,08 (antecipação) + 0,8` s. O 0,8 vem de `AttackPlanner.clip_hit()` = metade do comprimento do clipe `attack` limitado a 0,8 s (`clampf(len * 0.5, 0.25, 0.8)`). Os clipes `attack` medem 1,97 s (Abra), 1,77 s (Pancham) e 1,77 s (Gible); logo **todos caem no teto de 0,8 s**, não só o Pancham.
- A constante `BattleSpace.HIT_AT = 0,45` ("segundos dentro do clipe em que o golpe acerta") só é usada se o clipe não existir; com clipe ela é ignorada. O acerto está 0,35 s depois do valor previsto em `HIT_AT`.
- Medindo o clipe do Pancham (movimento dos ossos): o pico de movimento é em ~0,64 s e 50% do movimento acontece em ~0,72 s; nos quadros gravados ele levanta o braço (antecipação lenta) por ~0,6 s e o golpe cai perto de 2,4 s, junto com o dano (2,43 s). Ou seja, dano e animação estão sincronizados; o que parece "demora" é a antecipação longa do próprio clipe, depois do wind-up e da corrida.
- Por que o Pancham é o mais sentido: é o único do grupo só com golpes corpo a corpo e tem o Mach Punch (wind-up 0,2 s), um golpe "rápido" cujo acerto ainda espera 0,87 s depois de chegar (60% do tempo do golpe).
- **Não alterei nada**: mudar isso muda tempo de jogo (D-003). Opções para decidir: (a) usar `HIT_AT` (0,45 s) ou um ponto de contato medido por clipe em vez do teto de 0,8; (b) acelerar a antecipação do clipe `attack` (tocar mais rápido até o contato); (c) começar o clipe adiantado (pular o início da antecipação); (d) um tempo de acerto por Move, para o Mach Punch ser realmente rápido.

### Pergunta seguinte do criador: "todos personagens demoram o mesmo tempo pra realizar o tackle ou não?"

Medido com o Tackle básico (wind-up 1,5 s) em seis combinações de atacante e alvo (Abra, Pancham e Gible): o **wind-up** é igual (1,5 s) e a espera no alvo (**STRIKE**) também (0,87 s em todos, 0,88 no Abra/Gible mais distantes por arredondamento de quadros). Só a **corrida** muda, e muda **por distância** entre os dois (Abra↔Gible 1,10 s, Pancham↔Gible 0,93 s, Abra↔Pancham 0,72 s), igual nos dois sentidos: `Battle.travel_seconds` usa só a distância e os passos de posição, sem olhar a velocidade/AGI do personagem (D-136 ainda não implementada). Total do release até o acerto: 1,98 s (Abra→Gible), 1,80 s (Pancham→Gible), 1,59 s (Abra↔Pancham). A sala de VFX passou a listar o Tackle básico para essas medições.

## Ambiguidades em aberto

- Se "esses textos" incluía também o contador "ATB nn" (removido junto com a linha) e se o logo do canto deveria sair mesmo.
- Se a sombra deve existir só quando o personagem pode agir (como o anel) ou sempre (feito: sempre).
- Os anéis dos Moves do Abra e do Fire Bullet não são afetados (eles têm o próprio wind-up).

## Estado

Implementado; visto rodando na sala de VFX. Sem commit.
