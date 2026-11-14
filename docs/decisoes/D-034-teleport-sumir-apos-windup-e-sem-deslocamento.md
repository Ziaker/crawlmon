<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-034 — Teleport: sumir após o wind-up, sem deslocamento e reaparecer na origem

- **Data:** 2026-11-02
- **Área:** Combate
- **Origem:** Conversa

## O que o criador disse (literal)

> faz assim, o teleporte só faz o personagem sumir após o wind-up, surgindo no ataque, depois sumindo e surgindo devolta na posição original, sem deslocamento nenhum

## Decisão

1. **Wind-up (0.5s)**: O usuário do *Teleport* permanece visível em sua posição base/origem durante todo o wind-up, executando sua carga/telegraph normal. Ele **não** desaparece durante o wind-up (alterando o trecho anterior de D-032 que dizia "some na wind-up").
2. **Após o wind-up (TRAVEL)**: Imediatamente após o término do wind-up, o personagem desaparece instantaneamente na sua posição de origem com efeito visual de teleporte/brilho.
3. **No ataque (STRIKE)**: O personagem ressurge instantaneamente atrás do oponente com efeito de teleporte/brilho e desfere o golpe.
4. **Após o ataque (RETURN)**: O personagem desaparece instantaneamente de trás do oponente no início do retorno e ressurge instantaneamente em sua posição de origem com efeito de teleporte/brilho.
5. **Sem deslocamento nenhum**: Não existe nenhuma interpolação contínua de movimento, corrida ou deslocamento físico visível pelo chão da arena entre a base e o oponente. Todas as trocas de posição são teleporte puro (desaparecer em um ponto e ressurgir no outro).

## Ambiguidades em aberto

Nenhuma.

## Estado no código

Em implementação nesta sessão.
