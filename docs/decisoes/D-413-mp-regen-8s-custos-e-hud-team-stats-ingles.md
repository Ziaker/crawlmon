# D-413 — Regeneração de MP a cada 8s, Custos de MP, HUD TEAM/STATS, Inglês Global e Shift Avançado

- **Data:** 2026-11-07
- **Área:** Combate / MP / UI / Status / HUD / Localização
- **Origem:** decisão direta do criador, na conversa.
- **Estado:** em implementação.

## Declaração literal do criador

> "redundancia aqui, nao precisa desse texto falando a quantidade de blocos. acho que já da pra definir o custo de MP de todos moves, eu quero que vc me sugira e também implemente a mecânica de recuperação de MP a cada 8 segundos, 4 pontos com uma hud presente que mostra quando o MP vai ser recuperado, isso também afeta o oponente e o timer reseta toda vez que usar um move que custa MP (é um timer individual para cada personagem).
Ao lado do nome dos personagens coloque 2 icones placeholder que serão seus respectivos elementos (se tem apenas um aparece apenas um bloco mais largo com o ícone com o fundo do mesmo cobrindo o bloco todo (sem alargar a imagem do ícone futuro))
na segunda imagem que mostra as fraquezas, troque por placeholders que serão os icones equivalentes dos elementos. Além disso troque absolutamente TODO texto do jogo pra inglês, não quero ver português em nada.
remova esse texto de inspeção estilo lol também e permita que apertar a tecla shift, mostre as informações avançadas sobre cada move, mostrando os valores base e o quanto os modificadores os afetam com números precisos e fáceis de se entender assim como em lol
remova tudo da hud que contenha o nome Crawmon, é irrelevante, no topo esquerdo, onde tá escrito crawlmon, troque apenas por TEAM / STATS seguindo a estética visual do jogo, grande, do mesmo tamanho que o texto que tá escrito crawlmon (saiba que vc vai remover-lo, remova também o bloco de texto ao lado do crawlmon pra não ficar duplicado)
@[plugin:canva] quero que crie visualmente estas partes da hud faltantes (exceto icones de elementos por ora)
não exagere nos custos e além disso deixe o MP minimo do abra em 20.
ambiguidades ou planejamento, questione, use suas melhores skills"

## Regras aprovadas

1. **Mecânica de Regeneração de MP (8s / +4 MP):**
   - A cada 8,0 segundos de combate ativo, o combatente recupera +4 pontos de MP (limitado ao seu `max_mp`).
   - O cronômetro de regeneração (`mp_regen_timer: float`) é **individual para cada personagem** (aliados e oponentes).
   - Toda vez que um combatente executa um move que possui custo de MP maior que zero, o seu `mp_regen_timer` é zerado imediatamente para 0,0s.
   - O oponente também segue a mesma regra de regeneração individual de MP.
   - Uma HUD visual deve exibir o progresso de recarga do MP até o próximo pulso de regeneração.

2. **Calibração de MP e Piso Mínimo do Abra:**
   - O MP máximo do Abra possui piso mínimo obrigatório de **20 pontos** (`max_mp >= 20`).
   - Custos de MP moderados e balanceados para todos os golpes:
     - Golpe básico (Tackle): 0 MP.
     - Golpes leves/utilitários (1 ATB): 2 a 3 MP.
     - Golpes médios (2 ATB): 4 a 6 MP.
     - Golpes pesados/AoE (3 ATB): 7 a 9 MP.

3. **Placeholders de Elementos e Fraquezas:**
   - **Ao lado do nome do personagem:** 2 blocos de ícone placeholder representando seus respectivos elementos. Se o personagem possui apenas 1 elemento, exibe apenas um bloco mais largo com o fundo cobrindo o bloco todo (sem deformar a imagem do futuro ícone).
   - **Fraquezas (WEAK):** substitui o texto por blocos placeholders coloridos com os elementos aos quais o combatente é vulnerável.

4. **Identidade Visual e Remoção de Redundâncias:**
   - Remoção de qualquer texto "5 BLOCOS" na linha de ATB (mantém apenas o rótulo "ATB" e os blocos visuais).
   - Remoção de qualquer texto "INSPEÇÃO ESTILO LoL".
   - Remoção de todas as menções à palavra "Crawlmon" na HUD.
   - No topo esquerdo, substitui o bloco anterior por **TEAM / STATS** em fonte grande (40pt Kanit, estética visual com "TEAM" em Paper, "/" em Coral, "STATS" em Lime), removendo o bloco duplicado ao lado.

5. **Exibição Avançada com Shift (LoL Style):**
   - Ao segurar a tecla `Shift`, a ficha tática de habilidade exibe a decomposição matemática completa: valor base de dano + fórmula de modificadores (escalamento de MAG/STR, bônus de Nature, etc.) com números precisos e legíveis.

6. **Internacionalização Obrigatória (100% Inglês):**
   - Todo e qualquer texto da UI e HUD do jogo deve estar estritamente em **Inglês** (eliminando todo português da interface).
