# Atelier HTML — versão de revisão

Abra `atelier.html` diretamente no navegador. Three.js, Quarks.js, os shaders e o CSS estão incluídos no próprio arquivo; não é necessário servidor nem CDN.

## Correções e acabamento

- Restaurados os elementos DOM ausentes usados pelos oito Moves.
- Corrigida a variável inválida do shader de Sand Attack e os limites invertidos de `smoothstep`.
- Substituído o motor de partículas que apenas se chamava Quarks por `three.quarks` 0.15.7, com `BatchedRenderer` e `ParticleSystem` reais.
- Preservadas as receitas visuais do arquivo de origem, acrescentando detalhe moderado: mais partículas pequenas, textura de chama/fumaça, ruído simplex nos materiais e tratamento de saída de cor.
- Eventos e efeitos compartilham o relógio da simulação; alteração de velocidade não recalcula timers de parede.
- Referenciais dos efeitos derivados dos participantes; seleção de outro atacante, alvo, vista espelhada e tamanho do alvo.
- Limpeza de geometrias, materiais e sistemas ao encerrar cada instância.

## Validação realizada

`check.py`: Chromium headless, WebGL/SwiftShader, 1440 × 900. Oito Moves na configuração inicial e em três combinações adicionais: Pancham → Gible (0,65×), Gible → Abra (1,6×), Gible → Pancham (1×). Splitter Flames duplo e redirecionado também exercitados. Nenhum erro JavaScript/GLSL registrado; fila e sessões retornaram a zero após a dissipação.

`diagnose_clock.py`: 24 repetições com troca de velocidade e pausa. Todas passaram: HP 60 antes de 1,08 s e HP 24 depois; pausa preservou tempo e HP. A falha intermitente foi reproduzida e diagnosticada: o primeiro timestamp de requestAnimationFrame podia anteceder performance.now() da inicialização, inserindo delta negativo no acumulador. Agora a primeira amostra apenas inicializa o relógio; deltas negativos/não finitos são ignorados. Resultados em `clock-diagnostic.json`.

`audit_scale.py`: os oito efeitos conservaram escalas de malhas e tamanhos de partículas ao alterar atacante/alvo de 1×/1× para 0,65×/1,6×. A comparação de amostras aleatórias entre espécies diferentes é apenas diagnóstica: não exige identidade de cada partícula. Resultados em `scale-results.json`.

`record_preview.py`: gravação dos oito efeitos no HTML, normal e espelhado, com câmera fixa. Não é gravação do Godot.

## Pendências e limites

- D-333: o criador aprovou continuar no HTML com Quarks.js como exceção ao Motion Composer e à validação na batalha Godot.
- D-334: tamanho fixo no mundo. Medidas dos participantes localizam origens e contatos; não multiplicam o tamanho dos efeitos.
- Aprovação artística pendente. Não houve integração nem validação na batalha Godot.
- Não testados: GPU física, Firefox/Safari, dispositivos móveis, benchmark de desempenho e áudio gravado. A gravação é sem áudio.
- Valores de dano/cura/HP são os demonstrativos do arquivo recebido, não regras novas para o jogo.
- Código e documentação não foram commitados nem publicados.

## Reconstruir

Requer Node.js, Python e o arquivo recebido preservado como `original.html` nesta pasta:

```
npm ci --ignore-scripts
npm run build
```

`prepare.py` conserva os construtores e receitas do arquivo original, aplica as correções e produz `app.js`/`shell.html`. `engine.js` contém a integração real do Quarks e o relógio. `runtime.js` contém os participantes, controles e a simulação.

## Bibliotecas

- [Three.js](https://github.com/mrdoob/three), 0.169.0, MIT.
- [three.quarks](https://github.com/Alchemist0823/three.quarks), 0.15.7, MIT; [documentação de integração](https://docs.quarks.art/docs/getting-started).
- [Ashima webgl-noise](https://github.com/ashima/webgl-noise), simplex GLSL; licença em `LICENSE-noise.txt`.
- Tailwind CSS 3.4.17, MIT, usado apenas para compilar o estilo já presente no arquivo.

## Checklist da revisão visual

Quadros inspecionados individualmente em 1440 × 900: `move-0.png` a `move-7.png` (normal) e `review-mirror-0.png` a `review-mirror-7.png` (espelhado), aproximadamente 0,925 s de simulação. Vídeo final: `preview-normal-espelhado.mp4`, 134,12 s, ambas as vistas.

| Frase do criador | Verificação |
| --- | --- |
| “corrige os problemas desse código” | DOM e GLSL corrigidos; 32 casts da matriz e os dois modos adicionais de Splitter sem erros; sessões/fila zeradas ao final. |
| “mais detalhes nos efeitos, mais partículas, sem exagerar” | Emissão aumentada em 18%, partículas menores, texturas e ruído; quadros dos oito efeitos nas duas vistas inspecionados. A avaliação de “sem exagerar” depende da aprovação artística. |
| “parecer menos HTML-esco e mais GODOT-esco” | Acabamento de materiais/partículas aplicado. Parcial artisticamente: ondas psíquicas ainda mostram anéis geométricos planos; HUD pode encobrir parte do efeito na vista espelhada. |
| “usando quarks.js e bibliotecas de shaders” | three.quarks real e Ashima webgl-noise incluídos no HTML; execução offline verificada. |
| “Continuar no HTML com Quarks.js” | Entrega HTML; nenhuma integração Godot realizada. |
| “Tamanho fixo no mundo” | Escalas de malhas e tamanhos de partículas invariantes entre modelos de tamanhos diferentes nos oito efeitos. |

D-019: relógio compartilhado, pausa e velocidade testados. D-235: outros atacantes/lado espelhado/tamanhos testados. D-331: escopo restrito ao protótipo. D-333: exceção HTML respeitada. D-334: escala mundial implementada. D-308: quadros e vídeo entregues para revisão; não houve inspeção exaustiva de cada instante das quatro fases, nem aprovação artística. Não se afirma validação integral do protocolo.
