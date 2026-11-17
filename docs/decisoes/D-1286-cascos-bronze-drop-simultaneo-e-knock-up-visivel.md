<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1286 — Cascos: Bronze 50%, drops simultâneos, shells visíveis no knock-up e sem drop em fuga/recrutamento/derrota

- **Data** — 2026-11-17
- **Área** — Economia / drops / combate
- **Estado** — Respostas do criador. Só a taxa de Bronze e a elegibilidade negativa são implementáveis agora; o visual do drop em combate e o instante de crédito seguem pendentes.
- **Relacionadas** — [D-1285](D-1285-cascos-economia-moedas-separadas-e-chances-de-drop.md), [D-1252](D-1252-cascos-de-bronze-prata-e-ouro.md), [D-1259](D-1259-cascos-fisica-brilho-e-coleta-para-teste.md), [D-1255](D-1255-visual-dos-cascos-cunhados.md).

## Frases literais do criador

Perguntas feitas e respostas, na ordem:

1. Bronze, 50% por inimigo normal vale? — "1 - sim"
2. Prata e ouro podem cair juntos no mesmo inimigo? — "2 - sim"
3. Instante do drop (na morte ou só na vitória)? — "3 - Quando levam o knock-up a gente ve shells voando e caindo no chao, da pra saber pelo brilho bronze prata e dourado que tipo de moeda e"
4. Fuga, recrutamento e derrota geram drops? — "4 - obvio que nao geram"
5. Destino do `shell_balance` existente — "5 - nao sei"
6. Commit e push da D-1285 e da fórmula — "6 sim"

Sobre elite: "ignora essa bobagem entao" (não existe categoria de elite; vale só a taxa de inimigo normal).

## Decisão

1. **Bronze:** 50% por inimigo derrotado, uma moeda por sucesso. Sem categoria de elite.
2. **Simultâneo:** Bronze, prata e ouro podem cair juntos no mesmo inimigo, cada um com o seu sorteio independente.
3. **Fuga, recrutamento e derrota não geram drops.**
4. **Apresentação (3):** quando o inimigo leva o knock-up, os Cascos aparecem voando e caindo no chão, e o tipo é identificável pelo brilho bronze, prata ou dourado.

## Ambiguidades (não implementar)

- O sorteio acontece na morte ou no início do knock-up, e as moedas físicas viram saldo quando são coletadas ou quando a vitória é confirmada: a resposta 3 descreve o que se vê, não o instante do crédito.
- Qual inimigo "leva o knock-up" (todo inimigo derrotado, ou só o lançamento balístico de K.O. da D-1042).
- Onde as moedas ficam depois da batalha e como o jogador as coleta, e o que acontece com as não coletadas.
- Destino do `shell_balance` (resposta "nao sei"): segue pendente, sem migração.
