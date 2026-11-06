# D-936 — Oito efeitos do atelier com tamanho fixo no mundo

> **Renumerada em 2026-11-06:** D-334 → D-936. O ID D-334 já pertence a outra decisão no `origin/main`; o conteúdo local foi preservado com o novo ID.


- Data: 2026-11-05
- Escopo: protótipo HTML dos oito Moves (D-933/D-935).
- Estado: aprovado e implementado no HTML; invariância de tamanho verificada nos oito efeitos; aprovação artística pendente.

## Frase literal do criador

> Tamanho fixo no mundo

Resposta à pergunta: “Qual regra de tamanho vale para estes oito efeitos: tamanho fixo no mundo, como diz a D-308, ou dimensionado pela tela, como diz o protocolo? As origens e os pontos de contato continuarão derivados dos modelos reais.”

## Decisão

O tamanho próprio de cada efeito é definido em unidades do mundo. Não multiplicar a escala pelo tamanho do atacante, do alvo, pelo lado nem pela distância da câmera. A animação de crescimento/dissipação da receita continua, com os mesmos valores para todos os participantes. Origens e contatos continuam derivados dos modelos reais; caminhos continuam ligando os participantes reais.

Para estes oito efeitos, esta escolha resolve a divergência entre D-308 (escala fixa) e a orientação de dimensionamento pela tela no protocolo. Não alterar o protocolo global nem VFX Godot de outras sessões.

## Ambiguidades

Nenhuma quanto à unidade e independência da escala; aprovação visual continua pendente.
