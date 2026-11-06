# D-316 — Descanso ao pisar, cura da equipe ativa, 3º em 10%; expedição de 5 andares

- **Data:** 2026-11-05
- **Área:** Exploração
- **Origem:** Conversa (respostas Q7, Q8 e F4 do plano do overworld)

## O que o criador disse (literal)

- Q7 — descanso: > Pisar; equipe ativa; 3º em 10%
- Q8 — andares: > 5 andares; volta ao início
- F4 — o que acontece no 5º andar: > Nova dungeon

## Decisão

1. O ponto de descanso é ativado **ao pisar**, cura a **equipe ativa** e cada ponto só pode ser usado uma vez.
2. Cada andar tem **2 pontos**, com **10% de chance** de um terceiro.
3. A expedição tem **5 andares**. Ao usar a escada do último andar, começa uma **nova expedição completa**: andar 1, nova seed, MP cheio e Natures novas; mantém a equipe, os itens e o HP.

## Ambiguidades em aberto

- A cura é só da equipe ativa; o que acontece com reservas (se existirem)?
- O descanso pode ser usado durante uma batalha ou só na exploração?
- Inimigos derrotados e itens do andar são resetados junto com a nova seed? (nova expedição sugere que sim; confirmar)

## Estado no código

Não implementado. Detalha a D-311.

**Atualização 2026-11-06:** o reset de derrota já recomeça no **andar 1** com nova seed/bioma (`visual_floor = 1`, `biome_seed = 0`, `new_dungeon(0, false)`), conforme R23-Q3/R33-Q1 e D-317. A expedição real de 5 andares, a escada, o MP cheio, as Natures novas e os pontos de descanso continuam pendentes.
