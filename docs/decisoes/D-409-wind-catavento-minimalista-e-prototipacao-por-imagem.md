<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-409 — Wind: Catavento Minimalista (5 Opções em Imagem, Incluindo Perspectiva a 20°)

- **Data:** 2026-11-07
- **Área:** UI / Moves / Elementos / Combate / Regras
- **Origem:** decisão direta do criador direcionando a pesquisa visual de Wind para o conceito de catavento minimalista e proibindo alterações diretas no HTML durante a exploração.
- **Estado:** regra registrada; documentação atualizada; exploração visual conduzida exclusivamente via geração de imagens de exemplo.

## Declaração literal do criador

> "gere imagens de exemplo antes de ficar mexendo no código do html
> 
> quero 5 opções de cataventos minimalista, inclusive um com perspectiva inclinada em 20 graus"

## Regras aprovadas

1. **Protocolo de Prototipação Visual por Imagem:**
   - Durante fases exploratórias e rodadas de alinhamento estético, gerar exclusivamente imagens comparativas de exemplo (folha de contato em alta resolução), evitando edições repetidas em arquivos HTML extensos.
   - O HTML de laboratório só será atualizado após a aprovação formal da opção escolhida pelo criador.

2. **Diretriz de Design para Catavento Minimalista (Fundo `#4ff7ba`):**
   - Explorar 5 variantes distintas de catavento (*pinwheel* / moinho de vento eólico):
     - Silhuetas minimalistas, simples, com alto contraste e legibilidade imediata em múltiplas escalas (72px, 40px, 24px).
     - Obrigatoriamente incluir uma variante com **perspectiva dinâmica inclinada em 20 graus** (3D tilt / isometric-like slant).
     - Fundo oficial mantido em `#4ff7ba` com o glifo em preto sólido.

## Relação com decisões anteriores

- Estende **D-403**, **D-404**, **D-407** e **D-408**, aplicando a diretriz minimalista ao motivo visual de catavento com perspectiva tridimensional inclinada.
