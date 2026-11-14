<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-122 — Rodada 54 Q3 (A): Força determina base de dano físico e Magia determina base de dano mágico/especial

- **Data:** 2026-11-03
- **Área:** Atributos e identidade de espécies / Rodada 54.
- **Proveniência:** resposta expressa do criador; os textos marcados como recomendação aceita foram originalmente sugeridos pelo assistente, mas **a alternativa foi selecionada diretamente pelo criador**.
- **Estado:** regra de design aprovada e documentada; sem implementação nesta atividade.

## Declaração literal da resposta do criador

> 3A — Força determina a base do dano físico; Magia determina a base do dano mágico/especial.

## Regra aprovada

- A base do **dano ofensivo físico** usa **Força**. A base do **dano ofensivo mágico/especial** usa **Magia**.
- Preservar multiplicadores próprios de cada Move, fraquezas, críticos, etapas de buffs/debuffs, posicionamento e custos aprovados; não copiar fórmula externa.
- A categoria de dano físico versus mágico/especial precisa constar da ficha do Move; a forma geométrica (MELEE, PROJECTILE, CAST, STATUS) **não determina por si** qual atributo ofensivo deve escalar o dano.

## Referências, pendências e limitação

- **Referências:** D-001; D-019; D-117; Skill.gd; regras consolidadas §8.
- **Ainda não definido:** Fórmulas numéricas, escala de poder e classificação completa de Moves individuais; não aprovadas.
- **Sem implementação:** não alterar nem presumir alteração de código, recursos, dados de personagens ou testes.
