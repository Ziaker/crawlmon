# D-340 — Piscar próprio dos monstros DQT (e regra de olhos do jogo)

- **Data:** 2026-11-05
- **Área:** Visual / Modelos DQT (piloto de crossover)
- **Origem:** Conversa

## O que o criador disse (literal)

> "os olhos do slime abrem e fecham,ele pisca, vc n descobriu isso ainda, então precisa de melhorias"
> "no próprio jogo, não sei se ele também pisca nos outros estados, mas provavelmente sim"
> "Sim, piscar próprio"

Respostas às perguntas de esclarecimento:

- Intervalo: **"Aleatório 3–6 s"**.
- Duração: **"0,12 s"**.
- Estados: **"Sempre que os olhos estiverem abertos"**.
- Quem: **"Todos com adesivo de olho fechado"**.

## Contexto (investigação)

No DQ Tact, todo nó `<X>_scale` controla o objeto `<X>`: ele só aparece enquanto a escala do nó passa de 0,5
(classe `Aiming.MQ.CutoffByScaleNodeAnimation`). No Slime, `Eye_Model_a` é o adesivo de **olhos fechados**
(os abertos estão pintados no corpo). Os clipes só fecham os olhos no Sleep e no Die; **não há piscar no Idle**
nos dados nem no código do jogo, por isso o piscar é criação do Crawlmon.

## Decisão

1. **Regra de olhos do jogo** aplicada aos modelos DQT: cada malha `<X>` só aparece quando a escala animada de
   `<X>_scale` passa de 0,5 (sem isso o Slime fica sempre de olhos fechados).
2. **Piscar próprio:** em todo monstro DQT que tenha um adesivo de olho fechado, os olhos fecham por **0,12 s**
   a cada intervalo **aleatório de 3 a 6 s**.
3. Pisca **sempre que os olhos estiverem abertos** pelo próprio clipe (em qualquer estado); não pisca quando o
   clipe já fecha os olhos (Sleep, fim do Die).
4. **Qual é o adesivo de olho fechado:** o objeto `Eye_Model_*` que o clipe de Sleep (`_04`) deixa visível.
   Durante a piscada ele aparece e os demais `Eye_Model_*` somem. Nada depende do nome do monstro.
5. Orc e Cyclops não têm adesivo de olho fechado e não piscam.

## Ambiguidades em aberto

Nenhuma.

## Estado no código

`scripts/combat/dqt_eyes.gd` (novo) e chamada em `battle_scene.gd`.
