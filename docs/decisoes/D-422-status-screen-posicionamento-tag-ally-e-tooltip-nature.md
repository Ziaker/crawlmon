# D-422 — Ajuste Vertical da Tag ALLY/PROTAGONIST, Tipografia da Nature e Tooltip/Doutrina de Combate

**Status:** Aprovada e Implementada  
**Data:** 2026-11-08  
**Autor:** Criador  
**Decisões Relacionadas:** D-135 (Design System Flat Neo-Brutalist), D-249 (6 Atributos Canônicos e Natures), D-393 (Direcionamento Tático das 8 Natures), D-416 (Paralelogramos Flat `/ /`), D-421 (Overhaul Gauges, Atributos e Nature Integrada)

---

## 1. Frases Literais do Criador

> *"o bloco do ally está mt baixo e até mesmo colidindo com o nome do personagem, pode corrigir e posicionar um pouco mais para cima?"*  
> *"ao inves de NAT brave, deixe apenas BRAVE com um texto maior e ao passar o mouse por cima  ou clicar, mostrar o tooltip falando que é esta é a nature dele e também um texto explicando como é sua personalidade em combate na região aberta abaixo na segunda imagem. Onde tá a linha traçada em marrom, é onde deve ficar o paragrafo do texto (acima dela)"*

---

## 2. Decisão

1. **Reposicionamento Vertical da Tag `ALLY` / `PROTAGONIST`:**
   - A tag do cabeçalho direito foi elevada de `y = 82.0` para `tag_y = 62.0`.
   - Isso elimina por completo a colisão visual com o topo do nome do monstro (`PANCHAM` / `ABRA` em fonte 46), estabelecendo um respiro negativo limpo e equilibrado de ~16px entre a tag e o nome.
   - A tag adota geometria flat de paralelogramo (`_draw_para_flat`).

2. **Tipografia Destacada da Nature no Rodapé de Atributos:**
   - No rodapé do cartão de atributos, remove-se o prefixo `NAT`.
   - Exibe-se estritamente o nome da Nature (ex.: `BRAVE`, `MODEST`, `ADAMANT`) em tipografia ampliada de alto impacto (Teko condensada bold tamanho 20 em `GOLD`), acompanhada da aba vertical dourada.

3. **Interação de Hover e Clique na Nature:**
   - Ao passar o mouse por cima do badge da Nature ou ao clicar nele (para fixar/desafixar):
     1. **Tooltip Imediato:** Exibe-se um mini-badge identificador junto ao botão (`[ NATURE (PERSONALITY) ]`).
     2. **Parágrafo Tático na Região Aberta:** Abre-se na área livre inferior do painel (entre `y = 376.0` e `y = 520.0`, exatamente acima da linha de demarcação fornecida pelo criador) um dossiê com a personalidade tática de combate daquela Nature.

4. **Conteúdo do Parágrafo Tático por Nature (D-393):**
   - **Brave:** Vanguarda física agressiva que gasta ATB imediatamente (-1.0s bias) ao entrar no alcance, priorizando ímpeto ofensivo (+2 STR, +1 VIT) sobre recuo.
   - **Modest:** Conjuradora à distância de alto scaling mágico (+3 MAG), cadenciando o ATB para disparar rajadas elementais massivas enquanto preserva MP.
   - **Adamant:** Combatente de poder bruto (+3 STR) com agressividade máxima (1.4×), implacável no corpo a corpo.
   - **Timid:** Sobrevivencialista evasiva que reserva ATB (+1.0s bias) para garantir janelas de esquiva reativa (Evade), punindo a recuperação do inimigo.
   - **Calm:** Estrategista defensiva e reativa (+2 WIS, +1 VIT) que monitora telegraphs para priorizar Guard e janelas de contra-ataque.
   - **Jolly:** Skirmisher ágil e oportunista (+2 AGI, +1 LUK), reposicionando-se constantemente para flanquear e desestabilizar o ritmo adversário.
   - **Docile:** Suporte leal que prioriza buffs, escudos e cura de aliados antes de se comprometer ofensivamente.
   - **Hardy:** Combatente equilibrado com ritmo de ATB regular, adaptando-se a qualquer situação tática.

---

## 3. Estado da Implementação

- Ajustada elevação da tag para `tag_y = 62.0` em `scripts/ui/status_screen.gd`.
- Removido `NAT` e ampliada a tipografia da Nature para Teko 20px.
- Implementado detector de mouse `_gui_input` com hover e clique para alternar o painel doutrinário.
- Renderização do parágrafo explicativo e tooltip na região demarcada (acima da linha em `y = 520.0`).
- Testes automatizados passando 100%: `test_status_screen_content.gd`, `test_qol_batch.gd`.
- Capturas de validação salvas em `test_captures/` e documentadas no relatório.
