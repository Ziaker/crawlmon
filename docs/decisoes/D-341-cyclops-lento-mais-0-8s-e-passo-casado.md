# D-341 — Cyclops lento: +0,8 s para chegar ao alvo e passo casado com o chão

- **Data:** 2026-11-05
- **Área:** Combate / Animação / Piloto DQT
- **Origem:** Conversa

## O que o criador disse (literal)

> "eu não gosto da velocidade de movimento da animação do ciclope, ele tá se movendo rapido demais, no caso deslizando do que se movendo, vamos presumir que ele é um personagem lento e faça ele levar .8 segundos extras pra chegar no alvo, além de aumentar a velocidade da animação dele andando"

Respostas às perguntas de esclarecimento:

- Onde vale: **"Só a ida até o alvo"**.
- Escopo: **"vai ter haver com o atributo de AGI dos personagens"**.
- Animação: **"Casar passo com o chão"**.
- Como fazer agora (AGI ainda sem fórmula nem código, D-119/D-133): **"Provisório: +0,8 s fixo"**.

## Decisão

1. A corrida de **ida** dos golpes corpo a corpo do Cyclops leva **+0,8 s**. Volta e projéteis não mudam.
2. É um valor **provisório** na ficha do personagem (`travel_extra`); quando a AGI for implementada, a lentidão
   passa a vir da AGI baixa (D-119, D-133) e este campo sai.
3. Durante a corrida de ida, a animação de andar/correr do Cyclops toca na velocidade que faz os pés acompanharem
   o deslocamento real (passo medido no próprio clipe), sem deslizar. A escala de SPD (D-165) continua valendo.

## Extensão: Orc (mesma data)

> "deixe o orc um pouco lento também, levando .45 extras pra chegar no alvo"

Pergunta: casar também o passo do Orc? Resposta: **"Sim, casar o passo"**.

4. O Orc leva **+0,45 s** na ida até o alvo (mesmo campo provisório `travel_extra`) e, nessa corrida, a animação
   de andar casa o passo com o chão, como no Cyclops.

## Ajuste da velocidade da corrida (2026-11-06)

> "digamos que a velocidade da animação deles correndo está um pouco alta demais agora que vc fez a mudança, tem como reduzir um pouco?"

Pergunta: reduzir quanto? Resposta: **"75% do casado"**.

5. A animação da corrida toca a **75%** da velocidade que casaria o passo com o chão (Cyclops e Orc). Volta a
   deslizar um pouco, por escolha do criador.

## Orc em velocidade normal (2026-11-06)

> "deixa a animação do orc em 1x, a velocidade normal clássica dele"

6. O Orc **não** casa mais o passo: a animação de corrida dele toca em 1× (só a escala de SPD da D-165 continua
   valendo). Os +0,45 s na ida continuam. O Cyclops segue com o passo casado a 75%.

## Ambiguidades em aberto

- A janela de Evade fica 0,8 s maior contra o Cyclops e 0,45 s maior contra o Orc (consequência da corrida mais longa). Não foi discutido.

## Estado no código

`combatant.gd` (`travel_extra`), `attack_planner.gd`, `dqt_test_party.gd`, `dqt_model_profiles.gd`, `fx_motion.gd`.
