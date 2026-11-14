# D-1190 — Dois ícones novos de tipo de Move: Field e Status

- **Data:** 2026-11-12
- **Área:** UI / Moves / ícones de tipo (`assets/ui/icons/move_types/`).
- **Relacionadas:** D-395 (três ícones de Move), D-396/D-397 (Starburst, Sparkle, Escudo, Dodge; setas de alcance em fundo branco), D-416/D-419 (badges em paralelogramo flat ao lado do nome), D-1145 (Status puro sem ícone de tipo), D-1185 (o criador vai criar ícones para efeitos de status).
- **Estado:** **escolhido pelo criador (2026-11-12); os dois SVGs foram criados em `assets/ui/icons/move_types/` (`field.svg`, `status.svg`); não estão ligados ao jogo (nenhum código alterado).**

## Escolha do criador (2026-11-12)

> Perfeito nas duas opções A
>
> quanto no field, a cor verde

- **Field:** o desenho do protótipo (elipse em perspectiva + estrela plana de 5 pontas) está aprovado; **cor do badge: verde** (o verde `#22c55e` do protótipo; o tom exato não foi dito).
- **Status:** **opção A — Modificador (+ sobre −)** aprovada.
- A **cor do badge de Status** não foi dita; a laranja `#fb923c` do protótipo continua só como sugestão.

## O que o criador disse (literal)

> vamos criar 2 icones novos, O Field e o icone de status para tipo de moves
>
> para o tipo field, eu já tenho uma ideia, é um circulo deitado em perspectiva com uma estrela no meio acima dele flutuando, minimalista, a estrela não tá com perspectiva
>
> o outro eu estou adepto a suas ideias, quero 3 opções de interpretações

## Regra pedida

1. **Field** (novo tipo de Move, ao lado de Physical, Magical, Guard e Dodge): ícone minimalista = **círculo deitado em perspectiva** (elipse no chão) com **uma estrela flutuando acima do centro dele**; **a estrela não tem perspectiva** (fica de frente, plana).
2. **Status** (ícone de tipo para os Moves de status, que hoje não têm nenhum): o criador pediu **3 opções de interpretação** e vai escolher.
3. Os dois seguem o padrão dos ícones de tipo existentes: SVG 24×24 branco (`fill="#ffffff"`), desenhado dentro de um badge em paralelogramo flat colorido (D-416), legível a 15 px.

## Em aberto (decidir antes de ligar no jogo)

- **Cor do badge** de Field e de Status: não foi dita. O protótipo mostra uma **sugestão do assistente**, marcada como tal.
- **Quais Moves são Field**: o criador não disse. Hoje nenhum Move é desse tipo e o código (`Skill.type_icon_name()`) não tem o caso; ligar o ícone no jogo é uma etapa separada, só depois da aprovação do desenho.
- **Status:** hoje Moves de status não mostram ícone de tipo (D-395/D-1145); com o ícone novo, passam a mostrar? A confirmar junto com a escolha.

## Escolhas do assistente (marcadas no protótipo)

- A estrela do Field é de **5 pontas**, para não repetir o Sparkle de 4 pontas do Magical.
- A elipse é um **anel** (borda grossa, sem preenchimento) com espessura em perspectiva correta, para continuar legível a 15 px.
- As 3 interpretações de Status são conceitos diferentes entre si (ver protótipo).

## Estado

- Protótipo: `prototypes/icones_field_status_lab.html`.
- Nada alterado em `assets/`, `scripts/` ou `content/`. Nada de commit/push (D-022).

## Aplicação no jogo e no protótipo D-1185 (2026-11-12, sessão "Organizar pasta")

Pedido repassado pela sessão "Melhorias de ficha de personagem", com as frases do criador acima ("Perfeito nas duas opções A", "quanto no field, a cor verde").

1. **Mudança de regra (substitui a parte da D-1145/D-395 "status puro não tem ícone de tipo"):** `Skill.type_icon_name()` passa a devolver **`"status"`** para `Kind.STATUS`. Moves de status (Heal, Media, Sukunda, Taunt, Tarukaja, Rakunda, War Cry…) mostram o ícone ± no badge de tipo em: `status_screen.gd` (faixa e ficha), `skill_info_panel.gd`, `fan_menu.gd`, `move_card.gd`, `battle_hud.gd` (cartão de wind-up) e na inspeção (`move_inspection_modal.gd` já lia o nome).
2. **Field disponível, sem uso:** o tipo `"field"` existe no sistema (cor do badge verde `#22c55e`, glifo escuro) e é ativado por uma tag `field` no `MoveData`. **Nenhum Move tem essa tag**: o criador não disse quais Moves são Field.
3. **Cor do badge de Status — PROVISÓRIA:** laranja `#fb923c` (sugestão do protótipo), glifo escuro. **O criador não escolheu a cor.**
4. **Alcance dos Moves de status:** continua sem ícone de alcance (só o tipo foi pedido). Em aberto.
5. **Teste:** `tests/battle/test_d1145_move_type_icons.gd` esperava `""` para Media e Sukunda (regra antiga); passa a esperar `"status"`, por causa desta decisão.

## Cor do badge de Status (2026-11-12)

> acho que faz mais sentido ser branco do que laranja

Badge de Status passa a ser BRANCO `#ffffff`, com glifo escuro `#080e18` (igual ao badge guard). Substitui o laranja provisório `#fb923c` da seção 3 acima.

Aplicado em: `status_screen`, `skill_info_panel`, `fan_menu`, `move_card`, tela de pós-combate (`pc_draw`) e protótipo D-1185 (`prototypes/level_up_overhaul.html`).
