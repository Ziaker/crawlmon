# Protocolo obrigatório de VFX (D-308, ordem do criador, 2026-11-05)

> **Telemetria (D-1154):** antes de depurar ou anexar prova de VFX de combate, leia `docs/TELEMETRIA.md`. Use `--stdout-trace`/`--summary-json` como evidência; `queue.started` é Move que começou, `queue.lost` é vaga descartada.

**Vale para VFX de Move/elemento em combate: impacto, partícula, brilho e rastro de um Move.** Um VFX de Move feito fora deste protocolo está errado, mesmo que "pareça funcionar". **Não vale para clima/exploração** (névoa, calor ondulado, chuva/neve, distorção temporal): essas são camadas 2D de ambiente e não usam o Motion Composer (D-383).

## 0. Regra-mãe

O **Motion Composer é auxiliar e opcional** (D-1030). O VFX de Move/elemento em combate pode ser construído **à mão** com animação, malhas, flipbooks, shaders, partículas e câmera; não é obrigatório passar pelo Composer. Quando ele for usado, use as duas skills (`scenario-godot-vfx` e `scenario-godot-shaders`) e mantenha o movimento secundário/timing nele. Se o efeito escolhido precisar de algo que o Composer não faz, isso não bloqueia o efeito: o caminho à mão é permitido; melhorar o Composer é opcional. **Clima/exploração não é Move e fica fora deste protocolo (D-383).**

**Biblioteca de projéteis (D-956/D-957, 2026-11-07):** para os projéteis da biblioteca vale a D-954, escolhida pelo criador ("D-954: principal à mão"). O efeito principal (feixe/cabeça, clarões, impacto) é feito **à mão**, com malhas, flipbooks e shaders. O Motion Composer cuida só do **secundário** (faíscas, brasas, poeira, rastros) e do timing. As fases são seis: Start → Wind-up → Release → Trajectory → Impact → Post-impact. O resto deste protocolo (skills, checklist, duas vistas, vídeo, um ajuste por vez) continua valendo.

## 1. Antes de escrever uma linha (em ordem, sem pular)

1. **Citar as decisões aplicáveis** pelo ID (no mínimo: D-235, D-308 itens 1–3 e 5–11, D-044, D-045, D-043, D-019 e as do Move/personagem em questão). **D-019 foi renovada em 2026-11-09 (D-1040)** e volta a valer; D-1030 torna o Composer auxiliar. Abrir `docs/decisoes/` de verdade.
2. **Ler as referências do projeto** para o efeito: protótipos HTML em `prototypes/` e `docs/vfx/`, `docs/vfx/MOTION_COMPOSER_V1.md`, efeitos aprovados parecidos (`FireMoveVfx`, `AbraMoveVfx`), assets (`assets/vfx/`, `shaders/`).
3. **Carregar as skills com a ferramenta Skill**: `scenario-godot-vfx` e `scenario-godot-shaders` (e `scenario-godot-expert` para rodar/verificar). Escrever quais passos do fluxo delas serão aplicados neste efeito.
4. **Escrever o checklist literal**: cada frase do criador sobre o efeito vira uma linha verificável ("sem fogo secundário", "vórtices 0,2 s e 0,5 s", "cone no impacto nos dois lados"...). Nada de reinterpretar. Frase ambígua = **perguntar** antes (ex.: "tamanho fixo" = fixo em metros ou fixo na tela?).
5. **Planejar as 4 fases** (Wind-up, Release, Trajeto, Impacto) e a **transição contínua** entre elas (a carga não some: vira o tiro). Medir a duração real de cada fase no jogo (em segundos) antes de escolher tempos.

## 2. Como construir

- Se o Composer for usado, cada fase pode ser composta por **composições** (M01–M18 e o que vier) + **representações** (`MotionRep`: flames, streaks, embers, smoke, orb, glow, scorch, e novas) pintadas por `MotionPainter`, reunidas em um `MotionEffect` guardado em `MotionPresets`. Isso é opcional (D-1030); o caminho à mão é válido.
- A classe do Move (`ElementMoveVfx` ou equivalente) **só entrega** posições reais, relógios das fases e câmera. Nada de aparência nela.
- **Faltou comportamento, operação, representação ou preset?** Se o Composer for o caminho escolhido, implementar nele (com teste) e registrar a versão no `docs/vfx/MOTION_COMPOSER_V1.md` ou num `V1.x`. Se não, fazer à mão; não é obrigatório atualizar o Composer (D-1030).
- Independente de personagem, time e lado (D-235): tudo derivado de atacante, alvo, eixo, câmera. Testar normal e espelhado, alvos de tamanhos diferentes.
- Usar o que o Godot e o jogo têm: flipbooks, malhas (`shock_cone`, `slash_arc`, `ribbon_trail`), shaders com textura, partículas, brilho. Nada de "HTML genérico" (fitas finas, pontinhos, formas chapadas).
- GL Compatibility: sem GPUParticles, sem decals, sem sub-emitters.

