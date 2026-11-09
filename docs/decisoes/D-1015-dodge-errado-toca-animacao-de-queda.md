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
