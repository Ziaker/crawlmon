# D-1088 — Câmera de diálogo: dois-shot, trava movimento e volta suave

- **Data:** 2026-11-09.
- **Área:** Exploração / câmera / diálogo.
- **Relacionadas:** D-1023 (câmera/colisão), D-1063 (NPCs), D-1085 (prompt).
- **Status:** **direção aprovada; implementação depois da escolha do HUD**; batalha, 2D e regras não mudam; nada publicado.

## O que o criador disse (literal)

> 4 - camera que da zoom no NPC que estamos conversando (sem tirar os personagens de vista)

> de resto vamos com suas recomendações

## Decisão

1. **Travar o movimento do jogador** durante a conversa.
2. **Travar a rotação da câmera** durante a conversa.
3. **Enquadramento dois-shot:** jogador + NPC; aliados no fundo se couberem. Se algum personagem importante ficar fora, abrir o enquadramento em vez de cortar.
4. **Zoom moderado:** ~2,8–3,2 m, FOV ~45; transição de ~0,4 s com ease; volta suave ao fechar.
5. **Colisão:** a câmera continua sem atravessar paredes (D-1023); se não houver espaço, escolhe o lado com mais folga.
6. **Só NPCs:** porta/saída não entra no modo de câmera de diálogo.
7. **Não muda:** batalha, 2D, HUD/status, cards, regras.

## Ambiguidades

- Zoom/enquadramento exatos serão ajustados com captura; a referência é “sem tirar os personagens de vista”.
- O jogador pode girar a câmera? Não, fica travada durante a conversa.

## O que não foi verificado

- NPCs encostados em parede, câmera muito perto, 60 fps/mobile e outras resoluções.
- A cena principal em headless continua bloqueada pelos erros de VFX de outra sessão; teste no lab isolado.

## Estado

Direção aprovada; implementar depois que o HUD de diálogo for escolhido. Nada publicado.
