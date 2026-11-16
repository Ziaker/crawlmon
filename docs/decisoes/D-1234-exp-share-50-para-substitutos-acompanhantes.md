<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1234 — EXP SHARE: substitutos acompanhantes recebem 50% do XP integral

**Data:** 2026-11-15  
**Área:** progressão, experiência  
**Estado:** **registrada; nada implementado.** Só documento (D-061).  
**Origem:** briefing "IMPLEMENTAÇÃO FASEADA DE EMPLOY, SUMMON E RESPEITO" colado pelo criador.  
**Relacionadas:** D-399, D-402, D-1184, D-1185, D-1192, D-1225, D-1233.

## Texto literal do briefing do criador

> "Substitutos acompanhantes elegíveis recebem 50% do XP integral de cada vitória. O XP dos ativos não é reduzido para financiar essa distribuição. A D-399 permanece válida para participantes ativos elegíveis, e a D-402 continua restringindo XP de personagens nocauteados. Registrar participação por identidade individual, não apenas pelo índice ocupado ao fim da luta."

## Decisão

1. Substituto acompanhante elegível recebe **50% do XP integral** de cada vitória.
2. Ativos continuam recebendo o XP integral (D-399); nocauteados continuam sem XP (D-402).
3. A participação é registrada por identidade individual.

## Pendências declaradas pelo criador

- XP de quem alterna entre ativo e substituto na mesma batalha.
- XP de recrutas obtidos durante a própria batalha.
- Tratamento de nocauteados entre os substitutos.

## Conflitos e pendências achados na auditoria (perguntar)

- **GDD R26-Q3/R31-Q3 (`REGRAS_DO_JOGO.md` §14.5):** "reservas **não** recebem XP das vitórias". O briefing dá 50% aos substitutos acompanhantes. As duas ficam preservadas até o criador dizer qual vale.
- **Arredondamento** dos 50% (XP é inteiro).
- **Tela de vitória:** o painel de XP (D-1184) e o pós-combate (D-1192) só mostram a party ativa; como os substitutos aparecem é decisão visual pendente.
- **Código:** `PostCombatFlow.grant_xp(party, total_xp)` (`post_combat_flow.gd:18`) percorre a party ao fim da luta e usa `is_alive()`; não há histórico de participação.

## Estado no código

Nada implementado.
