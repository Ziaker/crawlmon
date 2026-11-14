<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-310 - Quatro níveis de ameaça dos inimigos no overworld

- **Data:** 2026-11-05
- **Área:** Exploração / IA
- **Origem:** Conversa (resposta à P3 do plano do overworld)

## O que o criador disse (literal)

> p3 - sim, depende do quão forte o mesmo é, inimigos tem 4 niveis de ameaça, 0 = medroso, que foge dos personagens lentamente ao invés de ir pra cima, 1 = fraco, que não corre atrás exceto se chegarem mt perto 2 = valente que caça normalmente os personagens se chegarem em sua linha de alcance e 3 = Perigoso, que caça os personagens com maior velocidade mas apenas dentro da sala que estão, se os personagens sairem de vista, ele para e patrulha normalmente pelo ambiente. Cada um tem um tamanho e um icone acima da cabeça que define o seu nível de ameaça (icone, não texto), o nivel é baseado também no nivel deles, então inimigos que eram fortes antes, podem ser fracos agora.

## Decisão

1. A detecção atual (linha de visão) está divergente da R38-Q1 e deve ser trocada por este sistema.
2. Níveis de ameaça:
   - **0 Medroso:** foge dos personagens, devagar, em vez de ir para cima deles.
   - **1 Fraco:** só persegue se os personagens chegarem muito perto.
   - **2 Valente:** caça normalmente quando os personagens entram no alcance dele.
   - **3 Perigoso:** caça com velocidade maior, mas só dentro da sala onde está; se os personagens saírem de vista, para e volta a patrulhar.
3. Cada nível tem um **tamanho** e um **ícone** (não texto) acima da cabeça.
4. O nível de ameaça leva em conta o nível do inimigo, de forma relativa: um inimigo que era forte antes pode passar a ser fraco depois.

## Ambiguidades em aberto

Fórmula do nível de ameaça (relativo a quê), distâncias, velocidades, tamanhos e ícones. Também falta definir de onde vem o nível dos inimigos do mapa, que hoje não têm nível.

## Estado no código

Não implementado.