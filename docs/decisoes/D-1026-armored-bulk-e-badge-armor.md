# D-1026 — Armored Bulk e a badge Armor

- **Data:** 2026-11-09.
- **Área:** Combate / Moves / Status / VFX.
- **Origem:** conversa. Brainstorm de um Move genérico novo para Orc e Cyclops.

## Frase literal do criador

> Armored Bulk - 10MP/1ATB/STATUS/SELF/TERRA/INSTANT wind up
>
> Mecânicamente: Os musculos do usuário se flexionam e pressionam-se a ponto de se metalizarem, ganhando ARMOR por 8 segundos.
>
> visualmente: Você define 3 opções de como será o start e o release do move (como o wind-up é rapido, o start e o release vão estar interconectados)
>
> ARMOR (Badge positiva de status nova de cor cinza e visual metálico) : Personagens sob o efeito de armor não sofrem interrupção ao sofrerem a primeira instância de dano com a badge, destruindo a badge no processo caso receberem dano advindo de moves (não é destruido contra efeitos de status como poison e burn). Se tornando ímunes a efeitos causados por contato e impacto com a badge ativa (pro exemplo, um move que, ao contato, cause Stun por 4 segundos: A badge é removida, o dano é sofrido ainda mas o efeito de stun não é causado)
>
> animação: Animação de vitória do personagem
> efeito visual no modelo causado pela badge: Envolto em um filtro de textura cromada de baixa opacidade, não obstruindo a textura completa do personagem

Respostas do criador à rodada de perguntas:

> vamos com a opção A por ora
> 1 - guard tem maior prioridade e não desliga a badge
> 2 - sim impede qualquer tipo de knockback exceto o de KO.
> 3 - sim
> 4 - como confirmado acima, guard tem maior prioridade e não desliga a badge ao sofrer contato
> 5 - adiciona + 8 segundos ao tempo restante apenas, não stacka badge
> 6 - sigo sua recomendação criativa
> 7 - sim e sim
> 8 - não
> 9 - algum ícone de armadura? algo como um capacete ou um peitoral  de armadura
> 10 - todo efeito de duração pausa quando outro aciona a pausa, isso é regra definida não?
> 11 - sim, inclusive pancham poderá aprender também
> 12 - inteiro

## Decisão

1. **Armored Bulk:** 10 MP, 1 ATB, STATUS, SELF, elemento TERRA, wind-up instantâneo. Move genérico por `move_id` (D-235): Orc e Cyclops o têm agora; Pancham o aprenderá por nível, mas fica fora por ora; comportamento idêntico em qualquer personagem, time e lado.
2. **Efeito:** concede a badge **ARMOR** por 8 s ao usuário.
3. **Recast:** soma +8 s ao tempo restante; a badge não acumula.
4. **ARMOR** (badge positiva nova, cinza, visual metálico):
   - No primeiro dano de Move recebido com a badge: sem interrupção (sem hit stun/cambaleio), a badge é destruída e o dano é sofrido normalmente.
   - Anula efeitos de contato e impacto (ex.: o STUN de 4 s não é aplicado, e a badge é consumida) e **qualquer knockback, exceto o de KO**.
   - Dano de status (poison, burn) não consome a badge.
   - **Guard tem prioridade:** com Guard ativo, a Armor não é consumida ao sofrer contato.
   - AoE: cada alvo consome a própria Armor no seu primeiro contato.
5. **Burst não paga** o Move.
6. **Animação:** clipe de vitória do personagem (DQT clipe 02 `victory`), **inteiro**. Pancham: clipe de vitória dele, a verificar.
7. **Visual no modelo:** filtro cromado de baixa opacidade, sem cobrir a textura.
8. **Start/Release:** opção A, "Flexão e Cromagem de baixo para cima": o usuário se agacha e contrai; uma onda de cromo sobe dos pés à cabeça com a fronteira brilhante; no release, anel de choque raso no chão e faíscas metálicas curtas; o cromo assenta no filtro da badge. Aprovada "por ora".
9. **Pausa:** efeitos de duração (a Armor de 8 s) pausam quando o motor é pausado por outro status (D-031). O criador perguntou se isso já é regra; a verificar no código.

