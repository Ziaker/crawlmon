# D-272 — Guard: escudo de 1 ATB, ícone azul, hotkey Shift, quebrado pelo Brick Break

- **Data:** 2026-11-04
- **Área:** Combate / HUD / Game Feel
- **Origem:** pedido e respostas diretas do criador, na conversa.
- **Estado:** implementada na lógica, no HUD e no domo; **aguardando aprovação visual do criador**. A redução de dano é provisória.

## Declaração literal do criador

> Implemente uma opção nova, o guard, que usa 1ATB e coloca um ícone acima da vida do personagem/aliado/oponente de escudo azul assim como os outros status ailments, um bloco azul flat com ícone de escudo chamado guard

> Pra implementar isso eu também preciso que aumente a duração do hit stun em .30 segundos globalmente. Guard também tem hotkey própria e pode ser selecionado ao apertar pra direita (pra voltar pro dodge aperta pra esquerda) no dodge que mostra o bloco de seleção do guard q é um escudo com fundo azul flat do bloco ao invés de verde. Enquanto tiver trocado, apertar espaço faz com q o personagem realize o guard ao invés do dodge.

> O status de guard tem duração de 3 segundos, tem efeito visual de uma barreira domo repartido com degrade de opacidade que é destruído ao receber contato, reduzindo o dano em uma porcentagem com arredondamento pra cima baseada no atributo de status referente ao dano causado. Brick break/mold break tem um efeito de quebrar o mesmo e causar o dano normal do ataque, além de também receber 1ATB com sucesso

Correções do criador sobre o visual (depois de ver o jogo):

> tá minusculo, imperceptível, é pra ser uma cápsula assim só que deitada e na frente do personagem

> não é uma capsula literal vc não entendeu, é uma barreira na frente do personagem, metade dela

> é um C só que virado pra cima deitado, não sei como explicar direito

> (sobre o arco desenhado em verde por cima do Abra:) algo meio assim só que circular

> sim é esse só que um pouco maior e mais azul iluminado

> nao sei ainda n gostei desse visual ainda, eu aproximaria um pouco mais, vê se os 3 personagens tem alguma animação que possa ser utilizada como "defendendo"

> use o de charge,  coloque um pop-up de texto tipo o do MISS só que de GUARD acima da cabeeça do personagem (no personagem no caso da visão do jogador pro oponente, no oponente)

> (ajustar o Guard:) o texto do guard, poderia ser um azul com shader metálico que brilha na frente do escudo e quando ele sofre contato, as letras saem voando pra várias direções com gravidade, quicando no chão

> pôe o texto do guard acima do personagem ao invés de embaixo para ambos sentidos, faça videos mostrando, quanto ao impacto, eu queria que as letras voassem e quicassem no chão, inclusive vamos só usar um texto azul marinho claro com contraste facil de ler ao invés desses efeitos metalicos

> ok, mudança de planos, ao invés de quicarem, só são dispersadas, disparadas e somem após ,5 segundos com opacidade reduzida nos últimos .2 segundos dos .5

> além disso, eu preciso de mais contraste nas cores, mais claro pra cor do guard, letras um pouco menores, pense num assim marinho choque para ambos efeito visual do guard e pro texto

> não precisa de video

