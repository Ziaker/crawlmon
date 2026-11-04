# D-253 — Rodada 80 Q4 (4A): matriz aprovada abrange status simultâneos e status já ativos de Moves distintos

- **Data:** 2026-11-04.
- **Área:** Combate / status / incompatibilidades / matriz de prioridades.
- **Origem:** escolha 4A expressa do criador na Rodada 80.
- **Estado:** abrangência da política aprovada; **pares incompatíveis, prioridades concretas e matriz preenchida seguem pendentes**; não implementado.

## Declaração literal do criador

> 4A — Aplicar a matriz de prioridades aprovada tanto a conflitos simultâneos quanto ao conflito entre um status já ativo e outro aplicado depois por Move diferente.

## Regra aprovada

- A **matriz explícita de prioridades por pares de status expressamente declarados incompatíveis** (D-239/D-243), **uma vez preenchida e aprovada pelo criador**, deverá reger **ambas** as situações:
  1. **Conflitos simultâneos** entre status produzidos por **Moves diferentes**;
  2. **Conflitos temporais** em que **um status já esteja ativo** e **outro status incompatível seja aplicado posteriormente por um Move diferente**.
- A matriz de pares aprovada usa a **identidade dos status**, sem inventar prioridade pela ordem de chegada, pelo ID dos Moves, pela espécie, pelo atacante ou pelo lado do campo (D-235). **Não aplicar uma matriz ainda não aprovada como se tivesse vencedores definidos.**
- **Exemplo exclusivamente abstrato:** o Move A aplicou `Status X` e, depois, o Move B tenta aplicar `Status Y`; supondo que **uma matriz futura aprovada** declare X/Y incompatíveis e estabeleça uma precedência, essa matriz também se aplica ao conflito entre o status já ativo e o novo. **O exemplo não homologa o par, a incompatibilidade, a precedência, uma remoção nem a aplicação de Y**.
- Preservar D-215/D-217 para prioridade expressa **dentro da mesma ficha** de Move; D-213/D-210 para ordem e limites de tentativas; D-219/D-223/D-227/D-234 para **consumo de RNG** e elegibilidade; D-095 para resultado de KO simultâneo. **A ordem de RNG não determina prioridade entre efeitos.**

## Pendências e escopo

- **Não há nenhuma entrada concreta aprovada da matriz**, nenhum par de status real homologado como incompatível, nenhum vencedor definido. Permanecem sem aprovação o **tratamento operacional do status de menor prioridade** (remoção, não aplicação, supressão, duração/renovação), a relação com prioridade expressa em fichas isoladas quando aplicável, e como agir quando a matriz não contém uma entrada necessária.
- Não extrapolar a abrangência aprovada para conflitos dentro do **mesmo Move** ou outras categorias de efeitos sem decisões específicas.
- Somente documentação; nenhum código, teste, status, Move, ficha, cena, asset ou VFX modificado.
