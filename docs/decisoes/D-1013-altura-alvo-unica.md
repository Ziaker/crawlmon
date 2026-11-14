<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1013 — Altura alvo única para todos os personagens

- **Data:** 2026-11-08.

## Frase literal do criador

> quanto aos problemas de altura, o que me propõe pra aumentar a altura de todos personagens para caberem melhor na visão do jogador e da câmera? removendo esta regra dos inimigos serem maiores e sim seguirem a altura normal deles corretamente.
> Sim, aplica

## Decisão

1. Remove D-339 (inimigos ×2,16) e D-342 (ally_scale 1,2 do Orc/Cyclops).
2. Todo modelo de batalha é escalado para **1,2 m** (criador: "1,2"; 2,2 m ficou grande demais) de altura, medido das próprias malhas; o mesmo personagem tem o mesmo tamanho como aliado ou inimigo.
3. A legibilidade dos inimigos ao fundo passa a ser trabalho da câmera (D-1008).

## Ambiguidade

- Uma altura só para todos (inclusive o Cyclops, que antes era maior). Ajustar por tamanho de espécie é decisão futura.

## Estado

Implementado para revisão.

> **D-1034 (2026-11-09):** a altura de **1,2 m** valia também para o trio DQT; essa parte foi **superada por D-1043** após o teste visual. **D-1043:** o DQT usa as proporções dos perfis (Orc 2,1 / Slime 1,4 / Cyclops 2,5 com teto), enquanto os Pokémon comuns continuam em 1,2 m. **D-1046:** o criador pediu **+30% em todos**; o alvo dos Pokémon comuns passou a **1,56 m**, com teto de 2,5 m para os DQT. **D-1047:** o criador pediu para reverter tudo; o jogo voltou à escala anterior, mantendo só **Cyclops 3,22 m** e **Slime 1,40 m** pelos perfis DQT. **D-1053:** o Cyclops foi ajustado para 3,58 m; **D-1054:** depois para **4,00 m**.
