<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# Corte de vento em faixa (Wind Slash Band) — descrição de código

- **Efeito:** Corte de vento em faixa. **Move:** Sand Attack (`tiro_areia`). Decisão: D-1214.
- **Par visual:** `Corte-de-vento-em-faixa--visual.md`.
- **Arquivos:** `scripts/vfx/combat/fx_sand_attack.gd` (classe `FxSandAttack`), `shaders/dust_slash.gdshader`, gatilho em `scripts/combat/battle_fx.gd` (`on_phase`).
- **Técnica:** malha de fita procedural (`ArrayMesh`, 49 pares de vértices) + shader `spatial` unshaded com varredura, fade e dissolução por ruído controlados por **um único uniform de tempo**. Nenhuma textura, nenhuma partícula real: os "grãos" são ruído no fragment shader.

## Receita em 6 passos (para reproduzir em outro Move)

1. **Medidas do atacante.** Pegue `height` (altura do corpo medida do modelo, `_body_height`) e a direção `fwd` = (alvo − atacante) no plano XZ, normalizada. Nunca use coordenadas fixas (D-235).
2. **Gere a fita.** Para `i` de 0 a 48, `f = i/48`: ângulo `ang = π/2 − turn/2 + f·turn` (arco centrado na frente local +Z), centro `c = (cos(ang)·R, Y + f·RISE, sin(ang)·R) · height`, meia largura `w = WIDTH · sin(π·clamp(f,0.02,0.98))^0.7 · 0.5 · height`, e `across = radial × tangente` (vertical quando RISE=0). Vértices `c ± across·w`. UV.x = `1 − f` (a varredura começa em f=1, a ponta de baixo depois da inclinação), UV.y = 0/1 nas duas bordas. Dois triângulos por segmento.
3. **Oriente a fita.** `Transform3D(Basis(fwd, deg_to_rad(TILT)) * Basis(side, UP, fwd), start_pos + fwd·height·AHEAD)` com `side = UP × fwd`. O eixo local +Z da malha é a frente (o shader usa isso na deriva). A inclinação de 20° é um *roll* em torno de `fwd`.
4. **Material.** `ShaderMaterial` com `dust_slash.gdshader`, `render_priority = 9`, uniforms `u_sweep`, `u_life`, `u_drift = DRIFT·height` (metros). `cast_shadow = OFF`.
5. **Relógio.** Guarde `{node, mat, t}`; a cada `process(delta)` faça `t += delta`, `mat.set_shader_parameter("u_age", t)` e `queue_free()` quando `t > SWEEP + LIFE`. O `delta` é o do `Battle` (vem de `BattleFx.process`), então a pausa de status congela o efeito (D-031/D-1150).
6. **Giro do atacante.** Em paralelo guarde `{model, base_yaw, t}` e, enquanto `t < SWEEP`, ponha `model.rotation.y = base + TAU · SPIN_TURNS · smoothstep(t/SWEEP)`; no fim restaure `base`. Funciona porque o `process` do `FxSandAttack` roda **depois** do laço que escreve a rotação de espera (`battle_fx.gd`, perto da linha `fx_sand_attack.process(delta)`).

## Constantes (todas em `fx_sand_attack.gd`)

| Constante | Valor | Origem | O que controla |
|---|---|---|---|
| `SLASH_SWEEP` | 0,35 s | **criador** | tempo para a cabeça varrer o arco |
| `SLASH_TILT` | 20° | **criador** | roll do plano do golpe (diagonal) |
| `SLASH_RISE` | 0,0 | **criador** (horizontal) | subida ao longo do arco; 0 = plano |
| `SPIN_TURNS` | 1,0 | **criador** | voltas do corpo do atacante |
| `SLASH_TURN` | 540° | criador ("volta e meia") | extensão do arco |
| `SLASH_LIFE` | 0,7 s | IA | duração da dissipação de cada trecho |
| `SLASH_WIDTH` | 0,49 | IA (≥35% sobre 0,36) | largura máxima, em alturas do corpo |
| `SLASH_RADIUS` | 1,05 | IA (0,7 × 1,25 × 1,2) | raio, em alturas do corpo |
| `SLASH_Y` | 0,6 | IA | altura do arco, em alturas do corpo |
| `SLASH_DRIFT` | 1,5 | IA | avanço da dissipação para a frente, em alturas do corpo |
| `SLASH_AHEAD` | 0,0 | IA | deslocamento do centro à frente (0 = em torno do corpo) |
| opacidade máx. | 0,8075 | criador (0,95 − 15%) | `ALPHA = 0.8075 · …` no shader |
| cores | núcleo (1,0, 0,95, 0,2); borda (1,0, 0,82, 0,05) | IA ("mais amarela") | `u_core`, `u_edge` |

Histórico dos valores (para entender o "porquê"): largura 0,2 → 0,28 → 0,45 → 0,3 → 0,36 → 0,49; raio 0,7 → 0,875 → 1,05; arco 200° → 240° → 540°; opacidade 0,95 → 0,8075.

## Shader `dust_slash.gdshader` (lógica)

