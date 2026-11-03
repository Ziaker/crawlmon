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
| [D-031](D-031-r39-q1-atb-inicial.md) | Combate / R39 | R39-Q1 (1A): ATB inicial e autorização de ação | Aprovada; implementação não declarada |
| [D-032](D-032-r39-q2-moves-hotkeys.md) | Combate / R39 | R39-Q2 (2A): Quantidade de Moves e controles | Aprovada; implementação não declarada |
| [D-033](D-033-r39-q3-burst-pagamento.md) | Combate / R39 | R39-Q3 (3A): Burst como pagamento completo | Aprovada; implementação não declarada |
| [D-034](D-034-r39-q4-evade-janela.md) | Combate / R39 | R39-Q4 (4A): Janela e custo do Evade manual | Aprovada; implementação não declarada |
| [D-035](D-035-r39-q5-ataque-continua.md) | Combate / R39 | R39-Q5 (5B): Evade perfeito preserva ataque original | Aprovada; implementação não declarada |
| [D-036](D-036-r39-q6-aoe-individual.md) | Combate / R39 | R39-Q6 (6A): AoE sem principal e com esquiva individual | Aprovada; implementação não declarada |
| [D-037](D-037-r39-q7-aoe-alvos-declaracao.md) | Combate / R39 | R39-Q7 (7A): Participantes do AoE na declaração | Aprovada; implementação não declarada |
| [D-038](D-038-r39-q8-status-pausa.md) | Combate / R39 | R39-Q8 (8A): Pausa de Moves de status na ativação | Aprovada; implementação não declarada |
| [D-039](D-039-r39-q9-camera-inimigos.md) | Combate / R39 | R39-Q9 (9A): Todos os inimigos enquadrados | Aprovada; implementação não declarada |
| [D-040](D-040-r39-q10-fase2-arquitetura.md) | Combate / R39 | R39-Q10 (10B): Arquitetura reintegrada da Fase 2 | Aprovada; implementação não declarada |
| [D-041](D-041-r40-q1-fim-do-golpe.md) | Combate / R40 | R40-Q1 (1A): Fim do golpe antes do retorno | Aprovada; implementação não declarada |
| [D-042](D-042-r40-q2-contra-ataque-dois-segundos.md) | Combate / R40 | R40-Q2 (2B): Janela de dois segundos após Evade perfeito | Aprovada; implementação não declarada |
| [D-043](D-043-r40-q3-contra-ataque-manual.md) | Combate / R40 | R40-Q3 (3A): Seleção manual do contra-ataque | Aprovada; implementação não declarada |
| [D-044](D-044-r40-q4-perseguicao-corrida.md) | Combate / R40 | R40-Q4 (4B): Perseguição na corrida, golpe com trajetória fixa | Aprovada; implementação não declarada |
| [D-045](D-045-r40-q5-recuo-visual.md) | Combate / R40 | R40-Q5 (5B): Recuo visual em qualquer hit recebido | Aprovada; implementação não declarada |
| [D-046](D-046-r40-q6-contato-motor.md) | Combate / R40 | R40-Q6 (6A): Contato espacial exato do motor | Aprovada; implementação não declarada |
| [D-047](D-047-r40-q7-projetil-guiado.md) | Combate / R40 | R40-Q7 (7A): Alvo declarado e projétil guiado | Aprovada; implementação não declarada |
| [D-048](D-048-r40-q8-atb-aoe-unico.md) | Combate / R40 | R40-Q8 (8A): Recompensas únicas por condição em AoE | Aprovada; implementação não declarada |
| [D-049](D-049-r40-q9-hitstop-onda.md) | Combate / R40 | R40-Q9 (9A): Hit-stop no primeiro impacto de onda AoE | Aprovada; implementação não declarada |
| [D-050](D-050-r40-q10-camera-zoom.md) | Combate / R40 | R40-Q10 (10A): Zoom e deslocamento sem tremor | Aprovada; implementação não declarada |
| [D-051](D-051-r41-q1-contra-ataque-fila.md) | Combate / R41 | R41-Q1 (1B): Contra-ataque escolhido no prazo pode executar depois | Aprovada; implementação não declarada |
| [D-052](D-052-r41-q2-selecao-antecipada.md) | Combate / R41 | R41-Q2 (2B): Seleção antecipada e execução enfileirada | Aprovada; implementação não declarada |
| [D-053](D-053-r41-q3-custo-contra-ataque.md) | Combate / R41 | R41-Q3 (3A): Custo normal do golpe extra | Aprovada; implementação não declarada |
| [D-054](D-054-r41-q4-contato-no-impacto.md) | Combate / R41 | R41-Q4 (4A): Ajuste espacial somente no impacto | Aprovada; implementação não declarada |
| [D-055](D-055-r41-q5-recuos-acumulados.md) | Combate / R41 | R41-Q5 (5B): Acumulação temporária dos recuos visuais | Aprovada; implementação não declarada |
| [D-056](D-056-r41-q6-fatal-lancamento.md) | Combate / R41 | R41-Q6 (6D): Lançamento fatal cinematográfico e desaparecimento | Aprovada; implementação não declarada |
| [D-057](D-057-r41-q7-onda-velocidade.md) | Combate / R41 | R41-Q7 (7A): Onda AoE em velocidade espacial constante | Aprovada; implementação não declarada |
| [D-058](D-058-r41-q8-alvo-morto.md) | Combate / R41 | R41-Q8 (8A): Alvo morto antes da chegada da onda | Aprovada; implementação não declarada |
| [D-059](D-059-r41-q9-evade-onda.md) | Combate / R41 | R41-Q9 (9B): Janela compartilhada de Evade da onda AoE | Aprovada; implementação não declarada |
| [D-060](D-060-r41-q10-status-idle-camera.md) | Combate / R41 | R41-Q10 (10B): Pausa seletiva de status com idle e câmera | Aprovada; implementação não declarada |
| [D-061](D-061-registro-continuo-das-decisoes.md) | Processo | Registrar e publicar cada decisão de design antes de avançar para a próxima rodada | Diretriz operacional |
| [D-062](D-062-r42-q1-custo-na-selecao.md) | Combate / R42 | R42-Q1 (1A): Cobrança na seleção do contra-ataque | Aprovada; implementação não declarada |
| [D-063](D-063-r42-q2-burst-antes-atb.md) | Combate / R42 | R42-Q2 (2A): Prioridade de Burst ao pagar Moves | Aprovada; implementação não declarada |
| [D-064](D-064-r42-q3-interrupcao-cancela-extra.md) | Combate / R42 | R42-Q3 (3A): Interrupção do original cancela contra-ataque | Aprovada; implementação não declarada |
| [D-065](D-065-r42-q4-alvo-morre-cancela-extra.md) | Combate / R42 | R42-Q4 (4A): Morte do alvo cancela golpe extra | Aprovada; implementação não declarada |
| [D-066](D-066-r42-q5-onda-evade-perfeito-comum.md) | Combate / R42 | R42-Q5 (5A): Janela perfeita compartilhada na onda AoE | Aprovada; implementação não declarada |
| [D-067](D-067-r42-q6-onda-alvos-posicao-atual.md) | Combate / R42 | R42-Q6 (6A): Onda AoE acompanha posições atuais | Aprovada; implementação não declarada |
| [D-068](D-068-r42-q7-aliado-lancado-nao-some.md) | Combate / R42 | R42-Q7 (7C): Derrota fatal de aliado sem desaparecimento | Aprovada; implementação não declarada |
| [D-069](D-069-r42-q8-intensidade-fatal-padronizada.md) | Combate / R42 | R42-Q8 (8A): Lançamento fatal de intensidade uniforme | Aprovada; implementação não declarada |
| [D-070](D-070-r42-q9-apenas-idle-ja-existente.md) | Combate / R42 | R42-Q9 (9A): Somente idle existente durante FX de status | Aprovada; implementação não declarada |
| [D-071](D-071-r42-q10-cronometro-pausado-hitstop-status.md) | Combate / R42 | R42-Q10 (10B): Pausar cronômetro do contra-ataque em hit-stop e status | Aprovada; implementação não declarada |
| [D-072](D-072-r43-q1-estorno-interrupcao.md) | Combate / R43 | R43-Q1 (1A): Devolver custo do contra-ataque cancelado por interrupção | Recomendação aceita por delegação; implementação não declarada |
| [D-073](D-073-r43-q2-estorno-alvo-morto.md) | Combate / R43 | R43-Q2 (2A): Devolver custo do contra-ataque cancelado por morte do alvo | Recomendação aceita por delegação; implementação não declarada |
| [D-074](D-074-r43-q3-personagem-morre-estorno.md) | Combate / R43 | R43-Q3 (3C): Morte do executor cancela o golpe extra com estorno | Recomendação aceita por delegação; implementação não declarada |
| [D-075](D-075-r43-q4-janela-perfeita-primeiro-impacto.md) | Combate / R43 | R43-Q4 (4A): Janela perfeita única antes do primeiro impacto da onda AoE | Recomendação aceita por delegação; implementação não declarada |
| [D-076](D-076-r43-q5-evade-visual-imediato.md) | Combate / R43 | R43-Q5 (5A): Evade visual imediato e registro para impacto posterior | Recomendação aceita por delegação; implementação não declarada |
| [D-077](D-077-r43-q6-geometria-por-move.md) | Combate / R43 | R43-Q6 (6D): Geometria da onda AoE definida por Move | Recomendação aceita por delegação; implementação não declarada |
| [D-078](D-078-r43-q7-velocidade-configuravel-move.md) | Combate / R43 | R43-Q7 (7A): Velocidade de onda AoE configurável por Move | Recomendação aceita por delegação; implementação não declarada |
| [D-079](D-079-r43-q8-lancamento-fatal-oposto-atacante.md) | Combate / R43 | R43-Q8 (8A): Lançamento fatal afastando do atacante | Recomendação aceita por delegação; implementação não declarada |
| [D-080](D-080-r43-q9-desaparecimento-particulas.md) | Combate / R43 | R43-Q9 (9C): Desaparecimento fatal com partículas e fumaça | Recomendação aceita por delegação; implementação não declarada |
| [D-081](D-081-r43-q10-resultado-apos-fatal.md) | Combate / R43 | R43-Q10 (10A): Resultado exibido somente após sequência fatal completa | Recomendação aceita por delegação; implementação não declarada |
| [D-082](D-082-r44-q1-credito-estorno-excedente.md) | Combate / R44 | R44-Q1 (1A): Crédito de restituição quando o medidor está cheio | Recomendação aceita por delegação; implementação não declarada |
| [D-083](D-083-r44-q2-janela-aoe-primeiro-falha.md) | Combate / R44 | R44-Q2 (2A): Janela de AoE preservada quando o primeiro impacto falha | Recomendação aceita por delegação; implementação não declarada |
| [D-084](D-084-r44-q3-onda-recalculo-primeiro-impacto.md) | Combate / R44 | R44-Q3 (3A): Recalcular previsão do primeiro impacto com alvos móveis | Recomendação aceita por delegação; implementação não declarada |
| [D-085](D-085-r44-q4-onda-sem-alvos-vivos.md) | Combate / R44 | R44-Q4 (4B): Onda continua visualmente se todos os alvos morrerem | Recomendação aceita por delegação; implementação não declarada |
| [D-086](D-086-r44-q5-burst-evade-onda.md) | Combate / R44 | R44-Q5 (5B): Burst por qualquer Evade bem-sucedido em onda AoE | Recomendação aceita por delegação; implementação não declarada |
| [D-087](D-087-r44-q6-duracao-fatal-global.md) | Combate / R44 | R44-Q6 (6A): Duração global configurável do lançamento fatal | Recomendação aceita por delegação; implementação não declarada |
| [D-088](D-088-r44-q7-arco-fatal-cinematografico.md) | Combate / R44 | R44-Q7 (7A): Trajetória fatal em arco aéreo exagerado | Recomendação aceita por delegação; implementação não declarada |
| [D-089](D-089-r44-q8-colisao-fatal-obstaculos.md) | Combate / R44 | R44-Q8 (8A): Colisão fatal interrompe o voo e causa queda | Recomendação aceita por delegação; implementação não declarada |
| [D-090](D-090-r44-q9-resultado-apos-multiplos-fatais.md) | Combate / R44 | R44-Q9 (9A): Resultado aguarda todas as sequências fatais de um AoE | Recomendação aceita por delegação; implementação não declarada |
| [D-091](D-091-r44-q10-ko-simultaneo-empate.md) | Combate / R44 | R44-Q10 (10B): KO simultâneo de equipes encerra em empate sem vencedor | Recomendação aceita por delegação; implementação não declarada |
| [D-092](D-092-r45-q2-evade-ataques-sobrepostos.md) | Combate / R45 | R45-Q2 (2A): Evade cobre impactos simultâneos | Decisão expressa; implementação não declarada |
| [D-093](D-093-r45-q3-contra-extra-unico-varios-atacantes.md) | Combate / R45 | R45-Q3 (3A): Um único contra-ataque extra por múltiplos Evades perfeitos | Decisão expressa; implementação não declarada |
| [D-094](D-094-r45-q4-projetil-apos-morte-lancador.md) | Combate / R45 | R45-Q4 (4A): Projétil lançado persiste após morte do lançador | Decisão expressa; implementação não declarada |
| [D-095](D-095-r45-q5-empate-mesmo-instante-logico.md) | Combate / R45 | R45-Q5 (5A): Empate por eliminação simultânea mesmo com ataques diferentes | Decisão expressa; implementação não declarada |
| [D-096](D-096-r45-q6-combate-continua-durante-morte.md) | Combate / R45 | R45-Q6 (6A): Sobreviventes continuam agindo durante animação de morte | Decisão expressa; implementação não declarada |
| [D-097](D-097-r46-q1-implementacao-por-sistemas-testados.md) | Combate / R46 | R46-Q1 (1B): Implementação em sistemas completos e testados | Recomendação aceita expressamente; implementação não declarada |
| [D-098](D-098-r46-q2-alvo-contra-extra-multiplos.md) | Combate / R46 | R46-Q2 (2A): Seleção manual do atacante-alvo e seleção pela IA | Recomendação aceita expressamente; implementação não declarada |
| [D-099](D-099-r46-q3-projetil-pendente-resultado.md) | Combate / R46 | R46-Q3 (3A): Aguardar projéteis em voo antes do resultado definitivo | Recomendação aceita expressamente; implementação não declarada |
| [D-100](D-100-r47-q1-sem-novas-acoes-projeteis-pendentes.md) | Combate / R47 | R47-Q1 (1A): Nenhuma nova ação durante resolução de projéteis pendentes | Decisão expressa; não implementada por esta entrega |
| [D-101](D-101-r47-q2-move-alvo-dentro-dois-segundos.md) | Combate / R47 | R47-Q2 (2A): Move e atacante-alvo escolhidos na mesma janela de dois segundos | Decisão expressa; não implementada por esta entrega |
| [D-102](D-102-r47-q3-continuar-somente-documentacao.md) | Processo / R47 | R47-Q3 (3B): Não alterar código do jogo existente; somente documentação e decisões | Decisão expressa; não implementada por esta entrega |
| [D-103](D-103-r48-q1-fim-imediato-retarget-windup.md) | Combate / R48 | R48-Q1: Último inimigo termina batalha; com outros inimigos, wind-up retargeta | Declaração registrada; conflito de compatibilidade pendente; sem implementação |
| [D-104](D-104-r48-q2-evade-termino-visual-sem-stagger.md) | Combate / R48 | R48-Q2: Evade é evasão; ataques terminam visualmente sem animação de interrupção | Declaração registrada; conflito de compatibilidade pendente; sem implementação |
| [D-105](D-105-r48-esclarecimento-vitoria-ultimo-inimigo.md) | Combate / R48 | R48-1A: vitória definitiva após último inimigo; projéteis pendentes sem dano | Aprovada expressamente; conflito D-099/D-100 delimitado; não implementada |
| [D-106](D-106-r48-esclarecimento-evade-ataque-erra.md) | Combate / R48 | R48-2A: golpes evitados terminam como erros, sem interrupção mecânica | Aprovada expressamente; conflito D-017/D-104 resolvido; não implementada |
| [D-107](D-107-r49-q1-derrota-definitiva-ultimo-aliado.md) | Combate / R49 | R49-Q1 (1A): derrota definitiva após último aliado; projéteis pendentes sem dano | Decisão expressa; complementa D-105; implementação não declarada |
| [D-108](D-108-r49-q2-inimigo-vivo-mais-proximo-no-windup.md) | Combate / R49 | R49-Q2 (2B): troca automática para inimigo vivo mais próximo no wind-up | Decisão expressa; complementa D-103; implementação não declarada |
| [D-109](D-109-r50-q1-projetil-alvo-morto-em-voo.md) | Combate / R50 | R50-Q1 (1A): projétil de alvo único termina sem dano se o alvo morrer durante o voo | Decisão expressa; R50-Q2 não definiu regra nova; implementação não declarada |
| [D-110](D-110-r51-q1-manter-interceptacao-personagens.md) | Combate / R51 | R51-Q1 (1A): manter a interceptação existente de projéteis por personagens | Decisão expressa; sem implementação nova |
| [D-111](D-111-r51-q2-alvo-aleatorio-ia.md) | Combate / IA / R51 | R51-Q2 (2C): IA escolhe adversário vivo aleatoriamente, respeitando engajamento | Decisão expressa; implementação não declarada |
