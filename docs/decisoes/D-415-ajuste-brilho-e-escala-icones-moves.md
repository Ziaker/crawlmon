# D-415 — Ajuste de Brilho dos Fundos e Escala dos Ícones de Moves na HUD

- **Data:** 2026-11-07
- **Área:** UI / Status Screen / Ícones / Moves
- **Origem:** instrução direta do criador via prompt.
- **Estado:** aprovado em definitivo; em implementação.

## Declaração literal do criador

> "estes fundos estão escuros demais nos ícones, além de que os próprios icones deviam ser um pouco maiores pra caber melhor nesses quadrados, ajuste"

## Regras aprovadas

1. **Clareamento e Fidelidade dos Fundos dos Ícones:**
   - Eliminar o escurecimento excessivo dos fundos das pedras elementares na hotbar (que antes aplicava `col.darkened(0.65)`).
   - O fundo de cada slot/quadrado deve refletir as cores vibrantes e ricas oficiais dos elementos (conforme `icones_moves_lab.html` e D-404), sem se perder na escuridão do painel.
   - O elemento Dark é calibrado para um roxo abissal legível (`#581c87` / `#6b21a8`) que se destaque contra o fundo escuro da UI sem parecer preto.

2. **Aumento de Escala dos Glifos dos Ícones:**
   - Nos slots da hotbar ($52 \times 52\text{ px}$ com miolo de $44 \times 44\text{ px}$), os ícones passam de $24\text{ px}$ para $34\text{ px}$ (preenchendo cerca de 75-80% da área útil do quadrado com respiração equilibrada).
   - O glifo é renderizado com sua cor de alto contraste (`_get_element_contrast_color`): branco sobre fundos escuros/médios (Fire, Water, Dark, Psychic, Earth) e preto sólido sobre fundos claros (Electric, Wind, Light, Sound, Nature, Neutral).
   - Nos blocos de cabeçalho e fraquezas, a proporção do ícone também é maximizada proporcionalmente para preencher melhor os blocos sem tocar as bordas.
