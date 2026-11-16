<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1231 — RESPECT: Respeito por feitos, individual do Traveler

**Data:** 2026-11-15  
**Área:** progressão, recrutamento, narrativa  
**Estado:** **parcial:** `RespectState` existe e é aplicado na retirada estratégica e na derrota de expedição (`game_state.gd`); os feitos +2, +6 e +3 ainda não têm chamador, e o Respeito ainda não entra na chance do Employ.  
**Origem:** briefing "IMPLEMENTAÇÃO FASEADA DE EMPLOY, SUMMON E RESPEITO" colado pelo criador.  
**Relacionadas:** D-1210 (Respeito como sistema novo; perder a corrida de rivais = perda de Respeito), D-1230, D-1089, D-316.

## Texto literal do briefing do criador

> "Respeito representa a credibilidade individual do Traveler como combatente e líder de expedições, não moralidade, amizade, bondade ou reputação da guilda."

> "Valor inicial: 50. Limite mínimo: 0. Limite máximo: 100. Valor neutro para Employ: 50. Penalidade máxima em Employ: −8 pp. Bônus máximo em Employ: +8 pp."

> "Vitória em encontro desafiador elegível: +2. No máximo três recompensas dessa categoria por expedição. Primeira vitória contra chefe importante: +6. Desafio tático especial aprovado: +3. Derrota definitiva da expedição: −2. Retirada estratégica: 0. Fracasso de Employ: 0. Sucesso de Employ: 0. Repetir inimigos fracos: 0. Repetir um feito de primeira vitória já reconhecido: 0."

> "O Respeito pertence ao Traveler individual. Não deve ser copiado para outro personagem quando a ordem da equipe mudar."

> "A abordagem escolhida é avaliar a ameaça do encontro a partir de um snapshot pré-combate, considerando o poder relativo disponível à expedição. O jogador não deve conseguir tornar um encontro artificialmente difícil removendo companheiros fortes pouco antes da batalha."

> "Personagens podem mencionar conquistas relevantes do Traveler. As reações podem variar de acordo com a personalidade. Não criar bônus ocultos de chance por personalidade. Não criar um sistema completo de relacionamento com NPCs."

## Decisão

1. Respeito: 0 a 100, inicial 50, neutro 50; pertence ao Traveler, não à posição na equipe.
2. Tabela de ganhos e perdas acima. Recrutar (sucesso ou fracasso) não mexe no Respeito.
3. Encontro desafiador é avaliado por snapshot pré-combate.

**Atualização 2026-11-15 (D-1235):** o criador definiu que "Travelers são os grupos de 3 personagens, o prota é um deles" e que o Respeito pertence "Ao grupo". O item 1 passa a valer para o grupo de Travelers, não para um personagem.

## Pendências declaradas pelo criador

- Fórmula do índice de ameaça e limiar de elegibilidade ("Não inventar esses valores"; o +2 automático não é ativado sobre classificador arbitrário).
- Identidade narrativa de cada Nature.

## Conflitos e pendências achados na auditoria (perguntar)

- **D-1210:** "Perder a corrida = só perda de Respeito" não aparece na tabela nova (valor não definido).
- **"Traveler" não existe no código:** o líder é `party[0]` (`combatant.gd:437`, `game_state.gd:28`) e o personagem é identificado por espécie (`species_key`, `game_state.gd:44`), sem identidade individual. O seletor de debug troca quem é controlado.
- **Chefe:** não há marcação de chefe nem de "chefe importante" no código; "desafio tático especial aprovado" não tem lista.
- **Expedição:** não há contador de expedição nem evento de vitória de expedição; derrota definitiva passa por `GameState.end_battle(false)` (`game_state.gd:312-333`), retirada por `return_to_hub_from_expedition` (`game_state.gd:227`).
- **Persistência:** não existe save em disco ("no save yet", `game_state.gd:31`); tudo vive em memória na sessão.

## Estado no código

Nada implementado.
