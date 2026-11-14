<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-978 — Electric: impacto menor e mais curto; versão atual só quando há STUN

- **Data:** 2026-11-08.

## Frase literal do criador

> mudança nova no efeito visual do contato, agora é pra ser 0.25x menor 0.35x mais rapido na sua duração da coroa para sumir (adicione um efeito de opacidade gradual), PORÉM, caso causar Stun efetivamente, ela continua com a mesma duração e tamanho atual, sendo tratado como um efeito alternativo de impacto baseado no acionamento de seu efeito de stun.

Respostas: **25% menor** (75% do tamanho); **35% mais curta** (65% do tempo); **tudo acelera**, inclusive a saída de dentro do inimigo.

## Decisão

1. **Contato sem STUN:** o pilar de coroas fica com 75% do tamanho e 65% da duração (saída 0,25 → 0,1625 s; vida 1,0 → 0,65 s), com opacidade que cai gradualmente até sumir.
2. **Contato com STUN (D-977):** impacto alternativo = o pilar atual (D-973/D-974/D-975), tamanho e duração iguais.
3. O efeito lê o resultado do acerto do combate (`stun`); só visual, não muda a regra.
4. O Slime passa a ter o Electric Beam (pedido anterior do criador: "dê o move pro slime").

## Estado

Implementado para revisão em vídeo.
