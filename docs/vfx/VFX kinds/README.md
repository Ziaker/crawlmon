<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# VFX kinds — catálogo de tipos de efeito visual

Pasta criada a pedido do criador (2026-11-14) para catalogar **tipos** de VFX e permitir reproduzi-los sem tentativa e erro. Cada tipo tem **dois arquivos**:

- `<Nome>--visual.md`: o que se vê, em ordem, tamanhos, cores, tempo, o que o criador rejeitou.
- `<Nome>--codigo.md`: como foi feito (arquivos, funções, fórmulas, constantes, armadilhas, como testar).

O nome do efeito e o do Move onde ele aparece ficam no topo de cada arquivo. Valores marcados "criador" vieram das palavras dele; "IA" são escolhas técnicas que ele pode mudar.

## Índice

| Efeito | Move | Visual | Código |
|---|---|---|---|
| Corte de vento em faixa (Wind Slash Band) | Sand Attack (`tiro_areia`) | [visual](Corte-de-vento-em-faixa--visual.md) | [código](Corte-de-vento-em-faixa--codigo.md) |

## Para acrescentar um tipo novo

1. Crie os dois arquivos com o mesmo prefixo, com o bloco de 5 linhas de debug no topo.
2. Registre as frases literais do criador na decisão `D-xxx` do Move e cite o ID.
3. Liste o que **não** foi verificado (vista espelhada, outros atacantes, `--audit-leaks`, suíte de combate).
4. Acrescente a linha na tabela acima.
