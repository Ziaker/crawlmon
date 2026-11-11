# D-1168 — Dread escolhe o ataque que o jogador pode desviar

- **Data:** 2026-11-11.
- **Área:** Combate / Evade / Dread / Debug.
- **Origem:** o criador relatou WHIFF mesmo apertando Evade quando o Dread aparece. O cenário automático de dodge errado também dispara WHIFF de propósito.
- **Status:** correção de seleção implementada e testada headless.

## O que o criador disse

> "AGORA ELE DA WHIFF TODA HORA MESMO DANDO DODGE QUANDO O DREAD APARECE, MEU DEUS TU NÃO FAZ NADA DIREITO???"

## Diagnóstico

1. **O cenário `dodge_errado_pokemon` é automático.** Ele executa `evade_once` fora da janela aos 2,7 s e produz WHIFF de propósito. Quem aperta Evade no Dread nesse cenário já encontrou o ATB gasto por esse disparo automático. O WHIFF na tela é o resultado do teste do caso errado, não do dodge manual.
2. **Com um ataque só, o input no quadro exato do Dread funciona:** o teste de input sintético no Dread deu `dodged=true`, sem `evade_mistimed`.
3. **Com mais de um ataque mirando o líder, havia uma falha real:** `find_evadable` devolvia o primeiro ataque que aceitava o botão (inclusive um wind-up), mesmo que o Dread estivesse aceso em outro. O `try_evade` então gastava o ATB e dava WHIFF no ataque errado.
4. **O Dread também podia aparecer em ataque mirando um aliado**, que o líder não pode desviar. Isso induzia o jogador a apertar e errar.

## Decisão

1. **Dread só no ataque que o jogador pode desviar:** o VFX só aparece para ataques inimigos cujo alvo é o líder do jogador (ou uma área que também o atinge). Ataque mirando só um aliado não acende o Dread.
2. **Se mais de um ataque aceita o botão, o da janela do Dread vence:** `find_evadable` prioriza `can_evade_now()`; se nenhum estiver na janela, mantém o primeiro dodgeable para o erro intencional de D-1014.
3. **Fora da janela continua sendo erro:** apertar antes/depois do Dread gasta o ATB e mostra WHIFF/queda, como D-1014/D-1166 mandam.
4. **Cenários de debug separados:**
   - `dodge_errado_pokemon` — **AUTO**, testa o WHIFF + `damage` + queda + poeira; o WHIFF é esperado.
   - `dodge_dread_valido` — **AUTO**, espera a janela do Dread e faz um Evade válido; não deve produzir WHIFF.
   - `dodge_manual` — sem ação automática: o atacante dispara e o jogador aperta no Dread para testar o input real.
5. **Auditoria da sala:** `SUMMARY_JSON` ganhou `evade_ok_count`, `evade_ok_actor`, `evade_ok_skill`, `evade_mistimed_count`, `evade_mistimed_actor`, `evade_mistimed_skill` e `whiff_visual` (clipe, `fall_assist`, texto, poeira).
6. **Sem clipe de outro personagem:** o fallback continua sendo o `damage` do próprio Pokémon (D-1167); nenhum FBX de Cogumelo/Wookada é aplicado.
7. **Simetria D-235:** a escolha é por alvo/janela real, não por nome, time ou lado.

## Ambiguidades em aberto

- **Janela de 0,25 s:** não foi alterada. O input no quadro exato do Dread funciona; se o criador quiser uma janela mais folgada (reações humanas), isso muda D-988 e precisa de decisão própria.
- **Dread em área:** a regra considera `is_aoe` como atingindo o líder; não foi testado em vídeo com todos os Moves de área.
- **Vídeo:** a auditoria foi por resumo/trace e captura de um cenário; falta vídeo normal+espelhado.

## Estado no código

Implementado e testado headless (2026-11-11):

- `scripts/combat/battle_evade.gd`: `find_evadable` prioriza o ataque na janela do Dread.
- `scripts/vfx/combat/fx_evade_flash.gd`: Dread ignora ataques mirando só aliados.
- `scripts/debug/vfx_room_scenarios.gd`: cenários `dodge_errado_pokemon` (AUTO) e `dodge_dread_valido` (AUTO).
- `scripts/debug/vfx_room.gd`: contadores de Evade válido/errado e `whiff_visual` no `SUMMARY_JSON`.
- Teste: `tests/battle/test_d1168_dread_target.gd` — **8/8 PASS** (inclui a escolha do ataque com Dread e o filtro de alvo do Dread).
- Suíte: **27/27 PASS**.
- Auditoria: `dodge_errado_pokemon` → `evade_mistimed_count=1`, `whiff_visual.clip="damage"`, `fall_assist=true`; `dodge_dread_valido` → `evade_ok_count=1`, `evade_mistimed_count=0`, `whiff_visual={}`.
