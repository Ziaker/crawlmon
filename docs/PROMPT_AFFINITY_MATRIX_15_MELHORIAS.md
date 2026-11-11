# Prompt — Affinity Matrix: 15 melhorias para adicionar personagens e definir afinidades

## Papel

Você é um agente de front-end e design de sistemas trabalhando no protótipo **`prototypes/affinity_matrix.html`** do projeto Crawlmon. Sua missão é evoluir esse protótipo para que **adicionar um personagem novo e definir todas as afinidades dele** seja rápido, seguro e à prova de erro — sem tocar no jogo, sem quebrar o JSON atual e sem sair da estética do projeto.

## Contexto atual

- O protótipo é um HTML standalone (CSS e JS inline), sem dependências externas, que abre por `file://`.
- Ele tem **12 elementos**: Neutral, Fire, Water, Electric, Wind, Earth, Nature, Psychic, Sound, Light, Dark, Mystic.
- Tem **16 personagens**: Abra, Pancham, Gible, Slime, Orc, Cyclops, Bulbasaur, Charmander, Squirtle, Pikachu, Eevee, Dracky, Heal Slime, Sabrecub, Platypunk e Funghoul.
- Cada personagem × elemento tem **apenas 3 estados**: `neutral`, `weak` ou `resist`. Não implementar `null`, `repel` ou `drain`.
- Cada card de elemento mostra todos os personagens com um seletor N/W/R.
- Existe busca básica, filtros Todos/Party/Inimigos/NPCs, navegação por elemento, contadores, autosave em `localStorage`, importação/exportação JSON e preview do JSON.
- Os 5 DQT usam ícones 2D do Tact com zoom fixo por personagem (C/C/C/C/C) e fundo em degradê ciano→verde copiado do Charmander.
- O JSON atual usa `schema: "crawlmon.affinities.v1"`, com `elements`, `godotMapping`, `byElement` e `characters[].affinities/weak/resist`.
- O jogo usa `Element.Type` (0–11) e `Affinity.Type` (Neutral=0, Weak=1, Resist=2). O `godotMapping` já existe para essa conversão.

## Objetivo

Transformar a matriz em uma **ferramenta de cadastro e revisão de afinidades** para o fluxo real do projeto: sempre que um personagem novo entrar no jogo, ele é adicionado aqui, suas 12 afinidades são definidas, revisadas e exportadas. O processo deve continuar funcionando para 16 personagens e escalar para **100+**.

## Restrições obrigatórias

1. **Não alterar o jogo.** Só o protótipo e seus assets.
2. **Não commitar nem fazer push.** O criador autoriza apenas o trabalho local.
3. **Não usar bibliotecas externas, CDNs, frameworks ou servidor.** O arquivo deve continuar abrindo por `file://`.
4. **Preservar a estética atual:** fundo ink, cream, lime, coral, gold, Kanit Black Italic, painéis recortados, ícones SVG do jogo, retratos pixel-art e degradê ciano→verde dos DQT.
5. **Preservar os 16 personagens atuais, suas afinidades e os ícones DQT.**
6. **Não implementar `null`, `repel` ou `drain`.** O escopo continua Neutral/Weak/Resist.
7. **Elementos do personagem ficam para depois:** reservar o campo `elements` no schema e na UI somente como “futuro”, sem permitir edição nesta rodada. Não inventar elementos para os personagens atuais.
8. **Toda alteração de dados deve ser reversível e exportável.**
9. **Acessibilidade e teclado são requisitos, não extras.**
10. **Não quebrar a importação de JSON v1.** Migrar automaticamente para v2.

## As 15 melhorias

### 1. Cadastro guiado de personagem novo

**Problema:** hoje um personagem novo exige editar o array `CHARACTERS` no código.

**Solução:** criar o botão **“+ NOVO PERSONAGEM”** e um modal de cadastro com:
- ID estável (slug, obrigatório, único, `[a-z0-9_]+`);
- Nome de exibição;
- Papel: `player`, `party`, `ally`, `enemy`, `npc`;
- Retrato: upload local ou caminho em `personagens/portraits/`;
- Ícone DQT opcional: slug + zoom A/B/C (com preview imediato);
- Afinidade inicial: tudo `neutral` por padrão;
- Prévia do card e do avatar;
- Botões Salvar / Cancelar.

