<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

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
