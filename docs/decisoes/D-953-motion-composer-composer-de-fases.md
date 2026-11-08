# D-953 — Motion Composer 2.0: Composer de Fases (direção aprovada)

- **Data:** 2026-11-06.
- **Área:** VFX / Motion Composer / animação / processo.
- **Origem:** resposta do criador à proposta do Composer de Fases, na conversa.
- **Estado:** direção aprovada; **V1, prelude e integração de debug descartados por completo em 2026-11-06** ("descarte-o por completo, está péssimo eu não gostei de nenhum dos resultados apresentados e acho que o problema é o motion em si"). O criador apontou o **motion do Motion Composer** como a causa, não um ajuste do efeito. A integração de debug foi **desligada do jogo**; o experimento fica isolado em `tests/` e não é usado por nenhum Move. Tackle/Brick Break do jogo continuam intocados. Nova direção pendente. Numeração: **D-953** é o próximo livre no `origin/main` (D-952 é o último); o checkout local está em um checkpoint antigo, com numeração própria ( local). Não há commit nem push (D-022).

## Frases literais do criador

> eu queria que o motion composer fosse na verdade também um animador de trajetorias e animações mas também uma ferramenta para criação de efeitos visuais seguindo as regras do jogo de wind up release projetil impacto, pos wind up, invocação e outros

Respostas às seis perguntas:

> 1 - A
> 2 - A
> 3 - B
> 4 - Tudo visuais que obviamente vão estar no combate, mas são apenas efeitos visuais que enriquecem a qualidade do jogo
> 5 - melee, aoe, status buff debuff, heal, guard, o que existe até o momento
> 6 - preset de dados + laboratorio, eu não vou mexer em nada, é vc quem faz as coisas.

## Decisão

1. **O Composer é as duas coisas:** animador de trajetórias e animações procedurais **e** ferramenta de criação de efeitos visuais. Não é um ou outro.
2. **A autoria é por contrato de fase:** cada família de Move declara suas fases **visuais** (wind-up, pós-wind-up, release, trajeto, impacto, retorno, invocação/cast, etc.). As trilhas de movimento, propriedades, emissão e representação são amarradas a essas fases.
3. **Animações = 1A:** animação procedural das propriedades do próprio VFX — posição, escala, rotação, opacidade, parâmetros de shader, luz e flipbook. **Não** autoriza, nesta decisão, criar ou tocar clipes esqueléticos de personagem nem dirigir o `AttackMotion`.
4. **Pós-wind-up = 2A:** é a **carga segurada** entre o fim do wind-up e o release. Vira uma **sub-fase visual explícita**, não uma fase lógica nova.
5. **Invocação = 3B:** é a **conjuração de magia/status**, não summon de criatura. Entra como contrato visual de cast/status; não cria criatura nem fase lógica nova.
6. **Tudo é visual (4):** as fases e trilhas só enriquecem a qualidade. Não alteram dano, acerto, esquiva, duração, alcance, ATB ou qualquer regra de combate. O Battle continua dono do relógio e das fases lógicas.
7. **Famílias da primeira versão (5):** melee, AoE, status buff/debuff, heal e guard, além do que já existe (projétil e os Moves atuais). A invocação, na acepção 3B, é tratada dentro de status/cast; se ela precisar de um contrato próprio, é decisão nova.
8. **Primeira versão = preset de dados + laboratório (6):** sem editor visual. O assistente cria os presets; o criador não vai editar. A UI de edição (D-042/D-043/D-045) fica para depois. O laboratório mostra o contrato de fases, as trilhas e o efeito em A/B, normal + espelhado.
9. **Projétil continua com as quatro fases da D-308** (wind-up → release → trajeto → impacto), agora com o pós-wind-up explícito entre wind-up e release. Os demais contratos são adições, não substituições.
10. **Nada existente muda:** nenhum efeito, Move, regra ou asset existente é alterado por esta decisão (D-323). Nenhum Move é ligado ao novo contrato sem decisão própria.
11. **Independência:** tudo deriva do atacante e do alvo reais; nada de personagem, time, lado, posição fixa ou câmera fixa (D-235).

## Primeiro corte (2026-11-06)

Perguntado qual família/Move vem primeiro, o criador escolheu:

> Melee — Tackle/Brick Break

**Decisão:** o primeiro corte do Composer de Fases é a família **melee**, tendo **Tackle** e **Brick Break** como casos. O contrato visual e a implementação ainda não foram definidos; nada foi codado.

## Primeiro corte implementado (2026-11-06)

