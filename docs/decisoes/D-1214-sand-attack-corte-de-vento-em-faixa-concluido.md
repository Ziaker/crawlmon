<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1214 — Sand Attack: corte de vento em faixa no release, rastro no chão, giro do atacante e release sem o atraso pós wind-up (move concluído)

- **Data:** 2026-11-14.
- **Área:** VFX de Move / combate.
- **Relacionadas:** D-1196 (Sand Attack A), D-1212 (rastro de poeira estilo LoL, revertido), D-235, D-308, D-280, D-1204.
- **Status:** **concluído a pedido do criador** ("trate esse move como concluído"). Verificações e lacunas no fim.

## O que o criador disse (literal, em ordem)

> este efeito, no momento que ocorre o release do move, eu quero que ele se mova junto com a areia,

> como marcado na parte verde, rastro assim (obviamente não por completo, mas sim que se cria junto com o trajeto do move)

> o tempo pra sumir podia ser mt menor, além da cor estar mt clara, reduza a opacidade maxima pra .8 e o tempo pra sumir pra .64

> no release, ao invés de ser aquele cone maior, faça ser na verdade um laço em arco na frente do personagem horizontal mas virado 20 graus pra diagonal que é realizado por .35 segundos junto com o disparo da areia, em amarelo

> não, é como um corte rapido, uma faixa larga

> NÃO, ELA SAI DO CHÃO, E FAZ UM ARCO COMPLETO, EM FORMA DE CORTE DE VENTO PRA CIMA, TIPO UM MOVIMENTO HELIOCIDAL

> está péssimo, tem que percorrer o redor do personagem, não sei lá o que vc tá fazendo, é um movimento horizontal semi-diagonal de arco, como um corte

> é de trás pra frente a geração do laço, ele não inicia por cima, inicia por baixo, aumente sua largura e deixe a cor mais amarela

> mais aberta, 15% menos opacidade, 25% maior, mais horizontal, menos vertical em questão de tamanho, como um corte

> faça com que ela seja mais "etérea" com a duração sendo maior mas aplicando uma redução de opacidade e dissipação de partículuas ao longo do trajeto

> durante o release faça o personagem dar um giro completo junto com o efeito visual. Faça com que a dissipação dela se mova pra frente, deixe-a maior em ambos horizontal e vertical em 20%

> faça com que este move tenha a exceção do pós wind-up, ocorrendo sem ter o delay

Resposta à pergunta "qual delas?" (pausa de carga segurada / atraso do jato / intervalo no combate):

> 2, ocorrer imediatamente após o fim do wind-up sem o delay

> deixe mas largo ainda a faixa, no mínimo 35% maior faça ela dar uma volta e meia ao invés de só um arco completo.

> perfeito, agora eu quero que trate esse move como concluido e atualize os documentos

## Decisão (o que está no jogo)

1. **Corte de vento em faixa** (nome no catálogo: "Corte de vento em faixa", em inglês "Wind Slash Band"): faixa larga amarela horizontal ao redor do atacante, inclinada 20°, 540° (uma volta e meia), varrida em 0,35 s a partir da ponta de baixo, depois dissipada em 0,7 s por trecho (opacidade cai e a faixa se desfaz em grãos que avançam para a frente). Substitui o cone parado maior do release. O cone que viaja com a areia continua.
2. **Giro completo** do atacante (360°) durante a varredura de 0,35 s.
3. **Rastro no chão** do atacante ao alvo, nascendo junto com o trajeto e perdendo opacidade (0,64 s por ponto, opacidade máxima 0,8).
4. **Anel de nuvens, véu e poeira solta** do release viajam do atacante ao alvo com a areia.
5. **Release sem o atraso pós wind-up:** o VFX nasce na entrada da fase STRIKE (logo após o wind-up), não no TRAVEL.
6. Mecânica, dano, cegueira, esquiva, tempos e o momento do acerto **não foram alterados**.

## Valores sem número do criador (escolha técnica da IA; ele pode mudar)

Largura 0,49 da altura do corpo; altura do corte 0,6 da altura; raio 1,05 da altura; dissipação 0,7 s e avanço de 1,5 alturas; cor núcleo (1,0, 0,95, 0,2) e borda (1,0, 0,82, 0,05); faixa do rastro 3 m de largura, 0,12 m acima do piso; poeira solta do anel a cada 0,09 s; sentido do giro positivo (anti-horário visto de cima). Tabela completa em `docs/vfx/VFX kinds/Corte-de-vento-em-faixa--codigo.md`.

## Efeito visível (o que o criador deve notar)

O efeito visual termina cerca de 0,5 s **antes** do acerto, porque o release agora nasce no STRIKE e o acerto continua no TRAVEL (regra de combate intocada). Se o criador quiser o acerto mais cedo, é mudança de regra no `AttackPlanner` e precisa do aval dele.

## Verificado

- Compila e roda na sala de debug (`--scenario=sand_attack`, vista normal), sem erro de script. Quadros reais de cada etapa em `docs/vfx/sand_attack_ref/` (capturas locais de ~1 GB, removidas na limpeza final; para refazer use os comandos de `docs/vfx/VFX kinds/Corte-de-vento-em-faixa--codigo.md`) (`slash8`, `spin1`, `nodelay1`, `wide1`).
- Trace de fases: STRIKE em 0,81 s, TRAVEL em 1,61 s, release visível a partir de ~0,95 s.

## NÃO verificado

- Vista espelhada (atacante inimigo e distante) com o corte e o giro; outros atacantes; alvos de tamanhos diferentes (D-235).
- `--audit-leaks` com o corte longo: a auditoria do debug listou sobras logo após o fim do move; não foi esperado o fim das vidas (`--audit-delay`).
- Suíte `python tests/battle/run_agent_combat_tests.py` e `tests/vfx/test_*` depois destas mudanças (antes delas a suíte oscilou entre 42/49 e 49/49 por edições concorrentes de outras sessões).
- Sentido do giro (horário × anti-horário); interação do giro com a animação e o retorno do atacante; `--bg`, `--scale-overlay`, `--proof-sheet`.
- Igualdade quadro a quadro com o HTML (o corte, o giro e o rastro são acréscimos do criador ao D-1196; "escala fixa em metros × por tela" do D-1196 segue pendente de confirmação).

## Divisão do trabalho

DeepSeek (via `ds-run.mjs`): remoção do projétil/impacto antigo e a integração base do Sand Attack A (patches `01b45703`, `601e6e53`); várias tentativas de patch falharam e foram aplicadas à mão. Claude: todo o visual (corte, giro, rastro, ajustes), o gatilho no STRIKE, a ferramenta `--audit-delay`, capturas e esta documentação.
