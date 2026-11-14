<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-116 — Delegação das recomendações futuras sobre comportamento da IA

- **Data:** 2026-11-03
- **Área:** Processo de decisões / IA do combate
- **Origem:** declaração expressa do criador.
- **Estado:** autorização de escolha de recomendações sobre IA; **não é autorização de implementação**.

## Declaração literal do criador

> sigo suas recomendacoes quanto a forma que a IA deve agir, ate mesmo para as proximas perguntas

## Alcance da delegação

- O criador declarou que seguirá as **recomendações do assistente quanto à forma como a IA deve agir, inclusive em perguntas futuras**. O assistente pode, portanto, recomendar e consolidar decisões de **comportamento da IA** sem repetir rodadas de múltipla escolha desnecessárias para cada detalhe, **desde que ancore cada recomendação concreta no código e nas decisões vigentes**.
- Registrar cada nova regra concreta aprovada por essa delegação em um documento individual D-*, no índice e nas regras consolidadas conforme D-061, com a **proveniência correta**: recomendação do assistente aceita por delegação, **não** uma letra ou frase escolhida individualmente pelo criador.
- **Não** usar esta delegação para alterar mecânicas de jogadores, conteúdo, regras não relacionadas à IA, arquitetura, efeitos visuais, dependências ou código sem autorização específica.
- **Não substituir** decisões anteriores por critérios novos em caso de conflito material: tornar o conflito explícito e pedir orientação quando a delegação não for suficiente para conciliá-lo.
- Não interpretar delegação como licença para inventar regras de comportamento ausentes do jogo ou aprovar antecipadamente hipóteses ainda não formuladas.

## Estado e limites

- Nesta atividade, a delegação cobre as recomendações formuladas para as duas perguntas da **Rodada 53** (D-114 e D-115). Regras futuras devem ser identificadas e registradas concretamente quando houver uma proposta fundamentada; não existe implementação automática nem trabalho em background.
- Nenhum código do Crawlmon foi modificado por este registro.
