<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-057 — R41-Q7 (7A): Onda AoE em velocidade espacial constante

- **Data:** 2026-11-02
- **Origem:** decisão direta do criador, R41; eventuais complementos posteriores estão reproduzidos abaixo.
- **Estado:** decisão de design aprovada; nenhuma implementação afirmada por este documento.

## Declaração do criador (literal)

> 7A — Como a onda de projétil AoE determina o momento de atingir cada alvo?: Velocidade constante no espaço; cada alvo recebe o impacto conforme sua distância.

## Regra aprovada

A onda AoE se propaga no espaço a velocidade constante, atingindo cada alvo conforme a distância e o instante de chegada.

## Relações e questões de compatibilidade

- **Referências:** D-009; R39-Q7; R40-Q9.
- **Observação:** Não presume uma velocidade numérica universal; poderá ser estabelecida por Move.
- **Implementação:** não modificar comportamento do jogo apenas pela criação deste registro; avaliar divergências antes da implementação.
