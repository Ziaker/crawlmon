# D-435 — Posicionamento dos Números de Atalho Dentro dos Blocos de Habilidade na Extrema Esquerda Sobre os Ícones Elementais

**Status:** Em Prototipação e Avaliação  
**Data:** 2026-11-08  
**Autor:** Criador  
**Decisões Relacionadas:** D-135 (Design System Flat Neo-Brutalist em Inglês), D-416 (Paralelogramos Flat nos Moves), D-417 (Padrão Visual Fichas Flat), D-419 (Layout Ficha de Move), D-420 (Ficha sem Repetições), D-424 (Diretriz Visual Neo-Brutalista), D-434 (Battle Strips 2×4 e Omissão de 0MP)

---

## 1. Frases Literais do Criador

> *"mudaça de planos, coloque os números Dentro dos blocos só que na extrema esquerda onde fica os ícones, por cima deles /generative_ui /game-ui-ux"*
>
> *(Ao avaliar o primeiro protótipo no motor:)*
> *"não estão alinhados no topo extremo esquerdo, está faltando espaço ainda, mova elas um pouco pra cima pra corrigir isso*
> *de resto está otimo"*

---

## 2. Decisão e Diretrizes de Design

1. **Eliminação das Abas Externas Superiores:**
   - As abas diagonais no topo externo do card são canceladas. Os números das teclas de atalho (`1` a `8`) passam a ser integrados **dentro** do perímetro do próprio card.
   - Isso elimina qualquer possibilidade de sobreposição vertical entre linhas de cards (`gap_y`), permitindo um alinhamento limpo e monolítico no grid 2×4.

2. **Alinhamento ao Topo Extremo Esquerdo (Flush no Canto Superior Esquerdo):**
   - O número é renderizado no bloco elemental à extrema esquerda, posicionado exatamente no **topo extremo esquerdo** (`num_y = sy`, `num_x = sx + skew - num_skew`).
   - A plaqueta chanfrada encaixa-se rente à borda superior e à inclinação chanfrada esquerda (`num_skew = 2.0`), sem margem vazia acima ou à esquerda.
   - O ícone elemental é centralizado no espaço vertical restante (`center.y = sy + 21.0`, `ic_sz = 18.0`), garantindo folga e respiro visual ("espaço") sem qualquer colisão entre o número e o ícone.

3. **Área de Dados Desimpedida:**
   - A área de dados à direita (onde ficam o nome do Move, os pips de ATB em paralelogramo e o custo de MP) permanece 100% desimpedida. Moves com nomes longos (como `SHOCK WAVE`, `BRICK BREAK`, `HASSOU TOBI`) possuem largura total disponível.
