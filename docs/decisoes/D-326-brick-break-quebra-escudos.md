# D-326 — Brick Break também quebra escudos

- **Data:** 2026-11-05.
- **Área:** Moves / combate / remoção de escudos.
- **Origem:** resposta direta do criador à auditoria de Bubble Shield.
- **Estado:** extensão de design expressamente aprovada; execução e interações exatas não implementadas.

## Declaração literal do criador

> Dispel Quais efeitos podem remover o Bubble Shield? Brick break quebra escudos também como dito no efeito (agora que escudos existem)

## Regra expressa

- **Brick Break quebra escudos**, incluindo o escudo do Bubble Shield, conforme a descrição do próprio efeito mencionada pelo criador.
- O escopo aqui é a capacidade de ruptura/remoção de escudos; não atribuir números adicionais, efeitos de remoção a outros Moves, anulação universal de defesa, ou novas condições por inferência.
- Preservar o restante da ficha e das regras de Brick Break, sem alterá-las por esta documentação.

## Pendências

- Conferir a descrição operacional exata de Brick Break antes de implementar; a pesquisa nesta atividade localizou o Move no registro histórico D-032, mas **não confirmou uma especificação completa do efeito de ruptura de escudos** no código consultado.
- Não foi expressamente determinado se um único uso remove **todas** as reservas, apenas uma reserva, escudos de certos tipos ou apenas a reserva atingida; não definir isso silenciosamente.
- Ordem de dano de Brick Break versus ruptura e possíveis efeitos de contato permanecem subordinados às regras existentes e a especificação do Move que vier a ser confirmada.

## Relações

D-032, D-061, D-247, D-249, D-262, D-323, D-324, D-325.

## Escopo

Apenas decisão documental. Nenhum arquivo de código, animação, shader, VFX ou teste modificado.
