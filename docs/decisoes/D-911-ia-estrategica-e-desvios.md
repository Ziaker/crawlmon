# D-911 — IA estratégica: variedade de Moves, desvios e reserva de ATB

> **Renumerada em 2026-11-06:** D-168 → D-911. O ID D-168 já pertence a outra decisão no `origin/main`; o conteúdo local foi preservado com o novo ID.


- **Data:** 2026-11-03
- **Área:** Combate / IA
- **Origem:** Conversa. Os critérios concretos são recomendação do assistente, aceita por delegação expressa (D-116); não são redação do criador.

## O que o criador disse (literal)

> inclusive faça com que a IA do jogo de ambos aliados e inimigo escolham mais outros moves e também voltem a executar desvios, sejam mais estratégicas do que diretas

## Causa medida (40 batalhas simuladas, antes da mudança)

0 desvios. Pancham usava só Tackle (Tactic padrão "Atacar", reação "Nada"). Gible gastava ATB em golpes de 1 custo assim que podia, nunca juntava os 3 ATB do Evade e sempre mirava o primeiro adversário vivo.

## Decisão

Implementa D-111, D-112, D-114 e D-115, valendo para aliados e inimigos (D-021).

1. **Ordem:** primeiro o alvo, aleatório entre adversários vivos, respeitando engajamento. Depois o Move (D-114).
2. **Escolha do Move:** cada Move recebe uma nota pela situação:
   - dano proporcional à vida do alvo, nocaute, fraqueza e todos os alvos de um AoE;
   - efeitos de contato, custo e chance de interromper o preparo do alvo;
   - Media pela vida que falta, Tarukaja/Rakunda/Sukunda pelo ganho restante, Sand Attack se o alvo não está cego, Taunt para proteger um aliado ferido.
3. **Variedade:** sorteio ponderado entre os Moves com nota de pelo menos 70% da melhor. Repetir o último Move reduz a nota em 40%.
   - A IA escolhe o Move mesmo sem ATB para ele e **economiza** até poder pagar, em vez de gastar no que já consegue pagar. Muda de plano se o golpe deixar de fazer sentido ou se um nocaute ficar disponível.
4. **Poção:** concorre com os Moves pela nota; sem limite fixo de HP (D-115). Em "Segurar", continua com a regra antiga de 50%.
5. **Reserva de ATB:** quem reage com Esquivar guarda ATB. Sob ataque, se puder chegar a 3 ATB antes do impacto, guarda os 3; sem ameaça, guarda 1. Nocaute e Burst dispensam a reserva.
6. **Desvios:** a chance continua igual à velocidade (D-021). No próprio trajeto, a IA só desvia na janela perfeita, porque fora dela perderia o ataque (D-029).
7. **Ritmo:** a IA decide a cada 0,25 s e só começa outra ação depois de terminar a anterior, retorno incluído (como o jogador, D-904).
8. **Padrão do aliado:** Pancham começa com "Habilidades" e "Esquivar". O jogador ainda pode mudar em Tactics. A Tactic "Atacar" continua usando só Tackle.

## Ambiguidades em aberto

D-040 dizia que a IA pode agir assim que tem 1 ATB. Isso continua valendo para quem não reage com Esquivar; quem esquiva agora guarda a reserva do item 5. Os pesos são calibração inicial e podem mudar. D-116 cobre recomendações sobre a IA, sem autorizar outras mecânicas.

## Estado no código

Implementado (`scripts/combat/battle_ai.gd`, `battle.gd`, `game_state.gd`).
