<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1285 — Cascos: moedas separadas, chances de drop e classificação comercial

- **Data** — 2026-11-17
- **Área** — Economia / moedas / drops / loja do Hub
- **Estado** — Regras aprovadas pelo criador em mensagem de chat. Implementação parcial; preços, bronze, elegibilidade e destino dos ganhos seguem pendentes.
- **Relacionadas** — [D-1250](D-1250-hub-loja-e-economia-de-expedicao.md), [D-1251](D-1251-moedas-exploracao-e-economia-inicial.md), [D-1252](D-1252-cascos-de-bronze-prata-e-ouro.md), [D-1253](D-1253-saldo-comum-e-balanceamento-dos-cascos.md), [D-1259](D-1259-cascos-fisica-brilho-e-coleta-para-teste.md).

## Frase literal do criador

> Saldo inicial zero.
> Saldos separados, com denominações obrigatórias para suas categorias.
> Sem conversão automática entre moedas para efetuar compras.
> Saldos consolidados protegidos.
> Ouro de combate explicitamente permitido.
> Não reduzir as chances de ouro para tentar limitar os ganhos.
>
> Silver: `7 + LUK_do_lider` por cento.
> Golden: `3 + LUK_do_lider / 2` por cento.
> Cada ponto de LUK acrescenta 1 ponto percentual à prata e 0,5 ponto percentual ao ouro.
> A probabilidade pode conter meio ponto percentual. Não arredondar a LUK nem a probabilidade indevidamente.
>
> - Bronze: itens básicos de HP, MP, ATB e buffs consumíveis em combate.
> - Silver: aumentos flat de atributos e itens com dois efeitos independentes.
> - Golden: equipamentos com efeitos únicos e itens com três efeitos independentes.
>
> A equivalência histórica 1:5:30 não autoriza conversão comercial.

(Origem: mensagem do criador em 2026-11-17 com o título "Implementação auditada da economia dos Cascos".)

## Decisão

1. Três moedas com **saldos separados**, saldo inicial 0 em cada uma. Cada categoria comercial só se paga com a sua moeda; não há conversão automática.
2. Chance por inimigo derrotado: prata = `7 + LUK_do_líder` %; ouro = `3 + LUK_do_líder / 2` %. Sem arredondar LUK nem probabilidade.
3. Ouro pode cair em combate; as chances de ouro não são reduzidas para limitar ganhos.
4. Classificação comercial: Bronze (HP, MP, ATB e buffs consumíveis básicos), Silver (aumentos flat de atributos e itens de dois efeitos independentes), Golden (equipamentos de efeito único e itens de três efeitos independentes).
5. Saldos já consolidados são protegidos.

## Precedência sobre decisões anteriores (ambas preservadas)

- Sobre [D-1253](D-1253-saldo-comum-e-balanceamento-dos-cascos.md) itens 1: "denominações de um saldo comum com equivalências fixas" é substituído por saldos separados sem conversão. Os demais itens da D-1253 (exploração rende mais, primeira compra sem prata, mochila do Hub chega à expedição, saldo consolidado protegido) continuam valendo.
- Sobre [D-1252](D-1252-cascos-de-bronze-prata-e-ouro.md): "Golden shells exclusivos de recompensas" é ampliado, pois ouro de combate foi permitido.

## Pendências (não implementar)

- Taxa de Bronze: a recomendação 50% (normal) e 70% (elite) não aparece em nenhum documento do repositório; falta confirmar a aprovação e definir o que é "elite".
- Se moedas diferentes podem cair juntas; instante do sorteio e da concessão; elegibilidade de vitória, fuga, recrutamento, chefes e líder incapacitado ou trocado.
- Preços e disponibilidade de todos os itens; contrato mecânico dos itens sem efeito implementado.
- Destino dos ganhos em derrota/retirada, instante de consolidação, arredondamento de perda parcial.
- Destino do `GameState.shell_balance` (saldo único já existente) frente aos saldos separados.
