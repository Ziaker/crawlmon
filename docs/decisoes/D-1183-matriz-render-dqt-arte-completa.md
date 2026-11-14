# D-1183 — Matriz de afinidades: o render dos personagens DQT é a arte completa do ícone

- **Data:** 2026-11-11
- **Área:** Protótipo / ficha de personagem (`prototypes/affinity_matrix.html`).
- **Relacionadas:** D-1167 (Ícone 256 px e Render 1024 px), D-1179 (captura de ícone; "render" = arte 2D do monstro), D-1182 (QoL).
- **Estado:** implementado no protótipo; aguardando aprovação visual. Nenhum arquivo do jogo alterado.

## Declaração literal do criador

> "cade os ícones completos dos personagens de DQT como renders?"

(com um print da ficha do Orc, em que a arte grande era o retrato recortado de perto, só o rosto.)

## Decisão

1. Na ficha, a **arte grande (Render)** dos personagens DQT passa a ser a **arte completa** do ícone do monstro trazida do Tact (`sugimori/dqt/<monstro>/icone_MonsterIcon_*.png`), não o recorte fechado.
2. Enquanto o personagem não tiver um render enviado, a ficha usa a arte completa padrão abaixo (também mostrada no espaço "Render" da seção ÍCONE). Um render enviado ou escolhido sempre tem prioridade.
3. O espaço "Render" ganha **Da galeria**: escolhe qualquer arte de `sugimori/dqt/` como render do personagem (imagem inteira, sem recorte). Vale para qualquer personagem novo e para todos os monstros. Mesma limitação de `file://` da D-1179 (só por servidor local).
4. O ícone pequeno (avatar) e o JSON não mudam.

## Arte padrão escolhida (forma igual à do ícone/retrato atual de cada um)

| Personagem | Arquivo em `sugimori/dqt/` |
|---|---|
| Slime | `0000_slime/icone_MonsterIcon_0000_b28d1f3b241238c2.png` (azul) |
| Orc | `0020_orc/icone_MonsterIcon_0020_62c57670bdcc9c37.png` (marrom/verde) |
| Cyclops | `0065_gigantes/icone_MonsterIcon_0065_59acef4fa99f3f8a.png` (azul) |
| Dracky | `0003_doraki-/icone_MonsterIcon_0003_2e223e7e3e7a6cdd.png` (roxo escuro) |
| Heal Slime | `0004_hoimislime/icone_MonsterIcon_0004_781444a17757c3f1.png` (azul) |
| Sabrecub | `0002_babypanther/icone_MonsterIcon_0002_e9dd7517ae12d5d7.png` (laranja) |
| Platypunk | `0001_momonja/icone_MonsterIcon_0001_c005276e85b7a2f2.png` (branco e azul) |
| Funghoul | `0038_obakekinoko/icone_MonsterIcon_0038_d25f8ed185df1883.png` (chapéu vermelho) |

## Adendo — arte oficial maior (2026-11-11)

Pesquisa na internet (a pedido do criador): as artes promocionais oficiais do [RPGFan](https://www.rpgfan.com/gallery/dragon-quest-tact-artwork/) foram baixadas para `sugimori/dqt_web/rpgfan/` (20 monstros, 600×700 transparente nas maiores). Criador: "Sim, ligar os 3". Por isso **Slime, Dracky e Sabrecub** usam a arte do RPGFan (600×700) como render padrão, acima do ícone do Tact da tabela. Orc, Cyclops, Heal Slime, Platypunk e Funghoul não têm arte oficial maior encontrada e seguem com o ícone do Tact. Wiki do Dragon Quest (155×153) e Game8 (140×175) não melhoram o que já existe.

## Adendo — Pokémon (2026-11-11)

Criador: "pqnão tá usando as artes completas dos pokes também?". A **arte grande** da ficha dos Pokémon já era a arte Sugimori completa (`sugimori/por_nome/<id>.png`); o que faltava era o espaço **Render** da seção ÍCONE, que mostrava "—". Agora ele mostra a mesma arte Sugimori como render padrão ("padrão: arte Sugimori"). Render enviado ou escolhido da galeria continua tendo prioridade; o JSON não muda.

## Escolhas do assistente (não ditas pelo criador)

- Os nomes dos monstros do Tact (Platypunk = `momonja`, Funghoul = `obakekinoko`, Cyclops = `gigantes`, Sabrecub = `babypanther`) foram associados comparando a arte com os ícones atuais; a forma/cor escolhida segue a do ícone atual.
- A arte tem ~128 px; na ficha ela é ampliada. Uma arte de resolução maior exigiria extrair de novo do Tact.
- O render padrão não vai para o JSON (é só exibição); só um render enviado ou escolhido da galeria é gravado em `renderData`.
- O arquivo único embute as 8 artes padrão; a galeria continua dependendo de servidor local.

## O que não muda

- Dados, regras, JSON `crawlmon.affinities.v1` e atalhos. Nada de commit/push (D-022).
