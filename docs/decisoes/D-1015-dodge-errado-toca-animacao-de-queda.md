# D-1015 — Dodge errado toca a animação de queda

- **Data:** 2026-11-08.
- **Origem:** Conversa.

## Frase literal do criador

> o dodge errado devia dar play na animação de queda dos personagens

Respostas: o clipe é o **"down"** ("Sim, o down", mesmo sendo reservado ao K.O. no comentário de `fx_motion.gd`); depois da queda o personagem **"Volta ao idle sozinho"**.

## Decisão

1. Quando o dodge é apertado fora da janela válida (D-1014), o personagem que errou toca o clipe `down` e, ao fim do clipe (entre 0,4 e 1,6 s), volta ao `battle_idle` sozinho. O golpe que ele errou o acerta normalmente.
2. Vale para qualquer personagem, aliado ou inimigo, de qualquer lado.
3. Exceção à reserva do `down` ao K.O. (comentário em `fx_motion.gd`, D-056): só neste caso e só durante o erro de timing.
4. Se o modelo não tiver o clipe `down`, nada toca. Se o corpo estiver sendo conduzido pela própria corrida de ataque, nada toca.

## Ambiguidades em aberto

- Pokémon sem clipe `down` ficam sem animação; não foi definido um clipe substituto.

## Estado

Implementado para revisão (`fx_dodge.gd`, `battle_fx.gd`, `battle_scene.gd`, `battle.gd`, `battle_evade.gd`).

## Extensão posterior — D-1166 (2026-11-11)

O criador relatou que, nos modelos Pokémon, o clipe `down` quase não move o corpo e o dodge errado parecia não ter indicação visual. A D-1166 mantém o `down` e acrescenta **WHIFF**, **poeira** e uma **queda assistida por código** quando o clipe não derruba o corpo. A D-1167 acrescenta o fallback para o clipe **`damage`** quando não há queda utilizável. A exceção do item 4 (“se não tiver `down`, nada toca”) fica ampliada: agora sempre há WHIFF + poeira + queda assistida. Ver `D-1166-dodge-errado-queda-whiff-poeira.md` e `D-1167-fallback-damage-quando-down-nao-cai.md`.
