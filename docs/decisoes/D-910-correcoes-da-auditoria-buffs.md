# D-910 — Correções da auditoria de buffs (D-901/D-902)

> **Renumerada em 2026-11-06:** D-167 → D-910. O ID D-167 já pertence a outra decisão no `origin/main`; o conteúdo local foi preservado com o novo ID.


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
6. **Rachadura do `-def`:** implementada, conforme a frase do criador em D-901. Aumenta até -3, junto com o teto visual da D-902.
7. **Fim da batalha:** os sobreviventes voltam ao tamanho, velocidade e contorno normais ao terminar a batalha.

## Escolhas do agente, para o criador conferir

- Item 3: o criador não disse se o bônus do Taunt conta para o limite; apliquei o limite por ser o apontamento aceito.
- Item 6: a aparência da rachadura (linhas escuras sobre o modelo) é proposta minha.
- Item 7: inimigos derrotados ficam de fora, para não interferir no encolhimento de D-909.

## Estado no código

Implementado (`battle.gd`, `combatant.gd`, `battle_fx.gd`, `fx_motion.gd`, `fx_projectiles.gd`, `vfx_lib.gd`, `smt_buff_controller.gd`, `shaders/def_crack.gdshader`).
