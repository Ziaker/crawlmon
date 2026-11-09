# D-1023 — Lab 3D em terceira pessoa estilo SMT III

- **Data:** 2026-11-08
- **Área:** Exploração / overworld / câmera / laboratório 3D
- **Origem:** depois de abandonar o overworld 2D (D-1022), o criador escolheu a câmera em terceira pessoa estilo Shin Megami Tensei III para o primeiro teste 3D.
- **Status:** lab implementado e corrigido; vídeos solo e do grupo gravados; **o jogo normal não muda**; a câmera final, a escala e a geração de mapa continuam pendentes; nada publicado.

## O que o criador disse (literal)

Pergunta: qual câmera/estilo testar na sala 3D primeiro?

> Só terceira pessoa SMT III

Depois de ver o primeiro teste:

> o pancham está mt grande além de ambos ele e o orc não seguirem o jogador corretamente ao lado dele (eles tambem nao estao executando suas animações de caminhada), um pouco atrás (não mais em fila, como um triangulo onde o jogador fica na ponta)

> os personagens não tem sombra ainda, corrija, corrija também a questão da iluminação no chão do ambiente, tire essas luzes azuis

> quando for ficar abrindo o godot pra testar o jogo, desliga esse lock do mouse pra câmera, eu não consigo mexer no meu PC com esse lock de movimento, além disso não abra o jogo como janela em foco

## Decisão

1. **Só laboratório.** Uma cena 3D isolada, sem tocar no overworld 2D atual, na batalha, na party, na colisão do jogo normal ou nas regras.
2. **Câmera:** terceira pessoa atrás do personagem, com follow suave, colisão contra paredes e inclinação para baixo — referência SMT III/Nocturne. Solo: 3,4 m, altura 0,85 m, 8°. Grupo: 6,2 m, altura 1,5 m, 22°, para o triângulo caber.
3. **Sala:** corredor em L de pedra, paredes, teto, pilares, tochas e porta de saída. É um teste de câmera, escala, formação e luz, não uma dungeon final.
4. **Personagens:** Abra, Pancham, Orc e um DQT Slime. Alturas provisórias do lab: Abra 1,0 m, **Pancham 0,7 m**, Orc 2,1 m, Slime 1,4 m. Nada disso vira regra sem nova decisão.
5. **Movimento:** dungeon crawler — frente/trás e virar; câmera atrás. Sem combate, dano ou batalha.
6. **Seguidores:** triângulo com o **jogador na ponta**; Pancham atrás/esquerda (1,3 m atrás, 1,4 m ao lado) e Orc atrás/direita (1,9 m atrás, 2,4 m ao lado). Eles seguem a posição do jogador, com idle/walk; não é a regra final de D-309/D-314.
7. **Sombra:** blob de contato sob jogador, Pancham, Orc e Slime, além da sombra direcional. A regra final de sombra do jogo continua pendente.
8. **Luz:** sem luzes azuis. Piso/paredes em pedra neutra, tochas quentes, preenchimento quente e porta dourada. O único azul restante é o modelo do Slime, não uma luz.
9. **Mouse/janela:** o mouse **não** é capturado; a câmera usa Q/E ou arrastar com o botão direito. Gravações automatizadas rodam com a janela **unfocusable** e fora da tela (`--position -4000,0`), para não roubar o foco.
10. **O que não muda:** o jogo 2D atual continua funcionando como referência; batalha 3D, party, atributos, Moves e UI intactos.

## Correções feitas nesta rodada

- **Pancham:** 1,1 m → **0,7 m**; sombra 0,7×0,45. Ficou visivelmente menor que o Abra.
- **Formação:** saiu da fila/V à frente; agora é um triângulo com o jogador na ponta, aliados um pouco atrás e aos lados.
- **Caminhada:** a animação agora é escolhida pelo **deslocamento real** do seguidor, não pela distância ao alvo; `walk` foi confirmado nos dois (`anim=walk`) durante o movimento.
- **Sombras:** blob de contato em todos os personagens; o Abra, o Pancham, o Orc e o Slime têm sombra no chão.
- **Luzes azuis:** removidos os rodapés ciano, o preenchimento azul, o rim azul do jogador e o tom azul do ambiente; piso/paredes neutros, tochas quentes e porta dourada.
- **Câmera do grupo:** subiu para 6,2 m/1,5 m/22° para o Orc caber inteiro; o Orc ainda é grande porque está atrás e perto da câmera, mas o jogador continua visível na ponta.
- **Mouse:** sem captura; Q/E ou botão direito. **Janela:** gravações em segundo plano, sem foco.

