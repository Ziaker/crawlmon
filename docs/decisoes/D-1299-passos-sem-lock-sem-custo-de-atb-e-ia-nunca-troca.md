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
2. A IA escolhe sozinha onde ficar (a posição que o jogador definir no Tactics para um aliado continua valendo, e o líder controlado pelo jogador não usa IA). Escolha da IA (critério do assistente, a pedido do criador de "usar de forma estratégica"; ajustável):
   - lutador saudável com algum golpe de dano vai para **+2**;
   - com menos de 40 % de vida recua para **−2** e só volta quando passar de 60 %;
   - quem não tem nenhum golpe de dano (curandeiro/buffer) fica em **−1**.

## Causa de a IA nunca trocar (medido)

A IA só dava passo quando `tactic_pos` era diferente da posição, e `tactic_pos` só era alterado pelo menu Tactics do jogador, só para aliados. Inimigos nunca tinham `tactic_pos`; 0 passos em 120 s simulados.

## Crítica (recomendações, não implementadas)

- Sem custo e sem trava, avançar para +2 é quase sempre vantajoso para quem ataca, e recuar para −2 para quem defende. A posição vira uma escolha de papel mais do que uma decisão a cada instante. Se o criador quiser mais tensão, as opções são um tempo de exposição durante a caminhada (0,35 s hoje) ou limitar a quantidade de passos por intervalo. Fica em aberto até ele pedir.
- Os números da IA (40 %, 60 %, +2, −2, −1) são meus; ver se o criador prefere outros.

## Ambiguidades em aberto

Nenhuma sobre o que foi pedido.
