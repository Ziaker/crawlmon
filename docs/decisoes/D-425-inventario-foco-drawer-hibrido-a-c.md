<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-425 — Inventário da Status Screen: Foco Híbrido A+C (Gaveta de Detalhes Inferior com Obscurecência dos Demais Itens)

**Status:** Aprovada e Prototipada  
**Data:** 2026-11-08  
**Autor:** Criador  
**Decisões Relacionadas:** D-033 (Inventário e Consumíveis), D-135 (Design System Flat Neo-Brutalist), D-416 (Paralelogramos Flat `/ /`), D-421 (Status Screen Overhaul), D-424 (Diretriz Visual Mochila Marrom e Amarelo Queimado)

---

## 1. Frase Literal do Criador

> *"opção A mas com a obscurecencia da opção C, deixando os outros itens escuros"*

---

## 2. Decisão

1. **Aprovação do Modelo Híbrido A+C (Focus Drawer):**
   - Combina a gaveta retrátil inferior da Opção A com o efeito de foco e obscurecência da Opção C.
   - Em estado padrão (sem item selecionado), todos os 10 slots da mochila de expedição (2 colunas × 5 linhas) permanecem visíveis em luminosidade integral sobre o fundo marrom couro (`#3c2415`), com capacidade para até 10 itens por membro ativo (R35-Q3).

2. **Comportamento de Obscurecência / Dimming (ao selecionar/clicar):**
   - Ao clicar ou selecionar um item ativo, este slot ganha destaque total em amarelo queimado/ocre (`#dfc980`) e texto escuro de alto contraste (`#24140a`).
   - **Todos os outros 9 slots da mochila tornam-se obscurecidos** (opacidade reduzida para ~28% e filtro de escurecimento/dessaturação), eliminando ruído visual periférico e concentrando a atenção do jogador no item manipulado.
   - Os slots vazios também acompanham o escurecimento de fundo.

3. **Gaveta de Detalhes Inferior (Slide-Up Drawer):**
   - A gaveta abre suavemente na base do cartão da mochila em marrom escuro profundo (`#201007`) com borda em amarelo queimado (`#dfc980`).
   - Apresenta: Ícone nítido em pixel art, Nome do item em caixa alta (fonte Teko), Badge categórico (`CONSUMABLE`, `EQUIP`, etc.), Descrição completa do efeito em inglês neutro, Alvo (`Single Ally`, etc.) e botão de ação de combate (`USE (1 ATB)` / tecla de atalho `[Z] USE`).
   - Botão `[X] CLOSE` no canto superior direito da gaveta (ou clicar novamente no slot / fora) fecha a gaveta e desfaz imediatamente a obscurecência, restaurando os 10 slots ao brilho pleno.

4. **Preservação Rígida de Geometria e Contraste:**
   - Geometria inclinada em paralelogramo à direita `/ /` (D-416), com padding interno estrito garantindo que nada colida ou extravase a silhueta da mochila.
   - Paleta canônica de mochila: Couro rústico (`#3c2415`), sombras profundas (`#24140a` / `#180d07`), realce amarelo queimado (`#dfc980`), consumíveis em terracota (`#c94a42`).

---

## 3. Estado da Prototipação

- Prototipado no laboratório interativo `inventory_hybrid_lab.html` e widget `inventory_hybrid_widget.html`.
- Renderizações em alta resolução com capturas reais do estado limpo e do estado obscurecido com gaveta aberta arquivadas em `hybrid_v3_clean.png` e `hybrid_v3_dimmed.png`.
