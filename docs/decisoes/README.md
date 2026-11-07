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
| [D-032](D-032-balanceamento-moves-ingles-e-status.md) | Combate | Nomes em inglês, rebalanceamento de moves, invulnerabilidade e novos status | Implementado |
| [D-033](D-033-overworld-mais-claro-e-consumiveis-no-mapa.md) | Exploração | Overworld mais claro, já visitado 100% iluminado e Poções no mapa (2–4 por andar, coleta automática, persistem) | Implementado |
| [D-034](D-034-teleport-sumir-apos-windup-e-sem-deslocamento.md) | Combate | Teleport: sumir após o wind-up, sem deslocamento e reaparecer na origem | Implementado |
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
| [D-048](D-048-rolling-hp-mother3-odometro.md) | Combate / UI / Game Feel / Configurações | Mecânica de Vida Rolante (Rolling HP / Odômetro estilo Mother 3 / EarthBound) | **Arquivado por D-347** (código em `scripts/legacy/`; D-203 já o excluía do jogo principal) |
| [D-049](D-049-knockback-final-e-screen-shake-ko.md) | Combate / Visual / Game Feel / Câmera | Impacto de K.O.: Lançamento Balístico do Inimigo, Shake Épico e VFX de Derrota | Implementado |
| [D-157](D-157-retorno-hitshake-e-correcao-lancamento-ko.md) | Combate / Game Feel / Câmera / VFX | Retorno do Hit Shake nos Ataques (menos intenso que KO) e Correção do Lançamento de K.O. à Distância | Implementado |
| [D-158](D-158-buffs-escalamento-tamanho-velocidade-e-defesa.md) | Visual / Combate / Game Feel / Shaders | Efeitos Visuais Físicos de Buffs/Debuffs: Tamanho (ATK), Velocidade de Animação (SPD) e Armadura (DEF) | Implementado |
| [D-159](D-159-limite-de-buffs-5-e-calculo-fracionario.md) | Combate / Atributos / Balanceamento / Visual | Limite de Buffs/Debuffs Ampliado para ±5, Acumulação Aditiva Unificada, Cálculo Fracionário e Teto Visual em 3 Stacks | Implementado |
| [D-160](D-160-lancamento-ko-sempre-para-tras.md) | Combate / Visual / Game Feel | Lançamento de K.O. sempre para longe de onde os jogadores estão | Implementado |
| [D-161](D-161-buffer-de-selecao-de-move.md) | Combate / Menu | Seleção de Move na pausa de status e buffer de seleção (uma vaga, paga ao executar; começa após o retorno) | Implementado |
| [D-162](D-162-camera-lenta-fight-2s.md) | Combate / UI / Game Feel | Câmera lenta de decisão: 2 s no Fight; Itens continua com 3 s | Implementado |
| [D-163](D-163-windup-em-loop.md) | Combate / Animação | A animação de wind-up fica em loop até o fim do preparo | Implementado |
| [D-164](D-164-contra-ataque-em-todo-desvio-perfeito.md) | Combate | Todo desvio perfeito dá contra-ataque de wind-up instantâneo | Implementado |
| [D-165](D-165-spd-vale-para-todos-os-clipes.md) | Visual / Combate / Animação | A velocidade de animação por SPD vale para todos os clipes | Em vigor |
| [D-166](D-166-ko-encolhe-e-some-no-ar.md) | Combate / Visual / Game Feel | O inimigo lançado encolhe e some ainda no ar | Em vigor |
| [D-167](D-167-correcoes-da-auditoria-buffs.md) | Combate / Visual | Correções da auditoria de buffs (D-158/D-159), incluindo a rachadura do `-def` | Implementado |
| [D-168](D-168-ia-estrategica-e-desvios.md) | Combate / IA | IA estratégica: variedade de Moves, desvios e reserva de ATB | Implementado; pesos delegados (D-116) |
| [D-169](D-169-karate-chop-e-dragon-claw-mais-lentos.md) | Combate / Animação | Karate Chop e Dragon Claw correm mais devagar (0,45 s) | Implementado |
| [D-170](D-170-vfx-dos-4-moves-do-abra-prototipo-v9.md) | Visual / VFX | VFX dos 4 moves do Abra conforme o protótipo v9 (só desenho; prisma do Teleport trocado por speedlines roxas) | Implementado (4 moves; Teleport com speedlines roxas no lugar do prisma) |
| [D-269](D-269-sem-escala-1-100-e-niveis-baixos-sem-valores-altos.md) | Personagens / atributos | Sem escala 1–100; sem valores exorbitantes em níveis baixos; o "limite de 10" NÃO é regra | Registrada; sem implementação (ambiguidades abertas) |
| [D-270](D-270-atributos-convertidos-dos-valores-originais-pelo-assistente.md) | Personagens / atributos | Atributos vêm da conversão dos valores originais, criada pelo assistente | Registrada; proposta em `docs/PROPOSTA_ATRIBUTOS_NIVEL_XP.md` (inválida: refazer); sem implementação |
| [D-271](D-271-nature-valores-flat-sem-porcentagem.md) | Personagens / Natures | Nature em valores flat de −3 a +3, soma 0, de 2 a 6 atributos; só atributos e formas de agir em combate, sem crescimento | Registrada; **Natures adiadas** pelo criador (precisam de mais planejamento); sem implementação |
| [D-272](D-272-guard-escudo-de-1-atb.md) | Combate / HUD | Guard: ação de 1 ATB, 2 s, escudo azul, hotkey Shift, quebrado por Brick Break; hit stun +0,30 s global | Implementado; aguardando aprovação visual |
| [D-273](D-273-barreira-hexagonal-reservada-para-protect.md) | Combate / VFX | A barreira em cúpula hexagonal fica guardada para um futuro Move Protect | Preservada (`fx_barrier.gd`), sem uso |
| [D-274](D-274-proposta-compositor-de-efeitos-em-camadas-pendente.md) | VFX / Laboratório | Proposta: evoluir o laboratório para um compositor de efeitos em camadas (7 itens; 4 receitas de referência) | PROPOSTA registrada, não aprovada, sem implementação |
| [D-308](D-308-videos-fases-e-qualidade-dos-efeitos-de-elemento.md) | VFX / Processo | Efeitos de elemento: sempre vídeo (normal e espelhado), 4 fases (Wind-up, Release, Trajeto, Impacto), qualidade real do Godot, melhorar o Motion Composer | Regras registradas; receitas V1 reprovadas |
| [D-275](D-275-overworld-2d-referencia-arena.md) | Exploração / visual | Overworld 2D com linguagem visual coerente e referência no combate 3D | Direção definida |
| [D-276](D-276-mystery-dungeon-referencia-overworld.md) | Exploração / visual | Pokémon Mystery Dungeon como referência para refazer os tiles e retirar os sinais de “+” do chão | Direção definida |
| [D-277](D-277-ruinas-suspensas-overworld.md) | Exploração / visual | Ruínas suspensas em 2D e correção da folga de passagem | Direção aprovada |
| [D-278](D-278-restaurar-overworld-e-ajustar-paleta.md) | Exploração / visual | Restauração do overworld original com alteração apenas de paleta | Direção vigente |
| [D-230](D-230-motion-composer-etapa-1-autorizada.md) | Motion Composer / implementação | Etapa 1 (contratos e avaliação) autorizada, isolada do combate; usar skills de Godot | Etapa 1 implementada e testada; Etapas 2–6 não autorizadas |
| [D-231](D-231-motion-composer-etapa-2-autorizada.md) | Motion Composer / implementação | Etapa 2 (M01–M13) autorizada; M16–M18 sem etapa definida | M01–M13 implementados e testados; M16–M18 pendentes |
| [D-232](D-232-motion-composer-etapa-2b-m16-m18.md) | Motion Composer / implementação | Etapa 2b: M16, M17 e M18 | M16–M18 implementados e testados; Etapas 3–6 não autorizadas |
| [D-233](D-233-motion-composer-etapa-3-composicao-espacial.md) | Motion Composer / implementação | Etapa 3: M14 Bifurcação e M15 Recombinação; ordem, máscaras e defasagens validadas | M14–M15 implementados e testados; Etapas 4–6 não autorizadas |

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
| [D-235](D-235-moves-e-vfx-independentes-de-personagem-e-lado.md) | Processo / Combate / VFX | Moves e efeitos independentes de personagem, de lado e de posição (obrigatório, inclusive em protótipos) | Em vigor; regra também em `AGENTS.md` (seção 7) |
| [D-241](D-241-mach-punch-acerta-0-20-s-depois-de-chegar.md) | Combate / animação | Mach Punch acerta 0,20 s depois de chegar ao alvo, com o clipe de ataque acelerado; Karate Chop e Brick Break seguem em 0,87 s | Implementado |
| [D-240](D-240-hud-sem-textos-sombra-basica-e-aneis-de-windup.md) | HUD / Visual | Sem logo nem linha de título nos cartões, badges acima do cartão, sombra preta básica no lugar do anel ciano, anéis de wind-up mais baixos e centrados | Implementado |
| [D-239](D-239-burn-hud-real.md) | HUD / combate | HUD real do Burn: fundo dos cartões chamuscado, barra de vida intacta com trecho pendente, etiqueta BURN e "-2" | Implementado; sem Motion Composer no jogo |
| [D-238](D-238-burn-regras-e-aplicacao-pelo-fire-bullet.md) | Combate | Burn: 1º tick 1 s depois, reaplicação renova os 4 s, o tick pode matar (animação de morte, sem lançamento), aplicado quando o Fire Bullet interrompe; sem HUD/3D | Registrada; implementação em andamento |
| [D-237](D-237-burn-opcao-2-barra-de-vida-em-chamas.md) | Combate / HUD / VFX | Burn opção 2 (dano pendente no HUD) e barra de vida em chamas para jogador e aliado (laranja escuro pulsante); só protótipo em vídeo | Registrada; só protótipo, sem mudança no jogo |
| [D-236](D-236-moves-fire-bullet-e-splitter-flames.md) | Combate / VFX | Moves de Fogo Fire Bullet e Splitter Flames: só visual + Skill básico, dois alvos incluídos, só na sala de VFX; pendências da ficha em aberto | Registrada; implementação em etapas |

