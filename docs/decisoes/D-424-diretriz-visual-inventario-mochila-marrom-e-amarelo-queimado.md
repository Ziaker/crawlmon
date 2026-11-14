<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-424 — Diretriz Visual do Inventário: Mochila Marrom e Amarelo Queimado com Paralelogramação Rígida

**Status:** Aprovada e Prototipada  
**Data:** 2026-11-08  
**Autor:** Criador  
**Decisões Relacionadas:** D-033 (Inventário e Consumíveis), D-135 (Design System Flat Neo-Brutalist), D-416 (Paralelogramos Flat `/ /`), D-421 (Status Screen Overhaul), D-423 (Alinhamento Badges Elemento)

---

## 1. Frases Literais do Criador

> *"a opção 1 é a melhor mas ela possui erros de angulariedade com o paralelogramação, eu escolhi a cor marrom pra ser a cor do fundo do inventário mesmo, como se fosse uma mochila. As coisas tem que caber dentro do paralelograma e a escolha de cores tem que ser decentemente contrastante, com um amarelo com pouca  saturação meio queimado junto com o marrom"*  
> *"1A porém, eu gostaria que as informações dessa região embaixo na verdade aparecessem ao selecionar o item (clicar nele), dando mais espaço para outros itens, afinal, segundo os docs, cada personagem tem limite de 10 itens certo? Não contando key items"*

---

## 2. Decisão

1. **Aprovação da Arquitetura da Opção 1A com 10 Slots Reais:**
   - O modelo de mochila de expedição rústica (Opção 1A) foi selecionado como oficial.
   - Em conformidade com a regra canônica R35-Q3 (`docs/REGRAS_DO_JOGO.md`, Seção 10), cada combatente ativo da equipe tem capacidade de carregar até 10 itens comuns não-segurados (20 com 2 membros, 30 com 3; held items e key items fora da contagem).
   - O bloco da mochila no HUD adota uma grade completa de 10 slots (2 colunas × 5 linhas), exibindo slots preenchidos e slots vazios demarcados (`[ SLOT 07 ]`, `[ SLOT 08 ]`, etc.).

2. **Dossiê de Detalhes On-Demand (Ao Selecionar/Clicar):**
   - A gaveta inferior de detalhes deixa de ser um bloco estático permanente, liberando ~72px de altura útil para os 10 slots caberem com folga no espaço vertical da tela (entre o roster e a hotbar de skills).
   - Ao selecionar ou clicar em um item preenchido, os detalhes (nome em Teko, insígnia de tipo, descrição de efeito, alvo e tecla de uso `[Z] USE`) abrem de forma dinâmica e retrátil (overlay inferior com botão `[X] CLOSE`), podendo ser fechados a qualquer momento para restaurar a visão total dos 10 slots.

3. **Paleta Canônica "Mochila de Expedição" (Satchel Brown & Burnt Yellow):**
   - **Fundo da Superfície:** Marrom couro rústico de mochila (`#3c2415`), conferindo identidade tangível de bagagem de expedição.
   - **Bolsos e Profundidades Internas:** Marrom sombra escuro (`#24140a`).
   - **Tipografia, Realces e Acentos de Alto Contraste:** Amarelo com pouca saturação meio queimado/ocre (`#dfc980`), garantindo contraste mínimo de 7.8:1 (WCAG AAA) sobre a superfície marrom.
   - **Acentos Categóricos:** Vermelho terracota (`#c94a42`) para consumíveis, verde-azulado/latão (`#40828a`) para equipamentos e âmbar antigo (`#b58e38`) para itens-chave.

4. **Correção Rígida de Paralelogramação e Encaixe Interno:**
   - Todo o conteúdo (cabeçalho, abas, slots, textos e gaveta de detalhes) cabe estritamente dentro dos limites angulares do paralelogramo sem vazamento de bordas.
   - Cada elemento adota a inclinação canônica de paralelogramo à direita `/ /` (D-416) com margens internas de segurança.

---

## 3. Estado da Prototipação

- Prototipadas 3 variações da Opção 1 no laboratório interativo `inventory_backpack_lab.html` e widget `backpack_widget.html`.
- Capturas em alta resolução geradas e arquivadas em `backpack_preview_opt1a.png`, `backpack_preview_opt1b.png`, `backpack_preview_opt1c.png` e `backpack_preview_sbs.png`.
- Aguardando validação final da variação (1A, 1B ou 1C) para implementação definitiva no GDScript da `StatusScreen`.
