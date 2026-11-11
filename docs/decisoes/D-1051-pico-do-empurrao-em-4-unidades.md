# D-1051 — Pico do empurrão em 4 unidades

- **Data:** 2026-11-09
- **Área:** Combate / Game Feel / Animação
- **Origem:** Conversa
- **Estado:** **implementado e aprovado pelo criador** em 2026-11-09 (encerramento da sessão).

## Frase literal do criador

> aumente o pico do empurrao pra 4 un

## Decisão

- O pico do empurrão normal passa de **2,0** para **4,0 unidades**.
- O crítico/fraqueza continua acompanhando proporcionalmente (multiplicador 1,55): o clamp passa de **1,4–3,2** para **1,4–6,2**.
- O Fire Bullet interrompido mantém o seu “empurrão especial” proporcionalmente maior: o override passa de **2,7** para **5,4 un**.
- O hold de 0,5 s (D-1049), a volta de 0,34 s e a corrida `run` (D-1050) não mudam. A corrida de volta passa a casar a velocidade dos pés com a distância maior quando o modelo tem `run_stride_speed` (D-341).
- **Só visual:** a posição lógica não muda (D-019/D-045).

## Relações

- **D-1050:** empurrão 2,0 e corrida na volta; D-1051 só aumenta o pico.
- **D-1049:** hold de 0,5 s.
- **D-1045:** recuo no impacto, âncora visual e volta.
- **D-236:** o Fire Bullet interrompido continua empurrando mais longe que o normal.
- **D-235:** testar nas duas vistas e em alvos de tamanhos diferentes.

## Estado no código

- `scripts/combat/fx/fx_motion.gd`: `clampf(4.0 * mult, 1.4, 6.2)`; `_start_return_run()` ajusta a velocidade do `run` pelo `run_stride_speed` quando existir e restaura a velocidade base no fim.
- `scripts/combat/battle_fx.gd`: override do Fire Bullet `2.7 → 5.4`.
- **Teste (normal/espelhado, relógio do FX):** pico **4,000 un**; hold medido **0,533 s** com tolerância de 0,06 (configurado 0,50 s); volta começa em **0,650 s** e termina em **0,933 s**; `run` no início e no meio da volta; `battle_idle` em 1,20 s. Modelos testados (Orc/Gible) **não** têm `run_stride_speed`, então tocaram o `run` na velocidade base; o ajuste de passada não foi exercitado.
- **Não verificado:** modelo com `run_stride_speed`, Fire Bullet a 5,4 un, crítico/fraqueza em 6,2 un e hits consecutivos durante o hold.
