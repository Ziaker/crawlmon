<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-434 — Overhaul da Hotbar de Skills da Status Screen: Battle Strips em Grade 2×4, Número de Atalho na Extrema Direita, Pips de ATB em Paralelograma Real e Omissão de 0MP

**Status:** Aprovada e em Implementação  
**Data:** 2026-11-08  
**Autor:** Criador  
**Decisões Relacionadas:** D-135 (Design System Flat Neo-Brutalist em Inglês), D-416 (Paralelogramos Flat nos Moves), D-417 (Padrão Visual Fichas Flat), D-419 (Layout Ficha de Move), D-420 (Ficha sem Repetições), D-424 (Diretriz Visual Neo-Brutalista), D-428 (Paralelogramação Rígida)

---

## 1. Frases Literais do Criador

> *"melhore a opção B apenas, ao invés de estar escrito o número e o atb, esteja que nem na A onde é os paralelogramas. quanto ao número do MP, eu deixava mais perto do texto MP, assim: '8MP' ao invés de '8  MP'*
> 
> *quanto a moves com nomes grandes, ache uma solução. Eu colocaria os números em um bloco fora no topo diagonal na extrema esquerda de cada para dar mais espaço ao nome do move"*  
> *(com anexos visuais apontando truncamento e colisão em SHOCK WAVE#4 e CONFUSION#2)*

> *"perfeito, mas coloque o número na extrema direita ao invés da esquerda, os atbs não são paralelogramas por sinal, corrija e faça-os ser"*

> *"perfeito, tudo perfeito"*

> *"ao inves de escrever 0mp ou free, deixe sem nada, tem certos números que acabam ficando encima do texto dos outros, se puder fazer uma mudanca de espaçamento seria ótimo, de resto está perfeito"*  
> *(com anexo visual destacando 0MP no Tackle e a sobreposição das abas 5, 6, 7, 8 sobre o texto de MP da linha 1)*

---

## 2. Decisão

1. **Aprovação do Overhaul de Skills Baseado na Opção B (Battle Strips em Grade 2×4):**
   - A hotbar de habilidades equipadas no rodapé da Status Screen abandona a fileira de 8 quadrados idênticos e adota a arquitetura de **Battle Strips** (fitas horizontais em paralelogramo `/ /`) dispostas em grade de 2 linhas × 4 colunas.
   - Cada fita é dividida em bloco de ícone elemental à esquerda e bloco de dados à direita.

2. **Posicionamento do Número de Atalho na Extrema Direita Externa:**
   - O número da hotkey (`1` a `8`) deixa de invadir o corpo interno da fita e é posicionado em uma **aba chanfrada diagonal externa no topo à extrema direita**, acompanhando o vértice superior direito do paralelograma (`/ /`).
   - A largura horizontal interna do card fica **100% livre e desimpedida** para a exibição integral do nome do Move em tipografia Teko maiúscula, eliminando truncamentos e colisões mesmo em nomes extensos (como `SHOCK WAVE`, `BRICK BREAK`, `HASSOU TOBI`).

3. **Pips de ATB Obrigatórios como Paralelogramas Reais (`/ /`):**
   - É terminantemente proibido o uso de retângulos ortogonais ou texto puro (`"2 ATB"`) para indicar o custo de ATB.
   - Cada bloco de ATB é renderizado como um **paralelograma real inclinado à direita** (`_draw_para_flat` com `skew` perceptível de 3.0px a 4.0px), preenchido em ciano neon brilhante (`#38bdf8` no slot ativo, `#138cb5` nos inativos).

4. **Custo de MP Compacto e Omissão Estrita de Custo Zero (Sem "0MP" / Sem "FREE"):**
   - O espaçamento aberto é eliminado: quando há custo de MP, o valor e a sigla ficam diretamente unidos sem espaço: **`"4MP"`**, **`"6MP"`**, **`"7MP"`**, **`"8MP"`**, **`"10MP"`** em azul ciano `#38bdf8`.
   - **Custo Zero (`mp_cost == 0`):** É expressamente proibido escrever `"0MP"` ou `"FREE"`. O campo deve permanecer **completamente vazio/sem nada**, deixando o espaço limpo e sem poluição visual.

5. **Ajuste de Espaçamento Vertical entre Linhas (Eliminação de Sobreposição de Abas):**
   - Para impedir que as abas de atalho da segunda linha (`5`, `6`, `7`, `8`) colidam ou fiquem por cima do texto de MP da primeira linha, o espaçamento vertical entre as linhas (`gap_y`) é ampliado para no mínimo `12.0px` (com altura da fita calibrada em `40.0px`), garantindo que o topo das abas da linha 2 termine abaixo da base da linha 1, com folga respiratória limpa.

---

## 3. Estado da Implementação

- Validado e aprovado no protótipo interativo Generative UI [`skills_rack_overhaul.html`](file:///c:/Users/zerke/OneDrive/Área%20de%20Trabalho/Z/crawlmon/skills_rack_overhaul.html).
- Totalmente implementado no código de produção da Status Screen ([`scripts/ui/status_screen.gd`](file:///c:/Users/zerke/OneDrive/Área%20de%20Trabalho/Z/crawlmon/scripts/ui/status_screen.gd#L975)) com suporte a cliques de mouse (`_gui_input`) e teclado numérico (`KEY_1` a `KEY_8` em `_unhandled_input`).
- Verificado com testes automatizados (`tests/ui/test_status_screen_content.gd`) e capturas reais no motor (`tests/ui/capture_status_screen_real.gd`).
