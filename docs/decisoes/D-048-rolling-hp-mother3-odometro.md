<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-048 — Mecânica de Vida Rolante (Rolling HP / Odômetro estilo Mother 3 / EarthBound)

- **Data:** 2026-11-03
- **Área:** Combate / UI / Game Feel / Configurações
- **Origem:** Conversa

## O que o criador disse (literal)

> "eu queria que a mecânica de perda de vida funcionasse exatamente como funciona em mother 3 e earthbound, com os valores descendo com o tempo, pesquise sobre antes de me fazer perguntas"
> "(Recommended) Exclusivo do jogador (Fiel a Mother 3 / EarthBound): Apenas os monstros do jogador têm o odômetro de HP rolante; inimigos sofrem o dano e são derrotados instantaneamente."
> "opção A, não esqueça que também fica mais lento pela camera lenta"
> "se o dano for maior que a vida restante, funciona como normalmente funcionaria no jogo, sem levar em conta a mecânica de mother 3"
> "(Recommended) Morte imediata: Se o dano for maior ou igual à vida atual, o monstro é derrotado na hora (faint imediato, HP vai a 0 e toca animação de derrota sem odômetro)."
> "opção A, saiba que tudo isso é uma ideia opcional com configuração pra desligar no jogo"
> "Apenas preparar a chamada de SFX para quando você adicionar seus próprios arquivos .wav/.ogg no projeto."

## Decisão

1. **Escopo dos Combatentes:**
   - Exclusivo para os monstros do jogador (`c.is_player == true`), fiel à mecânica clássica de Mother 3 / EarthBound. Inimigos sofrem dano de forma direta e instantânea, mantendo o ritmo acelerado de eliminação dos oponentes.

2. **Velocidade e Dinâmica de Rolamento:**
   - O rolamento do HP é proporcional à vida máxima (`max_hp`), calibrado para levar aproximadamente **3.0 segundos** para drenar 100% da barra em velocidade normal (1.0x).
   - A velocidade respeita integralmente a escala temporal do motor (D-019): durante a câmera lenta de decisão (D-047 em 0.2x nos menus Fight/Itens), o rolamento do odômetro desacelera na mesma proporção para 20% da velocidade, concedendo janela tática para decisão.

3. **Dano Fatal vs Dano Não-Fatal:**
   - **Dano não-fatal (`dano < vida_restante`):** o dano subtrai o alvo de HP (`target_hp`) e o valor exibido e efetivo desce progressivamente com o tempo até atingir o alvo.
   - **Dano fatal (`dano >= vida_restante`):** conforme instrução direta do criador, golpes com dano maior ou igual à vida restante não utilizam o odômetro; o monstro é derrotado imediatamente (HP vai a zero na hora, `died.emit(self)` dispara e executa o faint imediatamente sem enrolação).

4. **Interação com Cura:**
   - Se uma poção ou habilidade de suporte curar o monstro enquanto o odômetro ainda estiver descendo, o novo alvo é atualizado imediatamente (`target_hp = min(target_hp + cura, max_hp)`) e o odômetro inverte a direção, rolando suavemente para cima até alcançar o novo valor.

5. **Configuração Opcional (Toggle):**
   - A mecânica é opcional, controlada por `GameState.rolling_hp_enabled: bool` (padrão: `true`).
   - A opção pode ser ligada e desligada a qualquer momento no menu de configurações (tecla `C`). Quando desligada, o dano e a cura nos monstros do jogador voltam a ser 100% instantâneos.

6. **Feedback Sonoro (SFX):**
   - Fica estruturado o gancho de SFX `play_odometer_tick()` para disparar a cada variação inteira de ponto no odômetro, permitindo plugar facilmente arquivos de áudio customizados `.wav`/`.ogg` no projeto.

## Ambiguidades em aberto (perguntar antes de agir)

Nenhuma (todas as ramificações alinhadas via /grill-me).

## Estado no código

**Arquivado em 2026-11-06 por D-347.** O odômetro saiu do fluxo ativo: o HP e a barra atualizam imediatamente, o toggle saiu do menu e o sistema foi guardado em `scripts/legacy/rolling_hp_odometer.gd`, com o teste em `tests/legacy/test_d048_rolling_hp.gd`. Quando o criador pedir, o sistema volta a partir desse módulo.
