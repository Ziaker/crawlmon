<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-135 — Rodada 55 Q5 (A): Dispensa excepcional da distribuição obrigatória quando seis atributos estão em 100

- **Data:** 2026-11-03
- **Área:** Atributos e progressão de Pokémon / Rodada 55.
- **Proveniência:** escolha **expressamente enviada pelo criador**, aceitando alternativa recomendada previamente pelo assistente; a decisão foi escolhida pelo criador, não deduzida de delegação à IA.
- **Estado:** decisão de design aprovada e registrada; **não implementada nesta atividade**.

## Declaração literal do criador

> 5A — O que acontece ao subir de nível com todos os seis atributos em 100? Dispensar excepcionalmente a distribuição quando todos os atributos estiverem no limite. (recomendação aceita)

## Regra aprovada e compatibilidade

- O **protagonista** continua recebendo, como regra de progressão, a obrigação de **distribuir 1 ponto de atributo por nível**, conforme a progressão anteriormente aprovada.
- **Exceção expressa:** se **todos os seis atributos permanentes** (STR, MAG, VIT, SPI, AGI e LUK) estiverem no **teto de 100**, **dispensar a distribuição obrigatória do ponto**, **sem bloquear a subida de nível**.
- A dispensa é **excepcional**: enquanto ainda houver algum atributo elegível com valor inferior a 100, o protagonista deve seguir a distribuição obrigatória já aprovada. Preservar o limite de 1–100 de D-129 e a inclusão de Spirit por D-130/D-131.
- Não criar automaticamente um bônus alternativo, um banco de pontos ou uma conversão do ponto dispensado; **o destino contábil desse ponto não foi explicitamente detalhado** pela resposta.
- A decisão não modifica curvas automáticas dos aliados/inimigos nem define como tratar pontos automáticos excedentes em seus atributos.
- **Exemplo:** ao subir de nível com STR=MAG=VIT=SPI=AGI=LUK=100, o protagonista progride sem precisar escolher um atributo para aplicar o ponto.

## Estado de execução

- **Documentação somente:** não alterar código, cenas, tabelas, fichas de Moves, VFX, testes ou configurações do projeto.
- As fórmulas e dados marcados como pendentes não podem ser completados por suposição.

## Complemento posterior — Rodada 57 (2026-11-03)

**D-139 (R57-Q1B)** elimina o teto de 100. Assim, a condição **“todos os seis atributos no teto de 100”** desta D-135 não pode mais ocorrer: os atributos ainda podem crescer acima de 100. A dispensa excepcional do ponto por chegar a esse teto **fica superada**, enquanto a obrigação geral de distribuir **1 ponto do protagonista por nível** permanece. O texto da D-135 é preservado historicamente.
