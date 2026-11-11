# D-1163 — Matriz de afinidades passa a ser o cadastro oficial de personagens novos

- **Data:** 2026-11-11
- **Área:** Dados / personagens / afinidades / fluxo de trabalho.
- **Origem:** o criador finalizou o protótipo e definiu o fluxo para personagens novos.
- **Estado:** regra de processo registrada; protótipo pronto, nenhum código do jogo alterado.

## Declaração literal do criador

> "mas apartir de agora, toda vez que adicionarmos um personagem novo, utilizaremos essa matriz de afinidades para definir as afinidades deles, e também os elementos deles mais tarde."

## Regra aprovada

1. **A matriz de afinidades é o cadastro oficial de personagens novos.** Todo personagem novo entra primeiro em `prototypes/affinity_matrix.html` e tem as 12 afinidades definidas ali.
2. **Só `Neutral`, `Weak` e `Resist`** são usados (D-1161). A matriz não oferece `NULL`, `REPEL` nem `DRAIN`.
3. **Elementos do personagem ficam para depois.** A matriz apenas reserva o campo; não é desta rodada e não se inventam elementos para os personagens atuais.
4. **A exportação JSON da matriz é a entrega** do trabalho de afinidades de cada personagem novo.
5. **Os 16 personagens atuais permanecem** na matriz, incluindo Neutral (Tackle = Neutral).

## Decisões do criador

1. **Continua como protótipo.** A matriz permanece em `prototypes/affinity_matrix.html`, standalone, abrindo por `file://`, sem servidor.
2. **Como o JSON chega ao jogo (recomendação adotada pelo criador, que delegou: "sigo sua recomendação"):** um script `tools/apply_affinities.py` lê o JSON exportado e escreve a tabela `affinities` em `content/characters/<id>/species.tres`. Padrão é `--dry-run` (mostra o diff); `--write` aplica. O script **não** toca em `weaknesses` (fallback legado) e não apaga personagens que não estejam no JSON.
3. **Fonte de verdade (recomendação adotada):** a matriz é a fonte de **autoria** das afinidades; o `.tres` continua sendo a fonte de **runtime**. O JSON é o contrato entre os dois e só o script escreve no jogo. O jogo nunca lê o JSON em tempo de execução.
4. **Elementos (recomendação adotada):** entram na mesma matriz, numa rodada posterior, no campo `elements` por personagem; o JSON já reserva `elements: []` e ainda não edita nem preenche nada.

Se alguma dessas três recomendações não for o que o criador quis dizer, basta corrigir: nada depende delas no código do jogo ainda.

## Estado no código

- `prototypes/affinity_matrix.html`: 12 elementos, 16 personagens, N/W/R, busca, filtros, autosave, exportação/importação JSON, ícones DQT 2D do Tact com degradê ciano→verde.
- **Itens 1–3 do prompt implementados (2026-11-11):** cadastro de personagem por modal (ID único, nome, papel, retrato, DQT + zoom, upload até 150 KB, prévia), busca por nome/ID/papel sem acento com destaque e contador, filtro “Só novos” com badge NEW e “Revisar visíveis”. A importação agora recria personagens ausentes do roster.
- **Itens 4–6 implementados (2026-11-11):** visão **Por personagem** (12 linhas de elemento por card, contagem W/R e Editar), edição inline (nome, ID com confirmação e migração das afinidades, papel, retrato, DQT, ativo/inativo), e ações em massa por personagem (tudo neutral, copiar de outro com confirmação do número de células, duplicar e excluir com confirmação). O filtro e a visão persistem.
- **Fora desta rodada, por falta de definição:** a barra “12/12 revisados” por personagem (o prompt não define o que conta como revisado por elemento) e os templates de afinidade (item 13). Excluir personagem ainda não tem desfazer (item 9).
- Exportação verificada em 2026-11-11: `crawlmon.affinities.v1`, 12 elementos; 16 personagens de base e 17 com um personagem de teste; `isNew`, `reviewed`, `active` e `elements: []` por personagem; importação de ida e volta preserva tudo.
- Nenhum arquivo do jogo foi alterado por esta decisão.
- Nada de commit/push sem autorização (D-022).
