# D-202 — Rodada 70 Q3 (3A): uma tentativa de status por alvo por execução, após último impacto multi-hit

- **Data:** 2026-11-04.
- **Área:** Combate / Moves multi-hit / status condicionado ao acerto.
- **Origem:** escolha expressa do criador na Rodada 70.
- **Estado:** regra de design aprovada; sem implementação nesta atividade.

## Declaração literal do criador

> 3A — No máximo uma tentativa de aplicação do status por alvo e execução do Move, depois do último impacto, somente se o alvo sobreviver.

## Regra aprovada

- Em **Moves multi-hit que tenham aplicação de status condicionada ao acerto**, permitir **no máximo uma tentativa de aplicação desse status por alvo e por execução do Move**, **após o último impacto** dessa execução para o alvo.
- O status somente pode ser tentado **se o alvo sobreviver ao dano dos impactos aplicáveis**. Se o Move o derrotou, não rolar nem aplicar status condicionado ao acerto, conforme **D-199**. Esquivas válidas não são convertidas em acertos para disparar efeito (**D-195**).
- **Não inventar uma tentativa de status se nenhum impacto do Move acertou validamente o alvo**; a decisão controla a frequência de tentativas de efeito dependente de acerto, sem alterar efeitos independentes de acerto.
- **Exemplo hipotético:** um Move realiza três impactos contra Abra e pode causar Poison em um alvo. Se Abra recebeu ao menos um impacto válido e sobreviveu até depois do último impacto, pode haver **uma única tentativa de Poison nessa execução**, seguindo a chance prevista na ficha. Três impactos não autorizam três rolagens desse mesmo status. Se Abra morrer, não há tentativa.
- Preservar chances e garantias já definidas por **D-134/D-146/D-156** (LUK efetiva na rolagem, efeitos garantidos sem chance extra). A decisão não altera os Moves de status de alvo único não esquiváveis da D-012.
- Para **Moves multi-alvo**, o teto é **por alvo e por execução**: um sucesso ou falha em um alvo não substitui a tentativa elegível de outro alvo. Não inventar número global de rolagens, nova probabilidade nem regra especial de distribuição do efeito.

## Limites e pendências

- A regra não resolve casos de **vários status diferentes no mesmo Move**, a definição técnica de último impacto em trajetos assíncronos nem efeitos especiais de contato já governados por suas próprias fichas e decisões anteriores.
- Esta escolha não altera recompensas de ATB por hit, as quais possuem regras próprias, nem a simultaneidade de KO.
- Documentação somente; não modificar código, fichas de Move, testes, cenas, assets ou VFX.
