# D-275 — Rodada 84 reformulada Q3 (C): biblioteca de Moves permanente com preparação restrita

- **Data:** 2026-11-05.
- **Área:** Progressão / aprendizado de Moves / preparação da equipe.
- **Origem:** escolha expressa **C** da resposta literal do criador `C C C A` à Rodada 84 reformulada.
- **Estado:** estrutura de aprendizado/equipamento aprovada; implementação e locais específicos pendentes.

## Pergunta e alternativa aprovada

**Pergunta:** "O que acontece quando um Pokémon aprende mais de oito Moves?"

> C — Biblioteca com preparação restrita: conserva todos os Moves, mas só pode alterar os oito equipados em locais seguros ou entre expedições.

**Resposta literal do criador:** `C C C A` (terceiro **C**).

## Regra aprovada

- Cada Pokémon **conserva na própria biblioteca todos os Moves aprendidos**, mesmo quando o repertório excede **oito**; aprender um novo Move **não exige esquecer permanentemente** outro.
- O Pokémon pode **equipar até oito Moves utilizáveis em combate**, conforme **GDD R38-Q5 / D-032 (R39-Q2)**, com **quatro Moves principais destinados às hotkeys** e **Tackle separado**. O total de Moves aprendidos na biblioteca não aumenta o limite dos oito utilizáveis simultaneamente.
- **Alterar quais Moves estão equipados** é uma ação de **preparação restrita**, permitida **em locais seguros ou entre expedições**, não como troca livre a qualquer instante de batalha ou exploração.
- Preservar as fontes de aprendizado já aprovadas em **GDD R23-Q5/R27-Q4**: nível/progressão como fonte principal dos Moves comuns, além de mestres, HMs/TMs de combate e outros meios específicos. **Não** criar mecanismo novo de PP, consumo de Moves ou custo para equipar.
- **Exemplo ilustrativo:** um Pokémon com onze Moves aprendidos poderá manter os onze na biblioteca, mas selecionar no máximo oito para uso durante a expedição; em uma oportunidade de preparação permitida, poderá substituir um equipado por outro da biblioteca sem esquecê-lo.

## Pendências e limites

- Não estão definidos **quais locais contam como seguros** para esta preparação, se um ponto de descanso da D-311/D-316 é um desses locais, a interface, as regras de troca de hotkeys, requisitos adicionais, ou como a biblioteca será persistida.
- Não inferir autorização para trocar Moves dentro do combate, no meio de um encontro hostil, ou fora dos momentos autorizados. Não alterar o máximo de oito Moves nem a elegibilidade de Tackle.
- **D-235:** Moves e efeitos permanecem independentes de personagem, time e lado de campo em sua execução, embora a biblioteca dos Moves aprendidos pertença a cada Pokémon.
- Nenhum código, teste, menu, ficha de Move, cena, asset, IA ou VFX modificado; somente documentação.
