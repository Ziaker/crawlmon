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
| [D-300](D-300-motion-composer-etapa-1-autorizada.md) | Motion Composer / implementação | Etapa 1 (contratos e avaliação) autorizada, isolada do combate | Etapa 1 implementada e testada |
| [D-301](D-301-motion-composer-etapa-2-autorizada.md) | Motion Composer / implementação | Etapa 2 (M01–M13) autorizada | M01–M13 implementados e testados |
| [D-302](D-302-motion-composer-etapa-2b-m16-m18.md) | Motion Composer / implementação | Etapa 2b: M16, M17 e M18 | M16–M18 implementados e testados |
| [D-303](D-303-motion-composer-etapa-3-composicao-espacial.md) | Motion Composer / implementação | Etapa 3: M14 Bifurcação e M15 Recombinação; ordem, máscaras e defasagens validadas | M14–M15 implementados e testados; Etapas 4–6 não autorizadas |
| [D-304](D-304-motion-composer-etapa-4-persistencia-temporal.md) | Motion Composer / implementação | Etapa 4: M19 Rastro temporal, M20 Pós-imagem e reconstrução determinística do histórico | M19–M20 implementados e testados; Etapas 5–6 não autorizadas |
| [D-305](D-305-motion-composer-etapa-5-laboratorio-visual.md) | Motion Composer / laboratório | Etapa 5 em fatias: laboratório visual, representações em shaders/objetos do Godot, uma mudança visual por vez com aprovação | Fatia 1 (Pontos + laboratório) entregue; aguarda aprovação; Etapa 6 não autorizada |
| [D-306](D-306-motion-composer-etapa-6-validacao.md) | Motion Composer / validação | Etapa 6: testes, inspeção visual, medir desempenho (sem limite definido) e capturas em GL Compatibility | Executada e corrigida (§33, §35); receita agora com M19; orçamento P-07 continua do criador |
| [D-307](D-307-fusao-lab-vfx-com-motion-composer.md) | VFX / Laboratório | Lab do Motion Composer passa a tocar os efeitos existentes do jogo como referência; fx_lab não é substituído | Fatias 1 (efeitos do jogo) e 2 (busca no tempo) implementadas; aguardam aprovação visual |
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

| [D-224](D-224-r76-q1-perfis-defensivos-separados-vit-spi-amostra.md) | Atributos / R76 | Q1A: classificar perfis baixos/médios/altos separadamente para VIT e SPI, incluindo defesa física, mágica e mista na proposta de amostra | Aprovada; classificação e amostra concretas pendentes |
| [D-225](D-225-r76-q2-validar-bloqueio-antes-confirmacao-sem-custos.md) | Combate / R76 | Q2A: validar Move incompleto antes da confirmação e de debitar ATB/Burst; bloqueio não consome ação nem recursos | Aprovada; não implementada |
| [D-226](D-226-r76-q3-reservar-indices-ocorrencias-condicionais-na-declaracao.md) | Combate / R76 | Q3A: prever ocorrências condicionais possíveis no plano inicial e reservar índices na declaração do ataque | Aprovada; não implementada |
| [D-227](D-227-r76-q4-rng-exclusivo-status-seed-inicio-combate-registrada.md) | Combate / R76 | Q4A: fluxo RNG próprio de status com seed criada no início do combate e registrada para reprodução, separado do retarget | Aprovada; algoritmo e formato pendentes |

| [D-228](D-228-m1-q4a-mp-adicional-moves-magicos-especiais.md) | Fichas de Moves / M1 | Q4A: MP adicional para Moves mágicos/especiais, cumulativo com ATB/Burst aplicável; custos individuais pendentes; supera exclusivamente regra sem MP da D-032 | Aprovada; M1-Q1/Q2/Q3 sem resposta material; não implementada |

