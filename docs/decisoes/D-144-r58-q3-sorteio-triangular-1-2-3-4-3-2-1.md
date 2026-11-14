<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-144 — Rodada 58 Q3 (A): Sorteio individual triangular com pesos 1:2:3:4:3:2:1

- **Data:** 2026-11-03
- **Área:** Personagens / atributos / combate / Rodada 58.
- **Proveniência:** escolha expressa do criador, aceitando a recomendação do assistente para esta questão.
- **Estado:** regra de design aprovada e documentada; não implementada.

## Declaração literal do criador

> 3A — Qual distribuição exata usar para o sorteio individual de −3 a +3? Distribuição triangular, com pesos 1:2:3:4:3:2:1. (recomendação aceita)

## Regra aprovada e compatibilidade

- - Para cada um dos seis atributos permanentes de um indivíduo, a variação inicial **inteira de −3 a +3** usa uma distribuição **triangular discreta** de pesos **1:2:3:4:3:2:1**, na ordem exata **−3, −2, −1, 0, +1, +2, +3**.
- - A soma dos pesos é 16. As probabilidades resultantes são **6,25%; 12,5%; 18,75%; 25%; 18,75%; 12,5%; 6,25%**, respectivamente. Esta conta deriva diretamente dos pesos aceitos; não é uma nova decisão independente.
- - Preservar D-132: o sorteio é feito **uma única vez por atributo/indivíduo e persistido**; a distribuição não deve ser refeita em cada combate ou subida de nível.
- - Preservar D-139: **não há teto permanente de 100**, e a variação não deve ser truncada por um limite máximo de 100.
- - O usuário não determinou se os sorteios entre atributos são independentes ou correlacionados, nem mecanismo de seeds/identificação persistente, portanto isso permanece pendente.

## Pendências e implementação

- **Ainda não definido:** Independência entre os sorteios de cada atributo, geração de seeds e estrutura de persistência.
- Esta atividade autoriza apenas atualizar documentos, não implementar código, testes, VFX ou fichas de Moves.

## Complemento posterior — Rodada 59 (2026-11-03)

**D-147 — Rodada 59, Q2A:** os sorteios das variações individuais dos **seis atributos** (STR, MAG, VIT, SPI, AGI, LUK) são **independentes entre si**. Cada atributo mantém o mesmo conjunto de resultados −3..+3, os pesos triangulares **1:2:3:4:3:2:1** e um sorteio individual único/persistente (D-132/D-144). Não impor correlação ou compensação entre atributos; a forma de seed e armazenamento permanece pendente.
