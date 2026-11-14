<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-042 — Motion Composer: toggle de edição durante a reprodução

- **Data:** 2026-11-03
- **Área:** Motion Composer / laboratório / especificação
- **Origem:** Conversa

## O que o criador disse (literal)

> um toggle entre ambos

Resposta à escolha entre atualizar no mesmo instante reconstruindo os rastros com o novo valor e reiniciar a animação desde o nascimento ao alterar um parâmetro.

## Decisão

O laboratório do Motion Composer V1 terá um toggle entre dois modos de edição:

1. **Atualizar no instante atual:** manter o instante da prévia e reconstruir os rastros com os novos parâmetros.
2. **Reiniciar:** recomeçar a animação desde o nascimento com os novos parâmetros.

O histórico não deve misturar silenciosamente resultados de configurações diferentes. Esta decisão resolve a escolha dos modos de P-03/P-10 da especificação enviada pelo criador; não autoriza implementação ou integração ao combate. D-019 permanece em vigor.

## Ambiguidades em aberto

- Modo inicialmente selecionado e persistência da preferência ainda não definidos.
- As demais pendências técnicas e artísticas da especificação continuam abertas.

## Estado

Registrado na especificação por esta decisão. Toggle ainda não implementado nem validado em execução.