| [D-229](D-229-moves-tooltip-texto-integrado-visual-fora-combate.md) | Fichas de Moves / correção de M1 | Tooltip em combate estilo LoL: custos/windup acima; descrição, dano, efeitos, condições e modificadores juntos no texto; descrição visual só fora de combate | Aprovada; modelo técnico de alvos e fórmulas pendentes; não implementada |

| [D-230](D-230-moves-tooltip-dano-cura-numericos-sem-formulas.md) | Fichas de Moves / correção numérica posterior | Mostrar valores concretos de dano/cura em pontos no texto da tooltip; não substituir por multiplicadores ou fórmulas; números de contexto não são dano-base universal | Aprovada; dano-base oficial e exibição sem contexto pendentes; não implementada |

| [D-231](D-231-r77-q1-propor-faixas-vit-spi-por-distribuicao-verificavel.md) | Atributos / R77 | Q1A: propor faixas baixo/médio/alto separadas para VIT e SPI pela distribuição verificada no nível 50, aprovando limites antes de classificar amostra | Aprovada; limites e amostra ainda não homologados |
| [D-232](D-232-r77-q2-ia-excluir-moves-incompletos-antes-selecao.md) | Combate / R77 | Q2A: excluir Moves com incompatibilidade sem prioridade da lista de candidatos da IA antes da seleção tática, sem consumir ação ou recursos | Aprovada; não implementada |
| [D-233](D-233-r77-q3-limite-maximo-explicito-ocorrencias-condicionais.md) | Combate / R77 | Q3A: Move de ocorrências condicionais variáveis exige máximo explícito para reservar índices na declaração; plano fica incompleto sem limite | Aprovada; máximos específicos pendentes |
| [D-234](D-234-r77-q4-chance-status-extrema-sem-consumir-rng.md) | Combate / R77 | Q4A: chance final de status exatamente 0% falha e 100% tem sucesso, sem consumir RNG; demais condições preservadas | Aprovada; não implementada |
| [D-235](D-235-moves-e-vfx-independentes-de-personagem-e-lado.md) | Processo / Combate / VFX | Moves e efeitos independentes de personagem, de lado e de posição (obrigatório, inclusive em protótipos) | Em vigor; regra também em `AGENTS.md` (seção 7) |

| [D-236](D-236-r78-q1-tercis-separados-vit-spi-faixas-para-aprovacao.md) | Atributos / R78 | Q1A: propor faixas baixa/média/alta por tercis das distribuições verificáveis de VIT/SPI nível 50, separadamente; cortes sujeitos à aprovação | Aprovada; valores concretos não homologados |
| [D-237](D-237-r78-q2-ia-considerar-tackle-se-sem-moves-validos.md) | Combate / IA / R78 | Q2A: sem Move válido após filtragem, IA pode considerar Tackle separadamente se elegível; caso contrário, reação pendente | Aprovada; não implementada |
| [D-238](D-238-r78-q3-bloquear-move-plano-sem-maximo-antes-custos.md) | Combate / R78 | Q3A: bloquear confirmação de Move com plano condicional sem máximo explícito; indicar omissão antes de consumir ação ou recursos | Aprovada; não implementada |
| [D-239](D-239-r78-q4-politica-explicita-status-incompativeis-moves-distintos.md) | Combate / status / R78 | Q4A: exigir política expressa e aprovada antes de resolver status incompatíveis provenientes de Moves diferentes; sem inferir prioridades isoladas | Aprovada; política concreta pendente |

| [D-240](D-240-r79-q1-igualdade-atributo-mesma-faixa-tercis.md) | Atributos / R79 | Q1A: manter espécies de mesmo valor VIT/SPI na mesma faixa do atributo, mesmo com grupos de tamanhos desiguais | Aprovada; limites numéricos pendentes |
| [D-241](D-241-r79-q2-ia-sem-opcoes-reavaliar-proxima-oportunidade.md) | Combate / IA / R79 | Q2A: sem Move válido nem Tackle elegível, IA não inicia ação nem consome recursos; reavalia na próxima oportunidade normal | Aprovada; não implementada |
| [D-242](D-242-r79-q3-ocorrencia-excedente-rejeitar-e-registrar-violacao.md) | Combate / R79 | Q3A: rejeitar ocorrência condicional que exceda máximo, registrar violação e preservar eventos válidos já resolvidos | Aprovada; não implementada |
| [D-243](D-243-r79-q4-matriz-pares-status-incompativeis-aprovacao.md) | Combate / status / R79 | Q4A: criar política em matriz explícita de prioridades por pares de status incompatíveis oriundos de Moves distintos, sujeita à aprovação | Aprovada; matriz concreta e pares pendentes |

