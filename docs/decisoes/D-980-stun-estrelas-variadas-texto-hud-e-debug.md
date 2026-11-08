# D-980 — STUN: estrelas variadas e maiores; texto, HUD e cenários de debug (em definição)

- **Data:** 2026-11-08.

## Frase literal do criador

> Adicione cenários de efeitos de status no jogo e um botão pra adicionar eles a um ou mais personagens no debug.
>
> faça com que cada estrela tenha um tamanho diferente rotacionar angularmente de um jeito diferente, na visão distante na camera normal, as estrelas do oponente não são mt visíveis, aumente o tamanho delas um pouco
>
> faça com que surja um texto "STUN!" animado (me de 3 opções bem ambiciosas que batem com a ideia de um stun) por 1.5 segundos e coloração de texto flat sem bordas, amarela.
>
> Também quero ver como podemos fazer este efeito visualmente na hud do jogador assim como o Burn é (3 opções)

## Decisão (aprovada e implementada)

1. Cada estrela do STUN tem **tamanho próprio** (1,0 / 0,7 / 1,25 / 0,85 / 1,1) e **giro próprio** em torno do centro (velocidades e sentidos diferentes).
2. Estrelas **um pouco maiores**: 0,5 m → 0,65 m (para todos; tamanho fixo em metros, D-308).

3. **Texto "STUN!"** (escolha: "Pancada que racha"): o texto despenca do alto e bate na cabeça do alvo com achatamento, tremendo como um sino; as letras ficam tortas e balançando zonzas; no fim cada letra cai em velocidade diferente. 1,5 s, amarelo flat, sem borda.
4. **HUD** (escolha: "Cartão zonzo"): enquanto em STUN, o cartão balança levemente em círculo como o personagem; estrelinhas giram sobre o retrato; o retrato ganha olhos em espiral.
5. **Debug** (escolha: "Sala de VFX"): novo grupo de cenários "Status" e seleção de vários personagens para aplicar STUN, Burn, Blind e buffs/debuffs (ATK/DEF/SPD ±).

## Ambiguidade

- "Olhos em espiral" no retrato: o jogo não sabe onde ficam os olhos de cada retrato; as espirais ficam numa posição fixa relativa ao retrato (proporção), não por espécie (D-235). Conferir no vídeo.
