# D-163 — A animação de wind-up fica em loop até o fim do preparo

- **Data:** 2026-11-03
- **Área:** Combate / Animação
- **Origem:** Conversa

## O que o criador disse (literal)

> certas animações de wind-up não estão loopando corretamente e o frame do personagem acaba por travar.

## Decisão

O clipe `charge` repete até o fim do preparo. Se o wind-up for cancelado, o personagem volta ao idle.

## Causa no código

`charge` não estava na lista de clipes em loop de `_make_model`. Os clipes duram 0,63 s (Abra), 0,83 s (Pancham) e 1,00 s (Gible), e os preparos chegam a 2 s: o clipe acabava e o último quadro ficava parado (reproduzido com Dragon Rage). Um wind-up cancelado também não devolvia o personagem ao idle.

## Ambiguidades em aberto

Nenhuma. A emenda do fim com o início do clipe não foi vista na tela.

## Estado no código

Implementado (`battle_scene.gd`, `fx_telegraph.gd`, `battle_fx.gd`).
