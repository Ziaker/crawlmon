<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# GPUTrail

GPUTrail is a GPU-based trail plugin for Godot 4, offering an efficient alternative to CPU-based trails for creating ribbon trail effects in your games and applications.
![heart](https://github.com/celyk/GPUTrail/assets/50609684/a190fee3-682b-42b9-9bef-cd49a5e3b99c)

## Features

- GPU-accelerated trail rendering for improved performance
- Customizable trail length, texture, and color
- Support for color ramps and width curves
- Options for texture orientation and alpha channel handling
- Billboard mode for camera-facing trails
- Dewiggle and clip overlaps features for improved trail appearance

## Installation

1. Clone or download this repository
2. Copy the folder into your `addons/`, so that the root of this repo is located at `res://addons/GPUTrail`
3. Enable the plugin in your project settings: Project -> Project Settings -> Plugins -> GPUTrail

## Usage

1. Add a new `GPUTrail3D` node to your scene
2. Customize the trail properties in the Inspector panel
3. Attach the `GPUTrail3D` node to the object you want to trail

## Properties

- `length`: Number of steps in the trail
- `texture`: Main texture of the trail
- `color_ramp`: Color gradient along the trail's length
- `curve`: Width modulation along the trail's length
- `vertical_texture`: Adjust texture orientation
- `use_red_as_alpha`: Use the red channel of the texture as alpha
- `billboard`: Make the trail face the camera (experimental)
- `dewiggle`: Improve texture mapping to the trail
- `clip_overlaps`: Prevent trail self-intersectionis
- `snap_to_transform`: Snap the trail start to the node's position, and regardless of the particles own framerate

## Example

```gdscript
var trail = GPUTrail3D.new()
trail.length = 100
trail.texture = preload("res://trail_texture.png")
add_child(trail)
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgements

- Tutorial by Le Lu: [YouTube Video](https://www.youtube.com/watch?v=0VsEfP4XFCM)

## TODO

- Add flipbook support
- Hide the actual GPUParticles3D node
- Restructure code, use enums for flags
- Add more polygons, make trail smoother
- Add an acceleration parameter
- Port to Godot 3.5
- Port to 2D
- Allow custom material
