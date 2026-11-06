# D-908 — A velocidade de animação por SPD vale para todos os clipes

> **Renumerada em 2026-11-06:** D-165 → D-908. O ID D-165 já pertence a outra decisão no `origin/main`; o conteúdo local foi preservado com o novo ID.


- **Data:** 2026-11-03
- **Área:** Visual / Combate / Animação
- **Origem:** Conversa

## O que o criador disse (literal)

> NÃO NÃO É PRA TIRAR EU NÃO MANDEI TIRAR, DEIXA ASSIM, VAI SER IMPORTANTE

Resposta ao apontamento da auditoria: "SPD afeta tudo: a velocidade vale para todos os clipes, mas D-901 diz idle e corrida. Isso pode desalinhar o frame de contato do golpe".

## Decisão

O `speed_scale` por SPD continua valendo para o `AnimationPlayer` inteiro, e não só para idle e corrida. Isso prevalece sobre o texto de D-901 nesse ponto. Não remover nem restringir.

## Ambiguidades em aberto

O criador disse que isso "vai ser importante", sem dizer como será usado. Não inferir mecânica nova a partir disso.

## Estado no código

Em vigor, sem alteração (`battle_fx.gd`, `apply_buff_visuals`).
