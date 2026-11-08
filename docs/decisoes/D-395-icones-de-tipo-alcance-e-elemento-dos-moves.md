# D-395 — Três ícones de Move: Tipo de dano, Alcance e Elemento

- **Data:** 2026-11-07
- **Área:** UI / Moves / Combate
- **Origem:** decisão direta do criador, na conversa.
- **Estado:** regra registrada; sem código.

## Declaração literal do criador

> ainda precisamos definir os icones de cada tipo de move e elemento (são 3 icones, o Tipo (fisico / magico / nenhum ou seja, sem o icone presente para moves de status), o Alcance (seta pra cima pra melee, traço reto Mid range e seta pra baixo long range ou nada se for um move de status) e o Elemento

## Regra aprovada

Cada Move exibe até **três ícones indicadores** em sua identificação no HUD e menus:

1. **Ícone 1 — Tipo de Dano (Categoria):**
   - **Físico:** exibe o ícone de dano físico.
   - **Mágico:** exibe o ícone de dano mágico.
   - **Nenhum (Status / Suporte):** sem ícone presente de tipo de dano para golpes de status, cura ou buffs/debuffs.

2. **Ícone 2 — Alcance (Range):**
   - **Melee (Corpo a corpo):** seta para cima (`↑`).
   - **Mid Range (Médio alcance):** traço reto (`—`).
   - **Long Range (Longo alcance / Projétil / Distante):** seta para baixo (`↓`).
   - **Status (Pessoal / Sem alvo posicional):** sem ícone presente de alcance (nada).

3. **Ícone 3 — Elemento (SMT-inspired, D-118):**
   - Exibe o glifo/símbolo do elemento correspondente (ex.: Físico, Fogo, Gelo, Raio, Psíquico, Luz, Trevas, etc.).

## Ambiguidades em aberto (perguntar antes de agir)

- Desenho visual exato dos glifos de "Físico" e "Mágico" (ex.: espada/punho vs. cajado/orbe/estrela mágica).
- Conjunto fechado dos glifos visuais de cada um dos 11 elementos SMT (D-118).

## Estado no código

Nenhuma alteração.
