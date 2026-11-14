<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-394 — Progressão de pontos de nível: jogador e aliados

- **Data:** 2026-11-07
- **Área:** Personagens / progressão
- **Origem:** decisão direta do criador, na conversa.
- **Estado:** regra registrada; sem código.

## Declaração literal do criador

> 1  ponto por nivel, a cada 10 niveis (10 20 30 40) ele recebe 3 pontos ao invés para alocar.
> sim, suas ações, definem suas evoluções

## Regra aprovada

- **Jogador (Líder):** Ganha **1 ponto** para alocar livremente por nível comum. Nos marcos a cada 10 níveis (níveis 10, 20, 30, 40...), ganha **3 pontos** para alocação manual.
- **Aliados (IA):** Não possuem distribuição manual direta. Suas evoluções e ganhos de atributos ao subir de nível são definidos por **proficiência baseada em suas ações reais em combate** (usar golpes físicos fortalece STR/VIT, magias fortalecem MAG/WIS, esquivas/passos fortalecem AGI, etc.), modulados pela postura do menu Tactics e pela Nature do aliado.

## Ambiguidades em aberto (perguntar antes de agir)

- Taxas exatas de acúmulo de proficiência por ação (serão especificadas na fase de design detalhado).

## Estado no código

Nenhuma alteração.
