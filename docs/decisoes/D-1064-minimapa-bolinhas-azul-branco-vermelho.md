# D-1064 — Mini-mapa só com bolinhas: azul (jogador/aliados), branco (NPCs) e vermelho (inimigos)

- **Data:** 2026-11-09
- **Área:** Exploração / mini-mapa / UI
- **Origem:** mudança de planos do criador depois de ver o mini-mapa com o ícone dele; o ícone foi descartado.
- **Status:** direção registrada; **substitui as partes de ícone/tamanho de marcador da D-1027 e D-1037**; implementação pendente; nada publicado.

## O que o criador disse (literal)

> ta mudanca de planos tire o icone que escolhi e troque apenas por bolinhas azuis brancas (npcs) e vermelhas

## Decisão

1. **Remover o ícone** escolhido do mini-mapa. Nada de textura de ícone, PNG de marcador ou desenho procedural de criatura.
2. **Marcadores = bolinhas simples**, sem desenho interno:
   - **azul** = jogador **e aliados** (aliados menores);
   - **branco** = NPCs;
   - **vermelho** = inimigos.
3. **Tamanhos do primeiro teste:** jogador 12 px, aliados 8 px, NPCs 10 px, inimigos 10 px. Ajustáveis depois do vídeo.
4. **Como desenhar:** `Panel`/Control circular com `StyleBoxFlat` (sem textura), cor sólida e um contorno escuro fino de 1 px para leitura no fundo roxo. A bolinha é estática; só a posição se move com o personagem.
5. **O que não muda:** mini-mapa 112×112 (metade), sem o título "MAPA", top-down seguindo o jogador; HUD de HP/MP no canto esquerdo e alerta "!" de inimigo em `CHASE` continuam como em D-1037.
6. **Substituição:** esta decisão substitui, no mini-mapa, o ícone e os tamanhos 20/14/16 da D-1027/D-1037. O resto dessas decisões (2D só como mini-mapa, render top-down, HUD de vida, MP/alerta) continua valendo.

## O que ainda precisa ser definido (ambiguidades)

- **Aliados azuis:** a leitura é que "azuis" vale para jogador + aliados, com aliados menores (como o criador já tinha pedido antes). Confirmar se ele queria só o jogador azul.
- **Tom do azul:** azul royal/ciano? O primeiro teste usa `Color(0.25, 0.55, 1.0)`.
- **Tamanhos:** 12/8/10/10 px são o suficiente? Ajustar depois do vídeo.
- **Contorno:** o criador disse "apenas bolinhas"; o contorno escuro de 1 px é só para contraste. Se ele quiser bolinha chapada sem contorno, remover.
- **NPCs:** o lab não tem NPC; o branco ainda não aparece em vídeo.
- **Animação:** as bolinhas são estáticas; não há pulso/bob. Se quiser, é outra decisão.

## Estado

Direção registrada; nada implementado ainda. O mini-mapa atual ainda usa os PNGs do ícone (D-1027/D-1037); a próxima alteração troca tudo por bolinhas e remove os assets do ícone.
