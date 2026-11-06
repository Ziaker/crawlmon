# Bubble Shield — protótipo visual HTML (4 opções)

Protótipo **isolado** do Move **Bubble Shield** para o Slime, feito em HTML 3D com
**Three.js r169 + three.quarks 0.15.7** (D-333: exceção de protótipo HTML/Quarks).
A **opção D** incorpora a direção visual do laboratório externo fornecido
(`Bubble_Shield_Prototipo_3D_Documentacao.md` + `bubble_shield_vfx_lab.html`,
mantidos em `reference/`). Nenhum código, cena ou VFX do jogo Godot foi alterado.

## Abrir

`bubble_shield.html` é **autossuficiente**: Three.js, Quarks, o Slime GLB (base64),
CSS e JS estão embutidos. Basta abrir no navegador (não precisa de servidor).

## Ficha aplicada (D-323 a D-326)

- Água · Status · **ALL ALLIES** · **3 ATB** · **wind-up 0,7 s**.
- **25 + MAG** por aliado, reserva **individual**, duração **8,0 s**.
- **SEM TIPO** (resposta do criador para a tipagem defensiva).
- Reaplicação **reseta** (D-324), não soma.
- **Sem** anti-interrupção automática; a ficha não declara essa propriedade (D-325).
- O botão **Quebrar** é o gatilho visual de ruptura (D-326 / Brick Break); não é a
  implementação do Move Brick Break.
- MAG do protótipo: **9** (demo) → escudo **34** por aliado. O atributo real ainda
  não está ligado ao `Combatant` do jogo.

## As 4 opções

| Opção | Leitura visual |
|---|---|
| **A — Bolha de sabão** | Esfera de filme de sabão iridescente, micro-bolhas internas. Literal e limpa. |
| **B — Colmeia de bolhas** | A mesma membrana com grade hexagonal de células. Mais gráfica. |
| **C — Bolha prismática** | Geodo facetado com película iridescente; facetas acendem no contato. |
| **D — Aegis aquática** | Membrana fina de água, lâminas/crescentes radiais girando em coroa, crista de espuma, sinos de água-viva e sigilo central. Tradução da referência externa. |

### Opção D — o que veio da referência

- **Wind-up:** coroa de **lâminas/crescentes radiais de água** em torno do grupo, girando no eixo; cada lâmina sobe escalonada com overshoot, recebe uma **crista de espuma** (tubo + contas) e afunda suavemente ao cruzar a frente, mantendo os rostos livres. Duplo filete helicoidal, sinos de água-viva e sigilo central completam o vórtice.
- **Release:** anel fino se propagando a partir do lançador (visual, não projétil) e membranas expandindo com overshoot; as lâminas colapsam/descem enquanto os orbes inflam.
- **Ativo:** água com filamentos largos, reflexos, gotas capilares e **sigilo de núcleo** que escurece com a resistência; sem a malha de caustics que parecia rede; oscilação perto de expirar.
- **Impacto:** depressão localizada na membrana + onda circular de deslocamento; sem
  estrela/anel genérico de chão.
- **Ruptura:** contração e gotas balísticas (58).
- **Expiração:** expansão suave e gotas (30), distinta da ruptura.

A referência externa foi lida e usada como direção de arte/shaders; os controles de
seleção de lançador/alvo e o slider de MAG dela não foram duplicados — o protótipo
mantém a bancada atual (Slime como conjurador, todos os aliados, MAG demo 9).

## Choreografia

1. **Wind-up (0,7 s):** nasce uma **coroa-vórtice no chão ao redor do grupo**, girando no
   próprio eixo, expandindo e crescendo em hélice. Cada opção tem sua leitura:
   **A** coroa de espuma/arcos de sabão; **B** coroa de colunas e anéis hexagonais;
   **C** coroa prismática de espinhos e tetraedros; **D** coroa de lâminas radiais de
   água com crista de espuma, sinos e sigilo central.
2. **Release:** a coroa se dissipa em ~0,45 s enquanto os orbes de escudo terminam de
   inflar (com overshoot). Em D, um anel fino também se propaga do lançador.
   Pequenos fluxos sobem de cada aliado, ligando a coroa ao orbe.
3. **Ativo (8 s):** membranas individuais, micro-partículas e HUD com valor/tempo.
4. **Acerto:** onda na **própria membrana** (dent/ripple no shader), flash em estrela
   (A–C) ou depressão + onda circular de água (D), com gotas/fragmentos no contato.
5. **Expiração:** a bolha sobe, oscila e **estoura** (A–C) ou expande e dissolve
   suavemente com gotas (D). A opção C esconde o wireframe antes de sumir.

## Controles

- **Espaço** Conjurar · **H** Acertar · **B** Quebrar · **E** Expirar · **M** Espelhar · **R** Reiniciar
- **1 / 2 / 3 / 4** trocam a opção.
- Arraste para orbitar; roda para zoom.

## Limites deste protótipo

- Laboratório de **arte/comportamento visual**, não a implementação de combate:
  não há MP, Burn/Poison, empilhamento de escudos, Brick Break real nem integração
  com o Battle.
- A Sala de VFX/Godot e o Motion Composer **não foram alterados**. A opção escolhida
  ainda precisa ser portada para o jogo conforme D-308.
- O Slime é o conjurador porque o Move é para ele, mas o efeito é independente de
  personagem, time e lado (D-235); **Espelhar** troca a câmera.
- Capturas de contato em `test_captures/bubble_shield_options.png` (fora do Git).
- Vídeos em `test_captures/bubble_shield_videos/` (fora do Git): um MP4 por opção, 7,5 s a 24 fps, com wind-up, dois acertos e expiração; `bubble_shield_comparison.mp4` traz as quatro em grade 2×2 rotulada. A/B/C ainda usam a coroa antiga; só a D tem o tratamento novo.

## Arquivos

- `bubble_shield.html` — entrega standalone.
- `shell.html`, `style.css`, `main.js` — fontes.
- `build.mjs` — bundle (esbuild) + CSS + GLB base64 + licenças.
- `contact_sheet.py` — regenera `test_captures/bubble_shield_options.png` a partir de `test_captures/bubble_shield_sheet/`.
- `reference/` — documentação e HTML do laboratório externo que originou a opção D.
