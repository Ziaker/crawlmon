# D-967 — Rodada 92B Q3 (3A): rastros reproduzíveis da execução e do fluxo de eventos

- **Data:** 2026-11-07.
- **Área:** Engine de Moves / observabilidade / determinismo / reprodução de falhas.
- **Origem:** decisão expressa da Rodada 92B, questão 3.
- **Estado:** requisito aprovado; rastreamento/replay ainda não implementados.

## Declaração literal do criador

> 3A — Registrar rastros reproduzíveis com IDs, versões de configuração, resultados de condições/ocorrências e eventos, incluindo os estados e seeds necessários à reprodução, sem criar novas rolagens de RNG.

## Regra aprovada

- Registrar **rastros que permitam reproduzir a execução**, contendo os **IDs** necessários à correlação, **versões da configuração executada**, **resultados de avaliação das condições**, **resultados das ocorrências** e **eventos emitidos**.
- Incluir os **estados e seeds efetivamente necessários à reprodução determinística**, conforme o contexto e as fontes de aleatoriedade existentes, **sem adicionar novas rolagens de RNG**.
- Preservar **D-218/D-222/D-226** (identidade e reserva de ocorrências), **D-375** (ocorrência executada, cancelada ou não acionada), **D-954** (resultados de condições no instante mecânico), **D-956/D-959** (eventos estruturados e IDs determinísticos), **D-958/D-960** (configuração por execução/versionamento), **D-962** (participantes e referências espaciais) e regras anteriores sobre ordenação/uso de seeds.
- **Exemplo ilustrativo:** um Splitter Flames interrompido na variante de dois alvos deve poder ser investigado com o rastro de identidade, versão, condições e eventos pertinentes. O exemplo não declara o Move implementado nem altera suas regras.

## Pendências e limites

- **Não definidos:** formato de log, ciclo de retenção, tamanho máximo, compressão, exportação, regras de serialização de estados, interface de replay, estratégia de armazenamento ou isolamento de dados. A exigência é **reprodutibilidade dos dados relevantes**, não uma obrigação de registrar informação não necessária.
- Não escolher novas seeds nem consumir RNG em código de diagnóstico. **D-235** permanece obrigatória.
- **Somente documentação**: nenhum código, teste, sistema de rastreamento ou Resource implementado.
