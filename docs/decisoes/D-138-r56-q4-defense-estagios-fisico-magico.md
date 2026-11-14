<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-138 — Rodada 56 Q4: Estágios de Defense afetam danos físicos e mágicos com VIT/SPI separados

- **Data:** 2026-11-03
- **Área:** Atributos e combate / Rodada 56.
- **Proveniência:** resposta **expressamente enviada** pelo criador, aceitando a alternativa previamente recomendada pelo assistente.
- **Estado:** decisão de design aprovada e documentada, sem implementação nesta atividade.

## Declaração literal da escolha do criador

> 4A — Como os buffs/debuffs de Defense devem funcionar com VIT e SPI separados? Manter os estágios atuais de Defense afetando dano físico e mágico, enquanto VIT e SPI fornecem resistências naturais separadas. (recomendação aceita)

## Regra aprovada e compatibilidades

- Os **estágios existentes de Defense** (buffs/debuffs como Rakukaja/Rakunda e equivalentes já aprovados) **afetam tanto o dano físico quanto o mágico**.
- As **resistências naturais** são calculadas **separadamente**: **Vitality (VIT)** protege contra **dano físico**, enquanto **Spirit (SPI)** protege contra **dano mágico/especial**, conforme D-130.
- Não criar por esta escolha classes novas de buffs de defesa física ou defesa mágica, nem separar ou renomear os Moves já existentes; manter os estágios e a simetria entre aliados/inimigos.
- **Código consultado:** `Combatant.take_damage()` em `scripts/combat/combatant.gd` atualmente aplica `def_buff` genericamente e **ainda não possui resistências VIT/SPI**. Esta decisão mantém a abrangência geral do buff ao adicionar futuramente duas resistências naturais.
- **Exemplo:** Rakunda aplicado em Gible reduz sua proteção por Defense tanto contra um soco físico de Pancham quanto contra um ataque mágico de Abra; o componente de resistência natural de cada dano usa VIT ou SPI.
- Não escolher silenciosamente uma ordem de mitigação, um multiplicador novo, uma curva de VIT/SPI nem como redimensionar o dano mínimo existente.

## Pormenores não definidos

- Ordem de aplicação Defense versus VIT/SPI, fórmulas numéricas, eventuais limites de mitigação e tratamento de resistências elementais já aprovadas.
- **Sem alteração de código, cenas, dados de personagens, fichas de Moves, VFX ou testes** nesta atividade.
