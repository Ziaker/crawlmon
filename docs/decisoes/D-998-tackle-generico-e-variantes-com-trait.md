<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-998 — Tackle genérico e variantes de Tackle com trait

- **Data:** 2026-11-08.

## Frase literal do criador

> sim eu quero, inclusive atualize o gdd para regras assim para personagens específicos
> O nome tackle é o generico pra todos, mas se o tackle deles tiver outro nome, é pq tem uma trait diferente.

## Decisão

1. **Tackle** é o golpe corpo a corpo básico, genérico, de todos.
2. Um personagem pode ter uma **variante de Tackle com outro nome**; o nome diferente indica uma **trait** própria do golpe.
3. **Spear Thrust** é a variante de Tackle do Orc. Trait: para a 7 unidades do alvo para acertar com a ponta da lança (D-996/D-997).
4. Compatível com D-235: a trait pertence ao **move** (o `move_id` da variante), não ao personagem; qualquer um que tenha a variante usa a mesma trait.

## Estado

Registrado; GDD atualizado (seção de variantes de Tackle). Sem mudança de código.
