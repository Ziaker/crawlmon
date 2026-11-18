<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1299 — Passos de posição: sem trava, sem custo de ATB, em fila; e a IA passa a usar a posição

- **Data:** 2026-11-17
- **Área:** Combate / IA
- **Estado:** **implementado e testado por lógica (headless, os dois lados). Visual/feel aguarda o criador.**
- **Substitui da D-018:** o custo de 1 ATB por passo e todos os bloqueios (preparo/execução do ataque, ataque em curso, engajamento, "andando", pausa de status, Guard, atordoamento). Continuam da D-018: posição de −2 a +2, +10 % de dano causado por passo à frente, −10 % de dano recebido por passo atrás.

## O que o criador disse (literal)

> "as mudanças de posição não deviam ter lock, só ficarem em queue é ok que nem já acontece com aliados que realizam logo após ficarem ociosos, além de não precisar mais gastar ATB pra trocar a posição. Além disso NUNCA vejo a IA realizando troca de posição e quero suas recomendações críticas sobre"

> "se eu mandei tirar é pq é pra tirar, não é pra ficar preservando coisa que já mudei por vontade própria"

> "não existe mais bloqueios, eles são redundantes, é pro personagem se mover no momento que ficar ocioso, no caso, idle"

> "faça a IA usar a mecânica de uma forma estratégica"

## Decisão

1. Um passo não custa ATB e não tem trava. Se o combatente está ocupado (preparando/executando Move, retornando, engajado, atordoado, em Guard ou durante a pausa de status), o passo fica na fila e roda assim que ele ficar ocioso. Passos pedidos várias vezes somam na fila, sempre dentro de −2..+2. Só é recusado o passo que passaria de −2..+2.
2. A IA escolhe sozinha onde ficar (`scripts/combat/battle_positioning.gd`); a posição que o jogador define no Tactics para um aliado continua valendo, e o líder controlado pelo jogador não usa IA. Cada posição de −2 a +2 recebe uma nota, na mesma escala dos Moves: o que meu próximo golpe vale ali (com bônus de nocaute) menos o que os golpes que espero levar custam ali (com risco de morrer) menos um pequeno preço por passo andado. Como a posição vale no instante do golpe e ninguém anda durante o próprio ataque, isso produz sem regra por papel:
   - **bate-e-corre:** logo depois de atacar não há ganho à frente e a IA recua; quando o ATB está para encher, avança para o golpe;
   - **desvio por passo:** um ataque já em voo contra ela é dano certo; se está ociosa e dá tempo de o passo terminar antes do impacto, recua;
   - **empurrão de nocaute:** se o +10% por passo é o que faz o golpe matar, ela avança;
   - **sobrevivência:** quando um golpe a mataria na posição atual e o recuo a salva, ela recua mesmo com golpe pronto;
   - **papéis:** quem não tem golpe de dano (curandeiro/buffer) só tem o lado da defesa e fica atrás sempre que há ameaça; quem bate muito mais forte do que apanha avança, e quem apanha muito mais forte do que bate recua.
   Valores que são escolha minha, ajustáveis: horizonte de 4 s, preço de 1,5 por passo, reavaliar a cada 0,3 s, nocaute = 40 pontos (o mesmo da IA de Moves).

## Causa de a IA nunca trocar (medido)

A IA só dava passo quando `tactic_pos` era diferente da posição, e `tactic_pos` só era alterado pelo menu Tactics do jogador, só para aliados. Inimigos nunca tinham `tactic_pos`; 0 passos em 120 s simulados.

## Crítica (recomendações, não implementadas)

- Sem custo e sem trava, avançar para +2 é quase sempre vantajoso para quem ataca, e recuar para −2 para quem defende. A posição vira uma escolha de papel mais do que uma decisão a cada instante. Se o criador quiser mais tensão, as opções são um tempo de exposição durante a caminhada (0,35 s hoje) ou limitar a quantidade de passos por intervalo. Fica em aberto até ele pedir.
- Os números da IA (horizonte, preço do passo, bônus de nocaute) são meus; ver se o criador prefere outros.

## Ambiguidades em aberto

Nenhuma sobre o que foi pedido.
