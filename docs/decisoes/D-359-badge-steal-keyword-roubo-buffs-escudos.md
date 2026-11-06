# D-359 — Keyword Badge Steal: roubo de buffs positivos e escudos

- **Data:** 2026-11-06.
- **Área:** Moves / efeitos / buffs / escudos / HUD.
- **Origem:** definição de Drain Spear, respostas DS1, confirmações DS2 e novo esclarecimento de nomenclatura.
- **Estado:** keyword e regras de roubo aprovadas para Drain Spear; implementação e casos-limite pendentes.

## Declarações literais do criador (trechos)

> Drain spear afeta todo e qualquer efeito positivo de buff ou escudo que o alvo atingido possui, os extraindo e tomando para o usuário do move, reiniciando sua duração efetiva. Porem apenas se houver o contato com sucesso
>
> 9 opcao A
>
> 10 , ele rouba o escudo antes de aplicar o dano, desde que o move tenha sido um sucesso
>
> 11 A
>
> 12A desde que o efeito permita ser stackado, caso nao, ele apenas reinicia no usuario do drain spear
>
> Crawlmon Drain Spear — confirmações: elemento A; mid-range A; badges A.
>
> Drain spear ao invés de usar o nome drain, use como keyword, "Badge Steal" sigo suas recomendações

## Nome e elegibilidade

- **Badge Steal** é a **keyword do efeito de roubo** da Drain Spear; **não é o nome do Move** e **não é** a afinidade elemental **Drain** da D-352.
- **Elegibilidade confirmada (badges A):** roubar **somente buffs positivos e escudos representados por badge** no alvo. **Não roubar debuffs negativos**, mesmo que também tenham badge. A badge exprime um efeito mecânico elegível; não autoriza roubar automaticamente elementos puramente cosméticos da HUD.
- A transferência ocorre **apenas quando o ataque efetivamente acerta com sucesso** e o efeito não está bloqueado pela imunidade pertinente. O criador especificou efeito garantido, sem chance aleatória própria; não introduzir rolagem de LUK para o roubo.
- Efeitos de **invulnerabilidade que impedem o próprio contato** e **imunidade ao Move de contato/físico** podem impedir a transferência, segundo as condições do criador; **imunidade apenas ao dano mágico**, sem bloqueio de efeitos mágicos, **não impede por si só Badge Steal**, inclusive podendo ter a própria badge roubada quando for um buff elegível.
- **No impacto bem-sucedido, Badge Steal é resolvido antes de aplicar o dano**, inclusive retirando escudos elegíveis do alvo antes que eles possam absorver aquele impacto. É regra específica do Move, sem reordenar globalmente status/crit/dano de D-199.
- O efeito **retira** os efeitos elegíveis do alvo, **transfere** ao atacante e **reinicia a duração efetiva**. Escudos roubados preservam **a resistência restante no alvo**, não regeneram automaticamente a resistência máxima original; preservar a categoria defensiva e prioridades aprovadas da D-324 quando aplicáveis.
- No atacante, o efeito só **acumula** com um equivalente se sua própria definição permitir stacking; se **não permitir**, **reinicia** o efeito correspondente no atacante, sem criar acúmulo implícito.
- A transferência da lógica ocorre no instante do evento mecânico válido. **Animações da HUD de 0,3 s e a energia VFX não atrasam nem antecipam a resolução mecânica**, conforme D-019/D-348.
- Uma vez que o alvo seja derrotado pelo dano do próprio Move, a transferência prévia já foi resolvida; o tratamento de interrupções/morte antes do impacto preserva regras vigentes de ataques interrompidos e sem acerto.

## Distinguir de outras mecânicas

- **Afinidade Drain (D-352)**: converter dano recebido em recuperação de HP ou MP do defensor; **não** rouba buffs, escudos ou badges.
- **Badge Steal**: transferir buffs positivos e escudos elegíveis em ataque válido; **não** recupera HP/MP pelo dano e **não** é uma afinidade elemental.
- **Dispel (D-249/D-262)**: remover efeitos conforme a ficha; **não** transfere automaticamente efeitos removidos ao usuário.
- A keyword fica aprovada **nesta ficha**. Seu uso por outros Moves ou novas variantes não é autorizado automaticamente sem a definição específica desses Moves.

## Pendências para ficha operacional

- Se a imunidade **a dano mágico** for uma badge positiva roubada **antes** de resolver o dano, confirmar se essa mesma imunidade ainda protege contra o dano daquele impacto (snapshot) ou se cessa imediatamente e o ataque passa a causar dano.
- Confirmar como compatibilizar efeitos com magnitude dependente do **conjurador original**, atributos atuais, origem e regras próprias; decisão 11A aprovou **resistência restante dos escudos**, não uma regra universal de magnitude para todo buff.
- Para dois efeitos equivalentes que **não acumulam** (especialmente escudos), detalhar se o reset conserva a capacidade do efeito existente no atacante, substitui-a pela capacidade roubada ou usa regra individual; não preencher a pendência da D-324 por inferência.
- A identidade/status de cada badge mecânica e seu ciclo de vida ainda precisam ser definidos no novo runtime; na `main` atual, buffs são estágios numéricos simples e o sistema de escudos não está implementado.
- Tratar especificamente situações de efeito de proteção que se aplica apenas contra **dano**, contra **efeitos**, contra **contato** ou contra o **Move inteiro**, sem unificar essas imunidades por suposição.
- Nenhuma execução, teste ou integração HUD/VFX realizada.

## Relações

D-003, D-019, D-030, D-061, D-134, D-195, D-199, D-235, D-247, D-249, D-260, D-262, D-322–D-325, D-340, D-348–D-352 e D-356.
