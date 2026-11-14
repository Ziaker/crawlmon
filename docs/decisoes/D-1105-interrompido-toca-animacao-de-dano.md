<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1105 — Interrompido toca a animação de dano

- **Data:** 2026-11-10.
- **Área:** Combate / HUD / animação de reação.
- **Origem:** pedido do criador depois do cartão destruído na interrupção (D-1104).
- **Status:** regra registrada; **implementada**; aguardando aprovação visual.

## O que o criador disse (literal)

> "Faça com q, quando interrompidos, realizem a animação de levar dano"

Resposta da rodada de escopo:

> "Hit, War Cry e status; não Evade (Recommended)"

## Decisão

1. **Quem toca:** o personagem cuja ação foi interrompida toca a animação autêntica **`damage`** com o flinch curto de tronco, mesmo sem perder HP.
2. **Escopo:** interrupções por **hit**, **War Cry** e **status**. **Evade não toca** a animação de dano: o atacante não foi tocado.
3. **Sem pacote de dano:** não há HP perdido, flash, knockback, hit-stop nem texto de dano; é só a reação corporal. Se o criador quiser o pacote completo, é ajuste novo.
4. **Hits:** continuam tocando a reação pelo caminho normal do dano; a nova decisão cobre os interrupts **sem dano** (War Cry/status) e evita duplicar a animação nos hits.
5. **Simetria:** vale para qualquer personagem, time e lado (D-235), nas duas vistas.
6. **Convivência:** o shatter + eco `INTERRUPTED` da D-1104 continua acontecendo ao mesmo tempo.
7. **Regras:** nenhum dano, ATB, Evade, status ou interrupção muda.

## Estado no código

Implementado (2026-11-10), **aguardando aprovação visual**:
- `Battle`: sinal `action_interrupted(actor)`, emitido em `interrupt_windup_of` (War Cry/status sem dano).
- `BattleFx.play_damage_reaction(actor)` chama `_hit_react(actor, 0.0)` (clipe `damage` + flinch, sem HP/flash/knockback).
- `battle_scene.gd`: conexão `battle.action_interrupted.connect(fx.play_damage_reaction)`.
- Vídeo: `test_captures/vfx_tools/war_cry_flinch.mp4` (War Cry padrão, normal/espelhado; o Orc interrompido aparece curvado no flinch em ~1,25 s). Prova: `flinch_crop_125.png`.
- **Verificado:** War Cry interrompendo Tackle; as duas vistas; sem perda de HP; sem flash/knockback.
- **Não verificado:** interrupção de um Move de status em vídeo; Evade (por decisão, não deve tocar); vários interrompidos ao mesmo tempo; aprovação visual.

## Ambiguidades em aberto

Nenhuma de escopo. A ausência de flash/knockback é a proposta implementada; o criador pode pedir o pacote completo depois de ver.
