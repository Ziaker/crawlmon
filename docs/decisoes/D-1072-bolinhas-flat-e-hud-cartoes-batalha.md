<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1072 — Bolinhas flat e HUD de HP/MP no estilo dos cartões de batalha

- **Data:** 2026-11-09
- **Área:** Exploração / HUD / mini-mapa
- **Origem:** depois de aprovar o Slime menor, o criador pediu para tirar o contorno das bolinhas e trocar o HUD de HP/MP pelo visual dos cartões de batalha.
- **Status:** **teste implementado no lab da Murky Forest** via nó `ExplorationBattleHud`; o resto está aprovado; nada publicado.
- **Nota D-1074 (2026-11-09):** os retratos dos Pokémon e as barras/textos dos cards do overworld foram trocados/ampliados; o Gible entrou como 4º card demo; a casca 330×104, as bolinhas flat, o HUD aditivo e a omissão dos sistemas de combate continuam.

## O que o criador disse (literal)

> tire as outlines dos circulos, deixe flat

> agora mude o hud de HP e MP, deixe exatamente que nem o hud in-battle dos cartões

## Decisão

1. **Bolinhas flat:** remover o contorno escuro de 1 px dos marcadores do mini-mapa. Ficam círculos de cor sólida, sem borda: azul (jogador/aliados), branco (NPCs), vermelho (inimigos). Tamanhos e posições atuais mantidos.
2. **HUD de HP/MP no estilo dos cartões de batalha:** usar o visual do `UnitCard` do `BattleHud`:
   - card **330×104**, corpo inclinado (skew 8), sombra;
   - **hero (Abra):** fundo creme `#eae9d9`, texto `#111b29`, acento AQUA, HP `#e96159`;
   - **aliados (Pancham/Orc):** fundo azul-escuro `#17283b`, texto `#eceada`, acento lilás, HP `#b5a5fe`, escala 0,85;
   - retrato no slot inclinado (16,26,56,62), nome uppercase em (84,44) fonte 18;
   - **HP** em (84,52) 120×7 com texto "HP 86/100" em (212,59) fonte 10;
   - **MP** em (84,64) 120×5 azul `#38bdf8` com texto "MP 14/20" em (212,69) fonte 9;
   - mesma fonte do battle (`SystemFont` Arial/Segoe UI, peso 800).
3. **O que fica de fora:** ATB, Burst, badges de status, burn/armor e o tanque de água do MP são elementos de combate; a exploração não tem esses sistemas. O card mantém a casca e as linhas de HP/MP; se o criador quiser os blocos de ATB vazios ou o tanque de MP, é uma decisão nova.
4. **Implementação aditiva:** um nó filho `ExplorationBattleHud` na cena esconde os badges antigos, achata as bolinhas e desenha os três cards. O script compartilhado do lab (que outra sessão edita para NPCs) **não é alterado**.
5. **Valores demo:** ABRA 86/100 + 14/20; PANCHAM 100/100 + 10/20; ORC 46/100 + 8/20. No solo só o card do Abra; no party os três. O HUD real deve ler `GameState.party`/`Combatant` depois.
6. **O que não muda:** mini-mapa 112×112 sem título, alerta "!", câmera, chão/floresta, Slime 0,49 m, batalha 3D, jogo 2D e regras.

## Ambiguidades

- **ATB/Burst/status/tanque de MP:** foram omitidos por serem de combate. Se o criador quiser o card completo mesmo na exploração (com blocos vazios ou valores demo), confirmar.
- **Tamanho:** o card de batalha é grande (330×104). Os três ocupam a lateral esquerda; se ficar grande demais no vídeo, reduzir a escala.
- **HP/MP demo:** continuam demo até ligar na party real.
- **Retratos:** usa `personagens/portraits/abra.png`, `pancham.png` e `orc.png`; se faltar, o slot fica sem retrato (como no battle).
- **Posição:** cards empilhados no canto esquerdo, abaixo do texto de controles.

## Teste implementado (2026-11-09)

- **Nó `ExplorationBattleHud`:** filho de `scenes/debug/murky_forest_3d_lab.tscn` (e do `murky.tscn` isolado). Ele espera um frame de física, esconde o `VBox` dos badges antigos, zera os contornos das bolinhas e desenha os três cards numa `CanvasLayer` 19. O script compartilhado do lab **não foi alterado**.
- **Bolinhas:** `dots_flat=true` nas duas auditorias; tamanhos 12/8/8/10 e cores azul/azul/azul/vermelho mantidos, sem textura/ícone.
- **Cards:** `count=3`; visíveis **1** no solo (ABRA) e **3** no party (ABRA, PANCHAM, ORC). O hero é creme 1,0×; os aliados são azul-escuro 0,85×, com “ALLY | AI”. Casca, sombra, retrato, nome 18, HP 10 e MP 9 iguais ao `UnitCard`; o fundo sem burn é o mesmo `slant` do battle.
- **Demo:** ABRA 86/100 + 14/20; PANCHAM 100/100 + 10/20; ORC 46/100 + 8/20.
- **Auditoria:** Slime `scale=0.35` / `capsule_h=0.49`; 0 paredes, 0 câmeras dentro, 0 câmeras coladas, path mínimo 2, 0 empilhamentos; porta `near/visible/used`; alerta “!” e toon intactos.
- **Mídias:** `murky_forest_solo.*` e `murky_forest_party.*` (330 quadros/11 s), stills, contatos, `murky_forest_minimap.png` e `murky_forest_hud.png` com os três cards.

## O que não foi verificado

- **ATB/Burst/status/tanque de MP:** continuam fora do card por serem de combate. Se o criador quiser o card completo mesmo na exploração, é uma decisão nova.
- **HP/MP demo:** ainda não leem `GameState.party`/`Combatant`.
- **NPC branco real:** o projeto isolado roda sem os NPCs da outra sessão; a bolinha branca de D-1064 não apareceu no vídeo.
- **Tamanho/posição finais:** os cards 330×104 empilhados no canto esquerdo foram aprovados nesta rodada; escala ou posição diferentes exigem novo pedido.
- **Qualidade fina:** fidelidade de fonte em outras resoluções, mobile/web, performance em 60 fps e licença.

## Estado

Teste implementado no lab isolado; mídias regravadas. Bolinhas flat, cards no estilo do battle e Slime em 0,49 m. O lab de pedra D-1023, a batalha 3D, o jogo 2D, a party e as regras não mudam; nada publicado.
