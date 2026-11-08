# D-426 — Redesenho da Badge de Consumível: Escala Ampliada e Paleta Não Ameaçadora (Restaurativa)

**Status:** Aprovada e Prototipada  
**Data:** 2026-11-08  
**Autor:** Criador  
**Decisões Relacionadas:** D-033 (Inventário e Consumíveis), D-135 (Design System Flat Neo-Brutalist), D-416 (Paralelogramos Flat `/ /`), D-424 (Diretriz Visual da Mochila), D-425 (Inventário Foco Híbrido A+C)

---

## 1. Frase Literal do Criador

> *"troca esse badge de consumable, deixe maior, mude a cor pra algo menos ameaçador"*

---

## 2. Decisão

1. **Eliminação do Vermelho Alerta / Ameaçador:**
   - O vermelho terracota/alerta (`#c94a42`) anterior transmitia perigo, dano crítico ou estado de ameaça, o que colide com a natureza benéfica e curativa dos itens consumíveis (poções, tônicos, ervas e berries).
   - A cor passa para uma tonalidade suave, segura e acolhedora de restauração/boticário.

2. **Aumento de Escala e Legibilidade (Deixe Maior):**
   - A tipografia da badge é ampliada de micro-texto imperceptível (7px) para fonte mono robusta de 10px–11px com espaçamento entre letras (`tracking-wider`).
   - O padding interno é aumentado de `px-1 py-0.2` para `px-2.5 py-0.5` ou `px-3 py-1`, conferindo corpo sólido e equilibrado com o título do item.

3. **Geometria em Paralelogramo `/ /` (D-416):**
   - Mantém a inclinação canônica de paralelogramo flat à direita sem bordas vazadas e com contraste WCAG AAA sobre o marrom da mochila.

4. **Paleta Não Ameaçadora Proposta:**
   - **Opção Principal (Herbal Sage / Verde Botânico):** Fundo verde folha/restaurativo (`#2e7d4e` / `#3ba565`), remetendo diretamente a cura natural, restauração e segurança médica clássica de RPGs.
   - **Alternativa A (Âmbar Boticário / Mel Quente):** Fundo âmbar dourado mel (`#b57b22`), transmitindo essência de elixir, poção aquecida e acolhimento rústico em couro.
   - **Alternativa B (Teal Tônico / Cristalino):** Fundo azul-petróleo/teal suave (`#28757d`), sereno e refrescante.

---

## 3. Estado da Prototipação

- Prototipado no laboratório interativo `inventory_hybrid_lab.html` e widget `inventory_hybrid_widget.html`.
- Imagens de visualização e comparativo geradas em `badge_consumable_variants.png` e `hybrid_v4_badge_focused.png`.
