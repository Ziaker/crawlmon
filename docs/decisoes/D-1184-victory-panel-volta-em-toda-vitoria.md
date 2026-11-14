<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1184 — O painel de vitória simples (VictoryPanel) volta em toda vitória; level up usa o modal antigo de pontos

- **Data:** 2026-11-12.
- **Área:** Combate / pós-combate / UI.
- **Relacionadas:** D-400 (tela de vitória), D-401 (modal obrigatório de pontos do líder), D-402 (XP só para sobreviventes), D-433 (Level Up HUD; port Godot rejeitado, §5).
- **Status:** registrado; implementação a seguir.

## O que o criador disse (literal)

> tinha uma hub anterior a esta que era super simples que só mostrava os personagens ganhando XP, eu queria que ela voltasse e depois discutissemos um overhaul pra ela

Respostas às perguntas de esclarecimento:

- **Quando abre?** "Toda vitória".
- **Com level up, o que vem depois do VictoryPanel?** "Modal antigo de pontos".

## Decisão

1. **O `VictoryPanel` (D-400) volta** e abre em **toda vitória**, com ou sem level up: título, XP total, um card por membro com barra de XP animada, `LEVEL UP! +N` e `K.O. (+0 XP)` para quem caiu (D-402), e `[ Z / ENTER ] CONTINUAR`.
2. **Depois de confirmar o painel**, se o **líder** tiver pontos para distribuir (`distributable_points > 0`), abre o **`LevelUpModal` antigo** (D-401), que exige alocar os pontos antes de voltar ao mapa. Sem pontos, volta direto (`GameState.end_battle(true)`).
3. **O Level Up HUD (D-433) sai do fluxo da batalha.** O código dele (`scenes/ui/level_up_hud.tscn`, `scripts/ui/level_up_hud.gd`, componentes e lab) **não é apagado**; só deixa de ser aberto.
4. **D-433 fica substituída** na parte "sem level up volta direto ao mapa" e "o Level Up HUD substitui o painel". O nome Level Up HUD e o protótipo HTML ficam como referência.
5. **Overhaul do VictoryPanel:** a discutir depois; nada do visual muda agora.
6. **O que não muda:** cálculo de XP (D-399), XP só para sobreviventes (D-402), desaceleração antes do painel (D-400), regras de combate.

## Ambiguidades

- O `LevelUpModal` só considera o líder (como em D-401). Aliados que sobem de nível não abrem modal; os pontos deles seguem a regra que já existe no código.
