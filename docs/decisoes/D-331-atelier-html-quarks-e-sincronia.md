<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-331 — Correções e acabamento do protótipo HTML de oito Moves

- Data: 2026-11-05
- Escopo: HTML enviado pelo criador; sem integração ao jogo Godot.
- Estado: versão HTML de revisão produzida e testada; exceção do protocolo e escala resolvidas por D-333/D-334; aprovação artística pendente.

## Declarações literais

> corrige os problemas desse código e melhore os efeitos visuais dele

> quero mais detalhes nos efeitos, mais partículas, sem exagerar, parecer menos HTML-esco e mais GODOT-esco, usando quarks.js e bibliotecas de shaders

> sim

O “sim” respondeu à pergunta sobre corrigir as divergências, tornando os efeitos independentes do personagem e sincronizando os eventos pelo relógio da simulação.

## Decisão

Corrigir o protótipo HTML de oito Moves, integrar Quarks.js real, aumentar moderadamente os detalhes e partículas e usar bibliotecas de shaders. Corrigir elementos DOM ausentes, dependência de personagens/lados/posições (D-235) e timers fora do relógio da simulação (D-019). Preservar as identidades dos efeitos e não alterar regras do jogo Godot.

## Limites e ambiguidades

A autorização não é migração para Godot, nem autorização para substituir VFX do jogo, rebalancear dano ou aplicar decisões mecânicas pendentes. Os valores de demonstração do HTML não se tornam regras de combate. Aprovação visual final ainda pendente. Nenhuma autorização adicional de push foi dada nesta resposta.

## Atualização de instruções durante o trabalho

O criador enviou a nova seção 8 de AGENTS e pediu “continua”. Na época, D-308/protocolo exigiam Motion Composer e validação na batalha Godot; **D-1030 (2026-11-09) tornou o Composer auxiliar e opcional**, então essa exigência é histórica. Foram solicitados esclarecimentos sobre manter o HTML como exceção ou mudar a entrega, e sobre a contradição entre tamanho fixo no mundo (D-308) e tamanho por tela (protocolo). Nenhuma resposta foi presumida. Após a atualização, apenas validação e gravação da versão existente, documentação e empacotamento; sem novos ajustes de aparência.

## Resolução posterior

D-333 aprovou a entrega HTML com Quarks.js; D-334 definiu tamanho fixo no mundo. Aplicado referencial sem escala corporal e corrigido o delta negativo inicial do relógio, com 24 repetições aprovadas. Os oito Moves foram exercitados com outros atacantes, lado espelhado e alvos de tamanhos diferentes, sem erros JavaScript/GLSL. Aprovação artística continua pendente; nenhuma publicação Git foi feita.
