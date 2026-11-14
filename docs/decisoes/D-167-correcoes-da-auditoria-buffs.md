<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-167 — Correções da auditoria de buffs (D-158/D-159)

- **Data:** 2026-11-03
- **Área:** Combate / Visual
- **Origem:** Conversa

## O que o criador disse (literal)

> faça estas correções

Resposta à pergunta "Corrijo os pontos que restaram da auditoria?".

## Decisão

1. **Karate Chop no limite:** em -5 SPD, o log avisa o limite, em vez de dizer que reduziu.
2. **Efeito no limite:** Tarukaja, Rakunda e Sukunda sem efeito não mostram VFX nem popup de alteração.
3. **Taunt sobre +5:** o bônus temporário não passa do estágio +5.
4. **Cor do contorno em ±3:** não passa da cor do último nível; +3 e -3 usam a cor de ±2.
5. **ATK durante o próprio ataque:** o tamanho novo não se perde quando o buff entra no meio do ataque.
6. **Rachadura do `-def`:** implementada, conforme a frase do criador em D-158. Aumenta até -3, junto com o teto visual da D-159.
7. **Fim da batalha:** os sobreviventes voltam ao tamanho, velocidade e contorno normais ao terminar a batalha.

## Escolhas do agente, para o criador conferir

- Item 3: o criador não disse se o bônus do Taunt conta para o limite; apliquei o limite por ser o apontamento aceito.
- Item 6: a aparência da rachadura (linhas escuras sobre o modelo) é proposta minha.
- Item 7: inimigos derrotados ficam de fora, para não interferir no encolhimento de D-166.

## Estado no código

Implementado (`battle.gd`, `combatant.gd`, `battle_fx.gd`, `fx_motion.gd`, `fx_projectiles.gd`, `vfx_lib.gd`, `smt_buff_controller.gd`, `shaders/def_crack.gdshader`).
