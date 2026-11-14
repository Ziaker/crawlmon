<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1060 — A câmera nunca pode obstruir a visão; só pode aumentar o POV

- **Data:** 2026-11-09.
- **Área:** Câmera.

## Frase literal do criador

> tem como ajeitar a camera e fazer ela parar de se mover assim, deixe ela normal como sempre, tire esse movimento que obstrui visão

> não é só durante o armored bulk é durante a maioria dos outros moves, a camera NUNCA pode obstruir visão, só aumentar o Pov para questões de camera

## Decisão

1. A câmera **nunca** pode obstruir a visão da batalha.
2. Para fins de câmera, ela só pode **aumentar o POV** (ampliar o campo visto). Aproximar-se, fechar o enquadramento num personagem ou qualquer movimento que tampe a visão está proibido.
3. Vale para **a maioria dos Moves**, não só o Armored Bulk.

## Relação com decisões existentes (preservadas até o criador decidir)

- **D-060 / D-070:** "a câmera acompanha o efeito de status". Conflita se "acompanhar" fechar o enquadramento.
- **D-050 (10A):** "zoom e deslocamento para manter todos visíveis". Compatível se o zoom for só para ampliar.
- **D-1012:** câmera de impacto mais alta e no ponto médio (`action_raise`). A conferir.
- **D-015 / D-039:** o inimigo sempre visível. Compatível.
- No Armored Bulk, a câmera já foi desligada (`fx_telegraph.gd`, `resolve_attack`), por pedido anterior.

## Respostas do criador

> Movimento: "Ampliar e subir"
> Mira: "Mira pode seguir"
> Escopo: "Ataques e status", "Impacto e KO", "Evade e câmera lenta" (a tela de Status **não** entrou)

4. A câmera pode **abrir o FOV e ficar mais alta**, mas **nunca avança** (nem fecha o enquadramento, nem cobre o personagem).
5. A **mira pode seguir** a ação.
6. Vale para Moves de ataque e de status, impacto e KO, Evade e câmera lenta. O close da **tela de Status** (menu) fica como está.

## Divergências com decisões anteriores (a decisão nova vale; as antigas ficam registradas)

- **D-1010 / D-1011** ("a câmera avança até onde couber", até 12 m): o avanço foi **zerado** (`SA_MAX_DOLLY = 0`). A abertura de FOV e o giro de mira do enquadramento seguro continuam.
- **D-1012** (avanço de até 4 m na câmera de ação e "empurrão" de FOV a cada golpe): avanço **zerado** (`SA_ACTION_DOLLY = 0`) e o empurrão **deixou de ser desenhado** (`camera.fov` não subtrai mais `_fov_kick`). A câmera de ação mais alta (4,5) e apontada ao ponto médio continua.
- **D-060 / D-070** (a câmera acompanha o efeito de status): continua acompanhando a mira, sem aproximar.
- **Não alterado:** o tremor de acerto e de KO (D-157, D-049), que não fecha o enquadramento. Se o criador quiser retirar o tremor também, é outra decisão.
- Armored Bulk: continua sem nenhum movimento de câmera (pedido anterior).

## Estado

Implementado (`scripts/combat/battle_camera.gd`). Verificado em vídeo (Tackle e Armored Bulk, vista normal e espelhada): o enquadramento não se aproxima de ninguém. **Não verificado:** KO, Evade/câmera lenta, Moves com a câmera em modo Tática; os testes `test_d157_hitshake_and_launch` já falhavam em 2 asserções de valor do `_fov_kick` (esperavam o valor antigo, anterior à D-1012) e continuam falhando igual.
