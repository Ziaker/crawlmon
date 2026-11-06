# D-339 — Rodada 85B Q1: fichas executáveis em Resources tipados

- **Data:** 2026-11-06
- **Origem literal:** “Sigo suas recomendações porém, para fácil edição dos mesmos com pouco gasto de tokens, vão ser separados, cada um, em arquivos próprios? Ambos mecanicamente e visualmente? Pode garantir q a sincronia visual e mecânica vai se manter?”
- **Escolha aprovada:** 1A — Resources tipados nativos do Godot para dados executáveis de Moves, com ID estável e validação.
- **Decisão:** projetar definições executáveis de Moves em `Resource` tipados, identificados por `move_id` estável e sujeitos à validação frente às regras documentadas. Não escolher sem autorização classes, esquema técnico ou caminhos.
- **Vínculos:** D-333 (uma ficha lógica por Move), D-235 (independência de personagem e lado) e D-343 (arquivos mecânico e visual separados).
- **Exemplo ilustrativo:** parâmetros mecânicos aprovados de Fire Bullet em seu recurso, ligados à mesma identidade do visual.
- **Estado:** arquitetura aprovada como requisito; nenhum código, recurso executável, ficha operacional ou teste criado. Engrenagem de carregamento e validador pendentes.