**V1 no laboratório, sem tocar no jogo.** Contrato visual: wind-up → pós-wind-up (vazio nesses dois, porque não seguram carga) → release → trajeto → impacto → retorno. A arte nova é `MotionPresets.tackle_rush_effect`; o `brick` troca o acento. Peças novas do Composer: `MotionPhaseContract`, `ring.expand` (onda de choque que abre), `flipbook.tint` + `mc_sprite_tint` (poeira tingida), representação `light` (pulso omni pooled) e `M23 floor_y/restitution` (quique decorativo analítico). O laboratório é `tests/vfx/melee_phase_lab.gd`, com a câmera CINEMA do jogo (FOV 80), as duas vistas e vídeo de 60 fps. Luz e quique são **só do laboratório**; não são regra de combate e não tocam no jogo.

**Verificado:** parse headless; 13 quadros por vista; A/B com a mesma semente 0,000036 e com semente diferente 0,00234; **0 nós aos 4 s**; vídeo `test_captures/melee_phase_lab/melee_phase_v1.mp4` (normal em cima, espelhado embaixo).
**Não verificado:** batalha real, personagens reais (o lab usa marcadores neutros), desempenho, aprovação artística.
**Fraco:** o impacto na vista normal (alvo longe) ainda fica pequeno; a poeira ainda lê como fumaça; a carga do wind-up é sutil.

**Integração na batalha real (2026-11-06):** novo `MeleePhaseVfx` (`scripts/combat/fx/melee_phase_vfx.gd`) desenha o mesmo `tackle_rush_effect` no VFX room, lendo as fases reais do `Incoming` e os modelos reais (D-235). O Move de debug **"Melee Phase"** é listado só nessa sala (`Skill.melee_phase_skills`); o Tackle/Brick Break do jogo não foram alterados. O VFX genérico desse Move de debug é suprimido para não empilhar. Vídeo: `test_captures/melee_phase_room_v1.mp4` (normal em cima, espelhado embaixo, Abra → Gible, `--distance=8`).

**Escala:** o `MeleePhaseVfx` usa uma escala derivada da distância da câmera (1,0–2,6×) para o impacto ler no alvo longe; o tamanho é medido na tela.

## Reprovação da V1 (2026-11-06)

O criador viu o vídeo com personagens e reprovou:

> seu video não é mt claro, é preciso que tenha sim a animação de um ou dois personagens presentes na cena pros ataques melees fazerem sentido visual

> tá um lixo completo, impossível de ser aceitável

**Causa identificada (dados dos quadros):** a V1 tem **31 camadas**, mas nenhuma nasce do **contato real** do golpe. O impacto é uma nuvem/explosão branca na frente do alvo, não um golpe direcional; o wind-up é um anel/halo no corpo, não uma carga no membro; o trajeto é poeira, não rastro do corpo; o retorno é um sopro. A escala maior só aumentou a nuvem. **Não é um problema de quantidade de camadas; é de coreografia e contato.**

**Direção recomendada (a decidir):** reiniciar o melee com o conceito **"Impact Frame"**, contact-first: usar o **frame de contato do clipe real** e o **membro/alcance real** do atacante; o impacto é um **crescente/cone direcional + silhueta branca + cacos + onda no chão**, com **5–6 camadas**, não 31; o trajeto usa **afterimages/ghost snapshots** e um smear do membro, não poeira genérica; o wind-up carrega no membro; o retorno é afterimage + poeira de pouso. Testar primeiro **só o frame de impacto**, com os dois personagens, antes de refazer as outras fases. Nenhum código novo até o criador escolher o caminho.

## Correção de direção (2026-11-06)

> use o que temos de referência, o unico problema do nosso que já temos de referência é que o ataque em si (o timing do dodge) está completamente vertical e "2D" ao invés de seguir o movimento do ataque do personagem

**Decisão:** não inventar outro efeito. Usar a **referência que já existe** e corrigir o **eixo/timing**: o ataque tem de **seguir o movimento real do personagem**; o defeito é o impacto num plano **vertical/2D** e num tempo que não acompanha o golpe.

**Respostas do criador:** referência = **impacto do Tackle (D-041)**. O "timing do dodge" é o momento em que o atacante **já está a 2,6 unidades** do alvo, faz a animação de preparo e então acerta/erra; é a janela que permite o Evade. Nome sugerido pelo criador: **Hit-windup** ou **dodge prelude**. Termo adotado nos docs: **Hit-windup** (inglês) / **prelúdio do ataque** (português); sinônimo: **dodge prelude**.

**Implementado (2026-11-06, primeira passada):** nova fase visual **`prelude`** no `tackle_rush_effect`: tubo **3D** do **membro real** até o contato, carga no membro, poeira de chegada, anel de trava no alvo e linhas no eixo. O `MeleePhaseVfx` ancora no **osso de mão/arma** do modelo (nomes genéricos; fallback no corpo), então o efeito segue a animação de ataque em vez de um plano vertical. Vídeo: `test_captures/melee_phase_room_prelude.mp4`. **Ainda é primeira passada; não aprovado.**

