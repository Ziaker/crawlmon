# D-961 — Rodada 91B Q1 (1A): preservar a receita visual validada durante a execução

- **Data:** 2026-11-07.
- **Área:** Engine de Moves / execução visual / alterações e recarregamentos de Resources.
- **Origem:** o criador respondeu **“Tudo A continue”** ao formulário da Rodada 91B, aprovando expressamente as quatro alternativas A.
- **Estado:** requisito aprovado; **não implementado nem testado**.

## Declaração literal

> Tudo A continue

## Alternativa 1A aprovada (texto apresentado ao criador)

> Preservar a receita visual validada já associada à execução em andamento até seu encerramento; uma nova versão validada só entra em novas execuções. Recursos perdidos durante a execução geram diagnóstico, sem inventar fallback.

## Regra aprovada

- Cada execução de Move **preserva até seu encerramento a receita visual validada que já lhe estava associada**. Alterar ou recarregar posteriormente o Resource visual **não substitui a receita de execuções em andamento**.
- A **nova versão** da receita visual só pode servir a **novas execuções**, **após ser validada** de acordo com D-349, D-955 e D-957. A configuração mecânica da execução permanece fixa conforme D-958, sem eliminar a consulta dinâmica dos combatentes nos instantes definidos.
- **Recursos visuais perdidos durante uma execução em andamento devem gerar diagnóstico explícito**, sem fallback visual inventado ou silencioso. A regra não promete que se possa materializar uma receita cujo recurso necessário não esteja mais disponível.
- Preservar D-376: **Move já migrado** com Resource visual obrigatório ausente/inválido fica indisponível na engine **para novas execuções** até correção. Preservar D-348/D-351 (autoridade mecânica e testes), D-235 (mesma execução visual para qualquer atacante/lado) e D-343 (arquivo mecânico e visual próprios por Move).
- **Exemplo não normativo:** se Fire Bullet já iniciou e seu Resource visual for atualizado, o ataque iniciado continua associado à versão visual validada anterior; o arquivo atualizado só será utilizado em novas execuções quando válido. Não aprova mudanças nos números, fases, visual ou mecânica desse Move.

## Limites e pendências

- A escolha **não define** cache, imutabilidade/cópia do visual, retenção de referências, como tratar a **impossibilidade material** de continuar a receita visual por recurso perdido, descarte de VFX após o término ou política de memória. Não inventar interrupção mecânica nem fallback.
- **Somente documentação; nenhum código, Move, Resource executável, VFX, cena ou teste alterado.**