| [D-244](D-244-m2-q1-dano-base-categoria-escalas-separadas.md) | Fichas de Moves / M2 | Q1A: separar dano-base, categoria físico/mágico e escalas STR/MAG na ficha técnica; tooltip com dano numérico calculado | Aprovada; documentação apenas; dados concretos pendentes |
| [D-245](D-245-m2-q2-windup-trajeto-velocidade-projetil-independentes.md) | Fichas de Moves / M2 | Q2A: windup, tempo-base de deslocamento e velocidade de projétil separados; usar só modificadores aprovados | Aprovada; documentação apenas; dados concretos pendentes |
| [D-246](D-246-m2-q3-selecao-faccao-abrangencia-alvos-separadas.md) | Fichas de Moves / M2 | Q3A: seleção Self/One/Two/All, facção ally/enemy/both e abrangência condicional dos efeitos como dimensões distintas | Aprovada; documentação apenas; dados concretos pendentes |
| [D-247](D-247-m2-q4-cura-buffs-status-dispel-efeitos-individuais.md) | Fichas de Moves / M2 | Q4A: cura, buffs/debuffs, status e Dispel como efeitos individuais com magnitude, condição, chance, duração e ordem aplicáveis | Aprovada; documentação apenas; dados concretos pendentes |
| [D-248](D-248-m2-q5-visual-preparo-emissao-impacto-dissipacao-ficha-fora-combate.md) | Fichas de Moves / M2 | Q5A: descrição visual somente fora do combate, separada por preparação, movimento/emissão, impacto e dissipação quando aplicável | Aprovada; documentação apenas; dados concretos pendentes |
| [D-249](D-249-m2-q6-dispel-lista-explicita-removiveis-excecoes.md) | Fichas de Moves / M2 | Q6A: Move com Dispel deve listar expressamente efeitos removíveis e exceções aplicáveis | Aprovada; documentação apenas; dados concretos pendentes |

| [D-250](D-250-r80-q1-valor-igual-limite-tercil-faixa-superior.md) | Atributos / R80 | Q1A: VIT/SPI exatamente igual a limite aprovado entra na faixa superior; todos os empatados juntos | Aprovada; limites quantitativos pendentes |
| [D-251](D-251-r80-q2-ia-filtrar-moves-sem-maximo-condicional.md) | Combate / IA / R80 | Q2A: filtrar também Moves sem máximo condicional obrigatório antes da escolha tática, sem consumir recursos/ação | Aprovada; não implementada |
| [D-252](D-252-r80-q3-continuar-eventos-validos-apos-excedente.md) | Combate / R80 | Q3A: rejeitar e registrar só ocorrência excedente, continuar eventos futuros validamente previstos e preservar anteriores | Aprovada; não implementada |
| [D-253](D-253-r80-q4-matriz-incompatibilidade-simultaneos-e-ativos.md) | Combate / status / R80 | Q4A: matriz aprovada por pares de status vale para conflitos simultâneos e para status já ativo versus novo de Move distinto | Aprovada; entradas e prioridades concretas pendentes |

