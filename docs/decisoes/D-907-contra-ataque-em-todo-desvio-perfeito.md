# D-907 — Todo desvio perfeito dá contra-ataque de wind-up instantâneo

> **Renumerada em 2026-11-06:** D-164 → D-907. O ID D-164 já pertence a outra decisão no `origin/main`; o conteúdo local foi preservado com o novo ID.


- **Data:** 2026-11-03
- **Área:** Combate
- **Origem:** Conversa

## O que o criador disse (literal)

> contra ataque de wind-up instantâneo pós-desvio perfeito (que gera o burst) não está causando um wind-up instantâneo do move.

Pergunta: vale só no próprio trajeto ou em todo desvio perfeito? Resposta: "Todo desvio perfeito".

## Decisão

Um Evade manual nos últimos 0,22 s da janela (D-030) é perfeito **em qualquer situação**: parado, em wind-up ou no próprio trajeto. O próximo golpe não amigável não tem preparo. Isso **amplia D-027**, que limitava ao próprio trajeto.

Não muda: o teleporte para diante do oponente continua só no desvio perfeito durante o próprio trajeto (D-017, D-027, D-029). Parado, o desvio visual continua o de D-029.

## Causa no código

`BattleEvade.try_evade` só marcava `perfect` e `counter_ready` com o personagem correndo no próprio ataque. Parado, ganhava Burst, mas o golpe seguinte tinha preparo de 1,50 s (reproduzido).

## Consequências para o criador conferir

- A câmera lenta de 2 s do desvio perfeito (D-027/D-042) agora também dispara no desvio perfeito parado, porque ela segue a mesma marca `perfect`.
- Pela simetria (D-021), a IA também ganha o contra-ataque instantâneo.

## Ambiguidades em aberto

D-042 limita o contra-ataque a 2 s de câmera lenta. O código mantém `counter_ready` até o próximo golpe, sem prazo. A divergência já existia e não foi alterada: falta o criador decidir.

## Estado no código

Implementado (`battle_evade.gd`).
