<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1104 — Cartão de ação destruído na interrupção

- **Data:** 2026-11-10.
- **Área:** HUD / Combate / feedback de interrupção.
- **Origem:** pedido do criador depois dos vídeos do War Cry e do Javelin Throw.
- **Status:** regra registrada; **implementada**; escopo corrigido pela D-1160; aguardando aprovação visual.

## O que o criador disse (literal)

> "uma coisa nova, quando uma acao e interrompida eu queria que o cartao da acao que tava sendo feita fosse destruido e repartido em varias partes por .55 segundos e com um eco textual"

Respostas da rodada de perguntas:

> "Cartão de wind-up (AttackTag) (Recommended)"

> "interrupted e ele surge exatamente centralizado onde o cartao se destroi"

> "Todas as interrupções (Recommended)"

> "8–9 estilhaços da textura real (Recommended)"

## Decisão

1. **Cartão destruído:** o `AttackTag`, o cartão de wind-up acima do personagem que mostra o Move, tipo, alcance, alvo e contagem.
2. **Escopo:** toda interrupção real de ação — hit, Evade manual, Evade automático, War Cry e status. Ações que terminam normalmente continuam usando a saída normal (`leave()`), sem destruição.
3. **Destruição:** o cartão original desaparece no quadro da interrupção. Ele é repartido em **9 estilhaços** (faixa pedida: 8–9) feitos da **textura real** do cartão, com separação, rotação e gravidade, sumindo em **0,55 s**; a opacidade cai nos últimos **0,20 s**.
4. **Eco textual:** o texto é exatamente **`INTERRUPTED`** (caixa alta, sem “!”), centralizado exatamente no centro do cartão destruído. Dura os mesmos **0,55 s**. Segue o padrão de eco da D-1061: flat, saturado, sem borda.
5. **Ajuste visual aprovado na segunda rodada:** tipografia com **espaçamento de 4 px** entre letras e **piscada branca de 0,20 s no surgimento**, assentando no coral `#ff4d6d`. Impact, entrada de escala 1,2 → 1,0 em 0,08 s, fade nos últimos 0,20 s.
6. **Simetria:** vale para os dois lados e as duas vistas (D-235); o cartão de qualquer personagem se quebra igual.
7. **Natureza:** é feedback de HUD/interrupção, não VFX de elemento de Move; a verificação é por vídeo nas duas vistas, sem alterar regra de combate.

> **Correção posterior — D-1160 (2026-11-11):** o criador esclareceu que **desvio automático não é interrupção** e que o cartão não pode ser destruído quando o Move continua funcionando. Pela D-104/D-106, **Evade (manual e automático) é erro**, não interrupção; golpe recebido no retorno e fim de batalha também não são. O efeito da D-1104 (9 estilhaços, eco, 0,55 s) continua igual; mudou apenas o gatilho, que passou a ler `Incoming.interruption_feedback`. Ver `D-1160-interrupcao-visual-so-real.md`.

## Ambiguidades em aberto

- **Cor e animação do eco:** a proposta acima não foi vista pelo criador; ajustar depois do vídeo.
- **Número final de estilhaços:** 9 nesta implementação; se o criador preferir 8, é ajuste local.

## Estado no código

Implementado (2026-11-10), **aguardando aprovação visual**:
- `scripts/ui/attack_tag_shatter.gd`: 9 estilhaços do cartão real + `EchoText` `INTERRUPTED` centralizado, espaçamento 4 px e flash branco de 0,20 s.
- `scripts/ui/battle_hud.gd`: `AttackTag.shatter()` e o gatilho em `_sync_incoming` (tanto na lista ativa quanto na limpeza de cartões que já saíram da lista, como o War Cry). **D-1160:** o gatilho passou a ler só `Incoming.interruption_feedback`; Evade/desvio automático e golpe no retorno não destroem mais o cartão.
- Teste: `tests/ui/test_d1104_attack_tag_shatter.gd` (passa: 9 estilhaços, eco `INTERRUPTED`, espaçamento 4 px, flash inicial, 0,55 s) e `tests/ui/test_d1160_interruption_feedback.gd`.
- Vídeos: `test_captures/vfx_tools/war_cry_shatter_v2.mp4` (War Cry no DQT, normal/espelhado; flash branco em ~1,20 s e coral em ~1,34 s) e `mach_interrupt_shatter_v2.mp4` (Mach Punch interrompe o Tackle).
- **Verificado:** hit (Mach Punch) e War Cry; as duas vistas; 9 estilhaços; eco centralizado; 0,55 s; caixa alta, espaçamento e flash.
- **Não verificado:** Evade manual/automático e interrupção de um Move de status em vídeo; muitos cartões quebrando ao mesmo tempo; desempenho; aprovação visual final.