- [D-331 — Atelier HTML: Quarks, detalhe moderado e sincronia](D-331-atelier-html-quarks-e-sincronia.md) — HTML testado; aprovação artística pendente.
| [D-279](D-279-choque-de-corridas-pulinho-e-golpes-simultaneos.md) | Combate / trajeto | Choque de corridas: pulinho para trás e golpes ao mesmo tempo; o mais rápido interrompe; alvos distintos cancelam e voltam | Implementado (valores escolhidos pelo assistente; ver o arquivo) |
| [D-280](D-280-perseguicao-do-visual-e-strike-fixo.md) | Combate / trajeto / visual | O atacante persegue o ponto desenhado do alvo (lógica inalterada); STRIKE com trajetória fixa (restaura D-054) | STRIKE fixo implementado; mira no ponto desenhado pendente |
| [D-281](D-281-espera-de-0-7-s-antes-do-retorno-no-tackle.md) | Combate / retorno | Espera total de 0,7 s no alvo antes do pulo de volta, só nos 5 Moves melee de wind-up 1,5 s | Implementado |
| [D-282](D-282-estado-de-prisao-no-idle-pos-golpe.md) | Combate / retorno | Estado de prisão: o idle pós-golpe (melee) não pula enquanto outro ataque melee estiver no golpe contra ele; solta no impacto, desvio ou Guard; Evade/Guard manuais permitidos | Implementado |

