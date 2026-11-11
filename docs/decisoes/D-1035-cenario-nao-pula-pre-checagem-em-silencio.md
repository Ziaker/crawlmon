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
