# D-159 — Rodada 62 Q3 (3A): eventos ordenados deterministicamente na mesma linha do tempo

- **Data:** 2026-11-03
- **Área:** Combate / simultaneidade / aplicação de LUK
- **Origem:** resposta expressa do criador, Rodada 62 Q3
- **Estado:** decisão de design aprovada; não implementada nesta atividade

## Declaração literal do criador

> 3A — Resolver os eventos segundo uma ordem determinística única da linha do tempo; alterações de LUK anteriores à rolagem valem, posteriores não.

## Regra aprovada

- A resolução de eventos obedece a **uma ordem determinística única da linha do tempo**, coerente com a arquitetura D-019.
- Uma modificação válida de **LUK** resolvida **antes** de determinada rolagem na ordem lógica entra no cálculo dessa rolagem; modificação resolvida **depois** não modifica a rolagem anterior nem a sua chance.
- A LUK usada é a do instante de resolução do evento probabilístico, conforme D-156. Não congelar LUK na declaração ou na fase WINDUP por esta escolha.
- **Exemplo ilustrativo da questão:** Abra recebe +10 LUK e é alvo de um crítico no mesmo instante lógico. Se o buff é processado antes da rolagem, usa-se a LUK modificada; se depois, usa-se a anterior. A escolha exige ordem determinística, **mas não fixou qual dos eventos deve vir primeiro**.

## Conciliação e pendências

- **Preservar D-095:** eliminações totais das duas equipes no mesmo instante lógico continuam sendo **empate**, mesmo quando resultem de ataques diferentes. Uma ordem técnica determinística não pode ser usada para revogar o resultado de empate já aprovado.
- A escolha **não define uma tabela de precedências** (buff antes de dano, identificador de evento, ordem de declaração etc.), granularidade exata de simultaneidade, nem ordenação de operações de impacto. Essas decisões permanecem pendentes.
- Preservar chances próprias de crítico, esquiva automática e status (D-150, D-152/D-153, D-146) e limites D-143/D-151.

## Escopo

Registro documental apenas. Nenhuma alteração de código, timeline, VFX ou testes.

## Conciliação posterior — Rodada 62, versão prevalente confirmada (2026-11-03)

**Estado atual: registro histórico da versão divergente, não ratificado como escolha vigente da Rodada 62.** O criador confirmou que, na Rodada 62 prevalente, **Q3B** determina **AGI mínima 1 exclusivamente no cálculo da regeneração ATB** (D-164). Esta confirmação **não aprova automaticamente** a regra distinta de ordenação fina de eventos descrita nesta D-159, cuja eventual adoção continua pendente. Regras aprovadas independentemente em D-019, D-095 e D-156 permanecem preservadas. Nenhum código foi alterado.
