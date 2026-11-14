<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-343 — Heal Gain: opção 2 (Persona Kinetic Cross) no jogo, cruzes verdes em flipbook e lado direito limpo

- **Data:** 2026-11-06
- **Área:** HUD / VFX / Motion Composer
- **Origem:** Conversa. O criador enviou o arquivo `prot_tipo_de_redesign_heal_gain_22_godot_3d_battle.html` e escolheu a opção 2.

## O que o criador disse (literal)

> "vamos seguir com a opção 2, implemente-a no jogo, mas com efeitos visuais de cruzes verdes subindo brilhando junto, re-leia os docs relacionados a efeitos visuais e como fazer eles corretamente, usando as skills e o flipbook do godot, me surpreenda sem mudar o texto extilizado da opção 2 do html"

> "Sem a notificação na direita, use o protótipo corretamente"

## Decisão

1. O número de cura flutuante (`+HP`) passa a usar a **opção 2 — Persona Kinetic Cross** do HTML: dígitos em Kanit Black Italic, cor `#B7FFC9`, inclinação de −4°, cruz assimétrica em `#A8FFC4`, faísca em diamante `#F4FFF7`, recorte/sombra sólida `#08150E` e barra tática inferior com ponta chanfrada e ponto branco.
2. O **texto exibido não muda**: a cruz assimétrica faz o papel do sinal de mais e os dígitos mostram o valor real da cura. Não acrescentar um `+` extra nem trocar o número por outro conteúdo.
3. Junto do número sobem **cruzes verdes brilhantes**, construídas sobre o **Motion Composer** e pintadas pelo **flipbook** do jogo (`assets/vfx/flipbook_heal_cross.png`, 4×4, 16 quadros). O flipbook é a representação da camada; o movimento (subida, anel, atraso e desvanecimento) vem de uma composição M26.
4. O **lado direito do HUD fica limpo**, como no protótipo: a notificação/log alinhada à direita não é exibida. O sinal `Battle.log_message` e o histórico continuam existindo internamente; só a caixa visual da direita deixa de aparecer.
5. O número de cura é **HUD ancorado no alvo real** (posição derivada de `BattleFx._home`), com tamanho fixo na tela para continuar legível nas duas vistas. É desenhado em 2D na camada de HUD (hoje um `Control` dentro do `BattleHud`, com o `SubViewport` do desenho), para as cores `#B7FFC9`/`#A8FFC4` ficarem exatas (o tonemap Filmic da batalha desaturava o quad 3D). As cruzes são VFX do Motion Composer, com origem no próprio número; a escala do anel, da cruz e da subida vem da distância da câmera (referência 4 m, limites 0,5–2,2) para ler igual nas duas vistas. Nada depende de personagem, time, lado ou coordenada fixa (D-235). Este efeito não é um dos oito do Atelier de D-334: a escala de câmera acompanha o número, que já é HUD.
6. O efeito é estritamente visual e segue o relógio do `Battle` pelo sinal `healed` (D-019). Não altera cura, tempos de combate, dano ou regras.

## Ambiguidades

Nenhuma quanto ao visual pedido. Detalhes de curva, duração e quantidade de cruzes foram escolhidos na implementação e podem ser ajustados pelo criador sem mudar as regras acima.

## Estado no código

- Implementado em `scripts/combat/fx/heal_gain_mark.gd`, `scripts/combat/fx/heal_gain_fx.gd`, `scripts/combat/fx/fx_text.gd`, `scripts/motion_composer/runtime/motion_presets.gd` e `scripts/ui/battle_hud.gd`.
- O flipbook é reproduzível por `tests/vfx/bake_heal_cross.gd` (corpo verde `#78F0A4`, núcleo `#B7FFC9`, halo `#53E28B`, faíscas brancas).
- Verificação: capturas em tamanho real nas duas vistas e vídeo normal + espelhado. Vídeo final: `test_captures/HealGain_option2_normal_espelhado.mp4` (1280×720, normal em cima e espelhado embaixo).
- Medição de cor no quadro da batalha: dígitos `#B7FFC9` e cruz `#A8FFC4` (os valores exatos do HTML) na camada 2D; as cruzes somem até o fim do efeito.
- **D-347 (2026-11-06):** o número saiu de cima do personagem e passou para cima do `UnitCard`/`EnemyTag`, com rotação e diagonal por lado; as cruzes verdes continuam no personagem. O odômetro de HP foi arquivado e o HP/barra são imediatos.
- **Não verificado:** desempenho em hardware fraco e aprovação artística do criador.
