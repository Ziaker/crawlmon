# D-1090 — HUD de diálogo C (Paper) + ícone de fúria em estouro, ícones 25% maiores e reticências ao falar

- **Data:** 2026-11-09.
- **Área:** Exploração / UI / diálogo / indicadores.
- **Relacionadas:** D-1085 (prompt), D-1086 (indicadores), D-1087 (3 HUDs), D-1063 (NPCs), D-1075 (prompt/diálogo).
- **Status:** **teste implementado e verificado** no lab isolado; batalha, 2D, HUD/status, cards e regras não mudam; commit local; **sem push**.

## O que o criador disse (literal)

> 1 - o icone do  💢 não tá nem um pouco parecido com o emoji, nao da pra entender oq significa, pode mudar pra um estouro ou espada. Deixe os ícones 25% maiores

> 2 - Opção C, alias, quando o npc está falando, troca o icone encima da cabeça dele por reticiencias animadas

## Decisão

1. **HUD escolhido: C — Paper/RPG.** O card de pergaminho com moldura verde, medalhão dourado, selo “M” e abertura de slide/rotação/selo passa a ser o HUD do diálogo real no lab. A e B continuam no lab de protótipos como referência.
2. **Prompt com o diálogo aberto:** o prompt `[Z] TALK` fica oculto e o card mostra `[Z] CLOSE`; ao fechar, o prompt volta.
3. **NPC falando:** o ícone de estado acima da cabeça (❔/💬) é substituído por **reticências animadas** (`.` → `..` → `...`) enquanto a conversa está aberta; ao fechar, volta ao ícone normal (💬, pois já conversou).
4. **Ícone de fúria:** o antigo 💢 vira um **estouro/explosão** (estrela irregular), tingido de vermelho/laranja; é o ícone de `CHASE`. Se o criador preferir espada depois, é uma troca isolada.
5. **Tamanho:** todos os ícones de estado acima da cabeça ficam **25% maiores** (`pixel_size` de 0,0035 → 0,004375). O escalonamento por distância continua para não cobrir a tela.
6. **Retratos:** Pokémon usam o **ícone estabelecido** (face crop; D-1093), não a arte inteira; NPCs DQT sem retrato usam a inicial do nome no medalhão (fallback), em vez de repetir o Bulbasaur.
7. **Não muda:** batalha, 2D, HUD/status, cards, regras e a câmera (D-1088) / reações de aliados (D-1089) seguem pendentes.

## Ambiguidades

- “Estouro ou espada”: escolhi **estouro** por ler melhor como “inimigo avançando”. Troca para espada é simples.
- As reticências animadas são texto 3D; a velocidade é 3 estados por segundo.
- O `[Z] CLOSE` é visual; o input continua no `lab_interact` (Z/E).

## Teste implementado (2026-11-09)

- **HUD C no diálogo real:** o `murky_forest_3d_lab` usa o card Paper/RPG; o painel antigo fica oculto.
- **Auditoria:** perto do Bulbasaur, prompt `TALK`; ao interagir, `hud=true`, `prompt=false`, `card=BULBASAUR`, `next=[Z] NEXT` (há reações de aliados), `ellipsis=true`, `dots=.` (animando), `icon=talked`, `talked=true`. Ao avançar, as faixas PANCHAM/ORC entram à esquerda (D-1092) e o card continua BULBASAUR; o último passo mostra `[Z] CLOSE`. Ao fechar, `hud=false`, `prompt=true`, `action=TALK`, `ellipsis=false`, `icon=talked`.
- **Reticências:** o `Label3D` acima do NPC cicla `.` → `..` → `...` a 3 estados/s; o ícone de estado fica oculto enquanto fala.
- **Estouro:** `state_anger.png` virou uma explosão/estrela irregular; no `CHASE` a auditoria viu `state=1`, `icon=anger`. O burst também aparece na prova.
- **Tamanho:** `pixel_size` de `0,0035` → `0,004375` (+25%) para todos os ícones de estado.
- **Retratos:** Pokémon usam o ícone estabelecido (face crop; D-1093), não a arte inteira; DQT sem retrato usa a inicial no medalhão (fallback). O Bulbasaur está em B provisório.
- **`[Z] CLOSE`:** movido para a esquerda do selo “M”, para não ficar atrás dele.
- **Provas:** `docs/referencias/exploracao/3d/murky_forest_paper_dialogue.png`, `murky_forest_panchan_reaction.png`, `murky_forest_orc_reaction.png`, `murky_forest_chase_burst.png` e `overworld_icons_states.png`; vídeo C regravado (`dialogue_hud_c_paper.mp4/.gif`) e folha de contato atualizada.

## O que não foi verificado

- 60 fps/mobile, outras resoluções e falas muito longas.
- O HUD C em todos os 10 NPCs (o retrato DQT cai no fallback).
- A câmera D-1088 e as reações D-1089 foram implementadas nesta rodada; a aprovação visual/final delas é separada.
- A cena principal em headless continua com os erros de VFX de outra sessão; teste no lab isolado.

## Estado

Teste implementado e verificado no lab isolado: HUD C no diálogo real, estouro, ícones +25% e reticências animadas. Commit local; **sem push**.
