<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-119 — Rodada 54: tempo de deslocamento por Move, reduzido por AGI e seus aumentos

- **Data:** 2026-11-03
- **Origem:** esclarecimento direto do criador durante a Rodada 54.
- **Estado:** regra definida e registrada em documentação; sem implementação de código.

## Declaração literal do criador

> Tempo de deslocamento é uma variável própria dita na ficha dos moves também, ela é reduzida pela agi e efeitos que aumentam AGI. Voltamos as perguntas anteriores a minhas duas respostas

## Regra aprovada

- O **tempo de deslocamento do ataque é um parâmetro próprio de cada Move**, especificado na **ficha desse Move**; portanto, não se deve definir um único tempo-base universal para todos os ataques que envolvem deslocamento.
- A **AGI do Pokémon reduz esse tempo de deslocamento**. **Efeitos que aumentam AGI também reduzem esse tempo**. Isso complementa D-117, que estabelece os efeitos de AGI sobre preenchimento de ATB e velocidade nos trajetos de ataque.
- **Preservar D-018:** o posicionamento tático por passos (−2..+2), sua redução de 0,10 s por soma de passos e o mínimo histórico de 0,25 s continuam decisões anteriores. Não escolher por suposição a ordem matemática da aplicação de AGI e passos, nem substituir a fórmula antiga silenciosamente.
- A fala **não fixa curva, escala, fator percentual, mínimo específico novo, interação de debuffs negativos de AGI, tratamento para Moves sem trajeto ou velocidade de projéteis**, que continuam pendentes.
- O usuário pediu explicitamente **voltar às dez perguntas iniciais da Rodada 54**, mantendo suas correções sobre AGI e referência elemental SMT. Isso **não constitui aceitação prévia das alternativas do questionário**; manter as demais escolhas ainda sem resposta.

## Código consultado e divergência

- `scripts/data/skill.gd` possui atributos de custo, potência, elemento, tipo, AoE etc., mas **ainda não possui uma variável explícita de tempo de deslocamento por Move na ficha `Skill`**.
- `scripts/combat/attack_planner.gd` define tempos-base de corrida **por identificação de Move para alguns ataques** e chama `Battle.travel_seconds()`; `scripts/combat/battle.gd` aplica a correção posicional de D-018. Isso **não equivale ainda** à especificação uniforme do tempo na ficha de Move e não reduz duração com AGI.
- **Ação autorizada:** documentação somente. Nenhum arquivo de código, teste, VFX, modelo ou dado do jogo foi alterado.

## Complemento posterior — Rodada 55 (2026-11-03)

A decisão posterior **D-133 (R55-Q2, 2A)** especifica a **ordem**: (1) aplicar a redução decorrente de **AGI e efeitos que a aumentem** ao **tempo próprio da ficha do Move**; (2) aplicar a correção dos **passos posicionais D-018**; (3) respeitar o piso temporal de **0,25 s** já aprovado. Isso resolve apenas a ordem, **não** a função matemática de AGI ou sua calibração.

## Complemento posterior — Rodada 59 (2026-11-03)

**D-148 — Rodada 59, Q3A:** a duração do trajeto do Move, calculada com **AGI efetiva, buffs aplicáveis, tempo próprio do Move e passos táticos** conforme D-133/D-136/D-140, deve ser **determinada ao iniciar o ataque e preservada até o fim desse trajeto**. Uma mudança posterior de AGI durante esse trajeto **não recalcula a duração já fixada**. O usuário não definiu nesta resposta um novo instante técnico específico de gatilho entre declaração, WINDUP e início de TRAVEL; preservar a expressão 'ao iniciar o ataque' e não escolher um marco de implementação por suposição.
