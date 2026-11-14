<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-383 — Clima fora do Motion Composer; D-308 restrito ao VFX de combate

- **Data:** 2026-11-06
- **Área:** Exploração / visual / clima / VFX / processo
- **Origem:** resposta do criador ao conflito entre o clima 2D e o protocolo D-308.
- **Status:** decidido; documentação atualizada; neblina implementada (D-384).

## O que o criador disse (literal)

> não tem nada haver com o motion composer, nem sei pq ta levando ele em conta, pode ignorar ele e atualize os docs que mandam sempre levar ele em conta, na verdade ele é um problema. use as skills do godot que instalei em vc para melhor implementação do sistema e até melhorias que pode propor usando elas

## Decisão

1. **Clima/exploração não usa o Motion Composer.** Névoa, calor ondulado, chuva/neve com respingo e distorção temporal são camadas 2D de ambiente; não têm wind-up/release/trajeto/impacto de Move, não usam `MotionEffect`/`MotionRep` e não precisam de vídeo normal+espelhado de batalha.
2. **D-308 e o protocolo de VFX passam a valer para VFX de Move/elemento em combate.** A frase "qualquer efeito visual" do protocolo foi reduzida; era ela que obrigava o clima a entrar no Composer. Clima/exploração fica explicitamente fora.
3. **O Motion Composer é considerado um problema pelo criador.** Ele deixa de ser gate obrigatório para efeitos que não são de Move. O VFX de combate continua pausado por D-953/D-954; o clima não reabre esse pipeline.
4. **Implementação do clima:** usar as skills Godot instaladas (`scenario-godot-2d`, `scenario-godot-shaders`, `scenario-godot-vfx`, `scenario-godot-expert`) para a melhor implementação e para propor melhorias. A ordem continua a de D-362: neblina → calor → chuva/neve → distorção temporal.
5. **Escopo visual de D-381/D-382 não muda:** só visual; 20% por andar (1 em 5); 20–40 s; mapa de biomas de D-362; nada de regra.
6. **O que não é decisão:** apagar o Motion Composer ou o histórico dele. O Composer e as decisões D-953/D-954 continuam registrados; apenas não são mais obrigatórios para clima/exploração.

## Ambiguidades

- Se o criador quiser **apagar** o Motion Composer do projeto, isso é uma decisão separada; esta decisão só remove a obrigatoriedade para clima/exploração.
- A lista de exemplos do protocolo ("HUD animado", "protótipo") não é um contrato à parte; o protocolo fica restrito a **VFX de Move/elemento em combate**.

## Estado

Documentação atualizada: D-308, `docs/vfx/PROTOCOLO_VFX_OBRIGATORIO.md`, `docs/vfx/MOTION_COMPOSER_V1.md`, D-362, D-381, D-382, `AGENTS.md`, índice e `docs/REGRAS_DO_JOGO.md`. Neblina (D-384), chuva (D-386) e calor (D-387) implementados; neve/cinza/distorção pendentes. Nada publicado.
