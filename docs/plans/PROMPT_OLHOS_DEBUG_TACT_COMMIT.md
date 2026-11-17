# Prompt: debug de olhos em combate, auditoria dos modelos DQT em C:\Games\Tact e commit

Projeto Crawlmon (Godot 4.7, pasta de trabalho do repo). Leia `AGENTS.md`, `CLAUDE.md`, `docs/TELEMETRIA.md` (seção "Olhos") e as decisões D-340, D-1268, D-1271, D-1272, D-235 e D-1204 (use `node ~/.claude/tools/ds-decisions.mjs`; cite os IDs). Outras sessões editam o mesmo working tree: só Edit pontual, sem `git stash/checkout/reset`, e commite apenas os arquivos listados no item 3.

## Estado atual (já feito e verificado)
- `scripts/common/eye_shine.gd` pinta o brilho em olhos de textura chapada (Pikachu e Eevee); `scripts/common/eye_blink.gd` faz o piscar por shader (pálpebra desenhada na superfície do olho, cor de pele medida e em cache por modelo) em todo modelo com superfície `*_eye`.
- `BattleFx._sync_blind_eyes` fecha as pálpebras enquanto o personagem está BLIND (D-1271); `BattleFx._hit_react` fecha por 0,5 s a cada reação de hit (D-1272). Evento de telemetria `eyes` `{actor, closed, blind, hit}`. Cenários `st_blind_olhos` e `dano_olhos` na sala de VFX.
- Modelos com `EyeBlink` hoje: Pikachu, Eevee, Charmander, Bulbasaur, Gible, Squirtle, Pancham. Os DQT (Slime, Orc, Cyclops, Dracky, Fungi, Healslime, Platypunk, Sabrecub) NÃO têm (D-340: o Slime usa a malha `Eye_Model_a` como adesivo de olho fechado).
- Os valores de ritmo do piscar, 0,5 s, tempos de fechar/abrir e posição dos brilhos são escolhas técnicas minhas, pendentes de aprovação do criador. Não os apresente como decididos.

## Tarefa 1 — Verificar em COMBATE, criando um debug dedicado a piscadas e fechamento de olhos
Hoje só foi provado por capturas isoladas e pela telemetria `eyes`. Falta ver em batalha de verdade. Regras: D-1204 (nenhum teste passa de 1 minuto; sem cenário/controle, CRIE), sempre nas duas vistas (normal e `--mirror`, D-235), dados antes de imagem.
1. Criar na sala de VFX (`scripts/debug/vfx_room.gd`, `vfx_room_scenarios.gd`) um controle de debug para olhos: flags de linha de comando e botões na grade de status (ao estilo "ATB +1") que permitam, sem esperar o relógio: forçar piscada agora, forçar olhos fechados/abertos, ligar/desligar BLIND, disparar uma reação de hit, e escolher o personagem (hoje a sala só tem Abra, Pancham e DQT; o `--units=` citado na documentação não está implementado: implemente ou adicione Pikachu, Eevee, Charmander, Bulbasaur, Gible e Squirtle como atacante/alvo com `Skill.all_catalog_skills()`).
2. Telemetria: acrescentar ao `BattleTrace` o que faltar (por exemplo evento da piscada aleatória e fração de fechamento `_hold_k` por quadro, com asserção de que o BLIND mantém `closed=true` e que o hit reabre em ~0,5 s) e documentar o campo em `docs/TELEMETRIA.md` ANTES de usar.
3. Capturar quadros de batalha em tamanho real com a câmera de jogo e com a teleobjetiva (`--cam=macro`), nas duas vistas, com olho aberto, piscando, cego e levando hit. Ler as imagens antes de afirmar. O olho tem poucos pixels na câmera de jogo: diga o que é legível e o que não é.
4. Fechar o que ficou aberto: Murky Forest (mesmo `_make_model`) e uma batalha completa com Pikachu/Eevee; rodar `python tests/battle/run_agent_combat_tests.py` e separar falhas: Javelin Throw D-235 (falha igual sem as mudanças de olhos), Employ D-1239 espelhado (intermitente), e os testes do hub que quebraram quando `hub_3d_lab.gd` foi sobrescrito por outra sessão (rodar de novo).
Pronto quando: um comando <10 s por cenário mostra, com dado e captura, piscar/cego/hit em combate nas duas vistas, e a lista de verificado/não verificado está honesta.

