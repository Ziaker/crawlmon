<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1257 — Employ: regras do minigame rítmico (entrada, janelas, MISS, interrupção)

**Data:** 2026-11-16  
**Área:** combate, recrutamento  
**Estado:** **respondida; nada implementado.**  
**Relacionadas:** D-1229, D-1230, D-1239, D-1240.

## Respostas do criador (2026-11-16)

Cada pergunta foi feita separadamente, com a recomendação da IA ao lado; as respostas são as opções escolhidas:

- Entrada: "Uma tecla só (Recomendado)" (a tecla de confirmar acerta qualquer nota, teclado e controle).
- Janelas: "PERFECT ±60 ms, GOOD ±130 ms (Recomendado)".
- MISS: "Só não dá bônus (Recomendado)" (soma 0 pp, sem penalidade na chance).
- Interromper: "Não, vai até o fim (Recomendado)" (os 5 ATB já foram pagos ao confirmar o alvo; a sequência sempre termina e rola a chance).

## Requisitos de visual (2026-11-16)

À proposta de um protótipo HTML com 3 variantes de andamento, pista e linha de acerto, o criador respondeu:

> "Protótipo mas não pode ser 2D, precisa ter feedback visual épico a cada acerto e deve seguir a estética visual do jogo"

## Escolha da pista (2026-11-16)

Depois de jogar as variantes A (anéis no chão), B (orbes em arco) e C (pentagrama), o criador disse:

> "o que eu almejo é semelhante a opção B mas sem projéteis, não gostei do restante"

À pergunta "Sem projéteis na B, como a nota deve avisar a hora de apertar?" ele respondeu: "Anel que fecha no alvo (Recomendado)" (o alvo fica no peito do inimigo; um anel grande, na cor do aliado da vez, fecha sobre ele e a hora é quando encosta; nada viaja entre aliado e inimigo). Protótipo: `prototypes/employ_minigame/index.html` (só essa variante).

## Alvos: locais e design (2026-11-16)

Depois de jogar a pista com anel, o criador disse:

> "eu queria que os acertos fizessem os alvos pularem, eu mudaria o design dos alvos e também os locais, não serem todos no meio"

À pergunta "Onde ficam os alvos, já que não devem ficar todos no meio?" ele respondeu: "Espalhados em volta do inimigo". À pergunta sobre o que significa "pularem" ele respondeu:

> "use do protótipo pra me recomendar ideias, eu to pensando em um visual mais toon, comic e outros"

Ficam **pendentes** (o protótipo mostra opções, nada decidido): o design dos alvos (Toon, Comic ou Holo, ideias da IA), o tipo de pulo (A: salta no lugar e estoura; B: salta até o próximo alvo; C: estoura e os outros pulam junto) e os pontos exatos dos alvos em volta do inimigo (os do protótipo são provisórios).

## Estilo rejeitado e regra de estética (2026-11-16)

Depois de jogar os estilos Toon, Comic e Holo, o criador disse:

> "todos péssimos, siga apenas a estética visual da hud e do jogo"

Os três estilos estão descartados. O protótipo passou a usar só a estética da HUD e do jogo: cartões creme inclinados com contorno INK, losangos coral, moldura lime, blocos de ATB em aqua, estrelas douradas, fonte Kanit e a arena azul-petróleo (paleta de `battle_hud_draw.gd`). A escolha do pulo (A, B ou C) e os pontos exatos dos alvos continuam pendentes.

## Correção: sem cartões, só textos e estrelas (2026-11-16)

O criador apontou que o cartão creme com bloco de cor, número, losango e blocos de ATB foi invenção da IA (copiado do cartão do personagem), e que a estética da HUD são elementos planos sem fundo, "não os cartões do personagem". Depois disse:

> "só deixe textos e estrelas sem fundo"

O protótipo agora usa só textos (Kanit itálico com contorno INK) e estrelas douradas sem fundo. O alvo é uma estrela com o número da nota. O anel tracejado creme que fecha (da escolha "Anel que fecha no alvo") foi mantido, e é o único elemento que não é texto nem estrela: **pendente** se ele fica. Removidos: cartões, losangos, blocos de ATB, molduras, ondas e anéis de chão.

## Visual: provisório no jogo (2026-11-16)

Depois de rejeitar os visuais dos protótipos, o criador disse "tá impossível gostar de nenhuma destas" e, perguntado como passar o visual, respondeu "eu não sei". À pergunta "Implemento a mecânica do minigame no jogo com um alvo provisório, e o visual a gente refina vendo no jogo?" ele respondeu: "Sim, provisório (Recomendado)" (retículo que já existe no jogo como alvo, anel e textos simples; regras da D-1257 completas; o visual final fica pendente).

## Pendências (não implementar sem o sim do criador)

- Andamento e posição das notas (BPM, pista, onde a nota cruza a linha de acerto), tempo antes da primeira nota.
- Visual e som do minigame; qual membro da equipe ataca em cada nota; HUD durante a pausa.
- Se a tecla de confirmar depende do mapeamento atual (teclado e controle).
- Diálogo do alvo por Nature e cutscene de sucesso/fracasso.
