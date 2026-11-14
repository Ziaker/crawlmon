<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# Biblioteca de projéteis: Electric (feixe dourado). Plano de implementação

> **Para agentes:** sub-skill obrigatória: superpowers:subagent-driven-development ou superpowers:executing-plans. Passos com checkbox (`- [ ]`).

**Objetivo:** primeiro item da biblioteca de VFX de projéteis: o feixe Electric dourado em 6 fases, para 1 ou vários alvos, verificado na batalha real nas duas vistas.

**Arquitetura:** uma base `ProjectileLibVfx` define as 6 fases e o contrato com o jogo (posições reais e relógios). Cada elemento é uma subclasse que só desenha. O efeito principal (feixe, clarões, estouro) é feito à mão com malha e shader (D-956). O Motion Composer cuida só do secundário (faíscas residuais) e do timing. A ligação com a batalha reaproveita os ganchos que o `ElementMoveVfx` já usa (`fx_telegraph`, `fx_projectiles`, `fx_impacts`), por `move_id`.

**Tecnologia:** Godot 4.7.2, `gl_compatibility`, GDScript, `.gdshader`, CPUParticles3D, skills `scenario-godot-vfx`, `scenario-godot-shaders` e `scenario-godot-expert`.

**Especificação:** `docs/decisoes/D-955`, `D-956`, `D-957` e o dossiê `docs/vfx/referencias/projeteis/reports/Referências de projéteis por elemento.md`.

## Restrições globais

- Fases: Start → Wind-up → Release → Trajectory → Impact → Post-impact (D-956). Start = efeito que dispara o wind-up; Post-impact = a dissipação do impacto.
- Forma: feixe contínuo do lançador ao alvo, com fios elétricos; paleta dourada da Zeri (D-957). Referências: Zeri W `YSC--wQc-Jc` 01:21–01:26 (trajeto); Zio de P5R `PEFYE4pyb7c` 02:30–02:35 (impacto).
- Múltiplos alvos: vários feixes de uma vez, um por alvo (D-956).
- Principal à mão; Motion Composer só no secundário e no timing (D-954, D-956).
- Nada depende de personagem, time, lado ou coordenada fixa; tudo vem do atacante e do alvo reais (D-235, AGENTS §7).
- Visual não muda regra, tempo, dano nem ordem de eventos (D-019, D-003).
- GL Compatibility: sem GPUParticles, decals, sub-emitters nem trails de partícula.
- Tamanho fixo no mundo, igual nas duas vistas (D-308 item 6, D-334).
- Nada sobra na tela depois do Post-impact.
- Um ajuste por vez; vídeo normal + espelhado; esperar aprovação (D-308, memória).
- Sem commit nem push sem pedido (D-022).

## Respostas do criador (D-957)

1. Post-impact todo dourado.
2. Sem Glow: brilho só por cor e bandas.
3. Vários feixes também no combate. **Isso exige uma decisão de combate à parte** (conflito com D-007/D-009, "onda única"). Até lá, as Tarefas 2–6 fazem 1 alvo na batalha real e vários alvos no laboratório (Tarefa 5); a ligação de vários alvos ao combate vira uma tarefa nova depois dessa decisão.
4. Start nos primeiros instantes do wind-up.

## Foco de revisão

- Alvo que se move durante o feixe: o feixe tem de seguir o corpo (D-047), sem saltar.
- Alvo que morre no voo (D-109): o feixe termina sem estouro de impacto.
- Desvio perfeito (Evade): o feixe passa pelo ponto mirado e se apaga, sem impacto.
- Alvos de tamanhos diferentes (0,8 / 1,4 / 2,4 m): o ponto de impacto fica no corpo.
- Vista espelhada com alvo colado à câmera: o feixe não pode cobrir a tela.

---

### Tarefa 0: Documentação antes do código

**Arquivos:** `docs/vfx/PROTOCOLO_VFX_OBRIGATORIO.md` (seção 0), `docs/decisoes/D-957-*.md`, `docs/REGRAS_DO_JOGO.md`.

- [ ] Registrar as respostas das 4 pendências na D-957.
- [ ] Protocolo, seção 0: para a biblioteca de projéteis vale D-954/D-956 (principal à mão, Composer no secundário); citar a decisão.
- [ ] Escrever na D-957 o checklist literal: uma linha verificável por frase do criador (feixe, dourado, fios elétricos, 6 fases, vários alvos de uma vez, nada sobra).
- [ ] Atualizar `REGRAS_DO_JOGO.md` (D-061), só documentação.

### Tarefa 1: Medir os tempos reais

**Arquivos:** criar `tests/vfx/projectile_lib/measure_phases.gd`.

