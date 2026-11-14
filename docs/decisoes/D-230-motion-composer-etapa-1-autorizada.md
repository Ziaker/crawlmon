<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-230 — Motion Composer V1: Etapa 1 (contratos e avaliação) autorizada

- **Data:** 2026-11-04
- **Área:** Motion Composer / implementação isolada
- **Origem:** Conversa

## O que o criador disse (literal)

> continue o trabalho

Ao perguntar o que isso significava (Etapa 1 com código, só documentação ou voltar ao combate):

> prossiga com a etapa 1 e faça questão de utilizar as skills presentes do godot para melhor desempenho e efeitos

## Decisão

Implementar a **Etapa 1** da seção 16 de [Motion Composer V1](../vfx/MOTION_COMPOSER_V1.md): contratos formais de entrada, saída, tipos de operação, espaços de coordenadas e determinismo, com testes. Usar as skills de Godot do projeto (expert, architecture, vfx) como método.

Limites desta autorização:

- Só a Etapa 1. Os 20 comportamentos (Etapa 2), bifurcação/recombinação reais (3), histórico (4), laboratório visual (5) e validação final (6) **não** foram autorizados.
- Código isolado em `scripts/motion_composer/` e testes em `tests/motion_composer/`. Os nomes de pasta são escolha técnica do agente (seguem `scripts/combat` e `tests/battle`), não fala do criador.
- Não altera combate, `VfxLib`, `BattleFx`, cenas, `project.godot` nem VFX existentes (D-003, D-019, D-020). Sem integração ao combate.
- Sem commit nem push (D-022).

## Valores propostos pelo agente (não aprovados pelo criador)

Eixo longitudinal +Z local, unidades Godot, tempo em segundos, ângulos em graus na API; comprimento-base da trajetória de repouso 1,0; limite de amostras por composição 100000 (diagnóstico antes de alocar). Todos ajustáveis e sem valor de aceitação definitivo.

## Ambiguidades em aberto

Mesmas da especificação (§17): durações, curvas padrão, limites de interface, orçamento de desempenho. Nenhuma foi resolvida aqui.

## Estado

Etapa 1 implementada e testada em execução headless (133 verificações, 0 falhas); ver [§20 da especificação](../vfx/MOTION_COMPOSER_V1.md). Aparência e desempenho não avaliados. Sem commit nem push.
