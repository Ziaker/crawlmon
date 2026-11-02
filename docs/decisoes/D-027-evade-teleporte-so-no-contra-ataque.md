# D-027 — Teleporte só no desvio perfeito durante o próprio ataque; Evade em trajeto a 2 ATB

- **Data:** 2026-11-02
- **Área:** Combate
- **Origem:** Conversa

## O que o criador disse (literal)

> 1 - o boneco não devia se teleportar pra frente do oponente ao desviar, isso só deve acontecer se ele tiver realizando um ataque e conseguir desviar perfeitamente do ataque do oponente caso ele também esteja atacando, com o apertar do botão, o ataque deve continuar normalmente após o teleporte e ainda permitir o contra-ataque imediato
>
> 4 - Por que não está podendo desviar durante o trajeto do próprio ataque com o botão ao custo de 2atb (diferente do normal parado sem estiver realizando uma ação que custa 3)?

## Decisão

1. Desviar **não** teleporta o personagem para a frente do oponente.
2. **Exceção:** o personagem está **realizando um ataque**, o oponente **também está atacando** (ele), e o personagem aperta o botão e **desvia perfeitamente** → teleporta para a frente do oponente; **o próprio ataque continua normalmente** depois do teleporte **e ainda permite um contra-ataque imediato**.
3. Confirma D-006: Evade **durante o trajeto do próprio ataque = 2 ATB**; Evade **parado** (sem estar em ação) = **3 ATB**.

## Respostas do criador (perguntas)

- Desvio perfeito = **janela curta no fim** (últimos 0,22 s do trajeto do atacante).
- Desvio em trajeto não perfeito: **desvia e o próprio ataque segue** (sem teleporte).
- Contra-ataque imediato = **golpe extra sem preparo**, além do ataque que continua.
- Evade parado: **desvia no lugar e ganha +1 Burst**, sem teleporte.

## Ambiguidades em aberto

- Até quando o contra-ataque sem preparo fica disponível (hoje: até ser usado).
- Câmera lenta: aplicada só no desvio perfeito do líder, até o contra-ataque ou 2 s (regra antiga do criador); confirmar.

## Estado no código

Implementado em `battle_evade.gd` (custo 3/2, perfeito, teleporte, contra-ataque sem preparo). O desvio parado não interrompe mais o atacante nem cria engajamento.
