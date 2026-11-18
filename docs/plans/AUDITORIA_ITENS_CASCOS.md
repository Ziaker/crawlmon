<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# Auditoria dos itens existentes para a loja dos Cascos (2026-11-17)

Fonte: `scripts/data/item.gd` (catálogo), `Battle.use_item()` (`scripts/combat/battle.gd:510`), `scripts/ui/menus.gd:228` (uso no campo), `GameState.INITIAL_INVENTORY`. Regras: [D-1285](../decisoes/D-1285-cascos-economia-moedas-separadas-e-chances-de-drop.md). **Nenhuma classificação abaixo é aprovada item a item, e nenhum preço existe.** A coluna "Categoria" só indica onde a regra geral de D-1285 poderia encaixar o item.

| ID interno | Nome exibido | Efeito declarado | Efeito implementado | Efeitos independentes | Categoria (regra D-1285) | Preço | Disponibilidade |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `potion` | POTION | Restaura 30 HP | **Sim**: `use_item` e menu do campo aplicam `heal = 30` | 1 | Bronze (HP básico), a confirmar | 10 Bronze (D-1309) | Hub, sempre |
| `super_potion` | SUPER POTION | Restaura 60 HP | **Sim**: `heal = 60` | 1 | Bronze (HP básico), a confirmar | 25 Bronze (D-1309) | Hub, sempre |
| `revive` | REVIVE | Revive membro caído com 50% do HP máx. | **Não**: `heal = 0` e `use_item` exige ator vivo; não há lógica de revive | 1 | Bronze (HP), a confirmar | pendente | **bloqueado: sem implementação** |
| `sitrus_berry` | SITRUS BERRY | Restaura 25% do HP máx. quando crítico | **Não**: sem gatilho "crítico", `heal = 0` | 1 (com gatilho) | Bronze (HP), a confirmar | pendente | **bloqueado: sem implementação** |
| `lum_berry` | LUM BERRY | Remove todos os status (Stun, Burn, Freeze) | **Não**: nenhum caminho de uso | 1 | Bronze (cura de status), a confirmar | pendente | **bloqueado: sem implementação** |
| `elixir` | MAX ETHER | Restaura 20 MP | **Não**: `use_item` só faz `target.heal(item.heal)` (HP) | 1 | Bronze (MP básico) | pendente | **bloqueado: sem implementação** |
| `amulet` | AMULET | Proteção passiva (texto genérico) | **Não**: slot `held_item_id` existe, nenhum bônus lido | indefinido | Golden (equipamento), a confirmar | pendente | **bloqueado: sem contrato mecânico** |
| `charm` | TALISMAN | Bônus passivo (texto genérico) | **Não**: idem | indefinido | Golden (equipamento), a confirmar | pendente | **bloqueado: sem contrato mecânico** |

## Conclusões

- Só `potion` e `super_potion` funcionam. Os outros seis não podem ser oferecidos como compra funcional.
- Nenhum item atual tem dois ou três efeitos independentes, então Silver (itens de dois efeitos) e Golden (itens de três efeitos) **não têm itens existentes**. Não fabriquei nenhum.
- Itens `HELD` (`amulet`, `charm`) não contam para a capacidade da mochila (R35-Q3) e vêm do kit inicial.
- A busca por `revive`, `elixir`, `sitrus` e `lum_berry` em `scripts/` só achou o catálogo e a lista de inventário de teste de `status_screen.gd:149-152`.

## Decisões necessárias antes de oferecer qualquer item

1. Quais itens entram na primeira loja, com o preço de cada um e em qual moeda.
2. Contrato mecânico de `revive`, `sitrus_berry`, `lum_berry`, `elixir`, `amulet` e `charm` (o que fazem, quando disparam, alvo).
3. Se `potion` e `super_potion` são oferecidas já.
