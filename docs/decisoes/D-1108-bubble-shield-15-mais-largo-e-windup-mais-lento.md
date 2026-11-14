<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1108 — Bubble Shield 15% mais largo e wind-up sumindo 1 s mais devagar

- **Data:** 2026-11-10.
- **Área:** Combate / VFX / Bubble Shield.
- **Relacionadas:** D-235 (Move independente de personagem, time e lado), D-308 (protocolo de VFX), D-1040/D-019 (linha do tempo única: o visual só desenha), D-1042/D-1044 (sala e análise de VFX), D-003 (fazer só o pedido).
- **Status:** implementado; aguardando aprovação visual do criador.

## O que o criador disse (literal)

> "aumente o tamanho da bolha em 15% na largura diametro"

> "inclusive fca com que o efeito visual do wind up leve mais 1 segundo para sumir lentamente."

## Regra

1. **A bolha visível do Bubble Shield cresce 15% na largura (diâmetro horizontal).** O fator é `1,15` aplicado em X e Z; **a altura (Y) não muda**.
2. A mudança vale para o conjunto visual da bolha: casco, concha facetada, ondas de formação, gotas internas, motes, jato de liberação e o ponto de impacto/splash na superfície.
3. **O desaparecimento do efeito visual de wind-up dura 1 segundo a mais:** a saída lenta passa de `1,45 s` para `2,45 s`. O wind-up do Move (tempo de jogo, pausa de status, dano, duração do escudo, ATB e MP) **não muda**.
4. O Bubble Shield continua funcionando por `move_id`, com qualquer personagem, time e lado, com alvos de tamanhos diferentes (D-235).

## Ambiguidades

Nenhuma em aberto. "Sumir lentamente" foi aplicado à saída do efeito visual do wind-up, não ao tempo de jogo do Move.

## Implementação

- `scripts/vfx/combat/bubble_shield_visual.gd`: constante de largura `1,15`; escala do nó raiz em X/Z; ponto de impacto e splash medidos no raio horizontal.
- `scripts/vfx/combat/bubble_shield_windup.gd`: `RELEASE_SECONDS` de `1,45` para `2,45`.

## O que foi verificado

- Teste do Bubble Shield: **10/10 execuções verdes** (5× sem `--fixed-fps` e 5× com `--fixed-fps 60`), incluindo a razão X/Z = 1,15 e `RELEASE_SECONDS = 2,45`.
- Lista de 28 testes de combate/VFX: **28/28 exit 0**.
- Suíte `run_agent_combat_tests.py`: **16/16 PASS**.
- Sala de VFX com `--move=Bubble Shield --audit-leaks`: `[vfx_audit] leaks=0`.
- Sala de VFX com `--envelope-graph`: `envelope_pops=[]`, fases `release → strike → impact → return → done`.
- Vídeo in-game com o Slime em uma única gravação: metade normal (Slime no time aliado) e metade espelhada (Slime no time inimigo, longe), com a bolha inteira no quadro.

## O que não foi verificado

- Aprovação visual do criador para o novo tamanho e para a saída mais longa.
- Build/export.
- Alvos de tamanhos muito diferentes além do Slime (a largura é derivada do envelope medido, mas a prova visual foi só com o Slime).