**Regras:** validar ID duplicado, nome vazio, imagem inválida e papel inválido. O personagem nasce com `isNew=true`, `reviewed=false`. Ao salvar, ele aparece em todos os 12 blocos e no JSON.

**Aceite:** criar um personagem de teste, recarregar a página e ele continuar lá; exportar e importar mantém o personagem.

### 2. Busca global de personagem

**Problema:** a busca atual é básica e não destaca resultados nem cobre ID/papel.

**Solução:** busca no topo com:
- Nome, ID e papel;
- Ignorar acentos e maiúsculas;
- Destacar o trecho encontrado;
- Contador “X de Y personagens”;
- Botão limpar;
- Atalho `/` para focar a busca;
- `Esc` limpa e devolve o foco;
- Resultados vazios com mensagem clara.

A busca deve combinar com o filtro “só novos” e com o filtro de papel usando **AND**. Cada bloco de elemento mostra apenas os personagens que passarem nos filtros.

**Aceite:** buscar “abra” mostra 1 personagem nos 12 blocos; buscar “npc” mostra os NPCs; buscar “xyz” mostra estado vazio; `/` foca o campo; `Esc` limpa.

### 3. Filtro “Só novos” + badges NEW e revisão

**Problema:** não há como saber quais personagens ainda não tiveram as afinidades revisadas.

**Solução:**
- Cada personagem tem `isNew` e `reviewed`.
- Badge **NEW** no avatar/nome enquanto `isNew` for true.
- Filtro **“SÓ NOVOS”** (chip) que mostra apenas `isNew=true`.
- Contador no chip: “Só novos (3)”.
- Ação **“Marcar como revisado”** por personagem; remove o badge e o `isNew`.
- Ação **“Marcar todos os visíveis como revisados”**.
- Estado vazio: “Nenhum personagem novo.”
- O filtro persiste em `localStorage`.
- O JSON exporta `isNew` e `reviewed` por personagem.

**Aceite:** adicionar um personagem, ele aparece com NEW e no filtro; marcar como revisado remove dos dois; recarregar mantém o estado.

### 4. Visão por personagem (além da visão por elemento)

**Problema:** a visão atual é elemento → personagens, ótima para comparar, ruim para revisar um personagem inteiro.

**Solução:** toggle **“Por elemento / Por personagem”**.
- **Por elemento:** layout atual, 12 blocos.
- **Por personagem:** um card por personagem com as 12 linhas de elemento e o seletor N/W/R em cada uma.
- O card do personagem mostra: avatar, nome, papel, NEW/REVIEWED, contagem de Weak/Resist, barra de progresso “12/12 revisados”.
- Busca, filtros e “só novos” funcionam nas duas visões.
- A visão escolhida persiste.

**Aceite:** alternar visão não perde dados; buscar um personagem na visão por personagem mostra só o card dele; o seletor funciona igual.

### 5. Edição inline do personagem

**Problema:** corrigir nome, papel, ID ou ícone exige mexer no código.

**Solução:** no card do personagem (visão por personagem) ou no modal, permitir editar:
- Nome, ID (com aviso de que muda o JSON), papel;
- Retrato (upload/caminho) e preview;
- Ícone DQT + zoom A/B/C;
- Ativo/inativo (personagem fora do roster não aparece na matriz, mas permanece no JSON com `active=false`);
- Botão “Salvar alterações” e “Cancelar”.

**Regras:** não permitir ID duplicado; se o ID mudar, migrar as afinidades e avisar; manter o histórico de undo.

### 6. Ações em massa por personagem

**Problema:** definir 12 afinidades uma por uma é lento.

**Solução:** menu de ações por personagem:
- **Tudo Neutral**;
- **Copiar afinidades de…** (outro personagem, com preview do que será sobrescrito);
- **Aplicar template** (ex.: “Fraco a Fire”, “Resistente a Water”, “Neutral”);
- **Limpar personagem** (remove do roster com confirmação);
- **Duplicar personagem** (novo ID, mesmas afinidades, `isNew=true`).

