# D-1132 — Coruja: pulinhos sincronizados com a corrida do Orc

## Frase literal
> tu realmente comparou? cade os pulinhos, o movimento sincronizado entre cada passo parecendo que ele está pulando a cada passo? com que animação tu comparou? a idle? era pra comparar com a de corrida walk dele...

## Decisão
Aplicar à caminhada atual a impulsão, suspensão com ambos os pés fora do chão e compressão de aterrissagem a cada passada, usando o walk/run `cm_00_0020_01` do Orc. Corrigir a omissão da D-1131; manter quatro passos em 45 quadros, a postura monstruosa e uma cópia da versão anterior. Nenhuma mudança de regras ou integração no jogo autorizada.

## Estado

### Correção após rejeição da v19
O criador rejeitou o resultado e mandou executar a correção. A v19 não constitui aprovação: sua curva de salto artificial não reproduziu a coordenação do Orc. A próxima versão deve derivar a passada das poses avaliadas do clipe original `cm_00_0020_01`, incluindo as direções dos segmentos das pernas, articulação dos pés e fases de voo/apoio, adaptadas aos comprimentos reais da coruja. Preservar cópias anteriores, quatro passos/45 frames e postura superior monstruosa; verificar lado a lado com a referência.

### v20 — transferência medida
Criada `Walk 8 Orc Measured Locomotion` em `owl_walk_monster_arc_v20_orc_measured.blend`. Foram avaliadas 33 poses reais do Orc, com mapeamento temporal `orc_frame = (1,6 + (owl_frame-1)*12,8/22) mod 12,8`: contato em 1, compressão em 3,75, impulso em 6,5, voo em 9,25, próximo contato em 12. As direções coxa/joelho/tornozelo, rotação do pé e quadril vêm dessas poses, adaptadas aos comprimentos da coruja, com correção de alcance entre chaves. A altura de suspensão vem da menor altura medida da malha original, proporcional aos membros; não de uma senoide inventada. A pose superior monstruosa foi preservada.

Criada cena separada `COMPARE Orc walk - Owl measured`, com referência e resultado em escala proporcional e fases sincronizadas, sem translação horizontal apenas nessa cena de comparação. A cena original conserva o avanço. Inspeção de frente e perfil, Motion Lens e varredura de 177 amostras realizadas. Provas de fases e relatório junto ao `.blend`. Aprovação artística e integração no jogo continuam pendentes.
Implementado em `owl_walk_monster_arc_v19_orc_hops.blend`, Action `Walk 7 Orc Hop Each Step`, aberta em reprodução. Quatro impulsos em 45 frames, ápices em 6,5 / 17,5 / 28,5 / 39,5. Suspensão real dos dois pés: menor ponto da malha a aproximadamente 9,7 cm no ápice. Compressão do quadril após contato e retorno ao apoio em cada passada. Preservadas as rotações do corpo e braços, trajetória horizontal e versão anterior. Motion Lens e 177 amostras executados; folga final de chão ajustada para eliminar penetração observada. Inspeção visual lateral realizada. Restam alertas de arco/equilíbrio e deslizamento; não testado no jogo. Aprovação artística pendente. Sem push.
