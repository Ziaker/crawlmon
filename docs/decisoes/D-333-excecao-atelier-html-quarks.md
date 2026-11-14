<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-333 — Exceção do protocolo para o atelier HTML com Quarks.js

- Data: 2026-11-05
- Escopo: exclusivamente o protótipo HTML dos oito Moves da D-331.
- Estado: decisão aprovada; documentação local, publicação não realizada.

## Frase literal do criador

> Continuar no HTML com Quarks.js

Resposta à pergunta: “Para este pedido, o HTML com Quarks.js continua sendo a entrega, como exceção aos requisitos de Motion Composer e batalha Godot do novo protocolo, ou você quer mudar a entrega para Godot?”

## Decisão

A entrega permanece HTML com Quarks.js. Para este pedido, há exceção aos requisitos de construir sobre o Motion Composer e validar na batalha Godot. **Com D-1030, o Composer é auxiliar e opcional**, então a exceção é histórica; não há mais obrigação de usá-lo. Preservar as demais regras: independência dos participantes, relógio único, inspeção das duas vistas, vídeo e aprovação artística. Nenhuma integração ao jogo Godot autorizada.

## Ambiguidades

Nenhuma sobre o formato da entrega. A regra de tamanho foi respondida separadamente na D-334.
