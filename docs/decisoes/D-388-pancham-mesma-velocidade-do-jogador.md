# D-388 — Pancham na mesma velocidade do jogador

- **Data:** 2026-11-07
- **Área:** Exploração / fila de aliados
- **Origem:** o criador viu o Pancham se movimentando em uma velocidade diferente do jogador e pediu para corrigir.
- **Status:** implementado; teste de velocidade; nada publicado.

## O que o criador disse (literal)

> o pancham se movimenta em uma velocidade diferente do jogador, corrija

## Decisão

1. O seguidor usa a **mesma velocidade do jogador**: `SPEED` do `follower.gd` passa de **200** para **180 px/s** (o jogador já é 180 em `player.gd`).
2. Para a fila não nascer **48 px** atrás e continuar assim com a velocidade igual, o spawn do seguidor usa o **gap de D-361**: `TRAIL_GAP` (32 px) em vez de um tile inteiro.
3. O resto de D-314/D-361 **não muda**: rastro exato, sem atravessar paredes, gap de 32 px, espera de 1 s e reposicionamento no ponto atrás do líder em caso de prisão.
4. Consequência: o seguidor **não tem mais o ganho de velocidade** para alcançar o alvo enquanto o jogador anda. Ele mantém o ritmo e o gap; quando o jogador para, chega ao ponto de 32 px. Se ficar preso, o reposicionamento de D-314 continua valendo.
5. O valor 200 de D-329 fica **superado só nesse ponto**; o resto de D-329 permanece.

## Verificação

- `tests/exploration/test_follower_speed.gd` (headless, `--fixed-fps 60`): compara as constantes (`player 180 = follower 180`) e move o líder a 3 px/frame (180 px/s), medindo o passo máximo e a média do seguidor; esperado **≤ 3,05 px** e média perto de 3,0.
- Não verificado em uma exploração completa enquanto o worktree principal estiver com erros de compilação de outras sessões; o teste isola o seguidor e o líder falsos.

## Estado

Código, teste e docs no worktree; commit local; **nada publicado**.
