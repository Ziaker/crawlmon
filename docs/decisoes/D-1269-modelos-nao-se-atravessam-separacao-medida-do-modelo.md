> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** Nenhum teste pode levar mais de 1 minuto; crie o cenário/controle antes de testar. Ver `docs/TELEMETRIA.md`.

# D-1269 — Os modelos dos personagens não se atravessam, em todos os cenários

**Frase literal do criador:** "ache um jeito de não permitir que os modelos dos personagens se entrelacem em TODOS cenários possíveis, não é pra um entrar no outro"

Decisões lidas e aplicáveis: D-235 (nada por personagem/lado), D-314 (aliados sem atravessar o líder), D-1262/D-1267 (ataque do overworld), D-1264 (locomoção), D-1204 (debug < 1 min).

## Causa (medida)
- Camadas de física: líder = 2, aliados = 4, inimigos = 8, NPCs = 16, todos com máscara só do mundo (1). Corpos não colidem entre si; só o líder×NPC colide, e com uma cápsula pequena (0,22–0,42 m) que ignora o tamanho real do modelo.
- NPC patrulha por `global_position += ...` (sem física) e aliado/inimigo só tem `_separation()` fraca (0,8–0,9 m fixos).
- Linha de base (`body_overlap_scenario.gd --off`, floresta): Orc×Cyclops 1,34 m de interpenetração, NPC×NPC 0,43 m, aliado×NPC 0,72 m, líder×NPC 0,40 m (hub).

## Decisão (técnica; nenhuma regra de jogo nova)
1. **`BodyFootprint`** (`scripts/overworld/body_footprint.gd`): mede do próprio modelo um círculo no chão (centro visual + raio, percentil 95 dos vértices skinados na faixa 10–90 % da altura) e a altura. Amostra os clips `idle/walk/run` numa **cópia descartável** do modelo (nunca toca o AnimationPlayer vivo) e usa o maior raio, então não depende da pose do momento. Sem número por espécie (D-235).
2. **`BodySeparation`** (`scripts/overworld/body_separation.gd`): um nó filho de qualquer lab (`attach(lab)`, ligado uma vez em `third_person_3d_lab.gd:_ready`, vale para hub, floresta e o lab base). Todo quadro (física e `_process`, porque NPC anda em `_process`) reúne líder, aliados, NPCs, inimigos (+ grupo `body_actor`) e separa pares sobrepostos no plano do chão até os círculos só se tocarem. Paredes ganham: cada deslocamento é testado contra o mundo (`cast_motion`, máscara 1) e o que a parede recusar vai para o outro ator. Altura (y) nunca é tocada.
3. **Quem cede** (nada de "empurrar NPC" novo): quem **se moveu** para dentro do outro cede, na proporção do deslocamento do quadro; o líder andando contra NPC parado é segurado (como hoje); NPC que patrulha contra o líder parado é que desvia/espera. **Aliado cede a todos que não são aliados** (contorna o líder, D-314, nunca o bloqueia). Empate (spawn sobreposto): líder > NPC = inimigo > aliado. Correção limitada a 9 m/s para um teletransporte não "estalar".
4. **Estados com posição absoluta** (NPC entrando/saindo/ausente do portal, modelo encolhendo) ficam fora da separação; ao voltar a `walk` ela volta a valer.
5. **Controlador de ataque do overworld** (`overworld_attack_controller.gd`): para o "contato" ser exatamente onde o separador deixa dois corpos se tocarem, `_body_radius` usa o mesmo `BodyFootprint` e a distância entre corpos (`_body_distance`) é entre os centros visuais. A **regra de acerto não mudou** (borda com borda, `HIT_EDGE_EPS`, `HIT_REACH`, linha livre, vantagem de quem começou antes); só a medida do corpo passou a ser a compartilhada. Sem isso o separador seguraria o atacante fora do alcance do acerto.

