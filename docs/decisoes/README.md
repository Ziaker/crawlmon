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
| [D-031](D-031-status-pausa-o-motor.md) | Combate | Status: não desviável; preparo 0,5 s; motor pausado desde o preparo (animações e efeitos seguem); Media/Tarukaja 2 ATB, demais 1 | Implementado |
| [D-032](D-032-balanceamento-moves-ingles-e-status.md) | Combate | Nomes em inglês, rebalanceamento de moves, invulnerabilidade e novos status | Em implementação |
| [D-033](D-033-overworld-mais-claro-e-consumiveis-no-mapa.md) | Exploração | Overworld mais claro, já visitado 100% iluminado e Poções no mapa (2–4 por andar, coleta automática, persistem) | Implementado |
| [D-034](D-034-teleport-sumir-apos-windup-e-sem-deslocamento.md) | Combate | Teleport: sumir após o wind-up, sem deslocamento e reaparecer na origem | Em implementação |
| [D-035](D-035-vfx-smt-kaja-kunda.md) | Visual / VFX | VFX 3D e Shaders para Buffs/Debuffs SMT (Tarukaja, Rakunda, Sukunda amarelo) | Implementado |
| [D-036](D-036-smt-vfx-pilares-auras-volumetricas.md) | Visual / VFX | Pilares e Auras de Energia Volumétricas para Buffs/Debuffs SMT | **Revogado** a pedido do criador |
| [D-037](D-037-smt-vfx-selos-impacto-e-estase.md) | Visual / VFX | VFX SMT Avançado: Selos Rúnicos, Ruptura de Escudo e Estase Temporal | Implementado |
| [D-038](D-038-calibracao-iluminacao-e-sombreamento-anime.md) | Visual / Iluminação | Calibração da Iluminação da Batalha e Sombreamento Anime dos Pokémon | Implementado |
| [D-039](D-039-elevacao-camera-combate-15-porcento.md) | Câmera / Visual | Elevação da Câmera de Combate em 15% (Opção 1: Y = 2.875) | Implementado |
| [D-040](D-040-acoes-com-1-atb.md) | Combate / Menu | Liberação de Ações com 1 ATB para Habilidades de Custo 1 | Implementado |
| [D-041](D-041-vfx-impacto-tackle-e-poeira-de-corrida.md) | Visual / VFX / Game Feel | Efeitos Visuais Aprimorados: Impacto de Tackle e Poeira de Corrida Física | Implementado |
| [D-042](D-042-motion-composer-toggle-edicao.md) | Motion Composer / laboratório | Toggle entre atualizar no instante atual com reconstrução dos rastros e reiniciar ao editar | Especificado; não implementado |
| [D-043](D-043-motion-composer-camadas-ordenadas.md) | Motion Composer / interface | Composição por camadas ordenadas | Especificado; não implementado |
| [D-044](D-044-motion-composer-representacoes-v1.md) | Motion Composer / laboratório | Pontos, fragmentos, fitas e fumaça/billboards disponíveis na V1 | Especificado; não implementado |
| [D-045](D-045-motion-composer-pasta-fixa-presets.md) | Motion Composer / persistência | Salvar e carregar presets em pasta fixa do laboratório | Especificado; não implementado |
| [D-046](D-046-motion-composer-escopo-especificacao.md) | Motion Composer / escopo | Catálogo M01–M20 e consolidação da especificação com propostas técnicas identificadas | Documentado; não implementado |
| [D-047](D-047-camera-lenta-3s-decisao-menu.md) | Combate / UI / Game Feel | Câmera Lenta de 3 Segundos para Decisão nos Menus Fight e Itens | Implementado |
| [D-048](D-048-rolling-hp-mother3-odometro.md) | Combate / UI / Game Feel / Configurações | Mecânica de Vida Rolante (Rolling HP / Odômetro estilo Mother 3 / EarthBound) | Implementado |
| [D-049](D-049-knockback-final-e-screen-shake-ko.md) | Combate / Visual / Game Feel / Câmera | Impacto de K.O.: Lançamento Balístico do Inimigo, Shake Épico e VFX de Derrota | Implementado |

## Decisões Documentais de Design / Rodadas R39–R61 (GDD e REGRAS_DO_JOGO)