| [D-254](D-254-r81-q1-uma-especie-por-observacao-vit-spi-nivel50.md) | Atributos / R81 | Q1A: uma observação por espécie nas distribuições VIT/SPI nível 50, com valor oficial de referência e desvios individuais ±3 separados | Aprovada; valores e amostra pendentes |
| [D-255](D-255-r81-q2-identificar-todas-omissoes-de-bloqueio-juntas.md) | Combate / R81 | Q2A: identificar na mesma validação todas as omissões detectadas de causas de bloqueio aprovadas, sem consumo de ação ou recursos | Aprovada; não implementada |
| [D-256](D-256-r81-q3-log-estruturado-violacao-plano-identificadores-estaveis.md) | Combate / R81 | Q3A: registrar violação estruturada com Move, atacante, declaração, máximo aprovado e ocorrência excedente, todos rastreáveis por identificadores estáveis | Aprovada; mecanismo de log pendente |
| [D-257](D-257-r81-q4-eliminar-status-perdedor-sem-restauracao.md) | Combate / status / R81 | Q4A: eliminar status de menor prioridade por matriz aprovada; remover se ativo ou bloquear aplicação nova, sem restaurar após o vencedor terminar | Aprovada; matriz concreta pendente |

| [D-258](D-258-m3-q1-formula-dano-base-escala-vezes-potencia.md) | Fichas de Moves / M3 | Q1A: aplicar (base + coeficiente STR/MAG × atributo) × potência antes de outros modificadores | Aprovada; documentação apenas; implementação pendente |
| [D-259](D-259-m3-q2-sem-previa-dano-na-selecao-alvos.md) | Fichas de Moves / M3 | Q2D: não existe nem deve existir prévia de dano durante a seleção de alvos; tooltip numérica D-230 preservada | Aprovada; documentação apenas; implementação pendente |
| [D-260](D-260-m3-q3-efeitos-herdam-selecao-faccao-salvo-excecao.md) | Fichas de Moves / M3 | Q3A: efeitos herdam seleção e facção padrão, salvo abrangência ou condição diferente expressamente declarada | Aprovada; documentação apenas; implementação pendente |
| [D-261](D-261-m3-q4-agi-nao-altera-velocidade-projeteis-sem-excecao.md) | Fichas de Moves / M3 | Q4A: AGI não altera automaticamente velocidade de projétil; velocidade própria do Move, exceções só expressas | Aprovada; documentação apenas; implementação pendente |
| [D-262](D-262-m3-q5-dispel-remove-todos-efeitos-elegiveis.md) | Fichas de Moves / M3 | Q5A: Dispel remove todos os efeitos elegíveis declarados na ficha, respeitando exceções | Aprovada; documentação apenas; implementação pendente |
| [D-263](D-263-m3-q6-todos-moves-exceto-tackle-consomem-mp.md) | Fichas de Moves / M3 | Q6D: todo Move exceto Tackle consome MP; amplia a D-228 histórica, valores por Move pendentes | Aprovada; documentação apenas; implementação pendente |

