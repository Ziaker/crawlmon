<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-010 — AoE: dano igual para todos e recompensa de ATB uma vez por golpe

- **Data:** 2026-11-02
- **Área:** Combate
- **Origem:** Conversa

## O que o criador disse (literal)

> ... A, uma vez por golpe, ... (respostas 6 e 7)

## Decisão

**6A:** todos os alvos de um AoE levam o **mesmo dano (100%)**. **7:** a recompensa de ATB do atacante por fraqueza/crítico é **uma vez por golpe**, não por alvo.

## Ambiguidades em aberto (perguntar antes de agir)

Como combinar quando só alguns alvos são fracos/críticos (regra global +1 fraqueza / +2 crítico, ou outra)? Perguntado, sem resposta.

## Estado no código

**Não implementado** (hoje 100% no principal, 85% nos outros).
