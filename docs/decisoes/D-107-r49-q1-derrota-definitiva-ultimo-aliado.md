<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-107 — Rodada 49, Q1 (1A): derrota definitiva ao morrer o último aliado

- Data: 2026-11-03
- Origem: resposta expressa do criador.
- Estado: regra aprovada e registrada; não implementada nesta atividade.

## Declaração literal do criador

> 1A — Se o último aliado morrer, mas seu projétil ainda estiver voando, o que acontece? A derrota é definitiva quando Pikachu morre. A bola de energia não pode mais causar dano nem mudar o resultado.

## Regra aprovada

- Quando a **última unidade aliada** morre, a **derrota é definitiva imediatamente no KO**, mesmo que haja projéteis de sua equipe já lançados em voo.
- Após essa derrota definitiva, esses projéteis **não causam mais dano nem alteram o resultado**, em analogia à vitória definitiva pelo KO do último inimigo (D-105).
- **D-099 e D-100** ficam como histórico da regra de espera por projéteis, agora inaplicável após qualquer KO que elimine a última unidade de uma equipe (D-105/D-107).
- **D-095 e D-091 permanecem:** eliminação de ambas as equipes no **mesmo instante lógico** continua empate. A proibição aqui se refere a impacto de projétil **posterior** ao resultado já definitivo.
- **D-081 e D-090 permanecem:** fixar o resultado no KO não determina antecipar a apresentação da tela de resultado antes da sequência visual fatal.

## Limites

- Não foi definida a continuidade ou remoção **visual** de projéteis sem efeito após a batalha terminar.
- Esta decisão não modifica o comportamento de projéteis enquanto ainda há combatentes vivos nas duas equipes.
- Somente documentação; não alterou código, FX, dados nem testes.

