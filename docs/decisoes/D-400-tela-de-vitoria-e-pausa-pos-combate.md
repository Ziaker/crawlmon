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
