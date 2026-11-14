<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-026 — Remover o Evade e a mecânica de trajeto; corrida física mais rápida

- **Data:** 2026-11-02
- **Área:** Combate
- **Origem:** Conversa

## O que o criador disse (literal)

> quero que vocÊ corrija os problemas de VFX não estarem sendo executados, aparecendo blocos quadrados no lugar, remova tudo e qualquer coisa relacionada a mecânica de trajetos, mas mantenha o movimento dos personagens quando vão realizar um ataque físico, só deixe mais rápido
>
> tira tudo relacionado ao evade também, tira tudo acaba com tudo, eu não sei mais oq fazer
>
> NÃO TEM NENHUMA OUTRA SESSÃO VAMO LOGO
>
> mas QUEM pediu pra tirar burst?

## Decisão

1. **Sai todo o Evade:** manual (Espaço, botão do menu, whiff, interrupção, chegada, engajamento, golpe de graça, câmera lenta, MISS!), esquiva automática e reação de esquiva da IA (Tactics "Reação").
2. **O Burst FICA** (o criador não pediu para tirar). Observação: hoje ele só era ganho desviando; sem Evade, não há como ganhá-lo até o criador definir outra fonte.
3. **Sai toda a mecânica de trajeto:** janela de desvio no trajeto, tempo de trajeto que muda com a posição, interceptação de projétil.
4. **Os passos de posição FICAM** (−2..+2, 1 ATB, dano ±10%, marcas no HUD); só deixam de mexer no tempo de trajeto.
5. **Fica** a corrida do personagem até o alvo no ataque físico (e a volta), **mais rápida**.
6. Corrigir os VFX que aparecem como blocos quadrados.

Revoga D-005, D-006, D-016, D-017, a fórmula de trajeto de D-018, D-021 (reação da IA no trajeto) e o item 6 de D-024.

## Ambiguidades em aberto

- Quanto mais rápida a corrida: não foi dito. Usado **metade do tempo** atual; confirmar.
- Como o Burst passa a ser ganho sem o Evade: não definido.

## Estado no código

**Cancelada.** O criador mandou restaurar o código do GitHub antes da aplicação; nada desta decisão está no código.
