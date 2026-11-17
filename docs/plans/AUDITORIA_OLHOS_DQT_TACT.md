# Auditoria: olhos fechados / pálpebras dos monstros DQT (fonte: C:\Games\Tact)

> Somente leitura em `C:\Games\Tact`. Dados lidos dos GLBs em `C:\Games\Tact\monstros\00\<id>\modelo_3d\*.glb` (nós, malhas, animações) e confrontados com os GLBs do jogo em `assets/modelos/dqt_*/`. Regra do jogo para troca de olho: `EXTRATOR_CHANGELOG.md` item 12 (nó `<X>_scale` > 0,5 mostra o objeto `<X>`; no Slime `Eye_Model_a` é o adesivo de **olhos fechados**; "nenhum dos monstros conferidos tem ciclo de piscar no Idle"). Recomendações abaixo são para o criador aprovar (AGENTS.md §2); nada foi implementado.

## Tabela (nome do jogo = pasta no Tact)

| Modelo (jogo) | Pasta Tact | Malha de olho | Controle de visibilidade | Ossos de olho/pálpebra | Clipes que mexem neles |
|---|---|---|---|---|---|
| dqt_slime | 0000_slime | `Eye_Model_a` (adesivo de olho fechado) | `Eye_Model_a_scale` | nenhum | 12/12 animam `Eye_Model_a_scale` |
| dqt_dracky | 0003_doraki- | `Eye_Model_a` | `Eye_Model_a_scale` | nenhum | 12/12 |
| dqt_healslime | 0004_hoimislime | `Eye_Model_a` | `Eye_Model_a_scale` | nenhum | 12/12 |
| dqt_orc | 0020_orc | `Eye_Model_a` | sem `_scale` | `j_eye_l/r`, `j_mabuta_l/r` | clipes 01-12 mexem em olho/pálpebra; o `_00` (provável Idle) é constante (2 chaves iguais) |
| dqt_cyclops | 0065_gigantes | `Eye_Model_a` | sem `_scale` | `n_eye`, `j_mabuta` | vários clipes; `_00` só ruído de escala ~1 % (sem piscar) |
| dqt_sabrecub | 0002_babypanther | `Eye_Model_a` | sem `_scale` | `eyeL/R`, `mabutaL/R` | **`cm_00_0002_00` (provável Idle, 1,5 s) tem piscada real**: `mabutaL.translation` Y vai de -0,038 a -0,150 e volta entre 0,30 s e 0,67 s |
| dqt_fungi | 0038_obakekinoko | `Eye_Model_a` | sem `_scale` | nenhum | nenhum clipe mexe em olho |
| dqt_platypunk | 0001_momonja (nós `OpenEye`/`CloseEye`, `Eye_Model_a/b`) | `Eye_Model_a`, `Eye_Model_b` | nós `OpenEye`/`CloseEye` | nenhum osso | 12/12 clipes animam `OpenEye` e `CloseEye` (troca aberto/fechado) |

Referência extra (amostra): `0158_oomedama` tem `j_eye`, `j_uemabuta`, `j_sitamabuta` (pálpebra de cima e de baixo, rotação animada em quase todos os clipes). `0035_hitokuisou`: nenhum nó de olho.

## O que isso diz
1. **Slime, Dracky, Healslime:** o olho fechado é uma malha (`Eye_Model_a`) ligada por escala. Dá para fechar por BLIND/hit só com a regra de visibilidade já usada no D-340 (`DqtEyes`): forçar `Eye_Model_a_scale` > 0,5. Dado do jogo, não invenção.
2. **Platypunk:** tem par aberto/fechado (`OpenEye`/`CloseEye`); mesma abordagem, trocando qual dos dois aparece.
3. **Sabrecub, Orc, Cyclops:** têm ossos de pálpebra reais. O Sabrecub tem uma piscada autoral no clipe `_00`; Orc e Cyclops têm pálpebra animada em ataques/dano, mas sem piscar no `_00`. Para BLIND daria para segurar o osso da pálpebra na pose do clipe em que ele fecha (não verificada qual pose fecha de fato).
4. **Fungi:** sem dado de olho fechado no GLB; só o desenho pintado. Nada a reaproveitar (precisaria de regra do jogo ou nada).
5. Contradiz parcialmente o changelog do extrator ("nenhum tem piscar no Idle"): o `babypanther` tem, se `_00` for o Idle.

## Não verificado
- Qual número de clipe é Idle/Damage/Sleep (assumi `_00` = Idle pelo padrão; o `monstro.json` do Tact tem UTF-8 inválido para o `json` padrão e não foi lido).
- O mecanismo do jogo para `OpenEye`/`CloseEye` (nó vs malha) e a pose que de fato fecha as pálpebras de Orc/Cyclops/Sabrecub: só olhei dados numéricos, sem renderizar.
- Mapeamento nome→pasta feito por nome e pelos nós dos GLBs do jogo (Platypunk = `0001_momonja` pelos nós; `0005_ookizuti` NÃO é, apesar do nome); Cyclops = `0065_gigantes` por correspondência de nós, sem prova externa.
- Os GLBs lidos são os do Tact (`modelo_3d`); os do projeto têm os mesmos nós de olho (conferi por nome).
- Correção do extrator: nenhuma necessária para os dados acima (já exportados); apenas o changelog sobre "sem piscar no Idle" merece revisão para o Sabrecub.

## Recomendação (para o criador decidir)
Reaproveitar o `DqtEyes` (D-340) como o ponto único: (a) Slime/Dracky/Healslime/Platypunk fecham por troca de malha/escala com a regra do jogo; (b) Sabrecub/Orc/Cyclops por pose do osso de pálpebra, depois de uma checagem visual; (c) Fungi nada. Nada disso foi implementado nem aprovado.

Scripts de leitura usados (fora do repo): scratchpad da sessão (`audit_eyes.py`, `audit_lids.py`, `audit_idle.py`).
