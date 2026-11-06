# D-364 — Rodada 88 Q1 (1A): Repel em Moves multialvo reflete somente o impacto destinado ao portador

- **Data:** 2026-11-06.
- **Área:** Combate / afinidades elementais / Repel / Moves de múltiplos alvos.
- **Origem:** aprovação expressa do criador na Rodada 88.
- **Estado:** abrangência da reflexão por alvo aprovada; detalhes de cálculo e implementação pendentes.

## Declaração literal do criador

> 1A — Em Moves de múltiplos alvos, somente o impacto destinado ao alvo com Repel é refletido ao atacante original; os demais alvos recebem seus impactos normalmente.

## Regra aprovada

- Quando um **Move que atinge múltiplos alvos** encontrar **Repel aplicável em um dos alvos**, **somente o impacto destinado àquele alvo** deve ser **refletido ao atacante original**.
- **Os impactos destinados aos demais alvos devem continuar sendo resolvidos normalmente**, cada um conforme suas próprias afinidades, elegibilidade e demais regras aprovadas. A presença de Repel em um alvo **não cancela nem reflete automaticamente o Move inteiro**.
- Preservar **D-344**: a reflexão retorna ao **atacante original** e ocorre **uma única vez por golpe refletido**, **sem reflexões em cadeia**. Preservar **D-235**: a lógica depende de atacante/alvo reais, nunca do time, personagem ou lado do campo; preservar **D-276** (afinidades elementais possíveis).
- **Exemplo hipotético:** Splitter Flames é dirigido a dois alvos; o primeiro tem Repel contra fogo e o segundo não. O impacto destinado ao primeiro retorna ao atacante; o impacto destinado ao segundo prossegue conforme suas regras. A escolha **não atribui Repel a espécie real** e não altera a ficha concreta de Splitter Flames.
- O termo **impacto destinado ao alvo** não autoriza executar novamente contra os demais alvos efeitos que pertenciam ao impacto refletido; manter os efeitos individualizados conforme as declarações aprovadas na ficha do Move.

## Pendências e limites

- **Não foram aprovados** dano/cálculo refletido, esquiva, crítico, status, escudos, trajeto/tempo de projétil, recompensa de ATB/Burst, casos de vários hits sobre o mesmo alvo, reflexos concorrentes nem interações com Null/Drain. Não escolher comportamento de AoE/multi-hit além da regra por impacto destinada a cada alvo.
- Esta decisão **não altera recursos/custos**, não adiciona variante a qualquer Move e não implementa Repel no runtime.
- **Somente documentação:** nenhum código, Move, Resource, ficha, IA, HUD, teste, cena, asset ou VFX alterado.
