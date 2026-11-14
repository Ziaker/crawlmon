<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1161 — NULL, REPEL e DRAIN ficam fora; só Neutral, Weak e Resist

- **Data:** 2026-11-11
- **Área:** Combate / afinidades / escopo.
- **Origem:** correção direta do criador.
- **Estado:** regra registrada; só `NEUTRAL`, `WEAK` e `RESIST` são usados.

## Declaração literal do criador

> "não usaremos null e nem repel ainda"

> "sim, vamos só usar Resist Weak e Neutral"

## Regra aprovada

- **Conjunto ativo: `NEUTRAL`, `WEAK` e `RESIST`.** Só esses três podem aparecer em dados, Moves, UI e testes de conteúdo.
- **`NULL`, `REPEL` e `DRAIN` ficam fora.** Continuam no enum `Affinity.Type` apenas como reserva de schema para o futuro, mas não podem ser usados agora.
- `Affinity.damage_multiplier(NULL/REPEL/DRAIN)` continua **1,0** (inertes). Não há anulação, reflexão ou drenagem.
- O `CharacterFactory` emite aviso e **ignora** uma entrada explícita `NULL`/`REPEL`/`DRAIN` vinda de `CharacterData.affinities`.
- `WEAK` 1,5× e `RESIST` 0,5× continuam como em D-1157/D-1158.
- Nenhum número de dano muda.

## O que não muda

- Nenhuma espécie atual recebe `NULL`/`REPEL`/`DRAIN`.
- A UI pode manter os nomes no enum, mas não deve exibir `Nul`/`Rep`/`Drn` para nenhuma espécie atual.
- `DRAIN` não é o próximo passo; se um dia voltar, precisa de decisão própria.

## Estado no código

- `scripts/data/affinity.gd`: reserva documentada.
- `scripts/combat/character_factory.gd`: aviso + skip de `NULL`/`REPEL`/`DRAIN`.
- `scripts/ui/level_up_hud.gd`: só exibe Wk/Res.
- Teste D-1157 verifica que os três permanecem 1,0 e são ignorados pela fábrica.
- Nada de commit/push sem autorização (D-022).
