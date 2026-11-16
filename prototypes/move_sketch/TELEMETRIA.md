<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# Telemetria do Move Sketch

No console da página: `TEL` (também em `window.__sk.TEL`).

- `TEL.state()`: tempo, fase, velocidade, corpo, marcadores, cada forma (posição, rotação em graus, escala, opacidade, visível), células de traço (comprimento, pico), histórico, UI, checks.
- `TEL.sample([ms,...])`: estado em tempos exatos, sem reproduzir (determinístico).
- `TEL.cmd(nome, args)`: edita o app e entra no histórico. Retorna `{ok,...}` ou `{ok:false,error}`. Lista em `TEL.help`: type, seek, play, pause, speed, phase, phase.on, phase.ms, view, undo, redo, clear, shape.add, shape.set, shape.del, shape.anim, shape.anim.del, stroke.add, state.load, export.
- `TEL.check(nome, condição, detalhe)`: registra asserção (conta passa/falha).
- `TEL.log`: eventos (cmd, history, phase, play, stop, speed, check, error). `TEL.echo(true)` repete no console.
- Gadget "Telemetria" (dock): resumo, últimos eventos, copiar estado, baixar log.

Exemplo: `TEL.cmd('shape.add',{kind:'arrow',pos:[-1,1.5,0],face:'opponent',from:1,to:6})` e `TEL.sample([100,900])`.
