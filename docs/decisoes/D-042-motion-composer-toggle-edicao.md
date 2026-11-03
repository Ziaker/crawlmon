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
