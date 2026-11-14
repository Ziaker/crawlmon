<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-400 — Tela de vitória e pausa pós-combate

- **Data:** 2026-11-07
- **Área:** UI / Combate / Fluxo de Batalha
- **Origem:** Recomendações técnicas formuladas no Concepts Brief e aprovadas pelo criador na conversa.
- **Estado:** regra registrada; sem código.

## Declaração literal do criador

> "eu não tenho ideia de como mexer com estes valores, sigo suas recomendações"

## Regra aprovada

1. **Pausa e Desaceleração:**
   Ao derrotar o último inimigo da batalha, a cena de combate desacelera suavemente e é pausada antes de qualquer transição de saída.
2. **Painel de Vitória:**
   Abre-se um painel visual de vitória contendo:
   - Resumo da batalha com o total de XP obtido;
   - Barras de progresso de experiência animadas para cada integrante sobrevivente da equipe;
   - Alerta visual e sonoro de `LEVEL UP!` em destaque nos personagens que subirem de nível;
   - Lista de itens e espólios (loot) obtidos na luta.
3. **Confirmação do Jogador:**
   O combate não encerra abruptamente nem envia o jogador de volta ao 2D sem interação; o avanço requer confirmação explícita do jogador via tecla de confirmação (Z, Enter ou Botão A do gamepad).

## Ambiguidades em aberto (perguntar antes de agir)

- Formato visual exato dos cartões de espólio e efeitos de transição entre painéis.

## Estado no código

Nenhuma alteração.