- `render_mode unshaded, blend_mix, depth_draw_never, cull_disabled`.
- `age = u_age − UV.x · u_sweep`: cada ponto tem o seu relógio; quem tem UV.x menor nasce primeiro.
- `born = smoothstep(0, 0.05, age)`; `k = clamp(age/u_life, 0, 1)`; `fade = 1 − k`.
- Dissolução: `grain = 0.6·vnoise(along·30, UV.y·12 + u_age·3) + 0.4·hash(floor(along·90, UV.y·30))` e `dissolve = smoothstep(1.1k − 0.15, 1.1k, grain)`: o limiar sobe com `k`, os pixels de grão baixo somem primeiro (parecem partículas saindo).
- `body = 1 − smoothstep(0.55, 1.0, across + 0.25k)`: borda suave que encolhe ao dissipar.
- `ALBEDO = mix(u_core, u_edge, smoothstep(0.2, 1, across))`; `ALPHA = 0.8075 · born · fade · dissolve · body`.
- `vertex()`: `VERTEX += (0,0,1) · u_drift · kv` com o mesmo `k` por vértice: a dissipação escorre para a frente (+Z local = direção ao alvo).

## Gatilho e temporização (a parte que mais enganou)

- O plano do ataque de projétil é `[[STRIKE, hit], [TRAVEL, fly], [RETURN, …]]` (`attack_planner.gd`, ramo `Skill.Kind.PROJECTILE`). Depois do wind-up vem a fase STRIKE (animação de lançar, ~0,8 s) e só então o TRAVEL.
- O criador pediu o release **imediato após o wind-up**: por isso `BattleFx.on_phase` chama `fx_sand_attack.start(inc)` em `Phase.STRIKE` **e** em `Phase.TRAVEL` (a segunda chamada é ignorada, `_active.has(inc)`).
- O jato sai 0,06 s depois (`JET_DELAY`, HTML 2780). O tempo é contado em `process` somando `phase_time` da própria fase (`last_phase`/`last_pt`/`elapsed`) para sobreviver à troca STRIKE→TRAVEL e congelar na pausa de status.
- Mecânica intocada: o acerto, a cegueira e a esquiva continuam onde estavam (STRIKE→TRAVEL→impacto), então o visual termina ~0,5 s antes do acerto. Mudar isso é mudança de regra (`AttackPlanner`), não de VFX.

## Armadilhas encontradas (não repita)

1. **Faixa existia mas não aparecia.** Cor escura sobre o piso escuro e o atacante cobrindo a parte inicial. Cor clara + `render_priority` alto resolveu. Para depurar: troque o shader por `ALBEDO=vec3(1,0,0); ALPHA=1;` e veja se a geometria está certa antes de mexer na lógica.
2. **Varredura ao contrário.** `UV.x = f` começava na ponta de cima; o criador queria por baixo. Foi corrigido invertendo para `UV.x = 1 − f`, sem mexer na geometria.
3. **Hélice errada.** A primeira leitura de "movimento helicoidal" gerou uma espiral que sobe; o criador queria um arco horizontal em volta do corpo (`SLASH_RISE = 0`).
4. **Janela antiga aberta.** Reabrir o jogo sem fechar o anterior mostrava código velho: use `taskkill //F //IM Godot_v4.7.2-stable_win64.exe` antes de relançar.
5. **Poucos quadros no corte.** A gravação sai a ~0,13 s por quadro; o corte tem 0,35 s de varredura. Use `--step=0.05` e confira o `log.txt` para os tempos reais.
6. **Hook de segurança** bloqueia `rm -rf`; para apagar capturas, peça ao criador ou mova a pasta.

## Como testar (menos de 10 s)

```bash
./Godot_v4.7.2-stable_win64.exe --path . scenes/debug/vfx_room.tscn -- --scenario=sand_attack
./Godot_v4.7.2-stable_win64.exe --path . scenes/debug/vfx_room.tscn -- --scenario=sand_attack --record=2.2 --step=0.05 --out=docs/vfx/sand_attack_ref/teste --quit
./Godot_v4.7.2-stable_win64_console.exe --path . scenes/debug/vfx_room.tscn -- --scenario=sand_attack --stdout-trace --quit
./Godot_v4.7.2-stable_win64.exe --path . scenes/debug/vfx_room.tscn -- --scenario=sand_attack --mirror --audit-leaks --audit-delay=3 --quit
```

O último comando (vista espelhada com auditoria de restos) **não foi rodado depois do corte** (ver D-1214, "NÃO verificado"). Rode-o antes de reutilizar a técnica em outro Move.

## Para reutilizar em outro Move

- Copie `_spawn_slash`, o laço de `_move_release` que cuida de `_slashes`, o shader e as constantes; troque `SLASH_*` pelos valores do novo Move.
- Ligue o `start` na fase certa do `BattleFx.on_phase` e limpe em `cancel`/`clear_all` (`_slashes`, `_spins`).
- Troque as cores `u_core`/`u_edge` por paleta de elemento; o resto é independente de cor.
- Mantenha tudo em função de `height` e `fwd` medidos (D-235) e teste na vista espelhada.

## Outros VFX do mesmo release que ainda não têm ficha

Rastro escuro no chão (`dust_wind_strip.gdshader`, `_spawn_strip`: faixa de 3 m × distância atacante-alvo a 0,12 m do piso, mesma lógica de `age = u_age − along·u_travel`, vida 0,64 s, opacidade 0,8); anel de nuvens, véu e cone que viajam (`_movers`, `_move_release`); poeira solta emitida a cada 0,09 s ao longo do caminho (`cloud_ring(..., emit_dust=false)`). Catalogue-os aqui quando o criador pedir.
