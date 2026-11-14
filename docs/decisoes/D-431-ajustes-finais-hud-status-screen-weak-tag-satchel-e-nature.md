<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-431 — Ajustes de Alinhamento Visual da Status Screen: Hitbox/Hover da Nature, Rótulo WEAK, Remoção de Texto Redundante, Contenção da Tag Satchel e Separação de Rótulos no Rodapé

**Status:** Aprovada e Implementada  
**Data:** 2026-11-08  
**Autor:** Criador  
**Decisões Relacionadas:** D-135 (Design System Flat Neo-Brutalist em Inglês), D-416 (Paralelogramos Flat), D-421 (Painel de Status, Atributos e Nature), D-422 (Posicionamento de Tags e Tooltip de Nature), D-424 (Diretriz Visual Mochila/Gaveta), D-429 (Confinamento Rígido), D-430 (Aprovação de Ícones e Botão Retangular)

---

## 1. Frase Literal do Criador

> *"aqui fica quebrado quando o mouse passa encima, está posicionado muito acima. Inclusive, ao lado, não há mais o texto "WEAK:", coloque*
> 
> *este texto na segunda imagem é desnecessário*
> 
> *na terceira imagem, está vazado*
> *e na quarta imagem o texto está colidindo com o outro, separe-os corretamente*
> 
> *depois veremos como iremos mudar esta parte da quinta imagem"*  
> *(com 5 imagens anexas destacando: (1) hover da Nature descolado verticalmente acima do nome MODEST e ausência da legenda "WEAK:", (2) subtítulo redundante "NATURE (PERSONALITY)" abaixo da ficha de atributos, (3) tag amarela da aba "EXPEDITION SATCHEL" vazando para a esquerda da borda inclinada, (4) textos colidindo no rodapé da satchel "CLICK ITEM TO EXPAND DETAILS (A+C)10 SLOTS VISIBLE", (5) menu em texto simples de itens da dungeon, reservado para etapa futura)*

---

## 2. Decisão

1. **Correção da Hitbox e Highlight de Hover da Nature (Imagem 1):**
   - O cálculo da coordenada vertical `ly` em `_get_nature_badge_rect()` possuía uma divergência de 14px em relação a `_draw_panel()` (`82.0 + 56.0` em vez de `82.0 + 70.0`).
   - O retângulo da hitbox e do destaque de hover é realinhado exatamente sobre o nome da Nature (`MODEST`) na coordenada vertical `sy + 114.0` com altura de `20.0px`, eliminando a sobreposição indevida sobre os atributos superiores (`LUK`) e a linha divisória.

2. **Restauração do Rótulo "WEAK:" nos Badges de Fraqueza Elemental (Imagem 1):**
   - Ao lado dos badges de fraqueza no rodapé do painel de atributos, o rótulo de texto `"WEAK:"` é adicionado à esquerda dos ícones de fraqueza com tipografia de 9px e cor neo-brutalista `#8ea9b5`.

3. **Remoção do Subtítulo Redundante "NATURE (PERSONALITY)" (Imagem 2):**
   - O badge e texto inferior `| NATURE (PERSONALITY)` posicionado abaixo do card de atributos é completamente removido conforme solicitação expressa do criador.

4. **Contenção Estrita da Tag Amarela "EXPEDITION SATCHEL" (Imagem 3):**
   - A tag amarela e o título da aba do inventário são deslocados para a direita (`x = pos.x + 20.0px` para a tag e `x = pos.x + 30.0px` para o texto), garantindo margem interna confortável em relação à borda esquerda inclinada (cujo vértice superior se projeta a partir de `pos.x + 14.0px`), eliminando qualquer vazamento para o fundo azul.

5. **Separação Rígida e Descolamento dos Textos do Rodapé do Inventário (Imagem 4):**
   - No estado fechado/recolhido da gaveta, os textos de instrução e capacidade no rodapé do inventário são descolados e encurtados para evitar colisões tipográficas em resoluções compactas:
     - Texto esquerdo: `"CLICK ITEM FOR DETAILS (A+C)"` alinhado à esquerda com margem de 16px.
     - Texto direito: `"10 SLOTS"` alinhado à direita com margem de 16px.

6. **Escopo do Menu de Dungeon (Imagem 5):**
   - Conforme comando literal expresso (*"depois veremos como iremos mudar esta parte da quinta imagem"*), a interface de texto de itens na exploração do dungeon permanece inalterada nesta rodada.

---

## 3. Estado da Implementação

- Atualizado em [`scripts/ui/status_screen.gd`](file:///c:/Users/zerke/OneDrive/Área%20de%20Trabalho/Z/crawlmon/scripts/ui/status_screen.gd).
- Validado via testes unitários e capturas de tela in-engine em 1280×720 comprovando:
  - Hover e clique da Nature alinhados com precisão pixel-perfect sobre a palavra `MODEST`.
  - Exibição de `"WEAK:"` antes dos selos elementais.
  - Eliminação de qualquer texto flutuante abaixo da ficha de atributos.
  - Tag amarela do inventário 100% contida dentro do cartão marrom.
  - Rótulos do rodapé limpos, separados e legíveis sem colisão.
