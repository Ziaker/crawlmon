<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# Prompt: valores e balanceamento dos Cascos

Cole o texto abaixo em outro agente. O agente **propõe e pergunta**; quem decide é o criador.

> Você vai trabalhar **só nos valores e no balanceamento dos Cascos** do Crawlmon (Bronze Shell, Silver Shell, Golden shells). Não mexa em visual, modelos, shaders, física nem no feedback de coleta: isso já existe (D-1255, D-1259).
>
> **Antes de qualquer coisa**, leia `AGENTS.md`, `docs/decisoes/README.md` e, em especial, D-1250, D-1251, D-1252, D-1253, D-1255 e D-1259. Cite os IDs aplicáveis no início da resposta. Leia também `docs/REGRAS_DO_JOGO.md`. O GDD é ignorado no combate (D-001).
>
> **Regra de ouro (AGENTS.md §2):** você não decide nada pelo criador. Valor, preço, chance, quantidade, equivalência e escopo só entram em código, briefing ou documento depois de um "sim" claro dele àquele item. Você pode e deve **recomendar**, rotulando a recomendação, com o porquê e as alternativas. Uma decisão por pergunta; perguntas em bloco só se cada item for numerado, com a sua recomendação ao lado. Ao ser aprovada, cada decisão vira um `docs/decisoes/D-xxx-*.md` com a frase literal do criador, antes de qualquer código, e o índice é atualizado.
>
> ## O que já está decidido
> - Três tipos: Bronze Shell (drop de inimigos normais), Silver Shell (drop mais raro de inimigos), Golden shells (só recompensas, valor muito maior) — D-1252.
> - São denominações de um **saldo comum** da loja, com **equivalências fixas e transparentes** — D-1253.
> - Exploração deve render mais que repetir lutas fáceis; a primeira compra deve ser viável **sem** prata, com um desvio bem sinalizado; o ouro tem valor alto sem anular as escolhas de compra seguintes; considerar quem já sabe onde o ouro está e faz entrada, coleta e saída imediata; saldo já consolidado é protegido — D-1253.
> - A mochila preparada no Hub chega à expedição com as compras; resolver a transição pelo Portão **antes** de fixar preços. Primeiro teste: achar moedas no mapa, comprar um consumível no Hub e vê-lo na expedição seguinte — D-1253.
> - Economia difícil no início; recompensas e segredos dos mapas são a principal fonte, drops de inimigos rendem pouco — D-1250 e D-1251.
>
> ## O que está pendente (o seu trabalho)
> Para cada item, entregue: o que está em aberto, 2 a 3 opções com prós e contras, **a sua recomendação** e a pergunta numerada. Itens:
> 1. Equivalências numéricas entre as três denominações e saldo inicial.
> 2. Preços da loja do Hub (consumíveis, kit inicial) e como a loja cobra; como cada tipo aparece no saldo.
> 3. Chances e quantidades de drop de Bronze e Silver; quais inimigos podem dropar prata; elegibilidade de vitória, recrutamento e fuga.
> 4. Quais recompensas dão ouro, quanto, e a repetibilidade das recompensas nos mapas.
> 5. Instante de consolidação do saldo e destino dos ganhos em derrota ou retirada (decisão própria).
> 6. Regra de reposição do kit inicial compatível com a mochila preparada no Hub.
> 7. Valores de teste de D-1259 que viram definitivos: escala da moeda no mapa, raio de puxada, ritmo e intensidade do feedback, valor que o "+1" mostra (hoje conta moedas, não valor).
>
> ## Como trabalhar
> - Faça um **modelo de planilha** (tabela em Markdown ou script) que compare o rendimento de rotas completas: tempo, HP/MP gastos, quantos Cascos por rota, e quanto cada compra custa em rotas. Mostre as rotas "só lutar", "explorar tudo" e "quem já sabe onde está o ouro". Apresente os números, não impressões.
> - Onde o código já existe, o ponto de partida é: `scripts/exploration/shell_coin.gd` (moeda, `Denom` BRONZE/SILVER/GOLD, sem valores numéricos), `scripts/debug/shell_pickup_lab.gd` e `scenes/debug/shell_pickup_lab.tscn` (cenário de debug: `Godot_v4.7.2-stable_win64_console.exe res://scenes/debug/shell_pickup_lab.tscn -- --auto --stdout-trace --quit`, sai com código 0 se ok). Se o seu trabalho pedir telemetria nova ou um cenário novo, crie o cenário em vez de pedir ao criador para montar algo, e documente o campo em `docs/TELEMETRIA.md`.
> - Dados e fórmulas ficam em arquivos de dados, não espalhados no código; nada de número mágico.
> - Não implemente nada ainda não aprovado. Se detectar contradição entre decisões, preserve as duas e pergunte qual vale.
> - Antes de dizer "pronto", releia as decisões aplicáveis, confirme uma a uma que nenhuma foi violada e diga o que **não** foi verificado.
> - Não faça commit nem push sem autorização expressa do criador.
