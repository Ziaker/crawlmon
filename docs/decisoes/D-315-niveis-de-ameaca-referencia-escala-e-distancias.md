<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-315 — Níveis de ameaça: referência por soma dos níveis vivos, escala à equipe e distâncias

- **Data:** 2026-11-05
- **Área:** Exploração / IA
- **Origem:** Conversa (respostas Q2a, Q2b, Q3, Q4, Q5, Q6 e F3 do plano do overworld)

## O que o criador disse (literal)

- Q2a — referência: > o nivel dos personagens vivos no grupo se soma e subtrai contra o nivel do grupo do inimigo ou o nivel do inimigo sozinho (que normalmente é maior)
- Q2b — faixas: > define um valor melhor
- Q3 — nível dos inimigos: > Escalado à equipe
- F3 — escala: > Média da equipe + 1 a +4
- Q4 — distâncias/velocidades: > 3/6/9 tiles; 40/70/110/150
- F3 — Medroso: > 3 tiles; patrulha 42 px/s
- Q5 — tamanho/ícones: > Ver opções desenhadas antes
- Q6 — Medroso tocado: > Sim, batalha normal
- F3 — grupos: > os inimigos em grupo, também andam em grupo assim como o jogador, inimigos sozinhos andam sozinhos, soma da mesma forma que soma a do grupo do jogador

## Decisão

1. A ameaça do grupo é definida pela **soma dos níveis do grupo inimigo** (máx. 3 membros) comparada com a **soma dos níveis dos membros vivos da equipe**. Cada membro usa o **próprio nível** para o ícone e o tamanho. Ver D-321.
2. O nível de cada inimigo é **média da equipe + 1 a +4** (variação por inimigo, determinística pela seed).
3. Distâncias: **Fraco 3 tiles, Valente 6 tiles, Perigoso 9 tiles**. Velocidades: **Medroso 40, Fraco 70, Valente 110, Perigoso 150 px/s**.
4. O **Medroso** começa a fugir quando o grupo chega a **3 tiles**; patrulha a **42 px/s**.
5. O **Medroso**, quando tocado, inicia **batalha normal**.
6. Os **tamanhos e ícones** por nível serão escolhidos depois que o assistente desenhar opções.
7. As **faixas de diferença** foram delegadas ao assistente (“define um valor melhor”) e **confirmadas**: diferença percentual
   `diff = (soma_inimiga - soma_equipe) / soma_equipe`;
   `diff ≤ −0,40` Medroso; `−0,40 < diff ≤ −0,10` Fraco; `−0,10 < diff < +0,30` Valente; `diff ≥ +0,30` Perigoso.
   Isso equivale a razões 0,60 / 0,90 / 1,30.

## Ambiguidades em aberto

- Tamanhos e ícones ainda não escolhidos.
- O nível do inimigo é recalculado a cada entrada na cena (D-310: um inimigo forte pode virar fraco depois)?

## Estado no código

Não implementado. Detalha a D-310 e se relaciona com a D-321.
