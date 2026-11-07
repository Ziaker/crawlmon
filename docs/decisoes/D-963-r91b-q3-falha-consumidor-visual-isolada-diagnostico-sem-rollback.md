# D-963 — Rodada 91B Q3 (3A): isolar falhas de consumidores após evento mecânico válido

- **Data:** 2026-11-07.
- **Área:** Engine de Moves / VFX e rastreamento / falhas em runtime.
- **Origem:** resposta **“Tudo A continue”**, aprovando a alternativa A da questão 3 da Rodada 91B.
- **Estado:** política aprovada; **não implementada nem testada**.

## Declaração literal

> Tudo A continue

## Alternativa 3A aprovada (texto apresentado ao criador)

> Isolar e diagnosticar falhas de um consumidor visual ou de rastreamento após o evento mecânico válido, sem repetir, reverter ou alterar a resolução mecânica e sem fallback visual silencioso.

## Regra aprovada

- Quando um **evento mecânico válido já foi resolvido** e um consumidor de **VFX** ou **rastreamento** falha no processamento, a falha do consumidor deve ser **isolada e diagnosticada explicitamente**.
- **Não repetir, reverter, recalcular ou alterar a resolução mecânica** por falha do consumidor. Não reproduzir VFX/diagnósticos duplicados nem introduzir **fallback visual silencioso**.
- Preservar D-348 (autoridade temporal/mecânica), D-956 (consumidores independentes), D-959 (identidade individual e detecção de entregas repetidas), D-351 (testes de integração), D-961 (receita visual da execução) e D-235 (neutralidade quanto a atacante/lado).
- **Distinguir da D-376:** essa decisão trata de Resource visual **obrigatório inválido para um Move já migrado**, antes da execução; a D-963 trata da **falha de processamento de um consumidor após um evento mecânico válido**.
- **Exemplo não normativo:** a mecânica de um golpe resolve o acerto e a emissão do evento; o módulo visual de partículas falha. Registra-se o erro, sem reaplicar dano nem gerar automaticamente partículas genéricas.

## Limites e pendências

- **Não definidos:** exceções capturáveis, interface do diagnóstico, persistência/gravidade de falha, política de reparo do consumidor, apresentação residual, retenção de evento, procedimento de recuperação ou arquitetura de transporte. Não inventar loop de retries ou novo cancelamento da ação mecânica.
- **Somente documentação; nenhum código, Move, Resource, VFX, rastreamento ou teste modificado.**
