# D-332 — Rodada 83B Q2 (2A): ficha do personagem lista Moves aprendíveis, fontes e requisitos conhecidos

- **Data:** 2026-11-06.
- **Área:** Fichas de personagens / aprendizado de Moves / documentação.
- **Origem:** decisão expressa da Rodada 83B.
- **Estado:** campos documentais aprovados; tabelas concretas e implementação pendentes.

## Declaração literal do criador

> 2A — Registrar na ficha do personagem os Moves que pode aprender, a fonte de aprendizado e os requisitos conhecidos, separando isso da biblioteca individual dos Moves já aprendidos.

## Regra aprovada

- A **ficha de referência do personagem/espécie ou forma** deverá **registrar os Moves que podem ser aprendidos** e, para cada possibilidade documentada, **a fonte de aprendizado** e os **requisitos conhecidos**.
- **Separar claramente o catálogo do que pode aprender** da **biblioteca individual de Moves efetivamente aprendidos** de cada personagem. Uma possibilidade de aprendizado **não equivale** a possuir o Move nem a tê-lo equipado.
- Preservar **D-275**: cada personagem conserva os Moves aprendidos, com **até oito equipados** para combate e mudanças restritas a locais seguros de preparação ou entre expedições, mantendo Tackle separado; esta decisão **não altera** limites, fontes existentes ou regras de equipamento.
- **Exemplo exclusivamente ilustrativo, não conteúdo aprovado:** uma ficha poderia mencionar um Move com fonte “progressão de nível” e outro com fonte “mestre”, cada um acompanhado dos requisitos **quando estes forem definidos e verificados**. O exemplo não atribui Moves ou níveis a uma espécie real.
- **Conciliar com D-235:** o registro de **como uma espécie aprende** um Move **não autoriza implementar a execução desse Move condicionada a nome, espécie, modelo, equipe ou lado**. A execução/visual do Move continua genérica, baseada em `move_id` e no atacante/alvo reais.
- Integrar o procedimento à **estrutura vinculada de fichas de espécie e forma** da D-331 sem presumir que todas as formas têm o mesmo conjunto de aprendizado; vínculos não determinam herança automática de aprendizados.

## Pendências e limites

- Nenhuma lista concreta de Moves por espécie, nível, tutor, item, missão, fonte ou requisito foi homologada nesta rodada; **requisito não informado deve permanecer pendente**, não ser preenchido por suposição.
- Não foram definidos campos técnicos, formato da tabela, acesso de UI, repetição ou deduplicação de fontes, regras de aprendizado retroativo, persistência ou mudanças durante evolução.
- Documentação somente; nenhum código, Move operacional, ficha individual, teste, cena, VFX ou asset modificado.
