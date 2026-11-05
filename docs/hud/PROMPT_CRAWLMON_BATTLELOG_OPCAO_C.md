# CRAWLMON — PROMPT DE EXECUÇÃO CONTROLADA — BATTLELOG, OPÇÃO C

**Referência obrigatória:** `docs/hud/crawlmon-battlelog-opcao-c-referencia.png` (terceira imagem, opção C, selecionada pelo criador, a disponibilizar no repositório); `docs/hud/Crawlmon_BattleLog_Overhaul_Opcao_C_2026-11-05.docx` (documentação visual extensa, a disponibilizar no repositório). **Nunca finja que um arquivo existe:** se o PNG ou DOCX não estiverem publicados, solicite os arquivos anexos ao criador em vez de inventar a referência.

## 0. Natureza da autorização

O criador selecionou expressamente **a terceira imagem, opção C**, como **referência visual do BattleLog**. Ele pediu que um prompt e um DOCX extenso acompanhassem a imagem no GitHub. Isso **não autoriza** aplicar mudanças de código, reestruturar a HUD, trocar a estética de outros componentes ou inventar novas regras de combate. Uma implementação futura, se solicitada, deve cumprir exatamente as restrições desta especificação e das decisões vigentes.

## 1. Conferência obrigatória do repositório

1. Abra a branch `main` mais atual do repositório `Ziaker/Crawlmon`.
2. Leia `AGENTS.md`, `docs/decisoes/README.md`, as decisões relacionadas (especialmente D-003, D-015, D-061, D-235, D-268 e D-322) e `docs/REGRAS_DO_JOGO.md` na parte pertinente. Não use o GDD antigo como fonte de combate.
3. Consulte `prototypes/crawlmon-hud-buffs-debuffs-aprovado.html` e a referência de HUD em `docs/hud/crawlmon-hud-buffs-debuffs-preview.png`.
4. Confirme, sem presumir, a implementação atual de BattleLog e câmera em `scripts/ui/battle_hud.gd`, e as origens reais de eventos em `scripts/combat/battle.gd` e arquivos relacionados.
5. Informe os SHAs/branch consultados, arquivos envolvidos, as decisões aplicáveis e qualquer divergência entre código e documentação.

**Constatação da auditoria de 05/11/2026 (não presumir que ainda esteja atual):** em `scripts/ui/battle_hud.gd`, `_log` era um `Label`, `_log_lines` era `Array[String]`, e `_on_log(text: String)` mantinha três mensagens. `scripts/combat/battle.gd` emitia `signal log_message(text: String)`. Isso não fornece por si só um ID tipado da entidade para o retrato. Reconfirme antes de implementar; não deduza identidades por comparação textual de nomes.

## 2. Objetivo visual delimitado

Refazer **somente a aparência do BattleLog** tomando como molde o log no quadrante superior direito da **opção C selecionada**. O novo BattleLog é uma **pilha de faixas brancas/off-white estreitas, inclinadas/angulares, com recortes diagonais visíveis**, sem painel retangular escuro contínuo por trás, e com **um retrato/ícone do personagem relacionado em cada registro**. A composição fica no canto superior direito; a área antes ocupada pelas abas de câmera fica livre na proposta visual. Não remover o comportamento do diretor de câmera, sinais ou atalhos por inferência.

### Identidade a reproduzir

- **Cabeçalho:** `BattleLog` grande, ciano/azul, inclinado/itálico, acima das entradas; preservar a identidade tipográfica já aprovada no HTML.
- **Entradas:** cartões finos off-white, com bordas angulares e extremidades cortadas em diagonal, alinhados visualmente à direita e com defasagens discretas.
- **Retratos:** ao menos um retrato/ícone legível por evento, em recorte integrado à extremidade da faixa. Fonte de retrato deve vir dos recursos reais do jogo, sem atribuição fixa por espécie/equipe/lado.
- **Hierarquia:** personagem + verbo/ação + efeito/valor destacados; manter a leitura numa única olhada. Texto escuro contrastante sobre a faixa clara, estilo tipográfico pesado e inclinado.
- **Acentos:** cores para distinguir a mensagem representada no exemplo (rosa/vermelho em dano, roxo em status específico, verde-limão no aumento de atributo, ciano no destaque geral). **Não inventar um mapa global de cores** nem dar à cor roxa papel novo fora do que já foi aprovado.
- **Área:** respeitar legibilidade dos inimigos, arena e placas de personagem; sem caixa preta/azul cobrindo a cena.
- **Demais componentes:** preservar HUD aprovado do 04/11/2026: cartões de Abra e Pancham brancos, menu principal em leque, buffs/debuffs como peças diagonais coloridas, tag do inimigo, tarja de habilidade em preparo. A imagem C é somente a aprovação do log; alterações periféricas que o gerador de imagem introduziu são ilustrativas, não novos requisitos.

