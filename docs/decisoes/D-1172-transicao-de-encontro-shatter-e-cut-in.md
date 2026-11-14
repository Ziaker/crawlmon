<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1172 — Transição de encontro: shatter de 36 cacos + cut-in em paralelogramo

- **Data:** 2026-11-11.
- **Área:** Exploração / encontros / transição / VFX de overworld.
- **Origem:** o criador entregou o protótipo `crawlmon_encounter_transition_prototype_three_js_glsl.html` e o script `EncounterTransitionVFX.gd` ("Opção A (C1) — Shatter Gravitacional 3D (36 Cacos) + Cut-In de 1 Único Bloco Paralelogramo Flat") e mandou seguir com eles; depois respondeu a quatro perguntas de escopo.
- **Estado:** regra registrada; implementação em andamento.

## O que o criador disse (literal)

> Seguimos para a transição como consta nos arquivos

Respostas às perguntas (rótulos escolhidos ou texto digitado):

> Substitui mas sem deletar a antiga dos arquivos
>
> Depois dos 0,5 s (Recomendado)
>
> Sem som (Recomendado)
>
> Fonte do jogo (Recomendado)

## Decisão

1. **Nova transição:** a entrada em batalha passa a usar o shatter de **36 cacos poligonais 3D** (grade 6×6) da tela do overworld, com trinca, blur radial e aberração cromática suaves, onda de choque e o **cut-in de um único bloco paralelogramo flat** com a palavra batendo letra a letra; depois o **banner inferior inclinado**. Sem flash de tela (coerente com D-418).
2. **Três variantes (D-1100 mantida):** contato = branco `CONTATO!`; jogador primeiro = azul `OPORTUNIDADE!`; inimigo primeiro = vermelho `EMBOSCADA!`. Cores, textos do banner e intensidades são os do arquivo. A palavra do azul passa de `VANTAGEM` (selo da Fenda tática) para `OPORTUNIDADE`, como consta no arquivo.
3. **Substitui a "Fenda tática"** (`scripts/ui/transition.gd`, D-1100) no jogo, **sem apagar o arquivo antigo**: a classe `EncounterTransition` continua no repositório, sem uso.
4. **Início:** a transição começa **depois dos 0,5 s de impacto do Tackle** (D-1115 intacta). Os primeiros 0,45 s do protótipo (aproximação dos bonecos) são o avanço real do jogo e não são reencenados; a transição dura **1,65 s** (do instante 0,45 s ao 2,10 s do protótipo): trinca 0,33 s, ruptura a partir de 0,33 s, arena revelada em 1,00 s, cut-in até 1,17 s, banner de 0,80 s a 1,57 s.
5. **Sem som:** o sintetizador procedural do script não entra.
6. **Fonte:** a fonte do jogo (`FanMenu.body_font()`), não a fonte padrão do motor.
7. **O que do script não entra no jogo:** as duas cenas falsas (overworld e arena com bonecos de primitivas), a órbita de câmera por arraste, o painel de estúdio/telemetria, os sliders e os botões de keyframe. No jogo os cacos mostram a **tela real do overworld capturada** e, atrás deles, a **batalha real**.
8. **D-308 não se aplica** (efeito de overworld, D-1100 item 15). Regras de combate, ATB de vantagem (D-1101), ataque no overworld e retorno ao mapa não mudam.

## Ambiguidades em aberto

- **"Substitui"** foi lido como: vale para **todas** as entradas de batalha (ataque/contato do lab 3D e a entrada antiga do 2D, que usa sempre o branco). Se era só o lab 3D, corrigir.
- **Idioma:** as palavras e o banner estão em português, como no arquivo e como o selo anterior; a D-413 pede UI em inglês. Mantido como no arquivo; perguntar se deve traduzir.
- **Centro da onda de choque:** no script é o ponto de colisão projetado na tela. No jogo usa a posição do jogador no contato, projetada pela câmera ativa (centro da tela quando não há câmera 3D).

## Relações

D-1100 (três transições, cores), D-1101 (vantagem no ATB), D-1115 (impacto do Tackle de 0,5 s), D-418 (sem flash), D-413 (idioma), D-235, D-019, D-061.

## Estado no código (2026-11-11)

**Implementado e testado; aguardando aprovação visual.** Nada commitado.

- Transição nova: `scripts/ui/encounter_shatter_transition.gd` (`EncounterShatterTransition`), com os shaders `shaders/encounter_shard_face.gdshader` (cacos: blur radial de 12 amostras, chroma e onda de choque) e `shaders/encounter_arena_blur.gdshader` (batalha real atrás dos cacos: blur de 10 amostras, chroma e vinheta).
- `scripts/autoload/game_state.gd`: `start_battle` e `start_battle_3d` usam a nova classe; `start_battle_3d` passa o ponto do contato projetado na tela. `scripts/ui/transition.gd` (Fenda tática) **não foi alterado nem apagado**.
- A cena é trocada em 0,12 s, com a tela ainda coberta pelos cacos; `revealed` sai na ruptura (0,33 s) e é o que libera a entrada dos lutadores em `battle_scene.gd`.
- Testes: `tests/overworld/test_d1172_shatter_transition.gd` **D1172_PASS**; `test_encounter_rules` (PASS; as asserções de selo/tempo ali continuam medindo a classe antiga), `test_end_to_end_attack_flow` (PASS, já com a transição nova) e `test_overworld_attack` (`OVERWORLD_ATTACK_TEST_PASS`).
- Gravação no lab real (Murky Forest), três variantes em sequência: `test_captures/encounter_shatter_d1172_3cases.mp4`; quadros em tamanho real do azul em `test_captures/encounter_shatter_d1172_blue_frames.png`; visão geral do vermelho e do branco em `test_captures/encounter_shatter_d1172_red_white_overview.png`. Gravador: `tests/overworld/record_shatter_transition_video.gd` (cópia do gravador do lab com esperas mais longas).

**Não verificado:** a entrada antiga do 2D (`start_battle`) rodando de verdade; quadros em tamanho real do vermelho e do branco (só miniaturas); outras resoluções/proporções de janela; custo de GPU do blur; o retorno ao mapa depois da batalha visto em vídeo (só pelo teste de ponta a ponta).
