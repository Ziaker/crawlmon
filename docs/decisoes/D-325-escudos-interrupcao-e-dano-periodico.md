# D-325 — Escudos: interrupção condicional e dano periódico

- **Data:** 2026-11-05.
- **Área:** Combate / escudos / DoT / interrupção.
- **Origem:** respostas diretas do criador à auditoria de Bubble Shield.
- **Estado:** requisitos expressos aprovados; interação exata com status ainda pendente.

## Declarações literais do criador

> Escudo bloqueia 100% do dano O golpe ainda pode interromper ou aplicar status? Se tiver no efeito descrito q não interrompe seus moves enquanto estiver ativo, então não.

> Burn ou Poison causam dano Esse dano também consome a proteção? Sim

## Regras expressas

1. **Anti-interrupção é propriedade expressa do efeito:** quando a descrição de um efeito disser que os Moves do portador **não são interrompidos enquanto o efeito estiver ativo**, preservar seus Moves de interrupções nesse período. **Não atribuir essa proteção automaticamente a todo escudo** só porque ele absorveu 100% do dano.
2. **Dano ao longo do tempo consome escudo:** dano de **Burn** e **Poison** também deve diminuir as reservas defensivas de escudo que sejam elegíveis para absorvê-lo, respeitando a prioridade de camadas da D-324.

## Pendências e limites

- A resposta sobre anti-interrupção **não homologou imunidade automática à aplicação de status** quando o escudo absorve todo o dano. Diferenciar dano absorvido, acerto, interrupção e aplicação de status.
- A fórmula, a tipagem e a ordem exatas de consumo por tipos de DoT ainda não estão definidas além da prioridade expressa D-324. Não criar isenções de Burn/Poison.
- Se um efeito futuro permitir anti-interrupção, essa propriedade depende da descrição desse efeito; a ficha inicial de Bubble Shield (D-323) não a declara.
- Preservar regras anteriores de esquiva, crítico, mitigação, dano mínimo, sobrevivência e status, sem reinterpretar escudo como invulnerabilidade.

## Escopo

Registro documental conforme D-061; nenhuma implementação, alteração em batalha, VFX ou testes.
