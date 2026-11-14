<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-045 — Motion Composer: pasta fixa para presets

- **Data:** 2026-11-03
- **Área:** Motion Composer / persistência / especificação
- **Origem:** Conversa

## O que o criador disse (literal)

> fixa

Resposta à escolha entre salvar e carregar presets em qualquer pasta escolhida pelo usuário ou em uma pasta fixa do laboratório.

## Decisão

Os presets do Motion Composer V1 serão salvos e carregados em uma pasta fixa do laboratório.

Esta decisão resolve a política de localização de P-06; não define o caminho concreto nem o formato de serialização.

## Ambiguidades em aberto

- Caminho concreto da pasta fixa.
- Formato de serialização dos presets.

## Estado

Documentado; persistência não implementada nem testada em execução. Nenhuma pasta de presets foi criada por esta decisão.
