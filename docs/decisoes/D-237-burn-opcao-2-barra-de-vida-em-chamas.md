# D-237 — Burn: opção 2 (HUD com o dano pendente) e barra de vida em chamas para jogador e aliado

- **Data:** 2026-11-04
- **Área:** Combate (status Burn) / HUD / VFX
- **Origem:** Conversa. O criador pediu "3 ideias que tem em mente para como o burn funcionará e será visualmente"; respondeu:

> Opção 2 mas saiba como adaptar pro jogador também, estou pensando em mudar a cor da barra de vida do jogador/aliado pra um laranja escuro que pulsa com efeitos de fogo, sem comprometer informações, prepare um vídeo usando o motion composer se possível

## As 3 ideias apresentadas (o criador escolheu a 2)

2. **Queimadura que "pesa" (leitura clara no HUD):** 1 tick de 2 HP por segundo durante 4 s (da ficha, D-236); o status aparece na barra de status do personagem com ícone de fogo e contador de 4 s; o modelo ganha um contorno laranja pulsante no ritmo dos ticks; a barra de vida mostra um trecho laranja do dano que ainda vai chegar (os 8 HP pendentes) e cada tick tira um pedaço dele, com o rolling HP já existente (D-048).

## Decisão

1. A opção 2 é a base do Burn. A parte mecânica **continua pendente** como na D-236 (instante do primeiro tick, reaplicação sobre alvo já queimando, MP, `10 + MAG`, chances de Burn). Nada disso foi implementado.
2. Para **jogador e aliado**, a barra de vida passa a ser **laranja escuro que pulsa, com efeitos de fogo**, enquanto o Burn durar, **sem comprometer informações**. Interpretação aplicada no protótipo (não confirmada ponto a ponto): o comprimento da barra continua sendo a vida real; o texto "HP x/y" não muda de lugar, tamanho nem cor; o trecho de dano pendente aparece hachurado dentro da própria barra; as chamas ficam acima da barra e não cobrem o texto; ao fim do Burn a cor original volta.
3. Por ora é **só um vídeo de protótipo**: nenhuma alteração em `battle_hud.gd`, `status_panel.gd` ou nas regras. O protótipo é um mock-up com as medidas e cores do HUD real (barra de 120×7 do painel, 5 px do inimigo), não o HUD do jogo rodando.
4. "Usando o Motion Composer": o protótipo chama a **biblioteca** (M07 turbulência, M12 pulso viajante, M16 explosão direcional, M18/M16 dissolução) para animar as chamas e as brasas. A Etapa 5 (laboratório visual) não foi autorizada (D-233); a biblioteca não foi alterada e continua sem integração ao combate.

## Correção do criador (2026-11-04, literal)

> É pro fundo mudar, o fundo branco, o fundo preto e o fundo roxo dos personagens, não a vida, com o efeito de fogo chamuscante

Isto **corrige o item 2**: o que vira laranja escuro com fogo é o **fundo dos cartões** (branco do jogador, roxo/azul do aliado, preto da etiqueta do inimigo), **não a barra de vida**, que mantém as cores originais. Interpretação aplicada (não confirmada ponto a ponto): fundo em degradê laranja escuro que pulsa, com borda **chamuscada** (carbonizada, com brasa), fogo lambendo de baixo por trás do texto e das células de ATB, brasas subindo e halo quente; o retrato do personagem também vira marrom‑queimado; os textos passam a creme para manter a leitura. A barra mostra só o trecho hachurado de dano pendente, um flash no tick e o "-2". O texto de HP, o nome e as células de ATB não são cobertos.

## Ambiguidades em aberto

- Se a barra do **inimigo** também ganha a mesma cor ou só o trecho pendente (no protótipo ela mantém a cor coral e recebe o trecho pendente e as chamas).
- Cor exata do laranja escuro e velocidade da pulsação (valores do protótipo são propostas).
- Primeiro tick e reaplicação (pendências da D-236).
- Contorno laranja pulsante no modelo 3D (parte da ideia 2): **não** mostrado neste vídeo, que é só do HUD.

## Estado

Registrada. Protótipo de HUD em `prototypes/burn_hud/`. Sem commit.

**Aprovação do criador (2026-11-04):** depois do vídeo corrigido (fundo dos cartões em laranja chamuscado com fogo, barra de vida intacta), respondeu "perfeito". Fica aprovado o **visual** do Burn para jogador, aliado e inimigo e, com isso, o Fire Bullet fica finalizado do ponto de vista visual (condição que o criador impôs). **Continuam não implementados no jogo**: o status Burn (regras), o HUD real e o contorno no modelo 3D. As pendências da D-236 (primeiro tick, reaplicação, MP, `10 + MAG`, chances) seguem em aberto.
