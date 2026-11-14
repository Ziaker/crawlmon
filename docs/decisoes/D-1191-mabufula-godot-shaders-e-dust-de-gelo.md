# D-1191 — Mabufula no Godot: shaders de gelo e dust com baixa opacidade

- **Data:** 2026-11-12.
- **Área:** VFX de combate / Mabufula.
- **Estado:** direção visual aprovada; implementação e provas no Godot em andamento.

## O que o criador disse (literal)

> vamos implementar o mabufula, quero que tenha mais shaders e efeitos bonitos de gelo e dust de gelo com baixa opacidade

À pergunta sobre implementar no jogo Godot ou melhorar o Atelier HTML:

> No jogo Godot

Escolhas de acabamento e dust:

> Cristal translúcido, veios internos e brilho nas arestas

> Nos dois: névoa baixa e pequenas nuvens nas geleiras

Divisão de trabalho solicitada:

> continua, deixe a parte do codigo pro deepseek e a parte do visual pra vc

## Decisão

1. Implementar o trabalho visual do Mabufula **no jogo Godot**.
2. Acrescentar shaders e efeitos visuais de gelo e dust de gelo com baixa opacidade.
3. Este pedido é visual; não define mudanças de dano, custo, alcance, status ou tempos mecânicos.
4. Preservar a coreografia de geleiras da D-337 como referência, acrescentando **cristal translúcido, veios internos e brilho nas arestas**. Esta escolha autoriza o acabamento adicional em relação ao HTML.
5. A dust pouco opaca aparece **como névoa baixa na área e pequenas nuvens nas bases/nascimento e estilhaçamento das geleiras**. Parâmetros de shader são calibração da primeira proposta visual, sujeita à inspeção e aprovação do criador; não constituem regras mecânicas.
6. D-019/D-1040 (relógio de combate), D-235 (qualquer participante/lado), D-308 (provas visuais) e D-1154 (telemetria) continuam aplicáveis.
7. A continuação do código é delegada ao DeepSeek; o agente principal mantém a direção visual e a revisão. As provas seguem a versão atual do protocolo: dados e vídeo nas duas vistas, sem inspeção de quadros em tamanho real pelo agente principal.

## Ambiguidades em aberto

- Acabamento e distribuição definidos nas respostas acima; aprovação visual da implementação pendente.
- Nenhuma nova regra mecânica aprovada.

## Registro e publicação

Decisão registrada localmente com índice e consolidado. Sem commit/push nesta rodada; o pedido atual não contém autorização expressa de envio e o workspace contém alterações de outras sessões.

## Levantamento anterior à implementação

- `content/moves/mabufula/move.tres` usa `vfx_key = "generic"`; `MoveVfxRegistry` encaminha o impacto para `FxImpacts._mabufula_impact`, que desenha anéis, faíscas e fumaça. Os shaders `mc_glacial_spire`/`mc_cryo_decal` e as representações correspondentes existem, mas não há coreografia Mabufula ligada a eles.
- Baseline em 2026-11-12: execução com `--strict-asserts` interrompida por `SCALE_POP` no quadro 2, antes do Move. A normalização de altura ocorre em `battle_scene.gd`; o detector compara com a escala anterior. Não foi alterado o jogo nem o teste e não se declarou qual deles está errado.
- Execução observacional, sem `--strict-asserts`: `SUMMARY_JSON` com `move=Mabufula`, `hits_count=3`, `phases_reached=[release,strike,travel,impact,return,done]`, `leaks_detected=4`. Os quatro nós apontados incluem `ScaledFx` e um `Label3D`; a causa precisa ser distinguida entre efeito residual e momento de medição antes de qualquer correção.
- Logs: `C:/Users/zerke/.codex/visualizations/2026/11/12/01a1cfeb-c591-7783-b072-b13a37c03fef/mabufula-before.log` e `mabufula-before-observe.log`.
- Primeiros shaders e adaptador visual criados; integração, implementação completa e vídeo ainda pendentes. As escolhas de acabamento e distribuição já foram respondidas e estão registradas acima.
