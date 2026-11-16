# D-1218 — Teste de conformidade numérico da mão (evento `martial_hand`) e uso obrigatório das ferramentas de VFX

- **Data:** 2026-11-14.
- **Área:** VFX de Move / debug / telemetria.
- **Relacionadas:** D-1209, D-1204, D-1042, D-1044, D-1154, D-308.
- **Status:** registrada; implementação em andamento (DeepSeek: gancho e checker; Claude: julgamento visual).

## O que o criador disse (literal)

> "simplesmente não tem nenhum outro jeito além de tentativa e erro constante toda hora pra ajeitar um vfx? não tem nenhuma ferramenta não tem nada que possa pesquisar?"
> "faça então" (montar o teste de conformidade numérico da mão primeiro)
> "faça isso e obrigue o agents MD ou claude MD ou instructions sla pra usar essas ferramentas sempre"

## Decisão

1. Novo evento de telemetria `martial_hand` (documentado em `docs/TELEMETRIA.md` §3): uma linha por quadro enquanto a mão do Karate Chop existe (posição, rotação, escala, opacidade/fade, dissolve, forma, velocidade, fase da coreografia).
2. Um checker (`tools/vfx/check_martial_hand.py`) roda `--scenario=karate_holo` e `karate_holo_esp` com `--stdout-trace`, lê o JSONL e afirma, contra as palavras do criador na D-1209: a mão corre com o corpo até o prelúdio; o prelúdio dura 0,20 s com subida, virada e corte; o pico de velocidade fica no contato; nunca fica oculta nem abaixo do chão; desacelera após o corte; o fade (0,85 s) só começa no pouso. Gera também um gráfico PNG (PIL).
3. **Regra permanente:** todo trabalho de VFX/animação de Move usa, nesta ordem, dados antes de imagens: `--step-ticks`, evento de telemetria da mão/efeito, `--envelope-graph`, `--bone-probe`, `--proof-sheet`, `--diff-with`. Tentativa e erro com capturas em instantes chutados é proibido. Registrado em `AGENTS.md` §9.8.

## Ambiguidades

- Os limiares numéricos do checker vêm das palavras do criador (0,20 s, 0,85 s, "nunca some") e do Motion Lens (chicote ~0,17 s); tolerâncias de quadro são escolha técnica da IA.
