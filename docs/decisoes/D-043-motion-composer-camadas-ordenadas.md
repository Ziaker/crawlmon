# D-043 — Motion Composer: composição por camadas ordenadas

- **Data:** 2026-11-03
- **Área:** Motion Composer / interface / especificação
- **Origem:** Conversa

## O que o criador disse (literal)

> camadas ordenadas

Resposta à pergunta sobre organizar a composição em camadas ordenadas, grafo de nós ou ambos.

## Decisão

A interface de composição do Motion Composer V1 será organizada em camadas ordenadas. A ordem das camadas explicita a ordem de aplicação dos comportamentos, conforme o contrato de composição da especificação.

Resolve P-04. A escolha não elimina os comportamentos de bifurcação e recombinação já incluídos no catálogo; a apresentação de seus ramos dentro das camadas ainda precisa ser detalhada.

## Ambiguidades em aberto

- Apresentação e seleção dos ramos nas camadas.
- Disposição visual e interações específicas da interface permanecem pendentes.

## Estado

Decisão documentada; interface não implementada nem testada em execução. Nenhuma integração ao combate autorizada por esta decisão; D-019 permanece em vigor.
