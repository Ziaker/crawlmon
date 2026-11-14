<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-408 — Wind: Furacão Minimalista e Simples no Estilo Avatar (Air Nomad)

- **Data:** 2026-11-07
- **Área:** UI / Moves / Elementos / Combate / Regras
- **Origem:** decisão direta do criador rejeitando o excesso de detalhes dos furacões anteriores e exigindo simplicidade e minimalismo inspirados no símbolo de vento de *Avatar: The Last Airbender*.
- **Estado:** regra registrada; protótipos visuais atualizados; documentação oficial atualizada.

## Declaração literal do criador

> "tá extremamente detalhado esse furacão, faça 3 tipos de furacão, mas não exagere no design, é pra ser minimalista e simples,  pense na logo de vento de avatar"

## Regras aprovadas e diretrizes de revisão

1. **Rejeição do Excesso de Detalhes:**
   - Ficam proibidos quaisquer micro-sulcos, anéis empilhados finos, aletas serrilhadas ou floreios gráficos complexos. O glifo deve ser essencialmente simples, limpo e minimalista.

2. **Diretriz de Design Inspirada na Logo de Vento de Avatar:**
   - O símbolo dos Nômades do Ar (*Air Nomads*) de *Avatar: The Last Airbender* (composto por espirais fluidas, limpas e harmônicas de vento) torna-se a referência direta formal.
   - O elemento Wind deve evocar furacão através de curvas contínuas, fluidas e aerodinâmicas com alto impacto e zero ruído visual.
   - Manter o fundo oficial verde-menta `#4ff7ba` (D-403) com o glifo preto em alto contraste.

3. **Três Tipos Minimalistas de Furacão no Laboratório (`prototypes/icones_moves_lab.html`):**
   - **Opção 1 (Tríscele Avatar / 3 Espirais):** O símbolo autêntico dos Nômades do Ar de Avatar. Três espirais fluidas e contínuas de ar curvando harmoniosamente em vórtice circular.
   - **Opção 2 (Furacão Minimalista de 2 Braços / S-Swirl):** Símbolo clássico de furacão (🌀) simplificado ao extremo no traço fluido de Avatar: dois braços ciclônicos sweeping em torno de um olho circular central.
   - **Opção 3 (Ciclone Tríplice / Airbending Vortex):** Três correntes amplas de dobra de ar curvando em 360° em torno do olho central de tempestade, sem microdetalhes, pura silhueta sólida.

## Relação com decisões anteriores

- Estende e simplifica **D-407**, preservando o fundo `#4ff7ba` (D-403/D-404) e a paleta oficial dos demais 11 elementos ratificados.
