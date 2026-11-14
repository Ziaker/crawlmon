<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1133 — Novo cômodo a leste e Gible patrulhando lá

- **Data:** 2026-11-10.
- **Área:** Exploração 3D / lab Murky Forest / geometria / NPC inimigo.
- **Relacionadas:** D-1106 (segundo inimigo), D-1125 (inimigos visíveis), D-1028 (escala/visual), D-1132 (ataque).
- **Status:** **implementado/provado**; código na árvore de trabalho; **sem push**.

## O que o criador disse (literal)

> corrige isso do inimigo estar dentro das paredes adicionando mais um comodo no ambiente, então coloque ele lá patrulhando

## Regra

1. **Novo cômodo:** preencher o vazio a leste da sala inicial (x 4..18, z -6..6), formando um terceiro cômodo ligado à sala inicial e ao corredor.
2. **Porta:** abrir um vão de **3 m** (uma célula D-1028) na parede interna (z=-5,75, x 8..11), ligando o corredor ao cômodo novo. A parede leste da sala inicial (x=4,25) fica inteira.
3. **Gible fora das paredes:** mover o spawn de `(5, 0, -5)` para **`(11, 0, 0)`**, no centro do novo cômodo, e fazê-lo **patrulhar** quatro pontos: `(6,4)`, `(16,4)`, `(16,-4)`, `(6,-4)`.
4. **Navegação/colisão:** piso e paredes com colisão; novo polígono de navmesh cobrindo o cômodo; o Gible continua usando movimento direto com `move_and_slide` e volta a patrulhar quando o jogador sai do raio de perseguição.
5. **Visual:** reutilizar as texturas de parede existentes nas paredes novas; adicionar luz verde, folhas e pedras básicas para o cômodo não ficar vazio.
6. **Minimapa:** acrescentar piso/paredes do novo cômodo às cópias chapadas do mini-mapa.
7. **O que não muda:** ataque (D-1132), HUD, cards, regras, batalha, 2D, o resto do lab.

## Implementação

- `scripts/debug/murky_forest_3d_lab.gd`: piso/paredes/portas, spawn/patrol do Gible, navmesh, minimapa, luz e folhagem.
- A porta de 3 m divide a parede interna z=-5,75 em x 3,75..8 e x 11..18,25; a parede leste x=4,25 fica inteira.

## Provas

- `docs/referencias/exploracao/3d/d1133_new_room.png` — cômodo novo.
- `docs/referencias/exploracao/3d/d1133_new_room_patrol.png` — Gible em PATROL.
- `docs/referencias/exploracao/3d/d1133_new_room_door.png` — vista da porta de 3 m.
- `docs/referencias/exploracao/3d/d1133_new_room_inside.png` — jogador dentro do cômodo, após atravessar a porta.
- `docs/referencias/exploracao/3d/d1133_new_room.mp4` / `.gif` — patrulha + entrada.

## O que foi verificado

- O Gible nasce em **`(11, 0, 0)`**, dentro do piso novo, e patrulha; o log mostrou posições de `(10,0; 0,8)` a `(6,7; 3,5)` com estado **PATROL**.
- O jogador atravessou a porta de 3 m andando de `(9,5; -8)` para dentro do cômodo (`d1133_new_room_inside.png`).
- Piso e paredes têm colisão (`_box`); a navmesh ganhou o polígono do cômodo; o minimapa ganhou as cópias chapadas.
- As paredes novas reutilizam os materiais existentes; a parede leste da sala inicial ficou inteira.
- A cena rodou com `exit=0`.

## O que não foi verificado

- Se o tamanho/local do cômodo é o que o criador imaginou; a escolha foi o vazio quadrado onde o Gible estava.
- A navmesh depois de `super()` é atualizada ao vivo em todas as versões do Godot 4.7; o Gible usa movimento direto, então a patrulha não depende dela.
- Todos os ângulos de câmera/colisão, o Slime entrando no cômodo e o desempenho.

## Estado

Implementado e provado. Código na árvore de trabalho (o lab ainda depende do trabalho não commitado da D-1100/D-1106); **sem push**.
