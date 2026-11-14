<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-990 — Fase "Swing" = "Hit-windup"; o rastro do golpe segue a mão/arma em 3D

- **Data:** 2026-11-08.

## Frase literal do criador

> este efeito pós preludio sempre me encomodou por estar embaixo do chão ao invés de seguir o movimento da mão/arma do personagem, ele sempre ocorre instantes antes do ataque causar dano, tem que ter um nome para esta fase definido no gdd

Respostas: "escolha o melhor para você, mas vamos com swing e hit-windup como palavras chaves que significam o mesmo." e "seguir a mão/arma PORÉM, no angulo e orientação certa. No momento ele é 2D ao invés de 3D por conta do angulo e orientação que possui".

## Decisão

1. **Nome:** **Swing** e **Hit-windup** (D-953; "prelúdio do ataque") são a mesma fase: o golpe se armando e descendo até o contato, dentro da fase de golpe (D-030). Os dois termos valem como palavras-chave.
2. **Rastro do Swing:** o arco plano que nascia num ponto fixo (1,35 m à frente, 1,0 m de altura) dá lugar a uma **fita 3D que segue o osso real da mão/arma**, varrida entre o antebraço e um pouco além da mão: ângulo e orientação são os do próprio membro. Vive nos últimos 0,3 s antes do contato e some logo depois.
3. **Independente de personagem (D-235):** observa todos os ossos com nome de mão/arma (partes genéricas: hand, weapon, _te_, hte, wrist) e desenha o que se move e chega mais perto do alvo (o membro que golpeia); sem nenhum deles (golpe só com o corpo, como o Slime), **linhas de velocidade**: traços finos atrás do corpo, no eixo do golpe, que somem no contato (criador: "o slime não precisa necessariamente, ele não tem braços e só usa o corpo, então ache uma alternativa" → "Linhas de velocidade"). Modelo sem esqueleto mantém o arco antigo.

4. O arco duplo próprio do Tackle ("smear" plano em ponto fixo) também sai: o rastro 3D o substitui. As faíscas do Tackle continuam.

## Estado

Implementado para revisão em vídeo.
