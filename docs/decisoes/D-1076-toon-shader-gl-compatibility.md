# D-1076 — Restaurar o filtro toon do overworld no `gl_compatibility`

- **Data:** 2026-11-09.
- **Área:** Exploração / visual 3D / shaders.
- **Relacionadas:** D-1028 (toon no overworld), D-1023 (lab), D-1063 (NPCs).
- **Status:** **teste implementado e verificado** no lab isolado; renderer global mantido em `gl_compatibility`; batalha, 2D, status/menus não mudam; commit local; **sem push**.

## O que o criador disse (literal)

> inclusive cade o filtro toon que tinha:

## Diagnóstico

O `project.godot` está em **`renderer/rendering_method="gl_compatibility"`**. Nesse renderer, `BaseMaterial3D.DIFFUSE_TOON`/`SPECULAR_TOON` (o filtro usado por D-1028) **não é aplicado**; por isso os modelos/cenário ficam com sombreamento liso. O código do lab continua chamando `_apply_toon`, mas o efeito nativo é ignorado.

## Decisão

1. **Manter o renderer global em `gl_compatibility`.**
2. **Criar um shader toon espacial próprio** para o overworld, aplicado aos modelos e ao cenário da Murky Forest:
   - bandas de luz (3 níveis), sem PBR;
   - rim leve, como o toon antigo;
   - preservar **albedo color/texture**, emissão e transparência dos materiais existentes;
   - não aplicar em materiais `unshaded` (olhos/decais, partículas, mini-mapa).
3. **Onde aplicar:** `_apply_toon` do `murky_forest_3d_lab.gd` e `_toon_mat` do cenário. O lab de pedra D-1023 e a batalha 3D não são tocados.
4. **Sem contorno preto** por enquanto: D-1028 definiu toon + rim; contorno é uma decisão visual nova.
5. **Escopo:** só o overworld 3D; batalha, 2D, UI e regras não mudam.
6. **Se o shader não compilar/iluminar no Compatibility:** voltar e reportar antes de trocar o renderer global.

## Ambiguidades

- **Número de bandas:** 3 (o antigo toon tinia 3 níveis); ajustável.
- **Contorno:** não incluído; se o criador quiser, é uma decisão nova.
- **Custo/performance:** o shader é simples, mas não foi medido em 60 fps/mobile.

## Teste implementado (2026-11-09)

- **Shader:** `shaders/toon_overworld.gdshader` (spatial, `specular_disabled`, 3 bandas de luz, rim, albedo color/texture, emission).
- **Aplicação:** `murky_forest_3d_lab.gd` (`_toon_mat` e `_apply_toon`) converte os materiais `BaseMaterial3D` do cenário, player, aliados, inimigos e NPCs; materiais `unshaded` (olhos/decais, partículas, mini-mapa) continuam fora.
- **Teste no `gl_compatibility`:** a captura isolada (`murky_forest_hud_sugimori.png` e `murky_forest_status_hidden.png`) mostra os modelos/cenário com bandas de toon; sem erro de shader.
- **Texturas:** Abra, Pancham, Orc, Slime e NPCs mantêm as texturas; a iluminação é quantizada.
- **Escopo:** o lab de pedra D-1023, a batalha 3D, o 2D e a UI não foram tocados.
- **Cena principal:** o teste foi no projeto isolado (mesmo `gl_compatibility`); a cena principal em headless continua bloqueada pelos erros de VFX de outra sessão.

## O que não foi verificado

- Contorno preto: não incluído (D-1028 definiu toon + rim; contorno seria decisão nova).
- Custo/performance em 60 fps, mobile/web e muitas luzes.
- Se o shader cobre todos os casos de transparência/alpha (os materiais unshaded continuam separados).
- A cena principal em headless/janela enquanto os VFX de outra sessão estiverem quebrados.

## Estado

Teste implementado e verificado no lab isolado com `gl_compatibility`; toon de 3 bandas + rim restaurado no overworld, renderer global mantido. Provas registradas; commit local; **sem push**. Batalha/2D intactos.
