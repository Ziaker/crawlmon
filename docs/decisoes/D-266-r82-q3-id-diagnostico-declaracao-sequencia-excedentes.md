# D-266 — Rodada 82 Q3 (3A): identificador diagnóstico separado dos índices de eventos válidos

- **Data:** 2026-11-04.
- **Área:** Combate / plano de eventos / violação de máximo / identificação reprodutível.
- **Origem:** decisão expressa do criador na Rodada 82.
- **Estado:** regra de identidade diagnóstica aprovada; representação e implementação pendentes.

## Declaração literal do criador

> 3A — Criar um identificador de diagnóstico separado dos índices válidos do plano, derivado da declaração e de uma sequência determinística das solicitações excedentes.

## Regra aprovada

- Toda **solicitação de ocorrência condicional excedente rejeitada** (D-242/D-252) deve ser identificável no registro de violação (**D-256**) por **identificador de diagnóstico separado dos índices de ocorrências válidas do plano**.
- O identificador deve ser **derivado da identidade estável da declaração do ataque e de uma sequência determinística das solicitações excedentes nessa declaração**, de modo que solicitações distintas possam ser distinguidas sem atribuir a elas índices válidos, sem reutilizar índices reservados e sem alterar os índices previamente fixados (D-218/D-222/D-226/D-233).
- **Exemplo abstrato, não formato de API ou esquema aprovado:** em uma declaração fictícia `D`, a primeira e a segunda solicitações excedentes podem receber referências de diagnóstico `D/excesso-1` e `D/excesso-2`. Esses rótulos **não são** ocorrências válidas de execução, não alteram a reserva de índices e não implicam gerar ou executar eventos extras.
- Preservar D-256: o **registro estruturado** continua identificando **Move, atacante, declaração, máximo aprovado e solicitação excedente**, usando identificadores estáveis. Preservar D-252: **rejeitar/registrar somente o excedente**, **manter eventos anteriores já resolvidos** e **continuar os eventos posteriores validamente planejados e elegíveis**. Nenhum sorteio de RNG é feito pela mera identificação diagnóstica.
- Preservar D-235: usar identidades reais de Move e atacante, sem depender de personagem, espécie, posição fixa ou lado.

## Pendências e escopo

- A decisão **não fixa a sintaxe do identificador, formato/armazenamento de log, origem do ID de declaração, tratamento de replay ou reinício do contador após rollback**, nem cria sequência global para a batalha. O requisito é a identidade derivada da **declaração + sequência determinística de excedentes**.
- Não foram definidos máximos concretos de ocorrências condicionais para nenhum Move nesta atividade.
- Apenas documentação; nenhum código, teste, sistema de logging, IA, Move, cena, asset ou VFX modificado.
