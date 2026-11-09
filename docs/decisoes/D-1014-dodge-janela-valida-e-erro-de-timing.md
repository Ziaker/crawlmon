# D-1014 — Dodge: botão livre só para o jogador, mas só desvia na janela; erro de timing = não desviou (corrige D-1006/D-1007)

- **Data:** 2026-11-08.
- **Origem:** Conversa.

## Frases literais do criador

> ta mas nem era pra ser possível dele realmente desviar do move sendo que nem mesmo foi disparado nele ou entrou em prelude, não era pra isso acontecer, achei que era óbvio
> "permita realizar o dodge a qualquer momento e não só num momento específico" isso no caso do botão ser permitido de ser usado e efetuado a qualquer momento, era pra ser específico pro jogador...

Respostas às perguntas:

> faz o dodge e erra, esse era pra ser a ideia, é o normal, o mesmo pro inimigo, se ele errar o timing então NÃO desviou
> Prelúdio + 0,25 s antes

## Decisão

1. **Corrige a D-1006:** "dodge a qualquer momento" vale só para o **botão do jogador**: ele pode apertar de qualquer momento (do início do wind-up até o contato). Quem aperta fora da janela **faz o dodge e erra**: gasta o ATB, o dodge é usado e o golpe **não** é evitado.
2. **A janela em que o desvio vale de verdade** (a mesma para o jogador e para a IA):
   - **Ataque físico (corpo a corpo):** o prelúdio, a janela de 0,25 s da D-988 (termina 0,25 s antes do contato, quando o atacante se ergue).
   - **Projétil e magia de área:** os **últimos 0,25 s** antes de acertar.
3. **Corrige a D-1007:** a IA mantém a mesma chance (pela SPD), mas só pode desviar **dentro da janela**: o instante sorteado fica na janela, nunca durante o wind-up. Se a IA errar o timing, não desviou.
4. Desvio válido continua sempre perfeito (D-283).

## Ambiguidades em aberto

- A IA, quando "errar o timing", hoje não tenta fora da janela (só desvia dentro dela); se ela deve também gastar ATB num erro fica a decidir.
- Não há animação própria de "dodge errado": só o gasto de ATB, o registro e a perda do golpe evitado.

## Estado

Implementado para revisão (`incoming.gd`, `battle_evade.gd`, `battle.gd`).
