<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# Sitemap de Documentos de Design (RFCs e Especificações)

Este índice registra as especificações de design geradas através do Elephant-Goldfish Model (EGM) para o Crawlmon.

| Documento | Data | Status | Componentes | Descrição |
|---|---|---|---|---|
| [atributos_natures_progressao.md](atributos_natures_progressao.md) | 2026-11-07 | Especificação Aprovada (EGM Draft) | `CrawlmonAttributeMath`, `Combatant`, `NatureData`, `BattleAI`, `Battle` | Sistema de 15 pontos base (Hare-Niemeyer), HP anti-hitkill (+10/lvl, +25 marcos, +2/VIT), MP por WIS, 8 Natures flat de soma zero e progressão mista. |
| [sistema_experiencia_vitoria_levelup.md](sistema_experiencia_vitoria_levelup.md) | 2026-11-07 | Especificação Aprovada (EGM Draft) | `BattleScene`, `Combatant`, `GameState`, `VictoryPanel`, `LevelUpModal` | Sistema de XP (D-399), sobreviventes (D-402), tela de vitória (D-400) e alocação obrigatória do líder (D-401). |
| [hud_pos_combate_fichas_moves.md](hud_pos_combate_fichas_moves.md) | 2026-11-08 | Especificação Aprovada (EGM Draft) | `PostCombatHUD`, `MoveCard`, `StatPipsStrip`, `MoveInspectionModal`, `SlantedButton`, `skew_panel.gdshader`, `dragonball_aura.gdshader` | Tela pós-combate SMT III com paridade 1:1 ao HTML, paralelogramos a -9°, fichas universais de moves (D-417/D-419), modal de inspeção (D-420), celebração Ki 3D sem flashes (D-418) e bloqueio de alocação (D-401). |
