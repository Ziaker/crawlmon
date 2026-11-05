# D-305 — Motion Composer V1: Etapa 5 (laboratório visual) iniciada

- **Data:** 2026-11-04
- **Área:** Motion Composer / laboratório / representações
- **Origem:** Conversa

## O que o criador disse (literal)

> auditorie a etapa 4 por tudo que esqueceu ou nao implementou e depois que finalizar de corrigir isso ja imediatamente inicie a etapa 5

Em resposta anterior sobre os efeitos visuais:

> pode me garantir que estes efeitos visuais estao usando shaders e objetos do godot e nao coisas de html?

## Decisão

Iniciar a **Etapa 5** da seção 16 de [Motion Composer V1](../vfx/MOTION_COMPOSER_V1.md): "Construir a interface e as ferramentas de inspeção para os 20 movimentos e composições", conforme D-042 (toggle entre atualizar no instante atual e reiniciar), D-043 (camadas ordenadas), D-044 (pontos, fragmentos, fitas e fumaça/billboards) e D-045 (pasta fixa de presets).

**Regra técnica (resposta à pergunta do criador):** todas as representações usam **objetos e shaders do Godot** (`MultiMeshInstance3D`, `ArrayMesh`, `ShaderMaterial` com `.gdshader`, GL Compatibility); nada de HTML nem de primitivas de protótipo. A aparência segue a memória do criador sobre VFX ("idêntico" = visual, feito com as ferramentas do jogo).

**Ritmo (memória do criador sobre VFX):** uma mudança visual por passo; cada passo é mostrado rodando e **espera aprovação** antes do seguinte. Por isso a Etapa 5 é entregue em fatias:

1. **Fatia 1 (esta):** relógio do laboratório e toggle de edição (D-042), presets em pasta fixa (D-045), representação **Pontos** (neutra) com shader, laboratório mínimo (viewport, catálogo, camadas, parâmetros, linha do tempo, inspeção). **Para aqui e aguarda aprovação.**
2. Fatias seguintes, uma por vez e só com aprovação: Fitas; Fragmentos; Fumaça/billboards; comparação A/B; estudos individuais dos 20 comportamentos.

Limites: Etapa 6 (validação completa) não autorizada. Nenhuma alteração em combate, `VfxLib`, `BattleFx`, cenas ou VFX existentes (D-003, D-019, D-020). Sem push sem autorização (D-022). Faixa de IDs D-300+ reservada ao Motion Composer.

## Valores propostos pelo agente (não aprovados pelo criador)

Disposição da interface (P-08), pasta `user://motion_composer/presets/` e formato JSON versionado, velocidades de 0,1x a 2x, passo de 1/60 s, ciclo de 3 s, modo de edição inicial "atualizar no instante atual" (sem persistir a preferência), aparência neutra dos pontos e cores por ramo. Tudo ajustável e sujeito à sua aprovação visual.

## Ambiguidades em aberto

P-07 (orçamento), P-08 (aparência e disposição da interface), P-09 (composições demonstrativas adicionais) e a aparência dos estudos individuais continuam abertas.

## Aprovações do criador (literais)

- Fatia 1 (Pontos): "estao otimos".
- Fatia 2 (Fitas): "ok, oque deve prosseguir agora, aprovo ambos" (os dois vídeos de Fitas; a ordem prevista é Fragmentos, Fumaça/billboards, A/B, estudos individuais).
- Fatia 3 (Fragmentos): "prossiga".
- Fatia 4 (Fumaça/billboards), primeira versão: "Não gostei n parece fumaça nem dust" (**rejeitada**; refeita no estilo de fumaça e poeira do jogo, D-041).
- Fatia 4, segunda versão: "Não estou satisfeito ainda". Respostas à pergunta feita: problemas "Borrada/mole demais, Formato de nuvem/algodão, Cor ou luz, Movimento"; referência "Poeira do jogo (D-041)". Terceira versão feita medindo a poeira real do jogo (ver §29).
- Fatia 4, terceira versão: "Tá melhor, mas poeira mexe muito com opacidade, não estou vendo tanta". Quarta versão com densidade por baforada, oscilação da opacidade e curva de esmaecimento (ver §29).
- Fatia 4, quarta versão: "Muito melhor" (aprovação da poeira, tratada como aprovação para seguir à fatia 5, comparação A/B; se a intenção era só elogiar e pedir mais ajustes, a fatia 4 volta a ser retomada).

- Fatia 5 (comparação A/B): "O depois está melhor em todos" (julgou os três pares A × B com a ferramenta: o lado B, com mais camadas / fitas / fragmentos, foi preferido; tratado como aprovação da comparação e como preferência visual de Fitas e Fragmentos sobre Pontos).

- Fatia 6 (estudos individuais): "estão ótimos".

## Estado

Fatia 1 **aprovada pelo criador** ("estao otimos"). Fatia 2 (Fitas) **aprovada**. Fatia 3 (Fragmentos) **aprovada**. Fatia 4 (Fumaça/billboards): aprovada na quarta versão ("Muito melhor"). Fatia 5 (comparação A/B) **aprovada**. Fatia 6 (estudos individuais dos 20 comportamentos e a receita) **aprovada** ("estão ótimos"). Fatia 7 (seleção de ramos e máscaras na interface, último item da Etapa 5) implementada, aguardando aprovação visual (ver §32). Histórico: fatia 1 entregue e mostrada ao criador (relógio, toggle D-042, presets D-045, representação Pontos com shader, laboratório mínimo; 96 verificações novas, 553 no total). **Aguardando a aprovação visual do criador** antes da fatia seguinte (ver §26 da especificação).
