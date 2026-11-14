<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

@AGENTS.md

Leia `AGENTS.md` e todos os arquivos de `docs/decisoes/` antes de qualquer tarefa (veja o índice em `docs/decisoes/README.md`). Antes de combate, fila, pausa de status, dano, animação, VFX ou debug, leia também `docs/TELEMETRIA.md` (D-1154).

## Divisão Claude + DeepSeek (Command Code)

- LEITURA DAS DECISÕES SEM PERDER NADA E SEM ENCHER O MEU CONTEXTO: no início de uma tarefa, escreva a tarefa (nas palavras do criador) num arquivo e rode `node ~/.claude/tools/ds-decisions.mjs <arquivo>` na raiz do repo. O DeepSeek lê TODOS os `D-*.md` em lotes (cada um cabe na janela dele) e devolve um resumo único com a frase literal de cada decisão aplicável. Leia só esse resumo (e abra na íntegra os D-xxx que forem decisivos). Se alguma linha disser `LOTE n FALHOU`, refaça o comando; não prossiga sem os lotes todos. Isto cumpre AGENTS.md §1 (todas as decisões foram lidas) e substitui eu carregar os ~430k tokens. Cite os IDs do resumo na resposta.
- Rodadas de teste e de debug (`--scenario=... --stdout-trace`, `run_agent_combat_tests.py`, `--audit-leaks`): delegue ao `deepseek-code` em modo EXECUTOR (o Haiku roda os comandos e devolve só as linhas-chave e as falhas). Quadros de VFX no tamanho real continuam sendo vistos por mim quando o protocolo D-308 pede.
- Delegue ao `deepseek-code` a implementação, os testes e as capturas (preferência do criador: DeepSeek executa a maior parte do trabalho delegado). Eu dou contexto mínimo e direção, e revejo o resultado. Só faço eu mesmo o que for visual, a decisão de design ou uma linha trivial.
- Trabalho de texto (respostas, docs, D-xxx, análises, explicações, resumos): escreva você mesmo, direto e curto. NÃO delegue texto ao DeepSeek (o rascunho volta ao seu contexto e você o reemite: custo em dobro). Só delegue um documento longo (>~150 linhas) cujos fatos já estejam levantados.
- Saídas pequenas: Grep com `head_limit`/`files_with_matches`, Read com `offset`/`limit`, Bash com `| head`; buscas largas vão para um subagente `Explore` (devolve só a conclusão). Plano e wrap-up curtos. Não edite CLAUDE.md/AGENTS.md no meio de uma sessão (invalida o cache). Compacte (`/compact`) por volta de 150k de contexto.
- Sessão: um modelo só por sessão (trocar invalida o cache). Evite Read de imagens/capturas grandes; reduza o tamanho antes. Passou de ~200k de contexto, sugira sessão nova.
- Tarefas só visuais (HUD, UI/UX, shaders, VFX, animação, câmera), protótipos e modelos 3D: faça você mesmo.
- Tarefas mistas: primeiro `deepseek-code` faz a parte mecânica; aplique o patch; depois faça a camada visual.
- Ao integrar um patch do DeepSeek: confira se todos os caminhos estão no escopo (rejeite `project.godot`, `.import`, `addons/`, `assets/` e arquivos não relacionados); aplique com `git apply --check --ignore-whitespace` e `git apply --ignore-whitespace` (se falhar, aplique as mesmas mudanças com Edit); rode `python tests/battle/run_agent_combat_tests.py` quando tocar combate. Se falhar, devolva o erro ao `deepseek-code` uma vez antes de corrigir você mesmo.
- O working tree costuma ter mudanças não commitadas: nunca use `git stash`, `checkout` ou `reset` para limpar. Sem commit/push sem autorização. Sem `--yolo` no cmdc sem autorização.
- Fechar o ciclo (nunca deixar pedido parado): depois de cada delegação ao DeepSeek, olhe as linhas `[deepseek handoff]` (status, caminho do `.patch`, `apply_check`). `COMPLETE` + `OK` → aplique o `.patch` pelo caminho e rode os testes. `INCOMPLETE`/`FAIL` → não diga que está pronto: divida a tarefa (um Move ou um arquivo por chamada) e refaça, sem esperar o criador perguntar. Se não for possível resolver, diga na hora que ficou pendente e o motivo. Uma pergunta que fiz ao criador e não foi respondida deve ser lembrada na próxima mensagem. Uma tarefa por chamada (ex.: não misturar Sukukaja com balanceamento).
- BARREIRAS OBRIGATÓRIAS antes de qualquer código do DeepSeek entrar (nenhuma é opcional): (1) `status=COMPLETE` e `apply_check=OK`; (2) EU leio o diff inteiro, hunk por hunk, e confiro contra as decisões aplicáveis e contra o pedido (nada além do pedido, AGENTS.md §3); (3) aplico e rodo os testes (`python tests/battle/run_agent_combat_tests.py` em combate, `--test-d235`); (4) rodo o comportamento real quando houver como (cenário da sala de debug) e confiro com dados; (5) diga ao criador o que NÃO foi verificado. Qualquer barreira que falhe → não entra. ESCALADA: se o DeepSeek falhar duas vezes na mesma tarefa, EU faço a tarefa, sem insistir. Prefira eu mesmo escrever quando o custo de um erro for alto (regra de combate central, fila, dano, ATB).
- Na resposta final, diga o que foi feito pelo DeepSeek e o que foi feito pelo Claude.
- **NUNCA decida NADA pelo criador** (valor, alvo, custo, cor, forma, movimento, nome, escopo, "padrão", nem "a minha recomendação"). Uma decisão por pergunta; "sim" a uma pergunta em bloco não decide as partes. O que ele não disse fica pendente e não entra em código, briefing ou documento (AGENTS.md §2).
- Não mande o DeepSeek, um subagente ou outra sessão fazer algo que o criador não pediu. O briefing não pode conter escolhas de regra ou visual (cores, forma, movimento, valores, escopo) que ele não fez: se faltar definição, recomende e pergunte antes de delegar. Detalhes técnicos podem ser decididos pela IA (AGENTS.md §2).

