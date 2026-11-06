# D-372 — Badge Steal: imunidade mágica roubada não protege contra o impacto atual

- **Data:** 2026-11-06.
- **Área:** Moves / Drain Spear / Badge Steal / imunidades / ordem dos efeitos.
- **Origem:** confirmação expressa do criador após auditoria da Drain Spear.
- **Estado:** regra específica aprovada e documentada; não implementada nem testada no jogo.

## Pergunta confirmada e resposta literal do criador

Pergunta apresentada ao criador:

> Imagine que o alvo possui uma badge de **imunidade a dano mágico**, mas não é imune aos efeitos mágicos. Drain Spear consegue acertá-lo e rouba essa badge **antes do dano**, conforme sua decisão.
>
> Minha recomendação é que a imunidade roubada **deixe de proteger contra o próprio impacto**. Assim, a ordem é:
>
> **Acerto válido → Badge Steal remove a imunidade → cálculo do dano mágico → aplicação do dano.**
>
> Você confirma essa interpretação? A alternativa seria conservar a imunidade apenas para aquele impacto, apesar de ela já ter sido transferida.

Resposta literal:

> Sim

## Regra expressamente aprovada

1. **Somente após acerto válido e elegibilidade do Badge Steal**, se o alvo possuir um **buff positivo com badge que conceda imunidade a dano mágico**, mas não impeça o efeito de roubo, a Drain Spear transfere/removerá esse buff **antes de resolver o dano do mesmo golpe**, conforme D-359.
2. **A imunidade transferida deixa de proteger o alvo contra o próprio impacto da Drain Spear.** Não preservar um snapshot defensivo dessa imunidade para o mesmo dano após a retirada.
3. A ordem específica é: **confirmar acerto válido → executar Badge Steal e remover a imunidade elegível → calcular dano mágico do Move contra as defesas que permanecerem aplicáveis → aplicar dano resultante**.
4. A regra **não elimina outras imunidades ou bloqueios que permaneçam ativos** e não transforma um ataque esquivado, interrompido, inválido ou bloqueado contra o próprio efeito em sucesso. Se o alvo for imune ao efeito Badge Steal/ao Move ou ao contato e o roubo não puder ocorrer, esta decisão não autoriza removê-lo nem ignorar sua proteção.
5. Não extrapolar este caso a buffs sem badge, efeitos negativos ou efeitos que a ficha exclua; a elegibilidade continua limitada aos **buffs positivos e escudos com badge** expressamente aprovados (D-359).
6. Esta é uma **precedência particular de Drain Spear / Badge Steal**. Preservar a regra geral de status de D-199 e as afinidades Null/Repel/Drain da D-276/D-352; **Badge Steal não é a afinidade Drain HP/MP**.
7. Qualquer efeito visual de transferência, como as badges voando 0,3 s e o spray de energia em direção ao atacante, segue o plano mecânico autoritativo e **não retarda o instante de retirada da imunidade** (D-019/D-348).

## Histórico, escopo e pendências

- Esta decisão **resolve especificamente a pendência da imunidade a dano mágico roubada durante o próprio impacto** assinalada em D-356 e D-359; **preservar o texto histórico** desses registros. Esta D-372 prevalece na interpretação desse caso, sem substituir as demais disposições.
- Ainda pendentes: âncoras e contato a 16,3 unidades; calibração de AGI e duração das fases; magnitude de outros buffs roubados, reserva de escudos e conflitos de equivalência, VFX/anatomia, integração de HUD/BattleLog e os testes da nova engine.
- Nenhum arquivo de código, Move Resource, HUD, VFX ou teste foi alterado; somente documentação de regra.

## Relações

D-003, D-019, D-030, D-061, D-194, D-195, D-199, D-235, D-258, D-276, D-324, D-348–D-352, D-356, D-359.
