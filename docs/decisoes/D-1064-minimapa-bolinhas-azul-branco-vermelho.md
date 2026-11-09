# D-1064 — Mini-mapa só com bolinhas: azul (jogador/aliados), branco (NPCs) e vermelho (inimigos)

- **Data:** 2026-11-09
- **Área:** Exploração / mini-mapa / UI
- **Origem:** mudança de planos do criador depois de ver o mini-mapa com o ícone dele; o ícone foi descartado.
- **Status:** **teste implementado no lab**; substitui as partes de ícone/tamanho de marcador da D-1027 e D-1037; o ícone e os PNGs de marcador foram removidos; nada publicado.

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

## Teste implementado (2026-11-09)

- **Ícone removido:** `assets/exploration/minimap_marker.png` e os quatro `marker_*.png` (com os `.import`) foram apagados do projeto. O script não carrega mais textura de marcador.
- **Bolinhas:** `_add_minimap_marker` cria um `Panel` circular com `StyleBoxFlat`, sem textura. Tamanhos: jogador 12 px, aliados 8 px, NPCs 10 px, inimigos 10 px. Cores: azul `Color(0.25, 0.55, 1.0)` para jogador/aliados; branco para NPCs; vermelho `Color(1.0, 0.22, 0.18)` para inimigos. Contorno escuro de 1 px só para contraste. O jogador tem `z_index` maior e fica por cima.
- **Sem animação:** as bolinhas são estáticas; a posição é atualizada a cada frame com o personagem. Não há pulso, bob ou desenho procedural.
- **O resto continua:** mini-mapa 112×112 sem título, top-down seguindo o jogador; HUD de HP/MP no canto esquerdo; alerta "!" quando o Slime entra em `CHASE`.
- **Auditoria solo:** dots `sizes=[12,8,8,10]`, `colors=[azul, azul, azul, vermelho]`, `dots_ok=true`; mini-mapa 112×112/escala 0,4375/centro (56,56)/sem texto "MAPA"; HUD 3 badges, 1 visível; MP 14/10/8; alerta falso no 100 e verdadeiro nos 220/280; 0 paredes/câmeras/paths/stack; porta e `CHASE`; toon true.
- **Auditoria party:** dots iguais; HUD 3 badges visíveis; mini-mapa com 4 marcadores (jogador + 2 aliados azuis menores + inimigo vermelho); o resto igual.
- **Vídeos/stills:** `docs/referencias/exploracao/3d/murky_forest_solo.*`, `murky_forest_party.*`, `murky_forest_minimap.png`, `murky_forest_hud.png`; 11,0 s / 330 quadros.

## O que não foi verificado nas bolinhas

- Um NPC real com bolinha branca (o grupo `minimap_npc` existe, mas o lab não tem NPC).
- O tom exato do azul e os tamanhos 12/8/10/10; ajustáveis depois do vídeo.
- O contorno escuro: se o criador quiser bolinha chapada sem contorno, remover.
- Animação/pulso das bolinhas; por ora, estáticas.
- O mini-mapa em mapas 3D gerados de verdade (o lab usa o L fixo).
- Performance em 60 fps, mobile/web, licença.

## Estado

Teste implementado no lab isolado. O mini-mapa agora usa só bolinhas azuis/brancas/vermelhas, sem ícone e sem textura; o HUD de HP/MP e o alerta continuam. O jogo normal 2D, a batalha e as regras não mudam; nada publicado.
