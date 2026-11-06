# D-916 — Burn: regras (primeiro tick, reaplicação, morte) e aplicação pelo Fire Bullet

> **Renumerada em 2026-11-06:** D-238 → D-916. O ID D-238 já pertence a outra decisão no `origin/main`; o conteúdo local foi preservado com o novo ID.


- **Data:** 2026-11-04
- **Área:** Combate / regras de status
- **Origem:** Conversa. O criador pediu "Implementar Burn" (depois de aprovar o visual na D-915) e respondeu às perguntas desta rodada.

## Respostas do criador (escolhas expressas)

1. **Primeiro tick:** "1 s depois do acerto". Ticks em 1 s, 2 s, 3 s e 4 s (4 ticks de 2 HP = 8 HP no total).
2. **Reaplicação:** "Renova os 4 s". Um Burn novo sobre alvo queimando volta o contador para 4 s; não acumula dano por segundo (continua 2 HP por segundo).
3. **Morte pelo Burn:** "mata com o personagem ativando a animação de morte sem ser lançado". O tick pode derrotar o alvo: toca a animação de morte (`down`) e o personagem **não** é lançado (sem o lançamento de K.O. da D-049/D-903), nem inimigo nem aliado.
4. **Escopo:** "Regras do Burn + Fire Bullet". Status com 4 s, ticks de 2 HP **fixos** (não passam por Defense nem por estágios de buff), aplicado quando o Fire Bullet **interrompe uma ação do alvo**. **Fora** desta entrega: HUD real (fundo laranja chamuscado), contorno e chamas no modelo 3D. Só o Fire Bullet aplica Burn por enquanto.

## Regras aplicadas (as da ficha da D-914 + as respostas acima)

- Burn dura 4 s: 2 HP por segundo, o primeiro tick 1 s depois da aplicação.
- O dano do tick é fixo e não é crítico, esquivável nem interrompe/empurra o alvo; **não** gera recompensa de ATB nem hit-stop.
- Aplicação: o golpe do Fire Bullet **interrompeu uma ação do alvo** (`info["interrupted"]`, D-914) e o alvo continua vivo. Interromper é o gatilho; a ficha não dá chance (100% quando interrompe).
- Burn continua durante o wind-up, o movimento e a pausa de ATB do alvo; para quando o motor está pausado (status pausa, hit-stop, fim da batalha) como qualquer outro cronômetro.
- Ao fim da batalha o Burn é apagado.

## Ambiguidades em aberto (não decididas; escolha mínima do código abaixo)

- Sem HUD nem VFX do Burn no jogo ainda: só log de batalha e sinais para uso futuro.
- Reaplicação durante a mesma contagem: a cadência de 1 s é mantida e os 4 ticks voltam a ser 4 (o Burn dura 4 s a partir do próximo tick); é a leitura mínima de "renova os 4 s".
- O morto por Burn não toca o desaparecimento com partículas (D-080), que é do lançamento fatal; só `down`.
- Resultado da batalha quando o Burn mata o último inimigo ou o último aliado: segue as regras de fim de batalha já existentes (D-105/D-107).
- Pendências da D-914 que continuam abertas: MP, `10 + MAG`, chance de Burn do Splitter Flames.

## Estado

Implementada e testada (2026-11-04). Código: `Combatant` (`burn_ticks_left`, `burn_clock`, `apply_burn`, `is_burning`, `clear_burn`, `take_damage(amount, fixed)`), `Battle` (`_tick_burn`, sinais `burn_applied`/`burn_ticked`/`burn_ended`, aplicação no `_hit` do Fire Bullet que interrompe), `BattleScene._on_died` (morte por Burn: animação `down`, sem lançamento). Testes: `tests/battle/test_d238_burn.gd` (regras: 19 verificações) e `tests/vfx/test_burn_scene.gd` (na cena, nos dois lados: queima, tick de 2 HP, morte com `down` e sem lançamento). Não mostrados no jogo: HUD do Burn e VFX no modelo (fora do escopo); só o log de batalha ("X está queimando", "X sofre 2 de Burn").