| [D-264](D-264-r82-q1-universo-oficial-especies-vit-spi-verificaveis.md) | Atributos / R82 | Q1A: usar todas as espécies do universo oficial com VIT/SPI verificáveis no nível 50, uma observação por espécie, registrar lacunas e não homologar cortes sem representatividade | Aprovada; universo e cobertura verificáveis pendentes |
| [D-265](D-265-r82-q2-lista-textual-compacta-omissoes-selecao-aberta.md) | Combate / UX / R82 | Q2A: lista textual compacta das omissões detectadas ao tentar confirmar Move; manter seleção aberta e não consumir recursos/ação | Aprovada; não implementada |
| [D-266](D-266-r82-q3-id-diagnostico-declaracao-sequencia-excedentes.md) | Combate / R82 | Q3A: ID diagnóstico de excedentes separado de índices válidos, derivado da declaração e de sequência determinística de solicitações rejeitadas | Aprovada; mecanismo técnico pendente |
| [D-267](D-267-r82-q4-elegibilidade-chance-antes-matriz-status.md) | Combate / status / R82 | Q4A: resolver elegibilidade e chance de status primeiro; só após sucesso efetivo consultar matriz aprovada e eliminar perdedor | Aprovada; matriz concreta pendente |
| [D-268](D-268-hud-visual-buffs-debuffs-aprovado.md) | HUD / visual | Referência aprovada: peças diagonais coloridas para buffs/debuffs, cartões brancos, arena visível; protótipo HTML, PNG e DOCX | Aprovada; jogo não alterado |
| [D-269](D-269-r83-q1-relatorio-cobertura-vit-spi-separados-para-aprovacao.md) | Atributos / R83 | Q1A: preparar relatório verificável separado de cobertura VIT/SPI nível 50 por espécie e lacuna; aprovação da suficiência antes de homologar tercis | Aprovada; relatório e cobertura pendentes |
| [D-270](D-270-r83-q2-burst-paga-integralmente-atb-mp.md) | Combate / recursos / R83 | Q2B: Burst paga ação inteira, incluindo ATB e MP; exceção expressa ao débito de MP previsto na D-263 quando Burst é usado | Aprovada; não implementada; precedência MP/Burst conciliada |
| [D-271](D-271-r83-q3-excedentes-simultaneos-ordem-gerador-alvo.md) | Combate / eventos / R83 | Q3A: ordenar solicitações excedentes simultâneas por índice estável do gerador, depois ID do alvo, e numerar diagnósticos nessa ordem | Aprovada; não implementada |
| [D-272](D-272-r83-q4-matriz-ausente-suspender-conflito-preservar-independentes.md) | Combate / status / R83 | Q4A: par incompatível sem prioridade aprovada: não resolver aplicação conflitante nem eliminar existente; registrar pendência e preservar efeitos independentes | Aprovada; pares e matriz concretos pendentes |

> **Conciliação da Rodada 62 (2026-11-03):** D-157 a D-161 são registros históricos de outra versão das perguntas e respostas. O criador confirmou expressamente que **D-162 a D-166 são as cinco escolhas prevalentes**. Em conflito, aplicar as decisões mais recentes; notas históricas foram adicionadas aos D-157 a D-161, sem apagar o conteúdo anterior.

> **Histórico/precedência R70:** o arquivo [D-048 de HP rolante](D-048-rolling-hp-mother3-odometro.md) registra um **teste/protótipo histórico**, não uma regra vigente do jogo principal após [D-203](D-203-r70-q4d-odometro-descartado-jogo-principal.md). **Nao confundir** com o outro arquivo [D-048 de recompensas AoE](D-048-r40-q8-atb-aoe-unico.md), que não foi revogado.

## Decisões do overworld (2026-11-05)

