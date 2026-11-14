<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-402 — Concessão de experiência exclusivamente para combatentes sobreviventes

- **Data:** 2026-11-07
- **Área:** Combate / Progressão / Experiência
- **Origem:** Recomendações técnicas formuladas no Concepts Brief e aprovadas pelo criador na conversa.
- **Estado:** regra registrada; sem código.

## Declaração literal do criador

> "eu não tenho ideia de como mexer com estes valores, sigo suas recomendações"

## Regra aprovada

1. **Requisito de Sobrevivência:**
   Apenas combatentes da equipe que terminarem a batalha vivos (com `hp > 0`) recebem os pontos de experiência do combate.
2. **Combatentes Nocauteados (K.O.):**
   Combatentes com `hp <= 0` no instante do término da luta não recebem XP acumulado da vitória. Seus contadores de proficiência de ações executadas durante o combate são preservados, mas eles não sobem de nível nem avançam barra de experiência naquela batalha.
3. **Propósito de Design:**
   Valorizar e incentivar ativamente o suporte tático, uso de habilidades de cura (Media), escudos/defesas e consumíveis (Poções) durante a luta para manter todos os companheiros vivos.

## Ambiguidades em aberto (perguntar antes de agir)

- Nenhuma identificada.

## Estado no código

Nenhuma alteração.
