# D-1182 — Matriz de afinidades: clicar no personagem abre a ficha + rodada de QoL

- **Data:** 2026-11-11
- **Área:** Protótipo / ferramenta de cadastro de personagem (`prototypes/affinity_matrix.html`).
- **Relacionadas:** D-1163 (cadastro oficial), D-1167 (ficha), D-1177 (QoL), D-1178 (visual do jogo), D-1179 (captura de ícone), D-1161 (só N/W/R).
- **Estado:** implementado no protótipo; aguardando revisão. Nenhum arquivo do jogo alterado.

## Declaração literal do criador

> "permita que clicar em um personagem vá pra ficha dele, isso e mais umas 10 melhorias que poderia fazer"

(com um print da visão "Por elemento" no visual do jogo.)

## Regra pedida

Clicar no **avatar ou no nome** de um personagem, em qualquer visão, abre a **ficha** dele. A ficha ganha **← Voltar** para a visão e a posição de rolagem de onde veio.

## As 10 melhorias (escolhidas pelo assistente por delegação)

1. **Busca com operadores:** além de nome/ID, `e:fire` (elemento do personagem), `w:fire` (Weak a Fire), `r:dark` (Resist a Dark), `m:tackle` (move) e `n:modest` (nature); termos se combinam.
2. **Revisar e ir ao próximo:** na ficha, um botão marca como revisado e pula ao próximo NEW (`Shift+Enter`).
3. **Pendências novas:** "todas Neutral" (só para quem já foi revisado) e "afinidades idênticas às de X".
4. **Destaque do mesmo personagem** em todos os blocos ao passar o mouse na visão Por elemento.
5. **Modo compacto** (`C`): linhas e células menores, para rosters grandes.
6. **A ferramenta lembra onde você parou:** ficha aberta, ordenação e pincel da Matriz, filtro de moves e modo compacto.
7. **Copiar resumo** do personagem em texto (ficha e paleta).
8. **Baixar CSV** da matriz (separador `;`, UTF-8 com BOM, abre no Excel).
9. **Prévia da importação:** antes de aplicar um JSON, mostra quantos são novos, alterados e iguais e pede confirmação; a importação vale um único desfazer.
10. **Comparar com outro personagem** na ficha: lista os elementos em que as afinidades diferem e permite igualar.

## Escolhas do assistente (não ditas pelo criador)

- Nome e avatar viram botões; o selo NEW continua separado (marca como revisado).
- "Revisar e ir ao próximo" segue a ordem do roster e dá a volta; sem mais NEW, só marca como revisado.
- "Afinidades idênticas" ignora personagens com as 12 Neutral e é só aviso.
- O modo compacto e o estado lembrado ficam no navegador, não no JSON.

## O que não muda

- Dados, regras, JSON `crawlmon.affinities.v1`. Nada de commit/push (D-022).
