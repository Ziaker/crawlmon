<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-018 — Reposicionamento: passos de −2 a +2

- **Data:** 2026-11-02
- **Área:** Combate
- **Origem:** PROMPT

## O que o criador disse (literal)

> posição inteira de −2 a +2 ... Custo: 1 ATB por passo ... o tempo do trajeto = base − 0,10 s × (posição de A + posição de T), mínimo 0,25 s ... +10% no dano que você causa por passo à frente; −10% no dano que você recebe por passo atrás

## Decisão

Posição inteira de **−2 a +2** por personagem (0 = meio, + = à frente). **1 ATB por passo**, sem outro efeito, dentro do botão Tactics (que pausa). Trajeto = `base − 0,10 s × (posição do atacante + do alvo)`, mínimo **0,25 s**. **+10%** de dano causado por passo à frente; **−10%** de dano recebido por passo atrás (até 2). Bloqueado durante preparo/execução do próprio ataque, ataque em curso que o envolva e engajamento. A IA usa passos conforme a Tactic.

## Ambiguidades em aberto (perguntar antes de agir)

Nenhuma.

## Estado no código

Implementado.
