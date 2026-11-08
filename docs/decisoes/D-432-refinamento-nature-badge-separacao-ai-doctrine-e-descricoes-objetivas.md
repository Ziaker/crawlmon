# D-432 — Refinamento Visual da Nature Badge, Correção de Separação em AI DOCTRINE e Descrições Objetivas sem Menção a Status

**Status:** Aprovada e Implementada  
**Data:** 2026-11-08  
**Autor:** Criador  
**Decisões Relacionadas:** D-135 (Design System Flat Neo-Brutalist em Inglês), D-393 (Catálogo das 8 Natures e IA de Combate), D-421 (Painel de Status, Atributos e Nature Integrada), D-422 (Tooltip e Doutrina Tática da Nature), D-431 (Alinhamento Inicial da Nature e Rótulo WEAK)

---

## 1. Frase Literal do Criador

> *"a posição do texto está alinhado um pouco mais pra cima do que devia, o bloco de baixa opacidade está grande demais.*
> 
> *na segunda imagem, há textos colidindo, corrija a separação*
> *quanto ao texto de descrição da nature, nunca mencionar os status, eles já são perceptíveis nos atributos, inclusive seja mais objetivo quanto a descrição delas, não da pra entender direito o que significam"*  
> *(com 3 imagens anexas destacando: (1) texto MODEST deslocado para cima e bloco de hover cinza excessivamente largo à direita, (2) colisão entre "AI DOCTRINE" e "Aggression 1.0x", (3) texto de descrição de Modest com menções a "+3 MAG" e redação floreada)*

---

## 2. Decisão

1. **Alinhamento Vertical e Dimensionamento do Bloco de Hover da Nature (Imagem 1):**
   - A posição vertical do texto da Nature (`nat_name`) é rebaixada de `sy + 130.0` para `sy + 132.0`, alinhando perfeitamente a linha de base e a altura de maiúscula com a barra vertical dourada (`sy + 114.0` a `sy + 134.0`) e com a legenda `"WEAK:"` adjacente.
   - A largura fixa de 96px do bloco de baixa opacidade (`Color(0.94, 0.77, 0.49, 0.18)`) que sobrava desnecessariamente à direita é substituída por um dimensionamento dinâmico e compacto baseado na largura real do nome da Nature (`name_w + 14.0px`, ~68px para MODEST), envolvendo confortavelmente a barra dourada e o texto com margem elegante e sem avançar sobre `"WEAK:"`.

2. **Separação Obrigatória dos Textos em "AI DOCTRINE:" (Imagem 2):**
   - A coordenada horizontal do texto de parâmetros táticos (`ai_bias_str`) é calculada dinamicamente após a largura do rótulo `"AI DOCTRINE:"` (`x + 16.0 + doctrine_w + 8.0px`), eliminando a sobreposição de caracteres (`AI DOCTRINEAggression`) e garantindo espaçamento neo-brutalista limpo e legível.

3. **Descrições Objetivas de Natures sem Menção a Status (Imagem 3):**
   - **Regra Rígida:** Os textos descritivos das Natures **nunca** mencionam atributos ou valores numéricos (como `+3 MAG`, `-2 STR`), pois tais modificadores já são visíveis e perceptíveis na tabela de atributos logo acima.
   - **Objetividade Tática:** A descrição foca estritamente no comportamento prático e doutrina da inteligência artificial do combatente em jogo:
     - **Modest:** Conjuradora de retaguarda que mantém distância segura e prioriza habilidades mágicas de alto impacto, conservando MP para momentos cruciais.
     - **Brave:** Vanguarda ofensiva de linha de frente que avança para combate corpo a corpo e gasta blocos de ATB imediatamente em ataques contínuos.
     - **Adamant:** Combatente corpo a corpo implacável com altíssima agressividade, pressionando o alvo constantemente com ataques físicos pesados.
     - **Timid:** Combatente evasivo que mantém distância segura e reserva blocos de ATB para realizar esquivas reativas consistentes contra ataques inimigos.
     - **Calm:** Combatente defensivo que observa os telegrafos de ataque do adversário e reserva blocos de ATB para defender (Guard) e contra-atacar nas janelas de recuperação inimigas.
     - **Jolly:** Flanqueador ágil e móvel que se reposiciona constantemente ao redor do alvo para explorar aberturas de guarda com ataques rápidos e oportunos.
     - **Docile:** Suporte cauteloso que mantém distância dos oponentes para priorizar recuperação de aliados, escudos e fortalecimentos antes de atacar diretamente.
     - **Hardy:** Combatente equilibrado com ritmo regular e distribuição balanceada de ATB, alternando de forma adaptável entre ataque e defesa.

---

## 3. Estado da Implementação

- Atualizado em [`scripts/ui/status_screen.gd`](file:///c:/Users/zerke/OneDrive/Área%20de%20Trabalho/Z/crawlmon/scripts/ui/status_screen.gd).
- Validado via testes unitários e capturas de tela in-engine em 1280×720 comprovando:
  - Texto da Nature centralizado verticalmente com a barra dourada.
  - Bloco de baixa opacidade reduzido e moldado ao nome.
  - Separação impecável entre `"AI DOCTRINE:"` e os valores de agressão/reserva.
  - Dossiê tático claro, objetivo e 100% desprovido de menções a status numéricos.
