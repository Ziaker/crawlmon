<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** Nenhum teste >1 min; crie cenário/controle. `--view=gate_closed|gate_open|gate_close`, `--warp=murky_forest [--warp-enter]`, `--scenario=HUB_GATE_PORTAL`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1273 — Expedition Gate: modelo e local refeitos, só o portal abre, entrada sincronizada com o loading

Estado: **implementada e verificada por dados e capturas reais; aprovação visual do criador pendente.** Relacionadas: D-1260 (warp), D-1238 (NPCs no portal), D-1266 (altar), D-1261 (equipe), D-1237 (loading).

## Frases literais do criador
- "faça um overhaul visual do modelo e do local (o problema agora é que ele é mt mais alto do que devia, além de visualmente não indicar uma das coisas mais importantes do jogo. Ele deve ser chamativo visualmente e detalhado o bastante pra fazer o jogador ir a ele, quero que me surpreenda (não peça nada a mim)) que fazemos a expedition gate"
- "faça com que apenas o portal se abra, não que o personagem/jogador seja forçado a entrar nele, isso deve ser decisão do jogador"
- "além de também ter uma cutscene de entrada com uma transição que leva até o loading de forma sincronizada"

## O que o criador deixou à IA (visual)
"Quero que me surpreenda (não peça nada a mim)": forma, materiais, efeitos e tempos do novo portal são escolha minha, registrados abaixo para ele poder mudar. Nada de regra de jogo foi decidido por mim.

## Implementado (escolhas da IA, mudáveis)
1. **Modelo** (Blender, hard surface, `tools/blender/build_expedition_gate.py` → `assets/hub/expedition_gate.glb`): anel de pedra de 24 blocos com bisel e tons alternados, filete de ouro, runas emissivas, coroa de ouro com três espigões, gema nas duas faces, pés de pedra e dois cristais de runa; patamar redondo de dois degraus (rampas andáveis) com anel de runas gravado. Altura total **3,67 m** (o arco antigo tinha 5,5 m). Abertura circular de 2,5 m (passa o Orc/Cyclops de 2,2 m).
2. **Vida** (`scripts/hub/hub_gate.gd`): runas respiram, 7 estilhaços orbitam o anel, partículas sobem, coluna de luz vertical para ser vista da praça inteira, luz própria. **Dormente** = só um brilho âmbar no aro (pulsa quando um NPC entra/sai, D-1238); **aberto** = vórtice em espiral nas cores do mundo (D-1260), runas, luz e coluna na cor do mundo.
3. **Fluxo:** confirmar o mundo no painel do Gate → faixas pretas, câmera no portal, ele abre em espiral → **a câmera volta ao jogador e o controle é devolvido com o portal aberto**; nada move o jogador. Só entrar na boca do portal (pelo próprio movimento do jogador) dispara a entrada.
4. **Cutscene de entrada:** faixas, câmera enquadra o anel, o grupo é puxado para o vórtice (escala até 0, líder primeiro), o portal intensifica; um círculo parte do portal e enche a tela com a cor do loading (#051322); com a tela sólida o loading começa (a primeira imagem dele é essa mesma cor: sem corte). Um relógio só (`_warp_ms`).

5. **Correção do criador (2026-11-17), print do totem "EXPEDITION GATE":** "vc mudou o portal e não o que eu pedi pra mudar". O "Expedition Gate" que ele pediu para refazer é o **totem/placa onde se abre o painel**, não o arco do portal. Refeito: **Expedition Board** (Blender, `tools/blender/build_expedition_board.py` → `assets/hub/expedition_board.glb`, `scripts/hub/hub_board.gd`), ~2 m (antes poste + painel até 2,7 m e nome a 3,05 m), pedra, painel de madeira com 5 avisos e selos de cera, bússola dourada girando com anel de runas, duas lamparinas, luz âmbar e coluna de luz suave; nome flutuante a 2,45 m. **Local:** saiu do canto escondido (-3,2, -9,5) para (-3,0, -6,2), na rota até o portal, virado para o centro da praça (`BOARD_POS`, `BOARD_YAW`). O arco do portal novo ficou (a abertura sozinha e a cutscene valem por ele); se o criador quiser o arco antigo de volta, é só dizer. Capturas: `--view=board|board_close`.

6. **Ordem do criador (2026-11-17), literal:** "depois que finalizar, deixe o portal no mínimo 2X maior (junto com os seus efeitos e etc)". `HubGate.SCALE = 2.0`: anel 7,34 m de altura e abertura de 5 m (o "3,67 m" do item 1 é a medida a 1x), patamar, coluna de luz, partículas, estilhaços, luz e colisão (faces assadas no tamanho final) escalados juntos; o gatilho de entrada, as câmeras do warp e da entrada acompanham. Para caber: braziers e bandeiras do portal foram para fora do patamar (±5,7 e ±7,2). A escala é uma constante, mudável.

## Debug (D-1204)
`--view=gate_closed|gate_open|gate_close --shot=…`; `--warp=murky_forest` (abre o portal e para); `--warp=murky_forest --warp-enter` (cruza o portal sozinho e roda o loading real; com `--nht-shots=<dir> --nht-summary --nht-quit`); cenário `HUB_GATE_PORTAL` (altura < 4 m, dormente, abre sem mover o jogador, não entra sozinho, fora da boca não dispara, entrada → flood → commit, grupo some, atravessa o anel). Entradas na suíte `--only=D-1273`.

## Não verificado
Aprovação visual do criador; o gesto real de caminhar com teclado até o portal (o cenário teleporta para a boca); orc/cyclops atravessando a abertura com colisão real; o portal aberto visto de longe em tela cheia na resolução dele; retorno da expedição ao hub (fora do escopo).
