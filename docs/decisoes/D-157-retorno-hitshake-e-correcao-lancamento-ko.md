# D-157 — Retorno do Hit Shake nos Ataques e Correção do Lançamento de K.O. à Distância

- **Data:** 2026-11-03
- **Área:** Combate / Game Feel / Câmera / VFX
- **Origem:** Conversa

## O que o criador disse (literal)

> "traga devolta hitshake nos ataques, com menos intensidade que o hitshake do hit final, inclusive corrija o erro do hit final não estar lançando o inimigo, apenas o girando, é pra ele ser lançado longe"

## Decisão

1. **Hit Shake nos Ataques Normais (Menor Intensidade):**
   - Ataques físicos e projéteis que acertam o alvo voltam a disparar tremor de câmera (Hit Shake), calibrados com intensidade deliberadamente inferior ao K.O. final:
     - **Golpes normais:** trauma de câmera de ~0.35 (energia efetiva ~12% do K.O.), sem FOV-kick agressivo, com decaimento seco e rápido (~0.12s) para impacto tátil crocante sem desorientar o jogador.
     - **Golpes pesados (Fraqueza / Crítico / Poder >= 1.4):** trauma de câmera de ~0.55 (energia efetiva ~30% do K.O.), com micro FOV-kick de ~1.5° e decaimento ágil (~0.18s).
     - **K.O. final (D-049):** preserva trauma máximo de 1.0, FOV-kick de 4.5° e tremor direcional épico estendido.
   - Vetor do tremor acompanha a direção contrária ao impacto do golpe (`-hit_dir`).

2. **Correção do Lançamento de K.O. ("Lançar longe" em vez de apenas girar):**
   - **Distância ampliada:** O alcance horizontal do arremesso balístico de K.O. é aumentado para 28–36 metros (substituindo a escala insuficiente anterior de 9 metros, que mal saía do slot do inimigo a 30m da câmera).
   - **Arco e Altura:** Arco parabólico elevado para 7.0–9.5 metros de altura no ápice.
   - **Impulso inicial explosivo:** O avanço horizontal utiliza curva não linear (ease-out), fazendo o modelo explodir para trás nos primeiros instantes do impacto e desacelerar gradualmente na descida.
   - **Correção da rotação (eliminação do efeito pião):** A rotação do modelo durante o voo passa a ser função direta e determinística do progresso do voo (`prog`), executando um capotamento / backflip limpo de ~1.25 a 1.5 rotações distribuídas uniformemente ao longo de todo o trajeto, corrigindo o acúmulo contínuo que causava rotação em alta velocidade no mesmo ponto.
   - **Componente de projeção lateral:** Inclusão de leve deflexão lateral baseada na posição do inimigo, permitindo que a parábola se desenhe com clareza no campo de visão da câmera cinemática.
   - **Dissipação e desaparecimento:** O inimigo desvanece suavemente ao aterrissar ou atingir o horizonte distante, acompanhado de rastro de fumaça cinemática e nuvem de impacto.

## Ambiguidades em aberto (perguntar antes de agir)

Nenhuma (requisito direto e pontual do criador).

## Estado no código

Em implementação (`battle_camera.gd`, `battle_fx.gd`, `fx_motion.gd`).