| ID | Área | Decisão | Estado |
|---|---|---|---|
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
| [D-112](D-112-r52-q1-escolha-tatica-de-moves-ia.md) | Combate / IA / R52 | R52-Q1 (1C): escolha tática de Move, sem alterar alvo aleatório | Decisão expressa; implementação não declarada |
| [D-113](D-113-r52-q2-interromper-investida-alvo-morto.md) | Combate / R52 | R52-Q2 (2C): alvo morre na investida; retorno imediato à origem | Decisão expressa; implementação não declarada |
| [D-114](D-114-r53-q1-alvo-antes-move-tatico.md) | Combate / IA / R53 | R53-Q1: escolher alvo aleatório antes do Move tático | Recomendação 1A aceita por delegação expressa; sem código |
| [D-115](D-115-r53-q2-cura-situacional-da-ia.md) | Combate / IA / R53 | R53-Q2: cura por poção avaliada taticamente conforme a situação | Recomendação 2B aceita por delegação expressa; sem código |
| [D-116](D-116-delegacao-recomendacoes-ia.md) | Processo / IA | Delegação das recomendações futuras sobre comportamento da IA | Autorização expressa limitada ao design de IA; sem implementação |
| [D-117](D-117-r54-esclarecimento-agi-atb-e-trajeto.md) | Atributos / R54 | AGI acelera preenchimento de ATB e movimento nos trajetos de ataque | Correção expressa; fórmulas pendentes; somente documentação |
| [D-118](D-118-r54-referencia-elementos-smt.md) | Elementos / R54 | Afinidades e elementos inspirados principalmente em SMT, não em Pokémon | Correção expressa; lista e afinidades existentes preservadas |
| [D-119](D-119-r54-tempo-trajeto-por-move-reduzido-agi.md) | Atributos / R54 | Tempo de deslocamento individual por ficha de Move, reduzido por AGI e buffs de AGI | Esclarecimento expresso; fórmulas pendentes; sem código |
| [D-120](D-120-r54-q1-atributos-base-especie-referencia-biologica.md) | Personagens / R54 | Q1C: Atributos-base por espécie com referência biológica e balanceamento próprio | Aprovada expressamente; fórmulas/dados ainda pendentes; sem código |
| [D-121](D-121-r54-q2-pequena-variacao-aleatoria-atributos-individuais.md) | Personagens / R54 | Q2B: Pequenas variações aleatórias individuais nos atributos-base | Aprovada expressamente; fórmulas/dados ainda pendentes; sem código |
| [D-122](D-122-r54-q3-forca-dano-fisico-magia-dano-magico.md) | Personagens / R54 | Q3A: Força determina base de dano físico e Magia determina base de dano mágico/especial | Aprovada expressamente; fórmulas/dados ainda pendentes; sem código |
| [D-123](D-123-r54-q4-magia-efeitos-por-move-escalaveis.md) | Personagens / R54 | Q4B: Magia escala dano e apenas efeitos declarados escaláveis por Move | Aprovada expressamente; fórmulas/dados ainda pendentes; sem código |
| [D-124](D-124-r54-q5-hp-vitalidade-nivel-coeficientes-especie.md) | Personagens / R54 | Q5B: HP máximo por Vitalidade e nível com coeficientes de espécie | Aprovada expressamente; fórmulas/dados ainda pendentes; sem código |
| [D-125](D-125-r54-q6-vitalidade-resistencia-base-defesa-estagios.md) | Personagens / R54 | Q6A: Vitalidade influencia defesa natural mantendo estágios de Defesa | Aprovada expressamente; fórmulas/dados ainda pendentes; sem código |
| [D-126](D-126-r54-q7-calibrar-agi-atb-tempos-moves.md) | Personagens / R54 | Q7A: Calibrar AGI preservando ATB e tempos individuais dos Moves | Aprovada expressamente; fórmulas/dados ainda pendentes; sem código |
| [D-127](D-127-r54-q8-sorte-critico-esquiva-automatica-status.md) | Personagens / R54 | Q8C: Sorte modifica crítico, esquiva automática e aplicação de status | Aprovada expressamente; fórmulas/dados ainda pendentes; sem código |
| [D-128](D-128-r54-q9-afinidades-por-especie-referencia-smt.md) | Personagens / R54 | Q9A: Afinidades por espécie com SMT como referência principal | Aprovada expressamente; fórmulas/dados ainda pendentes; sem código |
| [D-129](D-129-r54-q10-atributos-permanentes-1-a-100-buffs-separados.md) | Personagens / R54 | Q10A: Atributos permanentes limitados a 1–100, buffs à parte | Aprovada expressamente; fórmulas/dados ainda pendentes; sem código |
| [D-130](D-130-separacao-vitality-fisico-spirit-magico.md) | Personagens / atributos | Spirit (SPI) mitiga dano mágico; Vitality (VIT) apenas dano físico, mantendo HP | Nova decisão expressa e escolha de nome delegada; nenhum código |
| [D-131](D-131-nomes-atributos-em-ingles.md) | Personagens / nomenclatura | Os seis atributos usam nomes ingleses e siglas STR, MAG, VIT, SPI, AGI, LUK | Regra expressa; nome Spirit escolhido pelo assistente a pedido |
| [D-132](D-132-r55-q1-variacao-individual-mais-menos-3.md) | Atributos / R55 | R55-Q1A: Variação individual persistente de até ±3 pontos por atributo-base | Escolha expressa; somente documentação; detalhes não aprovados preservados |
| [D-133](D-133-r55-q2-agi-antes-passos-tempo-move.md) | Atributos / R55 | R55-Q2A: Redução por AGI antes do ajuste dos passos no tempo individual do Move | Escolha expressa; somente documentação; detalhes não aprovados preservados |
| [D-134](D-134-r55-q3-luk-somente-status-com-chance.md) | Atributos / R55 | R55-Q3A: LUK só afeta aplicação de status declarada como probabilística na ficha do Move | Escolha expressa; somente documentação; detalhes não aprovados preservados |
| [D-135](D-135-r55-q5-seis-atributos-no-teto-sem-distribuicao.md) | Atributos / R55 | R55-Q5A: Dispensa excepcional da distribuição obrigatória quando seis atributos estão em 100 | Escolha expressa; somente documentação; detalhes não aprovados preservados |
| [D-136](D-136-r56-q2-agi-inversamente-proporcional.md) | Combate / atributos / R56 | R56-Q2: Tempo de trajeto inversamente proporcional à AGI efetiva | Aprovado expressamente; sem código |
| [D-137](D-137-r56-q3-diferenca-luk-aplicador-alvo.md) | Combate / atributos / R56 | R56-Q3: Diferença entre Luck do aplicador e do alvo modifica a chance de status | Aprovado expressamente; sem código |
| [D-138](D-138-r56-q4-defense-estagios-fisico-magico.md) | Combate / atributos / R56 | R56-Q4: Estágios de Defense afetam danos físicos e mágicos com VIT/SPI separados | Aprovado expressamente; sem código |
| [D-139](D-139-r57-q1-atributos-sem-teto-100.md) | Personagens / R57 | R57-Q1B: Atributos permanentes podem ultrapassar 100 sem teto máximo | Aprovada expressamente; nenhuma alteração de código |
| [D-140](D-140-r57-q2-agi-minimo-1-formula.md) | Personagens / R57 | R57-Q2A: AGI efetiva mínima de 1 apenas para o cálculo inverso do Move | Aprovada expressamente; nenhuma alteração de código |
| [D-141](D-141-r57-q3-sorteio-individual-central.md) | Personagens / R57 | R57-Q3B: Distribuição do sorteio individual favorece valores perto de zero | Aprovada expressamente; nenhuma alteração de código |
| [D-142](D-142-r57-q4-luk-1pp-cada-10.md) | Personagens / R57 | R57-Q4B: Status probabilístico: 1 ponto percentual para cada 10 pontos de diferença LUK | Aprovada expressamente; nenhuma alteração de código |
| [D-143](D-143-r58-q2-probabilidade-status-0-100.md) | Atributos / R58 | Q2A: Probabilidade final de status limitada ao intervalo 0–100% | Escolha expressa; documentação somente |
| [D-144](D-144-r58-q3-sorteio-triangular-1-2-3-4-3-2-1.md) | Atributos / R58 | Q3A: Sorteio individual triangular com pesos 1:2:3:4:3:2:1 | Escolha expressa; documentação somente |
| [D-145](D-145-r58-q4-referencias-agi-distintas-atb-trajeto.md) | Atributos / R58 | Q4B: Referências numéricas distintas para ATB e trajetos com AGI única | Escolha expressa; documentação somente |
| [D-146](D-146-r59-q1-luk-um-ponto-percentual-por-ponto.md) | Atributos / R59 | Q1A: Aplicação de status: 1 ponto percentual por ponto da diferença de LUK | Aprovada expressamente; somente documentação |
| [D-147](D-147-r59-q2-sorteios-independentes-seis-atributos.md) | Atributos / R59 | Q2A: Sorteios individuais independentes nos seis atributos | Aprovada expressamente; somente documentação |
| [D-148](D-148-r59-q3-duracao-trajeto-fixa-ao-iniciar-ataque.md) | Atributos / R59 | Q3A: Duração de trajeto calculada no início do ataque e fixa até seu término | Aprovada expressamente; somente documentação |
| [D-149](D-149-r60-q1-recalculo-unico-trajeto-na-troca-de-alvo.md) | Combate / R60 | R60-Q1 (1A): recalcular duração uma vez ao trocar alvo morto no wind-up; nova duração fixa | Aprovada expressamente; complemento de D-108/D-148; sem código |
| [D-150](D-150-r60-q2-critico-luk-um-ponto-percentual.md) | Combate / R60 | R60-Q2 (2B): crítico 10% base + 1 pp por ponto de diferença de LUK | Aprovada expressamente; sem código |
| [D-151](D-151-r60-q4-limites-critico-esquiva-automatica.md) | Combate / R60 | R60-Q4 (4A): crítico e esquiva automática entre 0–100%; R60-Q3D continua pendente | Aprovada expressamente apenas para limites; sem código |

