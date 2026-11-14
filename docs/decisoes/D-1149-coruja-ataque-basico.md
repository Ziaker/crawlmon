<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1149 — Ataque básico da coruja

> ataque basico agora, veja o cyclops como referencia

Ao esclarecer a adaptação da clava do Cyclops, o criador respondeu **“Com uma garra, de cima para baixo”**.

Criar no Blender uma batida descendente de uma garra, usando a animação de ataque básico do Cyclops `cm_00_0065_11` como referência de preparo, descida e recuperação. Usar a garra esquerda, que corresponde à mão da clava na referência. O arquivo é de autoria de animação. Nenhuma regra de combate é definida por esta decisão.

V1 salva em `assets/modelos/owl/blender/owl_attack_basic_v1.blend`, Action `Attack 1 Cyclops Claw Smash`, com apenas a coruja na cena. O clipe vai do quadro 1 ao 53 a 24 fps. A garra fica alta no quadro 15 e chega à batida no 19. A trajetória usa direções amostradas do braço do Cyclops, com ajustes para afastar a garra do rosto durante o preparo e do pé na recuperação. Folhas e curvas do Motion Lens abertas em `evidence/attack_v1_lens/`. Sem interseção do braço esquerdo com a cabeça ou perna esquerda nas 105 amostras, com pés sem deslizamento e retorno idêntico ao idle. O Lens registra pele até 11 mm abaixo do plano Z=0 e alerta de velocidade na descida rápida. Aprovação visual e integração no jogo pendentes.
