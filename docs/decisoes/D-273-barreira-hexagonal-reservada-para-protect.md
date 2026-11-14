<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-273 — A barreira em cúpula fica guardada para um futuro Move "Protect"

- **Data:** 2026-11-05
- **Área:** Combate / VFX
- **Origem:** decisão direta do criador, na conversa.
- **Estado:** barreira preservada em `scripts/combat/fx/fx_barrier.gd`, **sem ligar a nenhum Move**; o Move Protect ainda não existe.

## Declaração literal do criador

> me proponha melhorias para o efeito visual do escudo em si, inclusive não descarte aquela barreira, usaremos ela pra um eventual move de protect

## Regra aprovada

- **A barreira em cúpula não é descartada.** O Guard usa o escudo (D-272); a cúpula fica reservada para um **eventual Move "Protect"**.
- A cúpula guardada é a versão **casca única e lisa com células hexagonais** (azul translúcido, linhas ciano, brilho no encontro com o chão), com a quebra em pedaços ao contato. Os estilos "bolha" e "nervuras" ficam no código como alternativas.
- Como todo Move e efeito, a barreira não pode depender de personagem, time ou lado (D-235).

## Ambiguidades em aberto (perguntar antes de agir)

- Como o Move Protect funciona (custo, duração, o que bloqueia, se cobre o time inteiro); nada disso foi definido.

## Estado no código

`FxBarrier` (`scripts/combat/fx/fx_barrier.gd`) existe e compila, mas **não é criado em `BattleFx` nem usado** por nenhum Move.

> **Renumeração (2026-11-05):** este registro foi criado localmente com outro número (D-19x) que colidia com as decisões das Rodadas 68-82 do GitHub (D-192 a D-268). Por escolha do criador passou a ser **D-273**; texto e regras não mudaram.
