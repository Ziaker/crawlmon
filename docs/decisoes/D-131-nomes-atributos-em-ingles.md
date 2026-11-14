<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-131 — Nomes dos atributos em inglês e siglas oficiais de três letras

- **Data:** 2026-11-03
- **Área:** Nomenclatura de atributos / ficha de personagem / UI.
- **Proveniência:** o criador exigiu nomes de status em inglês e delegou ao assistente a escolha do nome e sigla para o novo atributo. Nomenclatura proposta pelo assistente, adotada neste registro em cumprimento ao pedido.
- **Estado:** nomenclatura definida em documentação; sem alteração de UI ou código.

## Declaração literal do criador

> Criamos um novo status relacionado a redução de dano mágico, que funciona exatamente como vitalidade. Agora vitalidade é apenas pra dano físico, Me escolha em nome em inglês que tenha uma abreviação de 3 letras boa, além disso todos nomes de status devem ser em inglês.

## Nomes oficiais para os seis atributos permanentes

| Nome de apresentação (inglês) | Sigla (3 letras) | Função definida |
|---|---|---|
| **Strength** | **STR** | Base ofensiva de dano físico (D-122) |
| **Magic** | **MAG** | Dano mágico/especial e efeitos escaláveis por Move; MP máximo segue sua regra (D-122/D-123) |
| **Vitality** | **VIT** | HP máximo (D-124) e mitigação de dano **somente físico** (D-130) |
| **Spirit** | **SPI** | Mitigação de dano **mágico/especial** (D-130) |
| **Agility** | **AGI** | Preenchimento natural de ATB e redução do tempo individual de deslocamento dos Moves (D-117/D-119) |
| **Luck** | **LUK** | Probabilidades de crítico, esquiva automática e aplicação de status (D-127) |

## Escopo da nomenclatura

- **Nomes de atributos/status numéricos da ficha e rótulos desses atributos na UI devem aparecer em inglês**, com as siglas de três letras desta tabela.
- Termos antigos em português nos **documentos históricos**, em comentários, citações literais e decisões anteriores **não devem ser reescritos** por esta instrução documental. Essa regra define a nomenclatura futura, não obriga alteração retroativa de textos preservados.
- O termo 'status' nesta decisão refere-se ao catálogo de **atributos do personagem**; não houve pedido inequívoco para renomear todos os efeitos, condições, Moves ou mensagens de combate, portanto o escopo não é ampliado silenciosamente.
- O novo conjunto de seis atributos amplia a inspiração histórica de cinco atributos baseada em SMT; não significa copiar um sexto atributo de SMT nem importar uma nova fórmula externa.

## Estado de implementação

- `scripts/combat/combatant.gd` não apresenta os seis atributos permanentes nem Spirit; a UI e as fichas não foram alteradas.
- As regras de dano, buffs, Natures, progressão, atributos 1–100 e escolhas anteriores continuam válidas salvo as revisões expressas de D-130.
- **Somente documentação**, sem modificar código, sprites, VFX ou testes.

