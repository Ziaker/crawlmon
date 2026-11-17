> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** Teste em <10 s: `--scenario=olhos_debug_dqt --stdout-trace --quit` (eventos `eyes`, `eyes_blink`).

# D-1295 — Monstros DQT fecham os olhos por BLIND e por hit (primeira tentativa)

## Frase literal do criador
> "tenta com eles"

(resposta à oferta de aplicar a recomendação da auditoria `docs/plans/AUDITORIA_OLHOS_DQT_TACT.md` aos monstros DQT, depois do "aprovo tudo" de D-1268/D-1271/D-1272.)

## Decisão (escopo desta tentativa)
- O `DqtEyes` (D-340) ganha a mesma interface do `EyeBlink` (`hold_closed`, `squeeze(s)`, `blink_now()`, `lid_k`, `blinks`) e `BattleFx` passa a achá-lo, de modo que BLIND (D-1271) e hit de 0,5 s (D-1272) valem também para os DQT que têm malha de olho fechado ligada por `<X>_scale`: **Slime, Dracky, Healslime** (dado do jogo, auditoria Tact). A pálpebra é a malha `Eye_Model_a` (adesivo de olho fechado), sem fração: aberto/fechado.
- Segunda tentativa ("sim" do criador à oferta): Orc, Cyclops e Sabrecub, que não têm malha de olho fechado mas têm ossos `*mabuta*`, seguram durante BLIND/hit a pose que o próprio clipe Sleep (`<prefixo>04`) dá a esses ossos em t=0 (translação/rotação/escala, só as trilhas que existem). Sem piscar aleatório próprio nesses (o Sabrecub já pisca no clipe). Visual: Sabrecub e Cyclops mudam nitidamente na captura; no Orc não deu para julgar.
- Fora desta tentativa: Platypunk (nós `OpenEye`/`CloseEye`) e Fungi (sem dado).
- Não muda regra de jogo, dano, tempo ou o piscar aleatório do D-340.
- Interpretação minha (pendente): "eles" = os monstros DQT que a auditoria mostrou com olho fechado por malha.