## Aliados: física e IA (lab)

- Pancham e Orc agora são **CharacterBody3D** com cápsula própria (layer 4, máscara 1): colidem com paredes, pilares e batentes, e deslizam em vez de atravessar.
- **Raycast de obstáculos:** três raios à frente/±32° a meia altura; a normal/tangente da parede entra na direção desejada. O alvo da formação é clampado por um raio jogador→alvo quando cai atrás de uma parede.
- **Separação:** empurram-se para não empilhar entre si nem no jogador; não colidem fisicamente com o jogador para não travar a câmera.
- **Máquina de estados:** `IDLE` (perto do alvo, jogador parado), `FOLLOW` (3,4 m/s), `CATCH_UP` (4,6 m/s quando o alvo está a mais de 2,4 m), `AVOID` (raycast ativo, velocidade reduzida) e `RECOVER` (alvo mais perto do jogador depois de 1,2 s bloqueado).
- **Animação:** `walk` pelo deslocamento/velocidade real, com `speed_scale` acompanhando a velocidade; idle vira o corpo para o jogador.
- O Slime de referência some depois que o jogador passa, para não ficar gigante entre a câmera e o grupo.
- Isto é **lab**: para uma dungeon 3D real, o caminho de produção é `NavigationRegion3D` + `NavigationAgent3D` (navmesh), com estes raycasts como camada de segurança.

## Resultado e verificação

- **Vídeo solo:** Abra caminha sozinho pelo corredor em L, passa pelo Slime, vira à direita e chega à porta; câmera atrás com colisão.
- **Vídeo do grupo:** triângulo com o jogador na ponta; Pancham menor, Orc à direita; os dois caminham com `walk`, têm sombra e o Orc desvia/desliza no pilar e na curva sem atravessar a parede.
- **Luz:** piso e paredes quentes, sem rodapés/azuis; a porta é dourada; o único azul é o Slime.
- **Mouse/janela:** a lab não captura o mouse; a gravação off-screen gerou os 345 quadros sem erro.
- **Worktree compartilhado:** a cena foi gravada num projeto isolado em `scratch/third_person_lab/` porque o projeto principal está temporariamente bloqueado por erros de parse de outra sessão (`TidalSurgeVfx`). O script da lab é autônomo (só `DqtModelProfiles` + GLBs) e é o mesmo que está em `scripts/debug/`.
- Nenhum erro de script na lab isolada; o jogo normal 2D continua intocado.

## O que não foi verificado

- Distância/FOV/altura/inclinação finais da câmera; o Orc ainda ocupa muito espaço no grupo.
- Colisão, escala e câmera em mapas 3D gerados de verdade.
- Navegação em mapa 3D real com `NavigationRegion3D`/`NavigationAgent3D`; a lab usa raycast + `move_and_slide`.
- A colisão entre aliados e o jogador é separação, não física (para não travar a câmera).
- Regra final de sombra (o blob é do lab).
- Transição para a batalha, encontros, névoa e performance.
- Mobile/web.
- A lab no projeto principal só poderá rodar depois que a outra sessão corrigir os scripts de VFX.

## O que ainda não está decidido

- Distância, FOV, altura e inclinação finais da câmera.
- Se a câmera será livre, presa atrás do personagem ou híbrida.
- Escala final do mundo e dos personagens.
- Geração de mapa 3D, kit de cenário, portas/escadas, encontros e transição para a batalha.
- Formação/colisão final dos seguidores e névoa.
- Regra final de sombra.
- Performance em desktop/mobile/web.

## Estado

Lab implementado em `scenes/debug/third_person_3d_lab.tscn` + `scripts/debug/third_person_3d_lab.gd`; gravações em `docs/referencias/exploracao/3d/`:
- `third_person_solo.mp4/.gif` e `third_person_party.mp4/.gif` — 11,5 s, 1280×720, 30 fps.
- `third_person_solo.png`, `third_person_solo_porta.png`, `third_person_party.png`.
- `third_person_solo_contato.png` e `third_person_party_contato.png`.

Jogo normal 2D intocado; commits locais; **nada publicado**.
