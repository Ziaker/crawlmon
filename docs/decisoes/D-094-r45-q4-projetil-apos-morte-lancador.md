<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-094 — R45-Q4 (4A): Projétil lançado persiste após morte do lançador

- **Data:** 2026-11-03
- **Área:** Combate / Rodada 45
- **Origem:** decisão expressa do criador, R45-Q4.
- **Estado:** decisão de design aprovada; implementação não verificada.

## Declaração literal do criador

> 4A — Se um personagem lançar um projétil e morrer antes de ele atingir o alvo, o que acontece? O projétil permanece ativo e pode atingir normalmente o alvo.

## Regra aprovada

Um projétil **já lançado** continua ativo após a morte de quem o lançou e **pode atingir normalmente seu alvo**. Não cancelar o projétil exclusivamente pela morte posterior do lançador.

## Referências e limites

- **Decisões relacionadas:** D-004; D-009; D-019; D-037; D-047; D-058.
- **Limite / pendência:** A regra não redefine efeitos de interrupção antes do lançamento, nem altera alvo, velocidade, dano ou trajetórias já estabelecidos.
- **Escopo:** registro documental somente; nenhum código, VFX, teste ou dado de jogo modificado.

## Conciliação posterior (2026-11-03)

A persistência do projétil lançado após a morte do lançador continua válida **enquanto o combate puder prosseguir**. **Exceção explícita D-105:** quando o inimigo derrotado é o **último inimigo presente**, a vitória é definitiva imediatamente; qualquer projétil pendente **não causa dano nem altera o resultado**. Não foi decidido se o efeito visual do projétil desaparece ou completa sua trajetória.

## Complemento posterior — Rodada 49

D-107: a persistência do projétil vale enquanto o combate está em andamento. Após o KO da última unidade de qualquer equipe, o resultado é definitivo, e projéteis pendentes não causam mais dano nem alteram o resultado (D-105/D-107).