Todas as ações entram no undo/redo.

### 7. Dashboard de revisão e completude

**Problema:** não há visão de progresso do trabalho.

**Solução:** painel compacto no topo:
- Total de personagens, novos, revisados, pendentes;
- Total de Weak/Resist no roster;
- Barra de progresso “X/Y personagens revisados”;
- “Última alteração: personagem/elemento/hora”;
- Filtro “Pendentes” (não revisados);
- Alerta se houver personagem sem nenhuma afinidade definida (tudo neutral) — não bloquear, só avisar.

### 8. Baseline, diff e reverter

**Problema:** é fácil mudar algo sem perceber e não há como comparar com o estado do jogo.

**Solução:**
- Guardar um **baseline** (os defaults atuais do jogo) ao abrir pela primeira vez.
- Destacar células alteradas em relação ao baseline (borda/ícone de “alterado”).
- Modo **“Ver diff”**: mostra só personagens/elementos alterados.
- Ações **“Reverter célula”**, **“Reverter personagem”**, **“Reverter tudo para o baseline”**.
- Exportar opção **“somente diff”** (apenas alterações em relação ao baseline).
- O baseline não é sobrescrito por importação sem confirmação.

### 9. Undo/redo e autosave com recuperação

**Problema:** erros de clique são difíceis de desfazer; o autosave atual não tem histórico.

**Solução:**
- Pilha de undo/redo (mínimo 100 ações) para célula, personagem, importação e reset.
- Atalhos `Ctrl+Z` / `Ctrl+Shift+Z` (e `Cmd` no Mac).
- Indicador “Alterações não exportadas”.
- Autosave em `localStorage` com timestamp.
- Ao abrir, se houver sessão mais nova que o último export, oferecer “Recuperar sessão” ou “Começar do baseline”.
- Botão “Descartar alterações e recarregar baseline”.

### 10. Importação em lote (CSV/JSON) para novos personagens

**Problema:** adicionar vários personagens novos um por um é inviável.

**Solução:** modal **“Importar roster”**:
- Aceitar JSON no schema v1/v2 e CSV com colunas `id,name,role,portrait,dqt,dqt_zoom,elements...`.
- Prévia em tabela com validação por linha (ID duplicado, papel inválido, elemento desconhecido).
- Modo de conflito: **Ignorar existentes / Sobrescrever / Mesclar**.
- Escolher se os importados nascem `isNew=true`.
- Relatório final: “X criados, Y atualizados, Z ignorados, W erros”.
- Nada é aplicado se houver erro crítico; mostrar o relatório antes de confirmar.

### 11. Exportação JSON v2 segura

**Problema:** o export atual funciona, mas não tem versão, status de revisão, validação nem opção de diff.

**Solução:** exportar `crawlmon.affinities.v2` com:
- `schemaVersion`, `exportedAt`, `gameVersion` (texto livre/commit), `activeAffinities`;
- `elements` na ordem canônica;
- `godotMapping` com `Element.Type` e `Affinity.Type`;
- `characters[]` com `id`, `name`, `role`, `active`, `isNew`, `reviewed`, `icon`, `dqtIconZoom`, `elements` (reservado), `affinities`, `weak`, `resist`;
- `byElement`;
- `stats` (totais de weak/resist/neutral, novos, revisados);
- opções **“Exportar tudo”** e **“Exportar somente diff do baseline”**;
- validação antes de baixar: IDs únicos, 12 elementos por personagem, valores permitidos;
- botões Copiar / Baixar / Prévia;
- nome de arquivo com data: `crawlmon_affinities_YYYY-MM-DD.json`.

### 12. Importação validada com migração v1 → v2

**Problema:** um JSON antigo ou malformado pode corromper o estado.

