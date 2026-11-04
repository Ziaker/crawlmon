# D-158 — Rodada 62 Q2 (2A): desempate de alvo por identificador estável de combate

- **Data:** 2026-11-03
- **Área:** Combate / escolha automática de alvo
- **Origem:** resposta expressa do criador, Rodada 62 Q2
- **Estado:** decisão de design aprovada; não implementada nesta atividade

## Declaração literal do criador

> 2A — Selecionar pelo identificador estável de combate, garantindo o mesmo resultado no mesmo estado.

## Regra aprovada

- Durante o redirecionamento de um ataque no **WINDUP** por morte do alvo (D-108), continuar escolhendo o **inimigo vivo mais próximo**.
- Quando **dois ou mais candidatos elegíveis estiverem empatados na distância usada por essa regra**, decidir o desempate **de modo determinístico pelo identificador estável de combate** dos candidatos, produzindo a mesma seleção a partir do mesmo estado.
- **Exemplo ilustrativo da questão:** Pancham morre durante WINDUP; Abra e Gible são candidatos vivos igualmente próximos, ambos a 4 metros. O desempate usa o identificador estável de combate, sem sorteio.
- A cada troca efetiva, aplicar o recálculo de duração uma vez (D-155), sem inventar um novo custo de ação.

## Limites e detalhes ainda não aprovados

- A escolha não especificou qual **ordenação** dos identificadores prevalece (ascendente/descendente), nem sua representação, atribuição ou persistência entre batalhas/replays; esses detalhes deverão manter o determinismo e necessitam definição antes da implementação.
- Não mudar o conjunto fixo de alvos de AoE (D-037), alvos de projéteis em voo (D-047/D-109) ou a seleção aleatória inicial de alvo pela IA quando não existe o empate específico da D-108.
- Preservar vitória imediata por último inimigo derrotado (D-105) e o limite temporal de retarget no WINDUP (D-113).

## Escopo

Somente documentação; nenhum código, teste, dado, cena ou VFX alterado.

## Conciliação posterior — Rodada 62, versão prevalente confirmada (2026-11-03)

**Estado atual: histórico, desempate por ID substituído.** Após a publicação desta D-158, o criador confirmou expressamente que a versão prevalente da Rodada 62 exige **R62-Q5A / D-166: sorteio entre alvos vivos igualmente próximos, usando aleatoriedade reproduzível do combate**. Portanto, a regra histórica de **desempatar por identificador estável sem sorteio não está vigente**. Preservado texto anterior, nenhum código alterado.
