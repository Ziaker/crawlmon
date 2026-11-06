# D-376 — Rodada 88B Q4 (4A): Move migrado indisponível na nova engine se visual obrigatório for inválido

- **Data:** 2026-11-06.
- **Área:** Engine de Moves / validação em runtime / falha de Resource.
- **Origem:** decisão expressa do criador na Rodada 88B.
- **Estado:** política aprovada; não implementada.

## Declaração literal do criador

> 4A — Se um Move já migrado apresentar Resource visual obrigatório ausente ou inválido, considerá-lo indisponível na nova engine, emitir diagnóstico explícito e impedir sua execução até correção, sem fallback silencioso.

## Regra aprovada

- Para um Move **já migrado**, quando seu **Resource visual obrigatório estiver ausente ou inválido**, considerá-lo **indisponível na nova engine** e **impedir sua execução por ela até a correção**.
- **Emitir diagnóstico explícito** e **não realizar fallback silencioso**, seja para recurso visual genérico, execução sem visual ou implementação antiga. A decisão não cria mecanismo automático de correção.
- **Exemplo hipotético:** um Fire Bullet já migrado perde a referência ao recurso visual obrigatório. A nova engine registra explicitamente a falha e não executa esse Move até que a configuração seja corrigida e validada. Este exemplo não afirma que Fire Bullet já esteja migrado.
- **Complementa sem substituir D-350**: a D-350 impede **aprovar uma migração** com visual obrigatório ausente/incompatível; esta D-375 cobre a **indisponibilidade pós-migração** na engine nova.
- Preservar D-235 (mesma regra para qualquer personagem/lado), D-343/D-349 (arquivos mecânico e visual separados, vínculo válido) e D-351 (testes obrigatórios). Tratamento geral de Moves inválidos da IA e ausência de consumo de recursos devem ser conciliados com D-225/D-237/D-241/D-255, sem inventar política adicional.

## Pendências e limites

- **Não decididos:** instante técnico de detecção, comportamento detalhado da seleção de combate e da IA nessa falha específica, canal de diagnóstico, Resource opcional, revalidação/recarregamento e tratamento em produção. Não presumir consumo de ação/ATB/MP ou mudança de fallback tático.
- Apenas documentação; nenhum código, Resource, Move, IA, cena, VFX ou teste alterado.
