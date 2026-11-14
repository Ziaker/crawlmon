# D-1192 — O pós-combate novo do protótipo D-1185 passa a ser implementado no jogo

- **Data:** 2026-11-12.
- **Área:** Combate / pós-combate / UI / progressão.
- **Relacionadas:** D-1185 (protótipo, rodadas 1–12 + notas), D-1184 (VictoryPanel + LevelUpModal, substituídos no fluxo), D-433 §5 (por que o port anterior falhou), D-401, D-402, D-399, D-394, D-417, D-420, D-1186, D-1187, D-1188, D-1190, D-235, D-1154.
- **Status:** **aprovado para implementação; em andamento.**

## O que o criador disse (literal)

> acho que ja podemos implementar por completo o visual novo do level up e o pos combate, faca isso enviando a informacao necessaria para outra sessao, deixe o deepseek cuidar do codigo e vc cuida de auditoriar o visual pra ser exatamente como no prototipo

## Decisão

1. O fluxo de `prototypes/level_up_overhaul.html` (D-1185) substitui no jogo o fluxo da D-1184 (`VictoryPanel` + `LevelUpModal` em `battle_scene.gd::_trigger_victory_flow`). Os arquivos antigos **não são apagados**, só deixam de ser abertos.
2. Como o criador mandou implementar **"por completo"**, as **propostas do assistente** da D-1185 viram regra:
   - **Ordem:** XP de todos ao mesmo tempo → etapa LV de cada membro que subiu (líder distribui, D-401; aliado automático) → Move novo → volta ao mapa.
   - **Move novo com vaga livre (< 8):** aprende sozinho, na próxima vaga.
   - **8 vagas cheias (R38-Q5):** escolher um Move para esquecer pela inspeção (**[Z] ESQUECER ESTE**) ou **NÃO APRENDER** (com confirmação). Aliados aprendem do mesmo jeito; a escolha é do jogador.
   - **Fonte dos Moves novos:** `CharacterLoadout.learnset` (nível → Moves). A mecânica é criada; os dados ficam vazios até o criador dizer quais Moves cada espécie aprende e em que nível.
3. Regras técnicas (D-433 §5): palco 1280×720; paralelogramo só como fundo (`draw_colored_polygon`); texto nunca inclinado sozinho; cada bloco gira inteiro (`Control.rotation`); todo texto é medido e encolhido para caber; nada depende de personagem (D-235).

## Em aberto (perguntar ao criador)

- Estilo de entrada dos blocos (Deslizar / Pop / Cair). Até a resposta: **Deslizar** (padrão do protótipo).
- Learnset: quais Moves cada espécie aprende e em que nível.
- Pontos automáticos do aliado: a D-394 diz "proficiência pelas ações em combate + Tactics + Nature", sem taxas; o código não aloca pontos de aliado. O protótipo usa "Nature prioriza X" só como exemplo.
- Cor do badge de Status (laranja `#fb923c` provisória, D-1190).
- Se Moves aprendidos entram nos 4 atalhos; se dá para reaprender um Move esquecido.

## Respostas do criador (2026-11-12)

- Visual auditado contra o protótipo: > esta tudo ok — aprovado.
- Entrada dos blocos: > desligar esta otimo — registrado como **Deslizar** (estilo atual). **A CONFIRMAR com o criador**: "desligar" pode ser digitação de "deslizar" ou pedido para desligar as animações de entrada.
- Learnset: > por ora ainda nao — continua vazio; nenhum Move é aprendido por nível até o criador definir.
- Pontos do aliado: > ainda tenho que ver, pendente — pendente; a tela do aliado continua mostrando "AUTOMÁTICO" sem aplicar pontos.
- Cor do badge de Status: > acho que faz mais sentido ser branco do que laranja — branco (ver D-1190).

- **Entrada dos blocos confirmada (2026-11-12):** > com desligar eu quis dizer deslizar sim → fica **Deslizar** (já é o estilo em uso; nada muda no código).
