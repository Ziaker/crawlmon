<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-029 — Desvio não perfeito na corrida cancela e volta à origem; lado e tempo dos desvios

- **Data:** 2026-11-02
- **Área:** Combate
- **Origem:** Conversa

## O que o criador disse (literal)

> durante o ataque no trajeto do personagem caso ele desvie sem for perfeito, o ataque na verdade é cancelado e ele teleporta direto pra sua posição de origem ao invés de continuar o ataque, faça esta mudança
> inclusive pode me garantir que o personagem se move pra esquerda, sumindo e aparecendo ao desviar naturalmente e quando desvia com o botão? retornando a sua posição normal dps?

Respostas às ambiguidades: "1 no instante que aperta e erra o timing perfeito / 2 some e reaparece com os efeitos visuais correspondentes / 3 obviamente perde / 4 sim / 5 sim / 6 como era antes, pra esquerda da visão do jogador / 7 .5 segundos / 8 na verdade mantenha sem ele se mover mas sumindo e aparecendo / 9 sim / 10 - parado sim, na corrida não perfeito volta direto, no perfeito ele some e aparece na frente do inimigo, sem se deslocar pra esquerda / 11 não"

## Decisão

1. **Desvio não perfeito durante a própria corrida:** no instante em que aperta, o próprio ataque é **cancelado** (o ATB pago é **perdido**) e o personagem **some e reaparece na posição de origem** (o ponto do passo de posição), com os efeitos visuais. Ganha **+1 Burst**. Substitui o "o ataque segue" da D-027.
2. **Desvio manual parado:** some, aparece **para o lado, como antes** (aliados à esquerda da tela; não é igual para todos), fica **0,5 s** e volta à posição normal.
3. **Desvio perfeito na corrida:** some e aparece na frente do inimigo, **sem** ir para o lado (D-027).
4. **Desvio automático:** **não se move**; só some e reaparece no lugar, com as linhas de velocidade.

## Ambiguidades em aberto

Nenhuma.

## Estado no código

Implementado.
