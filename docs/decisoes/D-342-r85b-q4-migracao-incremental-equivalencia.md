# D-342 — Rodada 85B Q4: migração incremental com equivalência validada

- **Data:** 2026-11-06
- **Origem literal:** “Sigo suas recomendações porém, para fácil edição dos mesmos com pouco gasto de tokens, vão ser separados, cada um, em arquivos próprios? Ambos mecanicamente e visualmente? Pode garantir q a sincronia visual e mecânica vai se manter?”
- **Escolha aprovada:** 4A — migrar Move por Move, preservando execução e visual existentes, com testes comparativos antes de substituir cada caminho antigo.
- **Decisão:** a adoção da engine será incremental; antes de substituir a execução de cada Move, confrontar custos, alvos, efeitos, condições, ordem, tempos, animações e VFX com as regras aprovadas. Diferença entre implementação legada e norma não deve ser resolvida unilateralmente: decisões D-xxx prevalecem (AGENTS.md/D-001).
- **Validação obrigatória:** seguir D-235 — outro atacante, lado espelhado e alvos de dimensões diferentes — e aferir a sincronia exigida na D-343.
- **Exemplo:** Tackle é apenas candidato hipotético a piloto, não escolhido.
- **Estado:** estratégia aprovada; nenhum Move migrado, nenhum teste executado, nenhuma alteração de código.
