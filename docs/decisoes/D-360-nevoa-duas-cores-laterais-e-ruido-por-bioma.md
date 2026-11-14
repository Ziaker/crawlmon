<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-360 — Névoa com duas cores laterais e ruído próprio por bioma

- **Data:** 2026-11-06
- **Área:** Exploração / visual / névoa
- **Origem:** O criador apontou que a névoa continuava com o mesmo desenho nos dois lados e entre biomas; só a cor do ambiente tinha mudado.

## O que o criador disse (literal)

> eu acho que até agr vc não entendeu o que eu pedi pra vc mudar na nevoa, ainda tá igual... to falando disso, dos dois lados, diferentes pra cada bioma, não sei o que vc tava mexendo antes

## Decisão

1. **Duas cores laterais por bioma.** O preset de névoa agora tem `color` (esquerda) e `color_b` (direita), com `side_mix`; o shader mistura as duas ao longo do eixo X. O lado esquerdo e o direito da névoa não são mais a mesma cor:
   - 4th verde-escuro → verde-lima; 7th azul-escuro → ciano; dark ice azul → azul vivo; peak índigo → violeta;
   - barren marrom → areia; deep boulder vinho → rosa; deep limestone âmbar → laranja; limestone oliva → amarelo;
   - murky vinho → violeta; spacial cinza-escuro → cinza-claro; Temporal/Spire azul-aço → azul.
2. **Ruído próprio por bioma.** `BiomeVisuals.FOG` define `noise_type` (`SIMPLEX_SMOOTH`, `SIMPLEX`, `CELLULAR`, `PERLIN`, `VALUE_CUBIC`), `noise_frequency`, `noise_octaves`, `noise_seed`, `noise_scale` e `noise_scale_b`. O `fog_of_war.apply_biome()` cria um `NoiseTexture2D` novo e troca no shader; a névoa de gelo é celular/cristalina, a de areia é Perlin larga, a de floresta é simplex suave, a de caverna é cubic.
3. **O shader** ganhou `fog_color_b`, `side_mix`, `noise_scale` e `noise_scale_b`; o `fog_color` antigo continua sendo o lado esquerdo. O `pattern` e o `warp` usam o ruído do bioma.
4. **O que não muda:** a máscara de visibilidade, o raio 7,5, a LOS, o explorado permanente, o tamanho 48 px, a câmera 2,3×, a geração do mapa e a posição da névoa acima das entidades. O laboratório continua sem névoa (só ambiente); a névoa é da cena do jogo.
5. **Cores laterais no contato in-game:** `docs/referencias/tilesets/biomes_ingame_contact.png`. O contato do laboratório (`biomes_contact.png`) mostra só o ambiente, porque não tem explorado/névoa.

## Estado

Implementado: 16 presets com duas cores laterais + ruído/scale próprios, shader atualizado, `fog_of_war` recriando o `NoiseTexture2D` por bioma, 16 capturas in-game regeneradas, baseline de brilho OK. O jogador continua sem luz dinâmica; as tochas continuam removidas; a única `PointLight2D` é a vermelha dos inimigos. Paredes 6.970/0; fallback 688/0; decals 8,1%/0; golden 0,60/0,61. Nada foi publicado.
