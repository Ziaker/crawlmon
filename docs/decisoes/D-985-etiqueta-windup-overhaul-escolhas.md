# D-985 — Etiqueta de wind-up: overhaul (escolhas do criador; implementação adiada)

- **Data:** 2026-11-08.

## Frase literal do criador

> me diz como faria um overhaul no cartão de wind-up de move (inclusive o reposicione mais para cima, deixando espaço para ainda ver as badges de buff e debuff do inimigo também.

> Fundo: cor do elemento do move
> quanto ao destaque da janela de evade,vamos trocar por um efeito visual
> MAS ANTES de fazer isso [...] vamos fazer isso primeiro (a auditoria do Electric Beam)

## Decisão (aprovada, ainda não implementada)

1. Etiqueta de wind-up acima da etiqueta do inimigo **e** da fileira de badges, sem sobrepor.
2. Fundo na **cor do elemento do move**, no padrão das fichas (D-417): marca d'água do elemento, nome grande, ícones de tipo e alcance.
3. A janela de Evade **não** usa destaque de texto/piscar na etiqueta: vira **um efeito visual** (a definir).
4. Demais pontos da proposta (alvo com mini-retrato, barra de contagem, entrada "carimbo" e saída rápida, tamanho ~150×38) seguem a proposta, a confirmar na implementação.

## Ambiguidade

- Qual efeito visual marca a janela de Evade: a propor quando o trabalho for retomado.

## Respostas seguintes

> é pra ser uma referência visual em vfx no prelude do ataque, como em metroid samus returns remake e metroid dread, cace referencias
> (proposta completa) "Sim, todos"

- A janela de Evade vira um **VFX no atacante, no prelúdio do ataque**, como o aviso de Melee Counter de Metroid: Samus Returns (anéis brancos piscando + clique) e Dread (o inimigo pisca uma luz). Opções propostas; aguardando escolha.

## Estado

Etiqueta implementada (`AttackTag` em `battle_hud.gd`): fundo na cor do elemento, marca d'água, nome grande, ícones de tipo e alcance, alvo com mini-retrato, barra grossa de contagem com segundos, entrada "carimbo" 115%→100% em 0,12 s, saída para cima em 0,1 s, acima da etiqueta e dos badges do inimigo. O destaque dourado da janela de Evade foi tirado da etiqueta. VFX da janela de Evade: pendente.
