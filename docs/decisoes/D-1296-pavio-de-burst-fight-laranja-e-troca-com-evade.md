# D-1296 — Pavio de burst: bloco Fight laranja, pavio aceso e Fight toma o lugar do Evade

**Data:** 2026-11-17  
**Área:** combate, menu de comando, QoL  
**Estado:** **implementada no jogo (2026-11-17); visual aprovado pelo criador: "Ficou bom".** Código: `battle_scene.gd` (`_start_fuse`/`_end_fuse`), `fan_menu.gd`, `burst_fuse_fx.gd`; cenário `--fuse=cut|expire|swap|action|ko|shot`; evento `fuse` em `docs/TELEMETRIA.md`.  
**Relacionadas:** D-1280 (Evade/Guard no leque), `_on_manual_evaded` (câmera lenta de 2,0 s após Evade perfeito manual).

## Frases do criador

> "um QoL, aparecer um pavio de bomba que pega fogo no topo do bloco de fight (é pra ter o mesmo intervalo de tempo da camera lenta depois do dodge não-automatico) e também trocar a cor do fight pra laranja quando o jogador recebe um burst. além disso, ao receber um burst por dodge, o botão de fight tomar o lugar do botão de evade apenas durante esse tempo de pavio pra um clique imediato no fight sem ter que mover pra cima duas vezes."

> "o Evade troca de lugar com o Fight" (resposta à pergunta do que acontece com o Evade enquanto o Fight toma o lugar dele)

> "O PAVIO É PRA ESTAR NA PARTE HORIZONTAL RETA DE TRÁS PRA FRENTE DO TOPO DO BLOCO FIGHT" — confirmado "está certo" para a queima da esquerda (trás) para a direita (frente).

> "eu quero chamas 2D onduladas como ondas sabe" / "chamas onduladas com branco laranja amarelo e vermelho, ANIMADAS" / "o pavil ainda está péssimo principalmente no efeito visual, não precisa ser 2D que nem o bloco" / "eu só reduziria os efeitos visuais do fogo no pavil pra serem menos redondos e mais cortados e separados como chamas e fumaça. O clique devia ter feedback visual, algo como uma pequena explosão" / "perfeito" (sobre o 3D do pavio) / "a animação das chamas está ótima dentro do bloco mas devia ser mais rápida em sua dissipacao continua, alem de ter reducoes visiveis de opacidade" / "tire esse "1ATB" é irrelevante" (no protótipo e no jogo).

## Decisão

- Ao receber um **burst por dodge**, durante o mesmo tempo da câmera lenta do Evade perfeito manual (hoje 2,0 s): o bloco **Fight** vira **laranja**, um **pavio de bomba** acende no topo dele (reto e horizontal, queimando de trás para a frente) com **chamas 2D onduladas** (branco, amarelo, laranja, vermelho) dentro do bloco, e o **Fight troca de lugar com o Evade** para o clique imediato.
- Clicar no Fight durante o pavio corta o pavio com uma **pequena explosão** visual.
- O custo "1 ATB" some do bloco Fight no jogo (já feito em `battle_scene.gd`); Fight continua mostrando FREE/queue/need ATB/stunned/GUARD quando se aplicam.

## Respostas (2026-11-17, por pergunta)

1. Laranja do Fight: **`ff8a2b`** ("ff8a2b (o do protótipo)").
2. Ao acender o pavio o cursor **pula sozinho para o Fight** ("Pula para o Fight").
3. Vale **só para burst por Evade manual perfeito** ("Só burst por Evade manual perfeito"), o mesmo gatilho da câmera lenta de 2,0 s.
4. Pavio acaba sem clique: **Fight e Evade voltam ao lugar** ("Fight e Evade voltam ao lugar").

6. Menu aberto em Fight/Items/Tactics ao acender: **"Só aparece no menu principal (Recomendado)"** (o pavio só aparece no menu principal).
7. "N ATB" some só do Fight: **"Só do Fight (Recomendado)"**; Items, Evade, Guard e Employ continuam mostrando o custo.
5. Pavio no jogo: **3D em SubViewport** ("B: 3D SubViewport"), fiel ao protótipo aprovado (2026-11-17).

8. Visual final no jogo (laranja, chamas, pavio 3D, explosão ao clique): **"Ficou bom"**.

## Pendente (não decidido; não entra em código até o criador dizer sim)


- Visual final do pavio, chamas e explosão (protótipo em `prototypes/burst_fuse/index.html`, Quarks + Three): o criador disse "perfeito" ao pavio 3D e pediu os ajustes de facetas e explosão; aguarda o julgamento da última versão.
