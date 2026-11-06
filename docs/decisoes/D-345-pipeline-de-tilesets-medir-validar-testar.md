# D-345 — Pipeline de tilesets: medir, validar e testar antes de usar

- **Data:** 2026-11-06
- **Área:** Ferramentas / assets / exploração
- **Origem:** Conversa depois da aprovação do Temporal Tower e da câmera 2,3×

## O que o criador disse (literal)

> eu acho que a forma como vc chega os tilesets devia ser melhorada, me diz 10 coisas que propõe

E, depois das 10 propostas:

> prossiga com todas, depois auditorie e veja algo que esqueceu e corrija esse esquecimento

## Decisão

As 10 propostas passam a ser o padrão do pipeline de tilesets:

1. Medir a folha antes de qualquer constante (linhas ciano, pitch, origem, célula).
2. Manifesto por folha com fonte, hash, grade, categorias, papéis e licença.
3. Recortar a célula inteira de arte; sem recorte 19×19, sem “limpeza” por vizinho.
4. Ler a legenda e o preview da folha; categorias vêm das labels, não de cor/posição suposta.
5. Folha de contato rotulada por importação (célula, C/R, categoria, índice no atlas).
6. Detectar o autotile (núcleo 3×3 + extras) e gerar a tabela de papéis.
7. Separar folha de jogo: perfil papel → índice; `map_visuals.gd` não usa índice cru.
8. Validar o atlas automaticamente (dimensões, contagem, vazio, ciano/teal, costura, hash).
9. Laboratório no Godot com todos os casos de máscara, no 48 px real e câmera 2,3×.
10. Versionar o pipeline e aprovar sobre o tileset isolado, não sobre a sala procedural.

## Ambiguidades e limites

- A implementação vale para os 16 sheets do Sky. O sheet do Time/Darkness continua como referência.
- Nenhuma regra de jogo, colisão, tempo ou câmera muda. O visual aprovado (Walls + Ground, 1 linha) continua o mesmo.
- A auditoria final deve apontar um esquecimento real e corrigi-lo; se não houver, dizer o que foi verificado.

## Auditoria e esquecimento corrigido

A auditoria encontrou um furo real na separação folha ↔ jogo: o perfil gerado
tinha o campo `atlas`, mas o `map_visuals.gd` continuava carregando o
`PMD_TILESET` fixo. Trocar o perfil para `murky_forest` mantinha a dungeon do
Temporal Tower. Correção: o perfil agora define a textura (`_atlas_path`), com
fallback para o caminho antigo. Testado com `murky_forest` (a captura ficou
roxa/teal) e revertido para `temporal_tower`.

Também corrigidos na auditoria:

- `--only` reescrevia o `index.json` global com uma folha só; agora não reescreve.
- As imagens de `docs/referencias/tilesets/` eram importadas pelo Godot; recebeu
  `.gdignore` e os `.import` gerados foram removidos.
- O código morto do atlas procedural antigo em `map_visuals.gd` foi removido
  (ele quebrava o parse depois da troca de constantes).
- Duplicatas de tiles passaram de erro para aviso (arte uniforme pode repetir
  borda/centro); o `--check` valida contato, atlas rotulado, labels e preview.
- `temporal_spire` tem uma grade regular de 27 colunas e um bloco de nota fora
  da grade; o probe agora para no primeiro intervalo ≠ 25.

## Estado

Implementado e validado nos 16 sheets. As 10 melhorias de percepção propostas depois do erro dos lados foram implementadas em D-354: orientação medida, preview como gabarito, contrato de face, teste de espelho, grade de componentes e gate humano. A folha ativa (Temporal Tower) tem 28 tiles reais e contrato de face OK; a aprovação humana ainda não foi gravada. Nada foi commitado ou publicado.
