# D-265 — Rodada 82 Q2 (2A): lista textual compacta de omissões ao tentar confirmar Move

- **Data:** 2026-11-04.
- **Área:** Combate / validação de Move / apresentação de bloqueio.
- **Origem:** decisão expressa do criador na Rodada 82.
- **Estado:** comportamento de apresentação aprovado; não implementado nesta atividade documental.

## Declaração literal do criador

> 2A — Exibir uma lista textual compacta com todas as omissões detectadas ao tentar confirmar o Move, mantendo a seleção de combate aberta.

## Regra aprovada

- Quando, ao **tentar confirmar um Move**, o validador detectar **omissões correspondentes a causas de bloqueio expressamente aprovadas**, exibir **uma lista textual compacta com todas as omissões detectadas na mesma validação**, e **manter aberta a seleção de combate**, sem confirmar a ação.
- Preservar D-255: enumerar todas as causas detectadas em vez de mostrar só a primeira. As causas aprovadas até aqui são **prioridade obrigatória ausente entre status expressamente incompatíveis na ficha** (D-215/D-217/D-221/D-225) e **máximo obrigatório ausente para ocorrências condicionais variáveis** (D-233/D-238). Não inventar outras causas de bloqueio.
- Preservar D-225/D-238/D-255: o bloqueio ocorre **antes da confirmação e de consumir ação ou recursos** (ATB/Burst/MP aplicável); a seleção continua disponível para escolha válida. Preservar D-232/D-251 quanto ao filtro da IA.
- **Exemplo hipotético de conteúdo, não copy/layout definitivo:** `Prioridade ausente entre efeitos A/B`; `Máximo de ocorrências condicionais ausente`. Se ambas as omissões estiverem presentes, **as duas aparecem como lista textual compacta** após a tentativa de confirmar, **sem fechar a seleção**. A/B são apenas rótulos e não status reais aprovados como incompatíveis.
- **Restrições visuais e de interface:** a decisão exige uma **lista textual compacta**, não redesenha ou reorganiza a HUD, não estabelece fonte, cor, posição, dimensões em pixels, modal, tooltip nova, prévia de dano ou painel extra. Preservar a proibição expressa de prévia de dano na seleção de alvos (**D-259**) e as tooltips no seu contexto (**D-229/D-230**).

## Pendências e escopo

- Não se aprovou localização exata da lista na HUD, comportamento ao trocar de Move, duração/exibição persistente do aviso, ordem das mensagens, linguagem final dos textos ou modo de interação do alerta.
- A mera indicação de um campo não atribui prioridade automática, máximo presumido nem corrige a ficha por conta própria.
- Somente documentação; nenhuma HUD, código, teste, ficha de Move, cena, asset ou VFX modificado.
