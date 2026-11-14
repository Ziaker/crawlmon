<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1024 — Trajeto mais discreto e ponto de choque previsto entre corredores

- **Data:** 2026-11-08.
- **Origem:** Conversa.

## Frase literal do criador

> a largura está ok, só quero que reduza a opacidade do trajeto
> quando 2 personagens estão prestes a se entrarem em trajeto para se golpearem, mostrar onde eles vão colidir no trajeto, com um efeito visual de choque (não eletrico) entre ambos

Respostas:

- Opacidade: **"A 70% do atual"**.
- Quando o ponto aparece: **"Só se os dois já estão em wind-up"** (some se um cancelar).
- Quais pares: **"Qualquer cruzamento"** (frente a frente e também alvos diferentes cujas corridas se cruzam; D-279).
- Efeito: **"Anel de pressão + marca"** (anel de choque no chão pulsando e um X no ponto, com poeira leve; sem raios).

## Decisão

1. A opacidade do trajeto (D-1013/D-1019) cai para **70%** do valor atual; a largura não muda.
2. Quando dois atacantes de **times opostos** estão em wind-up e suas corridas vão se cruzar, o jogo mostra **onde elas vão colidir**:
   - frente a frente (um mira o outro, ou trajetos quase colineares): o ponto é estimado com a velocidade de corrida `RUN_SPEED` e o tempo que falta para cada um começar a correr, no ponto de contato do choque (`CLASH_DIST`, D-279);
   - alvos diferentes: o ponto é o cruzamento dos dois trajetos.
3. O marcador é um anel de pressão que pulsa (dois anéis em fase oposta, mais um anel tracejado externo) com um X e poeira leve; fica mais forte conforme os wind-ups avançam. Não é elétrico.
4. Só aparece enquanto os dois estão em wind-up; some se um deles cancelar, for interrompido, desviar, morrer ou terminar o wind-up (a corrida começa).
5. Por D-235: nada depende de personagem, time (só "lados opostos"), lado da câmera ou Move.

## Ambiguidades em aberto

- A estimativa ignora a aceleração da corrida e o `RUN_START` exato de cada Move: o ponto real do choque pode diferir um pouco.
- Aliados no mesmo alvo e atacantes do mesmo time não mostram o ponto (não se chocam, D-279).
- 3 ou mais corredores: um marcador por par.

## Estado

Implementado para revisão (`scripts/combat/fx/fx_lane.gd`).
