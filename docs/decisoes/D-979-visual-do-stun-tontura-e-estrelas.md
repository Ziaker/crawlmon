<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-979 — Visual do STUN: tontura no modelo e estrelas acima da cabeça

- **Data:** 2026-11-08.

## Frase literal do criador

> agora uma questão visual sobre o stun, ele não possui efeito visual, eu to pensando em referenciar a forma como stun é visualmente no lol mas também quero representar no modelo do personagem o stun também, me diz o que pode causar no modelo do personagem para representar o stun, seja criativo e me de 3 opções

Escolha: **"opção 2"** (tontura com o corpo balançando), com a base proposta para qualquer opção: anel de estrelas girando acima da cabeça, como no LoL.

## Decisão

Enquanto um personagem estiver em STUN (qualquer causa, não só o Electric Beam):
1. **Anel de estrelas amarelas** girando acima da cabeça, preso ao topo medido do modelo real; some quando o STUN acaba.
2. **Tontura:** o corpo inteiro balança em círculo, inclinado de 8° a 12°; os "joelhos" cedem (modelo um pouco achatado e mais baixo); de vez em quando ele quase cai (inclinação maior e breve) e se recupera.
3. Ao fim do STUN, o modelo volta à pose e escala de antes, sem salto.

Status, não Move: fora do protocolo de VFX de Move (D-308). Nada depende de personagem, time ou lado (D-235): medidas vêm do modelo. Só visual.

## Estado

Implementado para revisão em vídeo nas duas vistas.
