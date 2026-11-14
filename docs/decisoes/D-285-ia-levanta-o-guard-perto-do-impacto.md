<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-285 — A IA levanta o Guard perto do impacto, não no começo do wind-up

- **Data:** 2026-11-05
- **Área:** Combate / IA / Guard
- **Origem:** Conversa

## O que o criador disse (literal)

> "a IA tá usando guard no segundo que o atacante COMEÇA a fazer o wind-up do ataque, isso faz com que ela NUNCA bloqueie o dano."

## Decisão

1. A IA continua sorteando se vai usar Guard quando um ataque é declarado contra ela (25%, D-272/D-116), mas **levanta o escudo só perto do impacto**, para o Guard (2 s) estar ativo quando o golpe chega.
2. O escudo sobe quando faltam **entre 0,8 s e 1,3 s** para o impacto (sorteado por ataque; escolha do assistente, o criador não deu o número). Antes disso o alvo não gasta o ATB.
3. Se na hora o alvo não puder (sem ATB, em ação, atordoado) ou o ataque já foi desviado/interrompido/cancelado, nada acontece.
4. Vale só para ataques de dano contra inimigos (amigáveis e de status não, como antes).

## Estado no código

Implementado (2026-11-05): `Battle._roll_ai_guard` (sorteio na declaração), `Incoming.ai_guard_eta`, `Battle._step_attacks`.
