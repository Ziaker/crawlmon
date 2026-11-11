# D-1062 — Regeneração de MP: 10 + MAG, barra azul que carrega e eco "+10MP"

- **Data:** 2026-11-09.
- **Área:** Combate / MP / HUD / eco textual.
- **Altera:** D-413 (a regeneração era +4 MP a cada 8 s). O intervalo de 8 s e o resto da D-413 continuam.

## Frase literal do criador

> a borda também devia afetar esse azul (deixe o azul mais parecido com o azul do MP e faça ela ser animada, como um carregamento que se preenche pra ocorrer a recuperação de mana, emitindo um eco textual "+10MP" (mude o valor recebido da recuperação de MP pra 10 pontos ao invés do valor que está hoje e faça-o escalar com MAG, 1 ponto extra para cada 5 mag até nivel 25, apartir dai é 1 ponto para cada 10 mag

Respostas às perguntas do assistente:

> Limiar: "MAG 25" · Barra azul: "Sempre" · Quem recupera: "Todos" · Eco: "Subir e sumir"

## Decisão

1. **Valor por pulso:** `10 + bônus de MAG`. Bônus = `MAG / 5` (arredondado para baixo) até **MAG 25** (no máximo +5); acima de 25, `+1` a cada 10 MAG. Ex.: MAG 12 = 12, MAG 25 = 15, MAG 35 = 16. Limitado ao MP máximo.
2. **Intervalo:** continua 8 s (D-413). Vale para **todos** (aliados e oponentes, cada um pela própria MAG).
3. **Barra azul à esquerda do cartão** (a faixa de acento): **azul do MP** (`#38bdf8`) e **sempre animada como um carregamento**: enche de baixo para cima conforme o cronômetro de 8 s; cheia quando o MP está no máximo. Com ARMOR a faixa também ganha o brilho cromado.
4. **Eco textual "+N MP"** (N = o valor realmente recebido, limitado ao MP máximo): azul do MP saturado, plano, sem borda; carimba sobre o personagem, sobe um pouco e some em ~0,6 s.

## Ambiguidades

- O limiar foi lido como **valor de MAG 25** (não nível), a pedido do criador.
- "1 ponto extra para cada 5 MAG" foi lido como `MAG / 5` desde MAG 0 (não só acima de um piso).

## Numeração

Este registro nasceu como D-1029 (e os da câmera e do eco como D-1027 e D-1028). Outras sessões tomaram os mesmos números em paralelo (minimapa, visual 3D, Dread do Fire Bullet), então os três foram renumerados para **D-1060 (câmera), D-1061 (eco ARMOR!) e D-1062 (este)**, com os comentários de código e o índice ajustados.

## Estado

Implementado (2026-11-09), **aguardando aprovação visual**. `Combatant.mp_regen_amount()` (teste `tests/battle/test_d1062_mp_regen.gd`, passa), faixa azul do cartão como barra de carga (`battle_hud.gd`), eco `MpEcho` (`scripts/combat/fx/mp_echo.gd`), sinal `Battle.mp_regenerated`. Verificado em vídeo (Orc no cartão, 8,9 a 10,3 s): a faixa enche de baixo para cima, o MP sobe de 10 para 20 e aparece "+10 MP". **Não verificado:** MAG alto em jogo (só no teste), o eco em inimigo distante, aliados controlados pela IA.
