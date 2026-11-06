# D-325 — Usar assets 2D de Pokémon Mystery Dungeon (Explorers) no jogo

- **Data:** 2026-11-05
- **Área:** Visual / assets / exploração
- **Origem:** Conversa (depois do brainstorm do hub e da página do The Spriters Resource)

## O que o criador disse (literal)

> iremos usar ambas dungeons, backgrounds e sprites de itens e outras coisas (pokemons não ainda)

## Decisão

1. Fica autorizado usar assets 2D das páginas de **Pokémon Mystery Dungeon: Explorers of Time / Darkness** e **Explorers of Sky** do The Spriters Resource.
2. As categorias autorizadas são: **dungeons** (tilesets/backgrounds), **backgrounds** (vila, guilda, base, dojo, café, praia, etc.), **sprites de itens** e **outros assets não-Pokémon** (UI, murais, fundos de menu, céus, estátuas, props, fontes, mapa).
3. **Pokémon do site ficam de fora por ora**: não importar sprites, retratos ou map sprites de Pokémon daquelas páginas. Os sprites/retratos de Pokémon que o projeto já tem continuam sendo usados.
4. Esta decisão **relaxa a D-313** apenas para esses assets não-Pokémon: eles podem ser importados, mesmo não sendo os sprites overworld existentes. A D-313 continua valendo no restante, inclusive a proibição de sombra elíptica sob as entidades sem nova autorização.
5. A batalha 3D e o escopo da D-319 **não mudam**: o Gible fixo continua; nada de combate, Moves ou VFX de combate por esta decisão.
6. Qualquer VFX novo segue a D-308 e o protocolo obrigatório de VFX.

## O que já foi verificado

- A página de **Time/Darkness** tem **Treasure Town** (mapa completo de 1157×985), **Guild 1F/2F/3F & Outside**, **Base Camp**, **The Crossroads**, **Marowak's Dojo**, **Sharpedo Bluff**, **Beach & Path to Beach**, **Jail**, além dos backgrounds de dungeon.
- A página de **Sky** tem **Dungeon Tiles** modulares (por exemplo, **Barren Valley**, 691×770), com legenda de paredes/chão/água; os tiles são de ~24 px. Também tem **Spinda Cafe**, **Secret Bazaar**, **Boards & Wanted Posters**, **Menu Backgrounds**, **Skies**, **Statues**, **Dungeon Title Font** e outros.
- A Treasure Town é um **mapa completo**, não um tileset modular. Os Dungeon Tiles do Sky são **tilesets modulares**, próprios para montar andares procedurais.

## Ambiguidades em aberto

- **"Ambas"**: são as duas páginas (Time/Darkness e Sky)? A decisão acima assume que sim; confirmar.
- **Importação direta ou referência?** A frase "usar" foi lida como importar os arquivos para o projeto; confirmar.
- **Dungeons**: manter a geração procedural (GDD R7-Q5) e **skin** com os tilesets do Sky, ou usar os backgrounds de dungeon como mapas completos? A primeira preserva a geração; a segunda perde.
- **Escala**: os tiles do PMD são de ~24 px e o jogo usa 48 px. Escalar 2× (nearest-neighbor) para 48 px, ou mudar o jogo para 24 px? Recomendação pendente de teste visual.
- **Personagens**: os sprites de Pokémon atuais são de ~32 px; com tiles de 48 px, a proporção do PMD (personagem maior que o tile) muda. Definir a escala dos personagens no hub e na dungeon.
- **Quais "outras coisas"**: UI, fontes, fundos de menu, céus, estátuas, murais, mapa, itens. A lista exata fica pendente.
- **Créditos/proveniência**: registrar fonte, autor do rip e URL em um manifesto de assets e em `docs/CREDITOS_ASSETS.md` (a criar).
- **Onde os arquivos ficam**: proposta `assets/pmd/hub/`, `assets/pmd/dungeons/`, `assets/pmd/items/`, `assets/pmd/ui/`, `assets/pmd/props/`.

## Atualização (D-326)

- Ordem definida: **Time/Darkness primeiro; Sky depois**.
- Dungeons: **tilesets modulares**, com a geração procedural preservada.
- Escala: **24 px por tile por ora**.

## Estado no código

Nada importado para o projeto. Nenhum código, cena ou VFX foi alterado. As imagens vistas até agora foram baixadas apenas para uma pasta temporária, para inspeção.