| [D-152](D-152-r61-q1-esquiva-luk-retorno-decrescente.md) | Combate / R61 | Q1B: esquiva automática usa ganho marginal de LUK reduzido pela metade a cada faixa de 10 | Aprovada expressamente; sem código |
| [D-153](D-153-r61-q2-esquiva-luk-curva-simetrica.md) | Combate / R61 | Q2A: mesma curva da esquiva atua simetricamente para diferenças negativas | Aprovada expressamente; sem código |
| [D-154](D-154-r61-q3-trajeto-calculo-inicio-windup.md) | Combate / R61 | Q3A: capturar duração do trajeto ao entrar efetivamente em WINDUP | Aprovada expressamente; sem código |
| [D-155](D-155-r61-q4-trajeto-recalculo-cada-troca-windup.md) | Combate / R61 | Q4A: recálculo uma vez em cada troca automática de alvo no WINDUP | Aprovada expressamente; sem código |
| [D-156](D-156-r61-q5-luk-no-instante-da-rolagem.md) | Combate / R61 | Q5A: consultar LUK efetiva na resolução de cada evento probabilístico | Aprovada expressamente; sem código |
| [D-157](D-157-r62-q1-trajeto-instantaneo-inicio-execucao.md) | Combate / R62 | Q1A: Move instantâneo sem WINDUP calcula duração ao iniciar execução efetiva | Aprovada; documentação apenas |
| [D-158](D-158-r62-q2-desempate-alvo-identificador-estavel.md) | Combate / R62 | Q2A: empate de distâncias no retarget do WINDUP desempatado deterministicamente por ID estável de combate | Aprovada; ordenação detalhada pendente; sem código |
| [D-159](D-159-r62-q3-ordem-deterministica-luk.md) | Combate / R62 | Q3A: linha do tempo com ordem determinística; mudanças de LUK anteriores à rolagem valem | Aprovada; preserva D-095; sem código |
| [D-160](D-160-r62-q4-referencia-agi-50-trajetos.md) | Combate / R62 | Q4A: referência AGI = 50 exclusivamente para tempo dos trajetos | Aprovada; não fixa ATB; sem código |
| [D-161](D-161-r62-q5-referencia-atb-pendente-avaliacao.md) | Combate / R62 | Q5B: referência numérica de AGI para ATB permanece pendente até avaliação do ritmo | Adiamento aprovado; não é fórmula; sem código |
| [D-162](D-162-r62-q1-trajeto-referencia-agi-mediana-jogaveis.md) | Combate / R62 confirmada | **1C** — Referência AGI do trajeto por mediana das espécies jogáveis, valor sujeito à validação antes de implementar; supera D-160 | Vigente; sem número nem código |
| [D-163](D-163-r62-q2-atb-tempo-inverso-agi.md) | Combate / R62 confirmada | **2A** — Tempo natural de ATB inversamente proporcional à AGI efetiva | Vigente; referência numérica ainda pendente |
| [D-164](D-164-r62-q3-piso-agi-um-na-regeneracao-atb.md) | Combate / R62 confirmada | **3B** — Usar AGI mínima 1 exclusivamente no cálculo de regeneração ATB, sem mudar atributo | Vigente; sem código |
| [D-165](D-165-r62-q4-sem-windup-calculo-entrada-travel.md) | Combate / R62 confirmada | **4A** — Sem WINDUP, duração do trajeto calculada ao entrar em TRAVEL, em vez de marco genérico da D-157 | Vigente; sem código |
| [D-166](D-166-r62-q5-desempate-aleatorio-reproduzivel.md) | Combate / R62 confirmada | **5A** — Sorteio reproduzível entre alvos igualmente próximos no retarget, em vez de desempate por ID da D-158 | Vigente; sem código |


