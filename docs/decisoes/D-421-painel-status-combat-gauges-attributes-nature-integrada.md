<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-421 — Overhaul do Painel de Gauges, Atributos e Nature Integrada (Opção 1C)

**Status:** Aprovada e Implementada  
**Data:** 2026-11-08  
**Autor:** Criador  
**Decisões Relacionadas:** D-135 (Design System Flat Neo-Brutalist), D-249 (6 Atributos Canônicos e Natures), D-413 (Regeneração de 4 MP a cada 8s, MP Individual, Inglês Global), D-416 (Paralelogramos Flat `/ /`, Remoção de Bordas de 1px), D-419 (Fichas de Moves e Hierarquia)

---

## 1. Frases Literais do Criador

> *"acho que essa região precisa de um overhaul"*  
> *"1 - sim [manter Combat Gauges em Paper Cream]"*  
> *"2 - sim, eles devem [modificadores integrados aos status], quanto ao formato, me surpreenda, mas mantenha uma opção que siga"*  
> *"3 - as fraquezas devem ser em forma de ícone, por mais que eu tenha gostado que estejam em forma de texto, porém o enquadramento é um dos problemas."*  
> *"4 - não é necessário [indicador de recarga de 8s de MP no painel de medidores]"*  
> *"remova isso do "tactical personality" deixe apenas nature eo nome da nature junto com ambos tendo o mesmo tamanho. Não precisa colocar abaixo do nome da nature os modificadores, eles ja estão perceptiveis através dos valores adicionados nos status. Eu não sei o que este agression e agressive . atb reserve deviam significar.*  
> *os textos e retangulos deviam estar angulares corretamente alinhados aos paralelograma"*  
> *"opção 1*  
> *Deixe apenas ATTRIBUTES , sem o "//6" e nem "canonical" e "canonical profile"*  
> *ao invés da nature ocupar um bloco de espaço extra, ela pode caber junto do bloco de atributos"*  
> *"Opção 1C, implemente"*

---

## 2. Decisão

1. **Eliminação do Bloco Separado de Nature:**
   - A `Nature` deixa de ocupar uma caixa externa dedicada de 82px na parte inferior.
   - Ela é incorporada diretamente no rodapé interno do cartão de `ATTRIBUTES`, permitindo que os dois blocos principais (`COMBAT GAUGES` e `ATTRIBUTES`) fiquem lado a lado com alinhamento horizontal limpo e mesma altura canônica (142 px).

2. **Rótulo Limpo de Atributos:**
   - O cabeçalho passa a ser estritamente `ATTRIBUTES`, eliminando os complementos `// 6`, `CANONICAL` e qualquer subtítulo secundário (`canonical profile`).

3. **Geometria Angular Contínua (Retângulos e Paralelogramos):**
   - Todos os contornos de 1px (`false, 1.0`) são removidos, cumprindo D-135 e D-416.
   - O bloco de `COMBAT GAUGES` (Paper Cream) e o bloco de `ATTRIBUTES` (Deep Navy) compartilham a mesma inclinação de paralelogramo à direita (`/ /`).
   - As barras de `HP` e `MP`, seus trilhos de fundo e os blocos de `ATB` são paralelogramos planos inclinados ao mesmo ângulo.

4. **Modificadores de Nature Integrados aos Atributos:**
   - Os bônus e penalidades da Nature (`+2`, `+1`, `-1`, `-2`) são estampados diretamente ao lado do valor do atributo em verde limão ou coral (ex.: `STR 6 (+2)`, `WIS 1 (-1)`).

5. **Rodapé Compacto Dividido (Opção 1C):**
   - Na linha inferior interna do cartão de atributos:
     - **Esquerda:** Faixa de Nature com aba vertical dourada (`GOLD`), exibindo `NAT` e o nome da nature (ex.: `NAT BRAVE`) no mesmo tamanho de fonte.
     - **Direita:** Doca de fraquezas (`WEAK`) com os glifos vetoriais oficiais SVG dos elementos dentro de paralelogramos planos coloridos, com enquadramento limpo e sem bordas brancas de 1px.
   - Totalmente eliminadas as menções crípticas de IA (`Aggression 1.3x • ATB Reserve Aggressive (-1.0s)`), o subtítulo `TACTICAL PERSONALITY` e a repetição de modificadores.

6. **Sem Poluição de 8s em Medidores:**
   - O indicador de ciclo de 8s de MP fica restrito às descrições técnicas de moves que gastam MP (D-420), mantendo a barra de medidores limpa (`HP`, `MP`, `ATB` e `ATB SPEED`).

---

## 3. Ambiguidades e Esclarecimentos

- **Q: A eliminação do bloco inferior de Nature afeta as funções lógicas de cálculo de atributos e IA de combate?**  
  **R:** Não. Todas as funções lógicas (`NatureData`, `CrawlmonAttributeMath`, `sync_effective_stats()`, etc.) permanecem intactas no motor de combate. A mudança é estritamente de apresentação gráfica e despoluição de HUD na `StatusScreen`.

---

## 4. Estado da Implementação

- Laboratório interativo verificado e aprovado em `panel_overhaul_lab.html`.
- Implementado em `scripts/ui/status_screen.gd`.
- Testes automatizados passando 100%: `tests/ui/test_status_screen_content.gd` e `tests/ui/test_qol_batch.gd`.
- Capturas visuais salvas em `test_captures/` e documentadas no relatório de verificação.
