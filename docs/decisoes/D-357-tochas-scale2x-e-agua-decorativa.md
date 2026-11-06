# D-357 — Tochas visíveis removidas, atlas em Scale2x e água decorativa adiada

- **Data:** 2026-11-06
- **Área:** Exploração / visual / tiles
- **Origem:** O criador pediu para remover as tochas estranhas e melhorar a resolução dos mapas; sobre a água, respondeu “Decorativa por ora”.

## O que o criador disse (literal)

> 3 - tem como remover essas tochas estranhas e melhorar a resolução dos mapas?
>
> 1 Decorativa por ora
>
> 2 - nao é necessário

## Decisão

1. **Tochas visíveis removidas.** O desenho da chama, o cabo e as brasas saíram do `map_visuals.gd`. A `PointLight2D` continua no mesmo lugar como **luz invisível**, para a sala não escurecer. O jogo não muda colisão, câmera, 48 px ou geração.
2. **Atlas em Scale2x.** A fonte das folhas é 24×24; não existe versão nativa maior. O atlas 48×48 agora usa **Scale2x/EPX** (2×) em vez de nearest: suaviza as bordas sem o borrão do Lanczos. As 16 folhas foram regeradas na versão 3.0.0; a câmera 2,3×, o tamanho de 48 px e a geração procedural não mudam.
3. **Água decorativa adiada.** O bloco `Water` do Temporal Tower é **cinza-escuro** (o centro C25R1 lê como o próprio chão); nas folhas de gelo a água é azul. Adicionar um `water_c` ao atlas/profiler e um patch no laboratório criaria 31 tiles para um efeito que quase não aparece no bioma ativo. Antes de fazer, o criador precisa escolher:
   - usar a **água azul das folhas de gelo** como decoração mesmo no Temporal;
   - ou fazer um **shader de água** próprio;
   - ou manter a água fora por ora.
   Nada de água entrou no atlas, no jogo ou no laboratório.

## Estado

Implementado: tochas visuais e brasas removidas; atlas 16× em Scale2x (versão 3.0.0); 16 capturas in-game e contato `docs/referencias/tilesets/biomes_ingame_contact.png`; golden 0,60/0,61; brilho do piso −0,7% a −2,1% (OK); 6.970 células de parede / 0 divergências; fallback murky_forest 688/0; decals 8,1% / 0 adjacentes. O gate do Temporal continua aprovado (30 tiles, Wall Alt. 5+5%). A água decorativa segue **pendente de escolha visual**. Nada foi publicado.
