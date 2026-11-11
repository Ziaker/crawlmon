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
