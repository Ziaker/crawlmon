# D-957 — Rodada 90B Q1 (1A): validação dos Resources ao carregar e após alterações

- **Data:** 2026-11-06.
- **Área:** Engine de Moves / ciclo de vida / validação de Resources.
- **Origem:** resposta expressa do criador à Rodada 90B, questão 1.
- **Estado:** requisito de design aprovado; não implementado.

## Declaração literal do criador

> 1A — Validar os Resources mecânico e visual no carregamento e após alterações/recarregamentos, antes de disponibilizar a configuração à nova engine, invalidando resultados anteriores quando os dados mudarem.

## Regra aprovada

- A engine deverá **validar o par de Resources mecânico e visual do Move no carregamento**, e **novamente após alterações ou recarregamentos**, **antes de disponibilizar** a respectiva configuração à nova engine.
- **Se os dados mudarem, resultados anteriores da validação devem ser invalidados**, não servindo como prova de conformidade da nova configuração. A configuração alterada só pode ser disponibilizada após a validação pertinente.
- Preservar **D-339/D-343** (Resources tipados separados, uma ficha lógica), **D-349** (validar identidade, variantes e gatilhos), **D-955** (diagnóstico conjunto de problemas estruturais, sem autocorreções), **D-350** (não aprovar migração incompleta) e **D-376** (Move já migrado com visual obrigatório ausente/inválido fica indisponível na nova engine, sem fallback silencioso).
- **Exemplo ilustrativo:** após alterar o Resource visual de Fire Bullet, a engine não deve aceitar automaticamente a antiga validação do par, devendo reexaminar os vínculos com seus gatilhos mecânicos. O exemplo não cria ou altera um Move concreto.
- Preservar **D-235/AGENTS.md §7**: a validação não deve ser específica de espécie, personagem, lado ou posição.

## Limites e pendências

- **Não definidos:** ferramenta que identifica alterações, mecanismo técnico de cache/invalidação, momento de notificações, custo e abrangência da validação incremental, recuperação automática, como uma apresentação visual **já em andamento** reage a um recarregamento e infraestrutura de testes.
- Esta decisão **não autoriza parar/retomar execuções em andamento nem escolher implementação**, e não muda regras de consumo de oportunidade ou recursos.
- **Somente documentação; nenhum código, Resource, Move, teste, VFX, cena ou asset modificado.**
