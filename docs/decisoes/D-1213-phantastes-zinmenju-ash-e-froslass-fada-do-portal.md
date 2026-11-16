<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1213 — Phantastes: Zinmenju como o Ash e Froslass como a fada do portal

- **Data:** 2026-11-14
- **Área:** narrativa, campanha
- **Estado:** **registrada; nada implementado.** Só documento (D-061).
- **Relacionadas:** D-1210, D-1211, D-420, `docs/campanhas/BRAINSTORM_MODO_CAMPANHA.md`

## Frase literal do criador

> "de resto sigo com suas recomendações, não vamos pros próximos 5 capítulos ainda"

(Resposta à lista de escopos dos personagens dos capítulos 1 a 10, em que as únicas recomendações explícitas minhas eram os dois itens abaixo.)

> "aprovo também, inclusive, você está escrevendo um documento de composição de cenas e cutscenes? se não então faça questão de já começar, é pra ser parte do escopo de criação de campanhas"

(Resposta à pergunta "se queria aprovar também as outras propostas de escopo". Lida como aprovação das propostas listadas no item 4 abaixo.)

## Decisão (somente o que ele disse)

1. **Zinmenju faz o Ash** (o ogro de dedos grossos do livro), e não a Alder. Fica como o D-1210 ("Ogro do amieiro: Zinmenju") com o nome do livro corrigido.
2. **Froslass é a fada da escrivaninha** que abre o livro (capítulos 1 e 2).
3. **Não avançar para os capítulos 11 a 15 ainda.**
4. **Escopos aprovados (propostas da minha lista):** Ash que se anuncia antes de aparecer (só acorda à noite), com o Exemplo B como problema dos Travelers; Alder como inimigo de engano que trabalha com o Ash; Dama de Mármore como segundo problema (acordá-la cantando, cantar como ação de interação); Cavaleiro Enferrujado como aliado narrativo que salva Anodos, com a ferrugem saindo como progresso visível; Sombra nascendo da escolha de abrir o armário proibido; Beech como aliada natural; fazenda como ponto de descanso e de explicação das regras; goblins hostis só até verem a Sombra, depois recuam (encontro evitável); moça do globo e aldeia dos rostos deformados como eventos de escolha sem combate.
5. **Documento de composição de cenas e cutscenes** passa a fazer parte do escopo de criação de campanhas: `docs/campanhas/COMPOSICAO_CENAS_E_CUTSCENES.md` (iniciado; só propostas até ele aprovar cada item).

## Ainda pendente (não implementar)

- **Alder (a moça-árvore sedutora):** modelo e se aparece em combate.
- **Sem modelo (regra só Z-A):** Beech, família da fazenda, ogra, fadas das flores.
- Quantidade e paleta dos goblins; os outros 2 grupos de rivais e a regra do sorteio; Respeito; final jogável; regra geral de "problema" contra "alterar o final".
- Ficam fora da aprovação: fadas das flores, ogra, modelos dos personagens sem modelo, se a ferrugem é mecânica ou só visual, se o Cavaleiro é jogável, NPC ou rival.
- Visual "trevas" dos inimigos: no brainstorm, não é decisão.
