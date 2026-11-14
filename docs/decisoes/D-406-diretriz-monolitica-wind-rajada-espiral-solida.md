<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-406 — Diretriz Visual de Wind: Silhueta Sólida Monolítica em Rajada / Chicote Espiral

- **Data:** 2026-11-07
- **Área:** UI / Moves / Elementos / Combate / Regras
- **Origem:** decisão direta do criador em resposta ao questionamento de alinhamento de direção visual.
- **Estado:** regra registrada; protótipos visuais atualizados; documentação oficial atualizada.

## Declaração literal do criador

> A1: (Recommended) Uma silhueta sólida única de rajada em chicote/espiral (sem várias linhas soltas finas, mantendo o peso monolítico dos outros 11 elementos)

## Regras aprovadas

1. **Diretriz de Design para o Glifo de Wind (Fundo `#4ff7ba`):**
   - **Monolítico e Sólido:** Fica expressamente proibido o uso de linhas finas soltas, correntes múltiplas desconectadas ou elementos fatiados dispersos. O glifo deve ser uma peça visual sólida e unificada.
   - **Peso e Equilíbrio Visual:** Deve ter peso, densidade e presença visual idênticos aos outros 11 elementos oficiais já aprovados (a gota d'água de Water, a labareda de Fire, o relâmpago de Electric, o sigilo de Mystic).
   - **Motivo Visual:** Uma rajada de vento encorpada, contínua e dinâmica que se fecha ou se enrola em chicote/espiral aerodinâmica, com corte limpo e arestas nítidas.

2. **Três Novas Variantes Monolíticas no Laboratório:**
   - **Variante 1 (Chicote Eólico Sólido — Wind Whip):** Uma rajada arqueada contínua e encorpada que sobe com velocidade e se enrola num caracol espiral sólido no topo.
   - **Variante 2 (Tufão Monolítico em Vórtice — Cyclone Swirl):** Uma espiral contínua em formato de vórtice de furacão estilizado com corpo maciço e recortes geométricos limpos.
   - **Variante 3 (Lâmina de Vendaval em Foice — Gale Scythe Crest):** Uma lâmina crescente contínua e encorpada de ar cortante com rabo afilado e gancho aerodinâmico de descompressão.

## Relação com decisões anteriores

- Estende **D-397**, **D-398**, **D-403** e **D-404**, resolvendo a causa-raiz da rejeição das versões anteriores de Wind através da padronização de silhueta monolítica.
