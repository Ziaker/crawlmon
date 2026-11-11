# D-1158 — Item no mapa: Bolha de Relíquia (opção 1)

- **Data:** 2026-11-11.
- **Área:** Overworld 3D / itens no mapa / leitura visual.
- **Relacionadas:** D-1151 (itens no mapa), D-1156/D-1157 (notificação e card do aliado), D-1090/D-1094 (papel/HUD), D-235 (nada depende de personagem/time/lado), D-1154 (overworld fora do `BattleTrace`).
- **Status:** **aprovado pelo criador em 2026-11-11 (“está perfeito”)**; implementado/provado no **lab real**; **colisão de ID com o `D-1158` fase 3 de outra sessão — commit pendente da numeração**; **sem push**.

## O que o criador disse (literal)

> perfeito, agora vamos fazer o protótipo visual dos itens presentes no mapa,eu não sei como explicar direito mas, ser apenas o sprite 2D flutuando fica impossivel de se entender, talvez eles estarem envoltos em uma bolha ou algo do tipo, me dê 3 opções bem diferentes

> opção 1

> está perfeito

## Decisão

1. A opção escolhida é a **1 / A — Bolha de Relíquia**.
2. O item do mapa passa a ser uma **bolha de vidro de 0,7 m** (raio 0,35) com **rim Fresnel dourado**, o **ícone real do item** dentro (0,30 m), um **glow** quente, um **facho de luz** até a bolha, um **anel no chão** e **4 sparkles** orbitando.
3. Abaixo da bolha, uma **etiqueta de papel** em 3D (frente para a câmera) com o **nome** do item e o **tipo** (`HELD`/`CONSUMABLE`), no estilo do Paper Tag (D-1156/D-1094). Ex.: `AMULET` / `HELD`.
4. A bolha **flutua** (bob de ±4 cm); a etiqueta, o anel e o facho ficam no lugar. A etiqueta é legível a ~5 m; o conjunto é o “beacon” do item.
5. **Qualquer item** usa o mesmo componente, derivado de `Item.display_name`/`Item.icon_of`/`Item.kind`; nada depende de personagem, time ou lado (D-235).
6. **O que não muda:** posição dos itens (D-1151), coleta automática a **1,25 m**, inventário, notificação/orbe (D-1156/D-1157), HUD, câmera, combate e regras.
7. As opções **B (Marco de Expedição)** e **C (Uplink SMT)** continuam no protótipo HTML como referência; não entram no jogo.

## Implementação

- `scripts/debug/overworld_item_pickup.gd`: a raiz do pickup continua no ponto do item; a bolha/ícone/glow/sparkles ficam num `_float_root` que bobeia; o anel, o facho e a etiqueta ficam estáticos. O anel usa `shaders/overworld_marker_ring.gdshader`; a bolha usa `shaders/item_relic_bubble.gdshader` (novo, Fresnel aditivo).
- A etiqueta usa uma textura de papel gerada em código + dois `Label3D` (nome e tipo), com o texto sempre de frente para a câmera.
- As texturas de glow/facho/sparkles são geradas em código; o ícone é o PNG real do item.
- Nada muda no sinal `collected`, no grupo `item_collector` nem na notificação.

## Provas

- `docs/referencias/exploracao/3d/d1158_item_bubble_amulet.png` — **lab real**, amuleto na sala oeste.
- `d1158_item_bubble_super_potion.png` — **lab real**, super poção na sala do meio.
- `d1158_item_bubble_close.png` — **lab real**, close do amuleto com bolha, etiqueta, anel, cone e as plantas da sala.
- `d1158_item_bubble_pair.png` — cena isolada, amuleto + super poção lado a lado.
- `d1158_item_bubble.gif` — 24 quadros (0,8 s, 30 fps) do close isolado.
- `d1158_item_bubble_sheet.png` — 24 quadros de contato.
- Cena isolada: `video_lab/item_visual_lab.tscn`; o lab real: `video_lab/audit_item_visuals.tscn` (agora roda; o attack controller de outra sessão voltou a compilar).
- O mesmo `scripts/debug/overworld_item_pickup.gd` usado pelo lab; shader `shaders/item_relic_bubble.gdshader`.

## O que foi verificado

- A bolha de vidro, o ícone real, a etiqueta de papel com nome/tipo, o anel, o cone 3D, o glow e os 4 sparkles aparecem no **lab real** (amulet na sala oeste e super poção na sala do meio) e na cena isolada; a bolha flutua e o resto fica estático.
- O mesmo componente funciona com **AMULET** e **SUPER POTION**; o nome longo é auto-ajustado para caber no papel.
- A coleta, o grupo `item_collector`, o inventário e a notificação não foram alterados (o `audit_item_visuals` deixa os itens a 3,5 m do dummy e eles não são coletados).
- A opção A está marcada como **ESCOLHIDA** no HTML; B/C continuam como referência.

## O que não foi verificado

- O **commit**: existe uma colisão de IDs (nossa `D-1158` × `D-1158 fase 3` de outra sessão); é preciso escolher a numeração antes de commitar.
- Performance com muitos itens na tela e o custo do shader aditivo/transparência em GL Compatibility.
- Leitura da etiqueta em outras resoluções/aspectos e a ±6 m.
- Oclusão da etiqueta por paredes/personagens (o texto usa `no_depth_test` para ficar legível; isso pode fazê-lo aparecer sobre um obstáculo).
- Nomes de item muito longos fora do catálogo atual.
- A cor do cone (rosa-pálido sobre o roxo; pode virar creme/ouro).
- As opções B/C não foram implementadas.

## Estado

**Aprovado pelo criador em 2026-11-11 (“está perfeito”)**; implementado/provado no lab real e na cena isolada; **sem push**. A opção A é a feature no `overworld_item_pickup.gd`; B/C ficam no protótipo HTML. O commit seletivo está pendente da numeração (colisão com o `D-1158` fase 3 de outra sessão).
