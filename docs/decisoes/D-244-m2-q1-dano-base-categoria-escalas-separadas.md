# D-244 — Fichas de Moves M2-Q1: dano-base, categoria e escalas registrados separadamente

- **Data:** 2026-11-04.
- **Área:** Fichas de Moves / Rodada M2 / questão 1.
- **Origem:** escolha **1A** expressamente enviada pelo criador, sem observações próprias.
- **Estado:** regra de design documental aprovada; **não implementada** nesta atividade.

## Declaração literal do criador

> 1A — Registrar dano-base, categoria física/mágica e escalas STR/MAG separadamente na ficha técnica, apresentando o dano numérico calculado na tooltip.

> Observações e regras próprias: Nenhuma.

## Regra aprovada, exemplos e limites

- Na **ficha técnica** do Move, especificar separadamente **dano-base**, **categoria física ou mágica/especial** e os **escalonamentos aplicáveis de STR/MAG**; nenhum desses campos pode substituir automaticamente os demais.
- A **tooltip em combate** deve apresentar **dano numérico calculado em pontos**, não uma fórmula ou somente multiplicador, conforme **D-229/D-230**; o texto de dano e modificadores continua integrado na descrição mecânica.
- Preservar **D-122**: STR governa dano ofensivo físico e MAG governa dano ofensivo mágico/especial. A forma de execução (melee, projectile, cast ou status) não determina por si a categoria do dano. Preservar **D-123**: MAG só escala efeitos adicionais explicitamente declarados escaláveis na ficha.
- **Exemplo ilustrativo, não ficha aprovada:** uma ficha futura pode ter campos distintos para `dano-base: [a definir]`, `categoria: física`, `escala STR: [a definir]`; se houver parâmetros suficientes para determinar `12 pontos` naquele contexto, a tooltip exibe o **12**, e não uma expressão de multiplicação. Não homologar o número demonstrativo.
- **Pendências:** fórmula exata de composição das parcelas, coeficientes, valores oficiais por Move, referência de atacante/alvo, texto antes de escolher alvo e como representar Moves sem dano ou com parcelas de categorias diferentes. Nenhum valor foi calculado, medido ou implementado nesta decisão.

## Relações e escopo

- **Decisões relacionadas:** D-122/D-123/D-198/D-205/D-228/D-229/D-230/D-235.
- **Processo:** registrar conforme D-061, preservar histórico, conflitos e descrições anteriores; não interpretar autorização documental como implementação.
- **Somente documentação:** nenhum código, Move/ficha operacional, IA, HUD, teste, cena, animação, VFX, asset ou dependência alterado por este registro.