- [ ] Script headless que roda a sala de VFX com um Move de projétil existente e registra em JSON a duração real do wind-up, do trajeto (alvo longe e perto) e o instante do impacto.
- [ ] Rodar e anotar os números na D-957. As durações das 6 fases saem desses números, não de palpite.

### Tarefa 2: Base da biblioteca e contrato das fases

**Arquivos:** criar `scripts/combat/fx/projectile_lib/projectile_lib_vfx.gd` e `tests/vfx/projectile_lib/test_contract.gd`; modificar `fx_telegraph.gd`, `fx_projectiles.gd`, `fx_impacts.gd` e `scripts/data/skill.gd` (novo `Skill.library_skills()`); `scripts/debug/vfx_room.gd` lista esses Moves só na sala.

**Interfaces produzidas:**
- `class_name ProjectileLibVfx extends Node3D`, `enum Phase { START, WINDUP, RELEASE, TRAJECTORY, IMPACT, POST }`.
- `static func begin(fx: BattleFx, move_id: String, src: Vector3, targets: Array[Vector3], windup: float) -> ProjectileLibVfx`.
- `func release(from: Vector3, to: Array[Vector3]) -> void`, `func set_travel(i: int, from: Vector3, to: Vector3, progress: float) -> void`, `func hit(i: int, pos: Vector3, dir: Vector3) -> void`, `func miss(i: int) -> void`.
- Subclasses sobrescrevem `_draw_phase(phase: Phase, t_local: float, beam_i: int) -> void`; a base não tem aparência.
- `const IDS := ["electric_beam"]`; Move de laboratório `Skill.new("Electric Beam", 1.0, 2, Element.Type.<Electric>, Kind.PROJECTILE, ...)` com o wind-up medido na Tarefa 1.

- [ ] Teste: ordem das fases é START < WINDUP < RELEASE < TRAJECTORY < IMPACT < POST; `begin` com 3 alvos cria 3 feixes; após o fim do POST o nó se libera e a contagem de nós volta à base; trocar atacante/lado não muda tamanhos em metros.
- [ ] Rodar: falha. Implementar. Rodar: passa.

### Tarefa 3: Shader do feixe

**Arquivos:** criar `shaders/lib_electric_beam.gdshader`, `shaders/lib_electric_common.gdshaderinc`; malha do feixe gerada em `scripts/combat/fx/projectile_lib/electric_beam_vfx.gd`.

- [ ] Feixe = faixa/tubo esticado entre origem e alvo; uniforms `extend` (0→1, Trajectory), `fade` (Post-impact), `jag_seed` trocado em degraus (fios elétricos em zigue-zague), núcleo claro e borda dourada em bandas duras (D-038/D-323).
- [ ] `gd_shaders.lint` sem erro; `compile_matrix` e `draw_check` em `gl_compatibility` sem erro; `param_sweep` de `extend` e `fade` com folha de quadros: monotônico e sem sobra em `fade = 1`.

### Tarefa 4: Start, Wind-up, Release, Impact, Post-impact

**Arquivos:** `electric_beam_vfx.gd` (só desenho), flipbook/quad para clarões, CPUParticles3D para faíscas.

- [ ] Start: estalo dourado curto. Wind-up: brilho crescendo com faíscas em zigue-zague, que **não some** e vira o disparo (D-308 item 5). Release: clarão na boca. Impact: estouro de faíscas com referência no Zio. Post-impact: feixe e faíscas se apagam (resposta da pendência 1).
- [ ] `gd_vfx.audit` com 0 erros; faíscas residuais pelo Motion Composer (preset `MotionPresets.electric_residue`), com teste da suíte do Composer.

### Tarefa 5: Laboratório de vários alvos

**Arquivos:** criar `tests/vfx/projectile_lib/electric_lab.gd` e `.tscn` (câmera de batalha do jogo, alvos de 0,8 / 1,4 / 2,4 m, 1 e 3 alvos, normal + espelhado).

- [ ] Capturar quadros em tamanho real nos instantes de cada fase; checklist literal ✔/✘ com o quadro que prova; procurar o que não deveria existir.

### Tarefa 6: Verificação na batalha real e entrega

- [ ] `vfx_room` com 2 atacantes diferentes, vista normal e espelhada, alvos de tamanhos diferentes (AGENTS §7).
- [ ] Medir: nós aos 4 s = base; contagem de camadas por fase; tempos reais das fases.
- [ ] Vídeo: `python tests/fx_lab/record_move_video.py "Electric Beam" test_captures/electric_beam_v1.mp4`.
- [ ] Entregar: checklist, o que foi verificado, o que não foi, o que ficou fraco. Esperar a aprovação antes do próximo elemento.
