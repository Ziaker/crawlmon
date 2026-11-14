<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-347 — Piso orgânico com Ground Alt. 1/2 (Bloco 2)

- **Data:** 2026-11-06
- **Área:** Exploração / visual / tilesets
- **Origem:** Auditoria do Bloco 1; recomendação de avançar para o Bloco 2

## O que o criador disse (literal)

> Aprove o resultado atual do Bloco 1 e avance imediatamente para o Bloco 2:

> O foco agora deve ser o **piso orgânico** (usar `Ground Alt. 1` e `Ground Alt. 2` com distribuição determinística por semente para quebrar a repetição do piso de tijolos). Isso vai deixar as salas visualmente muito mais bonitas e naturais.

## Decisão

1. Importar **Ground Alt. 1** (C16 R1) e **Ground Alt. 2** (C19 R1) para o atlas/perfil, somente onde a célula tem arte; se faltar, o jogo usa `ground_c`.
2. Usar as variantes **apenas em células de chão interiores** (sem parede nos quatro lados). Células de borda/canto continuam com o tile de borda da máscara de 4 vizinhos; isso preserva as costuras.
3. Distribuição **determinística por seed do andar** (`GameState.dungeon_seed`): 92% `ground_c`, 4% `Ground Alt. 1`, 4% `Ground Alt. 2` (quando existirem), por célula. O seed muda a cada andar; a mesma seed reproduz o mesmo piso. **Correção da auditoria visual:** as Ground Alt são **decals de chão** (flores, árvores, pedras, entulho), não variações seamless; 12%+12% deixava a sala parecendo um campo de flores/árvores aleatórias. 4%+4% mantém o piso orgânico sem poluir.
4. O **laboratório** passa a mostrar o renderer manual aprovado com o piso orgânico (não o terrain nativo de 47), e continua alternando os 16 perfis com ←/→.
5. O experimento de terrain nativo/pontas extras do Bloco 1 **sai do atlas ativo e do laboratório**; ele não era usado pelo jogo e piorava o contorno. A D-346 fica como histórico do limite da folha.
6. Nada de câmera 2,3×, 48 px, combate, movimento, colisão ou regras muda. Sem commit/push.

## Ambiguidades

- A proporção 92/4/4 e o sorteio por célula são uma primeira proposta; se o piso ficar ruidoso ou raro demais, ajusto para blocos 2×2 ou outra proporção depois da captura.
- A distribuição usa o seed do andar; o seed de bioma continua separado.

## Estado

Implementado: 16 perfis com 20 tiles (18 núcleo + Ground Alt. 1/2), piso orgânico 92/4/4 no jogo e no laboratório, `--check` OK, capturas em `scratch/block2_captures.png` e `scratch/tilesets/`. Nada foi commitado ou publicado.