## 3. Verificação (obrigatória antes de dizer qualquer coisa)

1. Rodar **na batalha real** (`scenes/debug/vfx_room.tscn`), **vista normal E espelhada**, com a câmera do jogo.
2. Olhar **quadros em tamanho real** (nunca só miniaturas ou colagens) **nos instantes de cada item do checklist**, nas duas vistas. Para cada linha do checklist: ✔ ou ✘ com o quadro que prova.
3. Medir com dados, não com impressão: quantidade de elementos por pincel/camada em cada instante, tempos reais das fases, sobras depois do fim (nada pode ficar na tela). **Usar obrigatoriamente as ferramentas de análise de VFX da sala (`D-1042` / `D-1044`):**
   - `--audit-leaks` para comprovar `[vfx_audit] leaks=0` (nenhum nó residual, partícula acesa ou luz órfã após o retorno);
   - `--envelope-graph` para garantir dissolução suave sem `[POP_DETECTED]`;
   - `--scale-overlay` e `--bg=gray|black|white` para validar tamanho em tela (px) a 30–37 m, teto de altura (1,2 m D-1013 / 2,5 m D-1033) e leitura de silhueta/contraste;
   - `--overdraw` e `--solo-node`/`--mute-node` para inspecionar camadas individuais e evitar estouro de branco;
   - `--bone-probe` e `--cam=macro` para verificar ancoragem em osso/soquete e sincronia no ponto de contato;
   - `--proof-sheet=<caminho.png>` e `--isolate-phase=windup|release|travel|strike|impact|return` para inspecionar as fases segundo a ficha visual do Move (`Skill.visual_phases()`).
4. **Procurar o que NÃO deveria existir** (fogo/restos fora de lugar, bolas paradas, camadas que não somem) tão ativamente quanto o que deveria.
5. Só então gravar o vídeo: **um único vídeo com as duas vistas em resolução cheia** (`tests/fx_lab/record_move_video.py`), e enviar.

## 4. Entrega

Dizer: o que foi pedido (checklist), o que foi verificado e como, **o que não foi verificado**, o que ficou fraco. Nunca "pronto" sem a prova do item 3. **Um efeito/ajuste por vez**; esperar a aprovação antes de seguir (memória: `vfx-show-running-game-then-wait`).

## 5. Quando o criador disser que está ruim

**Não remendar.** Reler as palavras literais; achar a **causa com dados** (contagem de camadas, tempos, quadros); corrigir só aquilo; reverificar o checklist inteiro; mostrar. Se a causa for o uso do Composer, corrigi-lo é uma opção; o efeito também pode ser corrigido à mão (D-1030).

## 6. Armadilhas já pagas (não repetir)

- M16 (explosão direcional) precisa de **duas camadas**: OFFSET (move) e MULTIPLY_ATTRIBUTE (dissipa). Só com OFFSET a opacidade nunca muda e o efeito fica preso na tela.
- O tiro atravessa o campo em ~0,3 s; na vista normal o alvo está a ~37 m: **tamanho em metros fixo fica invisível** lá. Decidir o tamanho pela **tela** (regra de distância do jogo), nunca pela altura do corpo.
- Fitas viradas para a câmera somem quando o tiro vai direto para longe da câmera: usar volume (quads/malhas), não fita fina.
- Hélice vista de frente vira anel.
- Restos (vórtices, fumaça, brasas) que ficam parados no meio do campo leem como "outro fogo": tudo que sobra precisa ter origem lógica e sumir.
- `String(float)` não existe no GDScript: usar `str()`.
- Não esconder camadas que deveriam continuar (vórtices dissolvendo) nem manter camadas que deveriam acabar (cabeça e corpo depois do pouso).
