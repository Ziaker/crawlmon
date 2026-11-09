# D-1026 — Armored Bulk e a badge Armor

- **Data:** 2026-11-09.
- **Área:** Combate / Moves / Status / VFX.
- **Origem:** conversa. Brainstorm de um Move genérico novo para Orc e Cyclops.

## Frase literal do criador

> Armored Bulk - 10MP/1ATB/STATUS/SELF/TERRA/INSTANT wind up
>
> Mecânicamente: Os musculos do usuário se flexionam e pressionam-se a ponto de se metalizarem, ganhando ARMOR por 8 segundos.
>
> visualmente: Você define 3 opções de como será o start e o release do move (como o wind-up é rapido, o start e o release vão estar interconectados)
>
> ARMOR (Badge positiva de status nova de cor cinza e visual metálico) : Personagens sob o efeito de armor não sofrem interrupção ao sofrerem a primeira instância de dano com a badge, destruindo a badge no processo caso receberem dano advindo de moves (não é destruido contra efeitos de status como poison e burn). Se tornando ímunes a efeitos causados por contato e impacto com a badge ativa (pro exemplo, um move que, ao contato, cause Stun por 4 segundos: A badge é removida, o dano é sofrido ainda mas o efeito de stun não é causado)
>
> animação: Animação de vitória do personagem
> efeito visual no modelo causado pela badge: Envolto em um filtro de textura cromada de baixa opacidade, não obstruindo a textura completa do personagem

Respostas do criador à rodada de perguntas:

> vamos com a opção A por ora
> 1 - guard tem maior prioridade e não desliga a badge
> 2 - sim impede qualquer tipo de knockback exceto o de KO.
> 3 - sim
> 4 - como confirmado acima, guard tem maior prioridade e não desliga a badge ao sofrer contato
> 5 - adiciona + 8 segundos ao tempo restante apenas, não stacka badge
> 6 - sigo sua recomendação criativa
> 7 - sim e sim
> 8 - não
> 9 - algum ícone de armadura? algo como um capacete ou um peitoral  de armadura
> 10 - todo efeito de duração pausa quando outro aciona a pausa, isso é regra definida não?
> 11 - sim, inclusive pancham poderá aprender também
> 12 - inteiro

## Decisão

1. **Armored Bulk:** 10 MP, 1 ATB, STATUS, SELF, elemento TERRA, wind-up instantâneo. Move genérico por `move_id` (D-235): Orc e Cyclops o têm agora; Pancham o aprenderá por nível, mas fica fora por ora; comportamento idêntico em qualquer personagem, time e lado.
2. **Efeito:** concede a badge **ARMOR** por 8 s ao usuário.
3. **Recast:** soma +8 s ao tempo restante; a badge não acumula.
4. **ARMOR** (badge positiva nova, cinza, visual metálico):
   - No primeiro dano de Move recebido com a badge: sem interrupção (sem hit stun/cambaleio), a badge é destruída e o dano é sofrido normalmente.
   - Anula efeitos de contato e impacto (ex.: o STUN de 4 s não é aplicado, e a badge é consumida) e **qualquer knockback, exceto o de KO**.
   - Dano de status (poison, burn) não consome a badge.
   - **Guard tem prioridade:** com Guard ativo, a Armor não é consumida ao sofrer contato.
   - AoE: cada alvo consome a própria Armor no seu primeiro contato.
5. **Burst não paga** o Move.
6. **Animação:** clipe de vitória do personagem (DQT clipe 02 `victory`), **inteiro**. Pancham: clipe de vitória dele, a verificar.
7. **Visual no modelo:** filtro cromado de baixa opacidade, sem cobrir a textura.
8. **Start/Release:** opção A, "Flexão e Cromagem de baixo para cima": o usuário se agacha e contrai; uma onda de cromo sobe dos pés à cabeça com a fronteira brilhante; no release, anel de choque raso no chão e faíscas metálicas curtas; o cromo assenta no filtro da badge. Aprovada "por ora".
9. **Pausa:** efeitos de duração (a Armor de 8 s) pausam quando o motor é pausado por outro status (D-031). O criador perguntou se isso já é regra; a verificar no código.

## Segunda rodada de respostas

> 1 Sim
> 2 1,5s
> 3 sim
> 4 sim, inclusive sua duração também continua a reduzir normalmente
> 5 sim, mas não usaremos com ele ainda então o ignore por ora, só deixe registrado q ele aprende upando de nível, não precisa perguntar que nivel

