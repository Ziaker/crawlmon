# D-1092 — Reações de aliados em faixas laterais + câmera três-quartos pela esquerda

- **Data:** 2026-11-09.
- **Área:** Exploração / UI / diálogo / câmera.
- **Relacionadas:** D-1088 (câmera), D-1089 (aliados), D-1090 (HUD C), D-1086 (ellipsis), D-1075 (cards de status).
- **Status:** **teste implementado e verificado** no lab isolado; batalha, 2D, HUD/status, cards e regras não mudam; commit local; **sem push**.

## O que o criador disse (literal)

> eu acho que respostas/reações de aliados deviam ser faixas que surgem do lado esquerdo com seus comentários ao invés de tomarem o lugar da fala do NPC, planeje

> sigo suas recomendações, porém, agora a câmera no zoom, faz um angulo tres quartos mais pra esquerda do que pro meio

## Decisão

1. **O card do NPC permanece:** nome, retrato, fala e `[Z] NEXT/CLOSE` do NPC não são substituídos.
2. **Faixas laterais:** cada reação de aliado vira uma faixa Paper (380×82) que entra da esquerda, acima do card do NPC. A primeira em `y≈288`, a segunda em `y≈380`; ambas ficam visíveis até fechar.
3. **Uma por `[Z]`:** estágio 0 = NPC; `[Z]` mostra Pancham; outro `[Z]` mostra Orc; `[Z]` final fecha. Se o NPC ainda estiver digitando, o primeiro `[Z]` completa a fala.
4. **Visual da faixa:** papel/ribbon com retrato circular, nome em tab escuro e uma borda de identidade (Pancham preto/creme; Orc verde/âmbar); texto em duas linhas com typewriter rápido (0,012 s/caractere); entrada em 0,35 s com pequeno overshoot; saída em 0,25 s.
5. **Cards de status:** ficam ocultos durante o diálogo (exceção visual à D-1075) e voltam ao normal ao fechar.
6. **Ellipsis:** o NPC fica com `...` enquanto fala; ao avançar, volta ao 💬 e o ellipsis vai para o aliado que está falando, se ele estiver em quadro. A faixa é a leitura principal do aliado.
7. **Câmera:** o zoom deixa de ser over-the-shoulder e vira **três-quartos pela esquerda**: orbita o ponto médio jogador↔NPC a **50° para a esquerda**, a **3,9 m**, FOV **45**, alvo 0,35 m abaixo do meio; trava movimento/rotação, colisão e volta em 0,4 s continuam iguais. Se a esquerda estiver bloqueada, usa a direita como fallback.
8. **Não muda:** falas/catálogo da D-1089, câmera normal fora do diálogo, batalha, 2D, HUD/status, cards, regras.

## Teste implementado (2026-11-09)

- **Estágio 0:** `hud=true`, `card=BULBASAUR`, `prompt=false`, `next=[Z] NEXT`, `banner0=false`, `banner1=false`, `npc_ellipsis=true`.
- **Skip:** `typing=false`.
- **Estágio 1:** `card=BULBASAUR`, `banner0=true`, `name0=PANCHAM`, `banner1=false`, `next=[Z] NEXT`, `pancham_ellipsis=true`, `npc_ellipsis=false`.
- **Estágio 2:** `card=BULBASAUR`, `banner0=true`, `banner1=true`, `name1=ORC`, `next=[Z] CLOSE`, `orc_ellipsis=true`.
- **Fechar:** `hud=false`, `prompt=true`, `action=TALK`, `banner0=false`, `banner1=false`, `icon=talked`.
- **Câmera:** prova visual em `murky_forest_paper_dialogue.png` (estágio 0) e nas duas faixas; o jogador e o NPC aparecem acima do card, vistos de três-quartos pela esquerda.
- **Provas:** `murky_forest_paper_dialogue.png`, `murky_forest_panchan_reaction.png` e `murky_forest_orc_reaction.png`.
- **Nota D-1093:** os retratos do card/faixas usam o ícone estabelecido (face crop/portrait), não a arte inteira; o Bulbasaur usa B com 0,03 para a esquerda.

## O que não foi verificado

- Aprovação final das falas dos aliados.
- A câmera três-quartos nos 10 NPCs e em corredores estreitos; se a esquerda estiver bloqueada, o fallback direito muda o lado.
- 60 fps/mobile/outras resoluções; Tab durante o diálogo (os cards ficam ocultos).
- A cena principal completa continua com os erros de VFX de outra sessão.

## Estado

Teste implementado e verificado no lab isolado. Faixas laterais, card do NPC preservado e câmera três-quartos pela esquerda. Commit local; **sem push**.