| [D-309](D-309-aliados-em-fila-no-overworld.md) | Exploração | Aliados seguem em fila | Não implementado |
| [D-310](D-310-niveis-de-ameaca-dos-inimigos-no-overworld.md) | Exploração / IA | 4 níveis de ameaça (medroso, fraco, valente, perigoso) com tamanho e ícone; relativo ao nível | Não implementado |
| [D-311](D-311-pontos-de-descanso-por-andar.md) | Exploração | Descanso cura todo HP/MP; 2 por andar (raramente 3); uso único | Não implementado |
| [D-312](D-312-biomas-floresta-fortaleza-caverna.md) | Exploração / visual | Biomas: floresta, fortaleza (atual), caverna | Não implementado |
| [D-283](D-283-evade-so-perfeito-nos-ultimos-0-25-s.md) | Combate / Evade | O Evade só existe como desvio perfeito, nos últimos 0,25 s do golpe; antes disso o botão não tem efeito; a IA desvia dentro da janela | Implementado |
| [D-284](D-284-contra-ataque-com-wind-up-de-0-3-s.md) | Combate / contra-ataque | Contra-ataque pós-desvio perfeito com wind-up de 0,3 s, independente do Move (status continua instantâneo) | Implementado |
| [D-313](D-313-overworld-tiles-refeitos-e-efeitos-visuais.md) | Exploração / visual | Tiles podem ser refeitos; poeira, tochas cintilando, NPC olha para o jogador e sprites de Pokémon autorizados; sombra não escolhida | Não implementado |
| [D-314](D-314-fila-de-aliados-rastro-exato-sem-atravessar.md) | Exploração | Fila com rastro exato, sem atravessar; se travar, espera ou vai ao ponto livre mais próximo | Não implementado |
| [D-315](D-315-niveis-de-ameaca-referencia-escala-e-distancias.md) | Exploração / IA | Ameaça pela soma do grupo vs soma da equipe; nível = média +1..+4; 3/6/9 tiles e 40/70/110/150 px/s; faixas −40%/−10%/+30% confirmadas; ícones a desenhar | Não implementado |
| [D-316](D-316-descanso-ao-pisar-e-expedicao-de-5-andares.md) | Exploração | Descanso ao pisar cura a equipe ativa; 3º ponto em 10%; expedição de 5 andares e nova expedição completa no fim | Não implementado |
| [D-317](D-317-bioma-a-cada-5-andares.md) | Exploração / visual | Bioma muda a cada 5 andares; espécies pendentes | Não implementado |
| [D-318](D-318-f6-eventos-primeiro.md) | Exploração / conteúdo | F6 começa por eventos; ordem restante pendente | Não implementado |
| [D-319](D-319-f3-so-no-overworld-batalha-continua-gible.md) | Exploração / escopo | F3 só no overworld; batalha 3D continua Gible fixo | Não implementado |
| [D-320](D-320-publicacao-de-docs-autorizada.md) | Processo / Git | Commit + push só de docs autorizado; worktree limpo do `origin/main` | Pendente de execução |
| [D-321](D-321-inimigos-tambem-andam-em-grupo.md) | Exploração / IA | Inimigos também andam em grupo (solto, máx. 3); soma define a ameaça do grupo; líder derrotado → próximo vira líder | Não implementado |
| [D-322](D-322-refazer-os-efeitos-de-elemento-do-zero.md) | VFX / Motion Composer | Refazer do zero fogo, água, terra e ar com qualidade visual extrema; melhorar o Motion Composer se preciso | Fogo refeito (aguarda aprovação); água, terra e ar não iniciados |
| [D-323](D-323-melhorar-o-motion-composer-antes-de-qualquer-efeito.md) | VFX / Motion Composer | Melhorar o Composer (elementos estilizados e semi-realistas) antes de qualquer efeito; não trocar peças do fogo agora | Registrada; escopo das melhorias em aberto; sem código |
| [D-327](D-327-composer-precisa-de-modelos-3d-dos-elementos.md) | VFX / Motion Composer | A galeria da V1.2 foi reprovada: o Composer precisa de malhas/modelos 3D dos objetos elementais, não só texturas e formas procedurais | Registrada; origem dos modelos em aberto; sem código |
| [D-332](D-332-fogo-por-shader-flipbook-e-composer-referencias.md) | VFX / Motion Composer | Fogo por shader + flipbook + Composer (não mais modelo 3D); referências: Persona, Genshin Impact, Pokémon | Registrada; implementação em andamento |
| [D-335](D-335-implementar-no-godot-os-efeitos-do-atelier.md) | VFX / Motion Composer | Implementar no Godot os efeitos do atelier.html, um de cada, melhorando com shaders sem arruinar o visual | 1 de 8 (Splitter Flames); aguarda aprovação |
| [D-323](D-323-remover-seis-especies-sem-overworld.md) | Exploração / Pokédex | Remove simisear, simipour, throh, amoonguss, stunfisk e aromatisse da lista usável (sem overworld); usável 297 | Aplicado no manifesto |
| [D-324](D-324-hub-2d-extracao-e-vila-compacta.md) | Exploração / campanha / visual | Hub 2D jogável: base compacta que cresce para vila, uma tela sem interiores, serviços como NPCs; modelo de extração | Direção aceita; detalhes pendentes; não implementado |
| [D-325](D-325-usar-assets-2d-de-mystery-dungeon.md) | Visual / assets / exploração | Usar assets 2D não-Pokémon de Explorers of Time/Darkness e Sky: dungeons, backgrounds, itens, UI e props; Pokémon do site ficam de fora por ora | Autorizado; nada importado; escala e uso pendentes |
| [D-326](D-326-ordem-dos-assets-tilesets-e-24px.md) | Visual / assets / exploração | Ordem: Time/Darkness primeiro, Sky depois; dungeons com tilesets modulares sobre a geração procedural; 24 px por tile por ora | Registrada; conversão 24 px proposta; nada implementado |
| [D-328](D-328-24px-no-jogo-inteiro-e-cena-de-teste-do-hub.md) | Exploração / visual / implementação | 24 px no jogo inteiro e cena de teste do hub autorizada | **Revertida por D-329**; cena do hub permanece em 48 px |
| [D-329](D-329-voltar-para-48px.md) | Exploração / visual | Voltar para 48 px; a perda de qualidade do teste de 24 px foi imensa | Revertido; testar e capturar de novo |
| [D-330](D-330-dungeon-tiles-do-sky-e-troca-do-atlas.md) | Exploração / visual / assets | Importar os 16 Dungeon Tiles do Sky e trocar o atlas procedural pelo tileset do Temporal Tower, mantendo a geração procedural | Implementado e testado em Godot 4.7.2; aguarda aprovação visual |
| [D-285](D-285-ia-levanta-o-guard-perto-do-impacto.md) | Combate / IA / Guard | A IA levanta o Guard quando faltam 0,8–1,3 s para o impacto, não no começo do wind-up | Implementado |
| [D-286](D-286-contato-sem-teleporte-quando-o-alvo-se-move.md) | Combate / contato | Se o alvo se move durante o golpe, o atacante o alcança deslizando (máx. 45 u/s) em vez de teleportar no impacto; suaviza D-054 | Implementado |

