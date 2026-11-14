<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1204 — Debug é obrigação extrema: nenhum teste leva mais de 1 minuto; qualquer milésimo do jogo é testável

- **Data:** 2026-11-13.
- **Área:** Processo / debug / telemetria.
- **Relacionadas:** D-1042, D-1044, D-1070, D-1154 (telemetria), D-235 (simetria), ordem "Testar SEMPRE no debug" (CLAUDE.md, 2026-11-13).
- **Status:** registrado; vale para todo agente, em todo documento.

## O que o criador disse (literal)

> me diz tudo no jogo que merece ter uma parte do debug com a obrigação extrema (atualize TODOS DOCUMENTOS, ENFIA 5 LINHAS DISSO NO INICIO DE TODOS PRA NUNCA ESQUECER)
>
> eu não quero ver teste NENHUM demorando mais do que 1 minuto pra ser feito, o debug foi feito pra testar qualquer MILÉSIMO do jogo se possível

## Decisão

1. **O debug é obrigação extrema**: existe para testar qualquer milésimo do jogo, se possível.
2. **Nenhum teste pode levar mais de 1 minuto** para ser feito (do pedido ao resultado).
3. Se não há caminho pronto no debug, o agente **cria o cenário/controle** (já valia pelo CLAUDE.md); não pede ao criador para montar nada.
4. **Cinco linhas fixas** com isso entram no **início de todos os documentos do projeto** (bloco marcado `DEBUG-OBRIGATORIO-D1204`, inserido por script idempotente `tools/inserir_bloco_debug.py`).
5. Escopo da inserção: `AGENTS.md`, `CLAUDE.md`, `docs/**` (incluindo todos os `D-*.md`), `prototypes/**`, `documentos/**` e `.md` da raiz. **Fora**: `addons/`, `assets/`, `skills/`, `.claude/`, `.agents/` (código/documentação de terceiros) e `docs/vfx/referencias/` (pesquisa externa).

## Pendente (recomendação da IA, o criador decide)

- Quais áreas do jogo ganham cenário de debug com meta de < 1 min (lista proposta na resposta da sessão; nenhuma foi aprovada ainda).
- Se o limite de 1 minuto vale também para suítes completas (`--test-all-moves-matrix`) ou só para um teste individual.

## Ambiguidades

- "Todos documentos" foi lido como todos os `.md` do projeto, exceto os de terceiros listados acima.
