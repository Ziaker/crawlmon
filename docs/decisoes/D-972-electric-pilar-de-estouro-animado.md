<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-972 — Electric: pilar de estouro de choque animado (impacto maior e mais longo)

- **Data:** 2026-11-08.

## Frase literal do criador

> mas não parece que nada mudou no impacto, estes são os próximos itens? eu quero mais vfx

> veja as referências, é um pilar de extouro de choques, nao apenas meshs de raio rodando, é uma animação completa, Impacto maior e mais longo

## Referência conferida

Persona 5 Royal, Zio (`PEFYE4pyb7c`, 151,6–152,1 s): coluna amarela sólida, núcleo branco e borda laranja, bate no alvo com um clarão no chão (151,72) → a coluna se parte em riscos e solta faíscas para os lados pela base (151,9–152,0) → sobram faíscas soltas e o brilho apaga (152,1).

## Decisão

O pilar do impacto vira uma animação completa nessa ordem, envolvendo o alvo até um pouco acima dele (D-970):
1. **Batida:** coluna sólida brilhante (núcleo branco, borda dourada/laranja) sobe rápido em volta do alvo, com clarão em disco no chão e anéis de choque se abrindo.
2. **Sustentação:** a coluna tremula e pulsa.
3. **Quebra:** a coluna afina e se parte em riscos em zigue-zague, soltando faíscas para os lados pela base.
4. **Dissipação:** sobram faíscas soltas e o brilho apaga.

Impacto **maior e mais longo**: cerca de 1,2 s (antes 0,7 s); anel e estrela maiores.

## Estado

Implementado para revisão em vídeo nas duas vistas.
