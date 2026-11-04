# D-261 — Fichas de Moves M3-Q4 (4A): AGI não altera automaticamente a velocidade de projéteis

- **Data:** 2026-11-04.
- **Área:** Fichas de Moves / Rodada M3, questão 4.
- **Origem:** decisão expressa do criador (4A).
- **Estado:** regra de design aprovada e documentada; implementação e dados individuais pendentes.

## Declaração literal do criador

> 44A — AGI não altera automaticamente a velocidade de projéteis; manter velocidade por Move, salvo modificador de projétil aprovado expressamente.

> Observações e regras próprias: Tudo q não é tackle consome MP , não existe previa de dano em seleção e não deve existir, pare de inventar coisa que eu não pedi

## Regra aprovada, alcance e exemplos

- A **AGI não modifica automaticamente** a velocidade de projéteis. Cada Move mantém **sua própria velocidade de projétil**, sujeita apenas a **modificador de projétil expressamente aprovado** no futuro ou já previsto de modo verificável pela norma aplicável.

- Preservar a separação entre **windup**, **tempo-base de deslocamento do atacante** e **velocidade de projétil** (D-245). A redução por AGI do tempo de deslocamento **do personagem** permanece conforme D-119/D-133/D-136/D-148 e **não migra por analogia** para velocidade de voo.

- Preservar **D-057/D-067/D-077/D-078** para ondas AoE, com velocidade espacial constante por execução, individual por Move e alvos considerados em suas posições atuais segundo normas vigentes. A presente decisão não altera geometria, resultado da esquiva nem velocidade durante a onda.

- **Exemplo abstrato:** dois combatentes de AGI diferente executam o mesmo Move de projétil sem modificador de velocidade próprio: a AGI **por si** não altera a velocidade de voo desse Move. O exemplo não atribui velocidade, trajetória ou windup concreto.

- **Pendências:** velocidades numéricas de Moves, especificação e aprovação de modificadores excepcionais de projétil e interação específica com outros fatores que ainda não tenham regra expressa.

## Histórico, fontes e escopo

- Preservar **D-061**, **D-228–D-230**, **D-235**, **D-244–D-249** e todos os demais requisitos pertinentes. As novas regras não autorizam reescrever os registros históricos para apagar escolhas anteriores, apenas explicitar precedência quando houver alteração expressa.
- **Nenhuma ficha de Move operacional, código, HUD, teste, VFX, asset, cena, configuração ou dependência foi modificada nesta atualização; não foram executados testes de gameplay.**
