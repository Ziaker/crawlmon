# D-126 — Rodada 54 Q7 (A): Calibrar AGI preservando ATB e tempos individuais dos Moves

- **Data:** 2026-11-03
- **Área:** Atributos e identidade de espécies / Rodada 54.
- **Proveniência:** resposta expressa do criador; os textos marcados como recomendação aceita foram originalmente sugeridos pelo assistente, mas **a alternativa foi selecionada diretamente pelo criador**.
- **Estado:** regra de design aprovada e documentada; sem implementação nesta atividade.

## Declaração literal da resposta do criador

> 7A — Calibrar AGI para preservar inicialmente os ritmos atuais de ATB e os tempos próprios dos Moves, introduzindo a redução por AGI sem alterar silenciosamente o equilíbrio.

## Regra aprovada

- Na integração inicial de Agilidade, **calibrar** os valores para preservar o ritmo observado de regeneração de ATB e os **tempos-base individuais de deslocamento** dos Moves, sem alterar silenciosamente o balanceamento existente.
- **D-117 e D-119 mantidas:** AGI influencia tanto ATB quanto a velocidade de deslocamento do Pokémon em seus ataques; cada Move declara seu próprio tempo de deslocamento, reduzido por AGI e efeitos que a elevem.
- **D-018 preservada:** o posicionamento por passos continua afetando tempos conforme sua regra histórica. A escolha 7A não autoriza uma fórmula nova nem suprimir os passos.
- Não fixar AGI de referência em 50, tempos de 5 ou 10 segundos nem multiplicadores sem decisão específica.

## Referências, pendências e limitação

- **Referências:** D-018; D-117; D-119; GDD R8-Q1/R10-Q5/R11-Q1; Battle.gd.
- **Ainda não definido:** Função AGI → redução de tempo, valor de referência para ATB, ordem com passos, piso temporal, arredondamento e testes de paridade; preservação inicial é objetivo de calibração, não identidade matemática universal.
- **Sem implementação:** não alterar nem presumir alteração de código, recursos, dados de personagens ou testes.
