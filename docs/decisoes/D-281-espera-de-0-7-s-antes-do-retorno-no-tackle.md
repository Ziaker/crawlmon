<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-281 — Espera de 0,7 s no alvo antes de pular de volta (Moves melee de wind-up 1,5 s)

- **Data:** 2026-11-05
- **Área:** Combate / retorno / animação
- **Origem:** Conversa

## O que o criador disse (literal)

> "depois de realizar uma ação melee, demorar mais .7 segundos pra pular devolta pro local de origem (aplique isso apenas nos moves com duração de wind-up igual a do tackle por ora)"

Respostas às perguntas:

- Como conta: **"Total de 0,7 s"** (a espera no alvo depois do golpe passa a ser 0,7 s, substituindo os 0,2 s atuais).
- Quais Moves: **"Os 5 com 1,5 s"**: Tackle, Brick Break, Dragon Claw, Hassou Tobi e Titanomachia.

## Decisão

1. Depois do golpe, o atacante fica **0,7 s** no alvo (`Incoming.hold`, hoje 0,2 s) antes do pulo de volta à origem.
2. Vale **apenas** para os Moves melee com wind-up de 1,5 s: Tackle, Brick Break, Dragon Claw, Hassou Tobi e Titanomachia. Ficam fora: Karate Chop (1,0), Bite (1,2), Dig (1,0), Mach Punch (0,2) e Teleport (0,5).
3. Por D-235: a regra é por `move_id`, vale para qualquer personagem, time e lado.

## Ambiguidades em aberto

- Se o atacante pode ser interrompido durante esses 0,7 s (hoje uma ação em RETURN interrompe, `battle.gd` ~999) e se isso encurta a espera.
- Se o ATB, o engajamento e a próxima ação do atacante contam durante a espera (hoje o ATB já volta a correr depois do golpe).
- Pose/animação durante a espera (idle de batalha de hoje, ou outra).
- Se o 0,7 s também vale quando o atacante já está engajado (ao lado do alvo, sem corrida).
- Se, quando o wind-up de um Move for alterado por outra regra, o critério continua sendo "1,5 s" ou passa a ser uma marca no Move.

## Estado no código

**Implementado** (2026-11-05): `BattleSpace.RETURN_HOLD` por `move_id` (0,7 s nos cinco; 0,2 s nos demais); `AttackPlanner` usa `inc.hold` no RETURN. Testado só nas regras (hold por Move); a espera desenhada com modelos não foi vista no jogo.
