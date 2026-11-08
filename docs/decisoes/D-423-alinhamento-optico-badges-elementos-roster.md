# D-423 — Alinhamento Óptico das Badges de Elemento no Roster com o Nome do Personagem

**Status:** Aprovada e Implementada  
**Data:** 2026-11-08  
**Autor:** Criador  
**Decisões Relacionadas:** D-135 (Design System Flat Neo-Brutalist), D-404 (Ícones de Elemento), D-413 (Regen MP e Roster), D-416 (Paralelogramos Flat `/ /`)

---

## 1. Frase Literal do Criador

> *"antes de começar, quero que corrija o posicionamento da badge de elemento do abra, ela está abaixo ao invés de estar alinhada com o seu nome"*

---

## 2. Decisão

1. **Alinhamento Óptico das Badges de Elemento no Roster:**
   - As badges de elemento ao lado do nome de cada combatente nos cartões do time (`TEAM // MEMBERS`) foram recalculadas para alinhamento vertical estrito com a tipografia do nome (`ABRA`, `PANCHAM`).
   - A altura da badge foi fixada em `eh = 15.0px` com `ey = r.position.y + 13.0px`.
   - O topo da badge (`ey = 13.0px`) coincide exatamente com a altura de caixa alta (cap-height) da fonte Teko/Impact 18, e a base da badge (`ey + eh = 28.0px`) coincide com a linha de base (baseline) do nome (`y = 28.0px`).
   - Elimina-se o rebaixamento de ~9.5px que fazia a badge pender para baixo em direção às barras de HP/MP.
   - Geometria atualizada para paralelogramo flat inclinado à direita `/ /` (`_draw_para_flat` com skew `2.5px`, sem bordas 1px), em conformidade com D-416.

---

## 3. Estado da Implementação

- Corrigido em `scripts/ui/status_screen.gd` no método `_draw_roster()`.
- Válido universalmente para monstros de 1 elemento (ex.: Abra) e 2 elementos (ex.: Pancham).
- Testes automatizados passando 100%: `tests/ui/test_status_screen_content.gd`.
- Captura de confirmação gerada e arquivada em `status_screen_v9_roster_detail.png`.
