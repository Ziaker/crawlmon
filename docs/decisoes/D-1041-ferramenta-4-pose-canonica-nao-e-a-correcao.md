<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1041 — Ferramenta 4: pose canônica não é a correção; DQT canônico é maior que os Pokémon

- **Data:** 2026-11-09
- **Área:** VFX / Ferramentas / D-1020
- **Origem:** resposta do criador à pergunta 1 da rodada de 2026-11-09.

## Frase literal do criador

> "a pose canonica dos DQT é muito grande comparado a dos pokemons, provavelmente não"

## Decisão

1. **Não corrigir por ora** `pose_height` trocando a medição para a pose canônica (bind/`battle_idle` em tempo fixo). O criador observa que a pose canônica dos DQT é muito maior que a dos Pokémon; usá-la não resolve a incoerência de tamanho.
2. A ferramenta 4 continua **reprovada** enquanto não houver uma leitura de altura que seja coerente com a escala real e com D-1013/D-1033.
3. A escala DQT (D-1013/D-1034) precisa ser resolvida antes de escolher a leitura oficial; a ferramenta não deve normalizar nem inventar altura.
4. Nenhum código da ferramenta 4 foi alterado por esta decisão.

## Ambiguidades em aberto

- O criador disse "provavelmente não", não um "não" definitivo. Se houver uma leitura alternativa (por exemplo, usar `mesh_height` como principal e `pose_height` só como diagnóstico), ela precisa ser escolhida antes de nova implementação.

## Estado

Regra registrada; ferramenta 4 continua como está e reprovada. Sem commit/push.
