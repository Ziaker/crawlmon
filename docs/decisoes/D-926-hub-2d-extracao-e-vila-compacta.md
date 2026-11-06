# D-926 — Hub 2D: base compacta que cresce para vila, com modelo de extração

> **Renumerada em 2026-11-06:** D-324 → D-926. O ID D-324 já pertence a outra decisão no `origin/main`; o conteúdo local foi preservado com o novo ID.


- **Data:** 2026-11-05
- **Área:** Exploração / campanha / visual
- **Origem:** Conversa (resposta ao brainstorm do hub)

## O que o criador disse (literal)

> sigo suas recomendações

As propostas abaixo são as que o assistente marcou como recomendação no brainstorm anterior. A frase do criador aceita essas recomendações; o texto das propostas é do assistente, não uma fala do criador.

## Decisão (direção aceita)

1. **Forma:** o hub é um lugar 2D jogável, não uma tela de menu. A primeira versão é uma **base compacta de uma tela fixa**, sem interiores, com fachadas ao fundo, uma praça central e serviços em bancas/NPCs. Ela começa como acampamento/base e **cresce para vila por plots vazios e NPCs novos**, sem mapas novos.
2. **Serviços como personagens:** cada serviço é um NPC ou uma banca com identidade, como o Kangaskhan Storage da referência; não é um botão de menu solto.
3. **Loop de extração:** o hub é a base da campanha. A escada do 5º andar continua a expedição; **extrair** volta ao hub; o chefe abre a próxima dungeon. A extração tem o custo já aprovado (itens obtidos na expedição e não segurados são perdidos; XP, níveis e recrutados ficam — R25-Q4/R31-Q1/R32-Q3/R24-Q5). Os gatilhos exatos de retorno continuam pendentes (D-316/D-317; GDD R26-Q4).
4. **Visual:** mesma linguagem 2D top-down do overworld; sprites existentes; **sem modelos novos** e **sem sombra elíptica sob as entidades** (D-313). Os tiles podem ser reutilizados/melhorados; a paleta segue a arena 3D (D-921/D-278). O portão enquadra o bioma atual.
5. **Núcleo funcional:** portão/quadro de expedições e guilda/mesa de equipe, mais NPCs de ambientação. Os demais serviços são candidatos, não parte da direção fechada.
6. **Não presunções:** o hub **não** é automaticamente obrigatório, **não** substitui automaticamente a seleção/progressão da campanha e **não** passa a ser o único lugar de troca de equipe (GDD R25-Q2). Nada de economia, preços, armazém, save, protagonista ou fila de aliados no hub foi decidido por esta direção.

## Ambiguidades em aberto

- O hub substitui a tela de seleção/progressão da campanha ou é opcional?
- Quais serviços entram na V0/V1 além do portão e da guilda? (loja, armazém, dojo/mestre, treino da reserva, estalagem/enfermaria, registro)
- Economia: moedas, preços e catálogo da loja.
- Armazém: capacidade, acesso e interação com a perda de itens não segurados.
- Estalagem/cura: o que cura, quando, e se compete com os pontos de descanso (D-311/D-316).
- Save/persistência: entra nesta fase? Sem save, o hub não cresce entre sessões.
- Protagonista: hoje o mapa desenha Pikachu e a batalha começa com Abra; qual é o canônico?
- Aliados seguem em fila no hub (D-309/D-314) ou ficam espalhados?
- Recrutas aparecem fisicamente na vila? A vila cresce com a campanha?
- Iluminação: dia claro, entardecer ou noite com lanternas? O hub é 100% iluminado e sem ameaça (D-033/D-310)?
- Planta, câmera, tamanho do mapa e nome do hub.
- Qualquer VFX novo do hub segue D-308 e o protocolo obrigatório.

## Relações

- D-921, D-922, D-278 e D-313: visual 2D, referência Mystery Dungeon, sprites existentes e ausência de sombra sob as entidades.
- D-316 e D-317: expedição de 5 andares, bioma e nova expedição.
- D-309 e D-314: fila de aliados (a confirmar no hub).
- D-319: a batalha 3D continua com o Gible fixo; o hub não mexe no combate.
- D-235: se o dojo exibir Moves, valem as regras de independência de personagem e lado.
- GDD R25-Q2, R26-Q4, R29-Q1, R31-Q4, R33-Q2 e R37-Q3: equipe/reserva, retorno à campanha, lojas, objetivos por NPCs, treino da reserva e desbloqueio por chefes.
- D-308: protocolo de VFX, se houver efeito novo.

## Divergência de código observada (não corrigida)

- `scripts/dungeon/map_visuals.gd` desenha sombras elípticas sob jogador, NPCs, inimigos e itens (por volta das linhas 455–470), enquanto a D-313 diz que a sombra sob as entidades não foi escolhida e não deve ser implementada sem nova autorização. Se o hub reutilizar esse visual, herda a divergência. Nada foi alterado.
- O mapa desenha Pikachu (`scripts/dungeon/player.gd`) e a batalha começa com Abra (`scripts/autoload/game_state.gd`); o protagonista canônico do hub continua pendente.

## Atualização (D-927/D-928)

- A parte “sprites existentes / sem modelos novos” desta direção passa a valer para Pokémon e para o que não foi autorizado. Assets não-Pokémon do PMD foram autorizados pela D-927; a ordem (Time/Darkness primeiro), os tilesets e a escala de 24 px estão na D-928.

## Estado no código

Não implementado. Nenhum código, cena ou VFX foi alterado. O hub não existe no projeto.
