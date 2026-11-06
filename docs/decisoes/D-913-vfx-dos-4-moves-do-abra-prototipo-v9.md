# D-913 — VFX dos 4 moves do Abra conforme o protótipo HTML v9

> **Renumerada em 2026-11-06:** D-170 → D-913. O ID D-170 já pertence a outra decisão no `origin/main`; o conteúdo local foi preservado com o novo ID.


- **Data:** 2026-11-04
- **Área:** Visual / VFX
- **Origem:** Conversa (pedido repassado pela sessão de origem; **não é a frase literal do criador**, que não foi reproduzida na tarefa)

## O que o criador pediu (resumo repassado)

> Implementar no jogo os efeitos visuais dos 4 moves reais do Abra (Confusion, Psybeam, Shock Wave, Teleport), a partir do protótipo `crawlmon_prot_tipo_vfx_dos_4_moves_reais_do_abra_hud_v9.html`. Antes de implementar o Teleport, consultá-lo com uma pergunta sobre trocar o "prisma" por um VFX melhor.

## Decisão

1. O protótipo v9 é a referência **visual** de cada move (wind-up, voo/feixe, impacto). O HUD do protótipo não faz parte do pedido.
2. **Paletas do protótipo:** Confusion, Psybeam e Teleport em rubi `#ff1744`, magenta `#e056fd`, rosa `#ff66b2`, violeta `#b666ff` e tinta escura; Shock Wave em amarelo `#ffea00` e amarelo queimado `#e67e00` com núcleo `#fff8d6`.
3. **Só desenho (D-019, D-003):** dano, custo, ordem de eventos, hit-stop, janelas de Evade e **durações do jogo** (wind-up, voo, fases do plano de ataque; D-032, D-034, D-906) continuam valendo. Os 1,5 s de wind-up e os `activeDur` do protótipo **não** são adotados; os efeitos se escalam pelo tempo que o jogo já usa.
4. **Sem tremor/zoom novo de câmera nem textos 3D novos (D-020).** O `camShake` do protótipo não é portado; o hit shake genérico da D-900 continua como está.
5. (Revogado pelo item 11.) Inicialmente os efeitos antigos seriam mantidos e recoloridos.
6. **Teleport (`teleporte_rapido`) por último**, só depois da resposta do criador sobre o prisma (abaixo). A sequência lógica (D-034: some depois do wind-up, surge atrás do alvo, volta à origem, sem deslocamento) não muda.

## Resposta do criador sobre o prisma do Teleport (2026-11-04, literal)

> "speedlines semelhantes mas não iguais ao do evade e animadas, roxas e brilhantes nos dois casos, com riscos em sentido de 90 graus pra cima"

Interpretação aplicada (não confirmada ponto a ponto; ver ambiguidades):

7. O prisma/fenda do protótipo **sai**. No lugar entram speedlines **roxas e brilhantes, animadas, em riscos verticais que sobem (90° para cima)**, parecidas com as do Evade (`FxDodge._speed_lines_at`: 9 riscos horizontais ciano) mas **não iguais**: verticais, roxas, mais numerosas, com núcleo claro e movimento de subida.
8. "Nos dois casos" = os dois lugares onde o protótipo punha o prisma: **na origem (onde o Abra some/volta)** e **atrás do alvo (onde ele surge/some)**. As speedlines aparecem em cada sumiço e cada aparecimento nesses dois pontos, e como sinal de carga durante o wind-up.
9. O resto do Teleport do protótipo é portado como desenho puro: anéis de varredura no Abra e selo de anéis no ponto de chegada (no wind-up), Tesseract na palma e 7 anéis de Mach no golpe, cores rubi/magenta/rosa/violeta.
10. **Não portados por conflito com D-034 ("sem deslocamento nenhum")**: a fita no chão ligando o Abra ao selo e a fita de retorno em curva. O ponto de chegada usado é o do jogo (atrás do alvo), não o "flanco" do protótipo.

## Ordem posterior do criador: fidelidade exata ao HTML (2026-11-04)

> "eu preciso que siga a mais perfeita risca os visuais, é pra ser exatamente igual aos do html, sem diferenças visuais"

Respostas às perguntas de esclarecimento (escolhas expressas do criador):

