# D-173 — Rodada 64 Q2 (2A): mediana de conjunto par pela média dos dois valores centrais

- **Data:** 2026-11-03.
- **Área:** Atributos / cálculo estatístico / AGI.
- **Origem:** escolha expressa do criador na Rodada 64.
- **Estado:** regra aprovada e registrada; sem cálculo de referência real.

## Declaração literal do criador

> 2A — Usar a média aritmética dos dois valores centrais.

## Regra aprovada

- Quando a amostra de **AGI-base no nível 50** das espécies elegíveis contiver um **número par** de valores, **ordená-los** e usar a **média aritmética dos dois valores centrais** para a mediana que servirá de base à referência de AGI dos trajetos.
- **Exemplo ilustrativo:** AGIs ordenadas fictícias `20, 30, 50, 60` → dois valores centrais `30` e `50` → mediana **40**. **40 não é valor aprovado como referência do jogo.**
- Esta decisão não introduz truncamento, arredondamento ou escolha do central maior/menor. **Mediana fracionária e tratamento de precisão/armazenamento** continuam pendentes de especificação técnica; não presumir arredondamento silencioso.
- Para quantidade **ímpar**, preservar o sentido estatístico de mediana e as escolhas anteriores sem redefinição adicional.
- O valor efetivo calculado a partir da lista real ainda **precisa ser validado pelo criador antes da implementação** (D-162).

## Compatibilidades e escopo

- Complementa D-162, D-167, D-168, D-172 e D-174. Não redefine a relação inversa da AGI nem a referência independente de ATB.
- Somente documentação; nenhum teste, arquivo de código ou tabela de atributos alterado.

## Complemento posterior — Rodada 65 / D-179 (2026-11-03)

**D-179 (R65-Q3A)** resolve a pendência de arredondamento: **preservar a mediana fracionária exata, sem arredondar**. Para uma amostra par, a média dos dois centrais desta D-173 permanece; se for **42,5**, a referência candidata permanece **42,5** e não 42 ou 43. O valor real ainda depende da amostra completa e da validação expressa do criador exigida por D-162. Declaração e texto históricos preservados; sem código.