## Segunda rodada de respostas

> 1 Sim
> 2 1,5s
> 3 sim
> 4 sim, inclusive sua duração também continua a reduzir normalmente
> 5 sim, mas não usaremos com ele ainda então o ignore por ora, só deixe registrado q ele aprende upando de nível, não precisa perguntar que nivel

10. **IA:** usa Armored Bulk quando tem 1 ATB sobrando e há golpe com efeito de contato forte vindo, sem Armor ativa (proposta do assistente, aprovada com "Sim").
11. **Pausa do Move:** o Armored Bulk pausa o motor por **1,5 s** (D-031: 0,5 s de preparo + 1,0 s de efeito), mesmo com wind-up instantâneo. Ambiguidade: o wind-up instantâneo e o preparo de 0,5 s de D-031 conflitam; a pausa fica em 1,5 s no total, como o criador confirmou.
12. **Recast:** os 10 MP e o 1 ATB são cobrados mesmo com Armor ativa.
13. **Guard + Armor:** com Guard ativo, a Armor não é consumida e **sua duração continua a diminuir normalmente** durante o Guard.
14. **Pancham:** poderá aprender o Move **subindo de nível** (nível não definido; o criador disse para não perguntar). **Ignorar por ora**: não implementar no Pancham agora.

## Terceira rodada de respostas

> um icone tipo estes 2,vamos testar com os 2 para eu ver e decidir qual aprovar
> 2 sim
> 1 sim, é o anel de choque o impacto

(Imagens de referência enviadas: um **peitoral** de armadura em silhueta preta com ombreiras e um **capacete** espartano em silhueta preta. Ficam só na conversa, não foram copiadas para o repositório.)

15. **Ícone da badge:** testar os **dois** (peitoral e capacete, no estilo das imagens de referência) para o criador ver e **aprovar um depois**. Nenhum está aprovado.
16. **Trajeto e Impacto (D-308):** o Move não tem trajeto (fase vazia). O **impacto é o anel de choque** no chão.

## Ambiguidades em aberto (perguntar antes de agir)

- **Cor** da badge: cinza por volta de `#9aa3ad` é escolha do assistente (a confirmar).
- **Pausa de durações (item 10 do criador):** não verificado no código se os timers de badges pausam com o motor.
- **Clipe de vitória do Orc/Cyclops:** o clipe 02 `victory` é o que está no doc de importação (`docs/IMPORTACAO_MODELOS_DQT.md`); não verificado se o clipe existe e toca inteiro em batalha.

## Quarta rodada (2026-11-09)

> autorizo ambos cor e implementação

17. **Cor da badge** aprovada: cinza `#9aa3ad` (texto escuro).
18. **Implementação autorizada.**

## Quinta rodada (2026-11-09)

> Peitoral (ícone da badge)
> "Me impressione" (qual ajuste visual fazer)

19. **Ícone aprovado: peitoral.** O capacete fica só no código, sem uso.
20. **Ajuste visual delegado** ("Me impressione"): o assistente escolheu **um** ajuste, o brilho do filtro cromado (reflexo que se move e mais contraste), a mostrar ao criador antes de seguir.

## Sexta rodada (2026-11-09)

> a textura podia aumentar um pouco a opacidade, acho que cromado seria mais próximo
> talvez um efeito visual que indicasse a distância, ao redor do personagem, de que ele está sob uma armadura
> (indicador escolhido) brilho, sparkles de brilho branco que surgem aleatoriamente sobre o corpo do personagem e se movem e somem de forma aleatória
> (anéis de choque) Remover

