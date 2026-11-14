<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-139 — Rodada 57 Q1 (B): Atributos permanentes podem ultrapassar 100 sem teto máximo

- **Data:** 2026-11-03
- **Área:** Personagens / atributos / combate / Rodada 57.
- **Origem:** escolha enviada expressamente pelo criador; as alternativas das questões 2–4 haviam sido recomendadas pelo assistente.
- **Estado:** regra aprovada e registrada em documentação; não implementada nesta atividade.

## Declaração literal do criador

> 1B — O limite de 100 deixa de existir completamente? Não existe limite máximo permanente de 100. Atributos podem continuar crescendo acima desse valor por progressão, Nature e variações.

## Regra aprovada

- **Não existe limite máximo permanente de 100** para os seis atributos STR, MAG, VIT, SPI, AGI e LUK. Eles podem superar 100 por **progressão, Nature e variações individuais**. Nenhum novo teto foi escolhido.
- **D-129 superada quanto ao teto superior:** preservar seu texto original como regra histórica; buffs temporários permanecem separados dos atributos permanentes. A escala-base inicial 1–100 não foi expressamente substituída.
- **D-135 superada quanto à dispensa do ponto:** sua condição era 'todos os atributos no teto de 100', teto que agora não existe. Mesmo com os seis atributos exatamente em 100, é possível continuar investindo neles. Preservar a obrigação geral do protagonista de distribuir 1 ponto por nível, salvo exceção futura expressa.
- **D-132 preservada:** o intervalo de modificação individual permanece de −3 a +3, sorteado uma vez e persistido, mas a soma pode ficar acima de 100. Exemplo: STR 99 + 3 = 102.
- Esta decisão não revoga o limite inferior dos atributos, nem determina os números de crescimento por nível, pesos de Nature, limites de representação ou novas formas de recompensa.

## Limitações

- Detalhes quantitativos não contidos na declaração literal continuam pendentes. Sem alterações de código, dados, testes, VFX ou assets.
