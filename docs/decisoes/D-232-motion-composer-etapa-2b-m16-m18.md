# D-232 — Motion Composer V1: Etapa 2b (M16, M17, M18)

- **Data:** 2026-11-04
- **Área:** Motion Composer / implementação isolada
- **Origem:** Conversa

## O que o criador disse (literal)

> Etapa 2b agora

Resposta à pergunta sobre em qual etapa entram M16 (explosão direcional), M17 (crescimento progressivo) e M18 (dissolução progressiva), que a seção 16 da especificação não atribuía a nenhuma.

## Decisão

Criar a **Etapa 2b**, imediatamente após a Etapa 2 ([D-231](D-231-motion-composer-etapa-2-autorizada.md)), contendo exatamente M16, M17 e M18. A seção 16 passa a ter, entre as etapas 2 e 3, esta etapa 2b. As Etapas 3 (M14, M15), 4 (M19, M20), 5 e 6 continuam como estavam e não foram autorizadas por esta decisão.

Limites: contratos das Etapas 1 e 2 inalterados (apenas adição de comportamentos e de auxiliares); sem integração ao combate; M16 não cria impactos nem altera resultado lógico de ataque (§3 grupo F); sem push (D-022).

## Valores propostos pelo agente (não aprovados pelo criador)

Fórmulas, nomes de parâmetro, unidades, padrões e limites de M16–M18 são propostas técnicas ajustáveis, documentadas na §22 da especificação.

## Ambiguidades em aberto

Mesmas da §17. Em particular: curvas padrão e a escolha de qual canal (visibilidade, espessura, intensidade, opacidade) cada representação usa na dissolução.

## Estado

M16–M18 implementados e testados em execução headless (57 verificações, 0 falhas; 14 mutações); ver [§22 da especificação](../vfx/MOTION_COMPOSER_V1.md). Aparência e desempenho não avaliados.
