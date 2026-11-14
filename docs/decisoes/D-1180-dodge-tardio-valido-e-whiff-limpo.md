# D-1180 — Dodge tardio válido e WHIFF limpo no acerto

- **Data:** 2026-11-11.
- **Área:** Combate / Evade / Dread / Feedback.
- **Origem:** o criador relatou WHIFF mesmo quando já era a hora de o dodge funcionar.
- **Status:** corrigido e testado headless.

## O que o criador disse

> "PELO AMOR DE DEUS O BONECO DA WHIFF MESMO QUANDO NAO DEVIA DAR WHIFF QUANDO JA TA NA HORA DO DODGE FUNCIONAR, CORRIGE ESSA MERDA"

## Diagnóstico

1. **A janela fechava cedo demais para o Dread visível:** ela terminava **0,25 s antes do contato** (D-988). Quem apertava quando o golpe já estava chegando — ou durante o fade do Dread — caía fora e levava WHIFF.
2. **O WHIFF/queda antigos não eram limpos por um Evade válido:** se o jogador apertasse cedo (WHIFF), depois apertasse no Dread e o Evade funcionasse, o texto `WHIFF` e o corpo deitado da tentativa anterior continuavam na tela. Parecia que o acerto tinha dado WHIFF.
3. **O cenário `AUTO — Dodge errado` consumia o Evade aos 2,7 s de propósito.** Quem apertava depois no Dread não tinha mais a tentativa; via o WHIFF antigo e achava que o dodge certo tinha falhado. O cenário foi separado em manual e AUTO.

## Decisão

1. **Margem tardia de 0,15 s:** `can_evade_now()` continua verdadeiro por mais **0,15 s** depois do fechamento antigo, ou seja, até **0,10 s antes do contato**. O Dread fica aceso nesse tempo todo. Um aperto com o Dread na tela não é WHIFF.
2. **O início da janela não muda:** continua sendo os 0,25 s do Dread (D-988), e o golpe continua acertando se o Evade não for feito.
3. **Evade válido limpa o visual do erro anterior:** remove o texto `WHIFF`, restaura a rotação do corpo e invalida a rotina antiga (token), para ela não deitar o personagem de novo depois.
4. **Fora da nova janela continua sendo erro (D-1014):** gasta o ATB, mostra WHIFF/queda e o golpe acerta. A margem só aumenta o tempo válido; não remove o custo.
5. **Cenários de debug:**
   - `dodge_errado_pokemon` — **manual**, sem ação automática; o jogador aperta fora da janela se quiser ver o WHIFF.
   - `dodge_errado_pokemon_auto` — **AUTO**, usado pela suíte para provar WHIFF + `damage` + queda + poeira.
   - `dodge_dread_valido` — **AUTO**, espera o Dread e faz Evade válido, sem WHIFF.
6. **Sem clipe de outro personagem:** o fallback continua sendo o `damage` do próprio Pokémon (D-1167).
7. **D-1107/D-1130 intactos:** o personagem ainda vira para a direção do movimento; A/D ainda são só câmera.

## Relação com decisões

- **D-988/D-1014:** a janela de 0,25 s e o custo do erro continuam; a **margem tardia de 0,15 s** é a mudança nova.
- **D-986:** o Dread acompanha `can_evade_now`, então fica aceso durante a margem.
- **D-1166/D-1167:** WHIFF, queda, poeira e `damage` continuam; agora são limpos por um Evade válido.
- **D-1168:** a escolha do ataque com Dread continua.
- **D-019/D-1040:** só feedback/entrada; o resto da lógica de combate não muda.

## Ambiguidades em aberto

- **Margem de 0,15 s:** se ainda parecer curta, é ajuste local; se parecer fácil demais, reduzir. Não foi vista em vídeo.
- **Aperto antes do Dread:** continua sendo erro intencional (D-1014); não há perdão para apertar antes.
- **Retry no mesmo ataque:** `evade_tried` continua impedindo uma segunda tentativa no mesmo ataque; um Evade válido em outro ataque não é bloqueado.

## Estado no código

Implementado e testado headless (2026-11-11):

- `scripts/combat/battle.gd`: `EVADE_LATE_GRACE = 0.15`.
- `scripts/combat/incoming.gd`: `can_evade_now` usa a margem tardia.
- `scripts/vfx/combat/fx_dodge.gd`: `_cancel_mistimed_visual` limpa WHIFF/queda/token no Evade válido.
- `scripts/vfx/combat/fx_text.gd`, `scripts/combat/battle_fx.gd`: `float_text` devolve o `Label3D` para poder ser limpo.
- `scripts/debug/vfx_room_scenarios.gd`: cenário manual e AUTO separados.
- Teste: `tests/battle/test_d1180_evade_feedback.gd` — **9/9 PASS**; su?te **28/28 PASS**.