- [D-333 — Exceção: atelier HTML com Quarks.js](D-333-excecao-atelier-html-quarks.md) — aprovado, somente este protótipo.
- [D-334 — Atelier: tamanho fixo no mundo](D-334-atelier-tamanho-fixo-no-mundo.md) — implementado; invariância verificada nos oito efeitos.
- [D-336 — Batalha DQT: modelos 30% menores, centralizados e chão mais largo](D-336-batalha-dqt-tamanho-posicoes-e-chao.md) — só a batalha de teste DQT; implementando.
- [D-337 — Auditoria extrema e implementação fiel dos 6 Moves já codados do Atelier HTML](D-337-auditoria-e-fidelidade-6-moves-atelier.md) — em implementação; Psychic Cannon e Psycho Orb por último para brainstorm.
- [D-338 — Inimigos alinhados para a esquerda, 6 entre eles, e chão de largura 60](D-338-inimigos-alinhados-a-esquerda-e-chao-60.md) — todas as batalhas; implementando.
- [D-339 — Inimigos 20% maiores em todas as batalhas](D-339-inimigos-20-porcento-maiores.md) — `ENEMY_SCALE` 1,8 → 2,16; trajeto preservado.
- [D-340 — Piscar próprio dos monstros DQT e regra de olhos do jogo](D-340-piscar-proprio-dos-monstros-dqt.md) — 0,12 s a cada 3–6 s, sempre que os olhos estão abertos.
- [D-341 — Cyclops lento: +0,8 s na ida e passo casado com o chão](D-341-cyclops-lento-mais-0-8s-e-passo-casado.md) — provisório até a AGI existir.
- [D-342 — Orc e Cyclops 1,2× maiores no lado do jogador](D-342-orc-e-cyclops-1-2x-no-lado-do-jogador.md) — lado do oponente sem mudança.
- [D-343 — Heal Gain: opção 2, cruzes verdes em flipbook e lado direito limpo](D-343-heal-gain-opcao-2-cruzes-verdes-flipbook.md) — implementado (número em `CanvasLayer` 2D com as cores exatas; cruzes com escala de câmera); aguardando aprovação visual.
- [D-344 — Câmera do dungeon em 2,3×](D-344-camera-do-dungeon-em-2-3x.md) — 1,5× → 2,0× → 2,3×; só exploração 2D.
- [D-345 — Pipeline de tilesets: medir, validar e testar antes de usar](D-345-pipeline-de-tilesets-medir-validar-testar.md) — as 10 propostas viram padrão do importador.
- [D-346 — Terrain nativo e seletor de bioma por andar (Bloco 1)](D-346-terrain-nativo-e-seletor-de-bioma.md) — seletor implementado; terrain nativo no laboratório (9 peças reais; 0/0 não alcançado); jogo mantém o renderer aprovado.
- [D-347 — Piso orgânico com Ground Alt. 1/2 (Bloco 2)](D-347-piso-organico-ground-alt.md) — 18 núcleo + 2 alts; só no centro do chão; 92/4/4; decals, não piso seamless.
- [D-348 — Parede de 1 tile: strip de dois lados e máscara de 8 vizinhos](D-348-parede-strip-dois-lados-e-mascara.md) — fora do mapa é aberto; `wall_strip_h/v` fecham os dois lados; lado aberto só para interseção.
- [D-347 — Heal Gain acima da ficha, torto por lado e odômetro guardado](D-347-heal-gain-acima-da-ficha-e-odometro-guardado.md) — número acima do `UnitCard`/`EnemyTag`, rotação e diagonal por lado, 1,4 s; odômetro arquivado em `legacy`; HP/barra imediatos; aguardando aprovação visual.
- [D-348 — Heal Gain na frente, visível desde o começo, e o atraso correto do ganho](D-348-heal-gain-na-frente-e-atraso-do-ganho.md) — número na frente, fora da ficha, visível no primeiro quadro; cruzes no personagem; Heal Gain espera 0,10 s depois do `healed`; pilares do Media revertidos; aguardando aprovação visual.