| ID | Área | Decisão | Estado |
|---|---|---|---|
| [D-273](D-273-r84-q1-prototipo-cinco-andares-campanha-com-chefes.md) | Exploração / R84 reformulada | Q1C: protótipo passa direto à nova expedição após cinco andares; jogo completo preserva chefes obrigatórios para conclusão das dungeons de campanha | Aprovada; duas regras de escopo conciliadas; sem implementação |
| [D-274](D-274-r84-q2-recrutamento-eventos-e-batalhas-especiais.md) | Exploração / R84 reformulada | Q2C: recrutamento por eventos/missões e candidatos após encontros ou batalhas especiais, sempre voluntário | Aprovada; condições concretas pendentes |
| [D-275](D-275-r84-q3-biblioteca-moves-preparacao-restrita.md) | Progressão / Moves / R84 reformulada | Q3C: preservar biblioteca de todos os Moves aprendidos; equipar até oito, alterando equipamento somente em locais seguros ou entre expedições | Aprovada; locais específicos pendentes |
| [D-276](D-276-r84-q4-afinidades-null-repel-drain-por-especie.md) | Combate / afinidades / R84 reformulada | Q4A: além de fraqueza/resistência, prever Null, Repel e Drain como afinidades possíveis por espécie, segundo SMT | Aprovada; espécies e mecânicas específicas pendentes |
| [D-278](D-278-restaurar-overworld-e-ajustar-paleta.md) | Exploração / visual | Restauração do overworld original e paleta; a D-313 relaxa a restrição de “somente cores” | Direção vigente |
| [D-309](D-309-aliados-em-fila-no-overworld.md) | Exploração | Aliados ativos seguem em fila | Não implementado |
| [D-310](D-310-niveis-de-ameaca-dos-inimigos-no-overworld.md) | Exploração / IA | Quatro níveis de ameaça (medroso, fraco, valente, perigoso), com tamanho e ícone; relativo ao nível | Não implementado |
| [D-311](D-311-pontos-de-descanso-por-andar.md) | Exploração | Descanso cura todo HP/MP; 2 por andar (raramente 3); uso único | Não implementado |
| [D-312](D-312-biomas-floresta-fortaleza-caverna.md) | Exploração / visual | Biomas: floresta, fortaleza (atual), caverna | Não implementado |
| [D-313](D-313-overworld-tiles-refeitos-e-efeitos-visuais.md) | Exploração / visual | Tiles podem ser refeitos; poeira, tochas, NPC olhando e sprites de Pokémon (inimigos e aliados); sem sombra; sem novos modelos | Não implementado |
| [D-314](D-314-fila-de-aliados-rastro-exato-sem-atravessar.md) | Exploração | Fila no rastro exato; espera 1 s e reposiciona; atravessa inimigos e o contato inicia batalha | Não implementado |
| [D-315](D-315-niveis-de-ameaca-referencia-escala-e-distancias.md) | Exploração / IA | Ameaça pela soma do grupo vs soma da equipe; nível = média +1..+4; 3/6/9 tiles e 40/70/110/150 px/s; faixas −40%/−10%/+30%; ícones a desenhar | Não implementado |
| [D-316](D-316-descanso-ao-pisar-e-expedicao-de-5-andares.md) | Exploração | Descanso ao pisar cura a equipe ativa; 3º ponto em 10%; 5 andares e nova expedição completa no fim | Não implementado |
| [D-317](D-317-bioma-a-cada-5-andares.md) | Exploração / visual | Bioma sorteado por dungeon; o 5º andar usa outro bioma e a nova dungeon continua com ele | Não implementado |
| [D-318](D-318-f6-eventos-primeiro.md) | Exploração / conteúdo | F6 começa por eventos; ordem restante pendente | Não implementado |
| [D-319](D-319-f3-so-no-overworld-batalha-continua-gible.md) | Exploração / escopo | F3 só no overworld; batalha 3D continua Gible fixo | Não implementado |
| [D-320](D-320-publicacao-de-docs-autorizada.md) | Processo / Git | Commit + push só de docs, por worktree limpo do `origin/main` | Pendente de execução |
| [D-321](D-321-inimigos-tambem-andam-em-grupo.md) | Exploração / IA | Inimigos em grupo solto (máx. 3); soma define a ameaça do grupo; líder derrotado → próximo vira líder | Não implementado |

| [D-322](D-322-battlelog-overhaul-opcao-c-retratos.md) | HUD / BattleLog / visual | Opção C aprovada para o log no alto à direita: faixas claras diagonais e retrato/ícone do personagem em cada evento, preservando D-268 | Visual aprovado; não implementado; imagem e DOCX binários ainda sem publicação verificada no GitHub |

