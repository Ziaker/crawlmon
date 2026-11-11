# D-1167 — Ficha de personagem no protótipo da matriz

- **Data:** 2026-11-11
- **Área:** Protótipo / ferramenta de criação de personagem.
- **Origem:** o criador pediu para evoluir a matriz para uma ficha de personagem visualmente divertida.
- **Estado:** implementado no protótipo; nenhum arquivo do jogo alterado.

## Declaração literal do criador

> "vamos melhorar o affinity matrix para poder criar uma ficha boa de personagem de forma visualmente divertida"

Escopo escolhido pelo criador: **afinidades + atributos + nature**.

## Regra aprovada

1. A matriz ganhou uma terceira visão: **Ficha** (ao lado de "Por elemento" e "Por personagem").
2. A ficha mostra, para um personagem por vez, em **duas colunas**:
   - **ÍCONE** — dois assets separados: **ícone** (256 px) e **render** (1024 px), ambos com upload; o ícone pode receber o fundo ciano→verde dos Pokémon;
   - **ELEMENTS** — os 12 elementos, até **2** marcados;
   - **NATURE** — as 8 natures do jogo com os modificadores;
   - **ATTRIBUTES** — os 6 atributos, base de nível 1, orçamento de **15 pontos**;
   - **AFFINITIES** — os 12 elementos em 6×2;
   - **MOVES** — os moves que já existem no jogo, até **8** marcados, com filtro.
3. **Atributos:** base 0–10 por atributo, editável por `−`/`+`. O total é comparado com 15 e o selo fica verde em 15/15 e coral fora disso. Os modificadores da nature aparecem ao lado do valor base, sem alterar a base.
4. **Afinidades:** clicar no tile alterna **N → W → R → N**, com as cores coral/azul e animação de pop.
5. **Nature:** clicar troca a nature do personagem; os modificadores de todos os atributos são recalculados na hora.
6. **Navegação:** uma faixa com todos os personagens ativos permite trocar a ficha sem sair da visão.
7. **Persistência:** ficha, nature, atributos, elementos e moves ficam no `localStorage` e vão para o JSON exportado.
8. **Elementos:** até 2 por personagem; um terceiro clique é recusado com aviso. Os 6 implementados vêm com os elementos atuais do `Combatant.get_elements()`.
9. **Moves:** lista com os 38 moves de `content/moves/*/move.tres` (nome, elemento, tipo, ATB e MP). O loadout atual dos 6 implementados vem de `loadout.tres`; máximo de 8.
10. Nada de itens ou level entram nesta rodada.
11. **Uploads:** aceita até **4 MB** por arquivo; a imagem é redimensionada no navegador (ícone 256 px, render 1024 px) e salva em WebP para caber no `localStorage`.
12. **Fundo Pokémon:** uma chave por personagem aplica o degradê ciano→verde atrás de ícones com transparência (o mesmo dos retratos Pokémon).
13. **Visual:** o editor recebeu a linguagem do jogo — barra bicolor lima/coral no topo da página, do card e do modal, marcador lateral nos títulos de seção, tiles de afinidade inclinados e os elementos do personagem como badges parallelogram ao lado do nome.

## Dados usados

- Os 6 personagens que já existem no jogo vêm com a **alocação real de 15 pontos** lida dos `species.tres`:
  - Abra 1/5/1/2/4/2 · Pancham 4/2/3/2/2/2 · Gible 4/2/2/2/2/3
  - Slime 3/2/2/2/3/3 · Orc 4/1/4/1/2/3 · Cyclops 5/1/3/1/2/3
- Os outros 10 começam em 0 e o criador preenche na ficha.
- Natures e modificadores vêm de `scripts/data/nature_data.gd` (D-393).

## Exportação

Cada personagem no JSON agora tem, além de `affinities`/`weak`/`resist`:

- `nature`: id da nature (`hardy`…`adamant`);
- `stats`: base dos 6 atributos;
- `elements`: lista de até 2 ids de elemento;
- `moves`: lista de até 8 ids de move;
- `iconData` / `renderData`: imagens em WebP (data URL), quando enviadas;
- `iconBg`: `true` quando o fundo Pokémon está ligado.

A importação aceita esses campos; `portraitData` de JSON antigo é lido como `iconData`. JSON antigo sem eles cai nos padrões.

## O que não foi feito

- Itens e level não entram na ficha.
- O protótipo não valida se a soma fecha 15; só avisa pela cor do selo.
- Nada de commit/push (D-022).
