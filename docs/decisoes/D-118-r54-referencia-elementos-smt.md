<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-118 — Rodada 54: elementos do Crawlmon inspirados principalmente em Shin Megami Tensei

- **Data:** 2026-11-03
- **Origem:** correção expressa do criador durante o questionário da Rodada 54.
- **Estado:** regra de referência conceitual definida, apenas documentada; Rodada 54 não foi aprovada integralmente.

## Declaração literal do criador

> Quanto aos elementos, são baseados mais em shin megami tensei que pokémon

## Regra definida

- O **sistema de elementos do Crawlmon se baseia mais em Shin Megami Tensei do que em Pokémon**. A referência principal para construir/avaliar os elementos e sua identidade é SMT; Pokémon não deve ser imposto como modelo principal de tipos, conversões ou fraquezas.
- A declaração **não** ordena cópia literal de uma tabela específica de SMT, **não** define nova tabela de fraquezas, resistências, imunidades ou afinidades por espécie e **não** renomeia nem remove categorias existentes.
- Preservar o `Element.Type` atual (`FISICO`, `FOGO`, `AGUA_GELO`, `RAIO`, `PSIQUICO`, `VENENO`, `SOM`, `TERRA`, `VENTO`, `LUZ`, `TREVAS`) e as fraquezas já cadastradas até receber definição específica que autorize alterá-las.
- **Rodada 54, pergunta 9:** a recomendação anterior, que usava tipos Pokémon como referência para gerar fraquezas, **deixa de representar corretamente a direção do criador**. A questão de como elaborar as fichas de afinidades por espécie continua em aberto, com SMT como referência principal.

## Estado verificado do código

- `scripts/data/element.gd` contém 11 categorias próprias do Crawlmon; `Combatant.weaknesses` armazena uma lista de elementos que causam fraqueza, sem catálogo global de afinidades de espécies.
- Nenhum código, dados, FX, testes ou tabela de fraquezas foi alterado nesta atividade.

