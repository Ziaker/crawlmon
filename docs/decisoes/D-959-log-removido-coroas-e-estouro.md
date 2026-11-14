<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-959 — Log de batalha removido; três coroas girando e estouro de 0,2 s no Electric

- **Data:** 2026-11-07.

## Frases literais do criador

> tem como remover esse log, pode deletar ele do código, só atrapalha a visão e sera trocado por outro mesmo assim

> quanto a coroa, coloque mais 2 camadas dela e faz elas girarem, uma em horaria, outra em antiohoraria, cada uma mais afastada e menor que a outra, me planeje o que mais faria pra melhorar este efeito visual. Além disso eu quero que também tenha um extouro de energia eletrica no disparo do feixe elétrico, bem rápido, .2 segundos

## Decisão

1. O painel de log da batalha (`BattleLogPanel`, tecla T, dica "T LOG") foi **apagado do código**, junto com as referências nos testes. Um novo painel o substituirá depois. O sinal `log_message` e `BattleHud.log_color` continuam.
2. Coroa do Electric: **3 camadas**. A primeira fica na boca do disparo. A segunda fica mais à frente no eixo do tiro e é menor, girando em sentido horário. A terceira fica ainda mais à frente e é menor ainda, girando em sentido anti-horário. As três se abrem e se separam para trás em 5 partes. Leitura do assistente: "mais afastada" = mais à frente no eixo do tiro.
3. **Estouro de energia elétrica** no disparo, em 0,2 s: raios curtos em todas as direções e um clarão branco-dourado.
4. O assistente propõe melhorias; nenhuma é feita sem aprovação.
