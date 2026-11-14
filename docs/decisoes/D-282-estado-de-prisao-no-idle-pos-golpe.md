<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-282 — Estado de prisão: o idle pós-golpe espera o ataque do outro terminar

- **Data:** 2026-11-05
- **Área:** Combate / retorno / deslocamento
- **Origem:** Conversa (cenário "alvo correndo em outro" da sala de VFX: o atacante teleportava ao acertar um alvo que já tinha pulado de volta)

## O que o criador disse (literal)

> "opção 2 mas não significa que é pro idle ficar maior de verdade, é mais uma variável definida pelo ataque do outro personagem que vai atacar o inimigo, ao invés de fazer o idle ficar maior, ele entra em um "estado de prisão" onde ele não vai pular até o personagem finalizar o ataque ou ele desviar ou bloquear."

Respostas às perguntas:

- Desde quando: **"quando o personagem já chegou perto o bastante pra realizar o ataque"** (o outro já chegou ao alvo e está na fase de golpe).
- Quando solta: **"No impacto do outro"**.
- Desviar ou bloquear: **"Sim, manual"** (o preso pode usar Evade ou Guard por conta própria).
- Escopo: **"todos que envolvem o deslocamento do personagem, quanto a projéteis, esse problema teoricamente n deve ocorrer"** (todo idle pós-golpe de Move corpo a corpo; projéteis não entram).

## Decisão

1. Um personagem no **idle pós-golpe de um Move corpo a corpo** (antes de pular de volta) **não pula** enquanto existir um ataque corpo a corpo de outro personagem **já na fase de golpe (STRIKE) contra ele**. O idle não é alongado: o pulo fica **suspenso** (estado de prisão) e continua de onde estava.
2. A prisão **termina** no impacto do outro ataque, ou antes se o ataque for **desviado** (Evade manual ou esquiva automática), **bloqueado** (Guard), interrompido ou cancelado.
3. Enquanto preso, o personagem **pode usar Evade e Guard manualmente** (hoje não age durante o idle pós-golpe).
4. Vale para todo Move corpo a corpo, não só os cinco de 0,7 s (D-281). Projéteis não entram.
5. Por D-235: sem dependência de personagem, time ou lado.

## Ambiguidades em aberto

- Se o outro atacante ainda está correndo (TRAVEL) quando o alvo termina o idle, o alvo pula normalmente (a prisão só começa com o outro na fase de golpe; escolha do assistente a partir da resposta "já chegou perto o bastante").
- Quantos ataques simultâneos prendem: aqui, enquanto **qualquer** um estiver em STRIKE contra o preso.
- Se o Guard aberto durante a prisão deve continuar depois do impacto (hoje o Guard acaba no hit).

## Estado no código

**Implementado** (2026-11-05): `Battle.is_held/_holds_idle`, congelamento do idle em `_step_attacks`, `BattleEvade._can_act` e `guard_block_reason`. Teste: `tests/battle/test_d282_prison.gd`. Medido no cenário "alvo correndo em outro" da sala de VFX (sonda quadro a quadro dos modelos): antes o atacante saltava 12 un num quadro no impacto; agora o alvo fica parado até o impacto e não há salto maior que 2 un por quadro. Não visto no jogo com modelos; o desenho do Evade de quem está preso é só o texto MISS (sem passo lateral).
