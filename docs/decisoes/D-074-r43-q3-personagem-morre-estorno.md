<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-074 — R43-Q3 (3C): Morte do executor cancela o golpe extra com estorno

- **Data:** 2026-11-03
- **Área:** Combate / Rodada 43
- **Estado:** decisão de design registrada após delegação às recomendações; implementação não afirmada.
- **Proveniência:** o usuário não informou letras individualmente. Ele respondeu literalmente **“Sigo suas recomendações”**. As alternativas abaixo foram **selecionadas e recomendadas pelo assistente**, com essa autorização geral. Não atribuir ao usuário a redação das alternativas.

## Autorização literal do usuário

> Sigo suas recomendações

## Pergunta e alternativa recomendada pelo assistente (não são citação do usuário)

- **Pergunta:** Se o próprio personagem morrer antes de executar o contra-ataque enfileirado, o que acontece?
- **Escolha recomendada:** **3C — Cancelar o Move extra, seguindo a mesma regra de reembolso escolhida para interrupção do ataque original.**

## Regra consolidada

Se o personagem que selecionou e pagou o contra-ataque extra morrer antes de o golpe começar, **cancelar o Move extra**. Aplicar **a mesma regra de reembolso da interrupção do ataque original**: devolução integral do recurso pago (R43-Q1A / D-072), ainda que o personagem esteja derrotado.

## Referências e limitações

- **Decisões relacionadas:** D-062, D-064, D-072, D-073.
- **Pendência:** A restituição contábil ao personagem derrotado não implica reviver, recuperar HP nem permitir ação. A persistência do saldo após batalha não foi definida por esta escolha.
- **Escopo:** documentação somente, sem mudança de código, FX, configurações ou testes.
