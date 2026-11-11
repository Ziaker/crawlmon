# D-1175 — Javelin Throw: escala do wind-up pelo atacante, subir e alongar a javelin

- **Data:** 2026-11-11.
- **Área:** VFX / Javelin Throw.
- **Origem:** ordem direta do criador no chat.

## O que o criador pediu (literal)

> "a javelin ta imensa no wind up do jogador e minuscula no wind up do oponente, eu deixaria ela um pouco mais pra cima levando em conta o corpo do personagem pra nao entrar dentro do personagem, alem de tambem deixar ela mais longa pra parecer menos uma flecha"

## Achado técnico (causa da diferença de tamanho)

O driver `fx_javelin_throw.gd` calculava `view_scale` com `_view_scale_at(chest)` — a distância da **câmera até o chest do alvo**. Consequência:

- jogador atacando: o alvo está longe → escala máxima 3,2 → a javelin na mão do jogador fica **imensa**;
- oponente atacando: o alvo (jogador) está perto → escala 1,0 → a javelin na mão do oponente fica **minúscula**.

A javelin é um efeito ancorado no **atacante**; a escala tem de vir da posição real da javelin/mão, não do alvo. O impacto e o retículo continuam usando a escala do alvo, porque estão no alvo.

## O que já está definido

1. **Escala do wind-up/flight:** usar a distância da câmera até a **mão/posição da javelin do atacante** (interpolando até o alvo durante o voo), não o chest do alvo. O impacto e o retículo usam a escala do alvo.
2. **Subir a javelin:** **ambos** — um fixo pequeno **+0,08 m** e um cálculo automático de folga contra o corpo real, com teto de **+0,12 m** (máximo total 0,20 m). A subida é aplicada no wind-up e some suavemente no voo; no laboratório de paridade sem corpo, é zero.
3. **Deixar mais longa:** **haste inteira** — a haste passa de **1,85 m para 2,30 m** (comprimento total 2,245 → 2,695 m). A ponta, o grip e o colar ficam; as penas são reposicionadas para a nova cauda (z=-1,12) para continuar parecendo uma javelin, não uma flecha.
4. **Escala da javelin:** usa a mão do atacante; o impacto/retículo usam a escala do alvo.

## Primeira passada (para você checar no vídeo)

- Fixo: **0,08 m**.
- Automático: até **0,12 m** adicionais, calculado contra o AABB do corpo (amostras da haste até a cauda; folga de 0,03 m).
- Haste: **2,30 m** (total **2,695 m**).
- Penas: nova posição na cauda, **z=-1,12**.

Se “um pouco” for mais ou menos que isso, o número é fácil de ajustar; o vídeo é justamente para você medir.

## Ambiguidades em aberto

1. O **valor do fixo** (0,08 m) e do teto automático (0,12 m) são a primeira passada; você pode pedir mais/menos.
2. O **comprimento** de 2,30 m da haste é a primeira passada; você pode pedir mais/menos.
3. A correção de escala por si só resolve o "imensa/minúscula", ou você quer um tamanho-alvo em tela (ex.: mesma fração da tela para jogador e oponente)?

## Estado no código

**Primeira passada implementada; aguardando aprovação visual.** `fx_javelin_throw.gd` usa escala da mão para a javelin e escala do alvo para retículo/impacto; `javelin_throw_vfx_html.gd` usa haste de 2,30 m, penas na cauda, subida fixa + automática e mantém o A/B do HTML sem subida no laboratório. Nenhuma regra de D-1103 muda.
