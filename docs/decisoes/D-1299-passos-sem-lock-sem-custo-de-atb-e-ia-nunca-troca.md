<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1299 — Passos de posição: sem lock, só fila, sem custo de ATB; e a IA nunca troca de posição

- **Data:** 2026-11-17
- **Área:** Combate / IA
- **Estado:** **registrada; NÃO implementada — conflita com D-018 e tem ambiguidades (abaixo). Aguarda o criador.** A parte da IA é só análise (recomendações abaixo), sem mudança de IA.
- **Relacionadas:** D-018 (passos: 1 ATB, bloqueado em ataque/engajamento), D-021 (inimigos usam as mesmas Tactics), D-1146 (passo bloqueado na pausa de status), D-161 (fila de 1 vaga), D-168.

## O que o criador disse (literal)

> "as mudanças de posição não deviam ter lock, só ficarem em queue é ok que nem já acontece com aliados que realizam logo após ficarem ociosos, além de não precisar mais gastar ATB pra trocar a posição. Além disso NUNCA vejo a IA realizando troca de posição e quero suas recomendações críticas sobre"

## Conflito (preservo as duas; pergunta ao criador)

D-018 diz "1 ATB por passo" e "bloqueado durante preparo/execução do próprio ataque, ataque em curso que o envolva e engajamento". A frase acima pede o contrário. Pergunta: **a frase nova substitui esses trechos da D-018?**

## Ambiguidades em aberto (perguntar antes de agir)

1. Quais travas somem? Hoje o `can_step` bloqueia por: pausa de status (D-1146), Guard, engajamento (Evade perfeito), "andando" (passo anterior em curso, 0,35 s), windup/ação própria, ataque em curso envolvendo o combatente (atacante ou alvo), atordoamento, ATB < 1.
2. "Ficar em queue": o passo pedido espera a vaga (como o Move em `queued_skill`) e roda quando o combatente fica livre? Substitui um passo/Move já na fila (vaga única, D-161)? Um passo na fila ocupa a mesma vaga do Move?
3. Sem ATB: o passo continua "dentro do Tactics" (que pausa) ou passa a ser um comando direto? Continua limitado a −2..+2?

## Análise: por que a IA nunca troca de posição (dados)

Diagnóstico headless, IA contra IA, 2×2, 120 s simulados por rodada, comando e script em `side-session-notes` (`ai_step_diag.gd`):

- **Padrão (nada configurado): 0 passos em 120 s.** `BattleAI.run` só dá passo se `tactic_pos != pos_step` (`battle_ai.gd:43`). `tactic_pos` vale 0 em todo mundo e só o menu Tactics do **jogador** o altera (`battle_scene.gd:1818`), e só para aliados. **Inimigos nunca recebem `tactic_pos`**, apesar de D-021 ("inimigos usam as mesmas Tactics"). A IA não tem nenhuma decisão própria de posição: não existe pontuação de passo.
- Com `tactic_pos=+1` em todos: 3 passos (um por quem quis; os demais já estavam parados no alvo). Em 2401 quadros de "quer andar", **1241 (52 %) estavam bloqueados por "ataque em curso"** e 1160 livres: o lock atual atrasa bastante.

## Recomendações (não implementadas; rotuladas "recomendação")

1. **Recomendação:** dar à IA uma decisão de posição própria (pontuada como os Moves, D-168), em vez de depender de `tactic_pos`. Sem isso, nenhuma mudança de lock/custo altera o que você vê, porque ninguém pede o passo.
2. **Recomendação:** pontuar o passo por papel e pela regra D-018 (+10 % dano causado por passo à frente do atacante; −10 % dano recebido por passo atrás do alvo): corpo a corpo/alto dano vai à frente; quem está com pouca vida ou é suporte recua; voltar a 0 quando um Move exigir. Os pesos são decisão do criador.
3. **Recomendação (crítica):** com custo 0 e sem lock, ir à frente no máximo é quase sempre melhor para quem ataca e recuar no máximo para quem defende; a IA otimizaria sempre os extremos e o jogador também. Sem custo, o jogo precisa de outro contrapeso (por exemplo tempo de caminhada de 0,35 s com o combatente exposto, ou o passo ocupar a vaga da fila) para a posição ser escolha e não obrigação. Decisão do criador.
4. **Recomendação:** dar aos inimigos os mesmos `tactic_pos` iniciais dos aliados (D-021) apenas depois de o criador definir as regras acima; é a menor mudança que acorda a IA inimiga.
5. **Recomendação:** adicionar `GameTrace`/evento `step` com motivo de bloqueio na fila (`block_reason`) ao `docs/TELEMETRIA.md`, para medir a fila de passos depois de implementada.
