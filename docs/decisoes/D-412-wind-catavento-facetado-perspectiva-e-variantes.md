<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-412 — Wind: Direção do Catavento Geométrico Facetado, Perspectiva e Variantes

- **Data:** 2026-11-07
- **Área:** UI / Moves / Elementos / Combate / Regras
- **Origem:** escolha expressa do criador ao avaliar as opções do Canva.
- **Estado:** regra registrada; produção de arte em andamento; aguardando aprovação da variante final.

## Declaração literal do criador

> "quero mais opções, só gostei da terceira, mas ela é basica, aplique um pouco de perspectiva nela e me de outras 3"

## Regras aprovadas

1. **Aprovação da Direção do Catavento Geométrico (Opção 3 do Canva):**
   - A linguagem preferida e ratificada para o elemento **Wind** é a do **catavento geométrico facetado** (lâminas poligonais densas, anguladas e mecânico-eólicas em preto sólido sobre `#4ff7ba`).
   - Ficam descartadas as opções 1 (ciclone tríplice fluido) e 2 (tornado demoníaco).

2. **Aplicação de Perspectiva Dinâmica:**
   - A versão base deve receber uma inclinação de perspectiva (tilt eólico em torno de 15° a 25°), quebrando o aspecto plano/básico e conferindo profundidade tridimensional ao plano de rotação.

3. **Geração de 3 Variantes Complementares:**
   - Devem ser produzidas 3 variações adicionais baseadas no mesmo DNA geométrico facetado, explorando chanfros, aerodinâmica angular, cortes de profundidade e lâminas eólicas estilizadas.

## Relação com decisões anteriores

- Valida a linha conceitual de **D-409** (catavento e perspectiva a 20°) combinada com a massa densa de **D-411**, afinando o design aprovado da Opção 3 do Canva.
