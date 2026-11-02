# Decisões do criador (uma por arquivo)

> **Obrigatório:** antes de **qualquer** tarefa, ler este índice e **todos** os arquivos `D-*.md`. Ambiguidade = perguntar. Nova decisão do criador = criar o arquivo aqui **antes** de codar. Ver `AGENTS.md`.

Fontes: **Conversa** = o que o criador disse (frase literal entre aspas); **PROMPT** = `PROMPT_trajeto_reposicionamento.md`; **memória** = preferência registrada. O GDD é ignorado no combate (D-001).

| ID | Área | Decisão | Estado |
|---|---|---|---|
| [D-001](D-001-gdd-ignorado-no-combate.md) | Processo | O GDD é ignorado no combate | Aplicado em `docs/REGRAS_DO_JOGO |
| [D-002](D-002-documentar-toda-decisao-e-ler-sempre.md) | Processo | Cada decisão vira um documento, e eu leio todos sempre | Implementado: `AGENTS |
| [D-003](D-003-so-fazer-o-pedido.md) | Processo | Fazer só o que foi pedido; perguntar na dúvida; refatorar sem mudar nada | Violada na Fase 2; correção pendente de decisão |
| [D-004](D-004-sem-erro-no-vazio.md) | Combate | Ataques e projéteis acertam o alvo mesmo fora do trajeto original | Implementado (`void_miss` removido) |
| [D-005](D-005-esquiva-automatica-10.md) | Combate | Esquiva automática: 10% por golpe | Implementado |
| [D-006](D-006-evade-parado-vs-em-trajeto.md) | Combate | Evade parado custa 3 ATB; Evade em trajeto (no próprio ataque) custa 2 ATB | **Não implementado |
| [D-007](D-007-aoe-sem-alvo-principal.md) | Combate | AoE: sem alvo principal, todos ao mesmo tempo, desvio individual | **Não implementado |
| [D-008](D-008-aoe-corpo-a-corpo.md) | Combate | AoE corpo a corpo: o atacante fica parado; quem desvia ganha Burst sem interromper | **Não implementado |
| [D-009](D-009-aoe-projetil.md) | Combate | AoE de projétil: onda única, cada alvo é atingido no seu tempo | **Não implementado |
| [D-010](D-010-aoe-dano-e-recompensa.md) | Combate | AoE: dano igual para todos e recompensa de ATB uma vez por golpe | **Não implementado** (hoje 100% no principal, 85% nos outros) |
| [D-011](D-011-aoe-quem-entra.md) | Combate | AoE: atinge quem estava vivo | Não implementado |
| [D-012](D-012-aoe-amigavel-e-status.md) | Combate | AoE amigável inclui o lançador; golpes de status não são esquiváveis | Parcial: golpes amigáveis já não são esquiváveis no código; debuffs de alvo único não têm trajeto, então não são desviáveis |
| [D-013](D-013-aoe-interrupcao.md) | Combate | Quem é atingido por um AoE é interrompido | Interrupção já existe; hit-stop único e câmera: não implementado para AoE |
| [D-014](D-014-golpes-de-status-pausam.md) | Combate | Golpes de status pausam o jogo durante a ativação | **Não implementado |
| [D-015](D-015-camera-inimigo-sempre-visivel.md) | Câmera | Câmera: o inimigo deve estar SEMPRE visível (estilo Kill la Kill IF) | **Não implementado |
| [D-016](D-016-evade-no-trajeto-do-ataque-inimigo.md) | Combate | Evade manual só funciona durante o trajeto; no preparo é whiff | Implementado (custo conforme D-006 pendente) |
| [D-017](D-017-evade-sucesso-sequencia.md) | Combate | Evade bem-sucedido contra corpo a corpo: interrompe, Burst, chegada, golpe de graça, engajamento | Implementado |
| [D-018](D-018-passos-de-posicao.md) | Combate | Reposicionamento: passos de −2 a +2 | Implementado |
| [D-019](D-019-linha-do-tempo-unica.md) | Arquitetura | Lógica e visual numa só linha do tempo; o visual só desenha | Em vigor (Fases 1 e 2) |
| [D-020](D-020-preservar-e-nao-reintroduzir.md) | Combate | Preservar o que existe; não reintroduzir o que foi removido | Em vigor |
| [D-021](D-021-simetria-e-ia.md) | Combate | Simetria total e IA de reação | Implementado |
| [D-022](D-022-regras-git-e-envio.md) | Processo | Git: nada de push sem autorização; só commitar o que é seu | Em vigor |
| [D-023](D-023-ordem-de-trabalho-fases.md) | Processo | Ordem de trabalho: fases e testes | Fases 0–2 feitas; Fase 3 não iniciada |
| [D-024](D-024-revisao-mudancas-fase-2.md) | Processo / Combate | Revisão das mudanças da Fase 2 feitas sem pedido | Nada alterado ainda |
| [D-025](D-025-reverter-fase-2.md) | Processo / Combate | Reverter a Fase 2, mantendo só o que o criador aprovou | Revertido na branch (main ainda tem a Fase 2) |
| [D-026](D-026-remover-evade-e-trajeto.md) | Combate | Remover Evade e trajeto | **Cancelada**: o criador mandou restaurar o GitHub antes de aplicar |
| [D-027](D-027-evade-teleporte-so-no-contra-ataque.md) | Combate | Teleporte só no desvio perfeito durante o próprio ataque; ataque continua + contra-ataque; Evade em trajeto 2 ATB, parado 3 | Implementado |
| [D-028](D-028-evade-so-na-acao.md) | Combate | O Evade só aparece durante a ação (trajeto), não na chamada (preparo) | Implementado (whiff deixa de existir: confirmar) |
| [D-029](D-029-desvio-nao-perfeito-na-corrida-e-lado.md) | Combate | Desvio não perfeito na corrida cancela o ataque e volta à origem; parado vai para o lado por 0,5 s; automático só pisca no lugar | Implementado |
| [D-030](D-030-evade-so-no-golpe.md) | Combate | O Evade só no golpe em si (a fase que termina com o acerto), não no anúncio nem na corrida | Implementado (projétil = voo, confirmado) |
