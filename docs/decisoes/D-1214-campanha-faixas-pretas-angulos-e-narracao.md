<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1214 — Cutscenes de campanha: faixas pretas, catálogo de ângulos e narração de Anodos

- **Data:** 2026-11-14
- **Área:** narrativa, campanha, câmera, UI
- **Estado:** **registrada; nada implementado.** Só documento (D-061).
- **Relacionadas:** D-1088, D-1090, D-1092, D-1210, D-1213, `docs/campanhas/COMPOSICAO_CENAS_E_CUTSCENES.md`

## Frases literais do criador

> "pensou também nos angulos de câmera, as faixas pretas nas regiões superiores e inferiores pra indicar cutscenes? as falas ?"

> "perfeito" (resposta à mensagem que propôs os três itens abaixo, cada um com a minha recomendação)

## Decisão (somente o que ele disse)

1. **Faixas pretas** no topo e na base indicam cutscene. Aparecem só em **momentos-chave, aberturas e fechos de andar**; o diálogo comum de NPC fica sem faixas (como em D-1088).
2. **Catálogo de ângulos inicial:** dois-shot (existe), plano aberto do ambiente e plano de grupo. Os outros ângulos só entram se uma cena pedir.
3. **Narração de Anodos:** card sem retrato, em itálico, só nas aberturas e fechos.

## Ainda pendente (não implementar)

- Espessura, animação de entrada e saída das faixas; se cobrem o HUD.
- Valores dos ângulos (distância, altura, FOV, duração).
- Idioma das falas (D-1085 português × D-1210 inglês) e as demais perguntas 1 a 7 e 11 do §7 do documento.
- Roteiros: nenhuma fala escrita; cada fala nova só entra com aprovação dele.
- **Ambiguidade:** "perfeito" foi lido como resposta aos três itens da mensagem; se ele quis dizer só parte, preciso que diga.
