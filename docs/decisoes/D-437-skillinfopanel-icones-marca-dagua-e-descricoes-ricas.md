# D-437 — SkillInfoPanel: Remoções de Redundâncias, Ícones de Tipo/Alcance, Marca d'Água Elemental e Descrição Rica

**Status:** Aprovada e em Implementação  
**Data:** 2026-11-08  
**Autor:** Criador  
**Decisões Relacionadas:** D-135 (Design System Flat Neo-Brutalist), D-235 (Independência de Personagem/Lado), D-416 (Paralelogramos de ATB), D-417 (Padrão Visual Fichas Flat e Marca d'Água), D-419 (Ícones de Tipo e Alcance ao Lado do Nome), D-420 (Fichas sem Repetições e Eixos de Conteúdo), D-434 (Omissão de 0MP), D-435 (Números de Atalho Sobre Ícones), D-436 (Desobstrução do Combate)

---

## 1. Frases Literais do Criador

> *"remove o "tactical analysis" é redundante e também o "incoming move from X" , e deixe o texto do move mais rico. Está faltando informação de ícones, por favor reveja o gdd para ter noção do que ainda falta. e ao invés de escrever psychic é pra ser a marca d'gua do elemento"*

---

## 2. Decisão e Diretrizes de Design

1. **Remoção de Rótulos e Alertas Redundantes:**
   - O rótulo/cabeçalho de seção `"TACTICAL ANALYSIS"` é expressamente removido por redundância.
   - A caixa inferior de alerta `"incoming move from X"` é removida do card de informações do Move, liberando espaço vertical valioso para o detalhamento da habilidade.

2. **Marca d'Água Elemental em Vez de Texto:**
   - Fica proibido escrever o nome do elemento por extenso como badge de texto no cabeçalho (ex.: remover o texto `"PSYCHIC"`).
   - O elemento do Move deve ser representado exclusivamente como uma **marca d'água gráfica translúcida** do seu respectivo ícone SVG oficial (`res://assets/ui/icons/elements/`), posicionada em baixo-relevo/segundo plano no cabeçalho sólido colorido (conforme D-417).

3. **Inclusão dos Ícones de Tipo e Alcance (D-417 / D-419 / GDD):**
   - Ao lado direito do nome do Move, no topo do card, são renderizados os ícones oficiais em mini-paralelogramas táteis (18×18px):
     - **Ícone de Tipo:** `physical.svg` (vermelho), `magical.svg` (azul), `guard.svg` (cinza) ou `dodge.svg` (âmbar).
     - **Ícone de Alcance / Entrega:** `melee.svg`, `mid.svg`, `long.svg` ou `area.svg`.

4. **Corpo de Texto Mais Rico e Detalhado:**
   - Com a eliminação do alerta inferior e do rótulo redundante, o espaço interno é ampliado para exibir a descrição técnica mecânica completa do Move (`mechanics_description()`), cobrindo com riqueza o efeito no alvo, comportamento especial, cinemática de deslocamento (`visual_motion_summary()`) e escalamento de atributos com tempo de wind-up (`scaling_timing_summary()`).
