# D-348 — Parede de 1 tile: strip de dois lados e máscara de 8 vizinhos

- **Data:** 2026-11-06
- **Área:** Exploração / visual / tiles
- **Origem:** Correção do bug visual do Temporal Tower (lados direitos abertos)

## O que o criador disse (literal)

> nos lados direitos nao estao fechados e sim abertos, o que ta errado, os abertos devem ser pra interseccao com outros que seguem, nao sejam tratados como fechados, prossiga com cada melhoria

## Decisão

1. **Fora do mapa é aberto, não parede.** A máscara de tile passa a distinguir `#` (parede real) de fora do mapa. O lado externo da parede de borda precisa de **borda fechada**, não de continuação.
2. **Lados opostos abertos usam strips sintetizadas das 9 peças.** Gerar:
   - `wall_strip_h`: `wall_c` com as 6 linhas de borda de `wall_t` no topo e de `wall_b` embaixo;
   - `wall_strip_v`: `wall_c` com as 6 colunas de borda de `wall_l` à esquerda e de `wall_r` à direita.
   As strips usam a arte da própria folha, mas compostas sem as juntas das formas do frame. Usar quando a célula tem chão/fora nos **dois lados opostos** (`N+S` ou `L+O`). A parede de 1 tile fecha os dois lados, inclusive o de fora, sem juntas verticais.
3. **Lado aberto só é usado quando a parede continua.** Se um lado é parede `#`, o tile de borda daquele lado não é usado; a peça aberta é a interseção com a parede seguinte. Isso vale para as quatro direções.
4. **Cantos continuam com os 4 cantos do 3×3**; pontas de 3 lados ainda não têm peça na folha (ficam para a próxima extração).
5. **Aplicar no jogo e no laboratório**, com a mesma função de máscara. A câmera 2,3×, 48 px, combate, movimento e colisão não mudam.
6. As melhorias 1–10 da lista anterior são o plano; esta decisão cobre a escolha de tiles e será complementada pelas ferramentas (overlay, matriz, validação, padding, bioma/decals).

## Estado

Implementado (D-354): o bloco 3×3 é uma **massa de parede** (linha 1 = topo, linha 2 = face; o preview da folha prova a composição). A seleção é por **assinatura de lado medida** (`N/S/W/E`) e usa as peças reais: núcleo para 1 lado, `wall_strip_v` C3R4 / `wall_strip_h` C4R3 para lados opostos, cantos do núcleo para 2 adjacentes, `wall_tip_*` para 3, `wall_island` para 4 e `wall_cross` para interseção. O atlas ativo tem **30 tiles reais**, sem síntese; os centros Wall Alt. 1/2 entram só como variação de interior em 10% (D-355). A strip C3R4 só entra em parede de dois lados (borda do mapa ou parede fina), nunca em todo lado. Ainda faltam: occluder por célula (D-355 fez por face), pass dos 16 no jogo, padding e 3 biomas/decals. Nada foi commitado ou publicado.
