# D-274 — Proposta: evoluir o laboratório de VFX para um compositor de efeitos completos em camadas (PENDENTE, NÃO APROVADA)

- **Data:** 2026-11-05
- **Área:** VFX / Laboratório / Motion Composer
- **Origem:** o criador colou na conversa o texto de uma proposta (escrita por outra sessão do assistente) e, perguntado o que fazer com ela, escolheu **"Registrar como decisão"**.
- **Estado:** **PROPOSTA registrada.** Em 2026-11-05 o criador autorizou **iniciar pelas ferramentas de percepção (item 6)**; os demais itens não estão aprovados. Nenhum Move, asset ou efeito existente foi alterado.

## O que o criador disse

> (colou a proposta abaixo, sem frase própria)
> Registrar como decisão *(resposta à pergunta "o que você quer que eu faça com ela?")*

Registrar a proposta **não equivale a aprová-la**: ela entra como "pendente de aprovação", item a item.

## Decisões citadas pela proposta

D-003, D-019, D-020, D-042–D-046, D-235 e D-300–D-306. **D-300–D-306 não existem neste checkout nem no GitHub (último é D-268)**; só foram citadas pelo texto colado e **não foram verificadas aqui**. D-235 (Moves/VFX independentes de personagem, equipe e lado) vale integralmente para tudo abaixo.

## Texto da proposta (como colado)

**Minha proposta é evoluir o laboratório para um compositor de efeitos completos:** combinar movimento, geometria, material, partículas e acabamento em camadas editáveis. O Motion Composer seria a base de movimento dessa ferramenta.

O ganho de qualidade viria principalmente de **silhuetas claras, materiais convincentes, movimentos característicos de cada elemento e bom controle do nascimento e da dissipação**.

### 1. Receitas visuais com camadas especializadas

Cada efeito poderia reunir camadas com funções distintas:

| Camada | Função | Exemplo em fogo |
|---|---|---|
| Corpo principal | Define volume e silhueta | Massa de chama deformável |
| Movimento secundário | Acrescenta variação | Línguas de fogo que se desprendem |
| Partículas | Mostra direção e escala | Brasas |
| Rastro | Comunica deslocamento | Fogo que se estreita e apaga |
| Contato | Liga o efeito à superfície | Chamas se espalhando lateralmente |
| Resíduo | Dá continuidade à dissipação | Fumaça e cinzas |

Cada camada teria sua própria representação. Uma receita poderia misturar uma malha deformada, duas fitas, partículas e um flipbook.

Na interface: **grupos de camadas, duplicação, solo, visibilidade, curvas e presets de componentes**. As camadas ordenadas já aprovadas continuariam sendo a organização principal.

### 2. Uma linguagem de movimento para cada elemento

| Elemento | Comportamento visual | Técnicas propostas |
|---|---|---|
| **Fogo** | Sobe, alonga, rompe e perde intensidade | Malhas afiladas deformáveis, ruído direcionado, erosão da silhueta, brasas e fumaça |
| **Água** | Mantém continuidade, estica, forma lâminas e se fragmenta em gotas | Tubos curvos, folhas de água, mapas de fluxo, espuma e gotas balísticas |
| **Terra** | Acumula tensão, rompe em blocos e perde velocidade com peso aparente | Malhas fragmentadas, emergência progressiva, rotação de detritos, poeira localizada |
| **Ar** | Acelera, curva, arrasta e deixa espaços vazios | Fitas afiladas, arcos descontínuos, campos de vórtice e partículas que revelam o fluxo |

As hélices seriam uma possibilidade dentro dessas linguagens (fogo que torce ao subir; água que envolve um jato; terra em coluna de fragmentos; ar em vórtice).

### 3. Controles artísticos que escondem a complexidade

Poucos controles principais na primeira tela; parâmetros técnicos em seção avançada:

- **Fogo:** intensidade visual, alongamento, fragmentação, turbulência, brasas e fumaça.
- **Água:** coesão, espessura, ondulação, espuma, dispersão e tamanho das gotas.
- **Terra:** tamanho dos blocos, irregularidade, dispersão, rotação e poeira.
- **Ar:** concentração, curvatura, torção, intermitência e quantidade de partículas.

Um controle como "fragmentação do fogo" ajustaria conjuntamente erosão do material, separação das pontas e emissão de pequenas chamas; essas relações seriam editáveis e salvas no preset.

**Os controles alterariam a aparência, sem mudar dano, alcance lógico ou duração do ataque.**

### 4. Ferramentas de geometria e materiais reutilizáveis

Seis geradores de forma: **fita, tubo curvo, arco, casca, lâmina e conjunto de fragmentos**, todos recebendo o movimento do compositor, com largura, espessura e deformação variando ao longo do efeito.

Biblioteca pequena de funções de material combináveis: **erosão**, **fluxo de textura**, **gradientes por idade**, **deformação de vértices**, **flipbooks** e **espuma e bordas**.

Bases reaproveitáveis em `VfxLib`: carregamento de malhas e texturas, flipbooks, materiais, partículas e cortes. Os shaders de fogo existentes seriam candidatos a componentes, após verificar seus contratos de tempo.

Para GL Compatibility: malhas de superfície para marcas no chão, com adaptação ao terreno quando necessária (a documentação de Godot 4.7 informa que decals nativos não estão disponíveis nesse renderizador).

