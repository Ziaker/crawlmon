<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-286 — Quando o alvo se move durante o golpe, o atacante o alcança deslizando (sem teleporte)

- **Data:** 2026-11-05
- **Área:** Combate / trajeto / contato
- **Origem:** Conversa

## O que o criador disse (literal)

> "Tem vezes que quando um personagem ataca depois que o alvo se move, ele simplesmente se teleporta pra frente dele realizando o ataque (isso sem ser com o desvio perfeito)"

## Decisão

1. Causa: depois de D-054 a trajetória fica fixa durante o STRIKE e o contato é corrigido num instante só, no impacto (D-054). Se o alvo saiu do lugar (empurrado por um hit, pulando de volta, passo), o atacante saltava até ele no impacto.
2. Agora, se o ponto de contato do alvo se afastou **mais de 1,0 un** do ponto onde o atacante está, o atacante o **alcança deslizando a no máximo 45 u/s** até chegar (`AttackMotion.CATCHUP_SPEED`, `CATCHUP_MIN`; números do assistente). Deslocamentos pequenos (avanço e recuo do próprio golpe, até 0,6 un) não disparam isso, para não voltar o arrasto colado que D-054 corrigiu.
3. Isso **suaviza D-054**: o ajuste deixa de ser só no impacto e passa a ser limitado em velocidade. O correto no impacto continua exato (D-046).
4. Não vale após um choque (D-279), em ataques desviados, interrompidos ou cancelados.

## Ambiguidades em aberto

- Se o alvo estiver tão longe que 45 u/s não chega até o impacto, sobra um salto final menor.
- Se o atacante deveria, em vez de deslizar, retomar a corrida (opção 1 discutida na conversa).

## Estado no código

Implementado (2026-11-05): `AttackMotion.update(inc, delta)` e `_catch_up`, `Incoming.catching`.