21. **Filtro cromado:** opacidade assentada de 0,30 para 0,45 e mais espelhado (horizonte duro, mais contraste).
22. **Indicador durante os 8 s:** sparkles de brilho branco que surgem, se movem e somem aleatoriamente sobre o corpo (`armor_aura_effect`, Motion Composer, segue o modelo real e some com a badge).
23. **Anéis de choque do release removidos.** Ficam o clarão, as faíscas e a poeira. O "!" e os anéis grandes vistos no vídeo eram a marca genérica de golpe de status (`play_hit`); o Armored Bulk saiu dela.

## Sétima rodada (2026-11-09)

> ok, agora o efeito de impacto quando o armor é perdido, o que me propõe
> A

24. **Impacto da perda da ARMOR: opção A "placas estilhaçadas".** Clarão branco de 0,08 s; o filme cromado some na hora e sai do corpo em placas retas que voam para fora com gravidade e somem em 0,5 s (últimos 0,2 s com opacidade caindo). Os extras propostos (badge do HUD se partindo, eco "BREAK!") **não foram pedidos**: ficam fora até o criador pedir. Cenário de teste: `armor_perde` na sala de VFX.
25. **Estado visual:** as placas aparecem e caem, mas hoje lêem como **detritos cinza escuros e quadrados**, não como placas triangulares cromadas (a representação `fragments` do Composer ignora a paleta clara). Falta uma representação própria de placa (Composer V1.13).

## Oitava rodada (2026-11-09)

> ok, prossiga, inclusive, visualmente, no cartão do personagem, coloque uma borda cromada animada para quando ele tem armor.
> ja aproveitando remova essa linha com cinza mais escuro que não sei pra que serve, além de deixar o Burst mais paralalelogramático assim como os paralelodramas do ATB, deixe-o 15% maior também, desde que não conflite com outros componentes, o mesmo para os oponentes
> o B do burst também tem que estar com o angulo alterado pra caber corretamente e não parecer estranho

26. **Placas da perda da ARMOR:** triangulares, retas e cromadas (Composer V1.13: rep `plate`, shader `mc_plate`, em `docs/vfx/MOTION_COMPOSER_V1.md` a registrar). Resolve o item 25.
27. **Borda cromada animada** no cartão (jogador e aliado) e na etiqueta (oponentes) enquanto a ARMOR dura: faixas de reflexo que deslizam pelo contorno sobre aço (`BattleHud.draw_chrome_border`). Aplicada a todos, por simetria (D-021); o criador disse "cartão do personagem".
28. **Linha cinza removida:** era a faixa do **numeral de ordem** (I / II / III) na direita do cartão do jogador, com o número. Removidos os dois; o `order` continua no código.
29. **Burst** em paralelogramo com o mesmo ângulo dos blocos de ATB, **15% maior** (cartão 25x17 para 28,75x19,55; etiqueta 13x9 para 14,95x10,35), com o **"B" inclinado** pelo mesmo ângulo. Vale para o cartão e para as etiquetas dos oponentes.

## Nona rodada (2026-11-09)

> move o B para onde está o ponto vermelho, mais pra cima, não colado as extremidades, deixe-o 15% maior

30. **Burst do cartão** movido para cima e para a direita (ponto vermelho indicado), com margem das bordas (12,4 px à direita), e **mais 15% maior** (33,06 x 22,48; o "B" cresce junto). Só o cartão do jogador/aliado; **as etiquetas dos oponentes ficam como estão** (14,95 x 10,35) até o criador pedir.

## Décima rodada (2026-11-09)

> a borda nao ta cobrindo o bloco ainda, eu pedi pra cobrir por completo o cartao, inclusive diminua a velocidade da animacao do cromado no cartao em 25%

31. **A borda cromada cobre o cartão por completo**, inclusive a faixa azul da esquerda (o contorno agora passa por fora da faixa quadrada). **Animação do cromado do cartão 25% mais lenta** (faixas e brilho da borda e das faixas sobre a barra azul).

## Décima primeira rodada (2026-11-09)

> ainda ta errado, ela ta cobrindo a parte visual da recuperacao de MP agora

