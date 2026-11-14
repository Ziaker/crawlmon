<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-036 — Pilares e Auras de Energia Volumétricas para Buffs/Debuffs SMT

- **Data:** 2026-11-03
- **Área:** Visual / VFX
- **Origem:** Conversa (Grill-Me)

## O que o criador disse (literal)

> eu não gostei mt desses efeitos, tem como deixar eles ainda melhores, mais detalhados e notáveis?
>
> Respostas no Grill-Me:
> - Efeitos alvos: "(Recommended) Buffs e Debuffs SMT (Tarukaja, Rakunda, Sukunda)."
> - Elementos adicionais: "(Recommended) Pilares e Auras de Energia Volumétricas: Adicionar cilindros de luz verticais com feixes e cascata de partículas densas na cor do golpe."

## Decisão

1. **Pilar de Luz Cilíndrico Volumétrico**:
   - Adicionar à cena `SmtStageVfx` um pilar cilíndrico de energia de corpo inteiro envolvendo o alvo (`CylinderMesh` vazado de ~3.6m de altura).
   - O shader `smt_stage_vfx.gdshader` recebe suporte a feixes verticais contínuos em rolagem (`vertical_scroll`), modulação de frequência de feixe (`beam_frequency`) e desvanecimento suave nas bordas superior e inferior (`smoothstep`), evitando cortes rígidos com o chão ou teto.
   - Direção do fluxo de energia:
     - **Tarukaja**: feixes de energia em ascensão rápida (`vertical_scroll > 0`).
     - **Rakunda**: feixes gravitacionais descendentes em esmagamento (`vertical_scroll < 0`).
     - **Sukunda**: feixes de desaceleração/estase em espiral alternada.

2. **Núcleo de Luz Interno (Energy Core)**:
   - Cilindro concêntrico interno mais intenso, criando profundidade visual e sensação de feixe volumétrico denso.

3. **Cascata de Feixes Verticais Orbitais (Light Beams Cascade)**:
   - Conjunto de 8 feixes luminosos orbitais verticais em cascata na cor temática do golpe, subindo ou descendo em sincronia com o ciclo de vida da animação.

4. **Preservação das Geometrias e Cromática D-035**:
   - Mantidas as cores oficiais: Tarukaja (`#D7FD6A` Verde-Lima), Rakunda (`#FF624F` Coral) e Sukunda (`#F7CB78` Amarelo/Ouro).
   - Mantidos os 3 anéis holográficos e as geometrias temáticas (4 lanças ascendentes no Tarukaja, 6 cunhas descendentes no Rakunda e 6 cubos de inércia rotativos no Sukunda), agora integrados de forma harmônica e imponente ao pilar de luz.

5. **Duração e Timing**:
   - Mantida a duração de 1.00s alinhada à pausa de status de D-031.

## Ambiguidades em aberto

- Nenhuma pendência; elementos alinhados no Grill-Me.

## Estado no código

- **Revogado / Removido a pedido do criador:** Os tubos/cilindros volumétricos foram completamente retirados do código (`scripts/vfx/smt/smt_stage_vfx.gd`), pois resultaram em um visual genérico, lavado e que ocultava os detalhes do efeito.
- O criador exigiu a remoção dos tubos e busca por referências ambiciosas de efeitos visuais autênticos.
