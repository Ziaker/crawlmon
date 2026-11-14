<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-986 — Janela de Evade: VFX no atacante no estilo de Metroid Dread

- **Data:** 2026-11-08.

## Frase literal do criador

> é o de dread, e não é só o corpo que pisca, é um vfx amarelo assim

(com dois prints de Metroid Dread: o aviso de Melee Counter — estrela branco-amarelada com raios longos e finos dentro de um anel dourado fino, no ponto do corpo que vai atacar).

## Decisão

1. Na janela de Evade (os últimos 0,25 s antes do golpe de um inimigo, D-283), aparece no atacante um **estouro em estrela** branco-amarelado (núcleo quente, raios longos e finos alternando tamanho) **dentro de um anel dourado fino**, virado para a câmera.
2. Fica na **parte de cima e da frente do corpo real do atacante**, na direção do alvo; o tamanho vem da altura do corpo (D-235).
3. O anel abre em 0,06 s e o efeito some em 0,1 s depois que a janela fecha.
4. Só nos ataques de inimigos (é o aviso para o jogador). Só visual (D-019).
5. Substitui o destaque dourado que a etiqueta de wind-up tinha (D-985).

## Estado

Implementado para revisão em vídeo.
