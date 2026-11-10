# D-1088 — Câmera de diálogo: dois-shot, trava movimento e volta suave

- **Data:** 2026-11-09.
- **Área:** Exploração / câmera / diálogo.
- **Relacionadas:** D-1023 (câmera/colisão), D-1063 (NPCs), D-1085 (prompt).
- **Status:** **teste implementado e verificado** no lab isolado (HUD C integrado); batalha, 2D e regras não mudam; commit local; **sem push**.

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

## Teste implementado (2026-11-09)

- **Composição:** **três-quartos pela esquerda (D-1092)**. Orbita o ponto médio jogador↔NPC a 50° para a esquerda, a 3,9 m, altura 1,55 m; o alvo fica 0,35 m abaixo do meio, para os dois aparecerem acima do card. Se a esquerda estiver bloqueada, usa a direita como fallback.
- **FOV:** 55° normal → 45° no diálogo; transição de 0,4 s com o mesmo blend da posição/alvo.
- **Trava:** movimento do jogador, rotação Q/E e mouse ficam bloqueados enquanto `_dialogue_focus` existe; o controle só volta depois que o blend retorna a zero (0,4 s).
- **Colisão:** a câmera testa os dois lados e escolhe o com mais espaço; raycast + sphere probe contra o cenário, ignorando jogador/aliados/inimigo.
- **Personagens em quadro:** o jogador e o NPC aparecem acima do card Paper, vistos de três-quartos pela esquerda; a tentativa lateral de 90° foi descartada porque escondia os dois atrás de folhagem/parede.
- **Aliados:** podem ficar fora do dois-shot; quando falam, entram as **faixas laterais** da D-1092, com nome/retrato, e o ellipsis fica no mundo, acima deles.
- **Provas:** `murky_forest_paper_dialogue.png`, `murky_forest_panchan_reaction.png` e `murky_forest_orc_reaction.png`.

## O que não foi verificado

- NPCs encostados em parede, câmera muito perto, 60 fps/mobile e outras resoluções.
- A câmera em todos os 10 NPCs e em corredores estreitos.
- A cena principal em headless continua bloqueada pelos erros de VFX de outra sessão; teste no lab isolado.

## Estado

Teste implementado e verificado no lab isolado. Câmera de diálogo over-the-shoulder com trava e volta suave. Commit local; **sem push**.
