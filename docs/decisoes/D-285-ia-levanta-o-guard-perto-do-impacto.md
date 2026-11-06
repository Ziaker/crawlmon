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
