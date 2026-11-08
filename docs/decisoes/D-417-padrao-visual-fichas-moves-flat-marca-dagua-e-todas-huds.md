# D-417 — Padrão Visual Oficial das Fichas de Moves (Flat Color, Marca d'Água do Elemento e Expansão para Todas as HUDs)

- **Data:** 2026-11-08
- **Área:** UI / Fichas de Moves / HUDs Gerais
- **Origem:** Declaração literal do criador em resposta à prototipação visual de `hud_post_combat.html`.
- **Estado:** Aprovado em definitivo pelo criador; implementado no protótipo pós-combate; diretriz mandatória para todas as HUDs do jogo.

---

## 1. Declaração literal do criador

> "de resto está perfeito, inclusive as mudanças que fez nas fichas de move foram tão excepcionais que eu preciso que sejam perfeitamente trazidas ao jogo em todas huds que envolvem as fichas dos moves."

---

## 2. Padrão Visual Oficial Aprovado

O layout e tratamento estético das fichas de habilidades (Moves) demonstrado em `prototypes/hud_post_combat.html` e validado pelo criador passa a ser a especificação canônica do jogo:

1. **Fundo Sólido Flat com a Cor do Elemento:**
   - O card do move possui preenchimento sólido com a cor oficial do elemento da habilidade (ex.: Psychic `#ec4899`, Electric `#fde047`, Dark `#7e22ce`, Fire `#f97316`, Water `#38bdf8`, Grass `#22c55e`, Wind `#4ff7ba`, Neutral `#9ca3af`, etc.).
   - Estilo neo-brutalista limpo, sem gradientes genéricos escuros ou texturas sujas.

2. **Ícone do Elemento em Marca d'Água Atrás do Nome:**
   - O glifo do elemento é renderizado como uma marca d'água em baixo-relevo/marca d'água translúcida posicionada em segundo plano, diretamente atrás do nome do Move.
   - Proporciona leitura imediata do elemento sem poluição visual.

3. **Tipografia Bold e Ampliada para o Título do Move:**
   - O nome do Move utiliza a fonte `Teko` (ou equivalente sans-serif geométrica em caixa alta com peso bold/black) com escala ampliada para leitura tática instantânea.
   - O texto mantém alto contraste com o fundo (preto sobre fundos claros como Amarelo/Ciano; branco sobre fundos escuros/saturados como Roxo/Rosa).

4. **Badges Padronizados (Tipo, Alcance e Elemento) + Custos ATB/MP:**
   - Trio de badges em pílulas com cantos sutis e fundo contrastante no topo do card.
   - Custos de ATB e MP (D-413) exibidos com destaque visual (ex.: `2 ATB`, `3 MP`).

---

## 3. Escopo de Aplicação em Todas as HUDs do Jogo

O padrão aprovado deve ser aplicado uniformemente em todas as interfaces do jogo que apresentem fichas ou cards de Moves:

1. **`prototypes/hud_post_combat.html`:** Grade de 8 moves com cor flat, marca d'água e explicação por clique (implementado).
2. **`scripts/ui/status_screen.gd`:** Card de inspeção de move e bandeja inferior (LoL/MOBA Tray).
3. **`scripts/ui/battle_hud.gd`:** Menu e botões de seleção de Moves durante a batalha ativa.
4. **`scripts/ui/skill_info_panel.gd`:** Painel de detalhamento e inspeção flutuante de habilidades.
5. **`scripts/ui/level_up_modal.gd`:** Modal de aprendizagem e substituição de novos moves.

---

## 4. Próximos Passos e Coordenação de Sessões

- Registrar D-417 no índice `docs/decisoes/README.md`.
- Na migração para o Godot (`.gd` / `.tscn`), coordenar com a branch e alterações ativas em `status_screen.gd` e `battle_hud.gd` para não sobrescrever o trabalho em andamento de outras sessões.
