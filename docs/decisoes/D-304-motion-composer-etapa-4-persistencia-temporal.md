# D-304 — Motion Composer V1: Etapa 4 (persistência temporal: M19 e M20)

- **Data:** 2026-11-04
- **Área:** Motion Composer / implementação isolada
- **Origem:** Conversa

## O que o criador disse (literal)

> autorizo etapa 4

## Decisão

Implementar a **Etapa 4** da seção 16 de [Motion Composer V1](../vfx/MOTION_COMPOSER_V1.md): "Adicionar rastros, pós-imagens e reconstrução de histórico". Isso significa:

- **M19 Rastro temporal** (continuidade histórica) e **M20 Pós-imagem** (estados discretos), distinguíveis entre si (§3 grupo H).
- **Reconstrução determinística do histórico** (§9.3, §19.4): cada amostra histórica é o estado do fluxo, produzido pelas camadas anteriores, **em um instante anterior**, calculado por avaliação direta pela função de tempo. Nada depende de quadros já exibidos, de busca (seek), retrocesso ou reinício. O histórico do emissor vem de `emitter_at(t)` em instantes passados.
- Adições aditivas aos contratos da Etapa 1: `MotionContext.history_fn` (preenchida pelo compositor só para camadas PERSIST) e `MotionSample.age`. Contratos existentes inalterados.

Limites: laboratório visual, presets e representações (Etapa 5) e validação completa (Etapa 6) **não** foram autorizados. Sem integração ao combate, sem tocar em VFX existentes (D-003, D-019, D-020). Sem push sem autorização (D-022). A numeração D-300+ é reservada ao Motion Composer (ver §24 da especificação).

## Valores propostos pelo agente (não aprovados pelo criador)

Fórmulas, nomes, unidades, padrões e limites (duração 0,5 s, intervalo 0,05 s, até 256 amostras de rastro por elemento, 4 pós-imagens a 0,1 s) são propostas técnicas ajustáveis, documentadas na §25 da especificação. Nenhum é requisito de aceitação.

## Ambiguidades em aberto

Mesmas da §17. Em particular: limites finais de amostragem e persistência (§12.3) e o comportamento ao repetir um trecho em laço continuam dependentes de medição e aprovação.

## Estado

M19 e M20 implementados e testados em execução headless (60 verificações, 0 falhas; 14 mutações; 445 no total das cinco suítes); ver [§25 da especificação](../vfx/MOTION_COMPOSER_V1.md). Aparência e desempenho não avaliados.
