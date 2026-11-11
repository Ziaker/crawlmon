# D-1145 — Auditoria move a move dos Moves antigos após a fórmula de WIS

- **Data:** 2026-11-10
- **Área:** Moves / fichas / UI / processo.
- **Origem:** ordem direta do criador.
- **Estado:** primeira etapa implementada e testada (ícones de tipo dos cinco Moves do Abra e status sem ícone); demais Moves pendentes.

## Declaração literal do criador

> "Vamos corrigir cada move feito antes da concepção completa das coisas após vc finalizar a formula do WIS"

## Regra aprovada

- Depois de a fórmula de WIS estar implementada, revisar **um por um** os Moves criados antes da concepção completa das regras atuais.
- Cada Move deve ser conferido contra as decisões vigentes em:
  1. **tipo de dano** (Physical/Magical) e atributo que escala (STR/MAG — D-1140);
  2. **elemento** (D-396/D-397/D-398);
  3. **alcance/entrega** (melee, mid, long, área — D-395);
  4. **ícone de tipo** exibido na UI (D-395/D-396);
  5. **textos da ficha** ("ATK" vs "MAG", nome do elemento, descrição);
  6. **poder, custos e wind-up** já aprovados — não rebalancear sem pedido.
- A correção é **um Move por vez**, com prova/teste do que mudou; nada de alteração em massa sem revisão.
- Começar pelos cinco Moves do Abra (Confusion, Psybeam, Shock Wave, Teleport, Megido), depois seguir para as outras espécies (Slime, Orc, Cyclops, Gible etc.).

## Ambiguidades em aberto (perguntar antes de agir)

- A ordem exata dos Moves depois dos cinco do Abra.
- Se um Move antigo não tiver ficha completa, perguntar antes de inventar tipo/elemento/alcance.
- Ícones de tipo: a UI ainda usa a heurística antiga por `kind` em algumas telas; a correção entra nesta auditoria, sem mudar o layout aprovado.

## Estado no código

- `Skill.type_icon_name()` centraliza a classificação visual: `magical`, `physical`, `guard`, `dodge` ou vazio para status puro.
- Os cinco Moves do Abra: Confusion/Psybeam/Shock Wave/Megido = `magical`; Teleport = `dodge` (D-396).
- Status puro (Media, Sukunda etc.) não exibe ícone de tipo nem de alcance nas telas corrigidas.
- Telas alinhadas: `status_screen.gd`, `skill_info_panel.gd`, `move_card.gd`, `move_inspection_modal.gd`, `battle_hud.gd` e `fan_menu.gd`.
- Teste dedicado `tests/battle/test_d1145_move_type_icons.gd` — **D1145_PASS**.
- Próximo: revisar os demais Moves (Slime, Orc, Cyclops, Gible etc.) e as fichas antigas, um por um.
