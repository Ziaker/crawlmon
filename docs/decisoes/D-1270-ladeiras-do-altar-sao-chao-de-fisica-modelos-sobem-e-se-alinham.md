> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** Nenhum teste >1 min; `--view=altar_ramps` (hub) roda em ~5 s por líder. Ver `docs/TELEMETRIA.md`.

# D-1270 — Ladeiras do altar tratadas como chão de física: todos sobem, se alinham e pisam nelas

Estado: **implementada, em verificação pelo criador.** Relacionadas: D-1266 (altar), D-1264 (pés no chão), D-235.

## Frase literal do criador
"essas ladeiras não estão sendo tratadas como modelos e chão com física"

## O que existe (medido)
- As únicas ladeiras do hub e da Murky Forest são os lados dos dois degraus do altar (`HubAltar`, ~29°). Têm colisão trimesh real (`StaticBody3D`, camada 1): o líder sobe e desce (`floor_max_angle` 45°, `floor_snap_length` 0,3).
- O resto do hub/floresta é plano (caixas); passarelas/portal/guilda não têm rampa.

## Defeitos achados com dados (`--view=altar_ramps`)
1. **NPCs atravessavam o altar**: patrulham por waypoints sem corpo físico e com y fixo; afundavam até 0,32 m (todo o altar).
2. **Modelos não acompanhavam a inclinação**: líder/seguidores ficavam em pé reto numa ladeira de 29° e a cápsula arredondada deixava os pés até 7–14 cm acima do degrau (maiores: Orc/Cyclops).

## Decisão (técnica; nenhuma regra, velocidade ou número por espécie)
- `_npc_ride_floor` (hub): NPC mede o chão por raio a cada passo; y = chão; modelo inclina pela normal.
- `_tilt_model_to_floor` / `_update_floor_tilt` (`third_person_3d_lab.gd`): líder e seguidores inclinam o modelo pela normal do chão (suavizado) e descem o modelo até o chão medido sob os pés. Roda depois do gait (que reescreve `model.position.y`).

## Dados (`--view=altar_ramps`, janela, 6 líderes)
Folga pé−chão: Abra −0,038..0,031; Pancham −0,019..0,046; Gible −0,029..0,037; Slime −0,029..0,039; Orc −0,016..0,071; Cyclops −0,022..0,065 (antes: até +0,14). NPCs: −0,010..0,000 (antes −0,32). Todos chegam ao fim da rota; tremor de câmera 0,04 m/quadro (= subida natural, igual a antes). Captura: `docs/capturas_warp/ramps_gible_D1270.png`.

## Floresta e seguidores (janela, `tests/overworld/diag_altar_followers.gd --scene=hub|forest`)
Folga pé−chão do líder + seguidores atravessando o altar: hub leader −0,027..0,031, Pancham −0,010..0,035; floresta leader −0,027..0,041, Pancham −0,013..0,043, Orc −0,008..0,087 (quina do degrau). Todos chegam ao fim. Captura da floresta lida: Abra na ladeira, em pé sobre a pedra.

## Pendente / não verificado
- O criador não disse qual ladeira era: assumida a do altar (única ladeira existente). Se for outra, indicar.
- Lado espelhado (D-235) fora do cenário de rampa; custo por quadro.
- Piso mínimo por vértice mais baixo foi tentado (3 variantes) e piorou a folga: revertido; só ficaram medidas (`vgap`, cache do rig).
