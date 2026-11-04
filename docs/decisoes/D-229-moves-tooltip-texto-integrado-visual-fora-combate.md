# D-229 — Fichas de Moves: tooltip estilo LoL com texto mecânico integrado e descrição visual somente fora de combate

- **Data:** 2026-11-04.
- **Área:** Fichas de Moves / apresentação de habilidades / descrições.
- **Origem:** correção direta e expressa do criador após os quatro exemplos da série Fichas de Moves M1.
- **Estado:** regra de **formato e apresentação** aprovada e documentada. Não implementada na HUD nem em dados de Move nesta atividade.

## Declaração literal do criador

> Não, está péssimo, seja mais similar a como lol descreve suas habilidades, com toda descrição, dano e efeitos em blocos de texto junto com seus modificadores e o restante como custos e wind up acima, deixa a parte do efeito visual pra descrição na ficha fora de combate

## Regra aprovada

- Nas **descrições de Moves exibidas em combate**, adotar uma apresentação **similar aos textos de habilidades de League of Legends**: informações de funcionamento em **um bloco de texto corrido e legível**, com **descrição, dano, cura, efeitos, condições, valores e modificadores inseridos juntos no texto correspondente**.
- **Não dividir dano, status, chances e modificadores em painéis independentes de números, cartões de status ou blocos técnicos separados do texto da habilidade.** Expressar, no próprio texto, cada quantidade/escala existente e aprovada, com destaque tipográfico quando útil, **sem inventar fórmula ou modificador**.
- Posicionar **custos e windup acima do bloco principal de texto**, como metadados de leitura rápida. Esta regra não aprova um catálogo definitivo dos demais metadados, sua ordem exata, abreviações ou a organização interna da fonte de dados.
- A **descrição do efeito visual pertence exclusivamente à ficha consultada fora de combate**, não à descrição/tooltip de habilidade no combate. Preservar a possibilidade de explicar mecanicamente deslocamento, projétil, impacto ou área **quando necessários para compreender as regras de execução**; isso **não é uma descrição estética/cinematográfica** do VFX.
- As fichas fora de combate podem explicar como o Move se apresenta visualmente; **nenhum VFX, animação, câmera, partícula, geometria ou sequência artística foi escolhido ou alterado aqui**.
- A referência a League of Legends é de **redação e organização de tooltip**. Não importar automaticamente dados, categorias, fórmulas de dano, escalas de atributos, alcance, timings, alvos ou regras de League of Legends/Dota 2 para o Crawlmon.

## Exemplos demonstrativos, não fichas homologadas

Os exemplos a seguir **ilustram o modo de escrever com parâmetros já presentes na documentação/código**. Não constituem aprovação individual de fichas completas, custos MP ou fórmulas novas.

- **Bite** — Metadados acima: `2 ATB`, `windup 1,2 s`. Texto integrado: “Morde um inimigo, causando **1,3× o dano-base** e tendo **30% de chance de aplicar Stun por 2 segundos** ao acertar. Enquanto atordoado, o alvo não regenera ATB [...]”. Efeitos e exceções conforme D-032; não atribuir escalonamento numérico de STR sem fórmula.
- **Sand Attack** — Metadados: `1 ATB`, `windup 0,75 s`. Texto: “Dispara um projétil esquivável que **não causa dano**. Ao atingir validamente um inimigo, aplica **Blind durante 4 segundos**, fazendo cada ação ofensiva realizada nesse período ter **35% de chance de errar**”. **35% é a chance de erro sob Blind, não de aplicar Blind** (D-032).
- **Dragon Rage** — Metadados: `3 ATB`, `windup 2 s`. Texto: “Dispara um projétil contra um inimigo, causando **1,6× o dano-base**; ao acertar o alvo inicial, detona e causa o mesmo dano aos aliados desse alvo. Se errar ou for esquivado, a explosão não ocorre [...]” (D-032). Não decidir categoria físico/mágico ou MP pela geometria do projétil (D-122/D-228).
- **Media** — Metadados: `2 ATB`, `windup 0,5 s`. Texto: “Recupera **40% do HP máximo** de todos os aliados vivos, incluindo o usuário, com **mínimo de 12 HP por alvo**”. Essa cura foi inspecionada em `scripts/combat/battle.gd` e é arredondada individualmente; não atribuir escala de MAG automaticamente (D-123).

## Relações, decisões anteriores e limites

- Este esclarecimento **define o formato de apresentação** que permanecia em aberto em **M1-Q1 (1D)** e a **integração textual dos modificadores** solicitada após **M1-Q2 (2D)**. **Não define a fórmula ou estrutura técnica interna dos modificadores** nem a modelagem de dados/seleção/abrangência de alvos de **M1-Q3 (3D)**, que permanece aberta.
- **D-228** continua estabelecendo MP adicional para Moves mágicos/especiais, **sem valores individuais aprovados**. Na tooltip, custo de MP concreto só aparece quando houver definição verificável para aquele Move. O documento histórico D-032 permanece preservado quanto ao conflito anterior de MP, superado exclusivamente nesse ponto por D-228.
- Respeitar as decisões de requisitos vigentes, incluindo D-119 (tempo próprio de deslocamento), D-122/D-123 (STR/MAG e escalonamentos), D-199/D-210/D-213 (efeitos condicionados ao acerto e status), D-215/D-225 (ficha incompleta) e D-203 (odômetro descartado do jogo principal). **Não inventar parâmetros faltantes**.
- Esta regra **não autoriza alterar código, fichas, interface, arte, animações, testes ou VFX**. Só documentação; nenhuma validação de gameplay foi executada.
