<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1232 — SUMMON (Convocação): troca de aliados por 2 ATB

**Data:** 2026-11-15  
**Área:** combate, UI/HUD  
**Estado:** **implementada na Fase 8 (D-1244, D-1249, D-1254); o item 1 (custo de 2 ATB) foi SUPERADO pela D-1254**, em que o criador disse "remova o custo de atb, o intervalo de 4s e o bastante, nao e mais necessario este custo para invocacao". Os itens 2 a 4 continuam valendo.  
**Origem:** briefing "IMPLEMENTAÇÃO FASEADA DE EMPLOY, SUMMON E RESPEITO" colado pelo criador.  
**Relacionadas:** D-1229, D-1233, D-033, D-107, D-235, D-1011, D-161, D-162.

## Texto literal do briefing do criador

> "A ação `SUMMON` fica na mesma aba alternativa de `TACTICS` que contém `EMPLOY`. Custo: 2 ATB. O protagonista emite a ordem e paga o custo, quando estiver apto a comandar. Não substituir automaticamente esse custo por Burst."

> "É permitido substituir aliados saudáveis. É permitido substituir aliados nocauteados. O jogador escolhe quem entra e quem sai. Nenhum substituto entra automaticamente quando alguém sofre K.O. A troca não recupera HP ou MP. Estados individuais devem ser preservados. A batalha termina em derrota quando todos os ativos estiverem incapacitados, sem resgate automático por substitutos."

> "Um inimigo que aceita Employ passa ao elenco do jogador. Ele pode participar do combate atual, mas sua entrada deve ocorrer por meio da ação de Convocação, respeitando seu custo. Não introduzir entrada automática gratuita."

## Decisão

1. Summon custa **2 ATB**, pagos pelo protagonista em ATB de verdade.
2. Troca aliado saudável ou nocauteado; o jogador escolhe quem entra e quem sai; sem entrada automática, sem cura, estados preservados.
3. Derrota quando todos os ativos estiverem incapacitados, mesmo havendo substitutos.
4. Recrutado por Employ só entra no combate atual via Summon.

## Pendências declaradas pelo criador

- Comando quando o protagonista está nocauteado; interrupções; ações em trânsito; ATB de quem entra; posicionamento; efeitos temporários.

## Conflitos e pendências achados na auditoria (perguntar)

- **GDD R30-Q5/R24-Q3 (`REGRAS_DO_JOGO.md` §14.3):** "Recrutado entra na equipe ativa se houver vaga (máx. 3); senão vai para a reserva." O briefing diz que a entrada é só por Convocação.
- **Protagonista substituível?** O briefing não diz se o próprio protagonista pode sair.
- **Fila D-161 e ações de quem sai:** não definido.
- **Código:** não existe reserva nem troca em combate; a cena tem 3 `PARTY_SLOTS` fixos (`battle_scene.gd:12`) e nenhum caminho de saída/entrada de lutador fora o debug (`battle_scene.gd:439-458`).

## Estado no código

Nada implementado.
