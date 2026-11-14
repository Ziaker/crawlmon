<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-231 — Motion Composer V1: Etapa 2 (comportamentos básicos) autorizada

- **Data:** 2026-11-04
- **Área:** Motion Composer / implementação isolada
- **Origem:** Conversa

## O que o criador disse (literal)

> ok vá pra fase 2

## Decisão

Implementar a **Etapa 2** da seção 16 de [Motion Composer V1](../vfx/MOTION_COMPOSER_V1.md): "Implementar e validar trajetórias, campos, deformações e propagação". Isso corresponde a **M01–M13** (grupos A, B, C e D do catálogo), sobre os contratos da Etapa 1 ([D-230](D-230-motion-composer-etapa-1-autorizada.md)).

Limites desta autorização:

- Fora da Etapa 2: M14 e M15 (bifurcação/recombinação, Etapa 3) e M19 e M20 (rastro e pós-imagem, Etapa 4).
- **M16 (explosão direcional), M17 (crescimento) e M18 (dissolução) não pertencem a nenhuma etapa da seção 16.** Não foram implementados; a etapa deles precisa ser definida pelo criador.
- Contratos da Etapa 1 inalterados (apenas adições, se necessárias). Sem integração ao combate, sem tocar em `VfxLib`, `BattleFx`, cenas ou VFX existentes (D-003, D-019, D-020). Sem push (D-022).

## Valores propostos pelo agente (não aprovados pelo criador)

Todas as fórmulas, nomes de parâmetro, unidades, padrões e limites dos 13 comportamentos são propostas técnicas ajustáveis, documentadas na §21 da especificação. Os parâmetros funcionais seguem a lista da seção 3 do anexo do criador; os valores e as curvas não foram aprovados. Aparência não foi avaliada.

## Ambiguidades em aberto

Etapa de M16–M18 (acima). Demais pendências da §17 da especificação continuam abertas.

## Estado

M01–M13 implementados e testados em execução headless (124 verificações, 0 falhas; 13 mutações); ver [§21 da especificação](../vfx/MOTION_COMPOSER_V1.md). Aparência e desempenho não avaliados. M16–M18 pendentes de definição de etapa.
