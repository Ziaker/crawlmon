# D-955 — Biblioteca de VFX de projéteis por elemento (fase de pesquisa e referência)

- **Data:** 2026-11-07.
- **Área:** VFX / Biblioteca / Processo.
- **Origem:** pedido direto do criador, na conversa.
- **Estado:** fase de **pesquisa e referência**. Nenhum efeito, código de jogo, Move ou preset foi criado ou alterado. Escopo a definir com o resultado da pesquisa.

## Frase literal do criador

> vamos criar uma biblioteca de VFX de projéteis de cada elemento no godot para que possamos usar como referência e reutilizar para criar outros, mas primeiro, estamos na fase de pesquisa e referência, essa fase vai ser muito importante pra definir o seu escopo

> a ideia é serem projéteis genéricos que também podem ser usados em múltiplos alvos como placeholder

> obrigatório seguir as fases visuais, start > wind-up > release > trajectory > impact > post impact

> use suas skills de brainstorm e pesquisa para caçar por referências boas para cada elemento presente no jogo até o momento

> tem algumas referências nestes videos que são mt velhas e na maior parte do tempo nem mostra a parte das referências que usaremos em si nos efeitos, tem como se planejar melhor nessas pesquisas? esses prints que vc tira não estão bons, faça questão de se focar em pesquisar por referências de jogos recentes como genshin, naruto ultimate ninja storm 4, honkai star rail, zenzeless zore zero, dragon ball sparking zero, pokemon legends ZA, metaphor, expedition 33, dragon quest mais recentes, tales of arise, granblue sea  e shin megami tensei V vengeance

> as skins spotlights de league of legends também podem ajudar

> antes de continuar, veja as mudanças nas regras do jogo, agora tem um novo elemento, o místico que é algo meio feérico (faerie court skins league of legends), mágico (arcanist skins league of legends), brilhante mas em um verde ciano
>
> a mudança do elemento Ice que agora está acoplado ao Water, então é apenas water, Veneno que virou Nature

**Elementos atualizados (D-396/D-397/D-398):** Neutral, Fire, Water, Electric, Wind, Psychic, Light, Dark, Nature, Sound, Earth, Mystic. Gelo deixa de ser alvo separado. Mystic = feérico (skins Faerie Court do LoL), mágico (skins Arcanist do LoL), brilhante, verde-ciano.

> guido n tem efeitos psíquicos uteis, pesquise por boku no hero, skinline psy ops no lol, mas especialmente psi em persona 5 e persona 3 remake, eles tem uns efeitos de orbes de cores rosas brancas e amarelas e outras cores psicodelicas, elas são melhores pra ter referencia

**Psychic:** Guldo descartado. Prioridade: magias Psi de Persona 5 e Persona 3 Reload (orbes rosa, branco, amarelo e outras cores psicodélicas); depois a skinline PsyOps (LoL) e jogos de Boku no Hero.

> acho melhor pesquisar apenas sobre lol e persona 5 / shin megami tensei V vengeance, eles tem o melhor repertório que o restante

**Fontes restritas (2026-11-07):** daqui em diante a pesquisa usa só League of Legends (skin spotlights), Persona 5 e SMT V: Vengeance. Os aprovados de outros jogos ficam registrados; se ficam ou saem do dossiê, ainda falta perguntar ao criador.

> sim servem também, mas não significa que não vai ter moves de área como o mabufula que tem no jogo onde é um move de área sem projétil de múltiplos alvos

**Uso de Persona/SMT (2026-11-07):** as magias de Persona 5 e SMT V servem para Start, Wind-up, Impact e Post-impact; o trajeto vem do LoL. Elas também valem como referência de Moves de área sem projétil e com múltiplos alvos, como o Mabufula do jogo. Aberto: se essa variante de área entra na biblioteca de projéteis ou fica como conjunto à parte.

## Método de pesquisa (correção do criador, 2026-11-07)

- Foco nos jogos recentes citados na frase acima. Referência velha ou vídeo que não mostra o efeito não serve.
- Primeiro a lista de candidatos (jogo, golpe, elemento, trecho), sem navegador. Depois a conferência, um vídeo por vez.
- A entrega prioriza o trecho exato em movimento; print é só apoio.
- "granblue sea" = **Granblue Fantasy: Relink** (resposta do criador: "Relink"). Jogos fora da lista só entram para cobrir lacuna de elemento, e marcados como tal.

## Decisão

1. Haverá uma biblioteca, **no Godot**, de VFX de projéteis, **um conjunto por elemento**, para servir de referência e ser reutilizada na criação de outros.
2. Os projéteis são **genéricos** e também podem ser usados em **múltiplos alvos**, como placeholder.
3. **Fases visuais obrigatórias da biblioteca:** Start → Wind-up → Release → Trajectory → Impact → Post-impact.
4. A fase atual é **só pesquisa e referência**, e ela define o escopo.
5. Elementos cobertos: os 11 de `Element.Type`: Físico, Fogo, Água/Gelo, Raio, Psíquico, Veneno, Som, Terra, Vento, Luz, Trevas (D-118 preservada).

## Relações e conflitos a confirmar (nada resolvido por conta própria)

- **D-308 / protocolo VFX:** quatro fases obrigatórias (Wind-up, Release, Trajeto, Impacto). Esta decisão pede seis para a biblioteca. Falta confirmar se as seis substituem as quatro em todo VFX de projétil ou só na biblioteca.
- **D-953:** pós-wind-up (carga segurada) como sub-fase e VFX **pausado** até o pipeline ser definido. Falta confirmar se este pedido encerra a pausa quando a pesquisa acabar.
- **D-954 x protocolo D-308:** **resolvido por D-1030:** o Composer é auxiliar e opcional; a biblioteca pode fazer o principal à mão e, se quiser, o secundário no Composer.
- **`docs/vfx/referencias/README.md`:** sete fases de biblioteca anteriores, com Prelude. Esta decisão não cita Prelude.
- **D-009 / D-077:** AoE de projétil é onda única, com geometria por Move; "múltiplos alvos como placeholder" ainda não define a forma.
- **D-308 item 6 / D-334:** tamanho fixo no mundo; **D-308 item 7:** definição de Move poderoso pendente.
- **D-332:** referências de fogo Persona, Genshin Impact e Pokémon. **D-118:** elementos baseados mais em SMT. **D-323:** estilizado.
- Continuam valendo: D-235, D-019, D-022.

## Ambiguidades em aberto

- O que significa "Start" em relação a "Wind-up".
- O que "Post-impact" inclui e quanto tempo pode durar.
- Como é o uso em múltiplos alvos.
- Se Água/Gelo é um conjunto ou dois.
- Se Veneno e Som (sem Moves hoje) entram na primeira leva.

## Estado no código

**Nenhum.** Sem commit nem push (D-022).
