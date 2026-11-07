# D-361 — Pancham mais perto: gap do seguidor de 48 para 32 px

- **Data:** 2026-11-06
- **Área:** Exploração / fila de aliados
- **Origem:** O criador achou a distância entre Abra e Pancham enorme no movimento.

## O que o criador disse (literal)

> o pancham fica mt longe do abra, a distância é enorme, tem como deixaar ele mais perto no movimento?

## Decisão

1. O **gap do rastro** do seguidor passa de **48 px** (1 tile) para **32 px** (2/3 de tile): `TRAIL_GAP` em `scripts/dungeon/follower.gd`.
2. O resto de D-314 **não muda**: rastro exato, sem atravessar paredes, velocidade 200, espera de 1 s e reposicionamento no ponto atrás do líder em caso de prisão.
3. O seguidor continua mirando a trilha do protagonista; em curva a distância em linha reta pode parecer maior que 32 px, mas o percurso é 32 px.
4. Se 32 px ainda parecer longe, o próximo passo é 24 px (1/2 tile); não mexo nisso sem o criador confirmar.

## Estado

Implementado: `TRAIL_GAP = 32.0`; comentários atualizados. Sem teste automatizado de distância; a verificação é visual no jogo. Nada foi publicado.
