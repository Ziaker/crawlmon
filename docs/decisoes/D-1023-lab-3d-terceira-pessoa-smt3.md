<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1023 — Lab 3D em terceira pessoa estilo SMT III

- **Data:** 2026-11-08
- **Área:** Exploração / overworld / câmera / laboratório 3D
- **Origem:** depois de abandonar o overworld 2D (D-1022), o criador escolheu a câmera em terceira pessoa estilo Shin Megami Tensei III para o primeiro teste 3D.
- **Status:** lab implementado e corrigido; Onda 1 (navmesh, IA do Slime, poeira de passo, porta e vinheta) auditada em solo e party; vídeos solo e do grupo gravados; **o jogo normal não muda**; a câmera final, a escala e a geração de mapa continuam pendentes; nada publicado.

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
6. **Seguidores:** triângulo com o **jogador na ponta**; Pancham atrás/esquerda (1,3 m atrás, 0,9 m ao lado) e Orc atrás/direita (2,0 m atrás, 1,7 m ao lado). Eles seguem a posição do jogador, com idle/walk; não é a regra final de D-309/D-314.
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
- **Máquina de estados:** `IDLE` (perto do alvo, jogador parado), `FOLLOW` (3,8 m/s), `CATCH_UP` (5,2 m/s quando o alvo está a mais de 1,6 m), `AVOID` (raycast ativo, piso de 4,2 m/s) e `RECOVER` (alvo mais perto do jogador depois de 1,2 s bloqueado).
- **Animação:** `walk` pelo deslocamento/velocidade real, com `speed_scale` acompanhando a velocidade; idle vira o corpo para o jogador.
- O Slime de referência some depois que o jogador passa, para não ficar gigante entre a câmera e o grupo.
- Isto é **lab**: os aliados e o Slime já usam `NavigationAgent3D` sobre uma `NavigationMesh` em L feita à mão (3 polígonos); para uma dungeon real, o caminho de produção é o bake da navmesh a partir dos colliders, com estes raycasts como camada de segurança.


## Onda 1: navegação, IA, interação e auditoria

- **Navmesh do lab:** `NavigationRegion3D` com uma `NavigationMesh` em L feita à mão (3 polígonos, cell 0,25, agente 0,45/2,1). Aliados e Slime usam `NavigationAgent3D`; o path é consultado com `get_next_path_position()` **antes** de checar `is_navigation_finished()` (a ordem errada deixava o path sempre vazio e os agentes andavam por vetor direto). Numa dungeon real, isto vira bake a partir dos colliders.
- **Inimigo:** o Slime agora é `CharacterBody3D` na layer 8 (máscara 1), com `NavigationAgent3D` e máquina `PATROL → CHASE → SEARCH → RETURN`; vê por distância + raycast de linha de visão, persegue, procura o último ponto e volta à patrulha. Ele se esconde quando fica a menos de 6,2 m horizontais da câmera para não tapar o grupo.
- **Passos:** poeira de passo (`CPUParticles3D`, 6 partículas, 0,45 s) no jogador, nos dois aliados e no Slime; liga/desliga pelo deslocamento real. Funciona no renderer Compatibility.
- **Porta:** o prompt `Z/E: SAÍDA` aparece quando o jogador está a até 1,5 m da porta e olha para ela (ray de 3,2 m); depois de usar, o texto vira `SAÍDA`. A ação `lab_interact` é registrada no próprio lab (E/Z) e não depende do `GameState`.
- **Câmera:** continua por raycast (o `SpringArm3D` foi testado e colocado a câmera no pé do jogador; revertido). O raycast exclui jogador, aliados e inimigo e usa uma sonda esférica de 0,18 m para recuar se o ponto final raspar a parede.
- **Ambiente:** vinheta quente (`shaders/vignette.gdshader`) em `CanvasLayer`, sem azul.
- **Auditoria automatizada:** `audit.tscn` no projeto isolado roda 330 quadros em solo e party e mede: corpo dentro de parede, câmera dentro de parede, câmera colada no jogador, tamanho do path, empilhamento e porta. Resultado final: **0 corpos em parede, 0 câmeras dentro, 0 câmeras coladas, path mínimo 2, 0 pares empilhados, porta `near/visible/used` verdadeiros, Slime em `CHASE`**.
- **Correções que a auditoria achou:** a ordem do `NavigationAgent3D`; o `SpringArm3D` que colocava a câmera no pé do jogador; o prompt da porta fora de alcance; o Slime gigante entre câmera e jogador; a layer 3 do Slime (layers 1+2) que fazia a câmera colidir com ele; a câmera raspando a parede; e os aliados atrás do pilar de (13, -7), que ficavam 3 m atrás do alvo — triângulo estreitado para 0,9/1,7 m, alvo clampado 0,6 m além e piso de velocidade 4,2 m/s no `AVOID`.
- **Timeline da gravação:** 11,0 s (330 quadros a 30 fps); anda 1,0–3,8 s, vira à direita 3,8–4,9 s, anda 4,9–9,7 s, interage 10,3–10,6 s.

## Resultado e verificação

- **Vídeo solo:** Abra caminha sozinho pelo corredor em L, passa pelo Slime (que patrulha, vê, persegue e volta), vira à direita e chega à porta com o prompt `Z/E: SAÍDA`; câmera atrás com colisão.
- **Vídeo do grupo:** triângulo com o jogador na ponta; Pancham menor, Orc à direita; os dois caminham com `walk`, têm sombra e poeira de passo, e o Orc desvia/desliza no pilar e na curva sem atravessar a parede. A formação foi estreitada para não cair atrás do pilar.
- **Luz:** piso e paredes quentes, sem rodapés/azuis; a porta é dourada; o único azul é o Slime.
- **Mouse/janela:** a lab não captura o mouse; a gravação off-screen gerou os 330 quadros sem erro.
- **Worktree compartilhado:** a cena foi gravada num projeto isolado em `scratch/third_person_lab/` porque o projeto principal está temporariamente bloqueado por erros de parse de outra sessão (`TidalSurgeVfx`). O script da lab é autônomo (só `DqtModelProfiles` + GLBs) e é o mesmo que está em `scripts/debug/`.
- Nenhum erro de script na lab isolada; o jogo normal 2D continua intocado.

## O que não foi verificado

- Distância/FOV/altura/inclinação finais da câmera; o Orc ainda ocupa muito espaço no grupo.
- Colisão, escala e câmera em mapas 3D gerados de verdade.
- Bake real de navmesh a partir dos colliders, Jolt e nomes de layer de produção; a lab usa uma navmesh em L feita à mão e a layer 8 provisória.
- A colisão entre aliados e o jogador é separação, não física (para não travar a câmera).
- Regra final de sombra (o blob é do lab).
- Transição para a batalha, encontros, névoa e performance medida em 60 fps fixos; a gravação roda a 30 fps e não é benchmark.
- Blend tree de caminhada/corrida e animação de virar; a lab usa `walk` com `speed_scale`.
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
- `third_person_solo.mp4/.gif` e `third_person_party.mp4/.gif` — 11,0 s (330 quadros a 30 fps), 1280×720; GIF a 12 fps em 640×360.
- `third_person_solo.png`, `third_person_solo_porta.png`, `third_person_party.png`.
- `third_person_solo_contato.png` e `third_person_party_contato.png`.

Jogo normal 2D intocado; commits locais; **nada publicado**.
