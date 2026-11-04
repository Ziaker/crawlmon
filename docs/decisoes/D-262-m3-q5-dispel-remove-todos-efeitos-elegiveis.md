# D-262 — Fichas de Moves M3-Q5 (5A): Dispel remove todos os efeitos elegíveis declarados na ficha

- **Data:** 2026-11-04.
- **Área:** Fichas de Moves / Rodada M3, questão 5.
- **Origem:** decisão expressa do criador (5A).
- **Estado:** regra de design aprovada e documentada; implementação e dados individuais pendentes.

## Declaração literal do criador

> 55A — Dispel remove todos os efeitos elegíveis declarados na ficha, respeitando exceções.

> Observações e regras próprias: Tudo q não é tackle consome MP , não existe previa de dano em seleção e não deve existir, pare de inventar coisa que eu não pedi

## Regra aprovada, alcance e exemplos

- Quando o Move contiver **Dispel**, ele **remove todos os efeitos elegíveis expressamente declarados na ficha**, respeitando **as exceções aplicáveis**. Não estabelecer limite geral de 'somente um efeito' nem escolher por prioridade entre efeitos elegíveis sem instrução expressa.

- Preservar **D-249**: a ficha do Move precisa **listar expressamente** quais efeitos são removíveis e quais exceções se aplicam; não inferir que Dispel remove todos os tipos de buff/debuff ou status sem lista aprovada.

- **Exemplo abstrato, não um Move oficial:** uma ficha hipotética de Dispel declara removíveis Efeito A e Efeito B, ambos presentes e elegíveis em um alvo válido; o Dispel remove **A e B**, mas não o Efeito C excluído na ficha. Nenhum dos efeitos A/B/C é um status real homologado.

- Preservar **D-247/D-260** quanto a cada efeito individual e à herança de alvos/condições, e **D-235** quanto à independência de equipe/personagem. Esta regra **não atribui Dispel** a Media ou a qualquer outro Move existente.

- **Pendências:** listas reais por Move, instante da remoção, interação com aplicação simultânea de status, imunidades não definidas, múltiplas instâncias do mesmo efeito, resultados quando nada elegível está presente. Não criar limite ou ordem de seleção onde não há critério aprovado.

## Histórico, fontes e escopo

- Preservar **D-061**, **D-228–D-230**, **D-235**, **D-244–D-249** e todos os demais requisitos pertinentes. As novas regras não autorizam reescrever os registros históricos para apagar escolhas anteriores, apenas explicitar precedência quando houver alteração expressa.
- **Nenhuma ficha de Move operacional, código, HUD, teste, VFX, asset, cena, configuração ou dependência foi modificada nesta atualização; não foram executados testes de gameplay.**