## Descarte completo (2026-11-06)

> descarte-o por completo, está péssimo eu não gostei de nenhum dos resultados apresentados e acho que o problema é o motion em si

**Decisão:** descartar a V1, o prelude e a integração de debug. **O problema é o motion do Motion Composer**, não um parâmetro do efeito. Não iterar mais o mesmo motor para melee. A integração de debug foi desligada do jogo; o experimento fica isolado em `tests/` e **não é usado por nenhum Move**. A próxima direção deve ser **animação-first** (pose-a-pose/contato/afterimages/flipbook) e não motion procedural; a decisão de aposentar o Composer no motion principal continua aberta.

## Pausa do VFX (2026-11-06)

Perguntado se autorizava tirar o Motion Composer do motion principal, o criador escolheu:

> Pausar o VFX

**Decisão:** o trabalho de VFX fica **pausado** até o criador definir o pipeline e a régua de qualidade. Nenhum efeito novo, nenhuma alteração no Composer e nenhuma integração em Move até nova ordem. A integração de debug já foi desligada; o jogo está limpo; o experimento fica isolado em `tests/` e marcado como REJECTED. Sem commit ou push (D-022).

## Por que os protótipos são inferiores ao HTML/Quarks (2026-11-06)

> eu genuinamente não sei pq os protótipos feitos com ele são absurdamente inferiores a tudo, não utiliza as animações dos personagens, não utiliza um escopo decente, parece que está fazendo algo que não tem haver com o jogo, a maioria dos resultados é porco e inferior a um protótipo em html com quarks...

**Causas identificadas (técnicas, com evidência no projeto):**
1. **Motion procedural x animação do personagem:** o Composer anima **caminhos paramétricos** (M01–M26); ele não lê o `AnimationPlayer`, a pose, o membro ou o frame de contato do personagem. O efeito é um sistema separado do corpo.
2. **Falta de escopo por shot:** o HTML/Quarks é autorado como **um plano** (câmera, enquadramento, escala de tela, timing e camadas juntos). O Composer é testado em laboratório com marcadores e depois no jogo com o alvo a ~30 m; a composição e a escala não são as mesmas.
3. **Render:** o HTML usa `UnrealBloomPass`, aditivo e tela; o Godot está em **GL Compatibility** e o jogo **não tem bloom/glow** em nenhum `WorldEnvironment` (D-337). O material do Composer é plano e não reproduz o "neon" do HTML.
4. **Os efeitos aprovados não usam o Composer:** Abra v9 (`AbraMoveVfx`/`AbraCanvas`), Tackle D-041 (`VfxLib`/malhas/flipbooks) e os moves do atelier (`MotionAtelierMeshes`/shaders) foram feitos **à mão, por shot**, com câmera e composição. O Composer é o único pipeline que produziu resultados reprovados.
5. **Conclusão:** o Composer pode servir para **movimento secundário** (poeira, brasas, rastros), mas **não para o motion principal de um golpe**. O motion principal precisa ser **animação pose-a-pose/contato + malhas/flipbooks + câmera/composição**, como as referências aprovadas.

## O que fica em aberto (perguntar antes de codar)

- **Contrato de cada família:** a ordem exata e os nomes das fases visuais de melee, AoE, status, heal e guard. A decisão fixa as famílias, não a coreografia.
- **Invocação 3B:** quais elementos visuais entram (círculo, portal, selo, aura?) e se o alvo é o conjurador, o alvo ou ambos.
- **Formato do preset:** dicionário GDScript, `.tres`/Resource ou JSON. É detalhe técnico, mas define o laboratório.
- **Runtime:** se o Composer de Fases usa o grafo/eventos/simulação proposto antes ou uma camada mais simples sobre o `MotionEffect`. **O grafo não está aprovado por esta decisão.**
- **Ordem dos primeiros Moves:** melee escolhido; a V1 cobre Tackle/Brick Break no laboratório e no VFX room (Move de debug). Falta decidir a aprovação da arte, a escala (fixa vs câmera), a entrada no jogo e a ordem dos próximos Moves.
- **Editor visual:** não autorizado agora; D-042/D-043/D-045 continuam especificados, não implementados.

## Relações

D-042–D-046, D-230–D-233, D-235, D-274, D-308, D-322, D-323, D-343, D-061.

## Estado no código

**Nenhum.** A decisão é de direção e autoria; não há código novo, teste, preset ou efeito ligado. Nada de commit ou push sem autorização (D-022).
