<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-235 — Moves e efeitos são independentes de personagem, de lado e de posição

- **Data:** 2026-11-04
- **Área:** Combate / Visual / VFX / Processo
- **Origem:** Conversa

## O que o criador disse (literal)

> "vc precisa urgentemente levar em conta que nao estamos fazendo moves que so um personagem faz, tem personagens que vao ser capaz de fazer tambem entao nao pode so funcionar em apenas UM, e tambem obviamente levar em conta de que o inimigo distante tambem pode realizar o mesmo move se tiver ele equipado, e o efeito visual nao deve funcionar so de um lado. E UMA REGRA OBRIGATORIA PRA SE LEVAR EM CONTA ATE EM PROTOTIPOS, COLOQUE ISSO NA MEMORIA, NO AGENDS MD E NO GITHUB, OBRIGATORIO"

## Decisão

1. **Regra obrigatória, inclusive em protótipos, laboratórios e salas de debug.** Ela está também em `AGENTS.md` (seção 7).
2. Todo Move pode ser usado por **qualquer personagem**, de **qualquer time** (aliado ou inimigo), em **qualquer lado do campo** (perto ou longe da câmera) e contra qualquer alvo. O mesmo Move equipado em dois personagens funciona igual.
3. VFX, animação, câmera, UI e testes de um Move **não** podem depender de personagem (nome, espécie, modelo), de time, de `is_player`, de lado, de direção fixa da câmera nem de posições ou coordenadas fixas. Tudo é derivado do atacante e do alvo reais: eixo atacante→alvo, altura/raio/centro medidos do modelo, distância e escala da câmera.
4. O comportamento é por `move_id`. Nomes e arquivos com nome de personagem são só rótulos históricos.
5. Antes de dar um Move por pronto: testar com outro atacante, com o lado espelhado (atacante inimigo e distante) e com alvos de tamanhos diferentes, e dizer o que não foi testado.

## Ambiguidades em aberto

Nenhuma.

## Estado no código

Em vigor como regra de processo. Os VFX existentes dos moves do Abra (`scripts/combat/fx/abra_move_vfx.gd` e correlatos) já são por `move_id` e medem o corpo do atacante e do alvo, mas ainda não foram testados com outros atacantes além do Abra e do Gible; essa verificação continua pendente.
