# D-157 — Rodada 62 Q1 (1A): cálculo de trajeto de Move instantâneo no início efetivo da execução

- **Data:** 2026-11-03
- **Área:** Combate / fases de ataque / duração do trajeto
- **Origem:** resposta expressa do criador, Rodada 62 Q1
- **Estado:** decisão de design aprovada; não implementada nesta atividade

## Declaração literal do criador

> 1A — Calcular imediatamente ao iniciar a execução efetiva do Move, sem criar WINDUP.

## Regra aprovada

- Para **Move instantâneo que dispense WINDUP** e tenha trajeto cuja duração precise ser calculada, fazer esse cálculo **no início efetivo da execução do Move**, sem acrescentar uma fase WINDUP artificial.
- Esse instante cumpre a função da captura inicial de tempo definida pela D-154 para ataques que **possuem** WINDUP, preservando a duração fixada até o fim do respectivo trajeto conforme D-148.
- Usar as regras de tempo por Move, AGI efetiva, referência de trajeto e passos aprovadas (D-119, D-133, D-136, D-140, D-160, D-018). Não aplicar este cálculo a Moves sem deslocamento por mera analogia.
- **Exemplo ilustrativo da questão:** um Move instantâneo entra em execução com AGI efetiva 50; caso exija deslocamento, é nesse instante que se captura o valor para calcular sua duração.

## Relações e pendências

- Não altera a duração dos projéteis em voo, ondas AoE, regras de Evade nem as condições de retarget **durante WINDUP** das D-108/D-155; um Move sem WINDUP não adquire automaticamente a janela de retarget dessa fase.
- Não define uma nova diferença temporal entre confirmação de comando e começo da execução efetiva, nem uma fase alternativa.
- Preserva o princípio de uma única linha do tempo da D-019.

## Escopo

Registro documental somente, sem código, cenas, testes, assets ou VFX.

## Conciliação posterior — Rodada 62, versão prevalente confirmada (2026-11-03)

**Estado atual: registro histórico da versão divergente.** Após a publicação desta D-157, o criador confirmou expressamente que **as cinco escolhas da outra versão da Rodada 62 prevalecem**. Para Moves **sem WINDUP e com TRAVEL**, a regra vigente agora é **D-165 (R62-Q4A)**: calcular a duração ao **entrar efetivamente em TRAVEL**, não fixar um marco diferente apenas por interpretação de “início da execução”. Esta nota não apaga a declaração histórica acima e não altera código.
