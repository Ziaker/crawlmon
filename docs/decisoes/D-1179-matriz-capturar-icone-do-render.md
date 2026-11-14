# D-1179 — Matriz de afinidades: capturar o ícone a partir de um render (= ícone/arte 2D do monstro)

- **Data:** 2026-11-11
- **Área:** Protótipo / ferramenta de cadastro de personagem (`prototypes/affinity_matrix.html`).
- **Relacionadas:** D-1167 (Ícone 256 px e Render 1024 px na ficha), D-1177 (QoL), D-1178 (visual do jogo), D-1163 (cadastro oficial).
- **Estado:** implementado no protótipo; aguardando aprovação visual. Nenhum arquivo do jogo alterado.

## Declarações literais do criador

> "no matrix, adicione a opção de escolher tirar uma captura do render trazido pra usar de icone"

> "com render eu digo o icone dos monstros, não o modelo deles"

**Correção:** "render" é a **arte 2D do monstro** (os `Sprite_MonsterIcon` do Tact, ~128 px, e as variantes por forma da biblioteca do jogo). **Não** é o modelo 3D. Os 1.020 renders de QA em 512 px com fundo cinza (`render_*.png` em `sugimori/dqt/`) foram um erro de interpretação e **não são a origem** desta função.

Contexto: os ícones foram trazidos do Tact para `sugimori/dqt/<monstro>/icone_*.png` (777 arquivos, 540 pastas).

## Decisão

1. Na ficha, seção **ÍCONE**, o botão **Capturar do render** abre um editor de captura.
2. A **galeria** lista os ícones/arte 2D dos monstros de `sugimori/dqt/` (busca por nome; já começa filtrada pelo nome do personagem).
3. O editor mostra a arte e um **quadro quadrado**: arrastar move, roda do mouse ou controle muda o tamanho. **Auto-enquadrar** centraliza no personagem (pelo canal alfa); **Centralizar** volta ao meio.
4. **Remover fundo liso** (com tolerância) fica disponível para imagens com fundo opaco liso; nos ícones com transparência fica desligado. Prévia em 256, 64 e 36 px, com e sem o fundo Pokémon.
5. **Usar como ícone** grava a captura em 256 px (WebP) em `iconData`, como o upload atual. Vale desfazer (`Ctrl+Z`). O JSON continua `crawlmon.affinities.v1`, sem campo novo.
6. Outras origens: o **render já enviado na ficha** e **Arquivo…** (qualquer imagem do computador).

## Limite técnico (não é escolha)

O navegador não deixa exportar pixels de imagem lida de `file://` (canvas contaminado). A galeria só funciona com a matriz aberta por servidor local (ex.: `python -m http.server` na raiz do projeto e abrir `http://localhost:PORTA/prototypes/affinity_matrix.html`). Abrindo o arquivo direto, valem **Arquivo…** e **Render da ficha**; a galeria mostra o aviso e o comando.

## Escolhas do assistente (não ditas pelo criador)

- Quadro quadrado fixo (o ícone da ficha é quadrado, 256 px); como a arte tem ~128 px, a saída de 256 px é ampliada.
- A galeria lista só `icone_*` (sem os renders de QA 3D).
- O arquivo único (`affinity_matrix_standalone.html`) não embute a galeria (as imagens ficam fora do arquivo); lá valem arquivo e render da ficha.
- Os renders de QA 3D continuam em `sugimori/dqt/` sem uso; apagá-los é decisão do criador.

## O que não muda

- Dados, regras, JSON e atalhos. Nada de commit/push (D-022).
