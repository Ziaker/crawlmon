> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.

# D-1219 — A Nature fica com o personagem até ele ser perdido (game over)

Data: 2026-11-15

## Frases literais do criador

À pergunta "A roleta do portão continua existindo a cada nova expedição?":

> "Não, só esta"

À pergunta "A nature fica fixa desde a seleção de personagem?":

> "fica fixa enquanto o jogador não perder o personagem, no caso, causar um game over, então depois que for decidido a nature, ela fica com o personagem mesmo se o jogador desistir e fazer outra expedição com outro personagem"

## Decisão

- A roleta de Nature (D-1215) aparece só depois da seleção de personagem. A roleta do `EXPEDITION GATE` a cada nova expedição deixa de existir.
- Depois de decidida, a Nature fica com aquele personagem.
- Ela continua com o personagem mesmo se o jogador desistir e fizer outra expedição com outro personagem.
- A Nature só deixa de valer quando o jogador perde o personagem, isto é, quando causa um game over.

## Decisões anteriores afetadas (preservadas, não apagadas)

- **D-316** ("nova expedição completa: andar 1, nova seed, MP cheio e Natures novas"): a parte "Natures novas" a cada expedição deixa de valer para o personagem que já tem Nature.
- **D-1208** (confirmar a expedição no portão dispara a roleta `EXPEDITION NATURE (R18-Q4)`): a roleta do portão deixa de existir.
- **D-1207 C7** (rótulo `EXPEDITION NATURE (R18-Q4)` e texto "FOR THIS EXPEDITION" de Hardy/Docile): os textos falam em Nature "da expedição"; falta o criador dizer se mudam.

## Ambiguidades em aberto (nada disto está decidido)

1. **Respondido.** À pergunta "Depois do game over, o personagem ganha uma nature nova na roleta?", o criador respondeu "Sim, roleta de novo". Depois de um game over, a roleta roda outra vez e o personagem ganha uma Nature nova.
2. **Respondido.** À pergunta "Personagem que já tem nature pula a roleta?", o criador respondeu "Sim, pula". Ao escolher um personagem que já tem Nature, a roleta não aparece e o jogo vai direto para a transição ao mundo.
3. **Respondido.** À pergunta "Os offsets individuais de atributo também ficam fixos com o personagem?", o criador respondeu "Sim, ficam fixos". Os offsets individuais (D-132) ficam com o personagem junto com a Nature.
4. Aliados e inimigos: de onde vem a Nature deles e quando muda.
5. **Respondido em parte.** À pergunta "Os rótulos que falam em nature 'da expedição' devem ser trocados?", o criador respondeu "Sim, trocar". Os rótulos "EXPEDITION NATURE (R18-Q4)" e "PURE DISCIPLINE (UNALTERED STAT BASELINE FOR THIS EXPEDITION)" serão trocados. À pergunta "Qual texto vai no topo da roleta?", o criador respondeu "NATURE ROLL": o rótulo do topo passa de "EXPEDITION NATURE (R18-Q4)" para "NATURE ROLL" (aplicado no protótipo HTML; o jogo ainda mostra o antigo). À pergunta "O rótulo das puras fica 'PURE DISCIPLINE (UNALTERED STAT BASELINE)'?", o criador respondeu "Só PURE DISCIPLINE": o rótulo de Hardy e Docile passa a ser apenas "PURE DISCIPLINE" (o protótipo HTML já usa esse texto; o jogo ainda mostra o antigo).

## Estado

Implementada em 2026-11-15 (memória, sem arquivo de save, que ainda não existe): `GameState.character_natures` guarda Nature e offsets por espécie; a roleta só abre depois da seleção (a do `EXPEDITION GATE` foi removida); personagem que já tem Nature pula a roleta; derrota (`end_battle(false)`) apaga a Nature do líder (assumi que derrota = game over). Pendente: Nature de aliados e inimigos (o criador disse que o aliado "tem a sua", sem dizer como é sorteada; hoje o aliado recebe uma das 8 iniciais ao ser criado e não copia mais a do líder). O rótulo do portão `EXPEDITION NATURE PREVIEW (R18-Q4)` no Hub 3D ainda existe.
