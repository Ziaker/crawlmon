<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

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

## Complemento posterior (2026-11-03)

**D-164:** o contra-ataque sem preparo vale para todo desvio perfeito, inclusive parado. O teleporte continua só no próprio trajeto.
