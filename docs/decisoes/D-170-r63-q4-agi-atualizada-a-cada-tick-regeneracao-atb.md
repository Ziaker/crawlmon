# D-170 — Rodada 63 Q4 (4A): reavaliar AGI a cada atualização da regeneração natural ATB

- **Data:** 2026-11-03.
- **Área:** Combate / AGI / atualização temporal da regeneração ATB.
- **Origem:** resposta expressa do criador na Rodada 63.
- **Estado:** decisão aprovada; sem implementação.

## Declaração literal do criador

> 4A — Reavaliar AGI efetiva a cada atualização da regeneração natural do ATB.

## Regra aprovada

- Em **cada atualização efetiva da regeneração natural de ATB**, consultar novamente a **AGI efetiva atual** do personagem e aplicá-la à fórmula de regeneração (D-163), respeitando o piso de cálculo AGI 1 (D-164).
- Se buffs/debuffs válidos alterarem AGI entre atualizações, usar o novo valor **nas próximas atualizações de regeneração habilitadas**. O progresso de ATB já acumulado **não é recalculado retroativamente** por uma mudança posterior de AGI.
- Não congelar a taxa de AGI por toda a duração de uma barra de ATB nem até o começo de outra ação. **Preservar integralmente** pausas/bloqueios, a capacidade da barra, ATB extra e ganhos instantâneos; essa regra diz respeito somente à **regeneração natural**.
- **Exemplo ilustrativo:** um personagem tem dois blocos ATB acumulados com AGI 20 e recebe buff para AGI 40; a quantidade já preenchida continua sendo dois blocos, e as atualizações seguintes de regeneração usam AGI 40, enquanto o buff vigorar e a regeneração estiver habilitada.
- **Não confundir** esta leitura dinâmica do ATB com o tempo fixo do trajeto calculado na entrada de WINDUP ou, sem WINDUP, em TRAVEL (D-154/D-165), salvo recálculo excepcional aprovado durante troca em WINDUP (D-155).

## Limites e escopo

- Não define nova frequência de atualização, ordem de processamento de eventos simultâneos ou coeficientes de ATB.
- Documentação somente; nenhum código, teste, cena ou recurso alterado.
