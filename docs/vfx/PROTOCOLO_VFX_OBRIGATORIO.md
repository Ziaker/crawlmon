# Protocolo obrigatório de VFX (D-308, ordem do criador, 2026-11-05)

**Vale para QUALQUER efeito visual deste projeto, de qualquer tamanho, sem exceção: Move, impacto, partícula, brilho, rastro, HUD animado, protótipo.** Um efeito feito fora deste protocolo está errado, mesmo que "pareça funcionar".

## 0. Regra-mãe

Todo efeito é construído **sobre o Motion Composer**, usando **as duas skills** (`scenario-godot-vfx` e `scenario-godot-shaders`). Se o Motion Composer não consegue fazer o que o efeito precisa, **o Motion Composer é atualizado primeiro** (nova versão: V1.1, V1.2, ... sem limite), documentado e testado, e só depois o efeito é feito. É proibido contornar o Motion Composer com código de partículas, rastros ou trajetórias escrito à mão dentro da classe do Move.

## 1. Antes de escrever uma linha (em ordem, sem pular)

1. **Citar as decisões aplicáveis** pelo ID (no mínimo: D-235, D-308, D-044, D-045, D-043, D-019, e as do Move/personagem em questão). Abrir `docs/decisoes/` de verdade.
2. **Ler as referências do projeto** para o efeito: protótipos HTML em `prototypes/` e `docs/vfx/`, `docs/vfx/MOTION_COMPOSER_V1.md`, efeitos aprovados parecidos (`FireMoveVfx`, `AbraMoveVfx`), assets (`assets/vfx/`, `shaders/`).
3. **Carregar as skills com a ferramenta Skill**: `scenario-godot-vfx` e `scenario-godot-shaders` (e `scenario-godot-expert` para rodar/verificar). Escrever quais passos do fluxo delas serão aplicados neste efeito.
4. **Escrever o checklist literal**: cada frase do criador sobre o efeito vira uma linha verificável ("sem fogo secundário", "vórtices 0,2 s e 0,5 s", "cone no impacto nos dois lados"...). Nada de reinterpretar. Frase ambígua = **perguntar** antes (ex.: "tamanho fixo" = fixo em metros ou fixo na tela?).
5. **Planejar as 4 fases** (Wind-up, Release, Trajeto, Impacto) e a **transição contínua** entre elas (a carga não some: vira o tiro). Medir a duração real de cada fase no jogo (em segundos) antes de escolher tempos.

## 2. Como construir

- Cada fase = **composições do Motion Composer** (M01–M18 e o que vier) + **representações** (`MotionRep`: flames, streaks, embers, smoke, orb, glow, scorch, e novas) pintadas por `MotionPainter`, reunidas em um `MotionEffect` guardado em `MotionPresets`.
- A classe do Move (`ElementMoveVfx` ou equivalente) **só entrega** posições reais, relógios das fases e câmera. Nada de aparência nela.
- **Faltou comportamento, operação, representação ou preset?** Implementar no Motion Composer (com teste), registrar a versão no `docs/vfx/MOTION_COMPOSER_V1.md` ou num `V1.x`, e então usar.
- Independente de personagem, time e lado (D-235): tudo derivado de atacante, alvo, eixo, câmera. Testar normal e espelhado, alvos de tamanhos diferentes.
- Usar o que o Godot e o jogo têm: flipbooks, malhas (`shock_cone`, `slash_arc`, `ribbon_trail`), shaders com textura, partículas, brilho. Nada de "HTML genérico" (fitas finas, pontinhos, formas chapadas).
- GL Compatibility: sem GPUParticles, sem decals, sem sub-emitters.

## 3. Verificação (obrigatória antes de dizer qualquer coisa)

1. Rodar **na batalha real** (`scenes/debug/vfx_room.tscn`), **vista normal E espelhada**, com a câmera do jogo.
2. Olhar **quadros em tamanho real** (nunca só miniaturas ou colagens) **nos instantes de cada item do checklist**, nas duas vistas. Para cada linha do checklist: ✔ ou ✘ com o quadro que prova.
3. Medir com dados, não com impressão: quantidade de elementos por pincel/camada em cada instante, tempos reais das fases, sobras depois do fim (nada pode ficar na tela).
4. **Procurar o que NÃO deveria existir** (fogo/restos fora de lugar, bolas paradas, camadas que não somem) tão ativamente quanto o que deveria.
5. Só então gravar o vídeo: **um único vídeo com as duas vistas em resolução cheia** (`tests/fx_lab/record_move_video.py`), e enviar.

## 4. Entrega

Dizer: o que foi pedido (checklist), o que foi verificado e como, **o que não foi verificado**, o que ficou fraco. Nunca "pronto" sem a prova do item 3. **Um efeito/ajuste por vez**; esperar a aprovação antes de seguir (memória: `vfx-show-running-game-then-wait`).

## 5. Quando o criador disser que está ruim

**Não remendar.** Reler as palavras literais; achar a **causa com dados** (contagem de camadas, tempos, quadros); corrigir só aquilo; reverificar o checklist inteiro; mostrar. Se a causa for o Motion Composer, corrigir o Motion Composer.

## 6. Armadilhas já pagas (não repetir)

- M16 (explosão direcional) precisa de **duas camadas**: OFFSET (move) e MULTIPLY_ATTRIBUTE (dissipa). Só com OFFSET a opacidade nunca muda e o efeito fica preso na tela.
- O tiro atravessa o campo em ~0,3 s; na vista normal o alvo está a ~37 m: **tamanho em metros fixo fica invisível** lá. Decidir o tamanho pela **tela** (regra de distância do jogo), nunca pela altura do corpo.
- Fitas viradas para a câmera somem quando o tiro vai direto para longe da câmera: usar volume (quads/malhas), não fita fina.
- Hélice vista de frente vira anel.
- Restos (vórtices, fumaça, brasas) que ficam parados no meio do campo leem como "outro fogo": tudo que sobra precisa ter origem lógica e sumir.
- `String(float)` não existe no GDScript: usar `str()`.
- Não esconder camadas que deveriam continuar (vórtices dissolvendo) nem manter camadas que deveriam acabar (cabeça e corpo depois do pouso).
