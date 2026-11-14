# D-1187 — Moves do Abra: interrupção dissipa a carga em 0,45 s e o impacto começa no contato

- **Data:** 2026-11-12.
- **Área:** Combate / VFX / Moves do Abra (Confusion, Psybeam, Shock Wave, Teleport).
- **Origem:** o criador relatou o Confusion como "bugado".
- **Status:** implementado e verificado em quadros (acerto normal e espelhado; interrupção no wind-up e na espera); suíte de combate 28/28; **aprovado visualmente pelo criador em 2026-11-12** ("Está bom"). Cenários novos: `confusion_interrompe_windup`, `confusion_interrompe_espera`.

## O que o criador disse

> "Confusion é um move bugado, quando o personagem é interrompido, o move não é destruído ou nem se esvai sumindo lentamente (acho uma ideia melhor pra moves em conjuração com seus efeitos sendo interrompidos), além de que o Impacto acontece muito mais tarde do que devia, ao invés de ser no exato msm momento que chega no alvo"

Respostas às perguntas: duração da dissipação **"0,45 s"**; escopo **"Só os 4 Moves do Abra"**; impacto **"Só tirar o atraso"** (manter a forma atual).

## Diagnóstico (dados, D-1154)

1. **Carga órfã:** depois do wind-up o `AbraMoveVfx` fica "segurado" (`held`) esperando o disparo (fase STRIKE, 0,78 s). `FxMotion.on_attack_interrupted` → `FxProjectiles.finish` só limpa o que está em `inc.data["proj"]`, que só existe a partir do TRAVEL. Interrompido na espera, o nó fica vivo até a trava de 6 s. Cenário `confusion_interrompe_espera`: `interrupted` com `interruption_feedback: true` em t=4,133 e cubos + Tesseract ainda na tela em t≥3,8 s da gravação (≈1,9 s depois).
2. **Wind-up cancelado** (`cancelled`, `interruption_feedback: true`): `clear_telegraph` dá `queue_free()` seco, sem dissipar.
3. **Impacto tardio:** o hit é no fim do TRAVEL (`hit` em t=5,15, progresso 1,0), correto. Mas os cubos somem em `ext_p` 0,77–0,96 e o Tesseract em ≈0,9 (~0,2 s antes do contato), e o impacto (`_confusion_impact`) cresce com `sin(ep·π)` partindo de zero, pico ~0,55 s depois.

## Decisão

1. **Interrupção real** (`interruption_feedback: true`) de um Move do Abra em wind-up ou na espera antes do disparo: a carga **dissipa em 0,45 s** (some suavemente), não é cortada nem fica órfã.
2. **Escopo:** os 4 Moves do Abra, que compartilham a camada `AbraMoveVfx`. Comportamento por `move_id`, nunca por personagem (D-235).
3. **Impacto do Confusion:** o projétil chega ao alvo **exatamente** no fim do TRAVEL e o impacto **começa no contato**; a forma do impacto não muda.
4. Nada de regra de combate, tempo ou ordem de eventos muda (D-019): só desenho.

5. **Segunda passada (criador: "ainda parece que acontece um pouco tarde"; escolheu "Projétil chegando antes"):** o projétil freava no fim por causa da curva ease-in-out; agora cubos, rastros e Tesseract aceleram (`t²`) e batem em velocidade máxima no hit. Medido a 1/30 s: projétil visível até 2,933 s, hit e impacto em 2,967 s.

## Ambiguidades em aberto

- Interrupção em voo: o tiro já saiu e não é interrompido pelas regras (medido); fica como está.
- Outras famílias (Fire, Element, Electric) têm o mesmo padrão de carga segurada; **não** alteradas.
