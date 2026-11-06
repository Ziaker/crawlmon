# D-343 — Rodada 85B: arquivos mecânicos e visuais próprios por Move, com sincronia verificável

- **Data:** 2026-11-06
- **Origem literal:** “Sigo suas recomendações porém, para fácil edição dos mesmos com pouco gasto de tokens, vão ser separados, cada um, em arquivos próprios? Ambos mecanicamente e visualmente? Pode garantir q a sincronia visual e mecânica vai se manter?”
- **Estado:** condicionante de editabilidade solicitado pelo criador e confirmado nesta resposta como requisito de arquitetura; implementação e mecanismo de sincronia pendentes.

## Regra de organização

- Cada Move terá **um arquivo de recurso mecânico próprio e um arquivo de recurso visual próprio**, distintos e vinculados por identidade estável do mesmo Move; componentes reutilizáveis podem continuar compartilhados.
- Os dois arquivos compõem **uma única ficha lógica** (D-333), sem criar dois Moves ou duplicar dados comuns. A edição do visual de um Move não deve obrigar editar a mecânica, e vice-versa, salvo alteração expressa que afete ambos.
- Não escolher agora caminhos, nomes, estrutura de pastas, nomes de classes ou representação da referência entre recursos.

## Sincronia: requisito, não resultado alegado

- A futura engine deverá manter correspondência **verificável** entre gatilhos visuais e os marcos mecânicos aprovados, sem duas cronologias conflitantes, e sem que VFX modifiquem regras mecânicas.
- Ainda não foi escolhida a **fonte autoritativa de tempo**, API de eventos, estratégia de validação de referências, comportamento diante de arquivo visual ausente, tolerâncias ou ferramentas de teste. Esses pontos exigem decisões futuras.
- Antes de declarar um Move concluído, exigir evidência de testes de vínculo, sincronismo/ordem/tempo, interrupções e variantes, além de atacantes/anatomias/lados distintos (D-235/D-342).
- **Não é possível garantir sincronia já implementada ou ausência absoluta de bugs** antes do desenvolvimento e dos testes. Esta é uma obrigação de aceitação a ser verificada, não uma afirmação sobre o runtime atual.

## Escopo

- Compatível com D-235, D-333–D-334, D-337–D-338 e D-339–D-342. Não constitui autorização para alterar código, gerar `Resource`, modificar VFX, testar Godot ou migrar Moves.