### Entradas que constam do mockup (CONTEÚDO ILUSTRATIVO, não regra do motor)

1. Retrato do Abra à esquerda — `Abra used Psybeam!` — detalhe magenta de Move.
2. Retrato do Gible à direita — `Gible took 20 damage!` — detalhe vermelho de dano.
3. Retrato do Gible à direita — `Poison applied to Gible!` — detalhe roxo do status.
4. Retrato do Pancham à esquerda — `Pancham gained DEF+1!` — detalhe verde/amarelo do aumento.
5. Retrato do Gible à direita — `Gible is ready!` — detalhe ciano.

**A posição esquerda/direita do retrato no exemplo não determina política geral baseada em atacante/alvo; essa semântica não foi aprovada.** Os textos, número de entradas, valores de dano, efeitos e Moves são demonstrativos. Não introduzir `Psybeam`, `Poison`, `ready` ou `DEF+1` como novas mecânicas com base nesta figura.

## 3. Integração técnica: análise antes da execução

1. Auditar quais eventos já são disponibilizados pelo combate, sua ordem e seus dados de origem; não alterar lógica, determinismo, momento de emissão nem resultados.
2. Identificar como referenciar personagem e seu retrato por ID estável sem analisar textos humanos. **Não adotar silenciosamente** uma arquitetura (`Dictionary`, resource, signal, classe, singleton etc.) antes de comparar com o projeto.
3. Distinguir emissor do evento, personagem afetado, evento global e entradas com múltiplos participantes; **não decidir automaticamente** qual retrato mostrar onde a decisão não existir. Registrar a lacuna e submetê-la para aprovação antes da implementação definitiva.
4. Investigar comportamento do log em Status/Tactics, combate pausado, resolução simultânea, quantidade de eventos e histórico. Preservar o comportamento vigente até que haja decisão explícita sobre expandir, colapsar, limite, scroll, temporização e persistência.
5. Se a remoção dos **botões visuais** de câmera for implementada em pedido futuro, preservar o sistema de direção/câmera subjacente salvo instrução expressa contrária.
6. Garantir independência de personagem, equipe e lado do campo (D-235): não fixar retratos ou cores a Abra, Gible, Pancham ou jogador.

## 4. Critérios verificáveis de aceitação visual

- [ ] BattleLog na direita superior, sem invadir ou ocultar inimigos vivos visíveis.
- [ ] Cabeçalho azul/ciano na linguagem do HTML aprovado.
- [ ] Faixas off-white, finas, angulares e inclinadas; sem fundo escuro contínuo.
- [ ] Retrato ou ícone integrado a cada linha demonstrada.
- [ ] Tratamento cromático pontual por tipo de mensagem da amostra, sem impor semântica não aprovada.
- [ ] Texto legível e com alinhamento claro; cortes não eliminam retratos ou conteúdo.
- [ ] Sem deslocar cartões brancos, menu em leque, peças de efeito e tarja de habilidade.
- [ ] Sem implementar mecânicas a partir dos exemplos visuais.
- [ ] Sem atrelar Move/efeito/retrato ao nome de espécie ou ao lado do combate.
- [ ] Sem alterações de código ou documentação fora do escopo autorizado.

## 5. Procedimento de validação e entrega (quando implementação for autorizada)

1. Antes da edição, verifique `git branch --show-current`, `git status`, SHA atual e arquivos a alterar. Não sobrescreva trabalho de outras sessões.
2. Faça uma alteração visual por vez com comparação lado a lado com **o recorte do BattleLog da opção C** e com o HTML aprovado; sem modificar componentes periféricos.
3. Rode os testes relevantes ao projeto de acordo com scripts reais; inclua casos de aliado, inimigo, um evento global, evento com múltiplas entidades e campos ausentes quando o motor fornecer dados. Relate o que não foi possível testar.
4. Registre decisões novas conforme D-061, mas nunca transforme sugestões em decisões aprovadas.
5. Ao final, mostre capturas e diff, explique quais arquivos foram modificados e os que permaneceram intocados; **não faça commit/push sem autorização expressa**.

**Limites desta instrução:** este arquivo é um prompt para a etapa futura. A presente entrega documenta a opção C, não implementa o BattleLog no Godot.
