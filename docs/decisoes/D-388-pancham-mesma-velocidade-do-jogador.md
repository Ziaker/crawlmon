<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

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