## Tarefa 2 — Auditar C:\Games\Tact: os personagens têm ossos ou texturas de olhos fechados?
Objetivo: decidir se os monstros DQT (e qualquer personagem futuro vindo do extrator) podem piscar de verdade com dado do jogo original, em vez de inventar. Fonte: o extrator do criador em `C:\Games\Tact` (`scripts/tactlib.py`, `raw/gc/AssetBundles/Android/monster/00/<id>_<nome>.assetbundle`, `analysis`, `inventarios_jogo`, `fbx_inventario.csv`, `RELATORIO_FINAL.md`). Este é um diretório do criador: SÓ LEIA (não edite nem apague nada lá sem pedir).
1. Ler `PIPELINE.md`/`RELATORIO_FINAL.md` e achar como listar malhas, texturas, ossos e clipes por monstro.
2. Para cada monstro já usado no jogo (Slime, Orc, Cyclops, Dracky, Fungi, Healslime, Platypunk, Sabrecub) e, como amostra, mais alguns do catálogo, listar: (a) malhas de olho (ex.: `Eye_Model_a`, adesivo de olho fechado do D-340) e suas escalas animadas (`<X>_scale`); (b) texturas de olho (aberto/fechado/meio fechado, atlas de expressão, material `*_eye`); (c) ossos de pálpebra/olho/sobrancelha; (d) clipes que fecham os olhos (Sleep, Die, Damage) e a pose.
3. Entregar uma tabela por monstro (tem pálpebra? tem malha ou textura de olho fechado? clipe que fecha?) e uma recomendação de como cada um pisca/fecha por BLIND e hit (regra do jogo, textura/malha trocada, ou nada), reaproveitando o D-340 e o `DqtEyes`. Recomendar, não decidir: o criador aprova (AGENTS.md §2).
4. Se faltar dado no GLB exportado mas existir no bundle, apontar a correção do extrator, sem aplicá-la.
Pronto quando: tabela com fonte (arquivo/caminho) por afirmação, o que não foi possível verificar dito, e nenhuma alteração em `C:\Games\Tact`.

## Tarefa 3 — Commitar o restante
Branch: confira `git branch --show-current` e `git status` antes e diga o que será enviado. Commite SÓ o que é desta frente (outras sessões têm mudanças no tree). Pendentes conhecidos:
- `scripts/common/eye_blink.gd`, `scripts/common/eye_shine.gd` (cache por modelo, comentários)
- `tests/overworld/diag_eye_blink_cost.gd` (novo), `tests/overworld/diag_blink_solver.gd`
- `docs/TELEMETRIA.md` (seção "Olhos"), `docs/REGRAS_DO_JOGO.md` (entrada D-1268/1271/1272), `docs/decisoes/D-1268-olhos-pretos-pikachu-eevee-brilho-no-olho.md`
- tudo o que as Tarefas 1 e 2 criarem (cenários, telemetria, docs, decisões novas D-xxx com a frase literal do criador antes do código)
Não commite `assets/modelos/`, arquivos de outras sessões (por exemplo `diag_floor_map.gd`, `diag_altar_followers.gd.uid`, `README.md` com a linha D-1274, `hub_3d_lab.gd`, `third_person_3d_lab.gd` com gravidade/PerfProbe) nem faça push sem autorização. Mensagem em português no estilo do repo (`feat(olhos): ...`), terminando com a linha de coautoria. Diga no final exatamente o que entrou no commit.

## Regras gerais
- Fazer só o que está acima; nada de mudar regra de jogo, tempo ou visual que o criador não pediu. Dúvida = perguntar (uma decisão por pergunta, com recomendação rotulada).
- Antes de dizer "pronto": releia as decisões aplicáveis e diga o que NÃO foi verificado.
- Entregar capturas com `SendUserFile` e relatar à sessão que pediu.
