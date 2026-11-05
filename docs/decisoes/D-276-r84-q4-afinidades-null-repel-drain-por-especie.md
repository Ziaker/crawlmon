# D-276 — Rodada 84 reformulada Q4 (A): afinidades SMT incluem Null, Repel e Drain por espécie

- **Data:** 2026-11-05.
- **Área:** Combate / sistema elemental / afinidades por espécie.
- **Origem:** escolha expressa **A** da resposta literal do criador `C C C A` à Rodada 84 reformulada.
- **Estado:** categorias de afinidade aprovadas em design; fichas de espécies e implementação ainda não definidas.

## Pergunta e alternativa aprovada

**Pergunta:** "Até onde vão as afinidades elementais inspiradas em SMT?"

> A — Sistema completo: além de fraqueza e resistência, algumas espécies podem possuir **Null, Repel e Drain** — anulação, reflexão e absorção elemental.

**Resposta literal do criador:** `C C C A` (quarto **A**).

## Regra aprovada

- O sistema de afinidades elementais do Crawlmon, inspirado prioritariamente em **Shin Megami Tensei**, passa a **prever**, além de fraqueza e resistência, três **possibilidades de afinidade por espécie e por elemento**:
  - **Null:** anulação do ataque/dano do elemento correspondente, quando a afinidade for aplicável;
  - **Repel:** reflexão elemental do ataque correspondente, quando a afinidade for aplicável;
  - **Drain:** absorção elemental do ataque correspondente, quando a afinidade for aplicável.
- Essas categorias são **capacidades possíveis**, **não atribuídas automaticamente a todas as espécies** e **não homologadas para qualquer espécie/elemento concreto**. A distribuição das afinidades continua sujeita a design/decisão específica, como previsto em **D-128**.
- Esta escolha **autoriza expressamente estender as categorias conceituais de afinidade** além das existentes, complementando **D-118/D-128**. **Não substitui automaticamente os 11 elementos de `Element.Type` nem as fraquezas já cadastradas**, preservados até revisão específica. **D-194** mantém exceção ao mínimo de dano para imunidade/bloqueio completo.
- **Exemplo ilustrativo, não ficha aprovada:** espécies hipotéticas enfrentam um Move de fogo; uma pode ter fraqueza, outra Null, outra Repel e outra Drain. A aprovação é do **conjunto de interações possíveis**, não de alocação de qualquer efeito a espécies reais.
- Preservar **D-235**: um mesmo Move, equipado por quaisquer combatentes, de qualquer lado, deve interagir corretamente com as afinidades reais de atacante/alvo. Não criar lógica de afinidade baseada em nomes de personagens, times ou posições fixas.

## Pendências e limites

- Ainda não foram aprovadas **tabelas por espécie/elemento, multiplicadores, alvos/alcance/encadeamento da reflexão Repel, recurso e quantia recuperados por Drain, como ações AoE ou multi-hit interagem com Null/Repel/Drain, interação com status, crítico, fraqueza e recompensas de ATB/Burst**. Não inferir cópia integral de qualquer tabela de SMT.
- As definições conceituais **não garantem implementação** e não autorizam modificar o combate, assets ou fichas nesta rodada.
- Nenhum código, teste, Move, ficha, IA, UI, cena, asset ou VFX alterado; somente documentação.
