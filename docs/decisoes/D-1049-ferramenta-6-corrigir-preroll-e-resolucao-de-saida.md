<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1049 — Ferramenta 6: corrigir `clip_preroll` no início e a resolução de saída

- **Data:** 2026-11-09
- **Área:** VFX / Ferramentas / D-1020
- **Origem:** resposta do criador à auditoria: "sigo sua sugestao" para começar pelos dois erros da ferramenta 6.

## Frase literal do criador

> "sigo sua sugestao"

## Decisão

1. **`clip_preroll`/`local_time`:** quando o trecho baixado começa em `clip_start = 0`, o excedente de duração é **cauda**, não pré-roll. O manifesto deve gravar `clip_preroll = 0` e `local_time = tempo pedido` (sem os 3 ms a mais).
2. **Resolução do manifesto:** separar:
   - `source_resolution`: resolução do vídeo de origem;
   - `output_resolution`: resolução real dos quadros depois de `--crop` e `--max-height`;
   - `resolution`: mantido como apelido de `output_resolution` para não quebrar consumidores antigos.
3. Nenhuma regra de jogo é alterada; é só a ferramenta de captura de referência.

## Ambiguidades em aberto

- Para trechos com `clip_start > 0`, o pré-roll continua sendo estimado por duração; a precisão de ~1 quadro permanece documentada.

## Estado

Implementado em `tests/fx_lab/reference_capture.py`; testado com vídeo local, URL e crop. Sem commit/push.
