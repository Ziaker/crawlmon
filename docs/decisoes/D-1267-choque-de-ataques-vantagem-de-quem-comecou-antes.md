> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
> **MOVE = 3D, NUNCA 2D (D-1222).** Todo Move, efeito, mão, trajetória e protótipo é visualmente 3D de verdade (curvas em x, y e z, rotação de pulso/lâmina, volume, luz). É PROIBIDO tratá-lo como 2D (plano único, peça rígida deslizando, câmera 3D com movimento 2D) a não ser que o criador mande EXPLICITAMENTE, Move a Move. Referência de movimento: trajetória 3D real dos ossos dos ataques do Abra/Pancham.

# D-1267 — Choque de ataques no overworld: vantagem de quem começou antes

## Frase literal do criador (2026-11-16)

> "MAS TA CERTO, ENQUANTO O ATAQUE TIVER ATIVO ENQUANDO O PERSONAGEM ESTIVER SE MOVENDO É PRA SER ACERTÁVEL, O PROBLEMA É O HIT, O HIT, ELE DEVIA DAR VANTAGEM A QUEM JÁ INICIOU O ATAQUE, QUEM TEVE MAIS TEMPO DE TRAJETO INICIAL"

(Contexto: ele aprovou o impacto no primeiro toque durante o avanço, D-1262; o problema era o resultado do choque.)

## Decisão

1. Enquanto o ataque está ativo (o personagem ainda em avanço), ele é acertável.
2. Quando os dois ataques estão ativos e se tocam, a vantagem é de quem começou o ataque antes (maior tempo desde o início do ataque). Não é mais "quem encosta primeiro" nem empate por quadro.
3. Empate de verdade (diferença menor que 1/120 s) continua contato normal (D-1100).

## Implementação e ambiguidades

- `_duel_advantage` em `overworld_attack_controller.gd`. "Início do ataque" = começo do wind-up do jogador (Z) e começo do pré-avanço do inimigo, depois do telégrafo de 0,4 s. Se o telégrafo do inimigo deveria contar como "ataque iniciado", é **pendente**.
- Teste: `attack_reach_scenario.gd -- --duel --strict` (jogador ataca em 0,2 a 0,7 s contra um inimigo que arma em 0,4 s; os dois lados). Quem começou antes ganhou em todos os casos fora do empate.