| [D-167](D-167-r63-q1-mediana-todas-especies-controlaveis.md) | AGI / R63 | Q1B: mediana inclui todas as espécies diretamente controláveis pelo jogador, inclusive evoluções elegíveis | Aprovada; sem amostra calculada nem código |
| [D-168](D-168-r63-q2-agi-base-nivel-comum-sem-modificadores.md) | AGI / R63 | Q2A: utilizar AGI-base por espécie em nível comum ainda a definir, sem Nature, variações ou buffs | Aprovada; nível numérico pendente; sem código |
| [D-169](D-169-r63-q3-referencia-atb-calibrar-ritmo-existente.md) | ATB / R63 | Q3A: obter referência ATB por calibração do ritmo atual e apresentar valor antes de implementar | Aprovada; calibração e valor pendentes; sem código |
| [D-170](D-170-r63-q4-agi-atualizada-a-cada-tick-regeneracao-atb.md) | ATB / R63 | Q4A: reler AGI efetiva a cada atualização da regeneração natural do ATB | Aprovada; sem código |
| [D-171](D-171-r63-q5-tolerancia-empate-distancia-001-arena.md) | Combate / R63 | Q5B: tolerância inclusiva de 0,01 unidade da arena para empate entre alvos mais próximos no sorteio reproduzível | Aprovada; sem código |

