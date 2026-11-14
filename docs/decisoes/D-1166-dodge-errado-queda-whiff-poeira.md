<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1166 — Dodge errado: queda visível + WHIFF + poeira

- **Data:** 2026-11-11.
- **Área:** Combate / Evade / Feedback visual.
- **Origem:** o criador relatou que falhar o dodge não tinha indicação visual; o personagem só perdia ATB e não se movia.
- **Status:** regra registrada; implementada e testada headless. Estende a D-1015.

## O que o criador disse

> "falhar o dodge não tem nenhuma indicação visual, o personagem só perde o atb e não se move, corrija"

Resposta à pergunta de qual visual usar:

> "animação de queda e WHIFF e poeira"

## Diagnóstico

O evento `evade_mistimed` já disparava e o `down` já era mandado tocar (D-1015). O problema era visual: nos modelos Pokémon (Abra, Gible, Pancham etc.) o clipe `down` só abaixa braços/cabeça e **não derruba o corpo**. Nos modelos DQT o clipe `Die` derruba de verdade. Por isso o dodge errado parecia não ter reação nenhuma.

## Decisão

1. **WHIFF:** ao apertar Evade fora da janela válida (D-1014), aparece o texto **`WHIFF`** em caixa alta acima do personagem, flutuando e sumindo (helper `float_text`), na cor âmbar `#ffb020`.
2. **Queda:** o clipe `down` continua tocando quando ele derruba o corpo. Se o clipe **não derruba** (Pokémon), toca o clipe **`damage`** (D-1167) e o jogo inclina o modelo no próprio eixo até deitá-lo (~90°) por ~0,25 s, segura e levanta em ~0,15 s, tudo dentro da duração do clipe (0,4–1,6 s). Se o clipe já derruba (DQT), não inclina de novo.
3. **Poeira:** um puff de poeira cinza/terrosa nasce no chão, perto dos pés, quando o corpo chega ao chão.
4. **Sem clipe `down`:** se houver `damage`, ele toca como fallback (D-1167); senão, WHIFF + queda por código + poeira continuam valendo (cápsulas/modelos sem animação).
5. **Corpo conduzido pela própria corrida de ataque:** não há queda (D-1015), para não brigar com a corrida; ainda assim aparecem **WHIFF e poeira**, para o erro ser perceptível.
6. **Regras intactas:** o ATB continua sendo gasto e o golpe continua acertando (D-1014). Nada muda em dano, janela, crítico ou IA.
7. **Simetria D-235:** vale para qualquer personagem, aliado ou inimigo, perto ou longe da câmera; a direção da queda vem do modelo real e o texto/poeira da posição real.
8. **Duração:** a queda acompanha o clipe escolhido (`down` ou `damage`); quando ele acaba, o personagem volta ao `battle_idle` sozinho (mantém D-1015). Se um golpe acertar no meio, a reação de dano não é pisada pelo reset.

## Relação com decisões

- **D-1015:** mantém o `down` e a volta ao idle; acrescenta WHIFF, poeira e a queda por código quando o clipe é fraco. O item 4 da D-1015 (“se não tiver `down`, nada toca”) fica **ampliado**: agora o erro sempre tem WHIFF + poeira + queda assistida.
- **D-1167:** quando o `down` não derruba o corpo e existe `damage`, o clipe base passa a ser `damage`; a queda assistida, WHIFF e poeira continuam.
- **D-1014:** o custo e a regra de “não desviou” continuam iguais.
- **D-104/D-106:** o Evade válido continua sendo erro do ataque, não interrupção; nada muda no feedback de Evade bem-sucedido.
- **D-235:** nada depende de personagem, time, lado ou coordenada fixa.
- **D-1154:** o evento `evade_mistimed` já existia no trace; nenhum campo novo foi necessário.

## Ambiguidades em aberto

- **Texto exato:** foi usado `WHIFF` (sem “!”), como o criador escreveu. Se quiser `WHIFF!`, é ajuste local.
- **Cor:** âmbar `#ffb020`; pode ser trocada.
- **Direção da queda:** o modelo cai para trás em relação à própria facing; não foi definido se deve cair para o lado.
- **DQT:** o clipe `Die` já derruba; a poeira sai em ~45% da duração do clipe. O momento exato não foi ajustado em vídeo.
- **Vários erros ao mesmo tempo:** não verificado.

## Estado no código

Implementado e testado headless (2026-11-11):

- `scripts/vfx/combat/fx_dodge.gd`: `mistimed` toca `down`, detecta se o clipe derruba o corpo (`_down_clip_falls`), aplica a queda assistida, chama `_whiff_text` e `_whiff_dust`.
- Nenhuma regra de `battle.gd` foi alterada; o ATB e o acerto continuam iguais.
- Teste: `tests/battle/test_d1163_mistimed_visual.gd` — **9/9 PASS**.
- Suíte `python tests/battle/run_agent_combat_tests.py`: **28/28 PASS**.
- Verificação visual: capturas em 1280×720 mostram o Abra deitado, o texto `WHIFF` e a poeira; depois ele volta ao idle.
- **Não verificado:** vídeo nas duas vistas (normal/espelhada), modelos DQT em vídeo, vários personagens errando juntos e desempenho.
