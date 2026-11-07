# D-958 — Rodada 90B Q2 (2A): configuração mecânica fixada na declaração com estado de combatentes dinâmico

- **Data:** 2026-11-06.
- **Área:** Engine de Moves / execução mecânica / variantes / consistência temporal.
- **Origem:** resposta expressa do criador à Rodada 90B, questão 2.
- **Estado:** contrato aprovado; não implementado.

## Declaração literal do criador

> 2A — Fixar na declaração a configuração mecânica resolvida do Move e sua variante, preservando-a durante aquela execução; consultar dinamicamente o estado dos combatentes nos instantes mecânicos definidos.

## Regra aprovada

- **Ao declarar a ação**, fixar para **aquela execução** a **configuração mecânica resolvida do Move**, inclusive **sua variante**. Essa configuração não se altera durante a execução, mesmo que uma definição editável do Move seja atualizada posteriormente.
- **Não congelar na declaração todos os estados dos combatentes**: suas condições, atributos e mudanças relevantes devem ser consultados **dinamicamente nos instantes mecânicos definidos** para os efeitos aplicáveis.
- Integrar **D-360/D-373/D-953** (variante resolve apenas diferenças explícitas e ordenadas), **D-348** (plano mecânico autoritativo), **D-954** (condições avaliadas no instante do respectivo efeito), **D-226** (reserva de ocorrências condicionais na declaração) e regras antigas sobre AGI, trajeto e cálculo quando iniciado, sem reavaliar tempos cujo congelamento já tenha sido aprovado.
- **Exemplo ilustrativo:** Splitter Flames declarado com variante de dois alvos conserva os parâmetros daquela execução; alterações posteriores da ficha não modificam retroativamente sua configuração, mas eventos reais como morte, interrupção e mudança de atributos dos participantes continuam regidos pelos momentos mecânicos correspondentes. Não aprova novo comportamento de retarget.
- **D-235** continua obrigatória: nenhum estado é derivado de personagem, time, lado ou câmera fixos. D-957 rege validação de versões posteriores, sem implicar mudança na configuração mecânica já fixada.

## Limites e pendências

- **Não escolhidos:** representação técnica de configuração congelada, cópia ou referência imutável, vínculo com versão do esquema, política para atualizações **visuais** durante execução, ciclo de vida de participantes removidos, tamanho do snapshot e gerenciamento de memória.
- Nenhuma mudança de fórmula, chance, custo, prioridade ou relógio mecânico é autorizada.
- **Somente documentação; nenhum código, Resource, Move, VFX, teste ou cena modificado.**
