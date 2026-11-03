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

