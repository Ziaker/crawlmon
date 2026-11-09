# Importação de modelos DQT — mapa de clipes de animação

Referência para importar novos modelos DQT (Dragon Quest Tact) no jogo. Atualizado em 2026-11-08 (D-1004).

## Numeração dos clipes

Todos os modelos DQT medidos (Orc, Cyclops, Slime) vêm com os **mesmos 12 clipes**, com o sufixo numérico depois do prefixo do modelo (`cm_00_<id>_<NN>`):

| Clipe | O que é | Uso no jogo (alias do BattleFx) |
|---|---|---|
| 00 | idle | `idle`, `battle_idle` |
| 01 | corrida/andar | `walk`, `run` |
| 02 | vitória | `victory` |
| 03 | pose baixa parada | sem uso |
| 04 | pose baixa parada (igual ao 03) | sem uso |
| 05 | pose baixa parada, curta | sem uso |
| 10 | dano | `damage` |
| 11 | **ataque físico** | `attack` (corpo a corpo) |
| 12 | **ataque mágico / à distância** | `attack_special` (projétil, status, longo alcance) |
| 30 | queda | `down` |
| 32 | pose de prontidão | base do idle; wind-up e Guard de alguns modelos |
| 50 | pulo longo com a arma | sem uso |

Padrão confirmado nos três modelos: **11 = ataque físico** e **12 = ataque mágico**. Num modelo novo, esses dois já podem ser mapeados sem medir.

## Escolhas por modelo (D-1004)

| Modelo | Wind-up | Guard | Projétil / status / longo alcance |
|---|---|---|---|
| Orc | 32 (inteiro, em loop) | 12 | 12 |
| Cyclops | 32 (inteiro, em loop) | 32 | 12 |
| Slime | pose do 32 (padrão antigo) | igual ao wind-up | 12 |

## Como configurar

Em `scripts/combat/dqt_model_profiles.gd`, no perfil do modelo:
- `clip_prefix`: prefixo dos clipes (ex.: `cm_00_0020_`).
- `idle_source` / `idle_pose_time`: clipe e instante da pose do idle.
- `charge_clip`: clipe do wind-up, tocado inteiro em loop (opcional).
- `guard_clip`: clipe do Guard (opcional; sem ele o Guard usa o wind-up).

Para ver os clipes de um modelo novo, renderizar um vídeo por clipe (como em `test_captures/clipes_dqt/`) e escolher.