- [D-354 — Pipeline de percepção dos tilesets: orientação, preview e contrato de face](D-354-pipeline-de-percepcao-e-composicao-da-parede.md) — as 10 melhorias viram auditoria obrigatória; o preview prova `topo (linha 1) → face (linha 2) → chão`; seleção por assinatura de lado; 30 tiles reais; início do jogo aprovado visualmente, gate formal aprovado em 2026-11-06.
- [D-355 — Polimento dos tilesets: golden, máscaras, occluder, decals e Wall Alt](D-355-polimento-tilesets-golden-mascaras-occluder-decals-alt.md) — golden da sala, máscaras 8-vizinhos, occluder ciente da face, decals com espaçamento (8,7% reais) e Wall Alt. 1/2 em 10% do interior; 30 tiles; gate do Temporal aprovado em 2026-11-06.
- [D-356 — Biomas restantes, porta, decals exatos, golden 2D e occluder medido](D-356-biomas-restantes-porta-decals-golden2d.md) — fallback dos 12 perfis por papel (murky_forest 0 divergências), 16 capturas de bioma, porta no lab, decals 8,1% sem adjacentes, golden 2D, baseline de occluder e sintonia 0/5/10/15% do Wall Alt; água/padding/commit bloqueados.
- [D-357 — Tochas visíveis removidas, atlas em Scale2x e água decorativa adiada](D-357-tochas-scale2x-e-agua-decorativa.md) — chama/cabo/brasas e luzes amarelas fora (D-358); 16 atlas 3.0.0 em Scale2x 2× (fonte 24 px); água do Temporal é cinza e ficou pendente de escolha visual (água azul das folhas de gelo, shader ou fora).
- [D-358 — Névoa e overlay por bioma; luzes amarelas removidas](D-358-nevoa-overlay-por-bioma-e-luzes-removidas.md) — `BiomeVisuals` com 16 cores de ambiente e 16 presets de névoa (cor/densidade/warp/drift); `fog_of_war` lê `GameState.visual_biome`; tochas e luzes amarelas fora; baseline de brilho regerada.
- [D-359 — Paletas fortes por bioma e sem luz do jogador](D-359-paletas-fortes-e-sem-luz-do-jogador.md) — 16 `AMBIENT`/`FOG` saturados e distintos; luz do jogador removida; só a vermelha dos inimigos; Temporal/Spire compensados; 16 capturas e baseline regeradas.
- [D-360 — Névoa com duas cores laterais e ruído próprio por bioma](D-360-nevoa-duas-cores-laterais-e-ruido-por-bioma.md) — `color`/`color_b` + `side_mix` no shader; `NoiseTexture2D` por bioma (simplex/cellular/perlin/cubic); 16 contatos in-game; laboratório só ambiente.
- [D-361 — Pancham mais perto: gap do seguidor de 48 para 32 px](D-361-pancham-mais-perto-gap-32.md) — `TRAIL_GAP` 32 px; rastro exato, velocidade, espera e reposicionamento de D-314 não mudam; se ainda longe, 24 px.
- [D-362 — PROPOSTA: eventos temporais (calor, chuva e neblina maior)](D-362-proposta-eventos-temporais-calor-chuva-neblina.md) — proposta de clima visual por bioma: calor ondulado EarthBound, chuva/neve com respingo no chão e neblina maior; nada implementado; aguarda escolha.
- [D-381 — Clima aprovado: só visual, os três eventos, raro e distorção temporal](D-381-clima-aprovado-visual-tres-eventos-e-raro.md) — clima não altera nenhuma regra; neblina é véu visual (raio 7,5/LOS intactos); entram calor, chuva/neve com respingo e distorção temporal; frequência rara com cadência pendente; clima fora do Motion Composer (D-383); CPUParticles2D (GL Compatibility).
- [D-382 — Clima: 20% por andar, 20–40 s e mapa de biomas de D-362](D-382-clima-cadencia-20-por-andar-duracao-20-40s.md) — rolagem determinística por andar (1 em 5), no máximo um evento, 20–40 s com fade; mapeamento de D-362 mantido; clima fora do Motion Composer (D-383); nada implementado.
- [D-383 — Clima fora do Motion Composer; D-308 restrito ao VFX de combate](D-383-clima-fora-do-motion-composer-e-escopo-do-d-308.md) — clima/exploração é camada 2D de ambiente e não usa o Composer; D-308 e o protocolo valem só para VFX de Move/elemento em combate; o Composer não é gate para clima.
- [D-384 — Neblina implementada: camada 2D, rolagem de 20% e capturas](D-384-neblina-implementada-camada-2d-rolagem-e-capturas.md) — shader `weather_mist` + controller 20%/andar (20–40 s, fade 2 s), camada 2D abaixo da UI; antes/depois em `docs/referencias/exploracao/weather_mist_before_after.png`; calor/chuva pendentes; capturas e vídeos no worktree principal.
- [D-385 — Neblina mais densa: visão pior e nevoeiros maiores](D-385-neblina-mais-densa-visao-pior-nevoeiros-maiores.md) — `max_alpha` 0,40, `density` 0,85, `noise_scale` 1,7 e `edge_mist` 0,55; bancos maiores e bordas fechadas; continua só visual (raio 7,5/LOS intactos); vídeos regravados.