**Solução:**
- Detectar `schema` v1 e migrar automaticamente (adicionar `isNew=false`, `reviewed=true`, `active=true`, `elements=[]`).
- Validar antes de aplicar: schema, IDs, elementos, valores, tipos.
- Mostrar erros por linha/campo; não aplicar parcialmente sem confirmação.
- Modos **Substituir tudo / Mesclar / Apenas adicionar novos**.
- Fazer backup automático do estado anterior antes de importar (recuperável no undo).

### 13. Templates e presets de afinidade

**Problema:** padrões repetidos (ex.: “fraco a Fire e Psychic”) são digitados manualmente.

**Solução:**
- Gerenciador de templates: nome + conjunto de `{elemento: weak|resist}`.
- Aplicar template a um personagem ou a vários selecionados.
- Templates iniciais sugeridos: “Tudo neutral”, “Fraco a Fire”, “Resistente a Water”, “Fraco a Psychic e Wind”.
- Prévia do resultado antes de aplicar.
- Templates ficam no `localStorage` e podem ser exportados/importados junto com o JSON (opcional).

### 14. Teclado, acessibilidade e mobile

**Problema:** a matriz é densa; mouse e tela grande não podem ser o único caminho.

**Solução:**
- Atalhos: `/` buscar, `N` neutral, `W` weak, `R` resist no item focado, `Tab`/`Shift+Tab` navegar, `Enter` abrir editor, `Esc` fechar modal.
- Foco visível em todos os controles; `aria-pressed` nos segmentos; `aria-label` com personagem/elemento/estado.
- Não depender só de cor: letras N/W/R e rótulos textuais.
- Layout mobile de 1 coluna, alvos de toque ≥ 40 px, toolbar que não cobre conteúdo.
- `prefers-reduced-motion` respeitado.
- Leitor de tela: anunciar mudança de estado (“Abra, Fire, Weak”) via `aria-live`.

### 15. Performance e escala para 100+ personagens

**Problema:** 12 blocos × N personagens cresce rápido; re-renderizar tudo a cada clique vai travar.

**Solução:**
- Não re-renderizar a matriz inteira a cada célula; atualizar só a linha, o contador do bloco e o JSON.
- Busca com debounce e indexação por nome/ID.
- Cards de elemento colapsáveis e “mostrar mais” para listas longas.
- Cabeçalho de elemento e toolbar sticky.
- `localStorage` dividido por personagem ou compressão leve; aviso se passar do limite.
- Exportar em partes se necessário; medir tempo de render e informar no console de debug.
- Meta: 100 personagens × 12 elementos (1.200 células) com interação fluida em um notebook comum.

## Extensão futura: elementos do personagem

Reservar no schema e no card:
- `elements: []` por personagem (0–2 elementos);
- UI futura com seleção de elemento primário/secundário;
- Não editar nesta rodada; não preencher automaticamente os 16 atuais;
- O JSON v2 já deve aceitar o campo vazio.

## Ordem sugerida de implementação

1. Itens 1, 2 e 3 (cadastro, busca e “só novos”) — o núcleo do fluxo.
2. Itens 4, 5 e 6 (visão por personagem, edição e ações em massa).
3. Itens 7, 8 e 9 (dashboard, baseline/diff e undo).
4. Itens 10, 11 e 12 (importação em lote, export v2 e migração).
5. Itens 13, 14 e 15 (templates, acessibilidade e performance).

## Critérios de aceite gerais

- Os 16 personagens atuais continuam com as mesmas afinidades.
- Nenhum `null`/`repel`/`drain` aparece na UI ou no JSON.
- Exportar e reimportar o JSON preserva todos os personagens, afinidades, flags e zooms DQT.
- Adicionar um personagem novo não exige editar código.
- Busca e “só novos” funcionam juntos e em ambas as visões.
- O arquivo continua abrindo por `file://`, sem servidor e sem dependências.
- A estética do jogo é preservada.
- Nada é commitado ou enviado.

## O que NÃO fazer

- Não alterar regras de combate, dano, WIS/VIT ou o jogo Godot.
- Não implementar `null`, `repel` ou `drain`.
- Não inventar elementos para os personagens atuais.
- Não trocar a identidade visual por um dashboard genérico.
- Não adicionar bibliotecas externas.
- Não commitar nem fazer push.
