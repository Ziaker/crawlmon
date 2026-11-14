<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1100 — Ataque no overworld e três transições de combate

- **Data:** 2026-11-10
- **Área:** Exploração / overworld 3D / encontros / transição
- **Origem:** pedido do criador para trabalhar no overworld com outro agente e respostas às perguntas bloqueantes do plano.
- **Status:** **implementado no lab 3D e testado**; vídeos gravados; pendente só a aprovação visual dos valores (D-1106); plano em `docs/PLANO_OVERWORLD_ATAQUE_TRANSICOES.md`.

## O que o criador disse (literal)

> quero agora que trabalhe junto com outro agente no overworld
>
> as mecânicas que eu quero são
> 1 - botão pra atacar no overworld, o personagem realiza um avanço pequeno atacando na direção de um inimigo próximo, ocasionando na transição de combate (ao invés de 1 transição haverá 3, uma normal de contato, uma em que o inimigo te ataca primeiro e uma onde vc ataca primeiro, com cor diferente, azul quando ataca primeiro, vermelho quando perde e branco quando é apenas contato) O inimigo também é capaz de atacar com um avanço rápido, visualmente tem efeitos visuais de Speedlines no personagem do jogador e no do oponente, além de mostrar um rastro no chão e ter os dust de opacidade reduzida de corrida dos perosonagens

Respostas às perguntas bloqueantes (rótulos escolhidos):

> Lab 3D (Recomendado)
>
> Contato normal (Recomendado)
>
> Mesma tecla de interagir

Segunda rodada:

> Todos do lado (Recomendado)
>
> Sem batalha (Recomendado)
>
> Inimigo primeiro (Recomendado)
>
> Ao entrar em CHASE (Recomendado)
>
> 0,4 s / 4 s (proposta)
>
> Quem acertou leva (Recomendado)

Terceira rodada:

> [Z] ATTACK
>
> Raio 4,5 m, qualquer direção
>
> Só inicia o encontro (Recomendado)
>
> Só no avanço (Recomendado)
>
> Linhas 3D no corpo
>
> Mesma posição no lab (Recomendado)
>
> Não, efeito de overworld (Recomendado)

## Decisão

1. **Alvo inicial:** lab 3D (`scenes/debug/murky_forest_3d_lab.tscn`, herdando `scripts/debug/third_person_3d_lab.gd`). O overworld 2D (`scenes/exploration.tscn`) e o main scene atual não mudam nesta etapa.
2. **Três transições:** contato normal = **branco**; jogador ataca primeiro = **azul**; inimigo ataca primeiro = **vermelho**.
3. **Empate:** se os dois avanços se encontrarem no mesmo instante, vale o **contato normal (branco)**, sem vantagem para nenhum lado.
4. **Input (atualizado pela D-1127):** o ataque é **somente Z**; perto de inimigo, o prompt é `[Z] ATTACK`. **E não ataca mais**; E/Z continuam interagindo/falando com NPC/porta quando não há inimigo. **Prioridade:** se um NPC e um inimigo estiverem no mesmo alcance, o **inimigo** mantém o prompt/alvo do ataque; E não inicia ataque.
5. **Avanços:** o jogador faz um avanço curto na direção de um inimigo próximo; o inimigo também pode atacar com um avanço rápido.
6. **VFX do avanço:** speedlines no jogador e no oponente, rastro no chão e dust de corrida com opacidade reduzida.
7. **Erro do ataque:** se o ataque do jogador errar, **não inicia batalha**; toca só a animação. O encontro começa no acerto ou no contato.
8. **Ataque do inimigo:** ele inicia o avanço rápido ao **entrar em `CHASE`**, com **telegraph de 0,4 s** e **cooldown de 4 s**.
9. **Dois avanços, um acerto:** se só um dos dois acerta, **quem acertou** leva a vantagem; se os dois acertam no mesmo instante, a transição é **branca**.
10. **Alvo do ataque:** o inimigo mais próximo em um **raio de 4,5 m**, em qualquer direção; o personagem vira para ele.
11. **Dano no overworld:** o ataque **não causa dano nem status**; só inicia o encontro.
12. **Dust:** opacidade reduzida **só no avanço**; a corrida normal continua como está.
13. **Speedlines:** **linhas 3D**, dimensionadas pelo corpo do ator; ficam **presas ao ator só nos primeiros 0,04 s** do dash e depois no **espaço do mundo** (não overlay 2D; D-1127).
14. **Retorno:** a batalha volta para a **mesma posição e direção** do lab 3D.
15. **D-308:** **não se aplica**; é efeito de overworld, verificado com frames/vídeo da skill de VFX.
16. **Prompt:** o ataque mostra `[Z] ATTACK` quando há inimigo no raio de 4,5 m.

