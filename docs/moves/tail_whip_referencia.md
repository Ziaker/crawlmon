> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.

# Tail Whip — referência de movimento v2 (PROPOSTA da IA, não é dado do jogo)

Refeito a partir da descrição do criador; auditoria completa em `tail_whip_auditoria.md`. Tudo é proposta até aprovação item a item (AGENTS.md §2).

**Como abrir:** `prototypes/move_sketch/move_sketch.html` → gadget **Biblioteca** → Moves salvos → Exemplos incluídos → **Abrir** (ou **Tutorial** → Moves de exemplo). Console: `await __sk.TEL.moves.build('tail_whip')` e `__sk.TEL.moves.audit()`.

## Sequência (Status, 1400 ms, o atacante não se desloca)
| Fase | ms | O que acontece |
|---|---|---|
| Wind-up | 0–300 | Vira de costas (0→180°), braços arqueados, a cauda enrola |
| Release | 300–380 | Segura de costas; marcador de som "whoosh" |
| Approach (giro) | 380–760 | Volta completa (180→540°); a ponta da cauda varre um círculo em volta do corpo descendo até o chão, com rastro e borrão em arco; a 90% a ponta toca o chão: anel e nuvem pequenos de poeira e o marcador "snap" (722 ms) |
| Impact | 760–1400 | Rajada de vento rente ao chão até a frente do oponente; o alvo recua o olhar (até 35°), inclina 10° e baixa a guarda 12% e volta; brilho sutil (opacidade 20%) e ícone de defesa caindo com um único pulso lento; o atacante termina de frente (720°) |

## Formas (7)
Tail · Tail blur · Ground dust ring · Dust puff · Gust · Guard-down glow · Defense-down icon (tudo relativo ao atacante, ao oponente ou à trilha de Efeito; nenhuma posição absoluta).

## Dados novos no Move Sketch
`body_yaw` (giro do corpo), `target_reaction` (reação do alvo), `cues` (sons) no export JSON/briefing/GDScript.
