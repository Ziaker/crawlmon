<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-058 — R41-Q8 (8A): Alvo morto antes da chegada da onda

- **Data:** 2026-11-02
- **Origem:** decisão direta do criador, R41; eventuais complementos posteriores estão reproduzidos abaixo.
- **Estado:** decisão de design aprovada; nenhuma implementação afirmada por este documento.

## Declaração do criador (literal)

> 8A — Se um alvo estava vivo na declaração do AoE, mas morreu antes da chegada da onda?: A onda atravessa a posição do alvo morto sem novo dano nem reação.

## Regra aprovada

O alvo incluído por estar vivo na declaração permanece referenciado, mas, se morrer antes da chegada da onda, a passagem não causa novo dano nem reação. Não selecionar alvo substituto.

## Relações e questões de compatibilidade

- **Referências:** D-007; D-009; D-011; R39-Q7.
- **Observação:** A semântica de desaparecimento de corpos fatais não autoriza substituição de alvos.
- **Implementação:** não modificar comportamento do jogo apenas pela criação deste registro; avaliar divergências antes da implementação.
