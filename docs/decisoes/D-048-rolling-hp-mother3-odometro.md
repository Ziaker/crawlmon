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

Implementado e validado por testes automatizados (`tests/battle/test_d048_rolling_hp.gd`).

## Complemento posterior — Rodada 70 / D-203 (2026-11-04)

**Superada para o jogo principal, sem apagar este histórico.** O criador determinou expressamente: **“o odometro era só um teste, não usaremos ele no jogo principal, descarte toda e qualquer ideia que o envolva”**. Conforme [D-203](D-203-r70-q4d-odometro-descartado-jogo-principal.md), toda esta mecânica de HP rolante, sua opção de ativação e ideias dependentes dela ficam **fora dos requisitos do jogo principal**. A implementação e os testes antigos podem continuar fisicamente presentes no repositório, mas não comprovam vigência do requisito nem autorizam sua integração no jogo principal. Esta anotação preserva o testemunho histórico do teste e **não modifica código**. A outra D-048 (ATB de AoE) é distinta e não é afetada.

