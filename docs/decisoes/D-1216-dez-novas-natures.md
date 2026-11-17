> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.

# D-1216 — Dez novas Natures (de 8 para 18)

Data: 2026-11-14

## Frase literal do criador

> "isso significa que tá na hora de criar mais 10 novas natures, me surpreenda, lhe dou a liberdade"

## Decisão

Criar mais 10 Natures. O criador deu liberdade à IA para defini-las.

## As 10 Natures definidas pela IA (sob a liberdade dada)

Regras que a IA seguiu, tiradas das 8 atuais (`scripts/data/nature_data.gd`, D-393, D-271): valores inteiros flat, soma zero, +3 de um lado e −3 do outro, nenhum valor acima de 3. Além disso, cada uma modifica **exatamente 3 status**, para preencher os 3 rolos de D-1215.

| ID | Nome | Mods | `atb_reserve_bias` | `aggression_mult` | Descrição (sem citar status, D-432) |
|---|---|---|---|---|---|
| `bold` | Bold | VIT +3, STR −2, AGI −1 | 0.5 | 0.8 | Holds the line and outlasts the enemy. |
| `impish` | Impish | VIT +2, LUK +1, MAG −3 | 0.0 | 1.1 | Takes the hit on purpose and grins about it. |
| `relaxed` | Relaxed | VIT +2, WIS +1, AGI −3 | 1.0 | 0.7 | Never rushes; acts late and stays standing. |
| `hasty` | Hasty | AGI +3, VIT −2, WIS −1 | −1.0 | 1.3 | Acts first and thinks later. |
| `naive` | Naive | AGI +2, STR +1, WIS −3 | −0.5 | 1.2 | Charges in with no fear of tricks. |
| `rash` | Rash | MAG +2, AGI +1, WIS −3 | −1.0 | 1.4 | Casts the moment it can, whatever the cost. |
| `quiet` | Quiet | MAG +2, WIS +1, AGI −3 | 1.0 | 0.9 | Waits, stores power and answers once. |
| `careful` | Careful | WIS +3, MAG −2, LUK −1 | 0.5 | 0.7 | Leaves nothing to chance. |
| `lonely` | Lonely | STR +3, VIT −2, WIS −1 | −0.5 | 1.3 | Fights alone, hits hard, guards nothing. |
| `quirky` | Quirky | LUK +3, VIT −2, STR −1 | 0.0 | 1.0 | Bets everything on the lucky hit. |

## Ambiguidades em aberto (nada disto está decidido)

1. Brave, Timid, Calm e Adamant ficaram com 3 status cada pela D-1217 (atualizado: D-1217).
2. Chance de sorteio: as 18 com a mesma chance ou pesos diferentes.
3. Hardy e Docile continuam as únicas "puras".

## Estado

Implementada em 2026-11-15: as 10 Natures estão em `nature_data.gd` (18 no total), em `PreGameCatalog` (`NATURE_ORDER`, descrições) e em `COMBO_EV_TABLE` (108 linhas, geradas com a fórmula do próprio controlador; as 48 antigas foram reproduzidas 48/48 como controle). `NatureData.INITIAL_IDS` guarda as 8 iniciais: sorteios fora da roleta (`CharacterFactory`, D-405) seguem nelas até o criador decidir o pool de aliados e inimigos.
