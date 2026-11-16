> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.

# D-1215 — Roleta de Nature como caça-níquel: os rolos são os status modificados

Data: 2026-11-14

## Frases literais do criador

> "eu acho que a roleta de escolha de natures devia ter um visual diferente, pense em uma roleta de bet, de caça niquel, até mesmo com os sons caracteristicos de um caça niquel (aqui eu permito o audio) com toda uma animação completa"

> "deixe 80% do trabalho do código do protótipo pro deepseek e me surpreenda visualmente, desde que siga o conceito visual do jogo de cores flats e interfaces tortas"

> "os rolos são os status que eles modificam, se a nature não modifica nenhum status então o resultado é NONE"

> "então sim 3"

## Decisão

- A roleta `EXPEDITION NATURE (R18-Q4)` ganha visual e som de caça-níquel, com animação completa. Áudio permitido nesta tela.
- Primeiro vem um protótipo; cerca de 80% do código do protótipo é do DeepSeek, e a direção visual é do agente principal.
- O visual segue o conceito do jogo: cores flat e interfaces tortas.
- A máquina tem 3 rolos.
- Os rolos mostram os status que a Nature modifica. Se a Nature não modifica nenhum status, o resultado é `NONE`.

## Respostas posteriores (2026-11-14)

- **3 rolos × quantidade de status:** resolvido em D-1216 (10 Natures novas com 3 status) e D-1217 (Brave, Timid, Calm e Adamant reajustadas para 3 status).
- **Alavanca:** à pergunta "O jogador puxa a alavanca para girar os rolos?", o criador respondeu:

> "Gira sozinho"

  Os rolos giram sozinhos, sem alavanca puxada pelo jogador.

- **Momento em que a roleta aparece:**

> "ela aparece na tela após a entrada do jogador no jogo, quando finalizar a seleção de personagem e então após ela ocorre a transição que o invoca no mundo"

  Ordem: seleção de personagem concluída → roleta → transição que invoca o jogador no mundo.

- **Impacto de cada parada de rolo:**

> "queria que desse mais efeito e impacto ao chegar em cada resultado, com um som forte bem caracteristico"

  No protótipo: baque grave com sino que sobe a cada rolo, tranco do gabinete, clarão só na casa sorteada e estilhaços flat. O criador ainda não disse se esse impacto está aprovado.

- **Som do resultado final:**

> "acho que o resultado devia dar um som de vitoria ou checkpoint um ta ta na nam!!!"

  No protótipo: fanfarra de quatro notas (duas curtas, uma subida, um acorde longo). À pergunta "A fanfarra do resultado ficou como você imaginou?", o criador respondeu:

> "Sim, aprovado"

  A variação mais grave e suave para Hardy/Docile foi escolha da IA e não foi comentada pelo criador.

## Ambiguidades em aberto (nada disto está decidido)

0. **Saída da roleta — respondido:** à pergunta "A transição para o mundo começa sozinha depois da revelação?", o criador respondeu "Espera o Enter". A transição só começa quando o jogador confirma. Segue em aberto se a roleta do `EXPEDITION GATE` a cada nova expedição (D-1208, D-316) continua existindo além desta.
1. **Quase-acerto — respondido.** A IA recomendou "sim" (o último rolo ameaça outro resultado antes de cair no certo; o resultado já está travado). O criador respondeu:

> "sigo suas recomendações"

2. **Chance de sorteio — respondido** pela mesma frase: a IA recomendou as 18 Natures com a mesma chance.
3. **Impacto de cada parada — respondido.** À pergunta "O impacto de cada parada de rolo está aprovado?", o criador respondeu "Sim, aprovado".
4. **Roleta do portão — respondido.** À pergunta "A roleta do portão continua existindo a cada nova expedição?", o criador respondeu:

> "Não, só esta"

   A roleta existe só depois da seleção de personagem; a do `EXPEDITION GATE` deixa de existir.

5. **Resolvido em D-1219** (a Nature fica com o personagem até o game over). Texto original da contradição: D-316 diz "nova expedição completa: andar 1, nova seed, MP cheio e Natures novas", e D-1208 dispara a roleta no portão. Sem a roleta do portão, falta o criador dizer se a Nature ainda muda a cada nova expedição (sem roleta na tela) ou se fica fixa desde a seleção de personagem. O código do jogo ainda abre a roleta no `HUB_GATE`; nada foi alterado.

## Restrições já existentes que continuam valendo

- Resultado travado antes da animação; pular não muda o resultado (D-1208).
- Sem piscada ou estrobo de tela (D-418, D-1185).
- Texto em inglês (D-131, D-413); sem bordas, blocos em paralelogramo (D-416, D-421, D-428).

## Estado

Implementada no jogo em 2026-11-15: `scripts/ui/pre_game/nature_slot_view.gd` (máquina de 3 rolos, SubViewport para o recorte, giro automático, quase-acerto no último rolo, impacto por parada, fanfarra, carimbo, chuva de fichas, saída com faixas) + `nature_slot_sfx.gd` (sons sintetizados da receita do protótipo) + `nature_slot_logic.gd` (símbolos e posições, igual ao HTML), hospedada em `PreGameViewModals`. Verificado: as 18 Natures mostram os mesmos símbolos do protótipo (`?autotest=all`) e do Godot (`--scenario=PREGAME_ROULETTE`: giro natural, SKIP e reduce-motion iguais). Debug: `--hud=roulette --nature=<id> [--roulette-at=<ms>] [--speed=] [--mute] --shot=...`. Não verificado: o som ao ouvido (só sintetizado e conferido por código), a captura de cada fase lado a lado com o HTML (só estado final, parada 1 e giro).
