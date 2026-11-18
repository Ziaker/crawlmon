<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1300 — "Os idles novos do Orc e do Cyclops não estão presentes" (em combate)

- **Data:** 2026-11-17
- **Área:** Combate / animação DQT
- **Estado:** **investigada com dados; causa NÃO encontrada; nada alterado. Aguarda o criador dizer qual idle é o "novo" (e ver a captura).**
- **Relacionadas:** D-1084 (idle_full toca uma vez e segura), D-1004, D-341.

## O que o criador disse (literal)

> "Os idles novos do Orc e do cyclops não estão presentes"

## Dados medidos (headless, só dados; nenhuma imagem avaliada)

`CharacterModelLoader.create_character_model` (o mesmo caminho do combate, `battle_scene.gd:595`) lê o perfil de `content/characters/<id>/model_profile.tres` (não o legado `DqtModelProfiles`):

| | clip de origem | modo | `idle`/`battle_idle` no combate |
|---|---|---|---|
| Orc | `cm_00_0020_00` (idle_speed 0,5) | `idle_full=false` | 3,33 s, em loop; `battle_idle` é o que toca |
| Cyclops | `cm_00_0065_32` (pose segurada em 1,95 s) | `idle_full=true` | 2,0 s, `battle_idle` **sem loop** (segura a pose final) |

Os GLBs têm só os clipes originais (`..._00`, `..._32` etc., últimas alterações em 06/11); não há arquivo de idle novo. Os perfis do `.tres` foram tocados por último em 17/11 pela sessão dos olhos (D-1295), não por idle.

D-1226 já registra que `idle_full` dos DQT (D-1084) toca uma vez e segura o último quadro; isso vale hoje para o Cyclops em combate.

## Pesquisa ampliada (docs e arquivos)

Revisei `docs/IMPORTACAO_MODELOS_DQT.md`, D-1084, D-1264, `docs/REGRAS_DO_JOGO.md`, o histórico do git (`-S idle_speed`, `--grep idle`), `content/characters/dqt_*/model_profile.tres`, os GLBs (clipes `00`..`50`), `character_model_loader.gd`, os labs (`third_person_3d_lab.gd`, `pre_game_stage_3d.gd`) e as sessões irmãs. O único "idle novo" com histórico é o do Orc: `idle_source 00`, `idle_speed 0,5`, `idle_full false`, entrado no commit de 16/11 (`8b0a90b9`), e está nos dados do combate. Para o Cyclops, o idle é o de 10/11 (clipe `32`, pose segurada, `idle_full`). Nenhum outro arquivo ou clipe de idle existe. Ainda não vi captura do combate com os dois.

## Ambiguidade (perguntar)

Não consegui identificar qual idle é o "novo" (não há arquivo/commit de idle novo para Orc/Cyclops). Possibilidades: o idle de outra tela (hub/lab, D-1084) que o combate não usa; o Cyclops estar parado por `idle_full` sem loop; ou um clipe que o criador espera e não está nos GLBs. **Pergunta:** qual clipe/aparência é o idle novo e onde você o viu?
