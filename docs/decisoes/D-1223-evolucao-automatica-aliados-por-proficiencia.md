<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1223 — Evolução automática de aliados por proficiência em combate, Nature e Tactics

- **Data:** 2026-11-15.
- **Área:** Personagens / Combate / Pós-combate / UI.
- **Relacionadas:** D-394 (regra base de proficiência de aliados), D-401 (líder aloca manualmente), D-1185, D-1192 (tela de pós-combate), D-235 (simetria e independência de personagem/lado).
- **Status:** **aprovada; em implementação.**

## O que o criador disse (literal)

> não da pra ver que stats o aliado recebe quando ele upa de nivel

> vamos definir então

> use sua skill de game designer e editor de crawlmon e me recomende suas opções

> sigo sua recomendação, mas antes faça mais uma auditoria por erros em seus pensamentos

> Sim

## Decisão

Fecha os critérios pendentes da **D-394** e **D-1192** para a evolução automática de aliados (não-líderes):

1. **Acumuladores de proficiência no `Combatant` (`proficiency_points`):**
   - Cada `Combatant` mantém acumuladores persistentes para os 6 atributos (`STR`, `MAG`, `VIT`, `WIS`, `AGI`, `LUK`), sem depender de personagem ou lado (**D-235**).
   - **Ações reais que pontuam (sem ruído de `step()` nem multiplicação por multi-hit/AoE/bounce):**
     - Ataque básico ou Move físico (1× por execução): `+3 STR`
     - Move mágico (1× por execução): `+3 MAG`
     - Move de Status / Cura / Buff / Debuff (1× por execução, fora de `_hit()`): `+3 WIS`
     - Usar `Guard`: `+3 VIT` | Receber golpe direto (1× por ataque sofrido): `+1 VIT`
     - Esquiva válida (`EVADE` manual ou `auto_dodged`): `+3 AGI`
     - Acertar crítico: `+2 LUK`
2. **Escolha do stat ao subir de nível (Nature + Tactics + desempate):**
   - Para cada ponto concedido ao aliado (`1` em nível comum, `3` em marcos a cada 10 níveis), calcula-se o score efetivo de cada atributo:
     `score[stat] = proficiency_points[stat] + nature_bonus[stat] + tactics_bonus[stat]`
   - `nature_bonus`: `+2` por ponto positivo em `NatureData.mods` (se a Nature não tiver modificador positivo, como *Hardy*/*Docile*, `+2` no maior `innate_stat` da espécie).
   - `tactics_bonus`: `+1` no stat correspondente à postura (`Act.ATTACK` → `STR`, `Act.SKILL` → `MAG`, `Act.HOLD` → `WIS`; `React.EVADE` → `+1 AGI`).
   - **Desempate determinístico:** maior `innate_stat` da espécie; persistindo o empate, ordem canônica fixa `STR → MAG → VIT → WIS → AGI → LUK`.
3. **Gasto sem efeito mono-stat:**
   - O stat vencedor recebe `+1` em `progression_points`, e **apenas `proficiency_points[vencedor]` é zerado**; os outros 5 stats mantêm seus pontos acumulados para os próximos níveis.
   - Em marcos de 10 níveis (`+3` pontos) ou múltiplos níveis ganhos de uma vez, a escolha e o zeramento ocorrem **1 ponto por vez**.
   - A alocação ocorre dentro de `Combatant.add_experience()` **antes** de `update_resource_maximums()`, garantindo que `max_hp` (`+2/VIT`) e `max_mp` (`WIS`) já atualizem no mesmo nível.
4. **Exibição na tela de Level Up (`PostCombatScreen`):**
   - O painel da direita (`ATTRIBUTES / AUTOMÁTICO`) exibe a base anterior (`old_stats`) + `+N` verde-lima e destaque dourado na(s) linha(s) que receberam ponto, evitando soma dupla com `c.get_effective_stat()`.
   - O card da esquerda exibe o motivo resumido (ex.: foco predominante + Nature).
