<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1035 — `--scenario` não pula a pré-checagem em silêncio

- **Data:** 2026-11-09
- **Área:** VFX / Ferramentas / D-1020
- **Origem:** resposta do criador à pergunta 6 da auditoria.

## Frase literal do criador

> "6 - sigo sua recomendação"

## Decisão

1. `--scenario` **não pode** pular a pré-checagem sem aviso. O gravador deve exigir `--skip-preflight` explícito para aceitar um cenário pronto sem a checagem de 1 s.
2. Um cenário inexistente deve **falhar rápido**, imprimir a razão e sair sem gravar, em vez de deixar o processo esperando o timeout.
3. A documentação deve mostrar que `--scenario` + `--skip-preflight` é uma escolha consciente, não o padrão.
4. A pré-checagem normal (sem cenário) continua obrigatória por padrão.

## Ambiguidades em aberto

Nenhuma.

## Estado

Implementado em `tests/fx_lab/record_move_video.py` e no tratamento de cenário de `scripts/debug/vfx_room.gd`; documentado. Testado com cenário inexistente + `--skip-preflight`: falha sem vídeo em ~28 s (carregamento do Godot), sem esperar o timeout de 180 s. Testado também sem `--skip-preflight`: erro imediato em ~0,2 s. Sem commit/push.
