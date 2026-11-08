# D-430 — Aprovação da Inclinação de 9 Graus (Opção A), Renderização com Ícones Reais dos Itens e Botão de Ação Retangular Alinhado

**Status:** Aprovada e Implementada  
**Data:** 2026-11-08  
**Autor:** Criador  
**Decisões Relacionadas:** D-135 (Design System Flat Neo-Brutalist), D-416 (Paralelogramos Flat), D-424 (Diretriz Visual Mochila/Gaveta), D-425 (Foco Híbrido A+C), D-427 (Integração na Status Screen), D-428 (Paralelogramação Rígida), D-429 (Confinamento no Paralelogramo e Inclinação de 9°)

---

## 1. Frase Literal do Criador

> *"opção A, obviamente, e por que não está utilizando os ícones dos items? inclusive o botão não precisa ser um paralelograma, deixe como um quadrado, mas corretamente alinhado"*  
> *(com anexo visual destacando em close o botão `USE (1 ATB) [Z]`)*

---

## 2. Decisão

1. **Aprovação Oficial da Opção A (Cisalhamento / Skew Itálico a 9°):**
   - O texto de descrição de itens na gaveta de detalhes adota oficialmente o cisalhamento horizontal a $9^\circ$ (`-tan(9°)` via `Transform2D`).
   - Os caracteres inclinam-se dinamicamente para frente acompanhando o fluxo neo-brutalista, enquanto as linhas de texto permanecem paralelas aos divisores horizontais da gaveta.

2. **Exibição dos Ícones Reais dos Itens (Sprites de Pixel Art):**
   - Eliminação de qualquer renderização residual de placeholder sólido ou branco.
   - Tanto os 10 slots da matriz de expedição quanto o cabeçalho da gaveta de detalhes utilizam instâncias de `TextureRect` dedicadas com filtragem `TEXTURE_FILTER_NEAREST` e modo de expansão centrado mantendo a proporção (`STRETCH_KEEP_ASPECT_CENTERED`), garantindo fidelidade de cor e renderização nítida dos sprites de itens (`potion.png`, `super_potion.png`, etc.).

3. **Botão de Ação Retangular Ortogonal com Alinhamento Preciso:**
   - O botão `USE (1 ATB) [Z]` deixa de ser um paralelograma inclinado (`skew = 0`), passando a ser um bloco retangular reto (90°).
   - O botão é confinado rigorosamente à direita no rodapé da gaveta com margem de segurança de $8\text{px}$ em relação à borda inclinada.
   - O texto interno `"USE (1 ATB) [Z]"` é alinhado com centralização óptica horizontal e vertical rigorosa dentro do retângulo amarelo queimado (`#dfc980`).

---

## 3. Estado da Implementação

- Atualizado em [`scripts/ui/status_screen.gd`](file:///c:/Users/zerke/OneDrive/Área%20de%20Trabalho/Z/crawlmon/scripts/ui/status_screen.gd).
- Ícones reais conectados via nós `TextureRect` gerenciados no ciclo de desenho.
- Validado com capturas de tela in-engine em 1280×720 comprovando a paleta de cores original dos itens e o alinhamento ortogonal do botão de uso.
