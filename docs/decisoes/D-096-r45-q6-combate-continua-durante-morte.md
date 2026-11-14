<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-096 — R45-Q6 (6A): Sobreviventes continuam agindo durante animação de morte

- **Data:** 2026-11-03
- **Área:** Combate / Rodada 45
- **Origem:** decisão expressa do criador, R45-Q6.
- **Estado:** decisão de design aprovada; implementação não verificada.

## Declaração literal do criador

> 6A — Durante uma sequência de morte cinematográfica, os outros personagens ainda podem agir? O combate continua normalmente entre os personagens vivos; só a tela de resultado aguarda.

## Regra aprovada

Enquanto uma sequência visual de morte cinematográfica é exibida, **o combate continua normalmente entre personagens vivos**, desde que a batalha ainda esteja logicamente em andamento. **Somente a exibição da tela de resultado aguarda** a conclusão das sequências fatais pertinentes.

## Referências e limites

- **Decisões relacionadas:** D-019; D-056; D-068; D-080; D-081; D-090; D-091; R45-Q5.
- **Limite / pendência:** Não cria permissão para iniciar ações após o encerramento lógico da batalha. Pausas de status e hit-stop previamente aprovadas seguem válidas quando aplicáveis.
- **Escopo:** registro documental somente; nenhum código, VFX, teste ou dado de jogo modificado.