> (imagem de um seletor de cores com HEX #2bd8ff, RGB 43, 216, 255:) uma cor mais assim

> e sem bordas no texto

> nenhum, o problema não é a cor, é a fonte e o design do escudo

> ok, ao invés de uma barreira, vamos com um escudo de verdade, branco com opacidade reduzida pra conseguir ver o personagem, com o guard encima dele

> pq o texto ta azul? é pra estar branco com os efeitos que tu fez aqui pro texto, além de também ter uma animação do escudo surgindo, se construindo, sem bordas, tudo flat

> o escudo é pra estar na frente do personagem, não encima dele, da mesma forma que a barreira era

> me proponha melhorias para o efeito visual do escudo em si, inclusive não descarte aquela barreira, usaremos ela pra um eventual move de protect

> As 4 principais

(As quatro: emblema interno chapado, escudo girado em direção à câmera, flash + cacos irregulares ao quebrar, e escudo que "drena" da ponta para cima durante os 2 s.)

> volte atrás com tudo exceto o 3 e o 4, quanto ao 4 acho melhor ele rachar do que sumir gradualmente

> não gostei desse estilo de rachadura, algo mais linhas retas é melhor

> linhas retas sem bifurcações, algo meio pizza pq o escudo se quebra em triangulos ja

> eu gostava quando tinha mais fatias

> é volta atrás, prosseguiremos com a última mensagem, cheque em video para ambos pancham e gibble e a espelhada (gibble vs os 2 ao invés do oposto)

(Respondendo "o que volta atrás nas fatias?": 8 fatias.)

Respostas às perguntas do assistente:

> (hit stun) Recuo/cambaleio do alvo
> (hotkey) Shift
> (redução de dano) Valor provisório seu
> (mold break) Mold break é uma abilidade futura só deixe isso registrado, brick break é o golpe q vai ganhar a trait
> (valor da redução) Você escolhe
> (quando ativar) Não é um buff, é uma ação que te impede de realizar outras até cancelar ou quebrar, inclusive ao receber contato, não sofre o hitstun do cambaleio
> (status de alvo único) Não, só dano
> (IA) Sim, aliados e inimigos
> (cancelar) Na verdade não pode cancelar mudei de ideia, mas reduz a duração pra 2 segundos
> (devolver ATB) Não devolve
> (ATB durante o Guard) Pausa
> (Burst) Burst não pode ser usado pra guard

## Regra aprovada

- **Atualizações finais do criador:** duração **2 s** (não 3); **sem cancelamento**; o 1 ATB **não é devolvido**; o **ATB do personagem pausa durante o Guard**; **Burst não paga o Guard** (só 1 ATB).

- Nova ação **Guard**, custo **1 ATB**.
- Aparece como **status** acima da vida de personagem, aliado e oponente, como os demais status ailments: **bloco azul flat com ícone de escudo e o nome "Guard"**.
- **Hotkey própria: Shift.**
- No bloco do **Dodge**, apertar **direita** troca a seleção para o **Guard** (bloco com **escudo sobre fundo azul flat**, em vez do verde); apertar **esquerda** volta ao Dodge. Enquanto o Guard estiver selecionado, **Space executa o Guard** em vez do Dodge.
- O Guard **não é um buff**: é uma **ação** que **impede o personagem de realizar outras ações até o Guard expirar (2 s) ou ser quebrado**; também termina ao **receber contato**. Pode ser ativado a qualquer momento em que se tenha o ATB. Dura **2 segundos** (reduzida de 3 s pelo criador). **Não pode ser cancelado** pelo jogador.
- **Animação:** nenhum dos três (Abra, Pancham, Gible) tem clipe de defesa; durante o Guard o personagem toca o clipe **`charge`** em loop (a pose agachada do preparo) e volta ao idle quando o Guard acaba.
- **Texto GUARD (versão atual):** as letras **GUARD** ficam **em cima do escudo**, **brancas**, fonte **Impact** do HUD, sem borda, e aparecem uma a uma. **Ao contato**, o escudo **se quebra em pedaços** e as letras **são disparadas em leque, com gravidade, sem quicar**, e **somem em 0,5 s** com a **opacidade caindo nos últimos 0,2 s**. Se o Guard só expira, escudo e letras desvanecem.
- A cúpula fica mais **perto do corpo** (base puxada para trás do peito).
- Ao receber contato, o personagem em Guard **não sofre o recuo/cambaleio** (o hit stun de +0,30 s não se aplica a ele).
- **Só golpes com dano** interagem com o Guard; golpes de status de alvo único continuam não bloqueados (D-012).
- **A IA usa o Guard**, aliados e inimigos (simetria, D-021).
- O **valor provisório** da redução de dano é escolhido pelo assistente, deixado como constante fácil de trocar e mostrado ao criador antes de seguir.
- **Visual atual (2026-11-04), substitui a barreira/cúpula:** um **escudo de verdade** (brasão com topo reto e ponta embaixo), **branco com opacidade reduzida**, **chapado (flat), sem bordas e sem degradê**, **em pé na frente do personagem, voltado para o oponente** (do jogador, do aliado ou do oponente), com a ponta tocando o chão, **da mesma forma que a barreira ficava** (não sobre o personagem). **Animação de surgimento:** o escudo se constrói (pedaços em cunha deslizam de fora e se montam, em ~0,4 s). **Detalhes mantidos das melhorias (2026-11-05):** (3) ao contato, **flash branco de 0,08 s e quebra nas fatias de pizza**; (4) em vez de sumir gradualmente, o escudo **racha**: rachaduras **em linhas retas, sem bifurcações, estilo pizza**: 8 linhas saindo do centro até a borda (o criador pediu para voltar às 8 fatias depois de testar 16), aparecem e crescem ao longo dos 2 s do Guard e, quando o tempo acaba, ele **quebra nas mesmas fatias** (8 pedaços triangulares, cortados exatamente sobre as rachaduras) (só o fade acontece no fim da batalha). **Desfeitos a pedido:** o emblema interno e o giro de 35° para a câmera. Versões descartadas: cúpula (guardada, D-273), cápsula, parede em C, cocho em U, casca hexagonal, escudo com borda, escudo sobre o personagem, emblema interno, escudo girado, drenagem.
- Ao receber contato, o Guard **reduz o dano em uma porcentagem, arredondada para cima**, baseada no **atributo de status referente ao dano causado** (VIT para físico, SPI para mágico, D-130/D-138).
- **Brick Break** quebra o Guard, causa o **dano normal** do ataque (sem redução) e dá **1 ATB** a quem o usa, quando quebra com sucesso. O **Brick Break é o Move que ganha essa trait**.
- **Mold Break** é uma **habilidade futura**; fica apenas registrada, sem implementação nem efeito agora.
- **Hit stun:** a duração do **recuo/cambaleio do alvo** ao receber um golpe aumenta em **0,30 s, globalmente** (todos os golpes, todos os personagens).

## Ambiguidades em aberto (perguntar antes de agir)

- Se o Guard dá recompensa de ATB ou Burst ao absorver um golpe (exceto o 1 ATB do Brick Break).
- Como o "AoE" interage com o domo: um domo por personagem, destruído pelo primeiro contato dele.

## Estado no código

Implementado (2026-11-04): `Battle.use_guard` / `can_guard` / `guard_block_reason`, `Combatant.guard_timer` / `is_guarding`, dano em `Battle._hit`, hotkey `guard` (Shift) em `GameState`, bloco azul em `FanMenu`/`battle_scene.gd`, badge `🛡 GUARD` em `battle_hud.gd`, domo em `scripts/combat/fx/fx_guard.gd`, hit stun `AttackMotion.HIT_STUN_EXTRA = 0.30`. Teste: `tests/battle/test_d272_guard.gd`.

Escolhas do assistente que o criador deve confirmar:
- **Redução provisória de 50%** (`Battle.GUARD_REDUCTION`), igual para dano físico e mágico até VIT/SPI existirem.
- "Arredondamento para cima" aplicado ao **dano final**: `ceil(dano × (1 − redução))`, mínimo 1.
- O Brick Break é identificado pelo id `quebra_telha` (`Battle.GUARD_BREAKERS`).
- Efeitos secundários de contato (Karate Chop −1 VEL, Mordida atordoa) **continuam como antes** quando o alvo está em Guard.
- O Guard não pode ser ativado engajado, em ação própria, atordoado ou durante pausa de status.
- IA: um alvo controlado pela IA com reação Esquiva sorteia o Guard com 25% de chance quando um ataque é declarado contra ele (`Battle.AI_GUARD_CHANCE`).
- Hit stun +0,30 s aplicado em: `HIT_HOLD` (recuo de quem é interrompido), retorno de conjuração interrompida (0,55 s) e a animação de reação do alvo (`_hit_react`). Quem está em Guard não sofre o recuo.
- Shift sozinho dispara o Guard; no painel de debug, Shift+tecla também o aciona.

> **Renumeração (2026-11-05):** este registro foi criado localmente com outro número (D-19x) que colidia com as decisões das Rodadas 68-82 do GitHub (D-192 a D-268). Por escolha do criador passou a ser **D-272**; texto e regras não mudaram.
