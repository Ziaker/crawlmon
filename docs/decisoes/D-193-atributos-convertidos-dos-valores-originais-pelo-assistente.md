# D-193 — Atributos vêm da conversão dos valores originais dos personagens, criada pelo assistente

- **Data:** 2026-11-04
- **Área:** Personagens / atributos
- **Origem:** decisão direta do criador, na conversa.
- **Estado:** regra registrada; a conversão proposta está em `docs/PROPOSTA_ATRIBUTOS_NIVEL_XP.md`; **sem implementação**.

## Declaração literal do criador

> e pra converter os valores originais dos personagens nos atributos do jogo, seja uma conversao criada por vc nao por mim

## Regra aprovada

- Os atributos-base de cada espécie no jogo saem da **conversão dos valores originais** da espécie (HP, Attack, Defense, Sp. Atk, Sp. Def, Speed).
- A **conversão é criada pelo assistente**, não pelo criador. O criador não fornece os números nem a fórmula de conversão.
- O **HP** também é convertido do HP original da espécie. O MP não tem valor original, então sai da Magia e do nível. Sem número-alvo: a D-192 não impõe limite de 10.
- Compatível com D-120 (referência biológica com balanceamento próprio do jogo) e D-192 (sem valores exorbitantes em níveis baixos; o "10" não é regra).

## Ambiguidades em aberto (perguntar antes de agir)

- Se a conversão criada pelo assistente precisa de aprovação do criador antes de entrar no código. A regra acima delega a criação; a proposta é apresentada, e nada é implementado sem o criador dizer para seguir.
- Conflito a decidir: a conversão fiel da Speed original (Abra 90, Pancham 43, Gible 42) muda o ritmo do ATB de hoje, e a D-126 pede preservar esse ritmo. A proposta escolhe preservar o ritmo e registra o desvio da referência biológica.
- Fonte dos valores originais: não há ficha de estatísticas no repositório; a proposta usa os valores oficiais conhecidos e indica que não foram conferidos contra uma fonte do projeto.

## Estado no código

Nenhuma alteração.