| [D-172](D-172-r64-q1-nivel-50-mediana-agi.md) | AGI / R64 | Q1C: comparar AGI-base de todas as espécies elegíveis no nível 50 | Aprovada; sem mediana calculada nem código |
| [D-173](D-173-r64-q2-mediana-par-media-dois-centrais.md) | AGI / R64 | Q2A: mediana par = média aritmética dos dois valores centrais ordenados | Aprovada; arredondamento e valor efetivo pendentes |
| [D-174](D-174-r64-q3-especies-controlaveis-planejadas-documentadas.md) | AGI / R64 | Q3B: espécies previstas oficialmente na documentação vigente para controle direto entram na mediana mesmo não implementadas | Aprovada; sem lista inventada nem código |
| [D-175](D-175-r64-q4-calibracao-atb-intervalos-3a5-e-0a5.md) | ATB / R64 | Q4C: medir regeneração natural ATB nos intervalos 3→5 e 0→5 blocos e comparar com ritmo atual | Aprovada; medições e referência numérica pendentes |
| [D-176](D-176-r64-q5-distancia-horizontal-plano-arena.md) | Combate / R64 | Q5B: proximidade do retarget calculada pela distância horizontal na arena, ignorando diferença de altura | Aprovada; origem geométrica pendente |

| [D-177](D-177-r65-q1-formas-alternativas-agi-propria-distinta.md) | AGI / R65 | Q1C: formas alternativas só entram separadamente quando controláveis e com AGI-base própria distinta | Aprovada; sem amostra calculada ou código |
| [D-178](D-178-r65-q2-nao-finalizar-mediana-sem-dados-completos.md) | AGI / R65 | Q2A: não finalizar mediana enquanto faltar AGI-base verificável no nível 50 para qualquer espécie elegível | Aprovada; sem mediana validada |
| [D-179](D-179-r65-q3-mediana-fracionaria-exata-sem-arredondar.md) | AGI / R65 | Q3A: preservar valor fracionário exato da mediana, sem arredondamento | Aprovada; resultado real pendente |
| [D-180](D-180-r65-q4-atb-medicao-controlada-sem-interferencias.md) | ATB / R65 | Q4A: medir 3→5 e 0→5 em condições controladas, regeneração natural ativa, sem buffs, ações, ganhos instantâneos ou pausas | Aprovada; medições não executadas |
| [D-181](D-181-r65-q5-distancia-posicoes-logicas-plano-horizontal.md) | Combate / R65 | Q5A: medir distância horizontal entre posições lógicas de referência dos combatentes | Aprovada; sem implementação |

