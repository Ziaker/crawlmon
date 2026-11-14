<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-106 — Esclarecimento R48-2A: Evade faz o golpe errar, sem interrupção mecânica

- **Data:** 2026-11-03
- **Origem:** resposta direta do criador ao conflito da Rodada 48.
- **Estado:** decisão de design expressa; sem implementação de código.

## Declaração literal do criador

> 2A — Os ataques desviados terminam como golpes que erraram, sem interrupção mecânica adicional.

## Regra aprovada e precedência

- Quando um personagem faz um **Evade bem-sucedido**, os ataques evitados **terminam como golpes que erraram**, **sem interrupção mecânica adicional** e **sem animação de interrupção/cambaleio causada pelo Evade**.
- Em dois ataques simultâneos evitados pela mesma esquiva, **ambos** podem completar suas animações de golpe sem acertar (D-092, D-104). Isso **não** concede dois contra-ataques extras: preservar D-093 e decisões posteriores.
- **D-017:** a descrição histórica de ataque interrompido instantaneamente com cambaleio pelo Evade foi **superada especificamente nesse aspecto** por esta decisão; não eliminar outras regras aprovadas de Burst, contra-ataque e comportamento visual que permaneçam compatíveis.
- **D-104:** a expressão anterior de 'interrompidos após terminarem visualmente' foi esclarecida: são **golpes concluídos como erros**, **não** uma interrupção lógica posterior.
- **Interrupção por receber um ataque:** continua sendo situação distinta quando o atacante é atingido durante o **wind-up** ou o **trajeto** de seu ataque; não confundir com esquivar de um golpe.

## Limites e pendências

- Não foram definidos novos frames, duração ou janelas de Evade. Preservar as regras existentes de tempo e cobrança.
- Não inferir que um golpe evitado produz stagger, cancelamento adicional, dano ou nova ação automática.
- **Escopo:** somente documentação. Nenhum código ou VFX alterado.
