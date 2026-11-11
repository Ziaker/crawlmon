# D-1031 — Gravador DQT: `--dqt-mirror` grava o par; Slime é atacante explícito

- **Data:** 2026-11-09
- **Área:** VFX / Ferramentas / D-1020
- **Origem:** resposta do criador à pergunta 2 da auditoria.

## Frase literal do criador

> "2 - sigo sua recomendação"

## Decisão

1. `--dqt-mirror` passa a significar o **par DQT**:
   - vista **normal**: trio DQT no lado do jogador contra o encontro aleatório;
   - vista **espelhada**: trio DQT no lado inimigo contra o jogador padrão.
2. `--dqt` sozinho continua **rejeitado** (exit 2), porque não forma o par; a mensagem deve mandar usar `--dqt-mirror` ou as duas flags.
3. O atacante padrão continua sendo o **primeiro vivo do lado** (D-235). No trio DQT atual, isso é **Orc**, não Slime.
4. Para gravar um Move do Slime (D-1025, Tidal Surge), passar explicitamente `--attacker=Slime` e `--mirror-attacker=Slime`. A documentação não pode afirmar que o Slime é o atacante padrão.
5. O manifesto deve continuar mostrando os lados reais da pré-checagem; a documentação deve mostrar o par `--dqt-mirror` e o caso Slime separadamente.

## Ambiguidades em aberto

Nenhuma. A recomendação foi aceita.

## Estado

Implementado em `tests/fx_lab/record_move_video.py` e documentado em `docs/vfx/FERRAMENTAS_VFX.md`; testado com `--dqt-mirror` (normal Orc/player, espelhado Orc/enemy) e com `--dqt --dqt-mirror`. Sem commit/push.