## Aparência fina (Fase 3)

- Quantidade, cor e tamanho das speedlines, do rastro e do dust serão iterados com capturas; não são regra de gameplay.
- Distância/tempo do avanço e cooldown do jogador: valores de protótipo no vídeo do lab real; aguardando aprovação (D-1106).

## Implementação e testes (2026-11-10)

- Contrato: `scripts/overworld/encounter_rules.gd`, `GameState.start_battle_3d`, variantes em `scripts/ui/transition.gd`, aplicação do ATB em `scripts/combat/battle_scene.gd`.
- Ataque: `scripts/overworld/overworld_attack_controller.gd`, integração em `scripts/debug/third_person_3d_lab.gd` e `scripts/debug/murky_forest_3d_lab.gd`.
- VFX: `scripts/overworld/vfx/*` (speedlines 3D, rastro no chão, dust).
- Testes: 24/24 regras; 100/100 VFX (64/64 headless + gate de overdraw 5/6,5 nas duas vistas); 66/66 controlador; 16/16 suíte de combate; ponta a ponta player-first (party 4, inimigos 2), enemy-first (party 2, inimigos 4), Gible com VFX vermelho e derrota sem resetar o 2D, com retorno na posição/yaw.
- Contato normal andando: `_check_contact()` no controller; testado (branco) e gravado.
- Animação: clipe `attack` no início do dash do jogador, do Slime e do Gible, a **2,0×**, com pré-avanço de **0,12 s** sem congelar e dash de **até 0,18 s** (D-1112/D-1120); impacto do Tackle de 0,5 s no contato (D-1115); speedlines no espaço do mundo, com deslize/alongamento/rotação, e VFX limpo no contato (D-1119); `walk`/`idle` volta depois.
- Capturas dos VFX: `docs/referencias/exploracao/3d/overworld_dash_vfx_*` (dummies, normal/espelhada).
- Vídeos no lab real: `docs/referencias/exploracao/3d/overworld_attack_player.mp4/.gif` (azul/`VANTAGEM`), `overworld_attack_enemy.mp4/.gif` (vermelho/`EMBOSCADA`) e `overworld_attack_contact.mp4/.gif` (branco/`CONTATO`); folha `overworld_attack_lab_sheet.png`; combinado `overworld_attack_3cases.mp4/.gif` (os três em sequência, com rótulos); demo limpa `overworld_showcase_demo.mp4` (HUD oculto, câmera de lado, 4×) com os alvos visíveis (D-1125).

## Pendências de aprovação

1. **Resolvidas por D-1106:** segundo inimigo não-Medroso (Gible) para o vermelho; empate com cores por ator; derrota no lab sem resetar o 2D; reataque uma vez por entrada em `CHASE`; selo/tons mantidos.
2. **Pendente:** aprovação visual dos valores de avanço, do pré-avanço de **0,12 s**, do dash de **até 0,18 s**, do impacto do Tackle de 0,5 s e das speedlines no espaço do mundo (D-1112/D-1115/D-1119/D-1120) no vídeo do lab real. Se aprovado, os valores deixam de ser protótipo.

## Estado

Implementado no lab 3D e testado; demo em slow motion (`overworld_showcase_demo.mp4`, 120→30 fps, 4×) gravada; pendente só a aprovação visual dos valores. Nenhum commit e nenhum push.