## Testar SEMPRE no debug; sem cenário pronto, CRIE o cenário (ordem do criador, 2026-11-13)

- Para testar qualquer coisa de combate, Move, alvo, cura, IA, fila ou VFX, use SEMPRE a sala de debug (`scenes/debug/vfx_room.tscn`, `scripts/debug/vfx_room_scenarios.gd`, `BattleDebug`) e a telemetria (`--stdout-trace`, `--summary-json`). Não improvise com batalha real e não desista dizendo "o líder não tem o Move" ou "o slider não respondeu".
- Regra dos 5 e 10 segundos: se o que você precisa testar no debug não tem um caminho pronto e montar o teste à mão levaria mais de ~5 segundos, **crie um cenário** em `vfx_room_scenarios.gd` (papéis A1/A2/E1/E2, `hp`, `enemies`, `atk`, `acts`) para que a verificação rode em **menos de 10 segundos**, por exemplo com `--scenario=<id> --stdout-trace --quit`. Faça o lado normal e o espelhado (D-235). Não peça ao criador para ajustar slider, clicar ou montar nada: isso é trabalho seu.
- Se a ferramenta de debug em si não permite o teste (falta um controle, um alvo, um estado), **crie o controle** em vez de reportar que não deu para verificar.

## Preferência do criador — delegação ao DeepSeek

DeepSeek executa 99% do trabalho delegado, incluindo implementação, testes e captura. O agente principal dá apoio e direção visual quando solicitados, fornece contexto mínimo e revisa os resultados. Evite reler material já consultado, enviar o histórico completo ou repetir atualizações sem progresso.
