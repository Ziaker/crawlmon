<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-061 — Registrar continuamente as decisões no GitHub

- **Data:** 2026-11-02
- **Área:** Processo/documentação
- **Origem:** conversa, ordem expressa posterior às Rodadas 39–41.
- **Estado:** política documental a cumprir nas rodadas futuras.

## Declaração do criador (literal)

> ENTÃO FAZ ISSO, VC QUE ENFIOU ESSE NEGOCIO DE NÃO ALTERAR ARQUIVOS, É PRA ATUALIZAR SEMPRE VC SEMPRE ESQUECE

## Regra aprovada

- Sempre que o criador aprovar decisões de design, registrar imediatamente cada decisão em `docs/decisoes/D-*.md`, atualizar o índice e acrescentar as regras a `docs/REGRAS_DO_JOGO.md` antes de prosseguir para outra rodada.
- **Documentar decisões não é implementar mecânicas:** somente a documentação pode ser atualizada nesta atividade. Não modificar código, VFX, testes ou outros recursos sem autorização.
- Registrar pendências e conflitos, preservando o histórico. Não presumir respostas ou resolver conflitos silenciosamente.
- Se uma instrução futura proibir **expressamente** a atualização da documentação, respeitar essa instrução e informar que as decisões ainda não foram persistidas.
- Verificar publicação e integridade dos arquivos atualizados no GitHub antes de dizer que estão registrados.

## Relações

- Complementa D-002, D-003, D-022 e a seção 16 de `docs/REGRAS_DO_JOGO.md`.
