# D-206 — Rodada 71 Q3 (3A): IDs crescentes, sem renumeração ou reutilização, para entrada posterior

- **Data:** 2026-11-04.
- **Área:** Combate / IDs estáveis / entrada posterior e reprodutibilidade.
- **Origem:** escolha expressa do criador, Rodada 71.
- **Estado:** regra de identificação aprovada, não implementada nesta atividade.

## Declaração literal do criador

> 3A — Atribuir ao novo participante o próximo ID disponível, sem renumerar ou reutilizar IDs anteriores.

## Regra aprovada

- **Se um novo combatente vier a participar de uma batalha já iniciada**, atribuir-lhe **o próximo identificador ainda não utilizado naquela batalha**, prosseguindo a sequência crescente existente. **Não renumerar os combatentes anteriores e não reutilizar IDs previamente atribuídos**, mesmo quando o portador saiu de combate ou morreu.
- Preservar **D-196** (IDs únicos/estáveis por batalha) e **D-200** (sequência inicial por slots da equipe do protagonista, depois slots da equipe inimiga). A regra de novos participantes vale **somente depois de encerrada a atribuição da composição inicial**.
- **Exemplo ilustrativo, sem fixar valor inicial oficial:** participantes com IDs 1, 2 e 3 iniciam o confronto. O ID 2 deixa a batalha; um **novo** participante que ingressa recebe o **ID 4**, nunca o ID 2. O exemplo não autoriza nem define mecânica de reforços.
- Preservar **D-188/D-192**: IDs servem à ordenação dos candidatos e dos eventos simultâneos de retarget; não selecionam automaticamente o alvo sorteado. **D-095** preserva empate por eliminação simultânea.

## Limites e pendências

- Esta regra **não aprova que reforços, substituições ou entradas tardias existam no jogo principal**; somente define como identificar novos participantes **se** forem autorizados.
- Não determina o que acontece quando **o mesmo combatente** sai e retorna à batalha, a representação do ID, o valor inicial absoluto, a forma de registrar/reproduzir entradas em replay nem a ordem de processamento de entradas exatamente simultâneas.
- Somente documentação; nenhum código, cena, teste, sistema de spawn, ficha ou VFX alterado.
