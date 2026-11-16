Retomada: Summon, Fase 8 (cena), seletor nos cartões.

Leia AGENTS.md, docs/decisoes/README.md, D-1244, D-1249 e D-1254 (animação: pentagrama 4 s, raio, 1 s, não congela, quem entra só age após 4 s, cartão KO escuro com X, mudança em `Battle` AUTORIZADA), docs/TELEMETRIA.md (Summon).

Estado (não commitado, branch wip/checkpoint-2026-11-06; não use stash/checkout/reset; sem commit/push sem minha ordem):
- Lógica em `Battle` pronta e testada (D-1232/D-1244). Cena ligada: SUMMON no leque lateral abre o seletor em duas etapas; `leader` segue `battle.menu_owner()` (`_sync_leader`); modelo/cartão de quem sai e entra são tratados em `_on_summon_changed`.
- Seletor nos cartões é uma PRÉVIA provisória (D-1249 só decide o formato): contorno branco pulsante no cartão sob o cursor e faixa horizontal de cartões dos substitutos acima do cartão de quem sai. Código: `battle_hud.gd` (set_summon_cursor, show_summon_strip, set_summon_picking), `battle_scene.gd` (_begin_summon_pick, _summon_pick_entering, _confirm_summon).
- Testes: `--summon-ui=basic|cancel|noatb|protagonist|ko [--mirror] --quit` (10 linhas no run_agent_combat_tests.py), `--summon-ui=shot:1|2 --shot=arq.png`, `--summon-ui=shot|video[:ko][:pko][:pleave][:subs2][:atb=N][:step=1|2] [--mirror]` (variantes combináveis, legenda na tela; vídeo com `--fixed-fps 30 --write-movie x.avi`, converta com ffmpeg). Exemplo gravado: prototypes/summon_selector/summon_ko_subs2.mp4. Eu não gostei do primeiro resultado visual: pergunte o que mudar antes de refinar. Suíte: 116/117; `Javelin Throw D-235` falha por outro motivo (falha mesmo com _sync_leader desligado).
- Protótipo HTML de opções: prototypes/summon_selector/index.html.

Antes de implementar a D-1254, pergunte (uma por vez, com recomendação): o que fica na vaga nos 4 s; quando os 2 ATB são pagos (confirmar ou chegar); se dá para cancelar a invocação e se o custo volta.

Pendências (decisões minhas, uma por vez, sempre com a recomendação rotulada; não decida por mim):
1. Layout da faixa de substitutos (horizontal acima / coluna à esquerda / giro dentro do cartão).
2. Destaque do cursor.
3. Como o nocauteado aparece (hoje sem visual).
4. Textos de cabeçalho e de recusa.
5. Cor de destaque.
6. Animação da troca.
7. Teclas de confirmar/cancelar.
8. Se a escolha congela a batalha (hoje não congela; a troca em si é instantânea).
9. `save_state/restore_state` do Battle não cobrem a troca (party/roster/protagonist/battle_time): aviso, preciso decidir se entra.
10. O BattleTrace por quadro não registra quem entra no meio da batalha (o evento `summon` sim).

O que eu quero agora: [escreva aqui as opções que você escolheu, ou "assisti ao vídeo, quero X"].

Registre cada escolha como decisão (D-1255+, a D-1245 a D-1254 já existem) antes de codar. Termine com o relatório de 8 itens.
