# D-210 — Rodada 72 Q3 (3A): uma tentativa de aplicação por status distinto, alvo e execução

- **Data:** 2026-11-04.
- **Área:** Combate / multi-hit / múltiplos status condicionados ao acerto.
- **Origem:** aprovação expressa do criador na Rodada 72.
- **Estado:** regra de design aprovada; não implementada nesta atividade.

## Declaração literal do criador

> 3A — Permitir uma tentativa por efeito de status distinto declarado na ficha, respeitando o limite individual de cada efeito por alvo/execução.

## Regra aprovada

- Quando a **ficha do Move declarar mais de um efeito de status distinto** sujeito a aplicação **condicionada ao acerto**, permitir **no máximo uma tentativa por efeito distinto, por alvo e por execução do Move**.
- A existência de uma tentativa para um efeito **não consome nem substitui** a oportunidade de tentativa de **outro efeito distinto** também previsto pela ficha. A decisão **não cria um status extra**, não modifica as probabilidades declaradas nem garante o sucesso de qualquer efeito.
- Manter as condições de **D-202/D-207**: para efeito condicionado ao acerto, o alvo deve ter sido **acertado validamente** e **sobreviver ao dano**, e a tentativa ocorre depois do **último impacto destinado ao próprio alvo**. Manter D-199 (crítico e dano antes do status) e D-195 (esquiva automática antes de crítico/status dependente do acerto).
- **Exemplo ilustrativo, sem autorizar uma ficha concreta:** Move hipotético declara `Poison 30%` e `Paralysis 20%`, ambos condicionados ao acerto. Sobrevivendo o alvo que recebeu acerto válido, a execução pode tentar **Poison uma vez e Paralysis uma vez**, respeitando a chance aplicável de cada efeito. Não permitir três tentativas de cada um apenas porque houve três impactos.
- **D-134/D-146/D-156 preservadas:** efeitos com chance declarada seguem as próprias regras de LUK no instante da rolagem; efeitos declarados garantidos não ganham rolagem probabilística por esta decisão. **O conflito textual das escalas de LUK da Rodada 60 permanece pendente** conforme o GDD §12.13.

## Limites e pendências

- Não define **qual é a ordem das tentativas entre status distintos**, se o sucesso de um efeito pode impedir ou alterar outro por incompatibilidade, como efeitos de status já ativos interagem ou o comportamento de falhas decorrentes da ficha do Move; todas essas escolhas são separadas e não devem ser inventadas.
- A D-211 regula o caso de interrupção do Move após acertos válidos, sem aumentar a quantidade de tentativas por status/alvo/execução.
- Somente documentação; nenhum código, ficha de Move, probabilidade, teste, cena, asset ou VFX alterado.
