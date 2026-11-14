<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-123 — Rodada 54 Q4 (B): Magia escala dano e apenas efeitos declarados escaláveis por Move

- **Data:** 2026-11-03
- **Área:** Atributos e identidade de espécies / Rodada 54.
- **Proveniência:** resposta expressa do criador; os textos marcados como recomendação aceita foram originalmente sugeridos pelo assistente, mas **a alternativa foi selecionada diretamente pelo criador**.
- **Estado:** regra de design aprovada e documentada; sem implementação nesta atividade.

## Declaração literal da resposta do criador

> 4B — Magia aumenta dano mágico e somente os efeitos que cada Move definir como escaláveis.

## Regra aprovada

- Magia aumenta **dano mágico** e **somente os efeitos explicitamente definidos como escaláveis** pela ficha de cada Move.
- Não aumentar automaticamente os estágios de buffs/debuffs ou o efeito de curas cuja escala não tenha sido definida para o Move.
- Preservar estágios de buffs existentes e regras de custos de ATB/Burst e MP relacionadas à progressão.

## Referências, pendências e limitação

- **Referências:** D-012; D-014; GDD R11–R14; Skill.gd.
- **Ainda não definido:** Quais Moves escalam cura, duração ou intensidade por Magia; magnitude, fórmula e limites.
- **Sem implementação:** não alterar nem presumir alteração de código, recursos, dados de personagens ou testes.
