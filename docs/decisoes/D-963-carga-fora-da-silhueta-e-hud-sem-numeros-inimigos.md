# D-963 — Carga fora da silhueta na tela; HUD sem números de HP/MP dos oponentes

- **Data:** 2026-11-07.

## Frase literal do criador

> vc não fez a correção maior, ainda não está na frente do personagem, está dentro dele, além disso, na hud do combate, não é necessário mostrar os valores de Hp e Mp dos oponentes.

## Causa (dados)

Na vista espelhada, a carga estava 3,1 m à frente do corpo, mas na direção da câmera. Na tela ela caía sobre a silhueta e lia como "dentro".

## Decisão

1. Quanto mais o tiro aponta para a câmera (ou para longe dela), mais a carga é empurrada para o lado, além da borda do corpo: lateral = metade da largura + alinhamento × (0,6 × largura + 0,3 m). Assim ela lê "à frente" nas duas vistas. Regra geral junto com a D-958.
2. HUD: a ficha dos oponentes não mostra os números de HP e MP. As barras continuam.
