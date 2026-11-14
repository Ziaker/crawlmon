# D-1212 — Sand Attack: rastro de poeira rente ao chão, como os rastros de habilidades do League of Legends

- **Data:** 2026-11-14.
- **Área:** VFX de Move / combate.
- **Relacionadas:** D-1196 (Sand Attack A), D-235, D-308, D-1204.
- **Status:** revertido (ver D-1214 para o rastro e o corte atuais).

## O que o criador disse (literal)

> eu queria que a areia fizesse um rastro no chão, algo similar a como league-of-legends cria rastros no chão para certas habilidades

Enviou 4 imagens do LoL como referência (faixa de poeira rente ao chão em duas, terra e pedra levantadas, bonecos de treino).

## Respostas às perguntas (2026-11-14)

- Tipo: **"Faixa de poeira rasteira (Recomendado)"**.
- Trajeto: **"Do atacante até o alvo (Recomendado)"**.
- Duração: **"Dissipa junto com o jato (~1 s) (Recomendado)"**.
- Escopo: **"Sim, acréscimo (Recomendado)"**: o HTML fica como está e o rastro é somado.

## Decisão

1. O Sand Attack ganha uma faixa de poeira rasteira no chão, do atacante até o alvo, que se dissipa junto com o jato (~1 s).
2. É acréscimo à D-1196: o HTML não tem rastro; o resto do Sand Attack A não muda.
3. Independente de personagem, time e lado (D-235): o eixo vem do atacante e do alvo reais.

## Pendente (não dito pelo criador; escolhas técnicas da IA, ele pode mudar)

- Largura, espessura, opacidade e cor da faixa. Cores: paleta de areia do HTML (`PALETTE_SILICA_SAND`).
- Sem sulco/cicatriz, sem pedras extras e sem mancha sob o alvo (ele não escolheu essas opções).

## Estado

- Registrado; implementação em andamento.

## Correção visual (2026-11-14, após ver o 1º resultado)

> está péssimo visualmente, não tem nenhum movimento aplicado vc não usou as imagens dereferencia direito, é um rastro de chão de poeira mas em forma de arco completo

Resposta ao mockup animado (opção A "arco que viaja" x B "arco que se abre"):

> é como a opção A mas não tão grande

- Decisão: o rastro é um **arco (crescente) de poeira que viaja do atacante ao alvo, com largura fixa**, em movimento (nuvem que rola e some atrás, riscos de vento seguindo a curva, pedacinhos de terra, risco escuro de terra revirada na frente). A faixa plana anterior (`dust_sand_trail.gdshader`) é substituída.
- "Não tão grande": o tamanho exato não foi dito. Escolha da IA (ele pode mudar): meia-largura do arco 1,6 m, recuo das pontas 1,2 m.

## REVERTIDO (2026-11-14)

> só volta atrás pra ser exatamente igual a sua primeira entrega desse move

- Tudo o que a D-1212 acrescentou foi desfeito: faixa plana, arco de poeira, anéis do wake, anel/véu movidos, e o ajuste de tamanho (70%), opacidade (40%) e cor clara. O Sand Attack volta a ser a primeira entrega (opção A do HTML, D-1196).
- Removidos: `shaders/dust_sand_trail.gdshader`, `scripts/vfx/combat/dust/dust_arc_wave.gd`, `DustFx.sand_ground_trail`, `DustFx.sand_cloud_wake`, `SAND_OPACITY`/`SAND_SIZE`/`PALETTE_SAND_PALE` e os parâmetros `opacity_scale`/`emit_particles`.
- Mantido (não é visual): o controle de debug `--audit-delay=SEC` em `vfx_room.gd`.
- Pendente, não implementado: o rastro/arco em movimento que o criador queria. O que ele pediu por último (o anel e o véu do release andarem junto com a areia) não ficou aprovado em nenhuma tentativa.