| [D-323](D-323-bubble-shield-ficha-inicial.md) | Moves / escudos | Bubble Shield: Water, Status, ALL ALLIES, 3 ATB, wind-up 0,7 s, proteção 25 + MAG do usuário por aliado, 8 s | Aprovado como design; MP e tipagem da reserva pendentes; não implementado |
| [D-324](D-324-escudos-reaplicacao-empilhamento-prioridade.md) | Combate / escudos | Mesmo Move reseta escudo salvo empilhamento expresso; escudos de naturezas distintas podem coexistir; prioridade escudo tipado > sem tipo > HP | Aprovado; critérios de tipagem/ordem dentro da mesma camada pendentes; não implementado |
| [D-325](D-325-escudos-interrupcao-e-dano-periodico.md) | Combate / escudos | Anti-interrupção somente se descrita no efeito; Burn e Poison também consomem escudos elegíveis | Aprovado; interação exata com aplicação de status pendente; não implementado |
| [D-326](D-326-brick-break-quebra-escudos.md) | Moves / escudos | Brick Break também quebra escudos, inclusive Bubble Shield, sem inferir quantas reservas ou condições adicionais | Aprovado; abrangência operacional pendente; não implementado |
| [D-327](D-327-r85-q1-afinidades-reveladas-por-teste-registro-especie.md) | Combate / R85 | Q1A: afinidades desconhecidas reveladas mediante teste e registradas para a espécie | Aprovada; sem implementação |
| [D-328](D-328-r85-q2-chefes-ia-tatica-cooperacao-variavel.md) | Combate / chefes / R85 | Q2C: combinar IA estratégica e cooperação variável por chefe, sem exigir Moves exclusivos de personagem | Aprovada; padrões pendentes |
| [D-329](D-329-r85-q3-troca-equipe-reserva-locais-seguros-entre-expedicoes.md) | Exploração / equipe / R85 | Q3A: troca ativa/reserva apenas em locais seguros de preparação e entre expedições, substituindo regra provisória de troca livre | Aprovada; locais pendentes |
| [D-330](D-330-r85-q4-campanha-narrativa-dungeons-extras-exploracao.md) | Campanha / R85 | Q4C: progressão principal narrativa e dungeons adicionais liberadas por conquistas de exploração | Aprovada; conteúdo pendente |
| [D-331](D-331-r83b-q1-ficha-referencia-por-especie-forma-vinculada.md) | Fichas de personagens / R83B | Q1A: uma ficha de referência por espécie ou forma distinta, vinculada a formas/evoluções, sem repetir dados compartilhados | Aprovada; fichas concretas pendentes |
| [D-332](D-332-r83b-q2-tabela-aprendizado-moves-por-personagem.md) | Fichas de personagens / R83B | Q2A: ficha lista Moves que pode aprender, fontes e requisitos conhecidos, separada da biblioteca individual aprendida | Aprovada; dados por espécie pendentes |
| [D-333](D-333-r83b-q3-ficha-unica-move-com-blocos-de-variantes.md) | Fichas de Moves / R83B | Q3A: uma ficha por Move com blocos explícitos de variantes, detalhando somente diferenças efetivas | Aprovada; sem alterações de Moves |
| [D-334](D-334-r83b-q4-origem-vfx-relativa-modelo-adaptacao-anatomica.md) | Fichas de Moves / R83B | Q4A: especificar origem visual relativa ao modelo, referências necessárias e adaptações anatômicas independentes de espécie | Aprovada; implementação pendente |
| [D-335](D-335-r84b-q1-status-por-campo-nas-fichas-de-personagens.md) | Fichas de personagens / R84B | Q1A: diferenciar em cada campo dados aprovados/verificados, propostas e pendências, com fontes quando conhecidas | Aprovada; fichas concretas pendentes |
| [D-336](D-336-r84b-q2-fontes-de-aprendizado-agrupadas-por-move.md) | Fichas de personagens / R84B | Q2A: registrar todas as fontes de aprendizado na entrada do Move, cada uma com requisitos conhecidos | Aprovada; fontes concretas pendentes |
| [D-337](D-337-r84b-q3-gatilhos-e-referencias-temporais-por-fase-visual.md) | Fichas de Moves / R84B | Q3A: especificar gatilhos, marcos temporais e durações por fase visual quando aprovados, deixando desconhecidos pendentes | Aprovada; dados individuais pendentes |
| [D-338](D-338-r84b-q4-referencias-anatomicas-alternativas-por-move.md) | Fichas de Moves / R84B | Q4A: registrar referência anatômica principal e alternativas genéricas relativas ao corpo, individualmente por Move | Aprovada; alternativas concretas pendentes |
