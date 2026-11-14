<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-427 — Aprovação da Badge de Consumível Verde Herbal, Alinhamento Óptico e Integração da Bag na StatusScreen

**Status:** Aprovada e Implementada no Protótipo  
**Data:** 2026-11-08  
**Autor:** Criador  
**Decisões Relacionadas:** D-033 (Inventário e Consumíveis), D-135 (Design System Flat Neo-Brutalist), D-416 (Paralelogramos Flat `/ /`), D-421 (Status Screen Overhaul), D-424 (Diretriz Visual Mochila Marrom e Amarelo Queimado), D-425 (Inventário Foco Híbrido A+C), D-426 (Redesenho da Badge de Consumível)

---

## 1. Frase Literal do Criador

> *"Opção A, alinhe o icone ao texto e pronto, coloque essa hud nova da bag de items no protótipo"*

---

## 2. Decisão

1. **Aprovação Oficial da Opção A (Verde Herbal / Botânico):**
   - Fixada a cor verde folha/restaurativa (`#2e7d4e` / `Color("2e7d4e")`) como a tonalidade canônica oficial para a badge de consumíveis (`CONSUMABLE`).
   - Elimina em definitivo qualquer vermelho alerta/agressivo de itens de cura.

2. **Alinhamento Óptico Estrito do Ícone ao Texto:**
   - O ícone do item e a tipografia (nome do item e badge de categoria) são posicionados estritamente no mesmo eixo horizontal central (optical centerline).
   - Aplicado tanto nos slots da grade de 10 itens quanto no cabeçalho da gaveta retrátil inferior de detalhes.

3. **Integração Definitiva da Bag de Itens na `StatusScreen` (`scripts/ui/status_screen.gd`):**
   - Inserida na coluna esquerda da HUD, na região entre o roster de integrantes (`y = 256px`) e a hotbar de skills (`y = 574px`).
   - Coordenadas canônicas: `x = 29.0`, `y = 268.0`, `largura = 276.0`, `altura = 288.0`.
   - Estrutura completa de 10 slots (2 colunas × 5 linhas) respeitando o limite canônico de 10 itens por combatente ativo (R35-Q3).
   - Comportamento híbrido A+C:
     - Clique do mouse em qualquer slot seleciona o item.
     - Slot selecionado recebe destaque total em amarelo queimado (`#dfc980`).
     - Os outros 9 slots sofrem obscurecência periférica (`alpha = 0.28`).
     - A gaveta inferior de detalhes abre com o ícone alinhado ao texto, nome, badge verde herbal, descrição, alvo e botão de uso `[Z] USE`.
     - Clique em `[X] CLOSE` ou fora restaura todos os slots ao brilho original.

---

## 3. Estado da Implementação

- Integrado no script do motor [`scripts/ui/status_screen.gd`](file:///c:/Users/zerke/OneDrive/Área%20de%20Trabalho/Z/crawlmon/scripts/ui/status_screen.gd).
- Validado por suíte de testes automatizados headless e capturas de tela in-engine em alta resolução.