### 5. Campos de movimento combináveis

| Campo | Utilidade |
|---|---|
| Fluxo direcional | Jatos, rajadas e chuva de fragmentos |
| Vórtice | Redemoinhos e chamas espiraladas |
| Atração/repulsão | Concentração de energia e expansão |
| Turbulência coerente | Variação orgânica contínua |
| Arrasto | Redução gradual de velocidade |
| Gravidade visual | Queda de gotas e detritos |

Cada campo teria região de influência, intensidade e máscara. Qualquer interação com superfícies seria **decorativa**: o VFX não decidiria acertos nem colisões do combate.

### 6. Um laboratório que facilite avaliar qualidade

Comparação A/B sincronizada com a mesma semente; visualização isolada de silhueta, material, partículas e rastros; fundos claros e escuros e iluminação semelhante à batalha; prévia com emissores móveis, diferentes tamanhos de personagem e posições espelhadas; captura automática de nascimento, desenvolvimento, contato e dissipação; indicadores de amostras visíveis, triângulos, custo de avaliação e envio ao desenho; avisos de excesso de transparências sobrepostas.

A medição precisaria primeiro incorporar a correção identificada na auditoria: **avaliar o desenho em estados efetivamente visíveis**.

### 7. Melhorias de desempenho que preservam a edição

A investigar antes de aumentar a densidade: cache de histórico; invalidação por dependência; amostragem adaptativa; reutilização de buffers e instâncias; detalhamento por tamanho na tela; pré-cálculo opcional de partes determinísticas. O cache precisa continuar correto ao voltar no tempo, editar camadas ou mover o emissor. Exigem medição; não há ganho antecipado.

### Início sugerido

**Quatro receitas de referência:** uma chama projetada, um jato com respingo, uma erupção de fragmentos e uma rajada curva.

Toda a prévia receberia um tempo explícito; na futura integração, esse tempo e os eventos viriam do combate (D-019); origem, direção e escala seriam derivadas dos participantes reais (D-235).

**Esta é uma proposta de evolução, sem implementação ou substituição dos efeitos existentes.** A compatibilidade visual e o desempenho das novas técnicas ainda precisariam ser demonstrados no laboratório.

## Autorização para iniciar (2026-11-05)

Perguntado por onde iniciar e onde o trabalho deve viver, o criador respondeu:

> vou com o que vc recomenda mais, mas se for pra criar mais ferramentas que melhoram sua capacidade de percepção e criação desses efeitos, então siga com elas primeiro, use as skills, superskills de shader e 3D do godot que vc tem

> *(escopo)* Lab + componentes no jogo

**Decisão:** iniciar pelas **ferramentas de percepção e criação** (item 6 da proposta: avaliar qualidade de um efeito por captura, A/B com mesma semente, vistas isoladas, espelhamento), antes de geradores, materiais ou receitas. O trabalho pode viver no laboratório (`tests/`) **e** em componentes reutilizáveis em `scripts/`, **sem substituir nem alterar nenhum efeito existente** e sem tocar em dano, alcance, duração ou acerto. Os demais itens (1–5, 7) seguem **não aprovados**.

**Observação verificada:** o Motion Composer V1 versionado tem a biblioteca de comportamentos (`scripts/motion_composer/`), mas **não tem o laboratório visual** (a cena `motion_lab` só existe em `scratch/`, ignorado pelo Git). O `tests/fx_lab/` existente é um palco com efeitos candidatos do Abra, não um compositor.

## Regras que continuam valendo (não são propostas)

- Os controles artísticos e os campos **só mudam a aparência**: nunca dano, alcance lógico, duração do ataque, acerto ou colisão (a própria proposta afirma isso).
- **D-235 / AGENTS §7:** nada de personagem, time, lado, coordenadas fixas ou direção de câmera fixa; teste espelhado obrigatório.
- Os efeitos existentes **não são substituídos** por esta proposta.

## Ambiguidades em aberto (perguntar antes de agir)

- **Quais dos 7 itens o criador aprova**, em que ordem, e se as 4 receitas de referência são o ponto de partida.
- Relação com o **Motion Composer** já commitado (D-230–D-233: comportamentos M01–M18, composição espacial) e com as **camadas ordenadas já aprovadas** (que decisões exatamente? a proposta cita D-042–D-046 e D-300–D-306, não encontradas aqui).
- Se esta proposta é **trabalho para a ferramenta de laboratório** (`tests/fx_lab`) ou para o **jogo**; se algo entra no código de combate (`VfxLib`, `BattleFx`).
- Se "avaliar o desenho em estados efetivamente visíveis" (correção da auditoria) é pré-requisito aprovado.
- Se o número **D-274** deve ser mantido (a sessão de origem usa D-300–D-306, que não existem aqui; risco de nova colisão de numeração).

## Estado no código

**Item 6, primeira parte (2026-11-05):** criadas as ferramentas de percepção: `scripts/vfx/perception/vfx_perception.gd`, `tests/fx_lab/perception/` e `docs/vfx/PERCEPTION_TOOLS.md`. Verificadas em 8 variantes (4 layouts, 2 tamanhos de alvo) com repetibilidade 0,0. Nenhum efeito, Move ou regra existente foi alterado. Itens 1–5 e 7 seguem não iniciados.
