<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-079 — R43-Q8 (8A): Lançamento fatal afastando do atacante

- **Data:** 2026-11-03
- **Área:** Combate / Rodada 43
- **Estado:** decisão de design registrada após delegação às recomendações; implementação não afirmada.
- **Proveniência:** o usuário não informou letras individualmente. Ele respondeu literalmente **“Sigo suas recomendações”**. As alternativas abaixo foram **selecionadas e recomendadas pelo assistente**, com essa autorização geral. Não atribuir ao usuário a redação das alternativas.

## Autorização literal do usuário

> Sigo suas recomendações

## Pergunta e alternativa recomendada pelo assistente (não são citação do usuário)

- **Pergunta:** Em qual direção o personagem deve voar após um hit fatal?
- **Escolha recomendada:** **8A — Para longe da posição de quem aplicou o golpe fatal.**

## Regra consolidada

O personagem atingido por um hit fatal é lançado **para longe da posição de quem aplicou o golpe fatal**. Preservar intensidade visual padronizada para todos os Moves (D-069): inimigos caem e desaparecem; aliados caem e permanecem visíveis.

## Referências e limitações

- **Decisões relacionadas:** D-056, D-068, D-069.
- **Pendência:** Não foram definidos valores de ângulo vertical, distância, velocidade, duração ou parâmetros de colisão com cenário.
- **Escopo:** documentação somente, sem mudança de código, FX, configurações ou testes.

## Complemento posterior (2026-11-03)

**D-160:** para inimigos, o lançamento fatal passa a ser sempre para longe de onde os jogadores estão, e não de quem aplicou o golpe.
