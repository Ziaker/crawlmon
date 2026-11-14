<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-233 — Motion Composer V1: Etapa 3 (composição espacial: M14 e M15)

- **Data:** 2026-11-04
- **Área:** Motion Composer / implementação isolada
- **Origem:** Conversa

## O que o criador disse (literal)

> Sim, Etapa 3

Resposta à pergunta "Começo a Etapa 3 (bifurcação e recombinação)?".

## Decisão

Implementar a **Etapa 3** da seção 16 de [Motion Composer V1](../vfx/MOTION_COMPOSER_V1.md): "Adicionar bifurcação, recombinação, ordem de composição, máscaras e defasagens". Isso significa:

- **M14 Bifurcação** e **M15 Recombinação**, seguindo a semântica proposta na §19.3 (ramos com ids estáveis derivados do id da camada e do índice; recombinação aproxima os ramos selecionados mantendo suas identidades; unificação visual por coincidência e redução controlada de largura/intensidade).
- Validar, **com comportamentos reais**, os recursos de ordem de camadas, máscaras e defasagens que já existem desde a Etapa 1 (D-230), inclusive a receita da §6 até a recombinação e as ondas.
- Um refinamento aditivo no compositor: operação de topologia que devolve o mesmo número de amostras (caso de M15, e de M14 com um ramo) substitui as amostras selecionadas **no lugar**, preservando a ordem; antes elas eram agrupadas na posição da primeira selecionada. Quantidades diferentes seguem como antes.

Limites: M19 e M20 (Etapa 4), laboratório visual (Etapa 5) e validação completa (Etapa 6) **não** foram autorizados; por isso a receita da §6 é testada **sem M19**. Sem integração ao combate, sem tocar em VFX existentes (D-003, D-019, D-020), sem push (D-022).

## Valores propostos pelo agente (não aprovados pelo criador)

Fórmulas, nomes, unidades, padrões e limites de M14 e M15 e as janelas temporais da receita de teste (derivadas dos intervalos propostos na §19.7) são propostas técnicas ajustáveis, documentadas na §23 da especificação.

## Ambiguidades em aberto

Mesmas da §17. Operações de topologia ignoram a máscara de influência por amostra e usam a intensidade da camada apenas como liga/desliga (0 = ignorada); a quantidade de efeito é controlada pelos parâmetros do próprio comportamento.

## Estado

M14 e M15 implementados e testados em execução headless (71 verificações, 0 falhas; 10 mutações); ver [§23 da especificação](../vfx/MOTION_COMPOSER_V1.md). IDs renumerados na auditoria da [§24](../vfx/MOTION_COMPOSER_V1.md) (colidiam com D-171 a D-174 do remoto). Aparência e desempenho não avaliados.
