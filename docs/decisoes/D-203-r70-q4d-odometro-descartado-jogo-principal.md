# D-203 — Rodada 70 Q4D: descartar odômetro de HP do jogo principal

- **Data:** 2026-11-04.
- **Área:** Combate / escopo do jogo principal / histórico do protótipo.
- **Origem:** escolha 4D e regra própria expressa do criador na Rodada 70.
- **Estado:** **revogação expressa de requisito para o jogo principal**, aprovada documentalmente; a remoção técnica do protótipo não foi autorizada nem executada.

## Declaração literal do criador

> 4D — Outra regra.

> Observações e regras próprias: o odometro era só um teste, não usaremos ele no jogo principal, descarte toda e qualquer ideia que o envolva

## Regra aprovada e precedência histórica

- O **odômetro de HP / HP rolante estilo Mother 3 / EarthBound foi apenas um teste** e **não será utilizado no jogo principal de Crawlmon**.
- **Descartar do planejamento e dos requisitos vigentes do jogo principal toda ideia que dependa do odômetro**: animação de contagem progressiva, janela tática por HP rolante, regras de sobrevivência dependentes do HP visual rolante, cura em reversão da contagem, toggle e SFX específicos do odômetro. Esta enumeração esclarece o escopo do descarte, **não instrui a excluir arquivos ou alterar código nesta rodada**.
- A declaração atual **supera para o jogo principal** a decisão histórica **`D-048-rolling-hp-mother3-odometro.md`**, mantendo esse documento íntegro como registro do **teste/protótipo antigo**. **Há também uma D-048 de recompensas AoE** (`D-048-r40-q8-atb-aoe-unico.md`), que **não tem relação com HP rolante e permanece válida**.
- Preservar a D-199: status condicionado ao acerto só pode atingir alvo que sobreviva ao dano. Esta decisão **não escolhe por si uma nova política de aferição de sobrevivência no runtime** além de retirar o odômetro da consideração; não selecionar silenciosamente a alternativa 4A, 4B ou 4C da pergunta anterior, pois o criador escolheu **4D**.
- Exemplo: um golpe derrota o inimigo de forma válida; sua sobrevivência para fins de status **não deve depender de odômetro ou de contagem rolante**. O momento exato de avaliação dos eventos simultâneos e de sobrevivência permanece regido por outras decisões ou pendente, sem criar mecanismo novo.

## Limites e estado técnico

- A `main` consultada contém `rolling_hp_enabled`, `target_hp`, `rolling_hp`, `tick_rolling_hp` em `scripts/combat/combatant.gd` e um teste `tests/battle/test_d048_rolling_hp.gd`. **A presença desses arquivos reflete o protótipo anterior, não autorização para usar essa mecânica no produto principal.**
- **Nenhum código foi removido, desativado ou modificado nesta atividade documental.** Se houver pedido posterior de implementação, será necessária uma alteração técnica delimitada que preserve demais sistemas.
- Não inferir uma nova mecânica de HP ou status a partir de 4D. A questão original sobre referência de sobrevivência não recebeu uma nova fórmula/alternativa positiva e não deve ser preenchida por suposição.
