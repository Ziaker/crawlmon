# D-260 — Fichas de Moves M3-Q3 (3A): efeitos herdam seleção/facção padrão salvo exceções explícitas

- **Data:** 2026-11-04.
- **Área:** Fichas de Moves / Rodada M3, questão 3.
- **Origem:** decisão expressa do criador (3A).
- **Estado:** regra de design aprovada e documentada; implementação e dados individuais pendentes.

## Declaração literal do criador

> 33A — Cada efeito herda seleção e facção padrão da ficha, exceto quando a própria ficha declarar abrangência ou condição diferente para aquele efeito.

> Observações e regras próprias: Tudo q não é tackle consome MP , não existe previa de dano em seleção e não deve existir, pare de inventar coisa que eu não pedi

## Regra aprovada, alcance e exemplos

- Cada efeito de um Move **herda a seleção de alvos e facção elegível padrão da ficha**, salvo quando **a própria ficha declarar abrangência ou condição diferente para aquele efeito**. A exceção precisa estar expressa, não inferida da espécie, lado do campo, visual ou nome do Move.

- Preservar **D-246** (seleção Self/One/Two/All; facção ally/enemy/both; abrangência efetiva dos efeitos) e **D-247** (efeitos individuais), sem obrigar a repetição de parâmetros já herdados em todos os efeitos.

- **Exemplo de comportamento já documentado:** Dragon Rage é um ataque com seleção de um inimigo e explosão secundária **condicionada ao contato válido** com o alvo inicial, atingindo outros alvos conforme D-032; o caso não altera a regra geral de AoE sem alvo principal (D-007/D-037). O exemplo **não autoriza** configurar alvos ou colisões adicionais.

- **D-235 obrigatória:** qualquer combatente que possua o Move, seja aliado ou inimigo, aplica a mesma regra relativa ao usuário/alvo, sem coordenadas ou lados fixos.

- **Pendências:** qual sintaxe técnica declara cada exceção, como lidar com efeitos cujas facções individuais divergem, comportamento de escolha Two com apenas um elegível, deduplicação de efeitos/participantes; não escolher tais detalhes.

## Histórico, fontes e escopo

- Preservar **D-061**, **D-228–D-230**, **D-235**, **D-244–D-249** e todos os demais requisitos pertinentes. As novas regras não autorizam reescrever os registros históricos para apagar escolhas anteriores, apenas explicitar precedência quando houver alteração expressa.
- **Nenhuma ficha de Move operacional, código, HUD, teste, VFX, asset, cena, configuração ou dependência foi modificada nesta atualização; não foram executados testes de gameplay.**
