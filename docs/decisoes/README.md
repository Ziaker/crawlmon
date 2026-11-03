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
| [D-31](D-031-r39-q1-atb-inicial.md) | Combate / R39 | R39-Q1 (1A): ATB inicial e autorização de ação | Aprovada; implementação não declarada |
| [D-32](D-032-r39-q2-moves-hotkeys.md) | Combate / R39 | R39-Q2 (2A): Quantidade de Moves e controles | Aprovada; implementação não declarada |
| [D-33](D-033-r39-q3-burst-pagamento.md) | Combate / R39 | R39-Q3 (3A): Burst como pagamento completo | Aprovada; implementação não declarada |
| [D-34](D-034-r39-q4-evade-janela.md) | Combate / R39 | R39-Q4 (4A): Janela e custo do Evade manual | Aprovada; implementação não declarada |
| [D-35](D-035-r39-q5-ataque-continua.md) | Combate / R39 | R39-Q5 (5B): Evade perfeito preserva ataque original | Aprovada; implementação não declarada |
| [D-36](D-036-r39-q6-aoe-individual.md) | Combate / R39 | R39-Q6 (6A): AoE sem principal e com esquiva individual | Aprovada; implementação não declarada |
| [D-37](D-037-r39-q7-aoe-alvos-declaracao.md) | Combate / R39 | R39-Q7 (7A): Participantes do AoE na declaração | Aprovada; implementação não declarada |
| [D-38](D-038-r39-q8-status-pausa.md) | Combate / R39 | R39-Q8 (8A): Pausa de Moves de status na ativação | Aprovada; implementação não declarada |
| [D-39](D-039-r39-q9-camera-inimigos.md) | Combate / R39 | R39-Q9 (9A): Todos os inimigos enquadrados | Aprovada; implementação não declarada |
| [D-40](D-040-r39-q10-fase2-arquitetura.md) | Combate / R39 | R39-Q10 (10B): Arquitetura reintegrada da Fase 2 | Aprovada; implementação não declarada |
| [D-41](D-041-r40-q1-fim-do-golpe.md) | Combate / R40 | R40-Q1 (1A): Fim do golpe antes do retorno | Aprovada; implementação não declarada |
| [D-42](D-042-r40-q2-contra-ataque-dois-segundos.md) | Combate / R40 | R40-Q2 (2B): Janela de dois segundos após Evade perfeito | Aprovada; implementação não declarada |
| [D-43](D-043-r40-q3-contra-ataque-manual.md) | Combate / R40 | R40-Q3 (3A): Seleção manual do contra-ataque | Aprovada; implementação não declarada |
| [D-44](D-044-r40-q4-perseguicao-corrida.md) | Combate / R40 | R40-Q4 (4B): Perseguição na corrida, golpe com trajetória fixa | Aprovada; implementação não declarada |
| [D-45](D-045-r40-q5-recuo-visual.md) | Combate / R40 | R40-Q5 (5B): Recuo visual em qualquer hit recebido | Aprovada; implementação não declarada |
| [D-46](D-046-r40-q6-contato-motor.md) | Combate / R40 | R40-Q6 (6A): Contato espacial exato do motor | Aprovada; implementação não declarada |
| [D-47](D-047-r40-q7-projetil-guiado.md) | Combate / R40 | R40-Q7 (7A): Alvo declarado e projétil guiado | Aprovada; implementação não declarada |
| [D-48](D-048-r40-q8-atb-aoe-unico.md) | Combate / R40 | R40-Q8 (8A): Recompensas únicas por condição em AoE | Aprovada; implementação não declarada |
| [D-49](D-049-r40-q9-hitstop-onda.md) | Combate / R40 | R40-Q9 (9A): Hit-stop no primeiro impacto de onda AoE | Aprovada; implementação não declarada |
| [D-50](D-050-r40-q10-camera-zoom.md) | Combate / R40 | R40-Q10 (10A): Zoom e deslocamento sem tremor | Aprovada; implementação não declarada |
| [D-51](D-051-r41-q1-contra-ataque-fila.md) | Combate / R41 | R41-Q1 (1B): Contra-ataque escolhido no prazo pode executar depois | Aprovada; implementação não declarada |
| [D-52](D-052-r41-q2-selecao-antecipada.md) | Combate / R41 | R41-Q2 (2B): Seleção antecipada e execução enfileirada | Aprovada; implementação não declarada |
| [D-53](D-053-r41-q3-custo-contra-ataque.md) | Combate / R41 | R41-Q3 (3A): Custo normal do golpe extra | Aprovada; implementação não declarada |
| [D-54](D-054-r41-q4-contato-no-impacto.md) | Combate / R41 | R41-Q4 (4A): Ajuste espacial somente no impacto | Aprovada; implementação não declarada |
| [D-55](D-055-r41-q5-recuos-acumulados.md) | Combate / R41 | R41-Q5 (5B): Acumulação temporária dos recuos visuais | Aprovada; implementação não declarada |
| [D-56](D-056-r41-q6-fatal-lancamento.md) | Combate / R41 | R41-Q6 (6D): Lançamento fatal cinematográfico e desaparecimento | Aprovada; implementação não declarada |
| [D-57](D-057-r41-q7-onda-velocidade.md) | Combate / R41 | R41-Q7 (7A): Onda AoE em velocidade espacial constante | Aprovada; implementação não declarada |
| [D-58](D-058-r41-q8-alvo-morto.md) | Combate / R41 | R41-Q8 (8A): Alvo morto antes da chegada da onda | Aprovada; implementação não declarada |
| [D-59](D-059-r41-q9-evade-onda.md) | Combate / R41 | R41-Q9 (9B): Janela compartilhada de Evade da onda AoE | Aprovada; implementação não declarada |
| [D-60](D-060-r41-q10-status-idle-camera.md) | Combate / R41 | R41-Q10 (10B): Pausa seletiva de status com idle e câmera | Aprovada; implementação não declarada |
| [D-061](D-061-registro-continuo-das-decisoes.md) | Processo | Registrar e publicar cada decisão de design antes de avançar para a próxima rodada | Diretriz operacional |
