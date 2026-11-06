# D-279 — Choque de corridas: pulinho para trás e golpes ao mesmo tempo

- **Data:** 2026-11-05
- **Área:** Combate / trajeto / corrida
- **Origem:** Conversa (pedido de auditoria do trajeto + respostas às perguntas)

## O que o criador disse (literal)

> "tem vezes que ambos se chocam enquanto se movem e acabam influenciando suas velocidades a ponto de ficarem super rápidos e sairem da tela colados. Transforme em uma feature de que quando ambos correm nas direções exatas, eles se chocam dando um pulinho pra trás e aí realizam seus movimentos ao mesmo tempo (respeitando as regras da animação e de wind-up para caso de um move ser mais rápido)."

Respostas às perguntas:

- Gatilho: **"Qualquer cruzamento"** (quaisquer dois corredores que se encontrem, mesmo com alvos diferentes).
- Quem acerta: **"O mais rápido interrompe"** (cada um acerta no seu tempo; se o golpe de um cai antes do golpe do outro, o outro é interrompido, pela regra de interrupção de hoje).
- Alvos diferentes (A corre em B e B corre em C): **"Cancela e volta à origem"** (os dois cancelam a corrida e voltam à origem depois do pulinho).
- Pulinho: **"Mesmo salto do retorno"** (reusa o cálculo do salto de retorno que cada ataque já tem).
- Depois do pulinho: **"do ponto do pulinho, se ambos ficarem mt distantes, se aproximam lentamente durante a animação até ficarem corretamente alinhados entre 2.6 unidades um do outro"**.

## Decisão

1. Quando duas corridas se cruzam, os dois **se chocam e dão um pulinho para trás**, reaproveitando o cálculo do salto de retorno de cada ataque.
2. Se os dois correm um no outro (mesmo alvo recíproco), depois do pulinho **os golpes saem ao mesmo tempo**, cada um a partir do **ponto do pulinho**, com a antecipação, o avanço e o tempo de acerto do **próprio Move**. Se ficarem muito distantes, **se aproximam lentamente durante a animação** até ficarem a 2,6 unidades um do outro (`STAND_GAP`).
3. Se um golpe cai antes do golpe do outro, o outro é **interrompido** (regra de interrupção existente; wind-up e animação de cada Move respeitados).
4. Se os alvos são diferentes (A→B e B→C), os dois **cancelam a corrida e voltam à origem** depois do pulinho.
5. Por D-235: vale por `move_id`, para qualquer personagem, time e lado.

## Ambiguidades em aberto

- Em que distância exata o choque acontece (ao chegar a 2,6 un? ao se sobreporem?) e qual é o eixo do pulinho.
- Velocidade da "aproximação lenta" e o que é "muito distantes".
- "Qualquer cruzamento" com alvos diferentes: custo/ATB do ataque cancelado (perdido como em D-029, ou devolvido como em D-072?) e se há "MISS"/Burst.
- Se o choque vale também quando um dos dois já está na espera no alvo (STRIKE) e o outro chega correndo.
- O que ocorre quando os dois golpes caem no mesmo quadro (ambos acertam?).
- Quantos corredores (3 ou mais) podem se chocar juntos.

## Causa encontrada na auditoria

O choque não existe nas regras: os dois atravessam a disputa sem colisão e, quando ambos estão em STRIKE, `AttackMotion._track()` reancora cada atacante à posição ao vivo do outro a cada quadro. O avanço (lunge) de um empurra o outro, que o arrasta, e os dois andam colados a 31–36 u/s (medido em simulação headless de regras, Tackle × Tackle com 0,5 s de defasagem). A correção da causa está em D-280 (restaurar D-054).

## Estado no código

**Implementado** (2026-11-05), com estas escolhas do assistente nas ambiguidades abertas (o criador não as definiu; ajustáveis em `BattleSpace`):
- Choque quando os dois corredores de **times opostos** (ambos em TRAVEL) chegam a **3,6 un** um do outro (`CLASH_DIST`); aliados no mesmo alvo não se chocam.
- Pulinho de **2,0 un** para trás no eixo do choque (`CLASH_BACK`), 0,26 s e altura 1,2 (o menor salto de retorno, `CLASH_HOP_T/H`).
- Recíproco: os dois golpeiam do ponto do pulinho e se aproximam lentamente, com a animação, até ficarem a 2,6 un um do outro; o que acerta antes interrompe o outro (regra existente). Alvos distintos: os dois são empurrados para trás e voltam à origem como num hit (sem dano; o ATB gasto se perde).
- Efeito: flash e anel de choque no ponto de encontro (`BattleFx.on_attack_clashed`).
Código: `Battle._detect_clashes/_clash`, `AttackMotion` (TRAVEL e STRIKE), `Incoming.clash*`. Teste: `tests/battle/test_d279_clash.gd`. Não visto no jogo com modelos além da sala de VFX; 3+ corredores e o choque com um corredor em STRIKE não tratados.