| [D-182](D-182-r66-q1-formas-um-valor-distinto-agi-por-especie.md) | AGI / R66 | Q1A: uma observação por valor distinto de AGI-base dentro de cada espécie, sem duplicar formas iguais | Aprovada; sem mediana calculada |
| [D-183](D-183-r66-q2-agi-nivel50-por-formula-oficial-verificavel.md) | AGI / R66 | Q2B: aceitar AGI-base nível 50 derivada de fórmula oficialmente aprovada e verificável com entradas documentadas; sem fórmula, pendente | Aprovada; nenhuma fórmula nova |
| [D-184](D-184-r66-q3-atb-perfis-velocidade-baixa-media-alta.md) | ATB / R66 | Q3B: medir representantes reais de velocidade baixa, intermediária e alta do código, em condições controladas | Aprovada; perfis/medições pendentes |
| [D-185](D-185-r66-q4-atb-cinco-medicoes-mediana-por-intervalo.md) | ATB / R66 | Q4B: cinco medições por intervalo e combatente, consolidar pela mediana dos tempos | Aprovada; medições não executadas |
| [D-186](D-186-r66-q5-fluxo-rng-exclusivo-desempate-retarget.md) | Combate / R66 | Q5A: fluxo de RNG reproduzível exclusivo dos desempates de retarget, separado dos demais sorteios | Aprovada; seed/algoritmo pendentes |

| [D-187](D-187-r67-q1-seed-propria-retarget-inicio-combate.md) | Combate / R67 | Q1B: gerar seed própria do RNG de retarget ao iniciar combate e registrar para reprodução | Aprovada; não implementada |
| [D-188](D-188-r67-q2-ordenacao-candidatos-id-estavel-antes-rng.md) | Combate / R67 | Q2A: ordenar candidatos empatados pelo ID estável de combatente antes de sortear; sem escolha fixa por ID | Aprovada; não implementada |
| [D-189](D-189-r67-q3-rng-so-consumir-em-empate-real.md) | Combate / R67 | Q3A: consumir RNG exclusivo somente com pelo menos dois candidatos empatados elegíveis | Aprovada; não implementada |
| [D-190](D-190-r67-q4-seis-medianas-atb-antes-conversao-agi.md) | ATB / R67 | Q4A: apresentar seis medianas separadas; não definir referência AGI/ATB sem conversão verificável de velocidade atual em AGI | Aprovada; dados/conversão pendentes |
| [D-191](D-191-r67-q5-tempo-simulado-real-medições-atb-separados.md) | ATB / R67 | Q5C: registrar tempos simulado e real em separado em cada medição, para diagnosticar discrepâncias | Aprovada; medições não realizadas |

| [D-192](D-192-r68-q1-ordem-retarget-simultaneo-id-atacante.md) | Combate / R68 | Q1A: ordenar eventos simultâneos de sorteio de retarget pelo ID estável do atacante antes de consumir o RNG exclusivo | Aprovada; não implementada |
| [D-193](D-193-r68-q2-resistencia-natural-antes-def.md) | Combate / R68 | Q2A: aplicar resistência natural VIT/SPI antes do modificador dos estágios de DEF | Aprovada; não implementada |
| [D-194](D-194-r68-q3-dano-minimo-um-golpe-valido.md) | Combate / R68 | Q3A: mínimo de 1 para golpe danoso que acertou validamente, exceto imunidades e bloqueios completos | Aprovada; não implementada |
| [D-195](D-195-r68-q4-esquiva-antes-critico-status.md) | Combate / R68 | Q4A: resolver esquiva automática primeiro; se funcionar, não rolar crítico/status condicionados ao acerto | Aprovada; não implementada |

