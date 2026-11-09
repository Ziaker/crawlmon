# D-438 — Overhaul do Fight Drawer e SkillInfoPanel: Cores Elementais, 3 Ícones, Wind-up no Topo, Redução de 30% no MP e 75% de Opacidade

**Status:** Aprovada e em Implementação  
**Data:** 2026-11-08  
**Autor:** Criador  
**Decisões Relacionadas:** D-001 (GDD ignorado em combate), D-135 (Design System Flat Neo-Brutalist), D-235 (Independência de Personagem/Lado), D-413 (Sistema de MP e Regeneração), D-416 (Paralelogramos Flat), D-417 (Fichas Flat e Marca d'Água), D-419 (Ícones de Tipo e Alcance), D-420 (Fichas sem Repetições), D-434 (Battle Strips e Omissão de 0MP), D-435 (Números de Atalho), D-436 (Desobstrução do Combate), D-437 (SkillInfoPanel)

---

## 1. Frases Literais do Criador

> *"faça com o que o cinza dos moves neutros sejam da mesma cor que o cinza dos cartões (imagem 1)*
> 
> *1 - não tem os custos em MP presentes (imagem 2 e 3)*  
> *2 - os blocos não apagam e ainda deixam ser selecionados caso não tenha MP suficiente para realizar o move, corrija*  
> *3 - Os moves tem custo em MP muito alto, reduza todos custos em 30% para todos moves do jogo no momento*  
> *4 - todas opções são iguais visualmente e não tem diferenças de coloração por elemento e muito menos tem seus respectivos 3 ícones presentes (imagem 2)*  
> *5 - faça com que o bloco inteiro (imagem 3) tenha 75% de opacidade, que dê pra ver o personagem atrás dele*  
> *6 - Remova textos redundantes nos moves, como por exemplo no tackle, ter a informação redundante de não ter consumo de MP. Tem que ser mais objetivo.*  
> *7 - O Wind-up é uma informação extremamente importante assim como os 3 icones do move, precisa estar no topo. precisa estar no topo"*

---

## 2. Decisão e Diretrizes de Design

1. **Harmonização do Cinza dos Moves Neutros/Físicos com os Cartões:**
   - A cor base para o elemento `FISICO` / neutro nos headers e cards passa a ser rigorosamente `Color("cbd5e1")` (cinza ardósia claro oficial dos UnitCards e AttackTags, D-416/D-417), substituindo o branco excessivo anterior.

2. **Exibição Obrigatória dos Custos em MP:**
   - No **Fight Drawer** (Imagem 2), cada opção de habilidade exibe claramente seu custo de MP ao lado do custo de ATB (ex.: `2 ATB · 3 MP` ou `2 ATB · 0 MP`).
   - No **SkillInfoPanel** (Imagem 3), o chip de MP permanece sempre presente na linha de custos, exibindo o valor exato (`0 MP` ou `X MP`).

3. **Bloqueio e Apagamento Visual de Moves sem MP Suficiente:**
   - Caso o combatente ativo não possua MP suficiente para o Move (`leader.mp < sk.mp_cost`), a opção no Fight Drawer é imediatamente **apagada / desativada** visualmente (opacidade reduzida para 35% e texto indicando `"NEED X MP"`).
   - A seleção via confirmação (Z/Enter) ou teclas de atalho numérico (`1-9`) é **estritamente bloqueada e impedida** de ser disparada quando o MP for insuficiente.

4. **Redução Geral de 30% nos Custos de MP:**
   - Todos os custos de MP de todas as habilidades cadastradas no jogo são reduzidos em **30%** (ex.: moves de 8 MP vão para 6 MP; 7 MP para 5 MP; 6 MP para 4 MP; 5 MP para 3 MP; 4 MP para 3 MP; 3 MP para 2 MP; 2 MP para 1 MP; 0 MP permanece 0 MP).

5. **Diferenciação Visual por Elemento e Exibição dos 3 Ícones no Fight Drawer:**
   - A lista de seleção do Fight Drawer abandona o visual genérico e uniforme:
     - Cada linha recebe uma tarja / indicador na cor oficial do elemento da habilidade.
     - Cada opção exibe os seus **3 ícones oficiais**: (1) Ícone do Elemento, (2) Ícone de Tipo (Físico, Mágico, Guarda, Esquiva) e (3) Ícone de Alcance / Entrega (Melee, Mid, Long, Área).

6. **Opacidade de 75% no SkillInfoPanel (Visibilidade da Arena):**
   - O painel tático lateral do Move (`SkillInfoPanel`) passa a ter **75% de opacidade** total (`modulate.a = 0.75` / fundo translúcido), permitindo a visibilidade contínua do modelo 3D do personagem e do campo atrás dele.

7. **Remoção Estrita de Redundâncias Textuais:**
   - Textos de habilidades são higienizados para remover menções supérfluas a MP (ex.: remover *"with zero MP consumption"* ou *"zero MP cost"* no Tackle). Descrições devem ser estritamente focadas no comportamento cinemático e efeito mecânico objetivo.

8. **Wind-up e os 3 Ícones Obrigatórios no Topo do Move:**
   - Tanto os 3 ícones do Move (Elemento, Tipo, Alcance) quanto o tempo exato de Wind-up (ex.: `⏳ 1.50s`) são promovidos para o **topo** (cabeçalho da ficha / SkillInfoPanel), garantindo leitura instantânea prioritária.
