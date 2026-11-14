<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-969 — Electric: flipbooks de anel, estrela e fagulhas animadas

- **Data:** 2026-11-08.

## Frase literal do criador

> oque adicionaria no efeito com o flipbook? partículas de choque e outras coisas? instale

Resposta à proposta numerada: "1, 2 e 3".

## Decisão

1. **Anel elétrico no impacto:** `flipbook_lightning` em billboard no ponto de contato, cerca de 0,45 s, tingido de amarelo saturado.
2. **Estrela de impacto:** `flipbook_impact` por baixo do anel, mais curta (cerca de 0,25 s).
3. **Fagulhas animadas:** as faíscas simples dão lugar a fagulhas que tocam um flipbook curto enquanto voam; saem no impacto e soltas em volta da esfera no wind-up.

Os flipbooks seguem o relógio do próprio efeito (não tweens), para valer em teste e em combate. Tamanhos em metros fixos (D-308 item 6). Nada depende de personagem, time ou lado (D-235).

## Ambiguidades

- "Trocar as faíscas simples": as faíscas do Motion Composer (V1.11) deixam de ser desenhadas no feixe. Isso tensiona D-308 ("construir sobre o Composer"); o principal à mão é permitido por D-954. **Criador deve confirmar** se as faíscas do Composer saem mesmo ou ficam junto.
- Itens 4 e 5 da proposta (pulso no disparo, fumaça no pós-impacto) **não** foram aprovados.

## Estado

Implementado para revisão em vídeo nas duas vistas.
