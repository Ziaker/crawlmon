# D-964 — Carga à frente no eixo do tiro, com folga de 1,1 m (substitui o deslocamento lateral da D-963)

- **Data:** 2026-11-07.

## Frase literal do criador

> agora ao invés de estar na frente, esta do lado, distancie um pouco mais o personagem do efeito e corrija este erro, veja em outros angulos de câmera também, mesmo que não seja angulos que estamos usando, é só pra ter uma referência melhor

## Decisão

1. A carga fica **exatamente à frente** do corpo, no eixo atacante→alvo: extensão do corpo nesse eixo + **1,1 m de folga**. **Não há deslocamento lateral**, e a câmera nunca move a carga. A regra lateral da D-963 item 1 foi **revogada**.
2. A conferência passa a incluir outros ângulos da sala de VFX ("Visão do atirador", "Órbita", "Lateral"), só como referência. Para isso, `--cam` agora aceita o modo 4 (Lateral).

## Verificado

`test_captures/electric_beam_v9_frente.mp4` (duas vistas) e `test_captures/electric_beam_v9_angulos.png`. Linhas da imagem: câmeras 0, 2, 3 e 4; colunas: vista normal e espelhada, em t = 1,0 s e 1,37 s. Na "Visão do atirador" da vista espelhada, a carga e o disparo aparecem à frente das mãos do Abra. Na vista espelhada de jogo, o atacante está de frente para a câmera, então a carga aparece sobre a silhueta, mas à frente dela.