| [D-196](D-196-r69-q1-ids-unicos-estaveis-por-combate.md) | Combate / R69 | Q1A: atribuir IDs únicos no início de cada combate, por ordem estável documentada, sem renumerar durante a batalha | Aprovada; ordem concreta e implementação pendentes |
| [D-197](D-197-r69-q2-mitigacao-percentual-retornos-decrescentes-vit-spi.md) | Combate / R69 | Q2A: mitigação percentual com retornos decrescentes e mesma estrutura de curva para VIT e SPI | Aprovada; equação e coeficientes pendentes |
| [D-198](D-198-r69-q3-arredondamento-unico-final-dano.md) | Combate / R69 | Q3A: manter decimais durante modificadores, arredondar uma vez ao final e só então aplicar mínimo cabível | Aprovada; código atual divergente; sem implementação |
| [D-199](D-199-r69-q4-critico-dano-antes-status-alvo-sobrevive.md) | Combate / R69 | Q4A: após acerto, resolver crítico e dano antes do status dependente de acerto; status apenas se o alvo sobreviver | Aprovada; sem implementação |

| [D-200](D-200-r70-q1-ids-por-slots-equipe-depois-inimigos.md) | Combate / R70 | Q1A: IDs sequenciais por slots da equipe do protagonista e depois slots inimigos na composição inicial | Aprovada; não implementada |
| [D-201](D-201-r70-q2-curva-racional-vit-spi-k-positivo.md) | Combate / R70 | Q2A: mitigação VIT/SPI pela curva racional R(x)=x/(x+K), K>0, calibração posterior | Aprovada; K pendente; não implementada |
| [D-202](D-202-r70-q3-status-uma-tentativa-por-alvo-move-apos-ultimo-hit.md) | Combate / R70 | Q3A: em multi-hit, no máximo uma tentativa de status por alvo/execução, após o último impacto e se sobreviver | Aprovada; não implementada |
| [D-203](D-203-r70-q4d-odometro-descartado-jogo-principal.md) | Combate / R70 | Q4D + regra própria: odômetro de HP era teste e está descartado do jogo principal; referência antiga preservada | Aprovada; código do teste permanece no repositório |

| [D-204](D-204-r71-q1-k-unico-compartilhado-vit-spi.md) | Combate / R71 | Q1A: único valor K compartilhado por VIT e SPI na curva racional; número ainda pendente | Aprovada; K não calibrado; sem implementação |
| [D-205](D-205-r71-q2-arredondamento-metade-para-cima.md) | Combate / R71 | Q2A: em empate exato de fração 0,5, arredondar o dano final ao inteiro superior | Aprovada; não implementada |
| [D-206](D-206-r71-q3-proximo-id-sem-reuso-entradas-posteriores.md) | Combate / R71 | Q3A: novo participante após início recebe próximo ID não utilizado; sem renumerar ou reutilizar | Aprovada; não aprova reforços; sem implementação |
| [D-207](D-207-r71-q4-status-apos-ultimo-impacto-por-alvo.md) | Combate / R71 | Q4A: resolver status de cada alvo após o último impacto destinado àquele alvo | Aprovada; não implementada |

| [D-208](D-208-r72-q1-calibrar-k-por-atributo-referencia-e-mitigacao-alvo.md) | Combate / R72 | Q1A: calibrar K a partir de atributo defensivo de referência e mitigação-alvo, submetidos a aprovação futura | Aprovada; referências e K pendentes; não implementada |
| [D-209](D-209-r72-q2-mesmo-combatente-mantem-id-no-retorno.md) | Combate / R72 | Q2A: mesmo combatente conserva seu ID original se voltar à mesma batalha | Aprovada; não autoriza reentrada; não implementada |
| [D-210](D-210-r72-q3-uma-tentativa-por-status-distinto-alvo-execucao.md) | Combate / R72 | Q3A: permitir no máximo uma tentativa por status distinto declarado na ficha, por alvo e execução | Aprovada; sem novas probabilidades; não implementada |
| [D-211](D-211-r72-q4-status-apos-ultimo-impacto-efetivo-se-interrompido.md) | Combate / R72 | Q4A: se Move for interrompido após acertos válidos, usar último impacto efetivamente realizado por alvo para status elegível se sobreviver | Aprovada; não implementada |

