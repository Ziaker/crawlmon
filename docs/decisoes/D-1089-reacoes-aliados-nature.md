<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1089 — Reações de aliados por Nature (flavor)

- **Data:** 2026-11-09.
- **Área:** Exploração / diálogo / aliados / Natures.
- **Relacionadas:** D-393 (8 Natures), D-271 (Natures adiadas), D-1063 (NPCs), D-1087 (HUD de diálogo).
- **Status:** **teste implementado e verificado** no lab isolado (HUD C); falas são uma primeira versão, ajustáveis; batalha, 2D, regras e atributos não mudam; commit local; **sem push**.

## O que o criador disse (literal)

> 5 - Aliados que conversam e reagem a conversa baseada na nature deles

> de resto vamos com suas recomendações

## Decisão

1. **Quem reage:** Pancham (Nature **Brave**) e Orc com tom **agressivo/bravo** do perfil, **sem criar uma Nature canônica para o Orc**.
2. **Gible** continua só card demo do HUD; não reage e não vira seguidor nesta rodada.
3. **Formato (atualizado por D-1092):** cada reação vira uma **faixa lateral** de papel, entrando pela esquerda, com retrato/nome do aliado; o **card do NPC permanece** com a fala do NPC. Um aliado por vez.
4. **Quando:** depois da fala do NPC, com `[Z]` para avançar; a faixa não interrompe nem substitui o NPC. As duas faixas ficam visíveis até fechar.
5. **Efeito:** só sabor, sem afinidade, missão, atributo ou consequência de gameplay.
6. **Falas:** 2–3 linhas por Nature (16–24 no total), escritas por mim e mostradas para aprovação antes de integrar; o tom segue D-393 (Brave agressivo, Timid cauteloso, Calm ponderado etc.).
7. **Não muda:** batalha, 2D, HUD/status, cards, regras e atributos.

## Ambiguidades

- Se o Orc deve receber uma Nature canônica no futuro, isso é uma decisão separada.
- Reações de Gible exigiriam modelo/seguidor e ficam para depois.
- Não há sistema de missão/afinidade; as falas não alteram nada.

## Teste implementado (2026-11-09)

- **Catálogo:** `scripts/dungeon/ally_dialogue.gd` com 2 falas por Nature (Hardy, Docile, Brave, Timid, Modest, Calm, Jolly, Adamant) + 2 do tom `orc`.
- **Escolha:** Pancham usa `brave`; Orc usa `orc`; a fala é escolhida pelo `pool_idx` do NPC. Gible não está no mundo e não reage.
- **Sequência:** estágio 0 = NPC (`[Z] NEXT`); estágio 1 = faixa do Pancham (Brave, `[Z] NEXT`); estágio 2 = faixa do Orc (`[Z] CLOSE`). Se o jogador aperta Z enquanto o typewriter roda, a fala do NPC completa primeiro; o próximo Z avança. As duas faixas ficam visíveis.
- **Card:** o card permanece **BULBASAUR** com a fala do NPC; as faixas mostram PANCHAM/ORC com retrato/nome. O NPC volta ao ícone 💬 e o ellipsis vai para o aliado que está falando. Pancham usa o **face crop estabelecido** (D-1093); Orc usa o retrato do Orc.
- **Auditoria:** estágio 0 `card=BULBASAUR next=[Z] NEXT banner0=false banner1=false npc_ellipsis=true`; skip `typing=false`; Pancham `card=BULBASAUR banner0=true name0=PANCHAM next=[Z] NEXT pancham_ellipsis=true`; Orc `card=BULBASAUR banner0=true banner1=true name1=ORC next=[Z] CLOSE orc_ellipsis=true`; fechar `hud=false prompt=TALK banner0=false banner1=false`.
- **Provas:** `murky_forest_paper_dialogue.png`, `murky_forest_panchan_reaction.png` e `murky_forest_orc_reaction.png` (as faixas aparecem ao lado do card do NPC).
- **Falas (primeira versão):** Brave — “Então que venham. Se atacarem, devolvemos em dobro!” / “Tesouro raro? Eu abro caminho.”; Orc — “Eu esmago qualquer coisa que aparecer na frente.” / “Se querem lutar, eu dou a eles o que pediram.” As demais Natures estão no catálogo.

## O que não foi verificado

- Aprovação final das falas; são uma primeira versão.
- Um aliado de cada uma das outras 7 Natures (o catálogo está pronto, mas só Pancham/Orc existem no mundo).
- 60 fps/mobile e outras resoluções.
- A cena principal em headless continua bloqueada pelos erros de VFX de outra sessão; teste no lab isolado.

## Estado

Teste implementado e verificado no lab isolado. Reações de Pancham (Brave) e Orc (tom bravo) em sequência, só sabor. Commit local; **sem push**.
