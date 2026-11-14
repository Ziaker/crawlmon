<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-334 — Oito efeitos do atelier com tamanho fixo no mundo

- Data: 2026-11-05
- Escopo: protótipo HTML dos oito Moves (D-331/D-333).
- Estado: aprovado e implementado no HTML; invariância de tamanho verificada nos oito efeitos; aprovação artística pendente.

## Frase literal do criador

> Tamanho fixo no mundo

Resposta à pergunta: “Qual regra de tamanho vale para estes oito efeitos: tamanho fixo no mundo, como diz a D-308, ou dimensionado pela tela, como diz o protocolo? As origens e os pontos de contato continuarão derivados dos modelos reais.”

## Decisão

O tamanho próprio de cada efeito é definido em unidades do mundo. Não multiplicar a escala pelo tamanho do atacante, do alvo, pelo lado nem pela distância da câmera. A animação de crescimento/dissipação da receita continua, com os mesmos valores para todos os participantes. Origens e contatos continuam derivados dos modelos reais; caminhos continuam ligando os participantes reais.

Para estes oito efeitos, esta escolha resolve a divergência entre D-308 (escala fixa) e a orientação de dimensionamento pela tela no protocolo. Não alterar o protocolo global nem VFX Godot de outras sessões.

## Ambiguidades

Nenhuma quanto à unidade e independência da escala; aprovação visual continua pendente.