| [D-212](D-212-r73-q1-levantar-vit-spi-reais-verificaveis-nivel50.md) | Atributos / R73 | Q1A: levantar valores reais e verificáveis de VIT/SPI no nível 50 para propor referência sujeita à aprovação posterior | Aprovada; dados e referência numérica ainda pendentes |
| [D-213](D-213-r73-q2-status-ordem-declarada-ficha-move.md) | Combate / R73 | Q2A: resolver tentativas de status distintos na ordem expressamente declarada na ficha do Move | Aprovada; não implementada |
| [D-214](D-214-r73-q3-retarget-mesmo-atacante-ordem-declaracao-indice.md) | Combate / R73 | Q3A: desempatar retarget simultâneo do mesmo atacante por ordem estável de declaração e índice estável por ocorrência | Aprovada; não implementada |
| [D-215](D-215-r73-q4-prioridade-ficha-para-status-incompativeis.md) | Combate / R73 | Q4A: usar prioridade expressa na ficha do Move para status declarados incompatíveis; sem criar incompatibilidades | Aprovada; não implementada |

| [D-216](D-216-r74-q1-lacunas-vit-spi-nivel50-sem-referencia-prematura.md) | Atributos / R74 | Q1A: registrar lacunas de VIT/SPI nível 50; não finalizar referência quantitativa sem dados necessários verificáveis | Aprovada; levantamento ainda pendente |
| [D-217](D-217-r74-q2-ficha-incompleta-sem-prioridade-incompatibilidade.md) | Combate / R74 | Q2A: ficha de Move incompleta se faltar prioridade expressa entre status declarados incompatíveis; não escolher automaticamente | Aprovada; não implementada |
| [D-218](D-218-r74-q3-indice-retarget-plano-deterministico-na-declaracao.md) | Combate / R74 | Q3A: índices de ocorrências de retarget definidos por plano determinístico ao declarar ataque e fixos até resolução | Aprovada; não implementada |
| [D-219](D-219-r74-q4-status-rng-simultaneo-por-id-do-alvo.md) | Combate / R74 | Q4A: ordenar rolagens simultâneas de status por ID estável do alvo para consumo de RNG, sem alterar simultaneidade lógica | Aprovada; não implementada |

| [D-220](D-220-r75-q1-amostra-defensiva-perfis-aprovacao.md) | Atributos / R75 | Q1A: propor amostra de espécies de defesa baixa, média e alta, com VIT/SPI nível 50 verificáveis, para aprovação da composição | Aprovada; amostra e valores concretos pendentes |
| [D-221](D-221-r75-q2-bloquear-move-prioridade-incompatibilidade-ausente.md) | Combate / R75 | Q2A: bloquear em combate Move incompleto por prioridade de incompatibilidade ausente, indicando exatamente a omissão | Aprovada; não implementada |
| [D-222](D-222-r75-q3-indices-cancelados-reservados-sem-reuso.md) | Combate / R75 | Q3A: índices cancelados permanecem reservados e os restantes não são renumerados na mesma declaração | Aprovada; não implementada |
| [D-223](D-223-r75-q4-status-mesmo-alvo-rng-id-atacante-declaracao-indice.md) | Combate / R75 | Q4A: RNG simultâneo de status para mesmo alvo: desempatar por ID do atacante, declaração e ocorrência; sem precedência lógica | Aprovada; não implementada |

> **Conciliação da Rodada 62 (2026-11-03):** D-157 a D-161 são registros históricos de outra versão das perguntas e respostas. O criador confirmou expressamente que **D-162 a D-166 são as cinco escolhas prevalentes**. Em conflito, aplicar as decisões mais recentes; notas históricas foram adicionadas aos D-157 a D-161, sem apagar o conteúdo anterior.

> **Histórico/precedência R70:** o arquivo [D-048 de HP rolante](D-048-rolling-hp-mother3-odometro.md) registra um **teste/protótipo histórico**, não uma regra vigente do jogo principal após [D-203](D-203-r70-q4d-odometro-descartado-jogo-principal.md). **Não confundir** com o outro arquivo [D-048 de recompensas AoE](D-048-r40-q8-atb-aoe-unico.md), que não foi revogado.

