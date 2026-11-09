# D-1013 — Trajeto visual no chão até o alvo, que se preenche durante o wind-up

- **Data:** 2026-11-08.
- **Origem:** Conversa.

## Frases literais do criador

> anteriormente nas versões mais antigas do jogo havia um trajeto visual no chão até o personagem alvo que se preenchia até o wind-up estar completo, ele foi removido por algum motivo, tem como trazer ele de volta?

Respostas às perguntas:

> 1 - faixa e bordas, os blocos quadrados eram dele? se sim então deixe os blocos fora
> 2 - todos
> 3 - o bloco ficava NO CHÃO? abaixo do pés dos personagens? se sim, sim também
> 4 - não? não é vfx de move...

## Fatos achados

- A faixa foi removida no commit `1b2f89a5` (2026-11-03), com o comentário "no rectangular trajeto lane per D-026". A D-026 está **cancelada** e fala da mecânica de trajeto, não do desenho no chão.
- Na versão antiga havia: faixa plana (alpha 0,24), duas bordas e um **bloco quadrado de carga** (0,6 de comprimento) que corria da origem ao alvo. Tudo era plano em y=0,03–0,04, no chão, abaixo dos pés.
- Não é possível provar se os "blocos quadrados" da queixa da D-026 eram esse bloco.

## Decisão

1. Volta a faixa no chão do atacante até o alvo, **com as bordas brilhantes**.
2. **Sem o bloco quadrado**: o preenchimento é a própria faixa se enchendo (mesma largura), da origem ao alvo, linear, terminando junto com o wind-up.
3. Vale para **todos** os ataques (também os com telegraph do Move), de qualquer atacante, lado ou alvo; não aparece quando atacante e alvo são o mesmo ponto (golpe em si mesmo).
4. Não é VFX de Move: o protocolo da D-308 e o Motion Composer não se aplicam. A regra de uma mudança por entrega, com vídeo nas duas vistas, vale.
5. O anel do alvo (D-240) continua como está.

## Estado

Implementado para revisão (`fx_telegraph.gd`).
