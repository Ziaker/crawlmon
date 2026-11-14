<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-439 — SkillInfoPanel: Wind-up ao Lado de MP na Linha de Custos, Chips Flat sem Borda e Redução de Tamanho do Bloco

**Status:** Aprovada e em Implementação  
**Data:** 2026-11-08  
**Autor:** Criador  
**Decisões Relacionadas:** D-001 (GDD ignorado em combate), D-135 (Design System Flat Neo-Brutalist), D-235 (Independência de Personagem/Lado), D-416 (Paralelogramos Flat), D-417 (Fichas Flat), D-420 (Fichas sem Repetições), D-436 (Desobstrução do Combate), D-437 (Remoção de Redundâncias e Marca d'Água), D-438 (Cores Elementais e 3 Ícones)

---

## 1. Frases Literais do Criador

> *"coloque o ícone de ampulheta junto de seu valor na aba abaixo ao lado de MP, além disso mude pra uma cor FLAT com o texto dentro sem borda*
> 
> *Agora que tem mais espaço para informação, reduzir o tamanho do bloco é uma ideia boa, cabendo tudo ainda"*
> *(com anexo visual do SkillInfoPanel destacando o chip de wind-up no cabeçalho e o chip de MP na linha de custos)*

---

## 2. Decisão e Diretrizes de Design

1. **Migração do Wind-up para a Linha de Custos ao Lado do MP:**
   - O indicador de tempo de wind-up (`⏳ X.XXs`) deixa o cabeçalho superior e passa a ser posicionado na linha de custos logo abaixo do header, **ao lado do chip de MP**.
   - O cabeçalho superior agora abriga com amplitude e elegância exclusivamente: (1) Nome do Move, (2) os 3 Ícones oficiais (Elemento, Tipo e Alcance) e (3) a Marca d'Água translúcida ao fundo.

2. **Chips com Cores Flat Sólidas e Sem Borda:**
   - Tanto o chip de MP quanto o chip de Wind-up abandonam contornos/bordas finas e adotam preenchimento **FLAT sólido** com o texto contrastante dentro:
     - **Chip de MP:** Fundo plano em ciano escuro / azul índigo sólido (`#0284c7` se ativo, `#1e293b` se 0 MP) com tipografia branca/ciano neon sem contorno.
     - **Chip de Wind-up:** Fundo plano âmbar/ouro queimado sólido (`#d97706` ou `#b45309`) com tipografia marfim/branca (`#fffbeb`) e o ícone de ampulheta (`⏳`), 100% plano e sem borda.

3. **Redução do Tamanho do Bloco (SkillInfoPanel Compacto):**
   - Com a eliminação do alerta coral inferior e o reposicionamento dos dados, o espaço vazio residual no rodapé é cortado.
   - A altura do `SkillInfoPanel` é reduzida de **246px** para **~196px** (economia de ~50px verticais), e a posição Y é ajustada para se manter alinhada com a base do Fight drawer (`y: 474`), desobstruindo ainda mais a visão do campo de batalha e do personagem aliado/inimigo.
   - Todas as informações mecânicas essenciais (Nome, 3 Ícones, Marca d'Água, ATB pips, MP flat, Wind-up flat, Previsão de alvo/dano e as 3 linhas de efeito) permanecem confortavelmente acomodadas com margens respiratórias limpas.
