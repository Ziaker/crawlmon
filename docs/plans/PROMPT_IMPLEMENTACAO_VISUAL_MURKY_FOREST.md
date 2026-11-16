# Prompt de implementação visual da Murky Forest

Construa do zero **um único mapa autoral da Murky Forest, sem geração procedural**, conforme [D-1256](../decisoes/D-1256-murky-forest-mapa-autoral-tres-referencias.md). Integre as três pranchas abaixo em um percurso contínuo. A entrega é a cena Godot funcional, com prova visual e validação de navegação e câmera no debug de exploração. A sensação de mata ampla vem das linhas de visão, da profundidade e de quanto se enxerga além do chão caminhável.

**Direção aprovada:** as três referências convivem no mesmo mapa. Adapte cada tratamento ao trecho em que melhor comunica a rota e faça as transições parecerem parte da mesma floresta. Antes de fechar a planta, mostre onde cada tratamento entra e quais decisões de layout seguem em aberto.

## Referências visuais obrigatórias

Abra **as três imagens completas** em um visualizador de imagens. Confira a composição principal e cada painel de sala. Os nomes, descrições e miniaturas servem para localizar as pranchas. A referência visual é o PNG completo.

| Referência | Prancha | Tratamento a integrar ao mapa |
| --- | --- | --- |
| 1 | [Aberturas na copa](../referencias/exploracao/3d/murky-forest-v2-opcao-1-copa.png) | Abrir a vista acima da paliçada na curva. Silhuetas de troncos e copas ao fundo dão profundidade. O arco aparece à frente. |
| 2 | [Vistas laterais entre troncos](../referencias/exploracao/3d/murky-forest-v2-opcao-2-vistas-laterais.png) | Revelar a mata lateralmente entre troncos e trechos de paliçada. O arco entra e sai do enquadramento conforme o jogador percorre a curva. |
| 3 | [Desnível cenográfico](../referencias/exploracao/3d/murky-forest-v2-opcao-3-desnivel.png) | Abrir uma vista controlada sobre uma camada baixa de mata. O piso violeta continua no mesmo nível jogável e o arco orienta a passagem. |

Na abertura do trabalho, cite os três arquivos e relacione o que você observou em **todos os quatro painéis de cada prancha** aos pontos do novo percurso. Na entrega, compare cada região com as pranchas que a informaram e explique divergências identificáveis na câmera real. As pranchas antigas de clareiras, lago e raízes servem como histórico. *Trials of Mana* é inspiração para revelar profundidade aos poucos. A linguagem visual vem das pranchas revisadas e do cenário real do Crawlmon.

### Fontes reais a abrir junto com as pranchas

- [Cena da Murky Forest](../../scenes/debug/murky_forest_3d_lab.tscn) e [script do cenário](../../scripts/debug/murky_forest_3d_lab.gd). Inspecione a geometria, os materiais, a colisão, a navegação, a copa, a folhagem, a iluminação e a composição de cada sala.
- [Câmera, movimento e carregamento dos modelos](../../scripts/debug/third_person_3d_lab.gd). Identifique os modelos locais pelos IDs usados na cena, inclusive Gible, Cyclops e Orc. Use as instâncias existentes como referência de silhueta e escala.
- [Textura base da paliçada](../../assets/textures/walls/murky_wall_root_palisade.png), suas variantes `v1` a `v5` listadas no script do cenário e [shader de transição das paredes](../../shaders/wall_palisade_blend.gdshader).
- Capturas de referência do jogo real: [corredor](../referencias/exploracao/3d/murky_forest_npcs_corredor.png), [Gible](../referencias/exploracao/3d/diag_enemy_gible_side.png), [ala sul](../referencias/exploracao/3d/d1143_rooms_contact.png) e [Amuleto com Bolha de Relíquia](../referencias/exploracao/3d/d1158_item_bubble_amulet.png). Use as capturas para conferir escala, materiais, personagens e props. Para posições e ocupantes, confira a versão atual da cena.

## Escopo da implementação

