# D-1023 — Lab 3D em terceira pessoa estilo SMT III

- **Data:** 2026-11-08
- **Área:** Exploração / overworld / câmera / laboratório 3D
- **Origem:** depois de abandonar o overworld 2D (D-1022), o criador escolheu a câmera em terceira pessoa estilo Shin Megami Tensei III para o primeiro teste 3D.
- **Status:** lab implementado; vídeo solo de 11,5 s e still do grupo gravados; **o jogo normal não muda**; a câmera final, a escala e a geração de mapa continuam pendentes; nada publicado.

## O que o criador disse (literal)

Pergunta: qual câmera/estilo testar na sala 3D primeiro?

> Só terceira pessoa SMT III

## Decisão

1. **Só laboratório.** Uma cena 3D isolada, sem tocar no overworld 2D atual, na batalha, na party, na colisão do jogo normal ou nas regras.
2. **Câmera:** terceira pessoa atrás do personagem, com follow suave, colisão contra paredes e um pouco de altura/inclinação para baixo — referência SMT III/Nocturne. O jogador pode girar a câmera; o movimento é relativo à câmera.
3. **Sala:** um corredor/salão de pedra de ~10×36 m, paredes, teto, pilares, tochas, névoa e uma porta/escada de saída no fundo. É um teste de câmera e escala, não uma dungeon final.
4. **Personagens:** Abra, Pancham e Orc com os GLBs atuais; um inimigo real (DQT Slime) parado no caminho. Escalas provisórias do lab: Abra ~1,0 m, Pancham ~1,1 m, Orc ~2,1 m, Slime ~1,4 m. Nada disso vira regra sem nova decisão.
5. **Movimento:** andar/correr em oito direções no plano, virar para a direção do movimento, idle/walk dos clipes; câmera atrás com mola e colisão; sem combate, sem dano, sem batalha.
6. **Seguidores:** Pancham e Orc seguem o rastro 3D do jogador em fila, com idle/walk; é uma aproximação de laboratório, não a regra final de D-309/D-314.
7. **Registro:** um vídeo de ~12 s no corredor: idle, andar, passar pelo inimigo, virar, chegar à porta. MP4/GIF/PNG.
8. **O que não muda:** o jogo 2D atual continua funcionando como referência; batalha 3D, party, atributos, Moves e UI intactos.

## Resultado e verificação

- **Vídeo solo (o teste principal):** Abra caminha sozinho pelo corredor em L, passa pelo Slime, vira à direita e chega à porta. A câmera fica atrás a 3,4 m, altura 0,85 m, inclinação 8°, com follow suave e raycast de colisão; o personagem fica legível contra o piso e as paredes.
- **Still do grupo:** Abra, Pancham, Orc e Slime aparecem juntos na formação em V; os modelos mantêm as alturas provisórias (1,0/1,1/2,1/1,4 m).
- **Vídeo do grupo:** não foi entregue. Em alguns quadros do walk o Orc renderiza muito maior que o nó (o dumping controlado, no mesmo tempo e com as mesmas posições, renderiza o tamanho certo). Isso aponta para um problema de modelo/animação ou de captura, não para a câmera; precisa ser investigado antes de usar seguidores no 3D.
- **Worktree compartilhado:** a cena foi gravada num projeto isolado em `scratch/third_person_lab/` porque o projeto principal está temporariamente bloqueado por erros de parse de outra sessão (`TidalSurgeVfx`). O script da lab é autônomo (só `DqtModelProfiles` + GLBs) e é o mesmo que está em `scripts/debug/`.
- Nenhum erro de script na lab isolada; o jogo normal 2D continua intocado.

## O que não foi verificado

- Distância/FOV/altura/inclinação finais da câmera.
- Seguidores no 3D (o vídeo do grupo tem a anomalia do Orc no walk).
- Colisão, escala e câmera em mapas 3D gerados de verdade.
- Transição para a batalha, encontros, névoa e performance.
- Mobile/web.
- A lab no projeto principal só poderá rodar depois que a outra sessão corrigir os scripts de VFX.

## O que ainda não está decidido

- Distância, FOV, altura e inclinação finais da câmera.
- Se a câmera será livre, presa atrás do personagem ou híbrida.
- Escala final do mundo e dos personagens.
- Geração de mapa 3D, kit de cenário, portas/escadas, encontros e transição para a batalha.
- Seguidores e névoa na versão final.
- Performance em desktop/mobile/web.

## Estado

Lab implementado em `scenes/debug/third_person_3d_lab.tscn` + `scripts/debug/third_person_3d_lab.gd`; gravações em `docs/referencias/exploracao/3d/`:
- `third_person_solo.mp4/.gif` — o teste de câmera (11,5 s, 1280×720, 30 fps).
- `third_person_solo.png`, `third_person_solo_porta.png` e `third_person_solo_contato.png`.
- `third_person_party.png` — still do grupo; o vídeo do grupo fica pendente pela anomalia do Orc.

Jogo normal 2D intocado; commits locais; **nada publicado**.
