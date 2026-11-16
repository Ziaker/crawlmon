<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1211 — Phantastes: rivais, Travelers, Goblins coloridos e sistemas pré-campanha

- **Data:** 2026-11-14
- **Área:** narrativa, campanha, hub, recrutamento
- **Estado:** **registrada; nada implementado.** Só documento (D-061).
- **Relacionadas:** [D-1210](D-1210-campanha-phantastes-primeiro-teste-narrativo.md), D-312, D-321, D-1207

## Frases literais do criador

> "podem ser ambos, com texturas coloridas sorteadas"

> "NUNCA use os modelos que não são da extração ZA, esses estão imcompletos e não estão utilizáveis"

> "os rivais podem ser sorteados aleatóriamente por  inicio de jogo, seriam 3 grupos rivais no total, com 3 membros cada. / vamos só fazer o primeiro / snorunt, gibble e Foongus"

> "ok" (Sunless Sea fica fora do primeiro teste)

> "o ideal é criar os sistemas PRÉ campanha antes de prosseguir pra campanha"

> "se o protagonista enfrenta ameaças, oponentes,vilões, então é o trabalho dos Travelers (nome dado ao grupo de personagens) de impedir que o protagonista morra. O protagonista morrer resulta em uma campanha fracassada, o time rival não influencia a morte do protagonista."

## Decisão (somente o que ele disse)

1. **Goblins:** `0160_gremlin` **e** `0007_lilliput`, ambos, com **texturas coloridas sorteadas**.
2. **Regra de modelos:** **nunca** usar modelos que não sejam da extração Legends Z-A (os outros estão incompletos e inutilizáveis).
3. **Rivais:** sorteados por início de jogo; **3 grupos rivais no total, 3 membros cada**. **Só o primeiro grupo será feito agora:** **Snorunt, Gible ("gibble") e Foongus** (os três têm `model_source: legends_za` no manifesto).
4. **Sunless Sea** fica fora do primeiro teste.
5. **Ordem de trabalho:** criar os **sistemas pré-campanha antes de prosseguir para a campanha**.
6. **Travelers** é o nome do grupo de personagens. Quando o protagonista (do livro) enfrenta ameaças, é trabalho dos Travelers impedir que ele morra. **Se o protagonista morrer, a campanha fracassa.** O time rival **não** influencia a morte do protagonista.

## Respostas posteriores (2026-11-14), frases literais

> "Todas equipes do jogo são travelers, eles entram em mundos diferentes para proteger as suas histórias de acabarem com um fim incoerente com a narrativa original"

> "2 - só vale se o protagonista for morto fora da sua narrativa principal"

> "3 - eles NÃO DEVEM SER LEVADOS EM CONTA PRA NADA, IGNORADOS POR COMPLETO"

Decisão: (a) **todas as equipes do jogo (jogador e rivais) são Travelers**, que entram em mundos diferentes para proteger as histórias de um fim incoerente com a narrativa original; (b) "protagonista morto = campanha fracassada" **só vale se ele morrer fora da sua narrativa principal** (a morte prevista pelo livro não conta como fracasso); (c) **Drowzee, Vigoroth e Croagunk (`arenamon_chars`) são ignorados por completo**: não entram em campanha, rivais, elenco nem análise. Esta decisão não manda removê-los do jogo.

> "o jogo é meio kingdom hearts em questão de entrar em narrativas e corrigir os problemas delas sem alterar o final"

Decisão: premissa do jogo registrada como o criador disse: os Travelers entram em narrativas (mundos) e **corrigem os problemas delas sem alterar o final**. Kingdom Hearts é só a comparação dele; nenhuma regra do KH foi adotada.

> "Exemplo B"

Decisão: o **primeiro problema de teste** é o do **Ogro do Amieiro (Zinmenju)**: o ogro-árvore persegue Anodos na floresta e quase o mata fora da narrativa; a equipe de Travelers impede (combate contra o Zinmenju e os goblins coloridos), Anodos segue a viagem. Detalhes do livro vêm da memória do assistente e **não foram conferidos no texto**.

## Ambiguidades e pontos em aberto (não implementar)

- **"Problema" × "final":** o exemplo B define um caso; a regra geral do que é problema e do que é alterar o final continua pendente.
- **Ogro × Amieiro (conferido no texto, edição espanhola Vórtice 2012):** no livro o **ogro é o Fresno (Ash)**, de dedos grossos, que quer enterrar Anodos ao pé da árvore; o **Amieiro/Aliso (Alder)** é outra criatura, uma mulher bela que tenta afogá-lo na rede do cabelo. O D-1210/D-1211 diz "Ogro do Amieiro = Zinmenju": falta o criador confirmar se o Zinmenju faz o Fresno (ogro), o Amieiro, ou os dois.
- **Exemplo B:** composição do combate, onde o rival aparece, o que a equipe ganha e o que muda por ter vencido não foram definidos. Conferir a cena no texto original.
- **Final do livro:** o que conta como "narrativa principal" e como o desfecho original de Anodos é cena jogável continua pendente.
- **Rivais:** os outros 2 grupos ficam para depois; a regra de sorteio (por que e como) e o que "terminar antes" muda na história continuam pendentes.
- **Sistemas pré-campanha:** quais são e em que ordem (Respeito, hub, recrutamento etc.) ainda não foi definido. Respeito segue sem valores.
- **Goblins:** quantidade e paleta de cores do sorteio pendentes.

## Referências

- `docs/pokedex_manifest.json` (`snorunt`, `gible`, `foongus`: `legends_za`)
- `docs/decisoes/D-1210-campanha-phantastes-primeiro-teste-narrativo.md`