32. **A borda cromada do cartão fica POR FORA do cartão** (contorno em volta de tudo, faixa azul incluída), para nunca cobrir a barra de carga do MP. Corrige o item 31, que a punha por dentro e cobria a faixa.

## Décima segunda rodada (2026-11-09)

> mudanca de planos, deixe o bloquinho da recuperacao de MP fora do cartao, um pouco afastado do cartao e um pouco maior tambem, inclusive com uma animacao mais aquatica pra recuperacao de MP no movimento da subida

33. **Bloco de recuperação de MP fora do cartão** (6 px à esquerda dele; 10 x 94,3 px, contra 7 x 82 da faixa antiga) e **carregando como água**: duas ondas deslizam na superfície, uma linha de espuma na crista e bolhas que sobem pela água. Cheio quando o MP está cheio (`BattleHud.draw_mp_water`). A faixa azul antiga saiu do cartão, e a borda cromada voltou ao contorno inclinado do cartão, por fora. Revoga o item 31 (borda por dentro, faixa coberta) e o brilho cromado sobre a faixa.

## Décima terceira rodada (2026-11-09)

> deixa ela torta assim como o cartao, 9 graus paralelogramatica
> alem disso poderia fazer com que seus videos nao fossem na velocidade 2x ou sla, nao e a velocidade normal do jogo

34. **Bloco de MP em paralelogramo de 9 graus** (inclinação de 94,3 x tan 9 = 14,9 px; a água, as ondas e as bolhas ficam dentro das paredes inclinadas). Nota: o cartão em si tem ~5,6 graus (inclinação 8 sobre 82 px); foi usado o 9 pedido.
35. **Velocidade dos vídeos:** as animações do HUD liam o relógio real (`Time.get_ticks_msec`); na gravação cada quadro leva bem mais que 1/30 s para renderizar, então o HUD andava várias vezes mais rápido que a batalha. O HUD agora lê `BattleHud.clock_ms()`, que usa o número de quadros desenhados quando o jogo roda com `--fixed-fps` (o mesmo tempo da batalha) e o relógio real no jogo normal. Sem mudança para quem joga.

> o angulo do bloco de mp agora ta um pouco mais angulado do que devia, pode reduzir a angulacao so um pouco menos

36. **Bloco de MP reduzido de 9 para 7 graus** ("só um pouco menos"; o cartão tem ~5,6). Mesma borda direita e mesma espessura.

> iguale

37. **Bloco de MP com o mesmo ângulo do cartão** (8 px sobre 82 px, cerca de 5,6 graus; 9,2 px de inclinação nos 94,3 px do bloco). Revoga os 9 e 7 graus.

## Estado

Implementado (2026-11-09), **aguardando aprovação visual do criador**:
- Mecânica: `Combatant.armor_timer` / `apply_armor` / `end_armor`, `Battle._hit` (ARMOR), `Battle._execute_status_move("armored_bulk")`, pausa total de 1,5 s, IA (`ARMOR_WORTHY_CONTACT`), Move no Orc e no Cyclops (`dqt_test_party.gd`, `enemy_factory.gd`). Teste: `tests/battle/test_d1026_armor.gd`.
- HUD: badge com os dois ícones (`scripts/ui/armor_icons.gd`; `--armor-icon=capacete` ou `CRAWLMON_ARMOR_ICON` escolhe; padrão peitoral). Nenhum ícone aprovado.
- VFX opção A: filtro cromado (`shaders/armor_chrome.gdshader`), partículas no Motion Composer (`armored_bulk_effect`, `armor_break_effect`), Composer V1.12 (`floor_ring`).
- Pancham: **não** recebe o Move por ora.
- Verificado: teste headless de mecânica; vídeo nas duas vistas (Abra como lançador na vista normal, Orc na espelhada). **Não verificado:** Cyclops como lançador, clipe de vitória inteiro no Orc/Cyclops (a animação tocada no Orc foi o clipe que o modelo oferece), Armor sendo quebrada num golpe real em batalha (só no teste headless), desempenho.
