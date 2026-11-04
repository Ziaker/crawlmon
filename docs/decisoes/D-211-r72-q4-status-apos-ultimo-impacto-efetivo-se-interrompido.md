# D-211 — Rodada 72 Q4 (4A): em Move interrompido, resolver status após o último impacto realmente executado

- **Data:** 2026-11-04.
- **Área:** Combate / interrupção de Move / status por alvo.
- **Origem:** aprovação expressa do criador na Rodada 72.
- **Estado:** regra de design aprovada; não implementada nesta atividade.

## Declaração literal do criador

> 4A — Se o Move for interrompido depois de acertos válidos, usar o último impacto realmente executado contra cada alvo para resolver o status elegível, se ele sobreviver.

## Regra aprovada

- Quando um **Move multi-hit for interrompido depois de executar acertos válidos**, para cada alvo que recebeu **pelo menos um acerto válido** e **sobreviveu ao dano realizado**, considerar seu **último impacto realmente executado** no Move para determinar a resolução do status condicionado ao acerto.
- **Não exigir a conclusão de impactos previstos mas nunca executados** para permitir a tentativa elegível, nem criar impactos faltantes. O ponto da resolução deve respeitar o encerramento/interrupção efetivo: não antecipar uma tentativa enquanto ainda houver impactos futuros sendo efetivamente executados contra aquele alvo.
- Preservar **D-202/D-207** (teto por alvo e execução, normalmente após último impacto próprio) e **D-210** (teto **por efeito de status distinto, alvo e execução**); preservar D-199 (somente sobreviventes, dano antes de status). Se o alvo morrer, não rolar status condicionado ao acerto. Se nenhum impacto válido atingiu o alvo, **não inventar tentativa**.
- **Exemplo ilustrativo:** um Move com três impactos previstos contra Gible é interrompido depois de dois impactos executados, sendo pelo menos um válido. Se Gible permanecer vivo, o segundo impacto foi o último **efetivamente executado** contra ele e permite resolver as tentativas elegíveis de status conforme a ficha. Se ambos erraram, ou o alvo morreu, não há tentativa condicionada ao acerto.
- A decisão **não modifica a regra que causa interrupção, cancelamento ou morte**, não reabre combate encerrado e não estabelece nova recompensa de ATB. Preservar a D-095 sobre KO simultâneo e D-203: **odômetro descartado do jogo principal**.

## Limites e pendências

- Não foi decidido o tratamento de status de um Move cancelado **antes de qualquer acerto válido**, além de não existir aplicação condicionada a acerto, nem o de habilidades com gatilhos especiais independentes de acerto. Não selecionar ordem de rolagens entre vários status simultâneos ou comportamento das incompatibilidades de efeitos.
- A regra não determina como a implementação define **o instante lógico exato da interrupção e do último impacto**, especialmente quando múltiplos alvos são atingidos simultaneamente.
- Somente documentação; nenhum código, teste, Move, cena, asset ou VFX modificado.
