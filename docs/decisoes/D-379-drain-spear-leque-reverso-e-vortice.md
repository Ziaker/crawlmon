<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-379 — Drain Spear: leque reverso do Badge Steal, partículas junto das badges e vórtice helicoidal da estocada

- **Data:** 2026-11-06.
- **Área:** VFX / Motion Composer.
- **Origem:** correção pedida pelo criador depois de assistir aos vídeos.
- **Estado:** implementado; aguardando aprovação visual.
- **Escopo:** protótipo visual.

## Frases literais do criador

> "já percebi que o impacto de direção oposta não está presente e nem o movimento de particulas brilhantes que se movem até o jogador junto dos badges está ausente, algo que havia nos HTMLs, corrija isso imediatamente"

> "alias adiciona um boost burst visual heliocondal em vortice drill apenas durante o início da estocada com duração de.6 segundos (onde após.4 já começa a sumir lentamente com opacidade) e giro similar a de um ventilador."

## Decisão

1. **Badge Steal com impacto de direção oposta.** O leque do impacto precisa existir também no sentido **alvo → atacante**, não só o sifão fraco. O Badge Steal passa a ter:
 - **streaks reversos** em leque (M16 com cone de 24°, 76 partículas, tamanho 0,42, rastro longo) saindo do contato e convergindo no atacante (M06), com fade após 0,30 s;
 - **orbs brilhantes** (34 partículas, tamanho 0,58, sem esticar) viajando **junto das badges** das 2,13 s às 2,43 s e continuando até ~2,52 s;
 - **coroas/orbitas** no atacante e uma **órbita espiral**;
 - **impacto reverso no atacante** (halo + anel de choque + luz) quando a energia chega, 0,30 s depois do contato.
2. **Vórtice helicoidal da estocada (boost burst).**
 - Só no **início da estocada** (a partir de 1,8 s), com **duração total de 0,6 s**.
 - **Após 0,4 s** começa a desaparecer lentamente por opacidade, sumindo por volta de 0,58 s.
 - **Giro de ventilador** (4,2 voltas/s), 10 faixas helicoidais cônicas em volta da frente da lança (raio 0,72 m na base do vórtice → 0,10 m na ponta), com um burst de 28 faíscas no início.
 - A lança, o cabo e a lâmina continuam independentes; o vórtice não decide acerto nem dano (D-235).

## Onde vive

- `MotionPresets.drain_spear_effect`: fases `steal` (6 camadas) e `drill` (2 camadas).
- `MotionMesh.helix_band` com `radius_end` (cone).
- `MotionPainter.vortex_band` e `MotionPainter.aura_band`.
- `MotionRep` `"vortex"` e `"aura"`.
- `shaders/mc_aura_band.gdshader` (reaproveitado pelo vórtice).
- `scripts/debug/drain_spear_lab.gd`: desenha `drill` de 1,8 s a 2,4 s.

## Relações

D-235, D-308, D-061.
