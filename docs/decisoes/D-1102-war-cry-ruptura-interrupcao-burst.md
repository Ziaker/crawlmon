<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1102 — War Cry: Ruptura, interrupção de wind-up e +1 Burst

- **Data:** 2026-11-10.
- **Área:** Combate / Moves / Status / ATB / Burst.
- **Origem:** escolha do criador depois da rodada de opções do War Cry.
- **Status:** regra registrada; **implementada**; aguardando teste in-game.

## O que o criador disse (literal)

> "wind-up de .3 pro war cry, custo em atb de 3."

> "opcao 4 pro war cry, com o bonus de ganhar 1 Burst (unico, mesmo se afetar 2 ou mais inimigos) se interromper alguem"

## Decisão

1. **War Cry = opção 4 (Ruptura).** Move `war_cry`, `STATUS`, elemento **Neutral** (o `FISICO` do código), sem dano.
2. **Custo:** **3 ATB / 3 MP**. O MP continua 3; o ATB sobe de 1 para 3.
3. **Wind-up:** **0,3 s**. A pausa de status segue a regra do motor: 0,3 s de wind-up + 1,0 s de cauda (D-031) = **1,3 s** no total.
4. **Alvo:** todos os inimigos vivos; **AoE inimiga sem trajetória** (ícone ○, D-403). Tipo Status, sem ícone de tipo (D-395).
5. **Interrupção:** no momento em que o Move resolve, todo inimigo que estiver **em WINDUP** tem a ação **cancelada**; o golpe não sai e o ATB já gasto **não volta**.
6. **Não afeta:** quem já está em STRIKE/TRAVEL/impacto; projétil já em voo; quem está em Guard ou sem wind-up.
7. **Sem dano, sem STUN, sem empurrão.** Se ninguém estiver em wind-up, o custo é pago e nada acontece.
8. **Burst:** se ao menos **um** inimigo for interrompido, o lançador ganha **1 Burst**. É **único por execução**, mesmo que o grito interrompa 2 ou mais inimigos.
9. **Simetria:** vale para qualquer personagem, time e lado (D-235); a IA pode usar nas mesmas condições (D-021).
10. **VFX:** não definido por esta decisão; quando for feito, segue D-308.

## Segunda rodada

> "1,3s para testar in-game depois"

- **Pausa total confirmada em 1,3 s** (0,3 s de wind-up + 1,0 s de cauda da D-031). O valor será testado in-game depois; se o teste pedir outro total, é ajuste novo.

## Atualização — D-1127 (pausa removida só no War Cry)

> "O move tá ocorrendo antes do que devia, o efeito está estranho por conta da regra de pausar as coisas, remova esta pausa APENAS NESTE MOVE pra eu ver uma coisa"

O War Cry deixa de pausar o motor (exceção experimental à D-031). O valor `status_pause = 1,3 s` continua registrado na ficha, mas não é aplicado em tempo de jogo. Custo, wind-up de 0,3 s, interrupção só de WINDUP, +1 Burst e ausência de dano/STUN/empurrão continuam iguais. Detalhes em `docs/decisoes/D-1127-war-cry-sem-pausa-de-status.md`.

## Notas de implementação

- `Battle.interrupt_windup_of()` cancela só `Incoming` em `WINDUP`, sem usar o empurrão de `_interrupt_attacks_of`.
- O behavior `WarCry` fica em `scripts/combat/moves/move_behaviors.gd` e é roteado por `move_id` (`war_cry`) no registry.
- O +1 Burst usa `Battle.grant_burst` uma vez por execução; se o Burst já estiver em 5, não ganha outro.
- O `.tres` do `war_cry` passou a 3 ATB / 3 MP / wind-up 0,3 s / `is_aoe=true` / `status_pause=1,3`.

## Estado no código

Implementado (2026-11-10), **aguardando teste in-game**:
- `content/moves/war_cry/move.tres`, `scripts/data/skill_legacy_data.gd`, `scripts/data/skill.gd`.
- `scripts/combat/battle.gd` (`has_windup`, `interrupt_windup_of`), `scripts/combat/moves/move_behaviors.gd` (`WarCry`), `scripts/combat/moves/move_behavior_registry.gd`.
- Teste: `tests/battle/test_d1102_war_cry.gd` (passa).
- Vídeos in-game (2026-11-10): `test_captures/vfx_tools/war_cry_d1102_dqt.mp4` (Orc no lado do jogador na vista normal; espelhado) e `war_cry_d1102.mp4` (party padrão). Log normal: Tackle cancelado em **1,167 s**, impacto de War Cry com **dano 0**; Burst flamejante visível no cartão do Orc. VFX **genérico** de status; o audit de vazamentos acusou **2 nós residuais** (não é VFX final D-308).
