<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-428 — Correção de Angularidade e Paralelogramação Rígida na Gaveta de Detalhes, Badge e Botão de Ação do Inventário

**Status:** Aprovada e Implementada  
**Data:** 2026-11-08  
**Autor:** Criador  
**Decisões Relacionadas:** D-135 (Design System Flat Neo-Brutalist), D-416 (Paralelogramos Flat `/ /`), D-424 (Diretriz Visual da Mochila e Paralelogramação Rígida), D-425 (Foco Híbrido A+C), D-426 (Badge de Consumível), D-427 (Integração da Bag na StatusScreen)

---

## 1. Frase Literal do Criador

> *"esta região não esta paralelogramada"*  
> *(com anexo visual destacando a gaveta de detalhes, a badge verde `CONSUMABLE` e o botão amarelo `USE (1 ATB) [Z]` com bordas retos/não-inclinados)*

---

## 2. Decisão

1. **Eliminação de Formatos Retangulares Ortogonais (90°):**
   - Todos os elementos destacados na gaveta de detalhes deixam de ter inclinações ínfimas e imperceptíveis (skew de 2px a 4px) que pareciam retângulos retos ortogonais.
   - Aplicação rigorosa da geometria de paralelogramo flat inclinada à direita `/ /` (D-416) com angulação perceptível e enérgica (tangente entre 0,20 e 0,33):
     - **Badge de Consumível (`CONSUMABLE`):** Altura 16px com `skew = 5.0px`, garantindo inclinação nítida `/ /` no Verde Herbal (`#2e7d4e`).
     - **Botão de Uso (`USE (1 ATB) [Z]`):** Altura 18px com `skew = 6.0px`, inclinado à direita `/ /` em amarelo queimado (`#dfc980`).
     - **Caixa da Gaveta de Detalhes (`drawer`):** Altura 106px com `skew = 12.0px`, acompanhando a inclinação canônica da borda esquerda da mochila.
     - **Slots da Grade de Itens (1 a 10):** Altura 22px com `skew = 5.0px`, tornando todos os slots visivelmente paralelogramados.

2. **Substituição da Função de Borda com Trapézio Incorreto (`_slant_border`):**
   - Substituição de `_slant_border` por `_draw_para_border`, desenhando estritamente um paralelogramo com lados esquerdo e direito paralelos entre si (`pos.x + skew` e `pos.x + size.x + skew` no topo; `pos.x` e `pos.x + size.x` na base), eliminando a convergência trapezoidal anterior.

---

## 3. Estado da Implementação

- Corrigido em [`scripts/ui/status_screen.gd`](file:///c:/Users/zerke/OneDrive/Área%20de%20Trabalho/Z/crawlmon/scripts/ui/status_screen.gd).
- Validado com capturas de tela in-engine em alta resolução comprovando a inclinação angular nítida de cada elemento.
