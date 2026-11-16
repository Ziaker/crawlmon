# D-1222 — Todo Move é visualmente 3D; tratá-lo como 2D é proibido sem ordem explícita

- **Data:** 2026-11-15.
- **Área:** VFX de Move / protótipos / debug.
- **Relacionadas:** D-1209, D-1218, D-308, D-235, D-1221.
- **Status:** regra permanente.

## O que o criador disse (literal)

> "ENFIA ISSO NA MERDA DA MEMORIA DO PROJETO E DE TODOS OS DOCUMENTOS, NUNCA NUNCA NUNCAAAAAAAAAAAAAAAAAAAA FAZER UM MOVE SENDO VISUALMENTE TRATADO COMO 2D A NÃO SER QUE EU EXPLICITAMENTE MANDE"
> "o maior problema é seu, vc trata o move como se ele fosse 2D e não 3D, a mão nem se move, a mão tá toda errado parece um tapa e não um corte"
> "é pra ser como o movimento dos ataques do Pancham e do Abra"

## Decisão

1. Todo Move (efeito, mão, arma, trajetória, impacto, protótipo HTML) é **3D de verdade**: trajetórias curvas no espaço (x, y e z), rotação de pulso/lâmina/aresta, volume, luz e sombra. **Nunca** definir o movimento num plano único, deslizar uma peça rígida numa diagonal, nem aceitar "câmera 3D com movimento 2D".
2. 2D (plano, sprite, flipbook chapado) **só** quando o criador mandar explicitamente, Move a Move.
3. Referência de movimento por padrão: a trajetória 3D real dos ossos dos ataques normais (Abra, Pancham), extraída com o Motion Lens / Blender (`hand_path.py`: posição da mão por quadro relativa ao quadril, nos 3 eixos), e não um plano inventado.
4. Antes de aprovar um Move ou protótipo: conferir a trajetória nas três vistas (topo, lado, frente), não só numa câmera.
