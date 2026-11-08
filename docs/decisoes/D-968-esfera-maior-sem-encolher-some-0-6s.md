# D-968 — Esfera do wind-up maior, sem encolher no release, some 0,6 s depois do disparo

- **Data:** 2026-11-08.

## Frase literal do criador

> pode me dizer se está usando as skills de melhora de vfx do godot e o flipbook? aumente o tamanho final da esfera do wind up e não faça ela perder o tamanho durante o release, ela deve sumir naturalmente .6 segundos depois do disparo.

Pediu também as skills `/scenario-godot-animation`, `/scenario-godot-rendering-lighting` e `/scenario-godot-shaders`.

## Resposta honesta sobre as skills (registrada)

- `scenario-godot-vfx` e `scenario-godot-shaders` estavam carregadas, mas as ferramentas delas **não** eram usadas. Agora rodou o lint de shader: só avisos informativos de transparência, intencional. A compilação por renderizador da skill **não rodou**, porque exige copiar o kit dela para `addons/agentkit/` no projeto; isso não foi feito sem autorização.
- **Flipbook: nenhum** no efeito atual (malhas, shader próprio e sprites aditivos).

## Decisão

1. A esfera de choque chega a **0,95 m** de raio no fim do pós-wind-up (antes 0,62).
2. No disparo ela **não encolhe**: mantém o tamanho e **some naturalmente em 0,6 s** depois do disparo (dissolve, junto com o brilho).
