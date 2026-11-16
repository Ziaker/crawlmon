<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1248 — Murky Forest: gatilho de revisita e ordem das visitas

- **Data:** 2026-11-16
- **Área:** overworld 3D / level design / eventos de expedição
- **Relacionadas:** D-1245, D-1246, D-1247, D-1208, GDD R29-Q2/Q3, R34-Q2, R36-Q2.
- **Estado:** aprovada; nenhuma implementação.

## Frases literais do criador

> "Marca no cenário + fala curta no Hub (Recomendado)"

> "1ª aprender, 2ª novidade — sem tranca (Recomendado)"

## Decisão

1. **Gatilho (E1):** o evento de revisita é anunciado por uma **fala curta no Hub** e identificado dentro da mata por uma **marca no cenário**. Solução diegética: não criar quadro/UI novo para isso.
2. **Ordem (E2):** a **primeira** expedição ensina o espaço; a **segunda** traz a situação nova. **Não há tranca nem pré-requisito** — evento é opcional para chegar ao chefe (GDD R36-Q2) e não muda progressão (R34-Q2).
3. **Compatibilidade:** D-1245 (portas medidas, descanso pendente, gating suave, áudio fora), D-1246 (direção de revisitas) e D-1247 (só o arco como marco, nenhuma persistência entre expedições, recompensa só de descoberta) continuam valendo.
4. **Não decidido aqui:** conteúdo concreto da marca, texto da fala, quantidade de eventos e detalhes de apresentação — ficam para a implementação guiada pelo plano, sem inventar regra nova.

## Estado

Documento criado antes de qualquer código. Plano: `docs/plans/2026-11-16-murky-forest-level-design.md`. Nada publicado; nenhum commit/push.
