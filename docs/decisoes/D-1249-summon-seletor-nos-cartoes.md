<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** Nenhum teste pode levar mais de 1 minuto; crie o cenário/controle antes de testar; teste no debug, nas duas vistas (D-235). Ver `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1249 — Summon: formato do seletor (escolher nos cartões)

**Data:** 2026-11-16
**Área:** combate, UI, Summon
**Relacionadas:** D-1232, D-1236, D-1244.

## Resposta literal do criador

- Formato do seletor do Summon (opções: duas listas no leque, escolher nos cartões, tela de troca em pausa, manter placeholder): "Escolher nos cartões".

## Decisão

O seletor do Summon é feito nos cartões: o cursor percorre os cartões de aliados (quem sai); depois uma faixa de cartões dos substitutos (quem entra).

## Pendente (não decidido)

Layout da faixa de substitutos, destaque do cursor, como os nocauteados aparecem, texto de cabeçalho e de recusa, cores, animação, teclas de confirmar/cancelar, e se a troca congela a batalha.

## Estado

Decidida; **não implementada**. A cena usa o seletor provisório em listas (placeholder) até essas pendências serem respondidas.
