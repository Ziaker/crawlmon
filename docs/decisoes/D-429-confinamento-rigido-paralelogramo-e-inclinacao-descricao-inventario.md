# D-429 — Confinamento Rígido de Elementos no Paralelogramo da Gaveta e Inclinação de 9 Graus no Texto de Descrição

**Status:** Aprovada e Em Validação  
**Data:** 2026-11-08  
**Autor:** Criador  
**Decisões Relacionadas:** D-135 (Design System Flat Neo-Brutalist), D-416 (Paralelogramos Flat `/ /`), D-424 (Diretriz Visual Mochila/Gaveta), D-425 (Foco Híbrido A+C), D-427 (Integração na Status Screen), D-428 (Paralelogramação Rígida)

---

## 1. Frases Literais do Criador

> *"o bloco de uso está fora do paralelograma"*  
> *"o texto da descrição do item não está inclinado a 9 graus"*  
> *"o ícone está vazando do paralelograma"*  
> *(anexo visual com a gaveta evidenciando o botão `USE` ultrapassando a borda amarela à direita, o ícone colidindo com a borda amarela à esquerda e a descrição plana a 0°)*

---

## 2. Decisão

1. **Confinamento Geométrico Estrito no Paralelogramo (`dr_left_x` e `dr_right_x`):**
   - Na renderização de paralelogramos inclinados à direita (`skew`), as coordenadas horizontais das bordas esquerda e direita variam em função da altura $Y$:
     $$\text{x\_left}(y) = \text{pos.x} + \text{skew} \times \left(1.0 - \frac{y - \text{pos.y}}{\text{size.y}}\right)$$
     $$\text{x\_right}(y) = \text{pos.x} + \text{size.x} + \text{skew} \times \left(1.0 - \frac{y - \text{pos.y}}{\text{size.y}}\right)$$
   - **Correção do Ícone (Topo-Esquerdo):**
     O cálculo anterior usava offset inverso a partir da base. O ícone passa a ser posicionado com margem de segurança de $\ge 8.0\text{px}$ à direita da borda esquerda no topo (`x_left(top_icon) + margin`), impedindo qualquer vazamento ou sobreposição com a borda amarela.
   - **Correção do Botão de Uso (Base-Direita):**
     O botão `USE (1 ATB) [Z]` possui largura de $84\text{px}$ e inclinação própria de $\text{skew} = 6.0\text{px}$. Seu vértice superior direito ($\text{btn.x} + \text{btn.w} + \text{btn.skew}$) passa a ser confinado estritamente dentro de $\text{x\_right}(btn\_top) - \text{margin}$, garantindo margem interna de $8.0\text{px}$ e eliminando a projeção para fora da gaveta.

2. **Inclinação de 9 Graus no Texto de Descrição:**
   - O texto de descrição do item ("Restores 30 HP instantly on target ally...") deve ter inclinação de 9 graus, acompanhando o dinamismo angular do design neo-brutalista.
   - Apresentar ao criador as duas variantes técnicas in-engine para confirmação:
     - **Opção A (Cisalhamento / Skew Itálico a 9°):** Linhas de texto continuam paralelas aos divisores horizontais da gaveta, e os caracteres individuais inclinam $9^\circ$ para frente via `Transform2D(Vector2(1, 0), Vector2(-tan(9°), 1), pos)`.
     - **Opção B (Rotação Angular a -9°):** O bloco inteiro de texto é rotacionado $-9^\circ$ via `draw_set_transform`, inclinando as linhas diagonalmente.

---

## 3. Estado da Implementação

- Corrigido o cálculo geométrico das bordas esquerda e direita em [`scripts/ui/status_screen.gd`](file:///c:/Users/zerke/OneDrive/Área%20de%20Trabalho/Z/crawlmon/scripts/ui/status_screen.gd).
- Confinamento do ícone e do botão de ação implementado com margem de segurança interna.
- Geradas capturas comparativas in-engine no Godot comprovando o confinamento e exibindo as variantes de inclinação de 9° para escolha visual do criador.
