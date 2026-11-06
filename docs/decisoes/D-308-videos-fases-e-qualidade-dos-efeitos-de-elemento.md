# D-308 — Efeitos de elemento: sempre vídeo (normal e espelhado), quatro fases e padrão de qualidade

- **Data:** 2026-11-05
- **Área:** VFX / Processo / Motion Composer
- **Origem:** pedido direto do criador, na conversa, depois de ver as receitas de fogo, água, terra e ar (D-920).
- **Estado:** regras registradas; as receitas atuais foram **reprovadas** e serão refeitas. **Aguardando o próximo vídeo.**
- **Numeração:** D-308 evita os números já usados no GitHub (até D-307) e nas sessões locais (até D-282).

## Declaração literal do criador

> eu preciso que sempre coloque os videos deles funcionando, no mesmo video mostrar angulos diferentes que serão visíveis no jogo, ou seja, o normal e o espelhado.

> os efeitos precisam levar em conta que tem Wind up, Release, Trajeto E impacto. eu mais vejo trajeto e impacto, e o impacto deles está PÉSSIMO

> todos efeitos estão PÉSSIMOS, parecem HTML genérico, não algo que seria possível de ser feito no godot, se isso é uma incapacidade do motion composer então MELHORE o motion composer.

## Regras aprovadas

1. **Sempre entregar vídeo** do efeito funcionando (não só folhas de contato nem imagens). **Um único vídeo** mostra os dois pontos de vista que existem no jogo: o **normal** (o jogador ataca, alvo longe) e o **espelhado** (o inimigo ataca, alvo perto da câmera), na **cena de batalha real**, com a câmera do jogo.
2. Todo efeito tem **quatro fases**: **Wind-up**, **Release**, **Trajeto** e **Impacto**. O criador olha sobretudo **Trajeto e Impacto**; o **Impacto precisa ser forte, legível e bonito**.
3. **Padrão de qualidade:** nada que pareça "HTML genérico" (formas planas, fitas finas, pontinhos). Os efeitos devem usar o que o Godot e o projeto oferecem de verdade: flipbooks, malhas 3D, shaders com textura, partículas com sprite, brilho, tremor e impacto, no estilo do jogo.
4. **Motion Composer:** se o Motion Composer não der conta, **ele deve ser melhorado**. Os efeitos devem ser construídos **sobre** ele, não ao lado dele.

5. **Transição entre fases (criador, 2026-11-05):** o VFX **não some** ao fim do wind-up: a carga **fica** (segura até o disparo) e **vira** o tiro, de forma contínua e suave. Vale para todos os efeitos de elemento.

> não existe isso do vfx do move sumir após o fim do wind-up, muito pelo contrário, a transição deve ocorrerr corretamente e suavemente

6. **Tamanho fixo (criador, 2026-11-05):** o tamanho do VFX é **fixo, o mesmo nas duas posições** (normal e espelhada), em unidades do mundo. **Não** depende da altura do alvo, do atacante, nem da distância à câmera.
7. **Intensidade do contato:** o impacto deste Move (que **não é poderoso**) estava exagerado; **por ora reduzir** o tamanho dos efeitos visuais no contato. **Ainda é preciso definir o que é um Move poderoso e o que não é**, para então definir a intensidade do VFX (pendente; nada inventado agora).
8. **Release:** o release da bola de fogo estava "muito básico e genérico"; deve ser refeito (o criador não disse como).

> o tamanho dos efeitos está completamente incoerente, principalmente quando se espelha, pq isso? é pra seguirem um tamanho fixo para ambas posições, o efeito de impacto na posição normal está extremamente exagerado pra um move que não é pra ser poderoso

> ainda devemos definir o que é um move poderoso e oque não é pra também definir a intensidade do VFX, por ora apenas reduza o tamanho dos efeitos visuais no contato

> eu ainda não gosto do release dessa bola de fogo, está mt básico e genérico

**Causa do tamanho incoerente (minha):** a unidade do efeito saía da **altura do corpo** (Gible mede 3,17 m, Abra 2,26 m) e de um fator de **distância da câmera**, então o mesmo Move mudava de tamanho conforme quem era o alvo e de que lado ficava.

9. **Impacto (criador, 2026-11-05, com desenho sobre o vídeo):** um **cone de fogo e brasas** que sai do ponto de contato, **em ambos os lados** (normal e espelhado). No desenho, o cone abre **a partir do alvo, para longe do atacante** (no sentido do tiro). Substitui o impacto anterior (anéis, coluna de fogo, domo).
10. **Alvo único:** o Flame Stream é de **alvo único**. A "outra bola de fogo" que aparecia no disparo **estava errada** (eram as chamas de recuo e o cone do release); foi removida.
11. **Release (criador, 2026-11-05):** **vórtices** que **seguem a bola de fogo e descem gradualmente durante os primeiros 0,2 s** e, depois desses 0,2 s, **somem em brasa e fumaça ao longo de 0,5 s**. "Descem" = os vórtices deslizam da cabeça da bola para trás, ao longo do corpo (**confirmado pelo criador em 2026-11-05**: "Sim, é isso").

> não gostei do impacto, quero algo mais assim, um cone de fogo e brasa quando atinge, em ambos lados

> inclusive no disparo, sai uma OUTRA bola de fogo, essa outra bola de fogo é pra significar que o move é multi-alvo ou é um move de alvo único? se for de alvo unico essa outra bola de fogo está errada

> eu quero que coloque uns vortexes que seguem e deseguem a bola de fogo gradualmente durante os primeiros .2 segundos e somem em brasa e fumaça após estes .2 segundos por .5 segundos

## Ambiguidades em aberto

- Como deve ser o release da bola de fogo (a proposta atual: bola que se estica em cometa, hélice de fagulhas do Motion Composer, cone de choque e sopro para trás; a confirmar).

- Quais Moves/elementos entram primeiro e se algum deles deve ser baseado em um Move existente.
- O que exatamente o criador espera visualmente de cada elemento (referências, protótipos HTML) além do estilo do jogo.

## Estado no código

**Motion Composer como gerador de VFX (2026-11-05, ordem do criador: "quero que essa merda funcione do jeito que ela foi feita"):** o Flame Stream agora é um `MotionEffect` (`scripts/motion_composer/representations/`): cada fase (windup, release+trajeto, impacto) é um conjunto de **composições** do Motion Composer (M01, M03, M06, M07, M09, M16, M17, M18) pintadas por **representações** (flames, streaks, embers, smoke, orb, glow, scorch) sobre um pintor com os shaders do jogo; `MotionPresets.fire_effect` guarda os dados. O M16 (explosão direcional) exige **duas camadas** (OFFSET para mover, MULTIPLY_ATTRIBUTE para dissipar); só com OFFSET a opacidade nunca muda. `ElementMoveVfx` só entrega as posições reais e os relógios das fases.


**Fogo (Flame Stream), primeira versão no jogo real (2026-11-05):** `scripts/combat/fx/element_move_vfx.gd` (4 fases, carga que vira o tiro) sobre o Motion Composer (`scripts/motion_composer/runtime/`: `MotionStrand` e `MotionPresets`), listado só na sala de VFX (`Skill.element_skills()`); vídeo normal + espelhado por `tests/fx_lab/record_move_video.py`. **Aguardando aprovação do criador**; água, terra e ar ainda não foram refeitos.

(Anterior:)

As receitas V1 (`scripts/vfx/elements/`) **não atendem** estas regras (sem fases, sem Motion Composer, impacto fraco) e serão substituídas. Nada ligado a Move.
