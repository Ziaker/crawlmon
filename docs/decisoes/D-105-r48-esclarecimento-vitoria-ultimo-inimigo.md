<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-105 — Esclarecimento R48-1A: vitória definitiva quando cai o último inimigo

- **Data:** 2026-11-03
- **Origem:** resposta direta do criador ao conflito da Rodada 48.
- **Estado:** decisão de design expressa; sem implementação de código.

## Declaração literal do criador

> 1A — A vitória é definitiva ao derrotar o último inimigo; o projétil não pode causar dano nem alterar o resultado.

## Regra aprovada e precedência

- Ao derrotar o **último inimigo presente**, o jogo determina a **vitória definitiva imediatamente no instante do KO**.
- **Projéteis já lançados e ainda em voo não podem causar dano nem alterar o resultado** após esse KO. Essa restrição cobre inclusive projéteis disparados pelo último inimigo antes de morrer.
- **D-099/D-100:** a espera para resolução de projéteis pendentes **não vale nessa hipótese específica de vitória por último inimigo derrotado**. Preservar as decisões anteriores como histórico e em outros casos não esclarecidos.
- **D-103:** quando restam outros inimigos, a batalha continua normalmente; um personagem no wind-up cujo alvo morreu troca de alvo e ainda pode ser atingido por projétil já lançado. Esta decisão não revoga isso.
- **D-081/D-090:** esta resposta determina **quando a vitória fica definitiva**, não necessariamente o instante em que a tela de resultado aparece. A apresentação visual continua conforme as regras de sequência fatal, a menos que o criador decida alterá-las.

## Limites e pendências

- Não foi definido se o projétil restante desaparece visualmente ou completa a trajetória sem efeito. Não inventar desaparecimento.
- Não extrapolar automaticamente o tratamento do último inimigo derrotado para a **última unidade da equipe do jogador**.
- A definição de como selecionar o próximo alvo no wind-up, se outros inimigos ainda existem, permanece aberta (D-103).
- **Escopo:** somente documentação. Nenhum código ou VFX alterado.

## Complemento posterior — Rodada 49

D-107: a regra de término definitivo foi estendida expressamente ao KO da última unidade aliada. Projéteis pendentes não causam dano nem mudam a vitória ou derrota depois que o resultado é fixado. Empate no mesmo instante lógico permanece conforme D-095.
