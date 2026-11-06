# D-340 — Rodada 85B Q2: interpretador genérico dos efeitos de Moves

- **Data:** 2026-11-06
- **Origem literal:** “Sigo suas recomendações porém, para fácil edição dos mesmos com pouco gasto de tokens, vão ser separados, cada um, em arquivos próprios? Ambos mecanicamente e visualmente? Pode garantir q a sincronia visual e mecânica vai se manter?”
- **Escolha aprovada:** 2A — interpretar efeitos declarativos, ordenados na ficha, com componentes reutilizáveis e extensões específicas apenas quando necessárias e aprovadas.
- **Decisão:** a engine deverá interpretar dados mecânicos declarativos do Move na ordem aprovada; danos, status, cura, escudos e outros efeitos devem reutilizar contratos compartilhados. Exceções particulares requerem aprovação, sem codificar uma rotina exclusiva por Move como padrão.
- **Compatibilidades:** preservar decisões D-244–D-249, D-258–D-263, D-323–D-326 e regras de custos, status, escudos, alvos e tempo sem modificá-las. A execução mecânica não deve depender de VFX, espécie ou lado (D-235/D-341).
- **Exemplo:** Fire Bullet e Bubble Shield podem usar efeitos declarados distintos, sem inventar números ou comportamento.
- **Estado:** direção arquitetural aprovada; operadores, API, schema, implementações e testes pendentes. Não houve alteração de código.
