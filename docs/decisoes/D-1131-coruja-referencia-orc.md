# D-1131 — Coruja: corrigir caminhada com referência principal no Orc

## Frase literal
> va no tact ou no crawlmon pra ver a referência maior, a forma como o cyclops e o orc se movimenta, especificamente o orc e faça as correções necessárias no movimento do boneco que está aberto no blender

## Decisão
Usar os clipes originais de locomoção do Crawlmon, especialmente o Orc, e o Cyclops como referência secundária para corrigir a caminhada atualmente aberta no Blender. Base verificada: `owl_walk_monster_arc_v17.blend`, Action `Walk 5 Monster Lunge 180`, incluindo alterações não salvas. Preservar essa base em cópia antes de editar e produzir nova Action/arquivo. Manter as escolhas já aprovadas em D-1109; não integrar no jogo nem alterar regras de combate.

## Estado
Referências `cm_00_0020_01` e `cm_00_0065_01` inspecionadas visualmente no Blender. Salvo `assets/modelos/owl/blender/owl_walk_monster_arc_v18_orc.blend`, Action `Walk 6 Orc Grounded`. Backup do estado não salvo: `owl_walk_v17_before_orc_review.blend`.

Corrigidos os alvos inalcançáveis dos pés, sua altura e a continuidade da pose dos pés entre início/fim. Somente 14 canais dos controles dos pés mudaram; corpo, braços, trajetória raiz, quatro passos e duração de 45 frames preservados. Inspeção frontal/lateral e Motion Lens executados. Em 177 amostras a cada 0,25 frame, alcance máximo das pernas 95,96%, menor altura da malha 0,00133 m (antes até -0,080 m). Ainda há deslizamento parcial e alertas heurísticos de equilíbrio/arco; não se declara validação artística nem integração no jogo. Sem publicação no GitHub (não há autorização de push).

## Ambiguidades
Nenhuma nova regra de jogo definida. Aprovação artística da correção permanece com o criador.