## Verificação (janela real, `tests/overworld/body_overlap_scenario.gd`, ~1 min, sem headless)
Mede o casco convexo (100 % dos vértices skinados, pose atual) de cada par, independente do círculo do separador. Comando:
`Godot_v4.7.2-stable_win64_console.exe --path . --resolution 960x540 --fixed-fps 60 --script res://tests/overworld/body_overlap_scenario.gd -- --lab=forest|hub --out=<pasta> [--off]`
- Floresta, separador ligado: líder anda contra NPC 0,000 m; NPC largado sobre o líder 0,000; dois aliados sobre o líder 0,000 (e líder andando de ré sobre eles 0,000); NPC sobre NPC 0,000; **14 espécies (Orc, Cyclops…) empilhadas no mesmo ponto: 0,000** após assentar; inimigo largado sobre o líder 0,000; avanço de ataque (Z) contra o Cyclops: acerto registrado, borda 0,00 m, interpenetração 0,000.
- Hub, separador ligado: os mesmos casos 0,000 (sem inimigo no hub).
- Linha de base (`--off`): ver Causa. Capturas lidas: `tmp_shots/d1269/forest_off|on/*.png` (pilha de 14 espécies antes/depois; líder×NPC; avanço do ataque tocando a borda do Cyclops).

## Não verificado / limites
- **Combate (BattleSpace)**: não alterado; lá o corpo a corpo encosta de propósito (animação conduz). Se o criador quiser separação também lá, é decisão à parte.
- Cápsula orientada: ponta de cauda/asa além do percentil 98 pode encostar 2–5 cm.
- Pares durante a entrada/saída do portal não foram medidos (estado absoluto, fora da separação); aliado×inimigo em ataque do inimigo ao aliado não foi simulado separadamente.
- O avanço do ataque contra o Orc a 4,3 m não foi adquirido no teste de regressão (não comparado com a base antiga).

## Perguntas ao criador (pendentes, nada decidido por mim)
1. ~~O jogador pode **empurrar** um NPC parado?~~ **Respondida pelo criador: "Não, NPC sólido".** O NPC parado segura o jogador (é o que o código já faz: quem se move contra o parado cede). Nada a mudar.
2. ~~Separação no **combate**?~~ **Criador: "por ora não".** Combate fica fora.
3. ~~Círculo ou cápsula?~~ **Criador: "prefiro cápsulas".** Implementado: cada corpo é uma cápsula orientada no eixo frontal do modelo (segmento + raio lateral, percentil 98 multi-pose); separador e contato do ataque (`BodyFootprint.gap`) usam a mesma cápsula. Medido na floresta: todos os casos 0,000 m, exceto a pilha de 14 espécies no mesmo ponto (stress) com resto de 2–5 cm (pontas de asa/cauda); avanço do ataque: acerto, borda 0,00, 0,000.

## Revisão (criador: "volta atrás, permita empurrar os npcs, além disso estas capsulas estão largas demais")
- **Empurrar NPC: permitido** (revoga o "NPC sólido"). O separador tira a camada do NPC da máscara física do líder e o NPC cede sempre ao líder. Medido no hub: líder andando contra NPC parado empurra o NPC 1,13 m e não é barrado; interpenetração 0,000.
- **Cápsulas estreitas**: percentil 94 (média das poses, não o máximo) em vez de 98/máximo. Causa principal do "largo demais": medida de spawn transitória em cache (Slime media 0,77 m de raio, o real é 0,28); agora há uma remedição única após 2,5 s e retentativa se os clips ainda não estão prontos. Raios atuais: Slime 0,28, Abra 0,34 (+0,15 de meio-comprimento), Pikachu 0,15, Orc 0,68, Cyclops 0,88.
- Consequência assumida: pontas de braço/asa/cauda/arma podem encostar (pilha de 14 espécies no mesmo ponto: até 0,29 m no pior par, Abra×Gible; casos reais de jogo: 0,000 exceto aliado×NPC 0,07 m logo após largar sobre o líder). O ajuste é uma constante (`PERCENTILE` em `body_footprint.gd`).
- Combate: por ora não (criador).

## Revisão 2 (criador: "npcs que não se movem não podem ser empurrados, npcs que se movem podem e também devem abrir espaço pro jogador, nunca permitir que tomem o espaço do jogador específicamente no hub")
- NPC **sem patrulha** (`waypoints` <= 1) é imóvel: segura o líder e nunca é deslocado. NPC **com patrulha** cede sempre ao líder (pode ser empurrado e abre espaço); o líder nunca cede a NPC. Aliado e inimigo cedem a NPC imóvel. Medido no hub: parado `npc_moved=0.0`; patrulheiro `npc_moved=1.48`; interpenetração 0,000 nos dois. Na floresta os NPCs são todos sem patrulha, logo imóveis.
