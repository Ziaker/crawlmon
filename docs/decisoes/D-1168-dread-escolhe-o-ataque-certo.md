<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1168 — Dread escolhe o ataque que o jogador pode desviar

- **Data:** 2026-11-11.
- **Área:** Combate / Evade / Dread / Debug.
- **Origem:** o criador relatou WHIFF mesmo apertando Evade quando o Dread aparece. O cenário automático de dodge errado também dispara WHIFF de propósito.
- **Status:** correção de seleção implementada e testada headless.

## O que o criador disse

> "AGORA ELE DA WHIFF TODA HORA MESMO DANDO DODGE QUANDO O DREAD APARECE, MEU DEUS TU NÃO FAZ NADA DIREITO???"

## Diagnóstico

1. **O cenário automático de dodge errado consumia o Evade.** O `dodge_errado_pokemon_auto` executa `evade_once` fora da janela aos 2,7 s e produz WHIFF de propósito. Quem aperta Evade no Dread nesse cenário já encontrou o ATB gasto por esse disparo automático. O `dodge_errado_pokemon` agora é **manual**, sem ação automática; o WHIFF só aparece se o jogador apertar fora da janela.
2. **Com um ataque só, o input no quadro exato do Dread funciona:** o teste de input sintético no Dread deu `dodged=true`, sem `evade_mistimed`.
3. **Com mais de um ataque mirando o líder, havia uma falha real:** `find_evadable` devolvia o primeiro ataque que aceitava o botão (inclusive um wind-up), mesmo que o Dread estivesse aceso em outro. O `try_evade` então gastava o ATB e dava WHIFF no ataque errado.
4. **O Dread também podia aparecer em ataque mirando um aliado**, que o líder não pode desviar. Isso induzia o jogador a apertar e errar.

## Decisão

1. **Dread só no ataque que o jogador pode desviar:** o VFX só aparece para ataques inimigos cujo alvo é o líder do jogador (ou uma área que também o atinge). Ataque mirando só um aliado não acende o Dread.
2. **Se mais de um ataque aceita o botão, o da janela do Dread vence:** `find_evadable` prioriza `can_evade_now()`; se nenhum estiver na janela, mantém o primeiro dodgeable para o erro intencional de D-1014.
3. **Fora da janela continua sendo erro:** apertar antes/depois do Dread gasta o ATB e mostra WHIFF/queda, como D-1014/D-1166 mandam.
4. **Cenários de debug separados:**
   - `dodge_errado_pokemon` — **manual**, sem ação automática; o jogador pode apertar fora da janela para ver o WHIFF.
   - `dodge_errado_pokemon_auto` — **AUTO**, testa o WHIFF + `damage` + queda + poeira; o WHIFF é esperado.
   - `dodge_dread_valido` — **AUTO**, espera a janela do Dread e faz um Evade válido; não deve produzir WHIFF.
   - `dodge_manual` — sem ação automática: o atacante dispara e o jogador aperta no Dread para testar o input real.
5. **Auditoria da sala:** `SUMMARY_JSON` ganhou `evade_ok_count`, `evade_ok_actor`, `evade_ok_skill`, `evade_mistimed_count`, `evade_mistimed_actor`, `evade_mistimed_skill` e `whiff_visual` (clipe, `fall_assist`, texto, poeira).
6. **Sem clipe de outro personagem:** o fallback continua sendo o `damage` do próprio Pokémon (D-1167); nenhum FBX de Cogumelo/Wookada é aplicado.
7. **Simetria D-235:** a escolha é por alvo/janela real, não por nome, time ou lado.

## Ambiguidades em aberto

- **Janela de 0,25 s:** a base continua; a D-1180 acrescentou **0,15 s de margem tardia** (válida até 0,10 s antes do contato). Se ainda parecer curta, é ajuste local.
- **Dread em área:** a regra considera `is_aoe` como atingindo o líder; não foi testado em vídeo com todos os Moves de área.
- **Vídeo:** a auditoria foi por resumo/trace e captura de um cenário; falta vídeo normal+espelhado.

## Estado no código

Implementado e testado headless (2026-11-11):

- `scripts/combat/battle_evade.gd`: `find_evadable` prioriza o ataque na janela do Dread.
- `scripts/vfx/combat/fx_evade_flash.gd`: Dread ignora ataques mirando só aliados.
- `scripts/debug/vfx_room_scenarios.gd`: `dodge_errado_pokemon` (manual), `dodge_errado_pokemon_auto` (AUTO) e `dodge_dread_valido` (AUTO).
- `scripts/debug/vfx_room.gd`: contadores de Evade válido/errado e `whiff_visual` no `SUMMARY_JSON`.
- Teste: `tests/battle/test_d1168_dread_target.gd` — **8/8 PASS** (inclui a escolha do ataque com Dread e o filtro de alvo do Dread).
- Suíte: **28/28 PASS**.
- Auditoria: `dodge_errado_pokemon_auto` → `evade_mistimed_count=1`, `whiff_visual.clip="damage"`, `fall_assist=true`; `dodge_dread_valido` → `evade_ok_count=1`, `evade_mistimed_count=0`, `whiff_visual={}`.