- Desenhe a planta do mapa autoral. Use o corredor em L, a sala do Gible e a ala sul com Cyclops e Amuleto, Super Poção e Orc (D-1133 e D-1151) como referências para a identidade, os papéis das salas e a leitura do percurso. A posição, a planta e as conexões vêm do layout novo a ser definido. O arco de pedra continua como marco de revisita.
- Traduza as três pranchas para o percurso, da entrada à volta pelo arco. Use o kit visual atual como base: piso violeta fosco, paliçada verde-escura texturizada, troncos simples, copa facetada, vegetação de borda e penumbra com preenchimento discreto (D-1028, D-1082, D-1083 e D-1116–D-1122). Use a paleta e a escala observadas na cena. Qualquer novo ajuste de cor, escala ou disposição que dependa de gosto do criador deve ser apresentado como opção para decisão.
- Posicione volumes e vegetação de fundo que sugiram continuidade além da rota. O desnível é cenário e fica fora da navegação. Mantenha a leitura dos limites perto das vistas laterais. Confira se as portas reais se destacam das aberturas cenográficas, se as três soluções têm transições coerentes e se o arco é reconhecível na ida e na volta.
- Use o critério de medição das portas de D-1245 se o trabalho encontrar um problema de passagem. A medição precede qualquer ajuste. Mantenha o retorno à floresta conforme D-1246–D-1248, com o arco como marco e a segunda visita como descoberta opcional. Mudanças de áudio, economia, combate, encontros, decoração como fonte de loot, novos níveis jogáveis e conteúdo dos eventos estão fora deste escopo visual.
- Separe os elementos cenográficos da colisão e do minimapa jogável. Use o renderizador e a câmera reais do projeto. Compare o comportamento da câmera e o desempenho com a cena de partida antes de acrescentar camadas ou luzes.

## Sequência de trabalho e validação

1. Leia `AGENTS.md`, o [plano de level design](2026-11-16-murky-forest-level-design.md), as decisões aplicáveis e [TELEMETRIA.md](../TELEMETRIA.md). Faça capturas da versão atual no debug de exploração com a câmera real. Marque entrada, curva do L, sala do Gible, cada acesso ao sul e a vista em direção ao arco.
2. Faça o blockout do mapa autoral com os três tratamentos no mesmo percurso. Teste a silhueta das massas, as linhas de visão e a diferença entre passagem jogável e vista de fundo. Confira o percurso nos dois sentidos, solo e com aliados, com a rotação normal da câmera.
3. Integre o acabamento nos trechos e nas transições entre eles. Ajuste copa, paliçada, fundo, distribuição de folhagem, iluminação e marco em conjunto. Mantenha a legibilidade de personagens, bolhas de item e entradas nas áreas de penumbra.
4. Rode o debug de exploração conforme D-1204. Consulte no código se `MF_LAYOUT_WALK` e `MF_LAYOUT_SHOT` do plano já existem antes de usá-los. Se faltarem e forem necessários, siga a divisão de trabalho do `AGENTS.md` para criar a validação. Verifique passagem das portas, oclusão e colisão da câmera, navegação dos aliados, coerência do minimapa e que o fundo cenográfico não é tratado como caminho. Faça as capturas em escala real e sob as mesmas posições de câmera do antes.
5. Entregue comparação **referência / antes / depois** para os três tratamentos e para os equivalentes da entrada, transição principal, cômodo do Gible, Cyclops e Amuleto, sala da Super Poção, sala do Orc e aproximação/retorno do arco. Compare enquadramentos funcionalmente equivalentes onde a planta nova mudar posições. Inclua comandos e resultados, divergências visuais, áreas ainda sem evidência e o que cabe a Codex ou DeepSeek conforme `AGENTS.md`. A direção de arte, as malhas e o acabamento visual são trabalho direto do agente visual. A lógica e os testes novos seguem o fluxo de DeepSeek previsto no projeto.

O trabalho está completo quando os três tratamentos aparecem num único percurso autoral coerente, se vê uma floresta maior ao redor da rota e as salas do mapa novo são legíveis e percorríveis no enquadramento real do Crawlmon. Cada diferença visual substancial em relação às pranchas precisa estar documentada para revisão.
