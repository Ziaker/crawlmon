<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1256 — Murky Forest autoral com as três referências visuais

- **Data** — 2026-11-16
- **Área** — Overworld 3D / level design / arte de ambiente
- **Estado** — Direção aprovada. Mapa e validação em jogo pendentes.
- **Relacionadas** — [D-1245](D-1245-murky-forest-level-design-medicao-e-gating.md), [D-1246](D-1246-murky-forest-destino-recorrente.md), [D-1247](D-1247-murky-forest-arco-e-persistencia.md), [D-1248](D-1248-murky-forest-gatilho-e-ordem.md).

## Frase literal do criador

> todas opcoes encaixam no mesmo mapa perfeitamente, so precisa ser corretamente adaptado para cada, todas sao boas e conversam entre si, o mapa nao e procedural e e construido do zero, entao nao havera problemas

## Decisão

1. A Murky Forest terá um único mapa 3D autoral, construído do zero e sem geração procedural. A decisão se aplica a este mapa.
2. As três pranchas revisadas são referências complementares do mesmo mapa. Aberturas na copa, vistas laterais e desnível cenográfico devem ser adaptados aos trechos em que funcionarem juntos. As imagens completas e as capturas do jogo são referências obrigatórias, conforme o [prompt de implementação visual](../plans/PROMPT_IMPLEMENTACAO_VISUAL_MURKY_FOREST.md).
3. Para o mapa novo, esta decisão substitui a exigência do primeiro recorte da D-1247 de manter a planta física existente. O cenário anterior continua como referência de identidade visual e dos papéis das salas. O arco continua como marco de revisita. Um desnível cenográfico é vista de fundo, e as decisões sobre passagem jogável inferior e posto de vigia permanecem nas respectivas etapas.

## Pendências

- Distribuição exata das três referências no percurso, planta, dimensões e transições entre trechos.
- Validação das vistas, da câmera e da navegação no blockout autoral.
