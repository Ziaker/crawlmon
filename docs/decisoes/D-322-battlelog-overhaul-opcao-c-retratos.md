# D-322 — Overhaul visual do BattleLog: opção C e retratos por evento

- **Data:** 2026-11-05.
- **Área:** Interface / HUD de combate / BattleLog.
- **Origem:** discussão visual do BattleLog, imagens propostas e escolha expressa da opção C.
- **Estado:** direção visual aprovada; **não implementado no Godot**. Referência binária e DOCX preparados para publicação, ainda não confirmados no GitHub.

## Declarações literais do criador

> “o battle log fica na direita acima e abaixo das câmeras (que vou remover por sinal pra dar mais espaço pro log), vc nem ta usando o visual estilizado definido pelo html novo”

> “todos estão péssimos, mas eu queria que tivessem o ícone do personagem no battle log.”

> “opcao C, prepare um prompt e docx extenso e coloque a imagem junto dooo docx no github”

## Decisão aprovada — somente o BattleLog

1. A **terceira imagem da rodada mais recente de mockups**, opção C, é a **referência visual selecionada para o BattleLog**. A aprovação não é dos demais componentes eventualmente modificados pela geração de imagem.
2. O **BattleLog permanece no canto superior direito** da arena, aproveitando visualmente a área que será liberada pela retirada das abas de câmera. Esta intenção de eliminar as abas **não autoriza** desativar o diretor de câmera, seus modos ou atalhos.
3. Cada entrada visual **deve apresentar um ícone/retrato do personagem** relacionado ao evento, integrado à própria faixa de informação.
4. A aparência da opção C utiliza faixas finas **brancas/off-white, angulares, inclinadas e recortadas diagonalmente**, com texto de alto contraste e realces cromáticos pontuais; título **BattleLog ciano/azul**, mantendo a identidade já aprovada no HTML.
5. Não acrescentar grandes painéis pretos/azuis, não deslocar HUD de jogador/aliado, buffs/debuffs, menu em leque, tag do inimigo ou tarja da habilidade. A decisão D-268 continua vigente para esses componentes.

## Não decidido a partir da imagem

- Política para escolher um ou múltiplos retratos em eventos com atacante e alvo, ações globais ou múltiplos participantes.
- Se o retrato aparece à esquerda ou à direita por regra fixa; na imagem estas posições são ilustrativas, **não** política por facção ou posição.
- Quantidade de linhas, limite do histórico, scroll, recolhimento, animações, sincronização, duração e persistência do log.
- Mapa cromático universal de eventos, regra de status, valor de dano, Moves, idioma e mecânicas de combate.
- Formato técnico dos eventos; o sinal atual `log_message(text: String)` não fornece por si só identidade tipada para os retratos.
- Projeto de remoção funcional de modos de câmera e atalhos.

## Fontes e rastreabilidade

- Referência de HUD existente: [D-268](D-268-hud-visual-buffs-debuffs-aprovado.md), [HTML aprovado](../../prototypes/crawlmon-hud-buffs-debuffs-aprovado.html).
- Fonte atual do HUD: `scripts/ui/battle_hud.gd`, com `_log: Label`, `_log_lines: Array[String]` e `_on_log(text: String)` mantendo até três mensagens, conforme auditoria em 05/11/2026.
- Fonte de eventos: `scripts/combat/battle.gd`, com `signal log_message(text: String)`, conforme auditoria em 05/11/2026.
- Documentos da entrega: `docs/hud/PROMPT_CRAWLMON_BATTLELOG_OPCAO_C.md`; arquivos binários PNG/DOCX somente quando a presença deles for verificada no GitHub.
- Aplicam-se D-003 (escopo), D-015 (todos inimigos visíveis), D-061 (registro contínuo), D-235 (independência de personagem/equipe/lado) e D-268 (HUD visual anterior).

## Escopo da presente publicação

Documentação apenas. **Nenhum código, cena, VFX, teste ou mecânica é modificado por esta decisão.**
