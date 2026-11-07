# D-965 — Rodada 92B Q1 (1A): ativação atômica do par de Resources validado

- **Data:** 2026-11-07.
- **Área:** Engine de Moves / ativação de configurações mecânicas e visuais.
- **Origem:** decisão expressa da Rodada 92B, questão 1.
- **Estado:** requisito aprovado; sem implementação ou testes.

## Declaração literal do criador

> 1A — Ativar mecanicamente e visualmente uma nova configuração como um par validado e consistente, substituindo atomicamente a versão anterior para novas execuções.

## Regra aprovada

- Uma **nova configuração de Move** deve ser disponibilizada como **um par consistente e validado** de Resource mecânico e Resource visual, **ativado atomicamente para novas execuções**.
- A ativação não pode expor uma mistura não validada de configurações mecânicas e visuais de versões diferentes. **Alterar apenas um arquivo** continua permitido: é o **par efetivo** resultante que deve ser validado e ativado como unidade.
- Preservar **D-343/D-349** (dois arquivos próprios do mesmo Move, identidade, variantes e gatilhos), **D-955/D-957** (rejeição de dados inválidos, invalidação/revalidação de configuração alterada), **D-958** (configuração mecânica fixada na declaração), **D-961** (execução já iniciada conserva receita visual validada) e **D-376** (Move já migrado com visual obrigatório inválido fica indisponível, sem fallback silencioso).
- **Exemplo ilustrativo:** se Fire Bullet receber alterações mecânicas e visuais relacionadas, a nova declaração só pode usar o par consistente após validação, sem combinar metades incompatíveis; nenhuma alteração concreta ao Move é aprovada.

## Pendências, compatibilidade e limites

- **Não definidos:** mecanismo técnico da troca atômica, simultaneidade de carregamentos, identificação de geração de configuração, armazenamento do par anterior e condições de recuperação quando a versão nova é inválida. A decisão **não autoriza fallback silencioso**, migração de Move ou modificação do código.
- **D-235/AGENTS.md §7** permanece obrigatória: ativação independente de atacante, espécie, equipe, câmera ou lado.
- **Somente documentação**: nenhum código, Resource executável, teste, VFX ou cena alterado.
