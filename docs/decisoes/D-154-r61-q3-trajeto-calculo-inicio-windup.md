<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-154 — Rodada 61 Q3 (3A): fixar duração de trajeto na entrada efetiva em WINDUP

- **Data:** 2026-11-03.
- **Área:** Combate / timing / trajeto.
- **Origem:** escolha literal do criador na Rodada 61.
- **Estado:** decisão aprovada e registrada documentalmente; não implementada.

## Declaração literal do criador

> 3A — calcular ao entrar efetivamente no WINDUP.

## Regra aprovada

- A expressão **“ao iniciar o ataque”** da D-148 fica especificada tecnicamente como **o momento em que o ataque entra efetivamente na fase WINDUP**.
- Calcular nesse momento a duração do trajeto do Move a partir da ficha e da AGI efetiva aplicável, com redução inversa, ajuste de passos e piso temporal previstos por D-119/D-133/D-136/D-140/D-018.
- Após esse cálculo a duração fica **fixa até o fim do trajeto**, exceto por **recálculos autorizados durante WINDUP em trocas automáticas de alvo** (D-149 e D-155).
- Exemplo ilustrativo: AGI 40 na confirmação do Move, 50 ao começar WINDUP, 60 ao entrar em TRAVEL. O **cálculo inicial** usa AGI **50**. O aumento posterior para 60 não altera a duração fixada, salvo a exceção de troca de alvo aprovada.

## Limites

- Não confundir a **confirmação do Move** com a entrada efetiva em WINDUP.
- Não modificar a duração de projéteis em voo ou ondas AoE apenas por esta decisão.
- Uma ação instantânea que dispense WINDUP não recebeu nesta resposta uma regra específica de captura de duração; não inferir comportamento técnico novo.
- Os números das referências AGI para ATB e trajeto (D-145) continuam por definir.

## Escopo

Somente documentação. Nenhum arquivo de código, Move, cena, teste, VFX ou asset alterado.