10. **IA:** usa Armored Bulk quando tem 1 ATB sobrando e há golpe com efeito de contato forte vindo, sem Armor ativa (proposta do assistente, aprovada com "Sim").
11. **Pausa do Move:** o Armored Bulk pausa o motor por **1,5 s** (D-031: 0,5 s de preparo + 1,0 s de efeito), mesmo com wind-up instantâneo. Ambiguidade: o wind-up instantâneo e o preparo de 0,5 s de D-031 conflitam; a pausa fica em 1,5 s no total, como o criador confirmou.
12. **Recast:** os 10 MP e o 1 ATB são cobrados mesmo com Armor ativa.
13. **Guard + Armor:** com Guard ativo, a Armor não é consumida e **sua duração continua a diminuir normalmente** durante o Guard.
14. **Pancham:** poderá aprender o Move **subindo de nível** (nível não definido; o criador disse para não perguntar). **Ignorar por ora**: não implementar no Pancham agora.

## Terceira rodada de respostas

> um icone tipo estes 2,vamos testar com os 2 para eu ver e decidir qual aprovar
> 2 sim
> 1 sim, é o anel de choque o impacto

(Imagens de referência enviadas: um **peitoral** de armadura em silhueta preta com ombreiras e um **capacete** espartano em silhueta preta. Ficam só na conversa, não foram copiadas para o repositório.)

15. **Ícone da badge:** testar os **dois** (peitoral e capacete, no estilo das imagens de referência) para o criador ver e **aprovar um depois**. Nenhum está aprovado.
16. **Trajeto e Impacto (D-308):** o Move não tem trajeto (fase vazia). O **impacto é o anel de choque** no chão.

## Ambiguidades em aberto (perguntar antes de agir)

- **Cor** da badge: cinza por volta de `#9aa3ad` é escolha do assistente (a confirmar).
- **Pausa de durações (item 10 do criador):** não verificado no código se os timers de badges pausam com o motor.
- **Clipe de vitória do Orc/Cyclops:** o clipe 02 `victory` é o que está no doc de importação (`docs/IMPORTACAO_MODELOS_DQT.md`); não verificado se o clipe existe e toca inteiro em batalha.

## Quarta rodada (2026-11-09)

> autorizo ambos cor e implementação

17. **Cor da badge** aprovada: cinza `#9aa3ad` (texto escuro).
18. **Implementação autorizada.**

## Quinta rodada (2026-11-09)

> Peitoral (ícone da badge)
> "Me impressione" (qual ajuste visual fazer)

19. **Ícone aprovado: peitoral.** O capacete fica só no código, sem uso.
20. **Ajuste visual delegado** ("Me impressione"): o assistente escolheu **um** ajuste, o brilho do filtro cromado (reflexo que se move e mais contraste), a mostrar ao criador antes de seguir.

## Estado

Implementado (2026-11-09), **aguardando aprovação visual do criador**:
- Mecânica: `Combatant.armor_timer` / `apply_armor` / `end_armor`, `Battle._hit` (ARMOR), `Battle._execute_status_move("armored_bulk")`, pausa total de 1,5 s, IA (`ARMOR_WORTHY_CONTACT`), Move no Orc e no Cyclops (`dqt_test_party.gd`, `enemy_factory.gd`). Teste: `tests/battle/test_d1026_armor.gd`.
- HUD: badge com os dois ícones (`scripts/ui/armor_icons.gd`; `--armor-icon=capacete` ou `CRAWLMON_ARMOR_ICON` escolhe; padrão peitoral). Nenhum ícone aprovado.
- VFX opção A: filtro cromado (`shaders/armor_chrome.gdshader`), partículas no Motion Composer (`armored_bulk_effect`, `armor_break_effect`), Composer V1.12 (`floor_ring`).
- Pancham: **não** recebe o Move por ora.
- Verificado: teste headless de mecânica; vídeo nas duas vistas (Abra como lançador na vista normal, Orc na espelhada). **Não verificado:** Cyclops como lançador, clipe de vitória inteiro no Orc/Cyclops (a animação tocada no Orc foi o clipe que o modelo oferece), Armor sendo quebrada num golpe real em batalha (só no teste headless), desempenho.
