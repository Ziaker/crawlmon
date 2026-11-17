> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** Teste em <10 s: `--scenario=dano_olhos --stdout-trace --quit` (evento `eyes`).

# D-1272 — Olhos fecham por meio segundo ao levar dano ou impacto

## Frase literal do criador
> "faça eles fecharem os olhosos por meio segundo quando levam dano também quando levam um impacto"

## Decisão
Todo personagem com olhos piscáveis (`EyeBlink`, D-1268/D-1271) fecha as pálpebras por **0,5 s** (`BattleFx.EYES_SHUT_ON_HIT`) a cada reação de hit: `BattleFx._hit_react` (dano de golpe, impacto com knockback/hit-stop e interrupção sem dano como War Cry). Vale para qualquer personagem, aliado ou inimigo, em qualquer lado (D-235). Se o BLIND (D-1271) estiver ativo, ele segura os olhos fechados além dos 0,5 s. Não muda dano, reação, knockback nem hit-stop.
- Interpretação minha (pendente de confirmação): "dano" e "impacto" = o mesmo gatilho, a reação de hit; golpe totalmente absorvido por escudo (sem reação de hit) não fecha os olhos.
- Os 0,5 s são de pálpebra fechada; fechar leva 0,12 s e reabrir 0,22 s (valores técnicos meus).

## Verificação
`--scenario=dano_olhos --stdout-trace`: Pancham (aliado) `eyes closed=true hit=true` no hit e `closed=false` 0,52 s depois (t=6,733 → 7,251); com `--mirror` o mesmo no Gible (t=5,803 → 6,337). O visual das pálpebras é o mesmo da cegueira (capturas D-1271).
Não verificado: captura em quadro de batalha real; aprovação do criador; suíte de combate completa: falhas vistas na última rodada são `hub_3d_lab.gd` com erro de parse de OUTRA sessão (corrupção na linha 2), Employ D-1239 espelhado intermitente (passa e falha em execuções seguidas sem mudança) e Javelin D-235 (falha mesmo sem nada disto).

## Aprovação do criador (2026-11-17)

Frase literal: "aprovo tudo" (resposta ao relatório final com os valores técnicos pendentes: ritmo do piscar 2,4-5,2 s com 0,06/0,05/0,09 s, 0,5 s ao levar dano/impacto, rampas 0,12 s e 0,22 s, posição e tamanho dos brilhos, e a interpretação de "dano" e "impacto" = reação de hit). Os valores deixam de estar pendentes. O visual em si continua sujeito ao julgamento do criador; a recomendação para os monstros DQT (auditoria Tact) NÃO foi decidida por esta frase.
