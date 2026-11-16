<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1210 — Campanha Phantastes como primeiro teste narrativo (elenco, castelo, rivais, Respeito)

- **Data:** 2026-11-14
- **Área:** narrativa, campanha, overworld, hub
- **Estado:** **registrada; nada implementado.** Só documento (D-061).
- **Relacionadas:** D-312, D-316, D-321, D-310, D-413, D-420, D-1181, D-1207, GDD §7.16, §7.25 (R34-Q1, R34-Q3), §7.27 (R36-Q2)

## Frases literais do criador

> "vamos com phantastes para o primeiro teste de narrativa e campanha"

> "A sombra : Gastly / Ogro do amieiro: Zinmenju / Dama de mármore: Golurk / Cavaleiro: https://dragonquest.fandom.com/wiki/Restless_armour / gigantes ok / goblins ok / Fada Froslass"

> "podemos apenas acompanhar o protagonista em momentos chave, ele não precisa estar presente. Nestes momentos chave seriam onde ocorreriam contato entre a equipe do jogador com a equipe rival"

> "não necessariamente precisa de um chefe, apenas o embate entre equipe principal e rival pode ajudar, mas a história precisa seguir como é no livro"

> "sim, meio aberta, com cada andar sendo um nivel da torre, visualmente não é uma dungeon mas mecanicamente ainda é"

> "geração procedural seria para outras coisas, como são campanhas então não é necessário que haja isso, campanhas devem ter coisas pré-prontas"

> "um emblema badge ao lado do mapa que diz em que andar estamos e também o objetivo e onde deve estar a próxima parte da história"

> "perfeito" (relógio mede progresso, andares e eventos, não minutos reais) / "sigo suas recomendações" (curva fixa por seed, repetível pelo jogador)

> "o jogador perde nível de respeito, um sistema que também vai definir mecânicas do hub e também mecânicas de recrutamento, com o nivel de respeito sendo importante" / "apenas perda de respeito"

> "Os rivais entram para ajudar a história do personagem principal, é o que iremos fazer também sendo o jogador, eles não tem relação com a história e muito menos o jogador também."

> "sim" (objetivo da expedição: descobrir o que a Sombra quer)

> "se o conteudo for os items e recompensas e até mesmo inimigos raros ou os rivais da vez, sim." / "progresso" / "ok" (biomas novos) / "sim" (posso propor 2 a 3 biomas novos)

## Decisão (somente o que ele disse)

1. **Phantastes** é a primeira campanha de teste (narrativa + design de campanha).
2. **Elenco aprovado (personagens narrativos):** Sombra = **Gastly**; Ogro do Amieiro = **Zinmenju** (DQT `0045_zinmenju`); Dama de Mármore = **Golurk**; Cavaleiro = **Restless Armour** do DQ (no tact: `0018_samayouyoroi`); Gigantes e Goblins = os candidatos que propus ("ok": Gigantes `0065_gigantes`; Goblins `0160_gremlin`/`0007_lilliput`); Fada = **Froslass**.
3. **O protagonista do livro não precisa estar presente**; só em momentos-chave, e é neles que a equipe do jogador encontra a equipe rival.
4. **Sem chefe obrigatório:** o embate entre equipe principal e rival pode servir; a **história segue como no livro**.
5. **Cada andar é um nível da torre** (visualmente não é uma dungeon, mecanicamente continua sendo andares). **Campanhas têm conteúdo pré-pronto**; procedural só para itens, recompensas, inimigos raros e os rivais da vez.
6. **Badge ao lado do mapa:** andar atual, objetivo e onde está a próxima parte da história (em vez de um minimapa por nível).
7. **Corrida de rivais** mede **progresso**, não tempo real; curva fixa por seed, repetível.
8. **Perder a corrida = só perda de Respeito.** Respeito é um sistema novo que também define mecânicas do hub e do recrutamento.
9. **Os rivais não têm relação com a história** nem com o jogador; entram para ajudar a história do personagem principal.
10. **Objetivo da expedição:** descobrir o que a Sombra quer.
11. **Biomas novos autorizados a propor** (o D-312 fixa floresta, fortaleza, caverna "por ora").

## Ambiguidades e pontos em aberto (não implementar)

- **Respeito:** valor inicial, faixas, como sobe e desce, efeitos concretos no hub e no recrutamento: tudo pendente (D-1207: Standby/loja/forja ainda "[Demo Preview]").
- **Rivais:** quem é o trio (espécies), quantos por campanha, como "ajudam a história", o que é "progresso" medido, a curva exata. Meus candidatos Arenamon (croagunk, drowzee, vigoroth) **não foram aprovados**.
- **Gigantes e Goblins:** "ok" aprovou meus candidatos, mas a escolha entre `0160_gremlin` e `0007_lilliput` e a quantidade não foram decididas.
- **Restless Armour:** o criador deu um link da wiki; o modelo no tact é `0018_samayouyoroi` (confirmar o rig e a animação antes de usar).
- **Final:** "segue como no livro" não define como o final do livro (Anodos morre no lugar de outro) vira cena jogável.
- **Conflitos a resolver:** GDD R34-Q3 (andares sequenciais) e R25-Q1 (desbloqueio) com "andar = nível de torre"; D-420 (nenhum Move ligado a espécie) vale para o elenco; D-413 (texto em inglês).
- **Biomas novos:** nomes e visual ainda a aprovar.
- **Modelos:** Gastly, Golurk, Froslass estão no manifesto como usáveis; Zinmenju e Restless Armour precisam passar pelo extrator do tact.

## Referências

- `docs/GDD.md` §7.16, §7.25, §7.27; `docs/decisoes/D-312-*.md`, `D-316-*.md`, `D-321-*.md`
- `C:\games\tact\fbx_inventario.csv` (`0018_samayouyoroi`, `0045_zinmenju`)
- `docs/pokedex_manifest.json`
