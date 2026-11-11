# D-1113 — A bolha não apaga o VFX de impacto do Move que ela absorve

- **Data:** 2026-11-10.
- **Área:** Combate / VFX / Bubble Shield.
- **Relacionadas:** D-1108 (Bubble Shield), D-019/D-1040 (linha do tempo única), D-235 (Move independente de personagem/lado), D-308 (protocolo de VFX), D-003 (fazer só o pedido).
- **Status:** implementado; aguardando aprovação visual do criador.

## O que o criador disse (literal)

> "nao permita que a bopha destrua efeitos visuais xe impacto de outros moves"

Esclarecimento escolhido pelo criador: **"Só o VFX de impacto (Recomendado)"** — quando a bolha absorve todo o dano, o Move atacante continua mostrando o impacto dele; sem número de dano, sem reação de corpo, sem knockback, sem hit-stop e sem tremor de câmera.

## Regra

1. **A bolha não suprime o VFX de impacto do Move atacante.** Se a reserva absorver 100% do dano, o impacto do Move ainda é desenhado no alvo.
2. O **splash da bolha** continua aparecendo, como antes.
3. **Não voltam** com o impacto: número de dano, reação de corpo/flinch, knockback, hit-stop, tremor de câmera e pós-processamento de impacto.
4. A regra vale por `move_id`, para qualquer atacante, time e lado (D-235), e não muda dano, duração, ATB ou MP.
5. Exceção existente preservada: o Drain Spear desenha o contato no próprio efeito de Motion e não recebe o impacto genérico.

## Implementação

- `scripts/combat/battle_fx.gd`: no caminho de escudo, quando `dmg <= 0`, chama somente o impacto autoral do Move (`_impact`) e retorna antes das reações de dano.
- `scripts/ui/battle_hud.gd`: não cria número de dano quando `dmg <= 0` e houve absorção da bolha (evita o "0" enganoso).

## O que foi verificado

- Teste do Bubble Shield: **10/10 execuções verdes** (5× sem `--fixed-fps` e 5× com `--fixed-fps 60`), incluindo:
  - impacto do Move continua quando a bolha absorve tudo;
  - nós de VFX do impacto criados;
  - nenhum número de dano "0".
- Lista de 28 testes de combate/VFX: **28/28 exit 0**.
- Suíte `run_agent_combat_tests.py`: **16/16 PASS**.
- Vídeo in-game com o Slime, nas duas vistas: o Confusion (rosa) e o Spear Thrust (branco) aparecem no impacto, com o splash da bolha e sem número de dano.

## O que não foi verificado

- Aprovação visual do criador.
- Build/export.
- Moves cujo impacto autoral dependa de condições específicas além do Confusion e do Spear Thrust.
