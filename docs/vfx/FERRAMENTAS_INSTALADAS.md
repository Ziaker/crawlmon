# Ferramentas de VFX instaladas (2026-11-06)

> Instaladas para **apoiar a criação de efeitos de qualidade**, não para criar efeito nenhum por conta própria. O VFX continua **pausado** (D-953); nenhum Move, regra ou efeito existente foi alterado.

## Instaladas no projeto

| Ferramenta | Caminho | Licença | O que faz | Como usar |
|---|---|---|---|---|
| **VFX Animation Player** | `addons/vfx_animation_player/` | MIT (Mariano Javier Suligoy) | Faz o AnimationPlayer pausar/rebobinar `CPUParticles2D/3D` e `GPUParticles2D/3D`, permitindo **scrabrar** o efeito quadro a quadro. | Plugin já habilitado no `project.godot`; reinicie o editor. |
| **Brackeys' Particle Controls** | `addons/brackeys_particle_controls/` | MIT (Brackeys) | Painel no viewport para **play/pause/scrub** de partículas, inclusive vários nós juntos; cria uma cópia de preview e não toca nos nós originais. | Plugin já habilitado; reinicie o editor. |
| **TrailRenderer** | `addons/TrailRenderer/` | MIT (Hyrdaboo) | Trilha/ribbon **3D** estilo Unity TrailRenderer; útil para smear de arma/membro, rastro de corrida e impacto. | Não é plugin: use o script `Runtime/GD/trail_renderer.gd` num `Node3D`. A versão C# existe, mas o projeto é GDScript. |

## Instalada e removida

- **VFX Library / Godot-VFX** (MIT, 35+ efeitos 2D e 17+ shaders): foi instalada, mas o plugin registra os autoloads `VFX`/`EnvVFX` e o editor reportou **erros de UID/autoload**; removida para não arriscar o projeto. Pode ser testada isolada depois, sem habilitar os autoloads.

## Não instaladas (externas ou pagas)

- **Pixelpart** — editor 2D/3D (US$ 24,99) + plugin Godot MIT; testar o demo antes.
- **EmberGen** — fogo/fumaça/explosão em flipbook (pago, com trial); o flipbook funciona em qualquer renderer.
- **Pixel Dreamer VFX Collection** — 1.187 efeitos `.tscn` (pago); o autor afirma Compatibility.
- **Vefects / FULGUR** — packs grátis/pagos com “Forward+ recommended”; não são GL Compatibility garantidos.
- **Particle Scene Compositor** — MIT; instalação com popup e componentes C#/GDScript; testar depois se fizer falta.

## Cuidados

- O jogo está em **GL Compatibility**: priorizar `CPUParticles3D`, malhas, shaders e flipbooks; **não** contar com GPUParticles, decals, sub-emitters ou trails de partícula.
- As duas ferramentas de preview (VFX Animation Player e Brackeys) podem disputar o mesmo espaço do editor; se houver conflito, deixe **uma** habilitada por vez.
- Nada foi commitado ou enviado. O checkout já tinha mudanças de outras sessões.
