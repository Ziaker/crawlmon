# D-1177 — Matriz de afinidades: rodada de QoL (heatmap, desfazer, diff, paleta, extras da ficha)

- **Data:** 2026-11-11
- **Área:** Protótipo / ferramenta de cadastro de personagem (`prototypes/affinity_matrix.html`).
- **Origem:** o criador delegou a escolha das melhorias.
- **Estado:** implementado no protótipo; nenhum arquivo do jogo alterado; aguardando revisão do criador.

## Declaração literal do criador

> "mostre pra mim o que o fable e capaz e melhore ainda mais, me surpreenda com o matrix, mas nao esqueca do pra que ele serve, quero QolS e muitas coisas legais"

## O que a delegação cobre (interpretação do assistente)

Só a **ferramenta**. Nenhuma regra de jogo, número de combate ou dado de personagem foi criado ou alterado. O JSON exportado continua **`crawlmon.affinities.v1`**, com os mesmos campos de D-1167. Só Neutral/Weak/Resist (D-1161).

## O que entrou (escolhas do assistente, todas reversíveis)

1. **Visão "Matriz"** (4ª visão): tabela personagens × 12 elementos. Clique alterna N → W → R; pincel N/W/R pinta arrastando; setas movem o foco e `N`/`W`/`R` gravam; ordenar por nome, mais Weak, mais Resist ou por uma coluna; totais por linha e por coluna; copiar/colar a linha de um personagem em outro.
2. **Desfazer/refazer:** `Ctrl+Z` / `Ctrl+Y`, 100 passos, vale para tudo (afinidade, atributos, nature, elementos, moves, criar/editar/excluir, importação). Excluir personagem deixa de ser definitivo.
3. **Base + diff:** a base é o último JSON baixado (antes do primeiro, o padrão do jogo). Células diferentes da base ganham marca dourada; o painel **Alterações** lista tudo e reverte por item, por personagem ou tudo. Imagens não entram no diff.
4. **Painel:** revisados, fichas completas, alterações pendentes e balanço W/R por elemento.
5. **Pendências (só aviso, não bloqueia a exportação):** personagem ainda NEW, atributos ≠ 15, sem elemento, sem move.
6. **Paleta de comandos (`Ctrl+K`)**, atalhos (`1`–`4` visões, `←`/`→` troca a ficha, `Ctrl+S` exporta, `?` ajuda) e `N`/`W`/`R` com o mouse em cima de qualquer célula.
7. **Ficha:** radar dos 6 atributos (base e base + nature), clique no segmento da barra para fixar o valor, pontos que faltam/sobram, moves arrastáveis para definir a ordem do loadout, filtro de moves por elemento, resumo do loadout e **Matchups**.

## Critérios criados pelo assistente (não são regra de jogo)

- **Ficha completa** = 15/15 pontos + pelo menos 1 elemento + pelo menos 1 move. É só um indicador da ferramenta.
- **Matchups** considera que um move atinge pela afinidade do **elemento do próprio move** e ignora moves `Status`. Mostra só contagens sobre os dados N/W/R que já existem; não calcula dano.
- O polígono "com nature" do radar é base + modificador, com piso 0, só para visualização.

## O que não foi feito

- Importação em lote CSV, editor de recorte de imagem, templates nomeados de afinidade (D-1163 já os deixou sem definição) e virtualização para 100+.
- Nada de commit/push (D-022).
