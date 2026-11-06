# D-327 — O Composer precisa de MODELOS 3D dos objetos elementais, não só formas procedurais e texturas

- **Data:** 2026-11-05
- **Área:** VFX / Motion Composer
- **Origem:** reprovação do criador da galeria da V1.2 (D-323).
- **Estado:** registrada; **nenhum código escrito depois dela**; origem dos modelos em aberto.

## Frase literal do criador

> são apenas texturas, não malhas nem modelos em 3D de objetos correspondentes aos efeitos especiais elementais, não tem como aceitar

## Decisão

1. A galeria da V1.2 (D-323) **não é aceita**. As formas dela são geradas por código (tubos, fitas, cascas) e pintadas por shaders; o criador quer **malhas/modelos 3D de objetos** que correspondam a cada efeito elemental (por exemplo: chama, bola de fogo, jato e coroa de água, pedras e colunas de terra, redemoinho de ar), e não apenas texturas e formas procedurais.
2. O Composer deve passar a **usar modelos 3D autorais como representação**, movidos pelos comportamentos (M01–M25) e acabados pelos looks por elemento (D-323: estilizado, bandas duras).
3. Continuam valendo D-322 (refazer os 4 do zero, um por vez, com aprovação), D-323 item 2 (nenhum efeito é mexido antes do Composer ficar bom), D-308, D-235, D-019.

## Resposta do criador (2026-11-05, em seguida)

> ambos modelagem e biblioteca gratuita só pra eu checar uma coisa

**Decisão:** produzir os modelos dos dois jeitos para o criador comparar: (a) **modelados no Blender** e (b) **de biblioteca gratuita** (com licença verificada). O criador não disse o que vai checar; começo com **um objeto por elemento em cada fonte** (fogo, água, terra, ar), mostrados em imagem, antes de integrar qualquer coisa ao Composer.

## Ambiguidades em aberto

- O que exatamente o criador quer checar (qualidade, estilo, contagem de polígonos, licença).
- Quais objetos por elemento (presumo: chama/bola de fogo, coroa/jato de água, pedra/coluna de terra, redemoinho de vento).

## Estado (2026-11-05)

**Primeiro lote modelado no Blender** (malhas reais, low-poly facetado, materiais simples por cor): `assets/vfx/elements/EL_fire_flame.glb` (739 faces), `EL_water_splash.glb` (1502), `EL_earth_rocks.glb` (153), `EL_air_vortex.glb` (486). Ainda **não integrados ao Composer** nem ao jogo (aguardam o criador ver as imagens).
**Biblioteca gratuita: não feita.** As bibliotecas do addon do Blender (Poly Haven, Sketchfab, Poly Pizza) estão **desligadas** (`libraries: off`); precisam ser ligadas nas preferências do addon (Sketchfab exige chave de API).
**Não verificado:** como os modelos ficam dentro do Godot (importação, escala, acabamento estilizado) e a aprovação artística.

## Rodada de comparação (2026-11-05)

Criador: "apenas pedra e vento tão decentinhas, o resto tá péssimo, gere por IA também e também pegue as bibliotecas pra comparacao". **Pedra e vento aprovados como "decentinhas"; fogo e água reprovados.**

- **Biblioteca:** só a **Poly Haven** pôde ser ligada (sem chave). Só tem objetos fotorrealistas: achei rochas, mas **nada de chama, respingo de água ou redemoinho** (busca por fogo/água/vento devolveu extintor, hidrante, regador). Importada para comparação a **Boulder 01** (CC0, Rico Cilliers): **66.122 faces**, textura fotográfica, estilo incompatível com o jogo. Poly Pizza e Sketchfab pedem chave de API (`polypizza_api_key`, `sketchfab_api_key`) e continuam desligados.
- **IA:** **não gerado.** Os quatro geradores (Tripo, Hunyuan3D, Hyper3D, Meshy) estão sem chave de API; chave não é algo que eu possa colocar (regra de segurança). Precisa que o criador coloque as chaves nas preferências do addon, ou outro caminho.
- Fogo e água do Blender precisam ser refeitos (ainda não feito).

## Fogo e água refeitos à mão (2026-11-05)

Criador: "Refazer à mão". **Fogo** agora é um feixe de 7 lâminas de chama curvas (casca vermelha, miolo laranja e núcleo amarelo, mais espesso para aparecer na frente): `EL_fire_flame.glb`, 1879 faces. **Água** é um respingo em coroa: 12 dedos que sobem e afinam, coluna central, 2 anéis de ondulação e 6 gotas, com 3 tons por altura e normal: `EL_water_splash.glb`, 3514 faces. Pedra (153 faces) e vento (486) ficaram como estavam, "decentinhas". Os modelos de IA e de biblioteca seguem não feitos (chaves de API). **Ainda não integrados ao Composer/Godot; aguardam a aprovação do criador.**

## Segundo ajuste de fogo e água (2026-11-05)

Criador: "Ainda ajustar"; ao perguntar o que, respondeu: forma do fogo, forma da água, cores e acabamento, mais detalhe (os quatro).
- **Fogo** (`EL_fire_flame.glb`, 7401 faces): 13 chamas em camadas (casca, miolo, núcleo), 3 delas com ponta bifurcada, bordas recortadas, base de chamas pequenas e 4 brasas flutuando; **cor por vértice** (atributo `Col`): quente e claro embaixo, vermelho na ponta.
- **Água** (`EL_water_splash.glb`, 6049 faces): coroa ondulada de parede fina com 9 picos e dedos grossos curvando para fora, coluna central de cabeça arredondada, 3 anéis de ondulação, 12 gotas em teardrop; **cor por vértice** (azul fundo, azul médio, ciano e espuma branca no alto e nas bordas).
- Pedra e vento inalterados. Todos continuam **não integrados** ao Composer/Godot.

## Fogo refeito com as skills do Blender (2026-11-05)

Criador: "fogo ainda esta pessimo use as skills". Carreguei `scenario-blender-expert` e `scenario-blender-texturing-shading` e segui o laço delas (blocagem, folha de revisão em silhueta e matcap, correção, portão de entrega).
- **Diagnóstico da versão anterior (silhueta):** lia como moita de folhas/agave (lâminas finas em leque sobre uma bola), não como fogo.
- **Nova construção:** 7 línguas grossas com a mesma curvatura de ponta (gesto único, chama ao vento), unidas por **voxel remesh** numa só massa, suavizadas e decimadas (1542 faces). Cor por vértice (`Col`): quente e claro embaixo, vermelho na ponta.
- **Portão (`bx_audit.deliverable`, perfil game):** achou 4 fragmentos flutuantes e uma parte interna; removidos; **passa sem erros** (aviso: sem UV, aceitável para cor chapada).
- **Arquivos:** `EL_fire_flame.glb` (1542 faces) e `EL_fire_ember.glb` (142 faces, uma gota de chama para o Composer espalhar).
- **Não verificado:** como fica no Godot e a aprovação artística; a cor na janela do Blender sai lavada (transformação de vista), o acabamento real vem do shader.
