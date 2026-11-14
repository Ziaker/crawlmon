<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-440 — Elemento Neutral: Glifo Diamond Core e AttackTag com Regra de Descoberta (Unknown '?')

- **Data:** 2026-11-08
- **Área:** UI / Moves / Elementos / Combate / Hud
- **Origem:** Decisão direta do criador na conversa.
- **Decisões Relacionadas:** D-001 (GDD ignorado em combate), D-135 (Design System Flat Neo-Brutalist), D-235 (Independência de Personagem/Lado), D-395 (Três Ícones de Move), D-396 (Tipos e Setas), D-397 (Revisão de Elementos e nomes em inglês), D-417 (Padrão Visual Fichas Flat e Marca d'água), D-438 (3 Ícones no SkillInfoPanel e Fight Drawer), D-439 (Wind-up Compacto), D-981 (Etiquetas Inimigo com Descoberta '?'), D-985 (AttackTag Overhaul).

---

## Frase literal do criador

> *"se não sabermos o elemento dos inimigos, eles devem aparecer como Unknown, um bloco com ponto de interrogação"*  
> *"diamond core"*

---

## Decisão

1. **Novo Glifo Oficial do Elemento Neutral (Diamond Core):**
   - Substituição oficial do antigo círculo liso preenchido (D-397) pelo glifo **Diamond Core**: losango facetado chanfrado com anel geométrico e núcleo sólido central.
   - Atualizados os arquivos oficiais em `assets/ui/icons/elements/neutral.svg` e `assets/ui/icons/elements/physical.svg`.
   - Aplicado em todas as superfícies onde o elemento Neutral/Físico é renderizado:
     - 1º badge de elemento no cabeçalho do `SkillInfoPanel` e gaveta do Fight (`FanMenu`).
     - Marca d'água em baixo relevo translúcida no `SkillInfoPanel`.
     - Marca d'água no `AttackTag` quando o elemento do golpe for conhecido.

2. **Ícones do `AttackTag` (Wind-up Inimigo em Campo):**
   - Mantém estritamente **apenas os 2 ícones** ao lado do nome do golpe: **Tipo de Dano** (`physical.svg`, `magical.svg`, etc.) e **Alcance** (`melee.svg`, `mid.svg`, `long.svg`, `area.svg`), em conformidade com D-985.
   - Não recebe o 3º ícone de elemento ao lado do nome (o elemento pertence ao fundo / marca d'água quando descoberto).

3. **Regra de Descoberta aplicada ao `AttackTag` (Anti-Spoiler Visual):**
   - Se o atacante inimigo for **Desconhecido** (`not known` pela regra D-981 — espécie não presente no time do jogador e sem fraqueza descoberta ainda):
     - O fundo do `AttackTag` permanece em tom escuro neutro (`Color("1e293b")`), **sem revelar a cor elemental do golpe**.
     - No canto direito da tag, no lugar da marca d'água elemental, é renderizado o bloco branco inclinado com ponto de interrogação preto `[ ? ]` (símbolo de Unknown padronizado em D-981).
   - Se o atacante for **Conhecido**:
     - O fundo recebe a cor oficial do elemento do golpe e o canto direito exibe a marca d'água do glifo oficial do elemento (Diamond Core para golpes Neutros).

---

## Estado

Implementado nos SVGs de assets e em `scripts/ui/battle_hud.gd`. Testado e validado visualmente via capturas in-engine.