11. **Efeitos antigos do jogo que não existem no protótipo saem** dos 4 moves do Abra (anéis de compressão, flipbooks, cones, reticle de chão e aura de carga, arco e trava do Shock Wave, anéis do Teleport etc.). Só ficam os efeitos do protótipo. Isto revoga o item 5 e é uma exceção expressa à D-020 apenas para estes 4 moves.
12. **Tempos: escalar ao tempo do jogo.** O visual do protótipo é comprimido/esticado para caber nas fases que o jogo já tem; dano, ordem e hit-stop não mudam.
13. **Teleport: vale a D-034** (chegada atrás do alvo, sem fitas no chão); speedlines roxas no lugar do prisma. É o único desvio assumido em relação ao HTML.
14. **Sem tremor de câmera** do protótipo (hit shake genérico da D-900 segue como está).
15. Coordenadas e tamanhos do protótipo são usados 1:1 (Abra do jogo e do HTML têm ~2,3 de altura); os efeitos não são escalados por distância. O HUD/legendas de texto do protótipo (barra "CARGA", "RUBY RESONATOR", "IONIZATION LOCK", "FLANK COORD", rótulo de dano) **não** são portados: não são VFX e o jogo tem sua própria interface.

## Ajustes posteriores do criador (2026-11-04)

> "shock wave ainda não me deixa satisfeito, as cores tão mt baixas mal perceptíveis, o impacto está péssimo ... quero mais impacto mesmo errando" / "confuse não tem efeito de disparo" / "o efeito visual que você colocou no teleporte está um lixo"

16. **Shock Wave:** cores saturadas e opacas (a transparência do protótipo ficava fraca na distância do jogo), raios mais grossos, e o impacto ganhou camadas fortes (flash, coluna de energia em shader, 3 anéis de choque no chão, flipbooks de relâmpago e de impacto, cone, faíscas). Isto reintroduz, só para o Shock Wave, o tipo de efeito que o criador aprovou antes (exceção expressa). **O impacto também toca quando o golpe erra** (visual apenas; dano e regras não mudam). Interpretação de "mesmo errando": impacto visual quando o alvo esquiva; não confirmada.
17. **Confusion:** efeito de disparo no instante em que sai (flash no Abra, anéis de choque na direção do tiro, cone de faíscas, anel no chão) e projéteis maiores com brilho e rastro de partículas.
18. **Teleport:** efeito refeito em camadas (`abra_pops.gd` + `shaders/abra_column.gdshader`): ao sumir e ao surgir (origem e atrás do alvo) há flash, coluna de energia roxa, anéis no chão, riscos verticais brilhantes que sobem, faíscas e fantasma do modelo; no wind-up colunas crescem na origem e no ponto de chegada; no golpe entram flash, flipbook, cone e riscos extras.

## Esclarecimento do criador sobre "idêntico ao HTML" (2026-11-04)

> "com identico ao html eu digo visualmente na questão da animação dos efeitos, não usar específicamente as mesmas coisas que o html usou, até pq na maioria eles não usam quarjs ks"

19. **"Idêntico ao HTML" vale para o visual e a animação** (formas, cores, ritmo, sequência de cada move), **não para a técnica**. Os efeitos do Abra devem ser feitos com os recursos do jogo (flipbooks, partículas com textura, malhas do Blender, shaders), como os do Gible, imitando o que o HTML mostra. Isto corrige a leitura anterior (item 11 / port literal de linhas e polígonos do Canvas 2D), que fica **superada** nesse ponto. Os itens 12 a 14 continuam valendo.
20. Só há 4 sheets de flipbook (`fire`, `impact`, `lightning`, `smoke`); para energia psíquica (esfera, vórtice, Tesseract) usam-se partículas e shaders texturizados, ou uma sheet nova se o criador aprovar.
21. Cada move é refeito um por vez, mostrado rodando na sala de VFX e só segue com a aprovação do criador.

## Ambiguidades em aberto

- "Nos dois casos" foi lido como origem e ponto de chegada (atrás do alvo); se o criador quis dizer outro par (por exemplo, sumir e surgir), ajustar.
- Quantidade, tamanho e velocidade das speedlines não foram especificados (valores de partida, ajustáveis).

## Estado no código

Confusion, Psybeam, Shock Wave e Teleport: implementados como VFX (`scripts/combat/fx/abra_move_vfx.gd`, `abra_canvas.gd`), ligados em `fx_telegraph.gd`, `fx_projectiles.gd` e `fx_impacts.gd`.
